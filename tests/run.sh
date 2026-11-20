#!/usr/bin/env bash
# Plain-bash test runner for audio-swapper using a fake pactl.
set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
FIX="$ROOT/tests/fixtures"
BIN="$ROOT/audio-swapper"
pass=0 fail=0

setup() { # <cards fixture>
  FAKE_DIR=$(mktemp -d)
  export FAKE_DIR
  cp "$FIX/$1" "$FAKE_DIR/cards.json"
  cp "$FIX/sources.json" "$FAKE_DIR/sources.json"
  cp "$FIX/sinks.json" "$FAKE_DIR/sinks.json"
  : > "$FAKE_DIR/calls.log"
  echo alsa_input.usb-mic > "$FAKE_DIR/default_source"
  echo alsa_output.pci > "$FAKE_DIR/default_sink"
  export PATH="$FIX:$PATH"
  export AUDIO_SWAPPER_NO_NOTIFY=1
}

check() { # <desc> <expected> <actual>
  if [[ "$2" == "$3" ]]; then pass=$((pass + 1)); echo "ok   $1"
  else fail=$((fail + 1)); echo "FAIL $1"; echo "  expected: $2"; echo "  actual:   $3"; fi
}
log_has() { rg -qxF -- "$1" "$FAKE_DIR/calls.log" && echo yes || echo no; }
field() { jq -r ".$2" <<<"$1"; }

CARD=bluez_card.AA_BB_CC_DD_EE_FF

t_no_headset() {
  setup cards_no_headset.json
  out=$("$BIN" status); check "no headset: connected" false "$(field "$out" connected)"
  check "no headset: mode" none "$(field "$out" mode)"
  "$BIN" toggle >/dev/null 2>"$FAKE_DIR/err"; check "no headset: toggle exits non-zero" 1 "$?"
  check "no headset: stderr message" yes "$([[ -s $FAKE_DIR/err ]] && echo yes || echo no)"
}
t_status_music() {
  setup cards_music.json
  out=$("$BIN" status)
  check "music: mode" music "$(field "$out" mode)"
  check "music: name" "realme Buds Air8" "$(field "$out" name)"
  check "music: card" "$CARD" "$(field "$out" card)"
  check "music: hasCall" true "$(field "$out" hasCall)"
  check "music: hasMusic" true "$(field "$out" hasMusic)"
}
t_default_devices() {
  setup cards_music.json
  out=$("$BIN" status)
  check "defaults: source description" "USB Microphone" "$(field "$out" defaultSource)"
  check "defaults: sink description" "Built-in Audio Speakers" "$(field "$out" defaultSink)"
  out=$("$BIN" call)
  check "defaults after call: source is headset mic" "realme Buds Air8" "$(field "$out" defaultSource)"
  check "defaults after call: sink is headset" "realme Buds Air8" "$(field "$out" defaultSink)"
  setup cards_no_headset.json
  check "defaults without headset still reported" "USB Microphone" "$(field "$("$BIN" status)" defaultSource)"
}
t_status_call() {
  setup cards_call.json
  check "call: mode" call "$(field "$("$BIN" status)" mode)"
}
t_toggle_to_call() {
  setup cards_music.json
  out=$("$BIN" toggle)
  check "toggle->call: msbc chosen" yes "$(log_has "set-card-profile $CARD headset-head-unit-msbc")"
  check "toggle->call: default source" yes "$(log_has "set-default-source bluez_input.AA_BB_CC_DD_EE_FF.0")"
  check "toggle->call: default sink" yes "$(log_has "set-default-sink bluez_output.AA_BB_CC_DD_EE_FF.1")"
  check "toggle->call: prints new mode" call "$(field "$out" mode)"
}
t_toggle_to_music() {
  setup cards_call.json
  out=$("$BIN" toggle)
  check "toggle->music: a2dp-sink chosen" yes "$(log_has "set-card-profile $CARD a2dp-sink")"
  check "toggle->music: default sink" yes "$(log_has "set-default-sink bluez_output.AA_BB_CC_DD_EE_FF.1")"
  check "toggle->music: prints new mode" music "$(field "$out" mode)"
}
t_a2dp_fallback() {
  setup cards_a2dp_fallback.json
  "$BIN" music >/dev/null
  check "fallback: highest priority a2dp" yes "$(log_has "set-card-profile $CARD a2dp-sink-aac")"
}
t_unavailable_skipped() {
  setup cards_msbc_unavailable.json
  "$BIN" call >/dev/null
  check "unavailable msbc skipped" yes "$(log_has "set-card-profile $CARD headset-head-unit")"
  check "msbc not selected" no "$(log_has "set-card-profile $CARD headset-head-unit-msbc")"
}

for t in t_default_devices t_no_headset t_status_music t_status_call t_toggle_to_call t_toggle_to_music t_a2dp_fallback t_unavailable_skipped; do "$t"; done
echo "passed=$pass failed=$fail"
[[ $fail -eq 0 ]]
