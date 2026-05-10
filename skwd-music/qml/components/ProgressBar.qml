import QtQuick
import QtQuick.Layouts

import ".." as Root


Item {
    id: progressRoot

    property real position: 0
    property real duration: 1
    property bool canSeek: false
    signal seekRequested(real position)

    implicitHeight: 28

    ColumnLayout {
        anchors.fill: parent
        spacing: Root.Style.spacingTiny

        
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 6

            Rectangle {
                id: track
                anchors.fill: parent
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.15)

                Rectangle {
                    id: fill
                    height: parent.height
                    width: progressRoot.duration > 0
                        ? parent.width * (progressRoot.position / progressRoot.duration)
                        : 0
                    radius: 3
                    color: Root.Colors.primary

                    Behavior on width {
                        NumberAnimation { duration: Root.Style.animFast; easing.type: Easing.OutQuad }
                    }
                }

                
                Rectangle {
                    visible: progressRoot.canSeek && seekArea.containsMouse
                    x: fill.width - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                    height: 12
                    radius: 6
                    color: Root.Colors.primary
                }
            }

            MouseArea {
                id: seekArea
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                enabled: progressRoot.canSeek
                onClicked: mouse => {
                    let ratio = Math.max(0, Math.min(1, mouse.x / track.width))
                    progressRoot.seekRequested(Math.round(ratio * progressRoot.duration))
                }
            }
        }

        
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: formatTime(progressRoot.position)
                font.family: Root.Style.fontFamily
                font.pixelSize: Root.Style.fontTiny
                color: Qt.rgba(1, 1, 1, 0.6)
            }

            Item { Layout.fillWidth: true }

            Text {
                text: formatTime(progressRoot.duration)
                font.family: Root.Style.fontFamily
                font.pixelSize: Root.Style.fontTiny
                color: Qt.rgba(1, 1, 1, 0.6)
            }
        }
    }

    function formatTime(secs) {
        let totalSec = Math.floor(secs)
        if (totalSec < 0) totalSec = 0
        let min = Math.floor(totalSec / 60)
        let sec = totalSec % 60
        return min + ":" + (sec < 10 ? "0" : "") + sec
    }
}
