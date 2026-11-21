# Audio Swapper plugin

Objective: Omarchy bar widget that swaps a connected Bluetooth headset between music mode (A2DP, no mic) and call mode (HFP/HSP, mic active and set as default source), so dictation tools like Superwhisper get audio without plugging another mic.

TDD: strict (session config). Runner: `bash tests/run.sh` (fake pactl on PATH).

## Tasks
- [x] T1 `audio-swapper` helper script (status/call/music/toggle) + tests — delegated (2+ non-trivial files)
- [x] T2 BarWidget.qml + manifest.json + README — delegated with T1
- [x] T3 Publish GitHub repo and push

## Checks
bash tests/run.sh; bash -n audio-swapper; shellcheck audio-swapper; qmllint -I $OMARCHY_PATH/shell BarWidget.qml
- [x] T4 Popup panel with Music/Call mode cards (impeccable, Omarchy kit) — delegated

## Evidence
- 10ab14a base widget: tests/run.sh 20/20, qmltestrunner 8/8
- T4 panel: tests/run.sh 25/25, qmltestrunner 16/16, live-rendered in omarchy-shell (no headset connected; toggle on real headset not yet exercised)
- [x] T5 Pin call mode against WirePlumber autoswitch (runtime wpctl setting) — delegated; tests 43/43, qml 18/18
