import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.services
import qs.theme

// Dashboard tab (06, caelestia-parity card grid): user identity,
// weather, datetime, month calendar, resource rings, media mini-player —
// each its own Card card inside the panel's single silhouette.
GridLayout {
    id: root
    columns: 3
    rowSpacing: QsmShellStyle.Style.space3
    columnSpacing: QsmShellStyle.Style.space3

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

    // Every card fills its column; the preferred widths are the floor the
    // grid starts from, and both gutters are one step, so the right edges of
    // row 0 and row 1 meet.
    // 1. User card: avatar + distro badge, WM pill, uptime.
    QsmShellComponents.Card {
        id: userCard
        Layout.row: 0
        Layout.column: 0
        Layout.fillWidth: true
        Layout.preferredWidth: Theme.dashboardUserCardWidth
        Layout.preferredHeight: userContent.implicitHeight + QsmShellStyle.Style.space4 * 2
        Layout.fillHeight: true

        RowLayout {
            id: userContent
            anchors.fill: parent
            anchors.margins: QsmShellStyle.Style.space4
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
                    // flat fills with no outlines anywhere (audit S5-F1): the
                    // avatar disc is overlay, so the badge takes band.
                    radius: QsmShellStyle.Style.radiusPill
                    color: Theme.band

                    QsmShellComponents.SvgIcon {
                        anchors.centerIn: parent
                        name: "arch"
                        size: QsmShellStyle.Style.iconSm
                        color: Theme.accent
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
        Layout.fillWidth: true
        Layout.preferredWidth: Theme.dashboardWeatherCardWidth
        Layout.preferredHeight: weatherContent.implicitHeight + QsmShellStyle.Style.space4 * 2
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
        Layout.preferredWidth: Theme.dashboardMediaCardWidth
        // One height for playing and idle, so the row does not jump when
        // playback starts or stops; the idle state centres inside it.
        Layout.preferredHeight: playingContent.implicitHeight + QsmShellStyle.Style.space3 * 2
        Layout.fillHeight: true

        readonly property var player: MediaService.active
        readonly property real progress: (player && player.lengthSupported && player.length > 0)
            ? Math.max(0, Math.min(1, player.position / player.length)) : 0

        ColumnLayout {
            id: emptyContent
            anchors.fill: parent
            anchors.margins: QsmShellStyle.Style.space3
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
            anchors.margins: QsmShellStyle.Style.space3
            spacing: QsmShellStyle.Style.space2
            visible: mediaCard.player !== null

            Item {
                id: artWrap
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Theme.dashboardMediaArtSize + Theme.artworkRingStroke * 2
                Layout.preferredHeight: Theme.dashboardMediaArtSize + Theme.artworkRingStroke * 2

                // The SAME type the media tab uses, so the two cannot drift
                // apart again. It used to be a square sleeve with a half ring
                // behind it — and the sleeve's own corners hid the arc, which
                // is what two independent assemblies of one idea get you.
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

    // 3. DateTime card: stacked big hours/minutes, 24h, live.
    QsmShellComponents.Card {
        id: dateTimeCard
        Layout.row: 1
        Layout.column: 0
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: dateTimeContent.implicitHeight + QsmShellStyle.Style.space4 * 2

        property date now: new Date()

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: dateTimeCard.now = new Date()
        }

        ColumnLayout {
            id: dateTimeContent
            anchors.centerIn: parent
            spacing: 0

            QsmShellComponents.Prose {
                role: "hero"
                technical: true
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(dateTimeCard.now, "HH")
            }

            QsmShellComponents.Prose {
                role: "hero"
                technical: true
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(dateTimeCard.now, "mm")
            }
        }
    }

    // 4. Calendar card: fills whatever width row 1 leaves between the
    // datetime and resources cards.
    QsmShellComponents.Card {
        Layout.row: 1
        Layout.column: 1
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: calendarContent.implicitHeight + QsmShellStyle.Style.space4 * 2

        QsmShellComponents.MonthCalendar {
            id: calendarContent
            anchors.fill: parent
            anchors.margins: QsmShellStyle.Style.space4
        }
    }

    // 5. Resources card: three vertical usage-% rings (CPU, memory, storage).
    QsmShellComponents.Card {
        Layout.row: 1
        Layout.column: 2
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: resourcesContent.implicitHeight + QsmShellStyle.Style.space4 * 2

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
