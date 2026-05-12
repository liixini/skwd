import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "."
import "components"
import "sections"


PanelWindow {
  id: window

  property var colors
  property bool showing: true

  visible: showing
  color: "transparent"

  WlrLayershell.namespace: "skwd-settings"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  exclusionMode: ExclusionMode.Ignore
  margins { top: 0; bottom: 0; left: 0; right: 0 }
  anchors { top: true; bottom: true; left: true; right: true }

  signal closeRequested()

  function _s(v) { return v * Config.uiScale }

  
  readonly property var sections: [
    { key: "general",      label: "GENERAL",      sectionId: "general" },
    { key: "switch",       label: "SWITCH",       sectionId: "switch" },
    { key: "launch",       label: "LAUNCH",       sectionId: "launch" },
    { key: "music",        label: "MUSIC",        sectionId: "music" },
    { key: "notification", label: "NOTIFICATION", sectionId: "notification" },
    { key: "bar",          label: "BAR",          sectionId: "bar" },
    { key: "power",        label: "POWER",        sectionId: "power" },
    { key: "programs",     label: "PROGRAMS",     sectionId: "programs" },
    { key: "modules",      label: "MODULES",      sectionId: "modules" }
  ]

  property string activeSection: "switch"
  property string activeCategory: "layout"

  function _sectionData(key) {
    for (var i = 0; i < sections.length; i++) {
      if (sections[i].key === key) return sections[i]
    }
    return sections[0]
  }

  
  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.35)
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: window.closeRequested()
    }
  }

  
  Item {
    id: panel
    anchors.centerIn: parent
    width: Math.min(window._s(820), parent.width - 80)
    height: Math.min(contentArea.implicitHeight + window._s(24), parent.height - window._s(80))

    
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) window.closeRequested()
      }
    }

    property int _tabSkew: 14

    Item {
      id: contentArea
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.topMargin: window._s(12)
      anchors.bottomMargin: window._s(12)
      anchors.leftMargin: window._s(12)
      anchors.rightMargin: window._s(12)
      readonly property int implicitHeight: tabRow.height + innerColumn.implicitHeight + window._s(36)

      Rectangle {
        anchors.fill: parent
        radius: 0
        color: window.colors ? Qt.rgba(window.colors.background.r, window.colors.background.g, window.colors.background.b, 0.95)
                             : Qt.rgba(0, 0, 0, 0.95)
      }

      Rectangle {
        anchors.top: tabRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: window._s(8)
        anchors.leftMargin: window._s(6)
        anchors.rightMargin: window._s(6)
        anchors.bottomMargin: window._s(6)
        radius: 0
        color: "transparent"
        border.width: 1
        border.color: window.colors
          ? Qt.rgba(window.colors.outline.r, window.colors.outline.g, window.colors.outline.b, 0.22)
          : Qt.rgba(1, 1, 1, 0.12)
        z: 5
      }

      Row {
        id: tabRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: window._s(10)
        spacing: -panel._tabSkew
        z: 11

        Repeater {
          model: window.sections
          FilterButton {
            colors: window.colors
            label: modelData.label
            skew: panel._tabSkew
            height: window._s(28)
            isActive: window.activeSection === modelData.key
            onClicked: {
              window.activeSection = modelData.key

              if (sectionLoader.item && sectionLoader.item.categories && sectionLoader.item.categories.length > 0)
                window.activeCategory = sectionLoader.item.categories[0].key
            }
          }
        }
      }

      Flickable {
        id: scrollArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: tabRow.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: window._s(10)
        anchors.bottomMargin: window._s(4)
        anchors.leftMargin: window._s(8)
        anchors.rightMargin: window._s(8)
        clip: true
        contentWidth: width
        contentHeight: innerColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: innerColumn
          width: scrollArea.width
          spacing: window._s(10)


          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: -8 * Config.uiScale
            visible: sectionLoader.item && sectionLoader.item.categories && sectionLoader.item.categories.length > 1

            Repeater {
              model: sectionLoader.item ? sectionLoader.item.categories : []
              FilterButton {
                colors: window.colors
                label: modelData.label
                skew: 8 * Config.uiScale
                height: 24 * Config.uiScale
                isActive: window.activeCategory === modelData.key
                onClicked: window.activeCategory = modelData.key
              }
            }
          }


          Loader {
            id: sectionLoader
            width: parent.width
          property string _sectionId: window._sectionData(window.activeSection).sectionId

          sourceComponent: {
            switch (_sectionId) {
              case "general":      return _generalComp
              case "switch":       return _switchComp
              case "launch":       return _launchComp
              case "bar":          return _barComp
              case "music":        return _musicComp
              case "notification": return _notifComp
              case "power":        return _powerComp
              case "programs":     return _programsComp
              case "modules":      return _modulesComp
              case "placeholder":  return _placeholderComp
              default:             return _placeholderComp
            }
          }

          onLoaded: {
            if (item) {
              item.colors = Qt.binding(function() { return window.colors })
              item.activeCategory = Qt.binding(function() { return window.activeCategory })
              var data = window._sectionData(window.activeSection)
              if (data.componentName !== undefined) item.componentName = data.componentName
              if (data.sectionFile !== undefined) item.sectionFile = data.sectionFile
              if (item.categories && item.categories.length > 0
                  && !item.categories.some(function(c) { return c.key === window.activeCategory })) {
                window.activeCategory = item.categories[0].key
              }
            }
          }
        }

        Component { id: _generalComp;     GeneralSettings {} }
        Component { id: _switchComp;      SwitchSettings {} }
        Component { id: _launchComp;      LaunchSettings {} }
        Component { id: _barComp;         BarSettings {} }
        Component { id: _musicComp;       MusicSettings {} }
        Component { id: _notifComp;       NotificationSettings {} }
        Component { id: _powerComp;       PowerSettings {} }
        Component { id: _programsComp;    ProgramsSettings {} }
        Component { id: _modulesComp;     ModulesSettings {} }
        Component { id: _placeholderComp; PlaceholderSection {} }
        }
      }
    }
  }

  
  Shortcut {
    sequence: "Escape"
    context: Qt.WindowShortcut
    onActivated: window.closeRequested()
  }
}
