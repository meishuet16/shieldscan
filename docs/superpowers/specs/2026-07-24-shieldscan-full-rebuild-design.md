# ShieldScan Full Rebuild Design

## Goal

Rebuild and polish ShieldScan into a more mature web-first fraud intelligence dashboard while preserving the existing FastAPI scan contract. The rebuild should make the project easier to demo, easier to trust, and safer to maintain without expanding scope into new production integrations.

## Scope

The primary scope is the Flutter web frontend. The backend remains API-compatible, with targeted fixes only where they improve demo stability or resolve obvious inconsistencies.

Included:

- Rework the first screen into an operational scanning workspace.
- Replace the MVP card stack with a clearer dashboard information architecture.
- Improve responsive behavior across desktop and mobile.
- Improve empty, loading, result, and error states.
- Keep bilingual English and Bahasa Malaysia result presentation.
- Keep the existing `/api/scan` and `/api/scan/stream` request and response shape.
- Add focused tests for parsing/state behavior or backend fallback behavior where practical.
- Verify with available build, analyze, and test commands.

Excluded:

- No new paid cloud resources.
- No real PDRM, BNM, MCMC, or Vertex production integration beyond the existing demo stubs.
- No authentication, user accounts, billing, or persistent history.
- No redesign of the backend into a separate service architecture.

## Product Design

The rebuilt UI should feel like a security analyst console for everyday users, not a marketing landing page. The first viewport should immediately show the scanner, current readiness, and a compact threat intelligence summary.

Main layout:

- Header bar with ShieldScan identity, backend/API readiness, and a concise Malaysia fraud protection tagline.
- Primary scan workspace with input controls on the left and live analysis output on the right for wide screens.
- Mobile layout stacks the same workflow in scan-first order with stable spacing.
- Below the workspace, include trend intelligence and roadmap content as compact dashboard sections rather than promotional blocks.

Visual direction:

- Dark security UI with restrained contrast, cyan/green/red status accents, and less decorative noise.
- Cards use tighter radius and consistent borders.
- Text sizes match their containers, especially inside buttons, cards, and status chips.
- Avoid oversized hero treatment, nested cards, and heavy one-color gradient styling.

## Frontend Architecture

Keep the Flutter app simple but better organized:

- `main.dart` owns app bootstrap, theme, and provider setup.
- `ScanProvider` owns scan state, SSE parsing, counters, result parsing, and error handling.
- Widgets remain split by purpose: input, pipeline, result, stats, intelligence, roadmap.
- Shared visual constants may be introduced only if they reduce duplication and clarify theme use.

Important frontend behaviors:

- Scanning disables inputs and shows deterministic progress.
- Non-200 API responses become visible user-facing errors.
- Malformed SSE lines are ignored without crashing the UI.
- `error` SSE events should put the provider into error state.
- Result parsing should tolerate unknown threat levels and missing optional fields.
- Reset clears scan state but keeps session counters.

## Backend Design

Keep backend endpoints compatible:

- `POST /api/scan/stream`
- `POST /api/scan`
- `GET /api/health`

Targeted backend polish:

- Align model labels with README and frontend copy.
- Improve Gemini JSON parsing fallback where needed.
- Preserve local RAG fallback for demo use.
- Avoid breaking existing request payloads.

## Testing

Preferred test coverage:

- Frontend provider tests for result parsing, unknown threat fallback, SSE step/result/error handling, and reset behavior.
- Backend tests for health response and local RAG matching if Python test tooling is available.

If dependency setup is blocked by local tooling or network restrictions, document the exact command and failure.

## Verification

Run the strongest available checks before completion:

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build web`
- backend import or pytest checks if the Python environment can be prepared

Report exact outcomes, including any commands that could not be run.
