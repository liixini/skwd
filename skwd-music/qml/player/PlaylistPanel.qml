import QtQuick
import QtQuick.Layouts

import ".." as Root


Item {
    id: panel

    property var spotifyApi: null
    property bool open: false
    property string currentTrackTitle: ""

    signal trackClicked(string uri)
    signal closeRequested()

    clip: true

    
    Rectangle {
        id: panelBg
        width: parent.width
        height: parent.height
        x: panel.open ? 0 : parent.width
        color: Root.Colors.surfaceContainer

        Behavior on x {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutCubic
            }
        }

        
        ColumnLayout {
            id: header
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: Root.Style.spacingXLarge
                leftMargin: Root.Style.spacingXLarge
                rightMargin: Root.Style.spacingXLarge
            }
            spacing: Root.Style.spacingSmall

            Text {
                Layout.fillWidth: true
                text: spotifyApi?.contextName || "Queue"
                font.family: Root.Style.fontFamily
                font.pixelSize: Root.Style.fontLarge
                font.weight: Font.DemiBold
                color: Root.Colors.surfaceText
                elide: Text.ElideRight
            }

            
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: Root.Style.radiusMedium
                color: Root.Colors.surfaceContainerHigh

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Root.Style.spacingMedium
                    anchors.rightMargin: Root.Style.spacingMedium
                    spacing: Root.Style.spacingSmall

                    Text {
                        text: "\u{F0349}"
                        font.family: Root.Style.iconFont
                        font.pixelSize: Root.Style.fontMedium
                        color: Root.Colors.outline
                    }

                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        font.family: Root.Style.fontFamily
                        font.pixelSize: Root.Style.fontNormal
                        color: Root.Colors.surfaceText
                        selectionColor: Root.Colors.primary
                        selectedTextColor: Root.Colors.primaryText
                        clip: true

                        property string filterText: ""

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Up || event.key === Qt.Key_Down ||
                                event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                                if (event.modifiers & Qt.ShiftModifier) {
                                    panel.closeRequested()
                                } else if (event.key === Qt.Key_Up) {
                                    trackList.decrementCurrentIndex()
                                } else if (event.key === Qt.Key_Down) {
                                    trackList.incrementCurrentIndex()
                                }
                                event.accepted = true
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Filter tracks..."
                            font: parent.font
                            color: Root.Colors.outline
                            visible: !parent.text && !parent.activeFocus
                        }

                        onTextChanged: filterText = text.toLowerCase()

                        onAccepted: {
                            if (trackList.currentIndex >= 0) {
                                let d = trackList.model[trackList.currentIndex]
                                if (d && d.uri) panel.trackClicked(d.uri)
                            }
                        }
                    }
                }
            }

            Text {
                text: {
                    let count = spotifyApi?.queueTracks?.length || 0
                    return count + " track" + (count !== 1 ? "s" : "")
                }
                font.family: Root.Style.fontFamily
                font.pixelSize: Root.Style.fontSmall
                color: Root.Colors.outline
            }

            
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Root.Style.spacingSmall
                height: 1
                color: Root.Colors.outlineVariant
            }
        }

        
        Text {
            anchors.centerIn: parent
            text: "Loading..."
            font.family: Root.Style.fontFamily
            font.pixelSize: Root.Style.fontNormal
            color: Root.Colors.outline
            visible: spotifyApi?.queueLoading ?? false
        }

        
        ListView {
            id: trackList
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                topMargin: Root.Style.spacingSmall
            }
            model: {
                let all = spotifyApi?.queueTracks || []
                let q = searchField.filterText
                if (!q) return all
                return all.filter(function(t) {
                    return t.name.toLowerCase().indexOf(q) !== -1 ||
                           t.artist.toLowerCase().indexOf(q) !== -1
                })
            }
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: -1
            highlightFollowsCurrentItem: true
            keyNavigationEnabled: false

            
            onCountChanged: {
                if (panel.open) _scrollToCurrent()
            }

            function _scrollToCurrent() {
                let tracks = spotifyApi?.queueTracks || []
                let uri = spotifyApi?.currentTrackUri || ""
                for (let i = 0; i < tracks.length; i++) {
                    if (tracks[i].uri === uri) {
                        positionViewAtIndex(i, ListView.Center)
                        break
                    }
                }
            }

            delegate: Item {
                id: trackDelegate
                width: trackList.width
                height: 58

                required property int index
                required property var modelData

                
                opacity: 0
                x: 40

                Component.onCompleted: {
                    if (panel.open) enterAnim.start()
                }

                SequentialAnimation {
                    id: enterAnim
                    PauseAnimation { duration: Math.min(trackDelegate.index * 30, 600) }
                    ParallelAnimation {
                        NumberAnimation {
                            target: trackDelegate; property: "opacity"
                            from: 0; to: 1; duration: 250
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: trackDelegate; property: "x"
                            from: 40; to: 0; duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: Root.Style.spacingMedium
                    anchors.rightMargin: Root.Style.spacingMedium
                    radius: Root.Style.radiusMedium
                    color: {
                        if (trackDelegate.modelData.uri === (spotifyApi?.currentTrackUri ?? ""))
                            return Qt.rgba(Root.Colors.primary.r, Root.Colors.primary.g, Root.Colors.primary.b, 0.12)
                        if (trackMA.containsMouse || trackDelegate.ListView.isCurrentItem)
                            return Qt.rgba(Root.Colors.primary.r, Root.Colors.primary.g, Root.Colors.primary.b, 0.06)
                        return "transparent"
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Root.Style.spacingMedium
                        anchors.rightMargin: Root.Style.spacingMedium
                        spacing: Root.Style.spacingMedium

                        
                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: Root.Style.radiusSmall
                            color: Root.Colors.surfaceContainerHigh
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: trackDelegate.modelData.artUrl || ""
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                visible: status === Image.Ready
                            }

                            
                            Text {
                                anchors.centerIn: parent
                                text: (trackDelegate.index + 1).toString()
                                font.family: Root.Style.fontFamily
                                font.pixelSize: Root.Style.fontSmall
                                color: Root.Colors.outline
                                visible: parent.children[0].status !== Image.Ready
                                    && trackDelegate.modelData.uri !== (spotifyApi?.currentTrackUri ?? "")
                            }

                            
                            Rectangle {
                                anchors.fill: parent
                                color: Qt.rgba(0, 0, 0, 0.5)
                                visible: trackDelegate.modelData.uri === (spotifyApi?.currentTrackUri ?? "")

                                Text {
                                    anchors.centerIn: parent
                                    text: "\u{F075A}"
                                    font.family: Root.Style.iconFont
                                    font.pixelSize: 18
                                    color: Root.Colors.primary
                                }
                            }
                        }

                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: trackDelegate.modelData.name || ""
                                font.family: Root.Style.fontFamily
                                font.pixelSize: Root.Style.fontNormal
                                font.weight: trackDelegate.modelData.uri === (spotifyApi?.currentTrackUri ?? "") ? Font.DemiBold : Font.Normal
                                color: trackDelegate.modelData.uri === (spotifyApi?.currentTrackUri ?? "") ? Root.Colors.primary : Root.Colors.surfaceText
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Text {
                                Layout.fillWidth: true
                                text: trackDelegate.modelData.artist || ""
                                font.family: Root.Style.fontFamily
                                font.pixelSize: Root.Style.fontSmall
                                color: Root.Colors.outline
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }

                        
                        Text {
                            text: _formatMs(trackDelegate.modelData.durationMs || 0)
                            font.family: Root.Style.fontFamily
                            font.pixelSize: Root.Style.fontSmall
                            color: Root.Colors.outline
                        }
                    }

                    MouseArea {
                        id: trackMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (trackDelegate.modelData.uri) {
                                panel.trackClicked(trackDelegate.modelData.uri)
                            }
                        }
                    }
                }
            }

            
            Rectangle {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                height: 20
                visible: trackList.contentY > 10
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Root.Colors.surfaceContainer }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Rectangle {
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                }
                height: 20
                visible: trackList.contentY < trackList.contentHeight - trackList.height - 10
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Root.Colors.surfaceContainer }
                }
            }
        }
    }

    onOpenChanged: {
        if (open && spotifyApi) {
            spotifyApi.fetchPlaybackContext()
            searchField.text = ""
            searchField.forceActiveFocus()
        } else {
            searchField.focus = false
        }
    }

    function _formatMs(ms) {
        let totalSec = Math.floor(ms / 1000)
        let min = Math.floor(totalSec / 60)
        let sec = totalSec % 60
        return min + ":" + (sec < 10 ? "0" : "") + sec
    }
}
