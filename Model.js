.pragma library

var NONE = { connected: false, card: "", name: "", mode: "none", hasCall: false, hasMusic: false, defaultSource: "", defaultSink: "" }

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
    hasMusic: raw.hasMusic === true,
    defaultSource: String(raw.defaultSource || ""),
    defaultSink: String(raw.defaultSink || "")
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

function heroTitle(status) {
  return status.connected && status.name ? status.name : "Audio Swapper"
}

function heroLine(status) {
  if (!status.connected) return "No headset connected"
  if (status.mode === "call") return "Mic on · Hands-free"
  if (status.mode === "music") return "Hi-fi audio · Mic off"
  return "Choose a mode"
}

// View state for one mode card. `kind` is "music" or "call"; `pendingAction`
// is the helper subcommand currently running ("" when idle). A background
// "status" poll never locks the cards.
function cardState(status, kind, pendingAction) {
  var isCall = kind === "call"
  var busy = pendingAction === "music" || pendingAction === "call" || pendingAction === "toggle"
  var pending = pendingAction === kind
  var available = status.connected && (isCall ? status.hasCall : status.hasMusic)
  var subtitle = isCall ? "Mic on · calls" : "Hi-fi · mic off"
  if (pending) subtitle = "Switching…"
  return {
    kind: kind,
    title: isCall ? "Call" : "Music",
    subtitle: subtitle,
    icon: isCall ? "󰍬" : "󰋋",
    active: status.connected && status.mode === kind,
    pending: pending,
    disabled: !available || busy
  }
}

function defaultMic(status) {
  return {
    label: "Default mic",
    value: status.defaultSource || "Unknown",
    isHeadset: status.connected && status.name !== "" && status.defaultSource === status.name
  }
}

function emptyHint(status) {
  return status.connected ? "" : "Connect your headset in Bluetooth settings"
}

function errorMessage(stderrText, exitCode) {
  if (exitCode === 0) return ""
  var text = String(stderrText || "").trim()
  return text !== "" ? text : "Could not switch audio mode."
}
