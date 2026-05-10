import QtQuick


Rectangle {
  id: root

  property bool active: false
  property real dimOpacity: 0.35

  signal clicked()

  anchors.fill: parent
  color: Qt.rgba(0, 0, 0, root.dimOpacity)
  opacity: root.active ? 1 : 0
  Behavior on opacity { NumberAnimation { duration: 300 } }

  MouseArea {
    anchors.fill: parent
    onClicked: root.clicked()
  }
}
