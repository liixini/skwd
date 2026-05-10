import QtQuick
import QtQuick.Layouts
import ".."


Text {
  Layout.fillWidth: true
  Layout.topMargin: 8
  font.family: Style.fontFamily
  font.pixelSize: 11
  font.weight: Font.Bold
  font.letterSpacing: 1.5
  property var colors
  color: colors ? colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
}
