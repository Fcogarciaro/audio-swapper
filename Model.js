.pragma library

var NONE = { connected: false, card: "", name: "", mode: "none", hasCall: false, hasMusic: false }

// Parse the one-line JSON printed by `audio-swapper status`. Never throws.
function parseStatus(text) {
  var raw
  try { raw = JSON.parse(String(text || "").trim()) } catch (e) { return NONE }
  if (!raw || typeof raw !== "object") return NONE
  var mode = String(raw.mode || "none")
  if (["call", "music", "other", "none"].indexOf(mode) === -1) mode = "other"
  var connected = raw.connected === true
  return {
    connected: connected,
    card: String(raw.card || ""),
    name: String(raw.name || ""),
    mode: connected ? mode : "none",
    hasCall: raw.hasCall === true,
    hasMusic: raw.hasMusic === true
  }
}

function icon(status) {
  if (!status.connected) return "󰋐"
  return status.mode === "call" ? "󰋎" : "󰋋"
}

function tooltip(status) {
  if (!status.connected) return "No Bluetooth headset connected"
  var name = status.name || "Headset"
  if (status.mode === "call") return name + " — call mode (mic on). Click to switch"
  if (status.mode === "music") return name + " — music mode. Click to switch"
  return name + " — idle. Click to switch to call mode"
}
