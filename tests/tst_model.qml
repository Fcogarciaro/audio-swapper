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
}
