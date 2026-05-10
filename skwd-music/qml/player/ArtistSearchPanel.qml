import QtQuick
import QtQuick.Layouts

import ".." as Root


Item {
    id: panel

    property var spotifyApi: null
    property bool open: false

    signal artistSelected(string artistUri, string artistName)
    signal closeRequested()

    clip: true

    
    Rectangle {
        id: panelBg
        width: parent.width
        height: parent.height * 0.85
        radius: Root.Style.radiusXLarge
        y: panel.open ? (parent.height - height) : parent.height
        color: Root.Colors.surfaceContainer

        Behavior on y {
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
                text: "Search Artists"
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

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Up || event.key === Qt.Key_Down ||
                                event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                                if (event.modifiers & Qt.ShiftModifier) {
                                    panel.closeRequested()
                                } else if (event.key === Qt.Key_Up) {
                                    artistList.decrementCurrentIndex()
                                } else if (event.key === Qt.Key_Down) {
                                    artistList.incrementCurrentIndex()
                                }
                                event.accepted = true
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Artist name..."
                            font: parent.font
                            color: Root.Colors.outline
                            visible: !parent.text && !parent.activeFocus
                        }

                        onAccepted: {
                            if (artistList.currentIndex >= 0) {
                                let d = artistList.model[artistList.currentIndex]
                                if (d && d.uri) panel.artistSelected(d.uri, d.name)
                            } else if (text.trim() && spotifyApi) {
                                spotifyApi.searchArtistsByQuery(text.trim())
                            }
                        }
                    }
                }
            }

            Text {
                text: {
                    let count = spotifyApi?.searchArtists?.length || 0
                    return count + " result" + (count !== 1 ? "s" : "")
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
            visible: spotifyApi?.artistSearchLoading ?? false
        }

        
        ListView {
            id: artistList
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                topMargin: Root.Style.spacingSmall
            }
            model: spotifyApi?.searchArtists || []
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: -1
            highlightFollowsCurrentItem: true
            keyNavigationEnabled: false

            delegate: Item {
                id: artDelegate
                width: artistList.width
                height: 64

                required property int index
                required property var modelData

                
                opacity: 0
                transform: Translate { id: artEnterTranslate; y: 40 }

                Component.onCompleted: {
                    if (panel.open) enterAnim.start()
                }

                SequentialAnimation {
                    id: enterAnim
                    PauseAnimation { duration: Math.min(artDelegate.index * 30, 600) }
                    ParallelAnimation {
                        NumberAnimation {
                            target: artDelegate; property: "opacity"
                            from: 0; to: 1; duration: 250
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: artEnterTranslate; property: "y"
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
                    color: artMA.containsMouse || artDelegate.ListView.isCurrentItem ? Qt.rgba(Root.Colors.primary.r, Root.Colors.primary.g, Root.Colors.primary.b, 0.08) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Root.Style.spacingMedium
                        anchors.rightMargin: Root.Style.spacingMedium
                        spacing: Root.Style.spacingMedium

                        
                        Rectangle {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            radius: 22
                            color: Root.Colors.surfaceContainerHigh
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: artDelegate.modelData.imageUrl || ""
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "\u{F0004}"
                                font.family: Root.Style.iconFont
                                font.pixelSize: 18
                                color: Root.Colors.outline
                                visible: parent.children[0].status !== Image.Ready
                            }
                        }

                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: artDelegate.modelData.name || ""
                                font.family: Root.Style.fontFamily
                                font.pixelSize: Root.Style.fontNormal
                                font.weight: Font.Medium
                                color: Root.Colors.surfaceText
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Text {
                                Layout.fillWidth: true
                                text: artDelegate.modelData.genres || ""
                                font.family: Root.Style.fontFamily
                                font.pixelSize: Root.Style.fontSmall
                                color: Root.Colors.outline
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                visible: text !== ""
                            }
                        }

                        
                        Text {
                            text: "\u{F040A}"
                            font.family: Root.Style.iconFont
                            font.pixelSize: Root.Style.fontMedium
                            color: Qt.rgba(Root.Colors.primary.r, Root.Colors.primary.g, Root.Colors.primary.b, artMA.containsMouse ? 1.0 : 0)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: artMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let d = artDelegate.modelData
                            if (d.uri) panel.artistSelected(d.uri, d.name)
                        }
                    }
                }
            }

            
            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 20
                visible: artistList.contentY > 10
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Root.Colors.surfaceContainer }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            
            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 20
                visible: artistList.contentY < artistList.contentHeight - artistList.height - 10
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Root.Colors.surfaceContainer }
                }
            }
        }
    }

    onOpenChanged: {
        if (open) {
            searchField.text = ""
            spotifyApi.searchArtists = []
            searchField.forceActiveFocus()
        } else {
            searchField.focus = false
        }
    }
}
