# ShieldScan Full Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild ShieldScan into a polished Flutter web fraud intelligence dashboard while preserving its existing FastAPI scan API.

**Architecture:** Keep the backend API shape stable and concentrate the rebuild in the Flutter app. Add focused provider tests before changing state behavior, then rebuild the UI around a scan-first dashboard with stable responsive layouts and complete empty/loading/error/result states.

**Tech Stack:** Flutter Web, Provider, Material 3, FastAPI, Pydantic, Gemini SDK, local RAG fallback.

## Global Constraints

- The primary scope is the Flutter web frontend.
- The backend remains API-compatible, with targeted fixes only where they improve demo stability or resolve obvious inconsistencies.
- Keep bilingual English and Bahasa Malaysia result presentation.
- Keep the existing `/api/scan` and `/api/scan/stream` request and response shape.
- No new paid cloud resources.
- No real PDRM, BNM, MCMC, or Vertex production integration beyond the existing demo stubs.
- No authentication, user accounts, billing, or persistent history.
- Verify with available build, analyze, and test commands.

---

### Task 1: Frontend Provider Hardening

**Files:**
- Create: `frontend/test/scan_provider_test.dart`
- Modify: `frontend/lib/services/scan_provider.dart`

**Interfaces:**
- Consumes: existing `ScanProvider`, `ScanResult`, `ThreatLevel`, `ScanStatus`, and `AgentStep`.
- Produces: public `ScanProvider.handleSseEvent(Map<String, dynamic> data)` for testable SSE state handling.

- [ ] **Step 1: Write failing provider tests**

Create `frontend/test/scan_provider_test.dart` with tests for:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shieldscan/services/scan_provider.dart';

void main() {
  group('ScanResult.fromJson', () {
    test('falls back to medium when threat level is unknown', () {
      final result = ScanResult.fromJson({
        'threat_level': 'unexpected',
        'confidence_score': 71,
        'summary_en': 'Review needed.',
        'summary_bm': 'Semakan diperlukan.',
        'recommendation_en': 'Verify through official channels.',
        'recommendation_bm': 'Sahkan melalui saluran rasmi.',
      });

      expect(result.threatLevel, ThreatLevel.medium);
      expect(result.indicators, isEmpty);
      expect(result.ragMatches, isEmpty);
    });
  });

  group('ScanProvider.handleSseEvent', () {
    test('updates pipeline step labels and durations', () {
      final provider = ScanProvider();
      provider.beginScanSessionForTest();

      provider.handleSseEvent({
        'type': 'step',
        'step': 2,
        'status': 'done',
        'label': 'Gemini analysis complete',
        'duration_ms': 1234,
      });

      expect(provider.agentSteps[1].status, 'done');
      expect(provider.agentSteps[1].label, 'Gemini analysis complete');
      expect(provider.agentSteps[1].durationMs, 1234);
    });

    test('stores SSE errors as user visible state', () {
      final provider = ScanProvider();
      provider.beginScanSessionForTest();

      provider.handleSseEvent({
        'type': 'error',
        'message': 'Analysis failed',
      });

      expect(provider.status, ScanStatus.error);
      expect(provider.errorMessage, 'Analysis failed');
    });

    test('result event increments threat counters for high risk results', () {
      final provider = ScanProvider();
      provider.beginScanSessionForTest();
      final previousScans = provider.totalScansToday;
      final previousThreats = provider.threatsBlocked;

      provider.handleSseEvent({
        'type': 'result',
        'threat_level': 'HIGH',
        'confidence_score': 91,
        'summary_en': 'High risk.',
        'summary_bm': 'Risiko tinggi.',
        'indicators': [],
        'recommendation_en': 'Do not proceed.',
        'recommendation_bm': 'Jangan teruskan.',
        'rag_matches': [],
        'scan_duration_ms': 1400,
      });

      expect(provider.status, ScanStatus.done);
      expect(provider.totalScansToday, previousScans + 1);
      expect(provider.threatsBlocked, previousThreats + 1);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/scan_provider_test.dart`
Expected: FAIL because `beginScanSessionForTest` and `handleSseEvent` are not public.

- [ ] **Step 3: Implement provider hardening**

In `frontend/lib/services/scan_provider.dart`:

- Make `ScanResult.fromJson` tolerate missing or non-string `threat_level`.
- Add `beginScanSessionForTest()` annotated with `@visibleForTesting`.
- Expose SSE handling through `handleSseEvent`.
- Support `type == 'error'`.
- Check HTTP status before consuming stream.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/scan_provider_test.dart`
Expected: PASS.

### Task 2: Rebuild Frontend Design System and Main Layout

**Files:**
- Create: `frontend/lib/theme/app_theme.dart`
- Modify: `frontend/lib/main.dart`
- Modify: `frontend/lib/screens/home_screen.dart`
- Modify: `frontend/lib/widgets/stats_banner.dart`

**Interfaces:**
- Consumes: `ScanProvider` fields `status`, `totalScansToday`, `threatsBlocked`, `result`, and `errorMessage`.
- Produces: a scan-first dashboard layout using existing widgets.

- [ ] **Step 1: Create shared app theme**

Create `frontend/lib/theme/app_theme.dart` with constants for colors, radii, borders, and `ThemeData buildShieldScanTheme()`.

- [ ] **Step 2: Update app bootstrap**

Change `frontend/lib/main.dart` to import `theme/app_theme.dart` and use `buildShieldScanTheme()`.

- [ ] **Step 3: Rebuild home layout**

Change `frontend/lib/screens/home_screen.dart` so the first viewport has:

- a compact top bar with identity and status chip,
- a scan workspace with input on the left and output on the right,
- an empty-state panel when no scan is running,
- dashboard sections below the workspace.

- [ ] **Step 4: Make stats responsive**

Change `frontend/lib/widgets/stats_banner.dart` from a fixed row to a responsive wrap/grid that does not overflow on mobile.

- [ ] **Step 5: Run analyzer**

Run: `flutter analyze`
Expected: no errors.

### Task 3: Polish Scan Input and Result Experience

**Files:**
- Modify: `frontend/lib/widgets/input_panel.dart`
- Modify: `frontend/lib/widgets/agent_steps_panel.dart`
- Modify: `frontend/lib/widgets/result_card.dart`

**Interfaces:**
- Consumes: `ScanProvider.scan`, `ScanProvider.reset`, `ScanStatus`.
- Produces: polished scan controls and complete output states.

- [ ] **Step 1: Improve input controls**

Change `InputPanel` to use segmented Material controls or consistent button-like tabs, remove emoji-dependent button labels, add selected-state clarity, and keep scan disabled while running.

- [ ] **Step 2: Improve pipeline states**

Change `AgentStepsPanel` so pending, running, done, and error states are visually distinct and labels do not overflow.

- [ ] **Step 3: Improve result card**

Change `ResultCard` so language toggle, confidence, indicators, recommendations, scan time, and hotlines are compact and responsive.

- [ ] **Step 4: Run widget/provider tests**

Run: `flutter test`
Expected: PASS.

### Task 4: Backend Demo Stability

**Files:**
- Modify: `backend/app/api/scan.py`
- Modify: `backend/app/services/gemini_service.py`
- Modify: `backend/app/models/scan.py`

**Interfaces:**
- Consumes: existing `ScanRequest`, `ScanResult`, `analyze_fraud`, and `search_rag_database`.
- Produces: API-compatible scan responses with clearer errors and model copy alignment.

- [ ] **Step 1: Align streaming model copy**

Change the stream step label from `Gemini 1.5 Pro multimodal analysis` to `Gemini 2.5 Flash multimodal analysis`.

- [ ] **Step 2: Harden Gemini fallback**

Make unknown threat levels fall back to `ThreatLevel.MEDIUM`, clamp confidence to `0..100`, and skip malformed indicator entries.

- [ ] **Step 3: Add backend smoke tests if pytest is available**

Create `backend/tests/test_scan_smoke.py` for `/api/health` and `search_rag_database`.

- [ ] **Step 4: Run backend smoke tests**

Run: `python -m pytest`
Expected: PASS if pytest is available; otherwise document missing tooling.

### Task 5: Final Verification and Handoff

**Files:**
- Modify: `README.md` only if commands or local behavior changed.

**Interfaces:**
- Consumes: final source tree.
- Produces: verified rebuild with clear user handoff.

- [ ] **Step 1: Run frontend dependency setup**

Run: `flutter pub get`
Expected: dependencies resolve.

- [ ] **Step 2: Run frontend static analysis**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 3: Run frontend tests**

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 4: Run frontend web build**

Run: `flutter build web`
Expected: build exits 0.

- [ ] **Step 5: Run git status and summarize**

Run: `git status --short`
Expected: only intentional rebuild files are modified.
