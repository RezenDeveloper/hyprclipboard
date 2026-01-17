import QtQuick
import Quickshell
import Quickshell.Io
import QtCore

import QtQuick.Layouts
import Quickshell.Wayland
import QtQuick.Controls
import Quickshell.Hyprland
import Quickshell.Widgets

import "src" 

PanelWindow {
    id: root
    visible: true
    color: "transparent"
    focusable: true
    aboveWindows: true
    WlrLayershell.namespace: `clipboard`
    exclusionMode: ExclusionMode.Ignore
    
    property var activeScreen: null
    property var fullClipboardArray: []
    property string filterQuery: ""
    property bool isSearching: false

    property var initialX: null
    property var initialY: null
    property var popUpWidth: 350
    property var popUpHeight: 430

    property Timer filterTimer: Timer {
        interval: 150
        onTriggered: updateFilteredItems()
    }
    
    anchors { 
        left: true  
        right: true  
        top: true
        bottom: true  
    }

    Settings {
        id: clipboardSettings
        category: "Clipboard"
    }

    ListModel  {
        id: clipboardHistory
    }

    Connections {
        target: Hyprland

        function onFocusedMonitorChanged(e) {
            const monitor = Hyprland.focusedMonitor
            if(!monitor) return
            if(activeScreen) return Qt.quit()
            
            if(!activeScreen) {
                for (const screen of Quickshell.screens) {
                    if (screen.name === monitor.name) {
                        activeScreen = screen
                    }
                }
            }
        }
    }

    Process {
        id: cursorCommand
        command: ["bash", "-c", "hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .x,.y,.width,.height' && hyprctl cursorpos"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: () => {
                const lines = this.text.trim().split('\n')
                
                if (lines.length >= 5) {
                    const monitorX = parseInt(lines[0])
                    const monitorY = parseInt(lines[1])
                    const monitorWidth = parseInt(lines[2])
                    const monitorHeight = parseInt(lines[3])
                    
                    const [cursorX, cursorY] = lines[4].split(',').map(item => parseInt(item.trim()))
                    
                    const cursorOnMonitorX = cursorX - monitorX
                    const cursorOnMonitorY = cursorY - monitorY
                    
                    const finalX = cursorOnMonitorX + popUpWidth > monitorWidth 
                        ? monitorWidth - popUpWidth 
                        : cursorOnMonitorX
                    const finalY = cursorOnMonitorY + popUpHeight > monitorHeight 
                        ? monitorHeight - popUpHeight 
                        : cursorOnMonitorY
                    
                    initialX = finalX
                    initialY = finalY
                    
                    popup.open()
                }
            }
        }
    }
    
    Process {
        id: cliphistProccess
        command: ["cliphist", "list"]
        running: true

        stdout: SplitParser {
            onRead: (line) => {
                const [_, id, __, text] = /(^\d{0,})(\t)(.*)$/g.exec(line)
                fullClipboardArray.push({id, text})
                updateFilteredItems()
            }
        }
    }
    
    Popup {
        id: popup
        x: initialX
        y: initialY
        implicitWidth: popUpWidth
        implicitHeight: popUpHeight
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        visible: false
        modal: false
        focus: true
        opacity: .75
        padding: 0
        margins: 0
        background: Rectangle {
            color: "transparent"
            border.color: "black"
        }

        onClosed: {
            Qt.quit()
        }

        contentItem: Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0,0,0,1)

            Rectangle {
                id: header
                color: "transparent"
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.topMargin: 10
                anchors.bottomMargin: 30

                height: 80
                z: 2

                ColumnLayout {
                    width: parent.width

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 5
                        
                        Label {
                            text: "Clipboard History"
                            color: "white"
                            font.bold: true
                            Layout.fillWidth: true
                            
                            Layout.alignment: Qt.AlignRight
                        }
                    
                        AbstractButton {
                            property bool hover: false
                            id: clearAllBtn
                            onPressed: clearAll()
                            Keys.onReturnPressed: clearAll()

                            Layout.fillHeight: true
                            implicitWidth: 50

                            Keys.onTabPressed: {
                                searchInput.forceActiveFocus()
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: clearAll()
                                onEntered: {
                                    parent.hover = true
                                }
                                onExited: {
                                    parent.hover = false
                                }
                            }


                            Label {
                                anchors.fill: parent
                                text: "Clear All"
                                color: parent.activeFocus || parent.hover ? "white" : '#bbbbbb'
                                font.pixelSize: 12
                                verticalAlignment: Text.AlignBottom
                                horizontalAlignment: Text.AlignHRight
                            }

                        }
                    }
                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        color: "#000000"
                        font.pixelSize: 16
                        placeholderText: "Search"
                        focus: true

                        Keys.onTabPressed: {
                            
                            if(clipboardHistory.count > 0) {
                                historyView.currentItem.itemRoot.forceActiveFocus()
                            } else {
                                clearAllBtn.forceActiveFocus()
                            }
                            
                        }
                        onTextEdited: {
                            filterSelection(text)
                            isSearching = true
                        }
                    }
                }
            }

            ScrollView {
                id: scroll
                anchors.topMargin: header.height
                anchors.fill: parent

                ScrollBar.vertical: ScrollBar {
                    parent: scroll
                    x: scroll.mirrored ? 0 : scroll.width - width
                    y: scroll.topPadding
                    width: 8
                    active: scroll.ScrollBar.horizontal.active
                    policy: ScrollBar.AlwaysOn

                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.rightMargin: 1
                }

                ListView {
                    id: historyView
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    model: clipboardHistory
                    cacheBuffer: 10
                    spacing: 10
                    focus: true
                    clip: true
                    
                    keyNavigationEnabled: true
                    keyNavigationWraps: false

                    Keys.onPressed: (event) => {
                        switch (event.key) {
                            case Qt.Key_Right:
                                incrementCurrentIndex()
                                if (currentItem) {
                                    currentItem.itemRoot.forceActiveFocus()
                                }
                                event.accepted = true
                                break
                            case Qt.Key_Left:
                                decrementCurrentIndex()
                                if (currentItem) {
                                    currentItem.itemRoot.forceActiveFocus()
                                }
                                event.accepted = true
                                break
                        }
                    }

                    delegate: ClipboardItem {
                        width: historyView.width
                        Keys.onReturnPressed: pasteSelected(model)
                        
                        onActiveIndexChanged: {
                            if (activeIndex) {
                                itemRoot.forceActiveFocus()
                            }
                        }
                        onFocusChanged: {
                            if (focus) {
                                historyView.positionViewAtIndex(index, ListView.Contain)
                            }
                        }
                    }
                }
            }

        }
    }


    function clearAll() {
        Quickshell.execDetached(["bash", "-c", "cliphist wipe"])
        clipboardHistory.clear()
        fullClipboardArray = []
    }
    
    function removeSelected(model, index) {
        Quickshell.execDetached(["bash", "-c", `printf '${model.id}' | cliphist delete`])
        fullClipboardArray = fullClipboardArray.filter(({ id }) => id !== model.id)
        clipboardHistory.remove(index)
    }
    
    function pasteSelected(model) {
        Quickshell.execDetached(["bash", "-c", `printf '${model.id}' | cliphist decode | wl-copy && hyprctl dispatch sendshortcut CTRL, V, activewindow`])
        Qt.quit()
    }

    function updateFilteredItems() {
        clipboardHistory.clear()
        
        if (filterQuery.trim() === "") {
            for (const item of fullClipboardArray) {
                clipboardHistory.append(item)
            }
        } else {
            const filtered = fullClipboardArray.filter(item => {
                if([">img", ">image"].includes(filterQuery)) {
                    return checkIsImage(item.text)
                } else {
                    return item.text.toLowerCase().includes(filterQuery.toLowerCase())
                }
            })
            for (const item of filtered) {
                clipboardHistory.append(item)
            }
        }
    }

    function checkIsImage(preview) {
        if (!preview) return false
        const imagePattern = /^\[\[ binary data .+ (png|jpg|jpeg|gif|bmp|svg|webp|tiff) \d+x\d+ \]\]$/i
        return imagePattern.test(preview.trim())
    }

    function filterSelection(query) {
        filterQuery = query
        filterTimer.restart()
    }
}