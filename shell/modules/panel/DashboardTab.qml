import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.services
import qs.theme

// Dashboard tab (06, caelestia-parity card grid): user identity,
// weather, date, month calendar, resource rings, media mini-player —
// each its own Card card inside the panel's single silhouette. Three columns
// and two rows fill the panel's content box: the calendar sets the lower row
// and its column, the upper row takes the rest of the height, and the right
// column takes the rest of the width.
GridLayout {
    id: root
    columns: 3
    rowSpacing: Theme.panelGap
    columnSpacing: Theme.panelGap

    // Every card has one padding.
    readonly property real cardPadding: QsmShellStyle.Style.space4
    readonly property real lowerRowHeight: calendarContent.implicitHeight + cardPadding * 2
    readonly property real upperRowHeight: Theme.panelContentHeight - rowSpacing - lowerRowHeight
    readonly property real calendarColumnWidth: calendarContent.implicitWidth + cardPadding * 2

    Component.onCompleted: {
        WeatherService.refresh();
        SystemInfoService.refresh();
    }

    // Down from the tab bar lands on the first operable control (06), the
    // mini-player's transport; a card with nothing to drive keeps focus on
    // the bar.
    function focusFirst(): void {
        for (const button of [previousButton, playButton, nextButton]) {
            if (button.enabled) {
                button.forceActiveFocus();
                return;
            }
        }
    }

    // The avatar picture exists only where the user put one: the Image is
    // given ~/.face only once that file has loaded, so a machine without it
    // shows Avatar's icon with no load warning.
    property bool faceFound: false
    property FileView faceFile: FileView {
        path: Quickshell.env("HOME") + "/.face"
        printErrors: false
        onLoaded: root.faceFound = true
        onLoadFailed: root.faceFound = false
    }

    // The first two columns have a width of their own and the third takes the
    // rest, so the right edges of both rows meet the tab bar's.
    // 1. User card: avatar + distro badge, WM pill, uptime.
    QsmShellComponents.Card {
        id: userCard
        Layout.row: 0
        Layout.column: 0
        Layout.preferredWidth: Theme.dashboardUserCardWidth
        Layout.preferredHeight: root.upperRowHeight
        Layout.fillHeight: true

        RowLayout {
            id: userContent
            anchors.fill: parent
            anchors.margins: root.cardPadding
            spacing: QsmShellStyle.Style.space4

            Item {
                id: avatarWrap
                Layout.preferredWidth: Theme.dashboardAvatarSize
                Layout.preferredHeight: Theme.dashboardAvatarSize
                Layout.alignment: Qt.AlignVCenter

                // ~/.face is the XDG-ish user avatar convention; no person
                // glyph ships, so the fallback is "monitor" (06: avatar or
                // person/monitor icon).
                //
                // The version this replaces was `Rectangle { radius; clip }`
                // around the Image, which does not round the picture: item
                // clipping is rectangular. Avatar carries the MultiEffect mask
                // that actually cuts the corners.
                QsmShellComponents.Avatar {
                    anchors.fill: parent
                    size: Theme.dashboardAvatarSize
                    background: Theme.overlay
                    source: root.faceFound ? "file://" + Quickshell.env("HOME") + "/.face" : ""
                    icon: "monitor"
                    glyphSize: QsmShellStyle.Style.iconLg
                }

                // Distro logo badge, proud of the avatar's top-left corner.
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.leftMargin: -QsmShellStyle.Style.space1
                    anchors.topMargin: -QsmShellStyle.Style.space1
                    width: Theme.dashboardBadgeSize
                    height: Theme.dashboardBadgeSize
                    // Separation by VALUE, not a stroke — 11-theme ratifies
                    // flat fills with no outlines anywhere: the
                    // avatar disc is overlay, so the badge takes band.
                    radius: QsmShellStyle.Style.radiusPill
                    color: Theme.band

                    QsmShellComponents.SvgIcon {
                        anchors.centerIn: parent
                        name: "arch"
                        size: QsmShellStyle.Style.iconSm
                        color: Theme.textMuted
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: QsmShellStyle.Style.space2

                // Whose session this is, and on what. An identity card that
                // named neither was mostly empty ground.
                QsmShellComponents.Prose {
                    role: "heading"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    visible: text.length > 0
                    text: SystemInfoService.user
                    textFormat: Text.PlainText
                }

                QsmShellComponents.Prose {
                    role: "supporting"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    visible: text.length > 0
                    text: SystemInfoService.distro
                    textFormat: Text.PlainText
                }

                RowLayout {
                    Layout.topMargin: QsmShellStyle.Style.space1
                    spacing: QsmShellStyle.Style.space2
                    visible: SystemInfoService.wm.length > 0

                    QsmShellComponents.SvgIcon {
                        name: "window"
                        size: QsmShellStyle.Style.iconSm
                        color: Theme.textMuted
                    }

                    QsmShellComponents.Prose {
                        role: "metadata"
                        text: SystemInfoService.wm
                        textFormat: Text.PlainText
                    }
                }

                RowLayout {
                    spacing: QsmShellStyle.Style.space2

                    QsmShellComponents.SvgIcon {
                        name: "clock"
                        size: QsmShellStyle.Style.iconSm
                        color: Theme.textMuted
                    }

                    QsmShellComponents.Prose {
                        role: "metadata"
                        text: SystemInfoService.uptime
                    }
                }
            }
        }
    }

    // 2. Weather card: large glyph + temperature + one-line description.
    // Hides its content while offline (06 DEFAULT); card frame stays put so
    // the grid doesn't reflow.
    QsmShellComponents.Card {
        Layout.row: 0
        Layout.column: 1
        Layout.preferredWidth: root.calendarColumnWidth
        Layout.preferredHeight: root.upperRowHeight
        Layout.fillHeight: true

        ColumnLayout {
            id: weatherContent
            anchors.centerIn: parent
            visible: WeatherService.available
            spacing: QsmShellStyle.Style.space1

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: QsmShellStyle.Style.space3

                QsmShellComponents.SvgIcon {
                    name: "sunset"
                    size: QsmShellStyle.Style.iconXxl
                    // The weather card's pastel: sky (info), a notice, not a status.
                    color: Theme.info
                }

                QsmShellComponents.Prose {
                    role: "display"
                    text: WeatherService.temperature
                }
            }

            QsmShellComponents.Prose {
                role: "supporting"
                Layout.alignment: Qt.AlignHCenter
                text: WeatherService.description
            }
        }
    }

    // 6. Media mini-card: square art + half-ring position arc, transport.
    QsmShellComponents.Card {
        id: mediaCard
        Layout.row: 0
        Layout.column: 2
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        // One height for playing and idle, so the row does not jump when
        // playback starts or stops; the idle state centres inside it.
        Layout.preferredHeight: root.upperRowHeight
        Layout.fillHeight: true

        readonly property var player: MediaService.active
        readonly property real progress: (player && player.lengthSupported && player.length > 0)
            ? Math.max(0, Math.min(1, player.position / player.length)) : 0

        ColumnLayout {
            id: emptyContent
            anchors.fill: parent
            anchors.margins: root.cardPadding
            spacing: QsmShellStyle.Style.space2
            visible: mediaCard.player === null

            Item { Layout.fillHeight: true }

            // Same empty-state pattern as the launcher and clipboard
            // surfaces: one library type owns "nothing to show" everywhere.
            QsmShellComponents.EmptyState {
                Layout.alignment: Qt.AlignHCenter
                icon: "music"
                title: "Nothing playing"
            }

            Item { Layout.fillHeight: true }
        }

        ColumnLayout {
            id: playingContent
            anchors.fill: parent
            anchors.margins: root.cardPadding
            spacing: QsmShellStyle.Style.space2
            visible: mediaCard.player !== null

            Item {
                id: artWrap
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Theme.dashboardMediaArtSize + Theme.artworkRingStroke * 2
                Layout.preferredHeight: Theme.dashboardMediaArtSize + Theme.artworkRingStroke * 2

                // The SAME type the media tab uses, so the two cannot drift
                // apart.
                QsmShellComponents.Avatar {
                    anchors.centerIn: parent
                    size: Theme.dashboardMediaArtSize
                    background: Theme.overlay
                    source: mediaCard.player?.trackArtUrl ?? ""
                    icon: "music"
                    glyphSize: QsmShellStyle.Style.iconMd
                    progress: mediaCard.progress
                    progressColor: Theme.accent
                    ringWidth: Theme.artworkRingStroke
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                QsmShellComponents.Prose {
                    role: "title"
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: mediaCard.player?.trackTitle ?? ""
                    textFormat: Text.PlainText
                }

                QsmShellComponents.Prose {
                    role: "supporting"
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: mediaCard.player?.trackArtist ?? ""
                    textFormat: Text.PlainText
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: QsmShellStyle.Style.space4

                // IconButton, not a bare glyph + MouseArea: growing the hit
                // rect with a negative margin still left a 28px target under
                // the 44x44 pointer-affordance floor. Padding widens the
                // target itself (icon stays the mini-card's own size) and
                // the button carries hover/press/focus for free.
                QsmShellComponents.IconButton {
                    id: previousButton
                    icon: "skip-back"
                    size: "md"
                    enabled: mediaCard.player?.canGoPrevious ?? false
                    Accessible.name: "Previous track"
                    onClicked: mediaCard.player?.previous()
                }

                QsmShellComponents.IconButton {
                    id: playButton
                    icon: (mediaCard.player?.isPlaying ?? false) ? "pause" : "play"
                    size: "lg"
                    enabled: mediaCard.player?.canTogglePlaying ?? false
                    Accessible.name: mediaCard.player?.isPlaying ? "Pause" : "Play"
                    onClicked: mediaCard.player?.togglePlaying()
                }

                QsmShellComponents.IconButton {
                    id: nextButton
                    icon: "skip-forward"
                    size: "md"
                    enabled: mediaCard.player?.canGoNext ?? false
                    Accessible.name: "Next track"
                    onClicked: mediaCard.player?.next()
                }
            }
        }
    }

    // 3. Date card: the day big, the weekday over it and the month under it. The
    // time is the rail's; the dashboard does not tell it twice.
    QsmShellComponents.Card {
        id: dateCard
        Layout.row: 1
        Layout.column: 0
        Layout.preferredWidth: Theme.dashboardUserCardWidth
        Layout.fillHeight: true
        Layout.preferredHeight: root.lowerRowHeight

        property date now: new Date()

        Timer {
            interval: 60000
            running: true
            repeat: true
            onTriggered: dateCard.now = new Date()
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: QsmShellStyle.Style.space1

            QsmShellComponents.Prose {
                role: "supporting"
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(dateCard.now, "dddd")
            }

            QsmShellComponents.Prose {
                role: "hero"
                technical: true
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(dateCard.now, "d")
            }

            QsmShellComponents.Prose {
                role: "supporting"
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(dateCard.now, "MMMM yyyy")
            }
        }
    }

    // 4. Calendar card: the calendar at its own natural size, which sets the
    // lower row's height and this column's width, so its cells stay whole.
    QsmShellComponents.Card {
        Layout.row: 1
        Layout.column: 1
        Layout.preferredWidth: root.calendarColumnWidth
        Layout.preferredHeight: root.lowerRowHeight
        Layout.fillHeight: true

        QsmShellComponents.MonthCalendar {
            id: calendarContent
            // Small: the card shares the tab's height with the row above it.
            size: "sm"
            anchors.fill: parent
            anchors.margins: root.cardPadding
        }
    }

    // 5. Resources card: three vertical usage-% rings (CPU, memory, storage).
    QsmShellComponents.Card {
        Layout.row: 1
        Layout.column: 2
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.preferredHeight: root.lowerRowHeight
        Layout.fillHeight: true

        ColumnLayout {
            id: resourcesContent
            anchors.centerIn: parent
            spacing: QsmShellStyle.Style.space2

            QsmShellComponents.StatRing {
                Layout.alignment: Qt.AlignHCenter
                diameter: Theme.dashboardRingDiameter
                readingSize: QsmShellStyle.Style.textSm
                value: Math.max(0, PerformanceService.cpuUsage)
                reading: PerformanceService.cpuUsage < 0
                    ? "—" : `${Math.round(PerformanceService.cpuUsage * 100)}%`
                label: "CPU"
                fill: Theme.loadTone(PerformanceService.cpuUsage)
            }

            QsmShellComponents.StatRing {
                Layout.alignment: Qt.AlignHCenter
                diameter: Theme.dashboardRingDiameter
                readingSize: QsmShellStyle.Style.textSm
                value: Math.max(0, PerformanceService.memUsed)
                reading: PerformanceService.memUsed < 0
                    ? "—" : `${Math.round(PerformanceService.memUsed * 100)}%`
                label: "Memory"
                fill: Theme.loadTone(PerformanceService.memUsed)
            }

            QsmShellComponents.StatRing {
                Layout.alignment: Qt.AlignHCenter
                diameter: Theme.dashboardRingDiameter
                readingSize: QsmShellStyle.Style.textSm
                value: Math.max(0, PerformanceService.storageUsed)
                reading: PerformanceService.storageUsed < 0
                    ? "—" : `${Math.round(PerformanceService.storageUsed * 100)}%`
                label: "Storage"
                fill: Theme.loadTone(PerformanceService.storageUsed)
            }
        }
    }
}
