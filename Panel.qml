import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "fcogarciaro.audio-swapper"
  ipcTarget: "fcogarciaro.audio-swapper"
  // The bar widget owns the single IpcHandler for this target.
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  // The bar widget owns status polling and the helper process.
  property var widget: null

  readonly property var barIdentity: hostWidget || root
  readonly property var status: widget ? widget.status : Model.parseStatus("")
  readonly property string pendingAction: widget ? widget.pendingAction : ""
  readonly property string lastError: widget ? widget.lastError : ""
  readonly property bool connected: status.connected === true

  readonly property color contentForeground: root.bar ? root.bar.foreground : Commons.Color.foreground
  readonly property string contentFontFamily: root.bar ? root.bar.fontFamily : Style.font.family
  readonly property color dimForeground: Qt.darker(contentForeground, 1.4)

  // Keyboard cursor: which card Enter/Space activates.
  property string cursorKind: "music"

  readonly property string shellPath: String(Quickshell.env("OMARCHY_PATH") || "/usr/share/omarchy") + "/shell"

  function initCursor() {
    root.cursorKind = root.status.mode === "call" ? "call" : "music"
  }

  function activate(kind) {
    var card = Model.cardState(root.status, kind, root.pendingAction)
    if (card.disabled || card.active || !root.widget) return
    root.widget.run(kind)
  }

  function openBluetoothSettings() {
    bluetoothProc.command = [
      "quickshell", "ipc", "-p", root.shellPath,
      "call", "shell", "toggle", "omarchy.bluetooth", "{}"
    ]
    root.close()
    bluetoothProc.running = true
  }

  onOpenedChanged: if (opened) {
    root.initCursor()
    if (root.widget) root.widget.refresh()
  }

  Process { id: bluetoothProc }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(body.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onMoveRequested: function(dx, dy) {
        if (dx !== 0) root.cursorKind = root.cursorKind === "music" ? "call" : "music"
      }
      onActivateRequested: root.activate(root.cursorKind)

      Column {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        PanelHero {
          title: Model.heroTitle(root.status)
          meta: Model.heroLine(root.status)
          foreground: root.contentForeground
          fontFamily: root.contentFontFamily
          iconOpacity: root.connected ? 1.0 : 0.48
          iconComponent: Component {
            Text {
              textFormat: Text.PlainText
              text: Model.icon(root.status)
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.display
            }
          }
        }

        Row {
          id: cards
          width: parent.width
          spacing: Style.space(10)

          Repeater {
            model: ["music", "call"]

            delegate: BorderSurface {
              id: card
              required property string modelData
              readonly property var view: Model.cardState(root.status, modelData, root.pendingAction)
              readonly property bool focused: root.opened && root.cursorKind === modelData
              readonly property bool hot: mouse.containsMouse && !view.disabled

              width: (cards.width - cards.spacing) / 2
              implicitHeight: cardColumn.implicitHeight + Style.space(24)
              radius: Style.cornerRadius
              opacity: view.disabled && !view.pending ? 0.45 : 1.0
              color: view.active
                ? Style.selectedFillFor(root.contentForeground, Commons.Color.accent)
                : (hot ? Style.hoverFillFor(root.contentForeground, Commons.Color.accent) : "transparent")
              borderSpec: Border.controlSpec("normal", root.contentForeground, Commons.Color.accent)

              Behavior on color { ColorAnimation { duration: Style.duration(150); easing.type: Easing.OutCubic } }
              Behavior on opacity { NumberAnimation { duration: Style.duration(150); easing.type: Easing.OutCubic } }

              // Accent border for the active card; fades in and out.
              BorderSurface {
                anchors.fill: parent
                radius: card.radius
                color: "transparent"
                borderSpec: Border.controlSpec("selected", root.contentForeground, Commons.Color.accent)
                opacity: card.view.active ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Style.duration(150); easing.type: Easing.OutCubic } }
              }

              // Keyboard focus ring.
              BorderSurface {
                anchors.fill: parent
                radius: card.radius
                color: "transparent"
                borderSpec: Border.controlSpec("focus", root.contentForeground, Commons.Color.accent)
                opacity: card.focused ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Style.duration(150); easing.type: Easing.OutCubic } }
              }

              Column {
                id: cardColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Style.space(12)
                spacing: Style.space(4)

                Item {
                  width: parent.width
                  height: cardIcon.implicitHeight

                  Text {
                    id: cardIcon
                    textFormat: Text.PlainText
                    anchors.left: parent.left
                    text: card.view.icon
                    color: card.view.active ? Commons.Color.accent : root.contentForeground
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.iconLarge
                    Behavior on color { ColorAnimation { duration: Style.duration(150); easing.type: Easing.OutCubic } }
                  }

                  Text {
                    textFormat: Text.PlainText
                    anchors.right: parent.right
                    anchors.verticalCenter: cardIcon.verticalCenter
                    text: "󰄬"
                    visible: card.view.active
                    color: Commons.Color.accent
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.icon
                  }
                }

                Text {
                  textFormat: Text.PlainText
                  width: parent.width
                  text: card.view.title
                  color: root.contentForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.subtitle
                  font.bold: true
                  elide: Text.ElideRight
                }

                Text {
                  textFormat: Text.PlainText
                  width: parent.width
                  text: card.view.subtitle
                  color: root.dimForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.bodySmall
                  wrapMode: Text.WordWrap
                }
              }

              MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: !card.view.disabled
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onContainsMouseChanged: if (containsMouse) root.cursorKind = card.modelData
                onClicked: {
                  root.cursorKind = card.modelData
                  root.activate(card.modelData)
                }
              }
            }
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(6)
          visible: root.lastError !== ""

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: root.lastError
            color: Commons.Color.urgent
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(8)
          visible: !root.connected

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: Model.emptyHint(root.status)
            color: root.dimForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          Button {
            text: "Bluetooth settings"
            iconText: "󰂯"
            focusable: true
            bordered: true
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
            onClicked: root.openBluetoothSettings()
          }
        }

        PanelSeparator { foreground: root.contentForeground }

        Item {
          id: micRow
          readonly property var mic: Model.defaultMic(root.status)
          width: parent.width
          implicitHeight: Math.max(micLabel.implicitHeight, micValue.implicitHeight)

          Text {
            id: micLabel
            textFormat: Text.PlainText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: micRow.mic.label
            color: root.dimForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Text {
            id: micValue
            textFormat: Text.PlainText
            anchors.left: micLabel.right
            anchors.leftMargin: Style.space(12)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: micRow.mic.value
            color: micRow.mic.isHeadset ? Commons.Color.accent : root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.body
            font.bold: true
            elide: Text.ElideRight
          }
        }
      }
    }
  }
}
