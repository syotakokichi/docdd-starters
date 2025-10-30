#!/usr/bin/env python3
"""
トレーサビリティマップの妥当性検証スクリプト

トレーサビリティマッピングが正しく設定されているか検証します。
- 必須フィールドの存在確認
- 空配列のチェック
- 参照IDの実在性確認
- 複数のマップタイプ（監視、フロントエンド等）に対応
"""

import json
import sys
from pathlib import Path
from typing import Dict, List, Set, Optional


class TraceabilityValidator:
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.errors: List[str] = []
        self.warnings: List[str] = []
        self.validated_ids: Set[str] = set()
        self.map_type: Optional[str] = None

    def validate(self, map_file: Path) -> bool:
        """トレーサビリティマップを検証"""
        if not hasattr(self, "quiet"):
            self.quiet = False
        if not self.quiet:
            print(f"🔍 トレーサビリティマップの検証開始: {map_file}")

        # JSONファイルの読み込み
        try:
            with open(map_file, "r", encoding="utf-8") as f:
                data = json.load(f)
        except FileNotFoundError:
            self.errors.append(f"❌ マップファイルが見つかりません: {map_file}")
            return False
        except json.JSONDecodeError as e:
            self.errors.append(f"❌ JSON解析エラー: {e}")
            return False

        # マップタイプの判定
        self.map_type = self._determine_map_type(data, map_file)
        if not self.quiet:
            print(f"📋 マップタイプ: {self.map_type}")

        # スキーマ検証
        if not self._validate_schema(data):
            return False

        # マッピング検証（マップタイプに応じて分岐）
        if self.map_type == "monitoring":
            mappings = data.get("mappings", {})
            for tc_id, mapping in mappings.items():
                self._validate_monitoring_mapping(tc_id, mapping)
        elif self.map_type == "frontend":
            self._validate_frontend_map(data)
        else:
            self.warnings.append(f"⚠️  未知のマップタイプです: {self.map_type}")

        # 検証結果を返す
        return len(self.errors) == 0

    def _determine_map_type(self, data: Dict, map_file: Path) -> str:
        """マップファイルのタイプを判定"""
        # ファイル名から判定
        if "monitoring" in map_file.name:
            return "monitoring"
        elif "frontend" in map_file.name:
            return "frontend"

        # データ構造から判定
        if "mappings" in data and all(
            isinstance(v, dict)
            and any(k in v for k in ["br", "uc", "dm", "sr", "nsr", "ext", "api"])
            for v in data["mappings"].values()
        ):
            return "monitoring"
        elif "components" in data:
            return "frontend"

        return "unknown"

    def _validate_schema(self, data: Dict) -> bool:
        """JSONスキーマの基本構造を検証"""
        if self.map_type == "monitoring":
            required_fields = ["mappings"]
            for field in required_fields:
                if field not in data:
                    self.errors.append(f"❌ 必須フィールド '{field}' がありません")
                    return False

            if not isinstance(data["mappings"], dict):
                self.errors.append("❌ 'mappings' はオブジェクトである必要があります")
                return False

        elif self.map_type == "frontend":
            required_fields = ["domain", "components"]
            for field in required_fields:
                if field not in data:
                    self.errors.append(f"❌ 必須フィールド '{field}' がありません")
                    return False

        return True

    def _validate_frontend_map(self, data: Dict) -> None:
        """フロントエンドマップの検証"""
        if not self.quiet:
            print("  🎨 フロントエンドマップを検証中...")

        # 基本メタデータの確認
        required_meta = ["domain", "description", "phase", "created_date"]
        for field in required_meta:
            if field not in data:
                self.errors.append(f"❌ メタデータ '{field}' がありません")

        # コンポーネントの検証
        components = data.get("components", {})
        if not isinstance(components, dict):
            self.errors.append("❌ 'components' はオブジェクトである必要があります")
            return

        for comp_name, component in components.items():
            self._validate_frontend_component(comp_name, component)

        # トレーサビリティの検証
        if "traceability" in data:
            traceability = data["traceability"]
            if "issue" not in traceability:
                self.warnings.append("⚠️  トレーサビリティにissueが指定されていません")

        # バリデーション設定の確認
        if "validation" in data:
            validation = data["validation"]
            if "script" in validation:
                script_path = self.project_root / validation["script"]
                if not script_path.exists():
                    self.warnings.append(
                        f"⚠️  バリデーションスクリプトが見つかりません: {validation['script']}"
                    )

    def _validate_frontend_component(self, comp_name: str, component: Dict) -> None:
        """フロントエンドコンポーネントの検証"""
        if not self.quiet:
            print(f"    🔧 {comp_name} コンポーネントを検証中...")

        # ステータス確認
        if "status" not in component:
            self.warnings.append(f"    ⚠️  {comp_name}: ステータスが指定されていません")
        elif component["status"] not in [
            "completed",
            "in_progress",
            "planned",
            "deprecated",
        ]:
            self.warnings.append(
                f"    ⚠️  {comp_name}: 不正なステータス '{component['status']}'"
            )

        # ファイル存在確認
        if "files" in component:
            files = component["files"]
            if isinstance(files, list):
                for file_path in files:
                    self._validate_frontend_file_existence(comp_name, file_path)
            elif isinstance(files, dict):
                for file_key, file_path in files.items():
                    self._validate_frontend_file_existence(
                        f"{comp_name}/{file_key}", file_path
                    )

        # ディレクトリ構造の確認
        if "directories" in component:
            directories = component["directories"]
            for dir_name, dir_info in directories.items():
                if "files" in dir_info:
                    for file_path in dir_info["files"]:
                        self._validate_frontend_file_existence(
                            f"{comp_name}/{dir_name}", file_path
                        )

        self.validated_ids.add(f"frontend:{comp_name}")

    def _validate_frontend_file_existence(self, context: str, file_path: str) -> None:
        """フロントエンドファイルの存在確認"""
        full_path = self.project_root / file_path
        if not full_path.exists():
            self.errors.append(
                f"    ❌ {context}: ファイルが見つかりません '{file_path}'"
            )
        else:
            self.validated_ids.add(f"file:{file_path}")

    def _validate_monitoring_mapping(self, tc_id: str, mapping: Dict) -> None:
        """個別マッピングの検証"""
        if not hasattr(self, "quiet"):
            self.quiet = False
        if not self.quiet:
            print(f"  📝 {tc_id} を検証中...")

        # 必須フィールドの確認
        required_axes = ["br", "uc", "dm", "sr", "nsr", "ext", "api"]
        for axis in required_axes:
            if axis not in mapping:
                self.errors.append(f"    ❌ {tc_id}: 必須軸 '{axis}' がありません")
                continue

            values = mapping[axis]
            if not isinstance(values, list):
                self.errors.append(
                    f"    ❌ {tc_id}: '{axis}' は配列である必要があります"
                )
                continue

            if len(values) == 0:
                self.warnings.append(f"    ⚠️  {tc_id}: '{axis}' が空配列です")

            # ID存在確認
            for value in values:
                self._validate_id_existence(tc_id, axis, value)

    def _validate_id_existence(self, tc_id: str, axis: str, id_value: str) -> None:
        """IDが実際に存在するか確認"""
        # APIはパス形式なので除外
        if axis == "api":
            # API仕様書の存在確認（簡易版）
            # TODO: OpenAPI仕様書での詳細検証
            return

        # 軸ごとのディレクトリマッピング
        axis_to_path = {
            "br": "7-axis/1_BR",
            "uc": "7-axis/2_UC",
            "dm": "7-axis/3_DM",
            "sr": "7-axis/4_SR",
            "nsr": "7-axis/4_NSR",
            "ext": "7-axis/5_EXT",
        }

        if axis not in axis_to_path:
            return

        base_path = self.project_root / axis_to_path[axis]

        # EXT系の特殊処理
        if axis == "ext":
            file_found = self._check_ext_file(base_path, id_value)
        # SR/NSR系の特殊処理（新しいディレクトリ構造に対応）
        elif axis in ["sr", "nsr"]:
            file_found = self._check_sr_file(base_path, id_value)
        # DM/UC/BR系もサブディレクトリ検索に対応
        elif axis in ["dm", "uc", "br"]:
            # rglob でサブディレクトリも検索
            file_patterns = [
                f"{id_value}.md",
                f"{id_value}.yaml",
                f"{id_value}.yml",
            ]
            file_found = False
            for pattern in file_patterns:
                matches = list(base_path.rglob(pattern))
                if matches:
                    file_found = True
                    break
        else:
            # 通常のIDファイル検索
            file_patterns = [
                f"{id_value}.md",
                f"{id_value}.yaml",
                f"{id_value}.yml",
            ]
            file_found = any(
                (base_path / pattern).exists() for pattern in file_patterns
            )

        if not file_found:
            self.errors.append(
                f"    ❌ {tc_id}/{axis}: ID '{id_value}' に対応するファイルが見つかりません"
            )
        else:
            self.validated_ids.add(f"{axis}:{id_value}")

    def _check_sr_file(self, base_path: Path, sr_id: str) -> bool:
        """SR/NSRファイルの存在確認（7-axis英語ディレクトリ構造対応）"""
        # FR-XXX-YYY or NFR-XXX-YYY 形式からドメインを抽出
        parts = sr_id.split("-")
        if len(parts) >= 2:
            domain = parts[1]  # MON, AUTH, PAY, etc.

            # ドメインごとのディレクトリマッピング（英語名）
            # 7-axis 構造: 7-axis/4_SR/{domain}/FR-XXX-YYY.md
            domain_dirs = {
                "MON": "monitoring",
                "AUTH": "auth",
                "PAY": "payment",
                "CHG": "charge",
                "STORE": "store",
                "SUPP": "supporter",
                "ADMIN": "admin",
                "INFRA": "infrastructure",
                "FRONTEND": "frontend",
                "PERF": "performance",
                "REL": "reliability",
                "SEC": "security",
            }

            # ドメインディレクトリ直下を検索（type_dir レイヤーなし）
            if domain in domain_dirs:
                domain_path = base_path / domain_dirs[domain]
                if domain_path.exists():
                    for ext in [".md", ".yaml", ".yml"]:
                        if (domain_path / f"{sr_id}{ext}").exists():
                            return True

        # フォールバック: rglob で再帰検索
        file_patterns = [f"{sr_id}.md", f"{sr_id}.yaml", f"{sr_id}.yml"]
        for pattern in file_patterns:
            matches = list(base_path.rglob(pattern))
            if matches:
                return True

        return False

    def _check_ext_file(self, base_path: Path, ext_id: str) -> bool:
        """外部連携ファイルの存在確認"""
        # EXT-XXX-YYY 形式からシステム名を抽出
        parts = ext_id.split("-")
        if len(parts) >= 2:
            system = parts[1]  # AWS, VGW, Slack, Grafana など

            # システムごとのディレクトリを確認
            system_dirs = {
                "AWS": "AWS",
                "VGW": "VGW",
                "SBPS": "SBPS",
                "Slack": "Slack",
                "Grafana": "Grafana",
                "Supabase": "Supabase",
            }

            if system in system_dirs:
                system_path = base_path / system_dirs[system]
                if system_path.exists():
                    # サブディレクトリ内のファイルを再帰的に検索
                    for ext in [".md", ".yaml", ".yml"]:
                        pattern = f"{ext_id}*{ext}"
                        matches = list(system_path.glob(pattern))
                        if matches:
                            return True

                    # サブディレクトリがない場合は直下を確認
                    for ext in [".md", ".yaml", ".yml"]:
                        if (base_path / f"{ext_id}{ext}").exists():
                            return True

        return False

    def print_results(self) -> None:
        """結果の出力（外部から呼び出し可能）"""
        self._print_results()

    def _print_results(self) -> None:
        """検証結果の出力"""
        print("\n" + "=" * 60)
        print("📊 検証結果サマリー")
        print("=" * 60)

        if self.warnings:
            print(f"\n⚠️  警告: {len(self.warnings)}件")
            for warning in self.warnings:
                print(warning)

        if self.errors:
            print(f"\n❌ エラー: {len(self.errors)}件")
            for error in self.errors:
                print(error)
        else:
            print("\n✅ エラーなし")

        print(f"\n✅ 検証済みID: {len(self.validated_ids)}件")
        print("=" * 60)


def main():
    """メイン関数"""
    import argparse

    # 引数パーサー設定
    parser = argparse.ArgumentParser(description="トレーサビリティマップの検証")
    parser.add_argument("--quiet", action="store_true", help="詳細出力を抑制")
    parser.add_argument(
        "--map",
        type=str,
        help="検証対象のマップファイルパス（デフォルト: docs/testing/traceability/monitoring_map.json）",
    )
    args = parser.parse_args()

    # プロジェクトルートの特定
    script_path = Path(__file__).resolve()
    project_root = script_path.parent.parent.parent  # scripts/test/.. -> project root

    # トレーサビリティマップファイル
    if args.map:
        # 相対パスをproject_rootからの絶対パスに変換
        if not args.map.startswith("/"):
            map_file = project_root / args.map
        else:
            map_file = Path(args.map)
    else:
        # デフォルトは従来通りmonitoring_map.json
        map_file = project_root / "docs/testing/traceability/monitoring_map.json"

    # バリデーター実行
    validator = TraceabilityValidator(project_root)
    validator.quiet = args.quiet
    is_valid = validator.validate(map_file)

    # quietモードでない場合のみ結果を出力
    if not args.quiet or not is_valid:
        validator.print_results()

    # 終了コード設定（pre-commit用）
    sys.exit(0 if is_valid else 1)


if __name__ == "__main__":
    main()
