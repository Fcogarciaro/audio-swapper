# Changelog

## Unreleased

### Added
- Popup panel opened by left click: hero, Music/Call mode cards, default microphone row, inline error, and a Bluetooth hint when no headset is connected.
- `audio-swapper status` now reports `defaultSource` and `defaultSink` descriptions.
- IPC `open` and `close`.
- Keyboard navigation in the panel (Left/Right, Enter/Space, Esc).

### Changed
- Left click opens the panel instead of toggling. `toggle` remains available over IPC and the CLI.

## 0.1.0

- Initial bar widget and `audio-swapper` helper: toggle a Bluetooth headset between A2DP music and HFP call mode, setting the default mic and sink.
