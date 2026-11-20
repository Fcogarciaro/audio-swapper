import QtQuick
import Quickshell.Io
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "fcogarciaro.audio-swapper"

  property var status: Model.parseStatus("")
  property string pendingAction: ""

  readonly property string helperPath: decodeURIComponent(
    String(Qt.resolvedUrl("audio-swapper")).replace(/^file:\/\//, ""))

  function run(action) {
    if (proc.running) return
    root.pendingAction = action
    proc.command = [root.helperPath, action]
    proc.running = true
  }

  function refresh() { root.run("status") }
  function toggle() { root.run("toggle") }
  function call() { root.run("call") }
  function music() { root.run("music") }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Component.onCompleted: root.refresh()

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: proc
    stdout: StdioCollector { id: out; waitForEnd: true }
    stderr: StdioCollector { id: err; waitForEnd: true }
    onExited: function(exitCode) {
      var wasSwitch = root.pendingAction !== "status"
      if (exitCode === 0) root.status = Model.parseStatus(out.text)
      root.pendingAction = ""
      // After a switch the new state is already printed, but re-read it once
      // so the bar reflects what PipeWire settled on.
      if (wasSwitch) Qt.callLater(root.refresh)
    }
  }

  IpcHandler {
    target: "fcogarciaro.audio-swapper"

    function toggle() { root.toggle() }
    function call() { root.call() }
    function music() { root.music() }
    function refresh() { root.refresh() }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: Model.icon(root.status)
    opacity: root.status.connected ? 1.0 : 0.48
    tooltipText: Model.tooltip(root.status)

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.MiddleButton) root.refresh()
      else root.toggle()
    }
  }
}
