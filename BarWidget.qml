import QtQuick
import Quickshell.Io
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "fcogarciaro.audio-swapper"

  property var status: Model.parseStatus("")
  property string pendingAction: ""
  property string lastError: ""

  // Optional outer widget used for bar popout ownership.
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true : false

  readonly property string helperPath: decodeURIComponent(
    String(Qt.resolvedUrl("audio-swapper")).replace(/^file:\/\//, ""))

  function run(action) {
    if (proc.running) return
    if (action !== "status") root.lastError = ""
    root.pendingAction = action
    proc.command = [root.helperPath, action]
    proc.running = true
  }

  function refresh() { root.run("status") }
  function toggle() { root.run("toggle") }
  function call() { root.run("call") }
  function music() { root.run("music") }
  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function togglePanel() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    target.bar = root.bar
    target.settings = root.settings
    target.anchorItem = button
    target.hostWidget = root.barIdentity
    target.widget = root
  }

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

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
      if (wasSwitch) root.lastError = Model.errorMessage(err.text, exitCode)
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
    function open() { root.open() }
    function close() { root.close() }
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
      else root.togglePanel()
    }
  }
}
