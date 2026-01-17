import QtQuick
import Quickshell
import Quickshell.Io
import QtCore

import QtQuick.Layouts
import Quickshell.Wayland
import QtQuick.Controls
import Quickshell.Hyprland
import Quickshell.Widgets
  
FocusScope {
    property var activeIndex: historyView.currentIndex === index 
    property alias clearBtn: clearItemBtn
    property alias itemRoot: itemRoot
    property bool rootHover: false
    property bool isImage: checkIsImage(model.text)
    property string imagePath: ""
    property string tempPath: ""
    property var imageInfo: undefined

    id: listFocus
    height: isImage ? 80 : 60

    Component.onCompleted: {
        if(isImage) handleImage(model)
        if(isSearching){
            Qt.callLater(() => {
                searchInput.forceActiveFocus()
                isSearching = false
            })
        }
    }

    Component.onDestruction: {
        if (imagePath !== "") {
            console.log("removing", imagePath)
            imageProcess.command = ["bash", "-c", `rm ${imagePath}`]
            imageProcess.startDetached()
        }
    }

    Process {
        id: imageProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("saved temp image", tempPath)
                imagePath = tempPath
            }
        }
    }

    Rectangle {
        id: itemRoot
        anchors.fill: listFocus
        color: activeFocus || rootHover ? '#6b6b6b' : "#444"
        radius: 6
        focus: true

        KeyNavigation.tab: clearItemBtn

        MouseArea {
            id: itemContainerMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                rootHover = true
            }
            onExited: {
                rootHover = false
            }
            onClicked: pasteSelected(model)
        }

        Item {
            focus: false
            anchors.fill: parent
            anchors.margins: 8

            Loader {
                id: contentLoader
                anchors.fill: parent
                sourceComponent: isImage ? imageComponent : textComponent
            }

            Component {
                id: textComponent
                Text {
                    focus: false
                    anchors.fill: parent
                    text: model.text
                    color: "white"
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                    rightPadding: 50
                }
            }

            Component {
                id: imageComponent
                Row {
                    spacing: 10
                    anchors.fill: parent
                    
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 60
                        height: 60
                        color: "#555"
                        radius: 4
                        
                        BusyIndicator {
                            anchors.centerIn: parent
                            running: imagePath === ""
                            width: 20
                            height: 20
                        }
                        
                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: imagePath
                            fillMode: Image.PreserveAspectFit
                            visible: imagePath !== ""
                            asynchronous: true
                            sourceSize.width: 60
                            sourceSize.height: 60
                        }
                    }
                    
                    Column {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter
                        
                        Text {
                            text: "Image (" + (imageInfo?.format.toUpperCase() || "") + ")"
                            textFormat: Text.PlainText
                            color: "white"
                            font.bold: true
                        }
                        
                        Text {
                            text: "Size: " + (imageInfo?.dimensions || "")
                            textFormat: Text.PlainText
                            color: "#CCCCCC"
                            font.pixelSize: 12
                        }
                        
                        Text {
                            text: imageInfo?.size || ""
                            textFormat: Text.PlainText
                            color: "#AAAAAA"
                            font.pixelSize: 10
                        }
                    }
                }
            }

            AbstractButton {
                property bool clearHover: false
                id: clearItemBtn
                onPressed: removeSelected(model, index)
                Keys.onReturnPressed: removeSelected(model, index)
                anchors.right: parent.right
                implicitHeight: 18
                implicitWidth: 18
                focus: true

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: removeSelected(model, index)
                    onEntered: {
                        parent.clearHover = true
                    }
                    onExited: {
                        parent.clearHover = false
                    }
                }

                KeyNavigation.tab: clearAllBtn

                Text {
                    focus: false
                    text: "󰆴"
                    color: clearItemBtn.activeFocus || parent.clearHover ? "#FFF" : '#818181'
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    anchors.fill: parent
                }
            }
        }

    }

    function handleImage(model) {
        if(!isImage) return

        const match = model.text.match(/^\[\[ binary data (.+?) (.+?) (.+?) (\d+x\d+) \]\]$/i)
        
        imageInfo = {
            size: match[1] + " " + match[2],
            format: match[3].toLowerCase(),
            dimensions: match[4]
        }
        
        tempPath = `/tmp/clipboard-img-${model.id}-${Date.now()}.${imageInfo.format}`
        imageProcess.exec(["bash", "-c", `printf '${model.id}' | cliphist decode > ${tempPath}`])
    } 
}