import unittest

from app.services.url_intelligence import analyze_url, url_signal_score
from app.services.risk_engine import score_to_level
from app.models.scan import ThreatLevel


class UrlIntelligenceTests(unittest.TestCase):
    def test_official_maybank_domain_is_not_flagged_for_impersonation(self):
        signals = analyze_url("https://www.maybank2u.com.my/home/m2u/common/login.do")
        codes = {signal.code for signal in signals}
        self.assertNotIn("brand_impersonation", codes)

    def test_fake_maybank_domain_is_flagged(self):
        signals = analyze_url("https://maybank2u-secure-login.xyz/verify/account")
        codes = {signal.code for signal in signals}
        self.assertIn("brand_impersonation", codes)
        self.assertIn("suspicious_tld", codes)
        self.assertIn("credential_bait_path", codes)
        self.assertGreaterEqual(url_signal_score(signals), 50)

    def test_raw_ip_is_flagged(self):
        signals = analyze_url("http://192.0.2.10/login/verify")
        codes = {signal.code for signal in signals}
        self.assertIn("ip_hostname", codes)
        self.assertIn("no_https", codes)

    def test_malformed_port_becomes_evidence_instead_of_exception(self):
        signals = analyze_url("https://example.com:99999/login")
        codes = {signal.code for signal in signals}
        self.assertIn("invalid_port", codes)

    def test_score_thresholds(self):
        self.assertEqual(score_to_level(10), ThreatLevel.SAFE)
        self.assertEqual(score_to_level(25), ThreatLevel.LOW)
        self.assertEqual(score_to_level(45), ThreatLevel.MEDIUM)
        self.assertEqual(score_to_level(70), ThreatLevel.HIGH)
        self.assertEqual(score_to_level(90), ThreatLevel.CRITICAL)


if __name__ == "__main__":
    unittest.main()
