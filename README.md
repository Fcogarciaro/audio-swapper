# Audio Swapper

An Omarchy bar widget that switches a connected Bluetooth headset between **music** and **call** mode with one click.

## Why

Bluetooth headsets expose two incompatible profiles:

- **A2DP** — high-quality stereo output, but no microphone.
- **HFP/HSP (headset head unit)** — the microphone works, but audio quality drops to narrowband/wideband mono.

Dictation apps such as Superwhisper need the headset mic, which only exists in call mode, and the default source must point at it. Audio Swapper flips the profile and sets the default source (`bluez_input.*`) and sink (`bluez_output.*`) in one step. Switching back to music restores A2DP quality.

## Requirements

PipeWire + WirePlumber, `pactl`, `jq`. `notify-send` is optional.

## Install

```bash
git clone https://github.com/Fcogarciaro/audio-swapper ~/.config/omarchy/plugins/fcogarciaro.audio-swapper
```

Then add the "Audio Swapper" widget to the bar with `omarchy bar` (or by listing `fcogarciaro.audio-swapper` in your `shell.json` bar section).

Widget: left click opens the panel, middle click refreshes. The icon shows call mode, music mode, or a dimmed icon when no headset is connected.

The panel shows the headset name and state, two mode cards (Music and Call; the active one is highlighted, unavailable ones are dimmed), and the current default microphone so you can confirm dictation apps get the headset mic. Left/Right (or h/l) moves between cards, Enter or Space switches, Esc closes. If a switch fails, the error appears inline. With no headset connected, the cards are disabled and a button opens the Omarchy Bluetooth panel.

## CLI

```bash
audio-swapper status   # one-line JSON (mode, availability, default mic/sink)
audio-swapper call     # HFP profile + default mic/sink
audio-swapper music    # best A2DP profile + default sink
audio-swapper toggle   # call -> music, anything else -> call
```

Bind a key in `~/.config/hypr/bindings.lua`:

```
o.bind("SUPER + ALT + M", "Toggle headset mic mode", "~/.config/omarchy/plugins/fcogarciaro.audio-swapper/audio-swapper toggle")
```

The widget also answers IPC: `qs ipc call fcogarciaro.audio-swapper toggle` (also `call`, `music`, `open`, `close`, `refresh`; `toggle` switches directly without opening the panel).

Profile choice: call prefers `headset-head-unit-msbc`, then `headset-head-unit`, then any head-unit/HFP/HSP profile. Music prefers `a2dp-sink`, else the `a2dp-sink*` profile with the highest priority. Unavailable profiles are skipped.

## Tests

```bash
bash tests/run.sh                                              # CLI, fake pactl
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests -o -,txt   # Model.js
```

## License

MIT
