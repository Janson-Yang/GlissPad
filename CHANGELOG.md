# Changelog

## [1.1.0] - 2026-06-05

### Added

- Added a full three-finger gesture family:
  - Three Finger Touch
  - Three Finger Tap
  - Three Finger Press
  - Three Finger Swipe
  - Three Finger TipTap
  - Three Finger TipSwipe
  - Thumb + Two Fingers Pinch / Spread
  - Three Finger Drawing
- Added three-finger parameter panels for timing, pressure, movement tolerance,
  start/end regions, fixed fingers, active finger selection, drawing matching,
  and scale/rotation normalization.
- Added configurable timing for Keyboard Shortcut actions:
  - key hold duration
  - post-release delay
- Added active-finger selection for the existing two-finger Tip Tap trigger.
- Added custom SVG icons for trigger categories, trigger types, and action
  types.
- Added a keyboard event probe tool for debugging keyboard shortcut behavior.

### Improved

- Improved Rotate Left and Rotate Right recognition for the existing two-finger
  rotate triggers.
- Improved action drag reordering so action cards keep consistent spacing while
  being moved.
- Improved workflow list visuals, including action status badges, connector
  spacing, and scrollbar overlap.
- Improved trigger list status display with clearer enabled/disabled indicators.
- Improved packaging so release DMGs include the app resource bundle and custom
  icon assets.

### Fixed

- Fixed Keyboard Shortcut workflows that needed precise key down/up timing, such
  as double-tapping a modifier key.
- Fixed action status badges being partially clipped near the top and right edge
  of the action list.
- Fixed local install and DMG builds so release artifacts do not include the
  user's local Application Support configuration.

## [1.0.0] - 2026-06-03

- Initial public release.
