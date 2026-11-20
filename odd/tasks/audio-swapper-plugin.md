# Audio Swapper plugin

Objective: Omarchy bar widget that swaps a connected Bluetooth headset between music mode (A2DP, no mic) and call mode (HFP/HSP, mic active and set as default source), so dictation tools like Superwhisper get audio without plugging another mic.

TDD: strict (session config). Runner: `bash tests/run.sh` (fake pactl on PATH).

## Tasks
- [ ] T1 `audio-swapper` helper script (status/call/music/toggle) + tests — delegated (2+ non-trivial files)
- [ ] T2 BarWidget.qml + manifest.json + README — delegated with T1
- [ ] T3 Publish GitHub repo and push

## Checks
bash tests/run.sh; bash -n audio-swapper; shellcheck audio-swapper; qmllint -I $OMARCHY_PATH/shell BarWidget.qml
- [ ] T4 Popup panel with Music/Call mode cards (impeccable, Omarchy kit) — delegated
