import QtQuick
import QtQuick.Layouts

import ".." as Root


Item {
    id: panel

    property var spotifyApi: null
    property bool open: false

    signal playlistSelected(string playlistUri, string playlistId, string playlistName)
    signal closeRequested()

    clip: true

    
    Rectangle {
        id: panelBg
        width: parent.width
        height: parent.height
        x: panel.open ? 0 : -parent.width
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
                text: "Your Playlists"
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
                                    playlistList.decrementCurrentIndex()
                                } else if (event.key === Qt.Key_Down) {
                                    playlistList.incrementCurrentIndex()
                                }
                                event.accepted = true
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Filter playlists..."
                            font: parent.font
                            color: Root.Colors.outline
                            visible: !parent.text && !parent.activeFocus
                        }

                        onTextChanged: filterText = text.toLowerCase()

                        onAccepted: {
                            if (playlistList.currentIndex >= 0) {
                                let d = playlistList.model[playlistList.currentIndex]
                                if (d && d.uri) panel.playlistSelected(d.uri, d.id, d.name)
                            }
                        }
                    }
                }
            }

            Text {
                text: {
                    let count = spotifyApi?.userPlaylists?.length || 0
                    return count + " playlist" + (count !== 1 ? "s" : "")
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
            visible: spotifyApi?.playlistsLoading ?? false
        }

        
        ListView {
            id: playlistList
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                topMargin: Root.Style.spacingSmall
            }
            model: {
                let all = spotifyApi?.userPlaylists || []
                let q = searchField.filterText
                if (!q) return all
                return all.filter(function(p) {
                    return p.name.toLowerCase().indexOf(q) !== -1 ||
                           p.owner.toLowerCase().indexOf(q) !== -1
                })
            }
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: -1
            highlightFollowsCurrentItem: true
            keyNavigationEnabled: false

            delegate: Item {
                id: plDelegate
                width: playlistList.width
                height: 64

                required property int index
                required property var modelData

                
                opacity: 0
                x: -40

                Component.onCompleted: {
                    if (panel.open) enterAnim.start()
                }

                SequentialAnimation {
                    id: enterAnim
                    PauseAnimation { duration: Math.min(plDelegate.index * 30, 600) }
                    ParallelAnimation {
                        NumberAnimation {
                            target: plDelegate; property: "opacity"
                            from: 0; to: 1; duration: 250
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: plDelegate; property: "x"
                            from: -40; to: 0; duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: Root.Style.spacingMedium
                    anchors.rightMargin: Root.Style.spacingMedium
                    radius: Root.Style.radiusMedium
                    color: plMA.containsMouse || plDelegate.ListView.isCurrentItem ? Qt.rgba(Root.Colors.primary.r, Root.Colors.primary.g, Root.Colors.primary.b, 0.08) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Root.Style.spacingMedium
                        anchors.rightMargin: Root.Style.spacingMedium
                        spacing: Root.Style.spacingMedium

                        
                        Rectangle {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            radius: Root.Style.radiusSmall
                            color: plDelegate.modelData.isCollection
                                ? Qt.rgba(Root.Colors.primary.r, Root.Colors.primary.g, Root.Colors.primary.b, 0.15)
                                : Root.Colors.surfaceContainerHigh
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: plDelegate.modelData.imageUrl || ""
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                visible: status === Image.Ready
                            }

                            
                            Text {
                                anchors.centerIn: parent
                                text: plDelegate.modelData.isCollection ? "\u{F02D1}" : "\u{F075A}"
                                font.family: Root.Style.iconFont
                                font.pixelSize: 18
                                color: plDelegate.modelData.isCollection ? Root.Colors.primary : Root.Colors.outline
                                visible: parent.children[0].status !== Image.Ready
                            }
                        }

                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: plDelegate.modelData.name || ""
                                font.family: Root.Style.fontFamily
                                font.pixelSize: Root.Style.fontNormal
                                font.weight: Font.Medium
                                color: Root.Colors.surfaceText
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Text {
                                Layout.fillWidth: true
                                text: {
                                    let parts = []
                                    if (plDelegate.modelData.owner)
                                        parts.push(plDelegate.modelData.owner)
                                    parts.push(plDelegate.modelData.trackCount + " tracks")
                                    return parts.join(" · ")
                                }
                                font.family: Root.Style.fontFamily
                                font.pixelSize: Root.Style.fontSmall
                                color: Root.Colors.outline
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }

                        
                        Text {
                            text: "\u{F040A}"
                            font.family: Root.Style.iconFont
                            font.pixelSize: Root.Style.fontMedium
                            color: Qt.rgba(Root.Colors.primary.r, Root.Colors.primary.g, Root.Colors.primary.b, plMA.containsMouse ? 1.0 : 0)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: plMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let d = plDelegate.modelData
                            if (d.uri) panel.playlistSelected(d.uri, d.id, d.name)
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
                visible: playlistList.contentY > 10
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
                visible: playlistList.contentY < playlistList.contentHeight - playlistList.height - 10
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Root.Colors.surfaceContainer }
                }
            }
        }
    }

    
    onOpenChanged: {
        if (open && spotifyApi) {
            spotifyApi.fetchUserPlaylists()
            searchField.text = ""
            searchField.forceActiveFocus()
        } else {
            searchField.focus = false
        }
    }
}
