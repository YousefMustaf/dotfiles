import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "dark.pomodoro"

    contentItem: Item {
        implicitWidth: layout.implicitWidth + 16
        implicitHeight: layout.implicitHeight

        RowLayout {
            id: layout
            anchors.centerIn: parent
            anchors.margins: 8
            spacing: 8

            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: timer.isRunning ? (timer.isWork ? "#ef4444" : "#22c55e") : "#737373"
            }

            Text {
                id: timeText
                font.family: "monospace"
                font.pixelSize: 12
                font.weight: Font.Bold
                color: palette.text
                text: {
                    var mins = Math.floor(timer.seconds / 60);
                    var secs = timer.seconds % 60;
                    return (mins < 10 ? "0" : "") + mins + ":" + (secs < 10 ? "0" : "") + secs;
                }
            }

            Text {
                font.pixelSize: 10
                color: palette.mid
                text: timer.isWork ? "W" : "B"
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: timer.toggle()
            onDoubleClicked: timer.reset()
            hoverEnabled: true
            cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        Palette {
            id: palette
        }
    }

    QtObject {
        id: timer
        property int seconds: 25 * 60
        property bool isWork: true
        property bool isRunning: false

        function toggle() {
            isRunning = !isRunning;
            if (isRunning) {
                pomodoroTimer.start();
            } else {
                pomodoroTimer.stop();
            }
        }

        function reset() {
            isRunning = false;
            pomodoroTimer.stop();
            isWork = true;
            seconds = 25 * 60;
        }
    }

    Timer {
        id: pomodoroTimer
        interval: 1000
        repeat: true

        onTriggered: {
            if (timer.seconds > 0) {
                timer.seconds--;
            } else {
                // Switch session
                timer.isWork = !timer.isWork;
                timer.seconds = timer.isWork ? 25 * 60 : 5 * 60;
                timer.isRunning = false;
                stop();
            }
        }
    }
}
