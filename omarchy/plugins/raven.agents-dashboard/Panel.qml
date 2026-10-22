import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  property var settings: ({})
  property bool opened: window.visible
  readonly property var providers: usage.availableProviders
  readonly property color cyberBg: "#07090e"
  readonly property color cyberPanel: "#111821"
  readonly property color cyberLine: "#3a4656"
  readonly property color cyberFg: "#f5f3ff"
  readonly property color cyberMuted: "#8b98a8"
  readonly property color cyberGreen: "#6ee7a8"
  readonly property color cyberPink: "#ff2e97"
  readonly property color cyberPurple: "#9b6bff"
  readonly property color cyberCyan: "#2ee6f6"
  readonly property color cyberOrange: "#ffb347"
  readonly property color cyberRed: "#f1142d"
  readonly property color dim: cyberMuted
  property string selectedProvider: "all"

  function open(payload) {
    window.visible = true
    usage.refresh()
    focusScope.forceActiveFocus()
  }

  function close() {
    window.visible = false
  }

  function toggle() {
    opened ? close() : open()
  }

  function refresh() {
    usage.refresh()
  }

  function providerOptions() {
    var result = [{ value: "all", label: "All active agents (" + providers.length + ")" }]
    for (var index = 0; index < providers.length; index++) {
      var provider = providers[index]
      result.push({
        value: String(provider.providerId),
        label: String(provider.providerName || provider.providerId)
      })
    }
    return result
  }

  readonly property var visibleProviders: selectedProvider === "all"
    ? providers
    : providers.filter(function(provider) {
        return String(provider.providerId) === selectedProvider
      })

  function percent(limit) {
    var value = Number(limit && limit.percent)
    return isFinite(value) ? Math.max(0, Math.min(1, value)) : 0
  }

  function statusColor(provider) {
    if (provider.future)
      return provider.installed ? cyberPurple : cyberMuted
    if (provider.limitsStale || provider.usageStatusText)
      return cyberRed
    return cyberGreen
  }

  Main {
    id: usage
    settings: root.settings
  }

  Timer {
    interval: 900000
    running: root.opened
    repeat: true
    onTriggered: usage.refresh()
  }

  FloatingWindow {
    id: window
    title: "Blackbox Agents"
    visible: false
    color: root.cyberBg
    implicitWidth: 1180
    implicitHeight: 680
    minimumSize: Qt.size(940, 560)

    FocusScope {
      id: focusScope
      anchors.fill: parent
      focus: window.visible

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape || (event.key === Qt.Key_W && (event.modifiers & Qt.ControlModifier))) {
          root.close()
          event.accepted = true
        } else if (event.key === Qt.Key_F5) {
          usage.refresh()
          event.accepted = true
        }
      }

      Column {
        anchors.fill: parent
        anchors.margins: Style.space(24)
        spacing: Style.space(18)

        RowLayout {
          width: parent.width
          spacing: Style.space(16)

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space(4)

            Text {
              textFormat: Text.PlainText
              text: "[ AGENTS / STATUS ]"
              color: root.cyberCyan
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Text {
              textFormat: Text.PlainText
              text: "CYBERCORE OPERATOR TELEMETRY"
              color: root.cyberFg
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
            }
          }

          Dropdown {
            Layout.preferredWidth: 280
            label: "Provider scope"
            options: root.providerOptions()
            value: root.selectedProvider
            onChanged: root.selectedProvider = value
          }

          Button {
            text: "↻ Refresh"
            onClicked: usage.refresh()
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: root.cyberCyan
          opacity: 0.5
        }

        Flickable {
          id: cards
          Layout.fillWidth: true
          Layout.fillHeight: true
          contentWidth: width
          contentHeight: grid.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          interactive: contentHeight > height

          GridLayout {
            id: grid
            width: cards.width
            columns: cards.width >= 1040 ? 3 : (cards.width >= 700 ? 2 : 1)
            rowSpacing: Style.space(14)
            columnSpacing: Style.space(14)

            Repeater {
              model: root.visibleProviders

              Rectangle {
                required property var modelData
                Layout.fillWidth: true
                Layout.minimumHeight: 150
                Layout.preferredHeight: 170
                radius: 2
                color: root.cyberPanel
                border.width: 1
                border.color: Qt.rgba(statusColor(modelData).r,
                                       statusColor(modelData).g,
                                       statusColor(modelData).b, 0.55)

                Column {
                  anchors.fill: parent
                  anchors.margins: Style.space(16)
                  spacing: Style.space(10)

                  Row {
                    width: parent.width
                    spacing: Style.space(10)

                    Text {
                      textFormat: Text.PlainText
                      text: "●"
                      color: root.statusColor(modelData)
                      font.family: Style.font.family
                      font.pixelSize: Style.font.body
                    }

                    Text {
                      width: parent.width - x
                      textFormat: Text.PlainText
                      text: String(modelData.providerName || modelData.providerId)
                      color: root.cyberFg
                      font.family: Style.font.family
                      font.pixelSize: Style.font.body
                      font.bold: true
                      elide: Text.ElideRight
                    }
                  }

                  Text {
                    width: parent.width
                    textFormat: Text.PlainText
                    text: {
                      var prompts = Number(modelData.todayPrompts || 0)
                      var sessions = Number(modelData.todaySessions || 0)
                      return prompts + " prompts  •  " + sessions + " sessions today"
                    }
                    color: root.cyberFg
                    font.family: Style.font.family
                    font.pixelSize: Style.font.caption
                  }

                  Repeater {
                    model: (modelData.limits || []).slice(0, 2)

                    Column {
                      required property var modelData
                      width: parent.width
                      spacing: Style.space(4)

                      Row {
                        width: parent.width

                        Text {
                          width: parent.width * 0.68
                          textFormat: Text.PlainText
                          text: String(modelData.title || modelData.label || "Quota")
                          color: root.cyberFg
                          font.family: Style.font.family
                          font.pixelSize: Style.font.caption
                          elide: Text.ElideRight
                        }

                        Text {
                          width: parent.width * 0.32
                          textFormat: Text.PlainText
                          text: Math.round(root.percent(modelData) * 100) + "% used"
                          color: root.statusColor(modelData)
                          horizontalAlignment: Text.AlignRight
                          font.family: Style.font.family
                          font.pixelSize: Style.font.caption
                        }
                      }

                      Rectangle {
                        width: parent.width
                        height: Style.space(6)
                        radius: height / 2
                        color: root.cyberLine

                        Rectangle {
                          width: parent.width * root.percent(modelData)
                          height: parent.height
                          radius: height / 2
                          color: root.statusColor(modelData)
                        }
                      }
                    }
                  }

                  Text {
                    visible: modelData.limits.length === 0
                    textFormat: Text.PlainText
                    text: modelData.future
                      ? (modelData.installed ? "DETECTED · COLLECTOR NOT CONFIGURED" : "FUTURE PROVIDER · NOT INSTALLED")
                      : "LOCAL ACTIVITY ONLY · no verified quota source"
                    color: root.cyberMuted
                    font.family: Style.font.family
                    font.pixelSize: Style.font.caption
                  }
                }
              }
            }
          }

        }

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: "F5 refreshes  •  Esc closes  •  quota meters are provider-authoritative"
          color: root.dim
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignRight
        }
      }
    }
  }
}
