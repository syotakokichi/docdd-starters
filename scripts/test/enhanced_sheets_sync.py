#!/usr/bin/env python3
"""
改良版テストシート同期システム
階層構造と視覚的管理を実現
"""
import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional

# Google API Client ライブラリのオプショナルインポート
try:
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
    import boto3

    GOOGLE_SHEETS_AVAILABLE = True
    AWS_AVAILABLE = True
except ImportError as e:
    print(f"❌ Error: 必要なライブラリがインストールされていません: {e}")
    print("💡 解決方法:")
    print(
        "   1. 自動セットアップを実行: scripts/test/auto_sync_test_sheets.sh --setup-only"
    )
    print(
        "   2. 手動インストール: pip install google-api-python-client google-auth boto3"
    )
    print(
        "   3. 依存関係を強制再インストール: scripts/test/auto_sync_test_sheets.sh --force-install"
    )
    GOOGLE_SHEETS_AVAILABLE = False
    AWS_AVAILABLE = False

from collect_test_metadata import TestMetadataCollector
from docdd_test_collector import DocDDTestCollector

PROJECT_NAME = os.getenv("DOCDD_PROJECT_NAME", "DocDD Starter Project")


def merge_test_metadata(
    pytest_cases: List[Dict[str, Any]], docdd_cases: List[Dict[str, Any]]
) -> List[Dict[str, Any]]:
    """pytestとDocDDのテストメタデータを統合"""
    function_index = {case.get("function_name"): case for case in pytest_cases}
    case_index = {
        case.get("case_id"): case for case in pytest_cases if case.get("case_id")
    }

    merged_cases = pytest_cases

    for doc_case in docdd_cases:
        doc_case = dict(doc_case)
        tc_id = doc_case.get("tc_id") or doc_case.get("case_id")
        pytest_id = doc_case.get("pytest_id")

        target_case = None
        if pytest_id and pytest_id in function_index:
            target_case = function_index[pytest_id]
        elif tc_id and tc_id in case_index:
            target_case = case_index[tc_id]

        if target_case:
            # 既存pytestケースをトレーサビリティ情報で拡張
            for key in [
                "case_id",
                "priority",
                "pytest_id",
                "br_ids",
                "uc_ids",
                "dm_ids",
                "sr_ids",
                "nsr_ids",
                "ext_ids",
                "api_ids",
                "ts_document",
                "ts_path",
                "domain",
            ]:
                value = doc_case.get(key)
                if value:
                    target_case[key] = value

            if doc_case.get("docstring") and not target_case.get("docstring"):
                target_case["docstring"] = doc_case["docstring"]

            # DocDD由来のマーカーを保持
            if doc_case.get("markers"):
                target_case["docdd_markers"] = doc_case["markers"]

            continue

        # pytest未実装のDocDDケースはそのまま追加
        doc_case.setdefault("function_name", pytest_id or (tc_id or "docdd_test_case"))
        doc_case.setdefault("file_path", doc_case.get("ts_path", "DocDD"))
        doc_case.setdefault("line_number", 0)
        doc_case.setdefault("priority", doc_case.get("priority", ""))
        doc_case.setdefault("markers", doc_case.get("markers") or ["docdd"])
        doc_case["status_override"] = doc_case.get("status_hint", "Pending")
        merged_cases.append(doc_case)

    return merged_cases


def get_secret_from_aws(
    secret_name: str, region_name: str = "ap-northeast-1"
) -> Dict[str, Any]:
    """AWS Secret Managerから秘密情報を取得"""
    if not AWS_AVAILABLE:
        print("❌ Error: boto3ライブラリがインストールされていません")
        print("💡 解決方法:")
        print("   scripts/test/auto_sync_test_sheets.sh --setup-only")
        raise ValueError("boto3ライブラリがインストールされていません")

    try:
        session = boto3.session.Session()
        client = session.client(service_name="secretsmanager", region_name=region_name)

        print(f"🔑 AWS Secret Managerから認証情報を取得中: {secret_name}")
        response = client.get_secret_value(SecretId=secret_name)
        secret_data = json.loads(response["SecretString"])
        print("✅ 認証情報の取得に成功しました")
        return secret_data
    except client.exceptions.ResourceNotFoundException:
        print(f"❌ Error: Secret が見つかりません: {secret_name}")
        print("💡 確認方法:")
        print("   1. Secret名が正しいかAWSコンソールで確認")
        print("   2. 適切なリージョンを指定しているか確認")
        print("   3. IAMロールに適切な権限があるか確認")
        raise ValueError(f"Secret が見つかりません: {secret_name}")
    except client.exceptions.UnauthorizedOperation:
        print("❌ Error: AWS認証情報に問題があります")
        print("💡 解決方法:")
        print("   1. aws configure で認証情報を設定")
        print("   2. aws sts get-caller-identity で認証状況を確認")
        raise ValueError("AWS認証に失敗しました")
    except json.JSONDecodeError as e:
        print(f"❌ Error: Secret の JSON 形式が不正です: {e}")
        raise ValueError(f"Secret の JSON 形式が不正です: {e}")
    except Exception as e:
        print(f"❌ Error: Secret Managerからの秘密情報取得に失敗しました: {e}")
        print("💡 トラブルシューティング:")
        print("   1. AWS認証情報の確認: aws sts get-caller-identity")
        print("   2. Secret の存在確認: AWS コンソール")
        print("   3. IAM権限の確認")
        raise ValueError(f"Secret Managerからの秘密情報取得に失敗しました: {e}")


class EnhancedTestSheetsSynchronizer:
    """改良版テストシート同期クラス"""

    def __init__(
        self,
        credentials_path: Optional[str] = None,
        spreadsheet_id: Optional[str] = None,
        secret_arn: Optional[str] = None,
    ):
        self.spreadsheet_id = spreadsheet_id
        self.service = None

        if not GOOGLE_SHEETS_AVAILABLE:
            raise ValueError(
                "Google API Clientライブラリがインストールされていません。"
            )

        # 認証設定
        scopes = [
            "https://www.googleapis.com/auth/spreadsheets",
            "https://www.googleapis.com/auth/drive",
        ]

        try:
            if secret_arn:
                # AWS Secret Managerから認証情報を取得
                secret_data = get_secret_from_aws(secret_arn)
                credentials_info = secret_data.get("credentials")
                if not credentials_info:
                    raise ValueError("Secret Managerに認証情報が見つかりません")

                # 認証情報がJSON文字列の場合はパース
                if isinstance(credentials_info, str):
                    credentials_info = json.loads(credentials_info)

                credentials = service_account.Credentials.from_service_account_info(
                    credentials_info, scopes=scopes
                )

                # スプレッドシートIDもSecretから取得
                if not self.spreadsheet_id:
                    self.spreadsheet_id = secret_data.get("spreadsheet_id")
                    if not self.spreadsheet_id:
                        raise ValueError(
                            "Secret ManagerにスプレッドシートIDが見つかりません"
                        )

            elif credentials_path:
                # ファイルパスから認証情報を取得（従来の方法）
                credentials = service_account.Credentials.from_service_account_file(
                    credentials_path, scopes=scopes
                )
            else:
                raise ValueError("認証情報のパスまたはSecret ARNが必要です")

            self.service = build("sheets", "v4", credentials=credentials)
        except Exception as e:
            raise ValueError(f"Google Sheets API認証に失敗しました: {e}")

    def extract_module_from_filepath(self, filepath: str) -> str:
        """ファイルパスからモジュール名を抽出 (新しいモジュール構造対応)"""
        # 新しいモジュール構造に対応
        if "/modules/admin/" in filepath:
            return "admin"
        elif "/modules/payments/" in filepath:
            return "payments"
        elif "/modules/stores/" in filepath:
            return "stores"
        elif "/modules/supporters/" in filepath:
            return "supporters"
        # 共通ディレクトリ
        elif (
            "/tests/shared/" in filepath
            or "/tests/helpers/" in filepath
            or "/tests/fixtures/" in filepath
        ):
            return "shared"
        # レガシー構造も引き続きサポート
        elif "/tests/" in filepath:
            return "legacy"
        else:
            return "unknown"

    def extract_test_layer(self, filepath: str) -> str:
        """テストレイヤを抽出"""
        if "/unit/" in filepath:
            return "unit"
        elif "/integration/" in filepath:
            return "integration"
        elif "/e2e/" in filepath:
            return "e2e"
        else:
            return "unknown"

    def create_module_sheets(self):
        """モジュール別シートの作成"""
        modules = ["admin", "payments", "stores", "supporters", "shared"]

        for module in modules:
            sheet_name = f"{module.title()} Tests"

            # シートの作成または取得
            try:
                worksheet = (
                    self.service.spreadsheets()
                    .get(spreadsheetId=self.spreadsheet_id, ranges=[sheet_name])
                    .execute()
                )
                print(f"✅ Sheet already exists: {sheet_name}")
            except HttpError:
                # シートが存在しない場合は作成
                body = {
                    "requests": [
                        {
                            "addSheet": {
                                "properties": {
                                    "title": sheet_name,
                                    "gridProperties": {
                                        "rowCount": 1000,
                                        "columnCount": 20,
                                    },
                                }
                            }
                        }
                    ]
                }

                self.service.spreadsheets().batchUpdate(
                    spreadsheetId=self.spreadsheet_id, body=body
                ).execute()

                print(f"✅ Created sheet: {sheet_name}")

            # ヘッダー行の設定
            headers = [
                "ケースID",
                "テスト名",
                "モジュール",
                "テストレイヤ",
                "機能",
                "観点",
                "シナリオ種別",
                "優先度",
                "ステータス",
                "ファイルパス",
                "行番号",
                "pytest markers",
                "最終実行日",
                "最終実行結果",
                "備考",
            ]

            # ヘッダー行の書き込み
            range_name = f"{sheet_name}!A1:O1"
            body = {"values": [headers]}

            self.service.spreadsheets().values().update(
                spreadsheetId=self.spreadsheet_id,
                range=range_name,
                valueInputOption="RAW",
                body=body,
            ).execute()

            print(f"✅ Updated headers for: {sheet_name}")

    def update_dashboard_with_modules(self):
        """モジュール別ダッシュボードの更新"""
        dashboard_data = self.generate_module_dashboard()

        # ダッシュボードシートの更新
        dashboard_sheet = "📊 Module Dashboard"

        # 既存のダッシュボードシートを削除して再作成
        try:
            sheets = (
                self.service.spreadsheets()
                .get(spreadsheetId=self.spreadsheet_id)
                .execute()
            )

            for sheet in sheets["sheets"]:
                if sheet["properties"]["title"] == dashboard_sheet:
                    # 既存シートを削除
                    delete_request = {
                        "requests": [
                            {"deleteSheet": {"sheetId": sheet["properties"]["sheetId"]}}
                        ]
                    }
                    self.service.spreadsheets().batchUpdate(
                        spreadsheetId=self.spreadsheet_id, body=delete_request
                    ).execute()
                    break
        except HttpError:
            pass

        # 新しいダッシュボードシートを作成
        create_request = {
            "requests": [
                {
                    "addSheet": {
                        "properties": {
                            "title": dashboard_sheet,
                            "index": 0,  # 最初のシートとして配置
                        }
                    }
                }
            ]
        }

        self.service.spreadsheets().batchUpdate(
            spreadsheetId=self.spreadsheet_id, body=create_request
        ).execute()

        # ダッシュボードデータの書き込み
        range_name = f"{dashboard_sheet}!A1:J50"
        body = {"values": dashboard_data}

        self.service.spreadsheets().values().update(
            spreadsheetId=self.spreadsheet_id,
            range=range_name,
            valueInputOption="RAW",
            body=body,
        ).execute()

        print("✅ Updated module dashboard")

    def generate_module_dashboard(self) -> List[List[str]]:
        """モジュール別ダッシュボードデータの生成"""
        data = []

        # タイトル
        data.append([f"📊 {PROJECT_NAME} Test Management - Module Dashboard"])
        data.append([f"Last Updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"])
        data.append([])

        # モジュール別サマリー
        data.append(["🏗️ Module Summary"])
        data.append(
            [
                "Module",
                "Total Tests",
                "Unit",
                "Integration",
                "E2E",
                "Completed",
                "Progress",
            ]
        )

        modules = ["admin", "payments", "stores", "supporters", "shared"]
        for module in modules:
            # 実際のテスト数を取得（実装時に具体的なロジックを追加）
            total = 50  # プレースホルダー
            unit = 30
            integration = 15
            e2e = 5
            completed = 40
            progress = f"{(completed/total*100):.1f}%"

            data.append(
                [module.title(), total, unit, integration, e2e, completed, progress]
            )

        data.append([])

        # テストレイヤ別統計
        data.append(["📋 Test Layer Statistics"])
        data.append(["Layer", "Total", "Completed", "Pending", "Progress"])
        data.append(["Unit", 120, 95, 25, "79.2%"])
        data.append(["Integration", 60, 45, 15, "75.0%"])
        data.append(["E2E", 20, 5, 15, "25.0%"])

        return data

    def categorize_tests(self, test_cases: List[Dict]) -> Dict[str, List[Dict]]:
        """テストケースを階層的にカテゴライズ"""
        categorized = {
            "ux": {
                "name": "UX・UI改善",
                "backend_unit": [],
                "backend_integration": [],
                "frontend_e2e": [],
            },
            "authentication": {
                "name": "認証システム",
                "backend_unit": [],
                "backend_integration": [],
                "frontend_e2e": [],
            },
            "payment": {
                "name": "決済システム",
                "backend_unit": [],
                "backend_integration": [],
                "frontend_e2e": [],
            },
            "point_management": {
                "name": "ポイント管理",
                "backend_unit": [],
                "backend_integration": [],
                "frontend_e2e": [],
            },
            "store_management": {
                "name": "店舗管理",
                "backend_unit": [],
                "backend_integration": [],
                "frontend_e2e": [],
            },
            "supporter_management": {
                "name": "サポーター管理",
                "backend_unit": [],
                "backend_integration": [],
                "frontend_e2e": [],
            },
            "admin_features": {
                "name": "管理機能",
                "backend_unit": [],
                "backend_integration": [],
                "frontend_e2e": [],
            },
            "infrastructure": {
                "name": "インフラ・共通",
                "backend_unit": [],
                "backend_integration": [],
                "frontend_e2e": [],
            },
        }

        for test_case in test_cases:
            category = self._determine_category(test_case)
            test_level = self._determine_test_level(test_case)

            if category in categorized and test_level in categorized[category]:
                categorized[category][test_level].append(test_case)

        return categorized

    def _determine_category(self, test_case: Dict) -> str:
        """テストケースのカテゴリを判定（改善版：Issue #19対応）"""
        domain = (test_case.get("domain") or "").lower()
        if domain == "ux":
            return "ux"
        if domain == "monitoring":
            return "infrastructure"
        if domain == "payment":
            return "payment"

        file_path = test_case.get("file_path", "").lower()
        function_name = test_case.get("function_name", "").lower()
        raw_markers = test_case.get("markers", [])

        if isinstance(raw_markers, str):
            markers = [m.strip() for m in raw_markers.split("|") if m.strip()]
        elif isinstance(raw_markers, list):
            markers = raw_markers
        else:
            markers = []

        docdd_markers = test_case.get("docdd_markers", [])
        if isinstance(docdd_markers, list):
            markers.extend(docdd_markers)

        # 1. 明示的なmarkerを最優先（Issue #19 フェーズ1対応）
        for marker in markers:
            if marker in ["auth", "authentication"]:
                return "authentication"
            elif marker in ["payment", "charge", "vgw", "sbps"]:
                return "payment"
            elif marker in ["point", "points", "incentive"]:
                return "point_management"
            elif marker in ["store", "shop"]:
                return "store_management"
            elif marker in ["supporter", "customer"]:
                return "supporter_management"
            elif marker in ["admin", "sales"]:
                return "admin_features"
            elif marker == "infrastructure":
                return "infrastructure"

        # 2. フェーズ2: 強化されたパスベース分類（Issue #19対応）
        # 2-0. ビジネスドメイン別の詳細な分類を最優先

        # カテゴリマーカーがジェネリック（unit, api, integration等）の場合は、
        # パスベースの分類を優先する
        category_marker = test_case.get("category", "")
        if category_marker and category_marker not in [
            "unit",
            "api",
            "integration",
            "e2e",
            "performance",
        ]:
            category_mapping = {
                "auth": "authentication",
                "payment": "payment",
                "point": "point_management",
                "store": "store_management",
                "supporter": "supporter_management",
                "admin": "admin_features",
                "security": "authentication",
                "infrastructure": "infrastructure",
            }
            return category_mapping.get(category_marker, "infrastructure")

        # Performance tests should be categorized by their business domain
        if category_marker == "performance":
            return self._determine_performance_category(test_case)

        # 3. 強化されたパスベース分類（Issue #19 フェーズ2実装）

        # 3-1. 認証・セキュリティ系（強化版）
        if any(
            x in file_path
            for x in [
                "security/authentication",
                "security/authorization",
                "security/vulnerability",
                "unit/core/auth",
                "unit/services/test_staff_auth",
                "unit/services/test_supporter_auth",
                "auth",
                "login",
                "token",
                "jwt",
            ]
        ) or any(
            keyword in function_name
            for keyword in ["auth", "login", "logout", "token", "permission", "role"]
        ):
            return "authentication"

        # 2-2. 決済・チャージ系（VGW, SBPS含む）- 強化版分類
        elif any(
            x in file_path
            for x in [
                "unit/adapters/sbps",
                "unit/services/test_charge",
                "unit/api/test_charges",
                "unit/api/test_store_charge",
                "integration/business_flows",
                "integration/external_systems",
                "e2e/payment_flows",
                "charge",
                "payment",
                "sbps",
            ]
        ):
            return "payment"

        # 2-2-1. VGW関連テストの細分化（Issue #19 フェーズ2対応）
        elif "unit/adapters/value_gateway" in file_path or "vgw" in file_path:
            # VGWテストの機能別分類
            if any(
                keyword in file_path or keyword in function_name
                for keyword in ["deposit", "withdraw", "balance", "payment"]
            ):
                return "payment"
            elif any(
                keyword in file_path or keyword in function_name
                for keyword in ["incentive", "point", "purchase_incentive"]
            ):
                return "point_management"
            else:
                return "payment"  # VGWデフォルトはPayment

        # 3-3. ポイント・インセンティブ系（強化版）
        elif any(keyword in file_path for keyword in ["point", "incentive"]) or any(
            keyword in function_name for keyword in ["point", "incentive", "reward"]
        ):
            return "point_management"

        # 3-4. 店舗管理系（強化版）
        elif any(
            x in file_path
            for x in [
                "unit/services/test_store",
                "unit/api/test_store",
                "unit/infrastructure/repositories/test_store",
                "store",
                "shop",
            ]
        ) or any(
            keyword in function_name
            for keyword in ["store", "shop", "merchant", "business"]
        ):
            return "store_management"

        # 3-5. サポーター管理系（強化版）
        elif any(
            x in file_path
            for x in [
                "unit/services/test_supporter",
                "unit/api/test_supporter",
                "unit/api/test_staff_supporters",
                "unit/infrastructure/repositories/test_supporter",
                "supporter",
                "customer",
            ]
        ) or any(
            keyword in function_name
            for keyword in ["supporter", "customer", "user", "member"]
        ):
            return "supporter_management"

        # 3-6. 管理機能系（強化版）
        elif any(
            x in file_path
            for x in [
                "unit/services/test_admin",
                "unit/api/v1/test_staff",
                "admin",
                "sales",
            ]
        ) or any(
            keyword in function_name
            for keyword in ["admin", "sales", "report", "analytics", "dashboard"]
        ):
            return "admin_features"

        # 3-7. API層テストの詳細分類（新規追加）
        elif "unit/api/" in file_path:
            # APIテストの内容に基づく分類
            if any(
                keyword in file_path or keyword in function_name
                for keyword in ["charge", "payment", "deposit", "withdraw"]
            ):
                return "payment"
            elif any(
                keyword in file_path or keyword in function_name
                for keyword in ["supporter", "customer", "user"]
            ):
                return "supporter_management"
            elif any(
                keyword in file_path or keyword in function_name
                for keyword in ["store", "shop", "merchant"]
            ):
                return "store_management"
            elif any(
                keyword in file_path or keyword in function_name
                for keyword in ["auth", "login", "permission"]
            ):
                return "authentication"
            elif any(
                keyword in file_path or keyword in function_name
                for keyword in ["point", "incentive", "reward"]
            ):
                return "point_management"
            elif any(
                keyword in file_path or keyword in function_name
                for keyword in ["admin", "staff", "sales"]
            ):
                return "admin_features"
            else:
                return "infrastructure"  # Generic API tests

        # 3-8. サービス層テストの詳細分類（新規追加）
        elif "unit/services/" in file_path:
            # サービステストの内容に基づく分類
            if any(
                keyword in file_path or keyword in function_name
                for keyword in ["charge", "payment", "vgw", "sbps"]
            ):
                return "payment"
            elif any(
                keyword in file_path or keyword in function_name
                for keyword in ["supporter", "customer"]
            ):
                return "supporter_management"
            elif any(
                keyword in file_path or keyword in function_name
                for keyword in ["store", "shop"]
            ):
                return "store_management"
            elif any(
                keyword in file_path or keyword in function_name
                for keyword in ["auth", "login"]
            ):
                return "authentication"
            elif any(
                keyword in file_path or keyword in function_name
                for keyword in ["point", "incentive"]
            ):
                return "point_management"
            elif any(
                keyword in file_path or keyword in function_name
                for keyword in ["admin", "sales"]
            ):
                return "admin_features"
            else:
                return "infrastructure"  # Generic service tests

        # 2-7. インフラ・共通系（最後に判定）
        elif any(
            x in file_path
            for x in [
                "unit/infrastructure/repositories",
                "unit/infrastructure/database",
                "unit/infrastructure/external",
                "unit/core/domain",
                "unit/core/errors",
                "helpers/",
                "fixtures/",
                "conftest.py",
                "test_utils.py",
                "factories/",
                "mocks/",
                "performance/",
                "load/",
                "stress/",
                "endurance/",
            ]
        ):
            return "infrastructure"

        # 2-8. E2E・統合テスト系（内容に応じて分類）
        elif any(
            x in file_path
            for x in [
                "e2e/",
                "integration/",
                "cross_features/",
                "payment_flows/",
                "user_journeys/",
                "api_flows/",
                "business_flows/",
                "external_systems/",
            ]
        ):
            # E2Eテストは内容に応じて分類
            if any(x in file_path for x in ["payment", "charge", "vgw", "sbps"]):
                return "payment"
            elif any(x in file_path for x in ["auth", "login", "security"]):
                return "authentication"
            elif any(x in file_path for x in ["store"]):
                return "store_management"
            elif any(x in file_path for x in ["supporter"]):
                return "supporter_management"
            else:
                return "infrastructure"

        # 2-9. 関数名による分類（ファイルパスで判定できない場合）
        elif any(x in function_name for x in ["auth", "login", "token", "jwt"]):
            return "authentication"
        elif any(x in function_name for x in ["payment", "charge", "vgw", "sbps"]):
            return "payment"
        elif any(x in function_name for x in ["store", "shop"]):
            return "store_management"
        elif any(x in function_name for x in ["supporter", "customer"]):
            return "supporter_management"
        elif any(x in function_name for x in ["admin", "sales"]):
            return "admin_features"

        # デフォルト：インフラ・共通に分類
        else:
            return "infrastructure"

    def _determine_performance_category(self, test_case: Dict) -> str:
        """パフォーマンステストのビジネスドメインを判定"""
        file_path = test_case.get("file_path", "").lower()
        function_name = test_case.get("function_name", "").lower()

        # パフォーマンステストのビジネスドメインを判定
        if any(x in file_path for x in ["payment", "charge", "vgw", "sbps"]) or any(
            x in function_name for x in ["payment", "charge", "vgw", "sbps"]
        ):
            return "payment"
        elif any(x in file_path for x in ["auth", "login", "security"]) or any(
            x in function_name for x in ["auth", "login", "security"]
        ):
            return "authentication"
        elif any(x in file_path for x in ["point", "incentive"]) or any(
            x in function_name for x in ["point", "incentive"]
        ):
            return "point_management"
        elif any(x in file_path for x in ["store", "shop"]) or any(
            x in function_name for x in ["store", "shop"]
        ):
            return "store_management"
        elif any(x in file_path for x in ["supporter", "customer"]) or any(
            x in function_name for x in ["supporter", "customer"]
        ):
            return "supporter_management"
        elif any(x in file_path for x in ["admin", "sales"]) or any(
            x in function_name for x in ["admin", "sales"]
        ):
            return "admin_features"
        else:
            # デフォルトはインフラストラクチャ
            return "infrastructure"

    def _determine_test_level(self, test_case: Dict) -> str:
        """テストレベルを判定"""
        override = test_case.get("test_level_override")
        if override in ["backend_unit", "backend_integration", "frontend_e2e"]:
            return override

        file_path = test_case.get("file_path", "").lower()

        # 新しいディレクトリ構造に対応したテストレベル判定
        if "tests/unit/" in file_path:
            return "backend_unit"
        elif "tests/integration/" in file_path:
            return "backend_integration"
        elif "tests/e2e/" in file_path:
            return "frontend_e2e"
        elif "tests/performance/" in file_path:
            return "backend_unit"  # パフォーマンステストは単体テスト扱い
        elif "tests/security/" in file_path:
            return "backend_unit"  # セキュリティテストは単体テスト扱い
        else:
            # 従来の判定ロジックをフォールバック
            if "api" in file_path or "integration" in file_path:
                return "backend_integration"
            elif "frontend" in file_path or "e2e" in file_path:
                return "frontend_e2e"
            else:
                return "backend_unit"

    def create_enhanced_sheets(self, categorized_tests: Dict, dry_run: bool = False):
        """改良版シートを作成"""
        print("改良版テストシートを作成中...")

        for category_key, category_data in categorized_tests.items():
            if not any(
                category_data[level]
                for level in ["backend_unit", "backend_integration", "frontend_e2e"]
            ):
                continue  # 空のカテゴリはスキップ

            sheet_name = category_data["name"]
            print(f"シート '{sheet_name}' を作成中...")

            if not dry_run:
                self._create_category_sheet(category_key, category_data, sheet_name)

    def _create_category_sheet(
        self, category_key: str, category_data: Dict, sheet_name: str
    ):
        """カテゴリ別シートを作成"""
        # シートの存在確認・作成
        self._ensure_sheet_exists(sheet_name)

        # ヘッダー行（最適化版：機能×観点の2軸構造）
        headers = [
            # 識別（自動採番推奨）
            "ケースID",
            "テスト名",
            # 分類（2軸構造・ドロップダウン固定）
            "機能",
            "観点",
            "テストレイヤ",
            "シナリオ種別",
            # 環境・端末（UI系のみ）
            "端末/ブラウザ",
            "Actor",
            # 優先度・進捗（手動+自動）
            "優先度",
            "ステータス",
            # 実装ハンドオーバ（自動）
            "ファイルパス",
            "行番号",
            "pytest markers",
            # 実行履歴（自動）
            "最終実行日",
            "最終実行結果",
            # 説明（手動）
            "備考",
            # トレーサビリティ
            "BR IDs",
            "UC IDs",
            "DM IDs",
            "SR IDs",
            "NSR IDs",
            "EXT IDs",
            "API IDs",
            "pytest_id",
            "テスト設計書",
        ]

        # データ行を作成
        rows = [headers]

        # テストレベル順に追加
        test_levels = [
            ("backend_unit", "バックエンド", "単体テスト"),
            ("backend_integration", "バックエンド", "統合テスト"),
            ("frontend_e2e", "フロントエンド", "E2Eテスト"),
        ]

        for level_key, major_category, minor_category in test_levels:
            tests = category_data.get(level_key, [])
            if not tests:
                continue

            for i, test in enumerate(tests):
                # 各種判定
                scenario_type = self._determine_scenario_type(test)
                test_aspect = self._determine_test_aspect(test)
                function_category = self._determine_function_category(test)
                browser_info = self._determine_browser_info(test, test_aspect)
                actor = self._determine_actor(test)

                # pytestマーカーを文字列に変換
                markers_field = test.get("markers", [])
                if isinstance(markers_field, list):
                    markers = ",".join(markers_field)
                else:
                    markers = markers_field or ""

                def _join_list(value: Any) -> str:
                    if isinstance(value, list):
                        return ", ".join(str(v) for v in value)
                    if isinstance(value, str):
                        return value
                    return ""

                row = [
                    # 識別
                    self._generate_case_id(test, category_key, level_key),  # ケースID
                    self._generate_test_name(test),  # テスト名（日本語化）
                    # 分類（2軸構造）
                    function_category,  # 機能
                    test_aspect,  # 観点
                    self._determine_test_layer(level_key),  # テストレイヤ
                    scenario_type,  # シナリオ種別
                    # 環境・端末
                    browser_info,  # 端末/ブラウザ
                    actor,  # Actor
                    # 優先度・進捗
                    test.get("priority", ""),  # 優先度
                    self._determine_status(test),  # ステータス
                    # 実装ハンドオーバ（自動）
                    test.get("file_path", ""),  # ファイルパス
                    test.get("line_number", ""),  # 行番号
                    markers,  # pytest markers
                    # 実行履歴（自動）
                    "",  # 最終実行日（CI更新用）
                    "",  # 最終実行結果（CI更新用）
                    # 説明
                    "",  # 備考（手動入力用）
                    # トレーサビリティ
                    _join_list(test.get("br_ids")),
                    _join_list(test.get("uc_ids")),
                    _join_list(test.get("dm_ids")),
                    _join_list(test.get("sr_ids")),
                    _join_list(test.get("nsr_ids")),
                    _join_list(test.get("ext_ids")),
                    _join_list(test.get("api_ids")),
                    test.get("pytest_id", ""),
                    test.get("ts_document", ""),
                ]
                rows.append(row)

        # シートに書き込み
        self._update_sheet_with_formatting(sheet_name, rows)

    def _determine_scenario_type(self, test: Dict) -> str:
        """シナリオ種別を判定（拡張7分類）"""
        function_name = test.get("function_name", "").lower()
        docstring = test.get("docstring", "").lower()
        combined_text = function_name + " " + docstring

        # 優先度順で判定（より具体的なものから）
        if any(
            keyword in combined_text
            for keyword in [
                "duplicate",
                "unique",
                "重複",
                "一意",
                "already_exists",
                "exists",
            ]
        ):
            return "重複/一意制約"
        elif any(
            keyword in combined_text
            for keyword in [
                "security",
                "csrf",
                "injection",
                "xss",
                "セキュリティ",
                "cookie",
                "token",
            ]
        ):
            return "セキュリティ"
        elif any(
            keyword in combined_text
            for keyword in [
                "validation",
                "format",
                "形式",
                "検証",
                "invalid_format",
                "required",
            ]
        ):
            return "入力検証"
        elif any(
            keyword in combined_text
            for keyword in [
                "external",
                "api",
                "connection",
                "外部",
                "timeout",
                "503",
                "500",
                "error",
            ]
        ):
            return "外部依存エラー"
        elif any(
            keyword in combined_text
            for keyword in ["boundary", "境界", "edge", "limit", "min", "max", "length"]
        ):
            return "境界値"
        elif any(
            keyword in combined_text
            for keyword in ["success", "正常", "成功", "valid", "ok", "normal"]
        ):
            return "正常系"
        else:
            return "その他"

    def _generate_test_name(self, test: Dict) -> str:
        """テスト名を日本語化して生成"""
        function_name = test.get("function_name", "")
        docstring = test.get("docstring", "")

        # docstringがある場合は優先
        if docstring:
            # 40文字以内に制限
            if len(docstring) > 40:
                return docstring[:37] + "..."
            return docstring

        # function_nameから推測して日本語化
        if function_name:
            # 一般的なテスト関数名のパターンを日本語化
            name_mapping = {
                "test_": "",
                "_success": "成功",
                "_failure": "失敗",
                "_error": "エラー",
                "_valid": "正常",
                "_invalid": "異常",
                "_create": "作成",
                "_update": "更新",
                "_delete": "削除",
                "_get": "取得",
                "_login": "ログイン",
                "_logout": "ログアウト",
                "_payment": "決済",
                "_charge": "チャージ",
                "_balance": "残高",
                "_point": "ポイント",
            }

            japanese_name = function_name
            for eng, jpn in name_mapping.items():
                japanese_name = japanese_name.replace(eng, jpn)

            # 先頭の文字を大文字に
            if japanese_name:
                japanese_name = japanese_name[0].upper() + japanese_name[1:]

            return japanese_name[:40]  # 40文字制限

        return "テスト名未設定"

    def _determine_test_aspect(self, test: Dict) -> str:
        """観点（テストカテゴリ）を判定"""
        file_path = test.get("file_path", "").lower()
        function_name = test.get("function_name", "").lower()
        docstring = test.get("docstring", "").lower()
        combined_text = file_path + " " + function_name + " " + docstring

        # 優先度順で判定（より具体的なものから）
        if any(
            keyword in combined_text
            for keyword in ["ui", "frontend", "display", "表示", "layout", "responsive"]
        ):
            if any(
                keyword in combined_text
                for keyword in ["click", "button", "link", "form", "操作", "input"]
            ):
                return "UI-操作"
            else:
                return "UI-表示"
        elif any(
            keyword in combined_text
            for keyword in [
                "validation",
                "format",
                "検証",
                "形式",
                "required",
                "length",
            ]
        ):
            return "入力検証"
        elif any(
            keyword in combined_text
            for keyword in [
                "database",
                "db",
                "repository",
                "model",
                "insert",
                "update",
                "delete",
            ]
        ):
            return "DB-登録"
        elif any(
            keyword in combined_text
            for keyword in ["api", "request", "response", "timeout", "connection"]
        ):
            return "API-通信"
        elif any(
            keyword in combined_text
            for keyword in ["auth", "permission", "role", "権限", "login", "logout"]
        ):
            return "権限"
        elif any(
            keyword in combined_text
            for keyword in ["performance", "load", "性能", "speed", "concurrent"]
        ):
            return "性能"
        elif any(
            keyword in combined_text
            for keyword in ["file", "upload", "download", "pdf", "csv", "image"]
        ):
            return "ファイル"
        elif any(
            keyword in combined_text
            for keyword in ["sync", "同期", "queue", "batch", "cron", "schedule"]
        ):
            return "同期連携"
        elif any(
            keyword in combined_text
            for keyword in ["reload", "back", "retry", "再試行", "recovery"]
        ):
            return "リカバリ"
        else:
            return "その他"

    def _determine_function_category(self, test: Dict) -> str:
        """機能カテゴリを判定"""
        function_name = test.get("function_name", "").lower()
        docstring = test.get("docstring", "").lower()
        file_path = test.get("file_path", "").lower()
        combined_text = function_name + " " + docstring + " " + file_path

        if any(
            keyword in combined_text
            for keyword in ["login", "logout", "signin", "signout", "ログイン"]
        ):
            return "ログイン/ログアウト"
        elif any(
            keyword in combined_text
            for keyword in ["register", "signup", "create", "登録", "作成"]
        ):
            return "登録/作成"
        elif any(
            keyword in combined_text
            for keyword in ["update", "edit", "modify", "更新", "編集"]
        ):
            return "更新/編集"
        elif any(keyword in combined_text for keyword in ["delete", "remove", "削除"]):
            return "削除"
        elif any(
            keyword in combined_text
            for keyword in ["search", "find", "filter", "検索", "絞り込み"]
        ):
            return "検索/フィルタ"
        elif any(
            keyword in combined_text
            for keyword in ["list", "index", "get", "一覧", "取得"]
        ):
            return "一覧/取得"
        elif any(
            keyword in combined_text
            for keyword in ["payment", "charge", "deposit", "決済", "チャージ"]
        ):
            return "決済/チャージ"
        elif any(
            keyword in combined_text
            for keyword in ["balance", "point", "残高", "ポイント"]
        ):
            return "残高/ポイント管理"
        elif any(
            keyword in combined_text for keyword in ["history", "log", "履歴", "ログ"]
        ):
            return "履歴/ログ"
        elif any(
            keyword in combined_text
            for keyword in ["report", "export", "pdf", "csv", "レポート", "出力"]
        ):
            return "レポート/出力"
        elif any(
            keyword in combined_text
            for keyword in ["notification", "mail", "message", "通知", "メール"]
        ):
            return "通知/メッセージ"
        else:
            return "その他"

    def _determine_browser_info(self, test: Dict, aspect: str) -> str:
        """端末/ブラウザ情報を判定（UI系のみ）"""
        if not aspect.startswith("UI-"):
            return "-"  # UI系以外は不要

        # テストファイルから推測
        file_path = test.get("file_path", "").lower()
        if "e2e" in file_path or "frontend" in file_path:
            return "PC-Chrome"  # デフォルトのE2E環境
        else:
            return "-"

    def _determine_test_layer(self, level_key: str) -> str:
        """テストレイヤを判定"""
        layer_mapping = {
            "backend_unit": "Unit",
            "backend_integration": "Integration",
            "frontend_e2e": "E2E",
        }
        return layer_mapping.get(level_key, "Unknown")

    def _determine_actor(self, test: Dict) -> str:
        """Actor（役割）を判定"""
        file_path = test.get("file_path", "").lower()
        function_name = test.get("function_name", "").lower()
        combined_text = file_path + " " + function_name

        # parametrizeされている場合を検出
        if any(keyword in combined_text for keyword in ["parametrize", "param"]):
            return "Param"
        elif any(keyword in combined_text for keyword in ["staff", "admin"]):
            return "Staff"
        elif any(keyword in combined_text for keyword in ["supporter", "customer"]):
            return "Supporter"
        else:
            return "System"  # システム機能（ログ、DB操作など）

    def _generate_case_id(self, test: Dict, category_key: str, level_key: str) -> str:
        """ケースIDを自動生成（TC-{CATEGORY}-{FUNCTION}-{連番}形式）"""
        case_id = test.get("case_id", "")
        if case_id:
            return case_id

        # カテゴリ略称マッピング
        category_abbrev = {
            "ux": "UX",
            "authentication": "AUTH",
            "payment": "PAY",
            "point_management": "PNT",
            "store_management": "STR",
            "supporter_management": "SUP",
            "admin_features": "ADM",
            "infrastructure": "INF",
        }

        # 機能略称を関数名から推定
        function_name = test.get("function_name", "").lower()
        if "login" in function_name:
            func_code = "LG"
        elif "register" in function_name or "create" in function_name:
            func_code = "RG"
        elif "update" in function_name:
            func_code = "UP"
        elif "delete" in function_name:
            func_code = "DL"
        elif "payment" in function_name or "charge" in function_name:
            func_code = "CHG"
        elif "balance" in function_name:
            func_code = "BAL"
        else:
            func_code = "GEN"  # General

        cat_code = category_abbrev.get(category_key, "UNK")

        # 連番は実際の実装では別途管理が必要
        # ここでは仮の値として行番号ベースで生成
        line_no = test.get("line_number", 0)
        sequence = str(line_no).zfill(4)

        return f"TC-{cat_code}-{func_code}-{sequence}"

    def _determine_status(self, test: Dict) -> str:
        """テストステータスを判定"""
        if test.get("status_override"):
            return test["status_override"]

        case_id = test.get("case_id", "")
        priority = test.get("priority", "")

        if case_id and priority:
            return "自動化済み"
        elif case_id:
            return "実装済み"
        else:
            return "未実装"

    def _update_sheet_with_formatting(self, sheet_name: str, rows: List[List]):
        """フォーマット付きでシートを更新"""
        # データを書き込み（25列: A=case_id ~ Y=ts_document）
        range_name = f"{sheet_name}!A:Y"
        body = {"values": rows, "majorDimension": "ROWS"}

        # 既存データをクリア
        self.service.spreadsheets().values().clear(
            spreadsheetId=self.spreadsheet_id, range=range_name
        ).execute()

        # 新しいデータを書き込み
        self.service.spreadsheets().values().update(
            spreadsheetId=self.spreadsheet_id,
            range=range_name,
            valueInputOption="RAW",
            body=body,
        ).execute()

        # フォーマットを適用
        self._apply_formatting(sheet_name, len(rows))

    def _apply_formatting(self, sheet_name: str, row_count: int):
        """シートにフォーマットを適用"""
        # シートIDを取得
        spreadsheet = (
            self.service.spreadsheets().get(spreadsheetId=self.spreadsheet_id).execute()
        )

        sheet_id = None
        for sheet in spreadsheet["sheets"]:
            if sheet["properties"]["title"] == sheet_name:
                sheet_id = sheet["properties"]["sheetId"]
                break

        if sheet_id is None:
            return

        requests = []

        # ヘッダー行のフォーマット
        requests.append(
            {
                "repeatCell": {
                    "range": {
                        "sheetId": sheet_id,
                        "startRowIndex": 0,
                        "endRowIndex": 1,
                        "startColumnIndex": 0,
                        "endColumnIndex": 16,
                    },
                    "cell": {
                        "userEnteredFormat": {
                            "backgroundColor": {"red": 0.9, "green": 0.9, "blue": 0.9},
                            "textFormat": {"bold": True},
                            "horizontalAlignment": "CENTER",
                        }
                    },
                    "fields": "userEnteredFormat",
                }
            }
        )

        # ステータスによる条件付き書式

        # Critical優先度の行を赤色に
        requests.append(
            {
                "addConditionalFormatRule": {
                    "rule": {
                        "ranges": [
                            {
                                "sheetId": sheet_id,
                                "startRowIndex": 1,
                                "endRowIndex": row_count,
                                "startColumnIndex": 0,
                                "endColumnIndex": 16,
                            }
                        ],
                        "booleanRule": {
                            "condition": {
                                "type": "TEXT_EQ",
                                "values": [{"userEnteredValue": "critical"}],
                            },
                            "format": {
                                "backgroundColor": {
                                    "red": 1.0,
                                    "green": 0.8,
                                    "blue": 0.8,
                                }
                            },
                        },
                    },
                    "index": 0,
                }
            }
        )

        # 自動化済み行を緑色に
        requests.append(
            {
                "addConditionalFormatRule": {
                    "rule": {
                        "ranges": [
                            {
                                "sheetId": sheet_id,
                                "startRowIndex": 1,
                                "endRowIndex": row_count,
                                "startColumnIndex": 0,
                                "endColumnIndex": 16,
                            }
                        ],
                        "booleanRule": {
                            "condition": {
                                "type": "TEXT_EQ",
                                "values": [{"userEnteredValue": "自動化済み"}],
                            },
                            "format": {
                                "backgroundColor": {
                                    "red": 0.8,
                                    "green": 1.0,
                                    "blue": 0.8,
                                }
                            },
                        },
                    },
                    "index": 1,
                }
            }
        )

        # 未実装行を黄色に
        requests.append(
            {
                "addConditionalFormatRule": {
                    "rule": {
                        "ranges": [
                            {
                                "sheetId": sheet_id,
                                "startRowIndex": 1,
                                "endRowIndex": row_count,
                                "startColumnIndex": 0,
                                "endColumnIndex": 16,
                            }
                        ],
                        "booleanRule": {
                            "condition": {
                                "type": "TEXT_EQ",
                                "values": [{"userEnteredValue": "未実装"}],
                            },
                            "format": {
                                "backgroundColor": {
                                    "red": 1.0,
                                    "green": 1.0,
                                    "blue": 0.8,
                                }
                            },
                        },
                    },
                    "index": 2,
                }
            }
        )

        # 列幅の調整（16列対応）
        column_widths = [
            120,  # ケースID
            220,  # テスト名
            120,  # 機能
            100,  # 観点
            100,  # テストレイヤ
            100,  # シナリオ種別
            120,  # 端末/ブラウザ
            80,  # Actor
            80,  # 優先度
            100,  # ステータス
            350,  # ファイルパス
            60,  # 行番号
            150,  # pytest markers
            100,  # 最終実行日
            100,  # 最終実行結果
            200,  # 備考
        ]
        for i, width in enumerate(column_widths):
            requests.append(
                {
                    "updateDimensionProperties": {
                        "range": {
                            "sheetId": sheet_id,
                            "dimension": "COLUMNS",
                            "startIndex": i,
                            "endIndex": i + 1,
                        },
                        "properties": {"pixelSize": width},
                        "fields": "pixelSize",
                    }
                }
            )

        # DataValidation（ドロップダウンリスト）の追加
        validation_requests = self._create_data_validation_requests(sheet_id, row_count)
        requests.extend(validation_requests)

        # バッチ更新実行
        if requests:
            self.service.spreadsheets().batchUpdate(
                spreadsheetId=self.spreadsheet_id, body={"requests": requests}
            ).execute()

    def _create_data_validation_requests(
        self, sheet_id: int, row_count: int
    ) -> List[Dict]:
        """DataValidation（ドロップダウンリスト）のリクエストを生成"""
        validation_requests = []

        # Column C: 機能（主要機能カテゴリ）
        function_values = [
            "ログイン/ログアウト",
            "登録/作成",
            "更新/編集",
            "削除",
            "検索/フィルタ",
            "一覧/取得",
            "決済/チャージ",
            "残高/ポイント管理",
            "履歴/ログ",
            "レポート/出力",
            "通知/メッセージ",
            "その他",
        ]
        validation_requests.append(
            {
                "setDataValidation": {
                    "range": {
                        "sheetId": sheet_id,
                        "startRowIndex": 1,
                        "endRowIndex": row_count,
                        "startColumnIndex": 2,  # C列（機能）
                        "endColumnIndex": 3,
                    },
                    "rule": {
                        "condition": {
                            "type": "ONE_OF_LIST",
                            "values": [
                                {"userEnteredValue": value} for value in function_values
                            ],
                        },
                        "showCustomUi": True,
                        "strict": True,
                    },
                }
            }
        )

        # Column D: 観点（テストカテゴリ）
        aspect_values = [
            "UI-表示",
            "UI-操作",
            "入力検証",
            "DB-登録",
            "API-通信",
            "権限",
            "性能",
            "ファイル",
            "同期連携",
            "リカバリ",
            "その他",
        ]
        validation_requests.append(
            {
                "setDataValidation": {
                    "range": {
                        "sheetId": sheet_id,
                        "startRowIndex": 1,
                        "endRowIndex": row_count,
                        "startColumnIndex": 3,  # D列（観点）
                        "endColumnIndex": 4,
                    },
                    "rule": {
                        "condition": {
                            "type": "ONE_OF_LIST",
                            "values": [
                                {"userEnteredValue": value} for value in aspect_values
                            ],
                        },
                        "showCustomUi": True,
                        "strict": True,
                    },
                }
            }
        )

        # Column E: テストレイヤ
        layer_values = ["Unit", "Integration", "E2E"]
        validation_requests.append(
            {
                "setDataValidation": {
                    "range": {
                        "sheetId": sheet_id,
                        "startRowIndex": 1,
                        "endRowIndex": row_count,
                        "startColumnIndex": 4,  # E列（テストレイヤ）
                        "endColumnIndex": 5,
                    },
                    "rule": {
                        "condition": {
                            "type": "ONE_OF_LIST",
                            "values": [
                                {"userEnteredValue": value} for value in layer_values
                            ],
                        },
                        "showCustomUi": True,
                        "strict": True,
                    },
                }
            }
        )

        # Column F: シナリオ種別（拡張7分類）
        scenario_values = [
            "正常系",
            "入力検証",
            "重複/一意制約",
            "外部依存エラー",
            "境界値",
            "セキュリティ",
            "その他",
        ]
        validation_requests.append(
            {
                "setDataValidation": {
                    "range": {
                        "sheetId": sheet_id,
                        "startRowIndex": 1,
                        "endRowIndex": row_count,
                        "startColumnIndex": 5,  # F列（シナリオ種別）
                        "endColumnIndex": 6,
                    },
                    "rule": {
                        "condition": {
                            "type": "ONE_OF_LIST",
                            "values": [
                                {"userEnteredValue": value} for value in scenario_values
                            ],
                        },
                        "showCustomUi": True,
                        "strict": True,
                    },
                }
            }
        )

        # Column G: 端末/ブラウザ
        browser_values = [
            "PC-Chrome",
            "PC-Safari",
            "PC-Firefox",
            "Mobile-iOS",
            "Mobile-Android",
            "Tablet",
            "-",
        ]
        validation_requests.append(
            {
                "setDataValidation": {
                    "range": {
                        "sheetId": sheet_id,
                        "startRowIndex": 1,
                        "endRowIndex": row_count,
                        "startColumnIndex": 6,  # G列（端末/ブラウザ）
                        "endColumnIndex": 7,
                    },
                    "rule": {
                        "condition": {
                            "type": "ONE_OF_LIST",
                            "values": [
                                {"userEnteredValue": value} for value in browser_values
                            ],
                        },
                        "showCustomUi": True,
                        "strict": True,
                    },
                }
            }
        )

        # Column H: Actor（役割）
        actor_values = ["Staff", "Supporter", "System", "Param"]
        validation_requests.append(
            {
                "setDataValidation": {
                    "range": {
                        "sheetId": sheet_id,
                        "startRowIndex": 1,
                        "endRowIndex": row_count,
                        "startColumnIndex": 7,  # H列（Actor）
                        "endColumnIndex": 8,
                    },
                    "rule": {
                        "condition": {
                            "type": "ONE_OF_LIST",
                            "values": [
                                {"userEnteredValue": value} for value in actor_values
                            ],
                        },
                        "showCustomUi": True,
                        "strict": True,
                    },
                }
            }
        )

        # Column I: 優先度
        priority_values = ["critical", "high", "medium", "low"]
        validation_requests.append(
            {
                "setDataValidation": {
                    "range": {
                        "sheetId": sheet_id,
                        "startRowIndex": 1,
                        "endRowIndex": row_count,
                        "startColumnIndex": 8,  # I列（優先度）
                        "endColumnIndex": 9,
                    },
                    "rule": {
                        "condition": {
                            "type": "ONE_OF_LIST",
                            "values": [
                                {"userEnteredValue": value} for value in priority_values
                            ],
                        },
                        "showCustomUi": True,
                        "strict": True,
                    },
                }
            }
        )

        # Column J: ステータス
        status_values = ["未実装", "実装済み", "自動化済み", "レビュー中", "スキップ"]
        validation_requests.append(
            {
                "setDataValidation": {
                    "range": {
                        "sheetId": sheet_id,
                        "startRowIndex": 1,
                        "endRowIndex": row_count,
                        "startColumnIndex": 9,  # J列（ステータス）
                        "endColumnIndex": 10,
                    },
                    "rule": {
                        "condition": {
                            "type": "ONE_OF_LIST",
                            "values": [
                                {"userEnteredValue": value} for value in status_values
                            ],
                        },
                        "showCustomUi": True,
                        "strict": True,
                    },
                }
            }
        )

        return validation_requests

    def create_overview_dashboard(self, categorized_tests: Dict):
        """概要ダッシュボードシートを作成（チャート機能付き）"""
        print("概要ダッシュボードを作成中...")

        # 概要シートの存在確認・作成
        dashboard_sheet_name = "📊 テスト管理ダッシュボード"
        self._ensure_sheet_exists(dashboard_sheet_name)

        # 統計データの計算
        dashboard_rows = self._generate_dashboard_content(categorized_tests)

        # シートに書き込み
        self._update_dashboard_sheet(dashboard_sheet_name, dashboard_rows)

        # チャートを追加
        self._add_dashboard_charts(dashboard_sheet_name, categorized_tests)

        print(f"概要ダッシュボード '{dashboard_sheet_name}' を作成しました")

    def _generate_dashboard_content(self, categorized_tests: Dict) -> List[List]:
        """ダッシュボードコンテンツを生成（リアルタイム進捗対応）"""
        rows = []

        # タイトル行とリアルタイム更新情報
        rows.append([f"{PROJECT_NAME} テスト管理ダッシュボード"])
        rows.append([f'最終更新: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}'])
        rows.append([""])  # 空行

        # リアルタイム進捗サマリー
        rows.append(["📊 リアルタイム進捗サマリー"])
        rows.append(
            [
                "ドメイン",
                "総テスト数",
                "実装済み",
                "自動化済み",
                "未実装",
                "進捗率",
                "ステータス",
                "トレンド",
            ]
        )

        for category_key, category_data in categorized_tests.items():
            # 各レベルのテスト数を集計
            all_tests = []
            for level in ["backend_unit", "backend_integration", "frontend_e2e"]:
                all_tests.extend(category_data.get(level, []))

            if not all_tests:
                continue

            total_count = len(all_tests)
            implemented_count = sum(
                1
                for test in all_tests
                if self._determine_status(test) in ["実装済み", "自動化済み"]
            )
            automated_count = sum(
                1 for test in all_tests if self._determine_status(test) == "自動化済み"
            )
            unimplemented_count = sum(
                1 for test in all_tests if self._determine_status(test) == "未実装"
            )

            progress_rate = (
                round((implemented_count / total_count) * 100, 1)
                if total_count > 0
                else 0
            )
            status = self._get_progress_status(progress_rate)

            # トレンド分析を追加
            trend = self._calculate_progress_trend(category_key, progress_rate)

            rows.append(
                [
                    category_data["name"],
                    total_count,
                    implemented_count,
                    automated_count,
                    unimplemented_count,
                    f"{progress_rate}%",
                    status,
                    trend,
                ]
            )

        rows.append([""])  # 空行

        # テストパターン分析
        rows.append(["🎯 テストパターン分析"])
        rows.append(["シナリオ種別", "件数", "割合"])

        # 全テストからシナリオ種別を集計
        all_tests = []
        for category_data in categorized_tests.values():
            for level in ["backend_unit", "backend_integration", "frontend_e2e"]:
                all_tests.extend(category_data.get(level, []))

        scenario_counts = {}
        for test in all_tests:
            scenario = self._determine_scenario_type(test)
            scenario_counts[scenario] = scenario_counts.get(scenario, 0) + 1

        total_scenarios = sum(scenario_counts.values())
        for scenario, count in sorted(
            scenario_counts.items(), key=lambda x: x[1], reverse=True
        ):
            percentage = (
                round((count / total_scenarios) * 100, 1) if total_scenarios > 0 else 0
            )
            rows.append([scenario, count, f"{percentage}%"])

        rows.append([""])  # 空行

        # 観点別分析
        rows.append(["🔍 観点別分析"])
        rows.append(["テスト観点", "件数", "割合"])

        aspect_counts = {}
        for test in all_tests:
            aspect = self._determine_test_aspect(test)
            aspect_counts[aspect] = aspect_counts.get(aspect, 0) + 1

        total_aspects = sum(aspect_counts.values())
        for aspect, count in sorted(
            aspect_counts.items(), key=lambda x: x[1], reverse=True
        ):
            percentage = (
                round((count / total_aspects) * 100, 1) if total_aspects > 0 else 0
            )
            rows.append([aspect, count, f"{percentage}%"])

        rows.append([""])  # 空行

        # テストレイヤ別統計
        rows.append(["⚙️ テストレイヤ別統計"])
        rows.append(["テストレイヤ", "件数", "実装率"])

        layer_stats = {
            "Unit": {"total": 0, "implemented": 0},
            "Integration": {"total": 0, "implemented": 0},
            "E2E": {"total": 0, "implemented": 0},
        }

        for category_data in categorized_tests.values():
            for level_key, level_data in [
                ("backend_unit", "Unit"),
                ("backend_integration", "Integration"),
                ("frontend_e2e", "E2E"),
            ]:
                tests = category_data.get(level_key, [])
                layer_stats[level_data]["total"] += len(tests)
                layer_stats[level_data]["implemented"] += sum(
                    1
                    for test in tests
                    if self._determine_status(test) in ["実装済み", "自動化済み"]
                )

        for layer, stats in layer_stats.items():
            impl_rate = (
                round((stats["implemented"] / stats["total"]) * 100, 1)
                if stats["total"] > 0
                else 0
            )
            rows.append([layer, stats["total"], f"{impl_rate}%"])

        rows.append([""])  # 空行

        # 優先度別統計
        rows.append(["🚨 優先度別統計"])
        rows.append(["優先度", "件数", "未実装件数", "対応必要度"])

        priority_counts = {"critical": 0, "high": 0, "medium": 0, "low": 0, "": 0}
        priority_unimplemented = {
            "critical": 0,
            "high": 0,
            "medium": 0,
            "low": 0,
            "": 0,
        }

        for test in all_tests:
            priority = test.get("priority", "")
            priority_counts[priority] = priority_counts.get(priority, 0) + 1
            if self._determine_status(test) == "未実装":
                priority_unimplemented[priority] = (
                    priority_unimplemented.get(priority, 0) + 1
                )

        priority_labels = {
            "critical": "Critical",
            "high": "High",
            "medium": "Medium",
            "low": "Low",
            "": "未設定",
        }

        for priority, label in priority_labels.items():
            total = priority_counts.get(priority, 0)
            unimpl = priority_unimplemented.get(priority, 0)
            urgency = (
                "🔴 緊急"
                if priority == "critical" and unimpl > 0
                else (
                    "🟡 要対応"
                    if priority == "high" and unimpl > 0
                    else "🟢 通常" if unimpl == 0 else "⚪ 低優先"
                )
            )
            rows.append([label, total, unimpl, urgency])

        return rows

    def _get_progress_status(self, progress_rate: float) -> str:
        """進捗率からステータスを取得"""
        if progress_rate >= 90:
            return "🟢 完了"
        elif progress_rate >= 70:
            return "🟡 進行中"
        elif progress_rate >= 30:
            return "🟠 開始済み"
        else:
            return "🔴 未着手"

    def _calculate_progress_trend(
        self, category_key: str, current_progress: float
    ) -> str:
        """進捗トレンドを計算（改善計画）"""
        # 実際の実装では過去のデータと比較する必要があるが、
        # ここでは簡易的に現在の進捗率から推定
        if current_progress >= 90:
            return "📈 安定"
        elif current_progress >= 70:
            return "📈 順調"
        elif current_progress >= 50:
            return "📊 進行中"
        elif current_progress >= 30:
            return "📉 要改善"
        else:
            return "⚠️ 要注意"

    def calculate_real_time_progress(self, test_results: Dict) -> Dict:
        """リアルタイム進捗率計算（新機能）"""
        progress_data = {
            "last_updated": datetime.now().isoformat(),
            "total_tests": 0,
            "executed_tests": 0,
            "passed_tests": 0,
            "failed_tests": 0,
            "skipped_tests": 0,
            "progress_rate": 0.0,
            "execution_trend": "📊 データ収集中",
        }

        # テスト実行結果から統計を計算
        if test_results:
            progress_data["total_tests"] = test_results.get("total", 0)
            progress_data["executed_tests"] = test_results.get("executed", 0)
            progress_data["passed_tests"] = test_results.get("passed", 0)
            progress_data["failed_tests"] = test_results.get("failed", 0)
            progress_data["skipped_tests"] = test_results.get("skipped", 0)

            if progress_data["total_tests"] > 0:
                progress_data["progress_rate"] = (
                    progress_data["executed_tests"] / progress_data["total_tests"]
                ) * 100

                # 実行トレンドを判定
                if (
                    progress_data["failed_tests"] == 0
                    and progress_data["passed_tests"] > 0
                ):
                    progress_data["execution_trend"] = "🟢 全成功"
                elif (
                    progress_data["failed_tests"] / progress_data["executed_tests"]
                    < 0.1
                ):
                    progress_data["execution_trend"] = "📈 良好"
                elif (
                    progress_data["failed_tests"] / progress_data["executed_tests"]
                    < 0.3
                ):
                    progress_data["execution_trend"] = "📊 要改善"
                else:
                    progress_data["execution_trend"] = "🔴 要修正"

        return progress_data

    def create_progress_charts(self, worksheet, data: Dict):
        """進捗チャートの生成（Google Sheets Charts API統合）"""
        charts_requests = []

        # 1. 円グラフ: ドメイン別進捗
        pie_chart_request = {
            "addChart": {
                "chart": {
                    "spec": {
                        "title": "ドメイン別テスト進捗",
                        "pieChart": {
                            "legendPosition": "RIGHT_LEGEND",
                            "domain": {
                                "sourceRange": {
                                    "sources": [
                                        {
                                            "sheetId": worksheet["properties"][
                                                "sheetId"
                                            ],
                                            "startRowIndex": 3,
                                            "endRowIndex": 10,
                                            "startColumnIndex": 0,
                                            "endColumnIndex": 1,
                                        }
                                    ]
                                }
                            },
                            "series": {
                                "sourceRange": {
                                    "sources": [
                                        {
                                            "sheetId": worksheet["properties"][
                                                "sheetId"
                                            ],
                                            "startRowIndex": 3,
                                            "endRowIndex": 10,
                                            "startColumnIndex": 5,
                                            "endColumnIndex": 6,
                                        }
                                    ]
                                }
                            },
                        },
                    },
                    "position": {
                        "overlayPosition": {
                            "anchorCell": {
                                "sheetId": worksheet["properties"]["sheetId"],
                                "rowIndex": 1,
                                "columnIndex": 8,
                            },
                            "offsetXPixels": 0,
                            "offsetYPixels": 0,
                            "widthPixels": 400,
                            "heightPixels": 300,
                        }
                    },
                }
            }
        }
        charts_requests.append(pie_chart_request)

        # 2. 棒グラフ: 優先度別分布
        bar_chart_request = {
            "addChart": {
                "chart": {
                    "spec": {
                        "title": "優先度別テスト分布",
                        "basicChart": {
                            "chartType": "COLUMN",
                            "legendPosition": "BOTTOM_LEGEND",
                            "axis": [
                                {"position": "BOTTOM_AXIS", "title": "優先度"},
                                {"position": "LEFT_AXIS", "title": "テスト数"},
                            ],
                            "domains": [
                                {
                                    "domain": {
                                        "sourceRange": {
                                            "sources": [
                                                {
                                                    "sheetId": worksheet["properties"][
                                                        "sheetId"
                                                    ],
                                                    "startRowIndex": 34,
                                                    "endRowIndex": 39,
                                                    "startColumnIndex": 0,
                                                    "endColumnIndex": 1,
                                                }
                                            ]
                                        }
                                    }
                                }
                            ],
                            "series": [
                                {
                                    "series": {
                                        "sourceRange": {
                                            "sources": [
                                                {
                                                    "sheetId": worksheet["properties"][
                                                        "sheetId"
                                                    ],
                                                    "startRowIndex": 34,
                                                    "endRowIndex": 39,
                                                    "startColumnIndex": 1,
                                                    "endColumnIndex": 2,
                                                }
                                            ]
                                        }
                                    },
                                    "targetAxis": "LEFT_AXIS",
                                }
                            ],
                        },
                    },
                    "position": {
                        "overlayPosition": {
                            "anchorCell": {
                                "sheetId": worksheet["properties"]["sheetId"],
                                "rowIndex": 15,
                                "columnIndex": 8,
                            },
                            "offsetXPixels": 0,
                            "offsetYPixels": 0,
                            "widthPixels": 400,
                            "heightPixels": 300,
                        }
                    },
                }
            }
        }
        charts_requests.append(bar_chart_request)

        return charts_requests

    def _add_dashboard_charts(self, sheet_name: str, categorized_tests: Dict):
        """ダッシュボードにチャートを追加"""
        try:
            # シート情報を取得
            spreadsheet = (
                self.service.spreadsheets()
                .get(spreadsheetId=self.spreadsheet_id)
                .execute()
            )

            dashboard_sheet = None
            for sheet in spreadsheet["sheets"]:
                if sheet["properties"]["title"] == sheet_name:
                    dashboard_sheet = sheet
                    break

            if not dashboard_sheet:
                print(f"Warning: ダッシュボードシート '{sheet_name}' が見つかりません")
                return

            # チャートリクエストを生成
            chart_requests = self.create_progress_charts(
                dashboard_sheet, categorized_tests
            )

            # チャートを追加
            if chart_requests:
                self.service.spreadsheets().batchUpdate(
                    spreadsheetId=self.spreadsheet_id, body={"requests": chart_requests}
                ).execute()
                print("📊 チャートを追加しました")

        except Exception as e:
            print(f"Warning: チャート追加中にエラーが発生しました: {e}")
            # チャート追加は失敗しても続行

    def _update_dashboard_sheet(self, sheet_name: str, rows: List[List]):
        """ダッシュボードシートを更新"""
        # データを書き込み
        range_name = f"{sheet_name}!A:Z"
        body = {"values": rows, "majorDimension": "ROWS"}

        # 既存データをクリア
        self.service.spreadsheets().values().clear(
            spreadsheetId=self.spreadsheet_id, range=range_name
        ).execute()

        # 新しいデータを書き込み
        self.service.spreadsheets().values().update(
            spreadsheetId=self.spreadsheet_id,
            range=range_name,
            valueInputOption="RAW",
            body=body,
        ).execute()

        # ダッシュボード専用フォーマットを適用
        self._apply_dashboard_formatting(sheet_name, len(rows))

    def _apply_dashboard_formatting(self, sheet_name: str, row_count: int):
        """ダッシュボード専用フォーマットを適用"""
        # シートIDを取得
        spreadsheet = (
            self.service.spreadsheets().get(spreadsheetId=self.spreadsheet_id).execute()
        )

        sheet_id = None
        for sheet in spreadsheet["sheets"]:
            if sheet["properties"]["title"] == sheet_name:
                sheet_id = sheet["properties"]["sheetId"]
                break

        if sheet_id is None:
            return

        requests = []

        # タイトル行のフォーマット（A1セル）
        requests.append(
            {
                "repeatCell": {
                    "range": {
                        "sheetId": sheet_id,
                        "startRowIndex": 0,
                        "endRowIndex": 1,
                        "startColumnIndex": 0,
                        "endColumnIndex": 10,
                    },
                    "cell": {
                        "userEnteredFormat": {
                            "backgroundColor": {"red": 0.2, "green": 0.4, "blue": 0.8},
                            "textFormat": {
                                "bold": True,
                                "fontSize": 16,
                                "foregroundColor": {"red": 1, "green": 1, "blue": 1},
                            },
                            "horizontalAlignment": "CENTER",
                        }
                    },
                    "fields": "userEnteredFormat",
                }
            }
        )

        # セクションヘッダーのフォーマット（📈、🎯などの行）
        header_rows = [2, 10, 18, 25, 33]  # セクションヘッダー行番号（概算）
        for row_idx in header_rows:
            if row_idx < row_count:
                requests.append(
                    {
                        "repeatCell": {
                            "range": {
                                "sheetId": sheet_id,
                                "startRowIndex": row_idx,
                                "endRowIndex": row_idx + 1,
                                "startColumnIndex": 0,
                                "endColumnIndex": 10,
                            },
                            "cell": {
                                "userEnteredFormat": {
                                    "backgroundColor": {
                                        "red": 0.9,
                                        "green": 0.9,
                                        "blue": 0.9,
                                    },
                                    "textFormat": {"bold": True, "fontSize": 14},
                                    "horizontalAlignment": "LEFT",
                                }
                            },
                            "fields": "userEnteredFormat",
                        }
                    }
                )

        # バッチ更新実行
        if requests:
            self.service.spreadsheets().batchUpdate(
                spreadsheetId=self.spreadsheet_id, body={"requests": requests}
            ).execute()

    def _ensure_sheet_exists(self, sheet_name: str):
        """シートの存在確認・作成"""
        try:
            spreadsheet = (
                self.service.spreadsheets()
                .get(spreadsheetId=self.spreadsheet_id)
                .execute()
            )

            existing_sheets = [
                sheet["properties"]["title"] for sheet in spreadsheet["sheets"]
            ]

            if sheet_name not in existing_sheets:
                print(f"シート '{sheet_name}' を作成中...")

                request_body = {
                    "requests": [{"addSheet": {"properties": {"title": sheet_name}}}]
                }

                self.service.spreadsheets().batchUpdate(
                    spreadsheetId=self.spreadsheet_id, body=request_body
                ).execute()

                print(f"シート '{sheet_name}' を作成しました")

        except HttpError as e:
            print(f"シート確認エラー: {e}")
            raise


def main():
    """メイン関数"""
    parser = argparse.ArgumentParser(
        description="Enhanced test metadata sync to Google Sheets"
    )
    parser.add_argument(
        "--test-dir",
        default="apps/backend/app/tests",
        help="Directory containing test files",
    )
    parser.add_argument(
        "--credentials", help="Path to Google service account credentials JSON file"
    )
    parser.add_argument("--spreadsheet-id", help="Google Spreadsheet ID")
    parser.add_argument(
        "--secret-arn", help="AWS Secret Manager ARN for test sheets configuration"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Dry run mode - don't actually update the spreadsheet",
    )

    args = parser.parse_args()

    # 認証情報の取得
    secret_arn = args.secret_arn or os.getenv("TEST_SHEETS_SECRET_ARN")
    credentials_path = args.credentials or os.getenv("GOOGLE_SHEETS_CREDENTIALS_PATH")
    spreadsheet_id = args.spreadsheet_id or os.getenv("TEST_SPREADSHEET_ID")

    # Secret Manager優先、次にファイルパス
    if secret_arn:
        print(f"AWS Secret Managerから認証情報を取得: {secret_arn}")
        synchronizer = EnhancedTestSheetsSynchronizer(
            secret_arn=secret_arn, spreadsheet_id=spreadsheet_id
        )
    elif credentials_path:
        if not Path(credentials_path).exists():
            print(f"Error: 認証ファイルが見つかりません: {credentials_path}")
            sys.exit(1)

        if not spreadsheet_id:
            print("Error: スプレッドシートIDが指定されていません")
            sys.exit(1)

        print(f"ファイルから認証情報を取得: {credentials_path}")
        synchronizer = EnhancedTestSheetsSynchronizer(
            credentials_path=credentials_path, spreadsheet_id=spreadsheet_id
        )
    else:
        print("Error: 認証情報が指定されていません")
        sys.exit(1)

    try:
        # テストメタデータ収集
        print("テストメタデータを収集中...")
        collector = TestMetadataCollector(args.test_dir)
        pytest_test_cases = collector.collect_metadata()
        print(f"pytestテスト: {len(pytest_test_cases)} 件")

        print("DocDDテストメタデータを収集中...")
        ts_root = os.getenv("DOCDD_TS_ROOT", "docs/7-axis/7_TC")
        traceability_root = os.getenv(
            "DOCDD_TRACEABILITY_ROOT", "docs/testing/traceability"
        )
        docdd_collector = DocDDTestCollector(
            ts_root=ts_root, traceability_root=traceability_root
        )
        docdd_test_cases = docdd_collector.collect_tests()
        print(f"DocDDテスト: {len(docdd_test_cases)} 件")

        test_cases = merge_test_metadata(pytest_test_cases, docdd_test_cases)

        if not test_cases:
            print("テストケースが見つかりませんでした")
            sys.exit(0)

        print(f"統合後: {len(test_cases)} 件のテストケース")

        # テストケースのカテゴライズ
        print("テストケースをカテゴライズ中...")
        categorized_tests = synchronizer.categorize_tests(test_cases)

        # 改良版シート作成
        synchronizer.create_enhanced_sheets(categorized_tests, dry_run=args.dry_run)

        # 概要ダッシュボード作成
        if not args.dry_run:
            synchronizer.create_overview_dashboard(categorized_tests)

        # 結果表示
        print("\n=== 改良版シート作成結果 ===")
        for category_key, category_data in categorized_tests.items():
            total_tests = sum(
                len(category_data[level])
                for level in ["backend_unit", "backend_integration", "frontend_e2e"]
            )
            if total_tests > 0:
                print(f"{category_data['name']}: {total_tests} 件")

        if not args.dry_run:
            print(
                f"\nスプレッドシートURL: https://docs.google.com/spreadsheets/d/{synchronizer.spreadsheet_id}"
            )

    except KeyboardInterrupt:
        print("\n❌ 処理が中断されました")
        sys.exit(1)
    except ValueError as e:
        print(f"❌ 設定エラー: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ 予期しないエラーが発生しました: {e}")
        print("💡 トラブルシューティング:")
        print("   1. 環境チェック: scripts/test/auto_sync_test_sheets.sh --check-only")
        print("   2. 詳細ログ: scripts/test/auto_sync_test_sheets.sh --verbose")
        print(
            "   3. セットアップ再実行: scripts/test/auto_sync_test_sheets.sh --setup-only"
        )
        sys.exit(1)


if __name__ == "__main__":
    main()
