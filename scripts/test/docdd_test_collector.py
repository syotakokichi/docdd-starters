#!/usr/bin/env python3
"""
DocDD テストケース収集クラス

TS-*.md と traceability map (*.json) からテストケース定義を抽出し、
トレーサビリティ検証やテスト管理で扱いやすいメタデータ形式に変換する。
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

try:
    import yaml
except ImportError as exc:
    raise ImportError(
        "PyYAML is required to parse DocDD frontmatter. "
        "Install it via `pip install pyyaml` or `pip install -r scripts/test/requirements.txt`."
    ) from exc


class DocDDTestCollector:
    """DocDD (7-axis) のテスト設計書からメタデータを収集"""

    def __init__(
        self,
        ts_root: str = "docs/7-axis/7_TC",
        traceability_root: str = "docs/testing/traceability",
    ):
        self.project_root = Path(__file__).resolve().parents[2]
        ts_root_path = Path(ts_root)
        traceability_root_path = Path(traceability_root)

        if not ts_root_path.is_absolute():
            ts_root_path = (self.project_root / ts_root_path).resolve()
        if not traceability_root_path.is_absolute():
            traceability_root_path = (
                self.project_root / traceability_root_path
            ).resolve()

        self.ts_root = ts_root_path
        self.traceability_root = traceability_root_path

        if not self.ts_root.exists():
            raise ValueError(f"Test specification directory not found: {ts_root}")

    def collect_tests(self) -> List[Dict[str, Any]]:
        """TSドキュメントとtraceability mapからテストケースを収集"""
        test_cases: List[Dict[str, Any]] = []

        # 再帰的に TS-*.md を検索（frontend/ux/, backend/monitoring/, payment/ など）
        for ts_file in sorted(self.ts_root.rglob("TS-*.md")):
            frontmatter = self._parse_frontmatter(ts_file)
            if not frontmatter:
                continue

            domain = (frontmatter.get("domain") or "unknown").lower()
            tc_ids = frontmatter.get("tc_defines") or []
            if not tc_ids:
                continue

            traceability_map = self._load_traceability_map(domain)
            mappings = traceability_map.get("mappings", {})
            document_refs = traceability_map.get("document_references", {})

            ts_id = frontmatter.get("test_id")
            ts_ref = document_refs.get(ts_id, {}) if ts_id else {}
            ts_title = ts_ref.get("title", frontmatter.get("title"))

            for tc_id in tc_ids:
                trace_info = mappings.get(tc_id, {}) or {}
                test_cases.append(
                    self._build_test_case(
                        ts_file=ts_file,
                        ts_id=ts_id or ts_file.stem,
                        ts_title=ts_title,
                        domain=domain,
                        frontmatter=frontmatter,
                        tc_id=tc_id,
                        trace_info=trace_info,
                    )
                )

        return test_cases

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _parse_frontmatter(self, file_path: Path) -> Optional[Dict[str, Any]]:
        """Markdownファイル冒頭のfrontmatterを抽出"""
        content = file_path.read_text(encoding="utf-8")
        match = re.match(r"^---\s*\n(.*?)\n---\s*", content, re.DOTALL)
        if not match:
            return None

        frontmatter_text = match.group(1)
        try:
            data = yaml.safe_load(frontmatter_text) or {}
            if not isinstance(data, dict):
                return None
            return data
        except yaml.YAMLError:
            return None

    def _load_traceability_map(self, domain: str) -> Dict[str, Any]:
        """ドメイン別トレーサビリティマップを読み込む"""
        map_path = self.traceability_root / f"{domain}_map.json"
        if not map_path.exists():
            return {}

        try:
            return json.loads(map_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            return {}

    def _build_test_case(
        self,
        ts_file: Path,
        ts_id: str,
        ts_title: Optional[str],
        domain: str,
        frontmatter: Dict[str, Any],
        tc_id: str,
        trace_info: Dict[str, Any],
    ) -> Dict[str, Any]:
        """TSファイルとトレーサビリティ情報からテストケースを生成"""
        description = trace_info.get("description") or tc_id
        pytest_id = trace_info.get("pytest_id", "")
        default_priority = frontmatter.get("priority", "")

        test_case: Dict[str, Any] = {
            "source": "docdd",
            "case_id": tc_id,
            "tc_id": tc_id,
            "function_name": pytest_id or tc_id.lower().replace("-", "_"),
            "docstring": description,
            "file_path": str(ts_file),
            "line_number": 0,
            "priority": default_priority,
            "markers": ["docdd", domain],
            "domain": domain,
            "br_ids": self._ensure_list(trace_info.get("br")),
            "uc_ids": self._ensure_list(trace_info.get("uc")),
            "dm_ids": self._ensure_list(trace_info.get("dm")),
            "sr_ids": self._ensure_list(trace_info.get("sr")),
            "nsr_ids": self._ensure_list(trace_info.get("nsr")),
            "ext_ids": self._ensure_list(trace_info.get("ext")),
            "api_ids": self._ensure_list(trace_info.get("api")),
            "pytest_id": pytest_id,
            "ts_document": ts_title or ts_id,
            "ts_path": str(ts_file),
            "test_level_override": self._infer_test_level(domain, trace_info),
            "status_hint": self._infer_status(tc_id, pytest_id),
        }

        return test_case

    def _infer_test_level(self, domain: str, trace_info: Dict[str, Any]) -> str:
        """ドメイン/トレーサビリティ情報からテストレイヤを推測"""
        if domain == "ux":
            # UXはフロントエンド視点をデフォルトにする
            return "frontend_e2e"

        # APIが指定されている場合は統合テスト扱い
        api_ids = self._ensure_list(trace_info.get("api"))
        if api_ids:
            return "backend_integration"

        return "backend_unit"

    def _infer_status(self, tc_id: str, pytest_id: str) -> str:
        """DocDDテストケースのステータスを推測"""
        return "Pending"

    def _ensure_list(self, value: Any) -> List[str]:
        if isinstance(value, list):
            return [str(v) for v in value]
        if isinstance(value, str):
            return [value]
        return []


__all__ = ["DocDDTestCollector"]
