from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "ingest_pdrm_alerts.py"
spec = spec_from_file_location("ingest_pdrm_alerts", SCRIPT)
module = module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(module)


def test_parser_keeps_only_official_pdrm_links_and_classifies_job_scam():
    html = """
    <div>
      <a href="https://www.rmp.gov.my/news-detail/2026/04/26/scam-alert-job">SCAM ALERT: PENIPUAN TAWARAN PEKERJAAN SAMBILAN</a>
      Apr 26, 2026 Kes penipuan tawaran pekerjaan sambilan dilaporkan.
    </div>
    <div>
      <a href="https://evil.example/scam">Fake external story</a>
    </div>
    """

    records = module.parse_pdrm_alert_listing(html)

    assert len(records) == 1
    assert records[0]["agency"] == "PDRM"
    assert records[0]["category"] == "job-scam"
    assert records[0]["source_url"].startswith("https://www.rmp.gov.my/")


def test_parser_classifies_impersonation():
    html = """
    <article>
      <a href="/news-detail/2026/07/28/pdrm-pesan">PDRM PESAN: SCAMMER MENYAMAR SEBAGAI BANK NEGARA</a>
      Jul 28, 2026 Jangan buat bayaran deposit keselamatan.
    </article>
    """

    records = module.parse_pdrm_alert_listing(html)

    assert records[0]["category"] == "impersonation-and-social-engineering"
    assert records[0]["published_at"] == "Jul 28, 2026"
