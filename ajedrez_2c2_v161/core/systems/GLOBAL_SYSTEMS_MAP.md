# Global systems map

Rule: when a feature appears in more than one screen, prefer a shared module and a small adapter over duplicated implementation.

## Shared systems

- `core/visual/`: chessboard drawing contract, highlight colors and board visual events. Any future board-like screen (live match, replay, study, puzzles, analysis) should use the same board view and publish semantic events rather than inventing its own piece scale or highlight palette.
- `core/events/global_events.gd` (`GlobalEvents` autoload): app-wide, data-only events for screen lifecycle, preferences, notifications, modal requests, long operations and connectivity. Consumers subscribe/unsubscribe in their lifecycle; payloads should not contain node references.
- `core/theme/`: design tokens and theme service for colors, typography and component styling.
- `core/layout/`: responsive sizing and mobile layout helpers; no screen should hardcode a device-specific scale if the shared helper can express it.
- `core/navigation/`: scene navigation and route lifecycle.
- `core/services/`: reusable app services (storage, audio feedback, runtime service access and safety/supervision).
- `domain/`: rules and feature logic, independent of presentation. Keep chess legality and analysis out of UI components.

## Board integration contract

1. Reuse `ChessBoardView` (`ui/components/board.gd`) when the screen is interactive or can adapt it safely.
2. Read piece ratio and semantic highlight colors from `BoardVisualContract`; do not define a screen-local piece scale.
3. Publish board changes through `BoardVisualEvents` with stable source IDs (`match`, `replay`, `analysis`, `study`, `puzzle`).
4. Keep live game state authoritative in the domain layer. Visual events describe state; they do not mutate chess rules.
5. Animation services must support instant mode for tests/reduced-motion and avoid blocking turn logic.
6. Publish animation lifecycle through `BoardVisualEvents.publish_move_started/finished`; do not emit the autoload signals directly. Use its stable source and highlight constants.

## Adding a repeated system

- Search existing `core/` modules first.
- Add the smallest reusable contract/service in the relevant `core/` category.
- Keep feature-specific decisions in `domain/<feature>/` and screen composition in `scenes/` or `ui/`.
- Add tests for duplicate calls, missing listeners, payload isolation and compatibility with existing flows.
- Document the event name/payload and who owns state. Avoid global events that secretly mutate domain state.

## Module ownership overview

| Concern | Owner |
|---|---|
| Chessboard scale, highlight semantics, board feedback | `core/visual/` |
| Cross-screen app events | `core/events/` |
| Colors, typography, theme variants | `core/theme/` |
| Responsive sizing and gestures | `core/layout/`, `core/services/mobile_scroll_gesture.gd` |
| Scene changes and navigation | `core/navigation/`, `core/services/app.gd` |
| Audio feedback | `core/services/audio_feedback.gd` |
| Persistence and sync | `core/services/`, `domain/player/` |
| Chess rules and game state | `domain/chess/` |
| Replay, analysis and coach | `domain/replay/` |


## V154 integration notes

- `BoardVisualEvents` now owns stable source IDs and highlight semantic IDs, plus defensive-copy helpers for move lifecycle, selection and variation events.
- `PieceMoveAnimator` gets its default movement duration from `BoardVisualContract` and routes lifecycle notifications through the event API instead of emitting global signals directly.
- The animator's `visual_source` is configurable so the same component can be hosted by replay/study/puzzle screens without hard-coded `live_game` labels.
- Cleanup remains conservative: legacy tests and scripts are not deleted based on grep-only results. The archive has many historical test files; removing them needs a call-graph and explicit archival policy.
