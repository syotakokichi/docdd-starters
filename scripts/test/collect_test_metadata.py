#!/usr/bin/env python3
"""
テストケース情報を収集してCSV/JSON形式で出力

使用方法:
    python collect_test_metadata.py [--format csv|json|both] [--output-dir ./output]
"""
import argparse
import ast
import csv
import json
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
from datetime import datetime


class TestMetadataCollector:
    """pytest テストからメタデータを収集するクラス"""

    def __init__(self, test_dir: str = "apps/backend/app/tests"):
        self.project_root = Path(__file__).resolve().parents[2]
        test_dir_path = Path(test_dir)
        if not test_dir_path.is_absolute():
            test_dir_path = (self.project_root / test_dir_path).resolve()

        self.test_dir = test_dir_path
        if not self.test_dir.exists():
            raise ValueError(f"Test directory not found: {test_dir}")

    def collect_metadata(self) -> List[Dict[str, Any]]:
        """pytest --collect-only を使用してテスト情報を収集（全テスト展開後）"""
        print(f"Collecting test metadata from {self.test_dir}...")

        # まずpytestでパラメータ化展開後の全テストを収集
        cmd = [
            sys.executable,
            "-m",
            "pytest",
            "--collect-only",
            "-q",
            "--no-header",
            str(self.test_dir),
        ]

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=False)
            if result.returncode != 0 and "no tests collected" not in result.stdout:
                print(
                    f"Warning: pytest returned non-zero exit code: {result.returncode}"
                )
                # stderr は冗長なので出力しない
        except Exception as e:
            print(f"Error running pytest: {e}")
            return []

        # pytest 出力をパースして展開後のテストIDを取得
        pytest_tests = self._parse_pytest_output(result.stdout)
        print(f"Found {len(pytest_tests)} tests from pytest (including parametrized)")

        # AST パーサーで追加メタデータ（マーカー、docstring等）を抽出
        ast_metadata = self._parse_collection_output(result.stdout)

        # pytestテストとASTメタデータをマージ
        return self._merge_pytest_and_ast_metadata(pytest_tests, ast_metadata)

    def _parse_pytest_output(self, output: str) -> List[Dict[str, Any]]:
        """pytest --collect-only の出力から全テスト（パラメータ化展開後）を抽出"""
        test_cases = []
        current_module = ""
        current_class = ""

        for line in output.split('\n'):
            line = line.strip()

            # <Module test_xxx.py> の行からモジュール名を取得
            if line.startswith("<Module ") and line.endswith(">"):
                current_module = line[8:-1]  # "<Module " と ">" を除去
                current_class = ""

            # <Class TestXXX> の行からクラス名を取得
            elif line.startswith("<Class ") and line.endswith(">"):
                current_class = line[7:-1]  # "<Class " と ">" を除去

            # <Function test_xxx> の行からテスト関数を取得
            elif line.startswith("<Function ") and line.endswith(">"):
                function_name = line[10:-1]  # "<Function " と ">" を除去

                # テストケース情報を構築
                if current_class:
                    test_name = f"{current_class}::{function_name}"
                else:
                    test_name = function_name

                test_cases.append({
                    "file_path": current_module,
                    "class_name": current_class,
                    "function_name": function_name,
                    "test_name": test_name,
                    "case_id": "",
                    "priority": "",
                    "category": "",
                    "related": "",
                    "markers": [],
                    "docstring": "",
                    "status": "implemented",
                    "last_updated": datetime.now().isoformat(),
                    "line_number": 0,  # pytest出力には含まれない
                })

        return test_cases

    def _parse_collection_output(self, output: str) -> List[Dict[str, Any]]:
        """pytest collection 出力をパース（AST経由でマーカー情報を取得）"""
        test_cases = []

        # 直接ファイルを探してパース
        for test_file in self.test_dir.rglob("test_*.py"):
            if "__pycache__" not in str(test_file):
                file_tests = self._extract_tests_from_file(str(test_file))
                test_cases.extend(file_tests)

        return test_cases

    def _merge_pytest_and_ast_metadata(
        self, pytest_tests: List[Dict], ast_tests: List[Dict]
    ) -> List[Dict[str, Any]]:
        """pytestテスト（展開後）とASTメタデータ（マーカー付き）をマージ"""
        # AST側を関数名でインデックス
        ast_index = {}
        for ast_test in ast_tests:
            key = ast_test.get("function_name")
            if key:
                ast_index[key] = ast_test

        # pytestテストにASTメタデータをマージ
        merged = []
        for pytest_test in pytest_tests:
            func_name = pytest_test.get("function_name", "")

            # パラメータ化されたテスト名から元の関数名を抽出
            # 例: "test_foo[param1]" → "test_foo"
            base_func_name = func_name.split('[')[0] if '[' in func_name else func_name

            # ASTメタデータがあればマージ
            if base_func_name in ast_index:
                ast_data = ast_index[base_func_name]
                pytest_test.update({
                    "case_id": ast_data.get("case_id", ""),
                    "priority": ast_data.get("priority", ""),
                    "category": ast_data.get("category", ""),
                    "related": ast_data.get("related", ""),
                    "markers": ast_data.get("markers", []),
                    "docstring": ast_data.get("docstring", ""),
                    "line_number": ast_data.get("line_number", 0),
                    "markers_summary": ast_data.get("markers_summary", ""),
                })
                # file_pathを完全パスに更新
                if ast_data.get("file_path"):
                    pytest_test["file_path"] = ast_data["file_path"]
            else:
                # ASTメタデータがない場合もデフォルト値を設定
                pytest_test["markers_summary"] = "❌ マーカー未設定"

            merged.append(pytest_test)

        return merged

    def _extract_tests_from_file(self, file_path: str) -> List[Dict[str, Any]]:
        """ファイルから個別のテスト情報を抽出"""
        tests = []
        full_path = Path(file_path)

        if not full_path.exists():
            # 相対パスの場合は test_dir からの相対パスとして解決
            full_path = self.test_dir / file_path

        if not full_path.exists():
            print(f"Warning: Test file not found: {file_path}")
            return tests

        try:
            with open(full_path, "r", encoding="utf-8") as f:
                tree = ast.parse(f.read(), filename=str(full_path))

            # ASTを走査してテスト関数を探す
            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef) and node.name.startswith("test_"):
                    test_info = self._extract_test_info(node, str(full_path))
                    if test_info:
                        tests.append(test_info)
                elif isinstance(node, ast.ClassDef) and node.name.startswith("Test"):
                    # テストクラス内のメソッドも探す
                    for item in node.body:
                        if isinstance(item, ast.FunctionDef) and item.name.startswith(
                            "test_"
                        ):
                            test_info = self._extract_test_info(
                                item, str(full_path), class_name=node.name
                            )
                            if test_info:
                                tests.append(test_info)

        except Exception as e:
            print(f"Error parsing {file_path}: {e}")

        return tests

    def _extract_test_info(
        self, node: ast.FunctionDef, file_path: str, class_name: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """AST ノードからテスト情報を抽出"""
        test_info = {
            "file_path": file_path,
            "class_name": class_name or "",
            "function_name": node.name,
            "line_number": node.lineno,
            "docstring": ast.get_docstring(node) or "",
            "case_id": "",
            "priority": "",
            "category": "",
            "related": "",
            "markers": [],
            "status": "implemented",
            "last_updated": datetime.now().isoformat(),
        }

        # デコレータからマーカー情報を抽出
        for decorator in node.decorator_list:
            marker_info = self._extract_marker_info(decorator)
            if marker_info:
                marker_name, marker_value = marker_info
                if marker_name == "case_id":
                    test_info["case_id"] = marker_value
                elif marker_name == "priority":
                    test_info["priority"] = marker_value
                elif marker_name == "category":
                    test_info["category"] = marker_value
                elif marker_name == "related":
                    test_info["related"] = marker_value

                test_info["markers"].append(marker_name)

        # マーカーリストを適切な形式に変換
        test_info["markers_raw"] = ",".join(test_info["markers"])  # 機械用
        test_info["markers_display"] = " | ".join(test_info["markers"])  # 人間用

        # 後方互換性のため、markers は markers_display と同じ値にする
        test_info["markers"] = test_info["markers_display"]

        # 可読性の高いマーカーサマリーを生成
        test_info["markers_summary"] = self._generate_markers_summary(test_info)

        # テスト名の生成
        if class_name:
            test_info["test_name"] = f"{class_name}::{node.name}"
        else:
            test_info["test_name"] = node.name

        return test_info

    def _extract_marker_info(self, decorator: ast.AST) -> Optional[Tuple[str, str]]:
        """デコレータからマーカー情報を抽出"""
        if isinstance(decorator, ast.Attribute):
            # @pytest.mark.xxx の場合
            if (
                isinstance(decorator.value, ast.Attribute)
                and isinstance(decorator.value.value, ast.Name)
                and decorator.value.value.id == "pytest"
                and decorator.value.attr == "mark"
            ):
                return (decorator.attr, "true")

        elif isinstance(decorator, ast.Call):
            # @pytest.mark.xxx("value") の場合
            if isinstance(decorator.func, ast.Attribute):
                if (
                    isinstance(decorator.func.value, ast.Attribute)
                    and isinstance(decorator.func.value.value, ast.Name)
                    and decorator.func.value.value.id == "pytest"
                    and decorator.func.value.attr == "mark"
                ):
                    marker_name = decorator.func.attr
                    # 引数から値を取得
                    if decorator.args and isinstance(decorator.args[0], ast.Constant):
                        return (marker_name, str(decorator.args[0].value))
                    else:
                        return (marker_name, "true")

        return None

    def _generate_markers_summary(self, test_info: Dict[str, Any]) -> str:
        """可読性の高いマーカーサマリーを生成"""
        summary_parts = []

        # ケースID
        if test_info.get("case_id"):
            summary_parts.append(f"🆔 {test_info['case_id']}")

        # 優先度
        if test_info.get("priority"):
            priority = test_info["priority"]
            priority_icons = {
                "critical": "🔴",
                "high": "🟡",
                "medium": "🟢",
                "low": "🔵",
            }
            icon = priority_icons.get(priority, "❓")
            summary_parts.append(f"{icon} {priority.upper()}")

        # カテゴリ
        if test_info.get("category"):
            category = test_info["category"]
            category_icons = {
                "payment": "💳",
                "auth": "🔐",
                "point": "⭐",
                "store": "🏪",
                "admin": "👥",
                "api": "🔌",
                "unit": "⚙️",
                "integration": "🔗",
                "vgw": "🌐",
            }
            icon = category_icons.get(category, "📋")
            summary_parts.append(f"{icon} {category}")

        # 関連テスト
        if test_info.get("related"):
            related_count = len(test_info["related"].split(","))
            summary_parts.append(f"🔗 関連テスト{related_count}件")

        # マーカーがない場合
        if not summary_parts:
            return "❌ マーカー未設定"

        return " | ".join(summary_parts)

    def export_to_csv(self, test_cases: List[Dict], output_file: str):
        """CSV形式でエクスポート"""
        if not test_cases:
            print("No test cases to export")
            return

        # CSVのヘッダー順序を定義
        fieldnames = [
            "case_id",
            "test_name",
            "markers_summary",
            "file_path",
            "class_name",
            "function_name",
            "line_number",
            "category",
            "priority",
            "related",
            "markers",
            "markers_display",
            "markers_raw",
            "docstring",
            "status",
            "last_updated",
        ]

        with open(output_file, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(test_cases)

        print(f"Exported {len(test_cases)} test cases to {output_file}")

    def export_to_json(self, test_cases: List[Dict], output_file: str):
        """JSON形式でエクスポート"""
        with open(output_file, "w", encoding="utf-8") as f:
            json.dump(test_cases, f, indent=2, ensure_ascii=False)

        print(f"Exported {len(test_cases)} test cases to {output_file}")

    def generate_summary(self, test_cases: List[Dict]) -> Dict[str, Any]:
        """テストケースのサマリー情報を生成"""
        summary = {
            "total_tests": len(test_cases),
            "tests_with_case_id": sum(1 for tc in test_cases if tc.get("case_id")),
            "by_priority": {},
            "by_category": {},
            "by_file": {},
            "coverage_percentage": 0,
        }

        # 優先度別集計
        for tc in test_cases:
            priority = tc.get("priority", "unspecified")
            summary["by_priority"][priority] = (
                summary["by_priority"].get(priority, 0) + 1
            )

        # カテゴリ別集計
        for tc in test_cases:
            category = tc.get("category", "unspecified")
            summary["by_category"][category] = (
                summary["by_category"].get(category, 0) + 1
            )

        # ファイル別集計
        for tc in test_cases:
            file_path = tc.get("file_path", "unknown")
            summary["by_file"][file_path] = summary["by_file"].get(file_path, 0) + 1

        # カバレッジ計算（case_idがあるテストの割合）
        if summary["total_tests"] > 0:
            summary["coverage_percentage"] = (
                summary["tests_with_case_id"] / summary["total_tests"] * 100
            )

        return summary


def main():
    """メイン関数"""
    parser = argparse.ArgumentParser(
        description="Collect test metadata from pytest tests"
    )
    parser.add_argument(
        "--test-dir",
        default="apps/backend/app/tests",
        help="Directory containing test files",
    )
    parser.add_argument(
        "--format",
        choices=["csv", "json", "both"],
        default="both",
        help="Output format",
    )
    parser.add_argument(
        "--output-dir", default=".", help="Output directory for generated files"
    )
    parser.add_argument(
        "--summary", action="store_true", help="Generate summary report"
    )

    args = parser.parse_args()

    # 出力ディレクトリ作成
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # コレクター初期化
    try:
        collector = TestMetadataCollector(args.test_dir)
    except ValueError as e:
        print(f"Error: {e}")
        sys.exit(1)

    # メタデータ収集
    test_cases = collector.collect_metadata()

    if not test_cases:
        print("No test cases found")
        sys.exit(0)

    # タイムスタンプ付きファイル名
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    # エクスポート
    if args.format in ["csv", "both"]:
        csv_file = output_dir / f"test_cases_{timestamp}.csv"
        collector.export_to_csv(test_cases, str(csv_file))

    if args.format in ["json", "both"]:
        json_file = output_dir / f"test_cases_{timestamp}.json"
        collector.export_to_json(test_cases, str(json_file))

    # サマリー生成
    if args.summary:
        summary = collector.generate_summary(test_cases)
        summary_file = output_dir / f"test_summary_{timestamp}.json"
        with open(summary_file, "w", encoding="utf-8") as f:
            json.dump(summary, f, indent=2, ensure_ascii=False)

        print("\n=== Test Summary ===")
        print(f"Total tests: {summary['total_tests']}")
        print(
            f"Tests with case ID: {summary['tests_with_case_id']} "
            f"({summary['coverage_percentage']:.1f}%)"
        )
        print("\nBy Priority:")
        for priority, count in summary["by_priority"].items():
            print(f"  {priority}: {count}")
        print("\nBy Category:")
        for category, count in summary["by_category"].items():
            print(f"  {category}: {count}")


if __name__ == "__main__":
    main()
