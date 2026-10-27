// Minimal top bar: Hyprland workspaces on the left, clock on the right.
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: 28
            color: "#1e1e2e"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Repeater {
                    model: Hyprland.workspaces

                    Text {
                        required property var modelData
                        text: modelData.id
                        color: modelData.focused ? "#89b4fa" : "#6c7086"
                        font.bold: modelData.focused
                        font.pixelSize: 14
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                SystemClock {
                    id: clock
                    precision: SystemClock.Minutes
                }

                Text {
                    text: Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm")
                    color: "#cdd6f4"
                    font.pixelSize: 14
                }
            }
        }
    }
}
