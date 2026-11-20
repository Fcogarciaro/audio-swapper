import QtQuick 2.15
import QtTest 1.3
import "../Model.js" as Model

TestCase {
  name: "AudioSwapperModel"

  function test_parse_valid_call() {
    var s = Model.parseStatus('{"connected":true,"card":"bluez_card.X","name":"Buds","mode":"call","hasCall":true,"hasMusic":true}')
    compare(s.connected, true)
    compare(s.mode, "call")
    compare(s.name, "Buds")
    compare(s.hasCall, true)
  }

  function test_parse_garbage_is_none() {
    compare(Model.parseStatus("not json").connected, false)
    compare(Model.parseStatus("").mode, "none")
    compare(Model.parseStatus(null).mode, "none")
    compare(Model.parseStatus("42").mode, "none")
  }

  function test_parse_unknown_mode_becomes_other() {
    compare(Model.parseStatus('{"connected":true,"mode":"weird"}').mode, "other")
  }

  function test_disconnected_forces_none_mode() {
    compare(Model.parseStatus('{"connected":false,"mode":"call"}').mode, "none")
  }

  function test_icons() {
    compare(Model.icon(Model.parseStatus('{"connected":true,"mode":"call"}')), "󰋎")
    compare(Model.icon(Model.parseStatus('{"connected":true,"mode":"music"}')), "󰋋")
    compare(Model.icon(Model.parseStatus("")), "󰋐")
  }

  function test_tooltips() {
    compare(Model.tooltip(Model.parseStatus('{"connected":true,"name":"Buds","mode":"call"}')),
      "Buds — call mode (mic on). Click to switch")
    compare(Model.tooltip(Model.parseStatus('{"connected":true,"name":"Buds","mode":"music"}')),
      "Buds — music mode. Click to switch")
    compare(Model.tooltip(Model.parseStatus("")), "No Bluetooth headset connected")
  }

  readonly property string musicJson: '{"connected":true,"card":"c","name":"Buds","mode":"music","hasCall":true,"hasMusic":true,"defaultSource":"USB Mic","defaultSink":"Buds"}'
  readonly property string callJson: '{"connected":true,"card":"c","name":"Buds","mode":"call","hasCall":true,"hasMusic":true,"defaultSource":"Buds","defaultSink":"Buds"}'

  function test_parse_defaults() {
    var s = Model.parseStatus(musicJson)
    compare(s.defaultSource, "USB Mic")
    compare(s.defaultSink, "Buds")
    compare(Model.parseStatus("").defaultSource, "")
  }

  function test_hero_title_and_line() {
    compare(Model.heroTitle(Model.parseStatus(callJson)), "Buds")
    compare(Model.heroTitle(Model.parseStatus("")), "Audio Swapper")
    compare(Model.heroLine(Model.parseStatus(callJson)), "Mic on · Hands-free")
    compare(Model.heroLine(Model.parseStatus(musicJson)), "Hi-fi audio · Mic off")
    compare(Model.heroLine(Model.parseStatus("")), "No headset connected")
    compare(Model.heroLine(Model.parseStatus('{"connected":true,"mode":"other"}')), "Choose a mode")
  }

  function test_card_active_and_labels() {
    var m = Model.cardState(Model.parseStatus(musicJson), "music", "")
    compare(m.active, true)
    compare(m.disabled, false)
    compare(m.title, "Music")
    compare(m.subtitle, "Hi-fi · mic off")
    compare(m.icon, "󰋋")
    var c = Model.cardState(Model.parseStatus(musicJson), "call", "")
    compare(c.active, false)
    compare(c.title, "Call")
    compare(c.subtitle, "Mic on · calls")
    compare(c.icon, "󰍬")
  }

  function test_card_disabled_when_profile_missing_or_no_headset() {
    var noCall = Model.parseStatus('{"connected":true,"mode":"music","hasCall":false,"hasMusic":true}')
    compare(Model.cardState(noCall, "call", "").disabled, true)
    compare(Model.cardState(noCall, "music", "").disabled, false)
    var none = Model.parseStatus("")
    compare(Model.cardState(none, "music", "").disabled, true)
    compare(Model.cardState(none, "call", "").active, false)
  }

  function test_card_pending_state() {
    var s = Model.parseStatus(musicJson)
    var c = Model.cardState(s, "call", "call")
    compare(c.pending, true)
    compare(c.subtitle, "Switching…")
    compare(c.disabled, true)
    var m = Model.cardState(s, "music", "call")
    compare(m.pending, false)
    compare(m.disabled, true)
    // a background status refresh must not lock the cards
    compare(Model.cardState(s, "call", "status").disabled, false)
  }

  function test_default_mic() {
    var line = Model.defaultMic(Model.parseStatus(callJson))
    compare(line.label, "Default mic")
    compare(line.value, "Buds")
    compare(line.isHeadset, true)
    var other = Model.defaultMic(Model.parseStatus(musicJson))
    compare(other.isHeadset, false)
    compare(Model.defaultMic(Model.parseStatus("")).value, "Unknown")
  }

  function test_empty_hint() {
    compare(Model.emptyHint(Model.parseStatus("")), "Connect your headset in Bluetooth settings")
    compare(Model.emptyHint(Model.parseStatus(callJson)), "")
  }

  function test_error_message() {
    compare(Model.errorMessage("audio-swapper: no available call profile on Buds\n", 1), "audio-swapper: no available call profile on Buds")
    compare(Model.errorMessage("", 1), "Could not switch audio mode.")
    compare(Model.errorMessage("ignored", 0), "")
  }
}
