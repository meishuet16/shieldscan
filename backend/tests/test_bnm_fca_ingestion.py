from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path

SCRIPT_PATH = Path(__file__).resolve().parents[1] / "scripts" / "ingest_bnm_fca.py"
spec = spec_from_file_location("ingest_bnm_fca", SCRIPT_PATH)
module = module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(module)


def test_parser_extracts_entity_provenance_without_following_reported_links():
    html = """
    <table>
      <tr><th>Name of unauthorised entities/individual</th><th>Website</th><th>Date Added to Alert List</th></tr>
      <tr>
        <td>Example Capital (potential clone entity)</td>
        <td><a href="https://example.invalid/scam">Website</a></td>
        <td>3 Aug 2026</td>
      </tr>
    </table>
    """

    records = module.parse_bnm_fca_html(html)

    assert len(records) == 1
    record = records[0]
    assert record["category"] == "clone-entity"
    assert record["agency"] == "BNM"
    assert record["source_url"] == module.SOURCE_URL
    assert record["published_at"] == "3 Aug 2026"
    assert record["reported_channels"] == ["https://example.invalid/scam"]


def test_merge_replaces_same_record_id_instead_of_duplication():
    existing = [{"id": "BNM-FCA-EXAMPLE", "title": "Old"}]
    incoming = [{"id": "BNM-FCA-EXAMPLE", "title": "New"}]

    merged = module.merge_records(existing, incoming)

    assert len(merged) == 1
    assert merged[0]["title"] == "New"
