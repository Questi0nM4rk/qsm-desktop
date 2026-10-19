import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.QsmShell.Components as QsmShellComponents
import qs.services
import qs.theme

// Dashboard tab (06 RATIFIED, caelestia-parity card grid): user identity,
// weather, datetime, month calendar, resource rings, media mini-player —
// each its own Card card inside the panel's single silhouette.
GridLayout {
    id: root
    columns: 3
    rowSpacing: Theme.space3
    columnSpacing: Theme.space3

    Component.onCompleted: {
        WeatherService.refresh();
        SystemInfoService.refresh();
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
        radius: Theme.panelCardRadius
        id: userCard
        Layout.row: 0
        Layout.column: 0
        Layout.fillWidth: true
        Layout.preferredWidth: Theme.dashboardUserCardWidth
        Layout.preferredHeight: userContent.implicitHeight + Theme.space4 * 2
        Layout.fillHeight: true

        RowLayout {
            id: userContent
            anchors.fill: parent
            anchors.margins: Theme.space4
            spacing: Theme.space4

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
                    glyphSize: Theme.iconLg
                }

                // Distro logo badge, proud of the avatar's top-left corner.
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.leftMargin: -Theme.space1
                    anchors.topMargin: -Theme.space1
                    width: Theme.dashboardBadgeSize
                    height: Theme.dashboardBadgeSize
                    // Separation by VALUE, not a stroke — 11-theme ratifies
                    // flat fills with no outlines anywhere (audit S5-F1): the
                    // avatar disc is overlay, so the badge takes band.
                    radius: width / 2
                    color: Theme.band

                    QsmShellComponents.SvgIcon {
                        anchors.centerIn: parent
                        name: "arch"
                        size: Theme.iconSm
                        color: Theme.accent
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.space2

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

                QsmShellComponents.Capsule {
                    Layout.alignment: Qt.AlignLeft
                    Layout.topMargin: Theme.space1
                    size: "sm"
                    icon: "window"
                    label: SystemInfoService.wm
                }

                RowLayout {
                    spacing: Theme.space2

                    QsmShellComponents.SvgIcon {
                        name: "clock"
                        size: Theme.iconSm
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
        radius: Theme.panelCardRadius
        Layout.row: 0
        Layout.column: 1
        Layout.fillWidth: true
        Layout.preferredWidth: Theme.dashboardWeatherCardWidth
        Layout.preferredHeight: weatherContent.implicitHeight + Theme.space4 * 2
        Layout.fillHeight: true

        ColumnLayout {
            id: weatherContent
            anchors.centerIn: parent
            visible: WeatherService.available
            spacing: Theme.space1

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.space3

                QsmShellComponents.SvgIcon {
                    name: "sunset"
                    size: Theme.iconXxl
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
        radius: Theme.panelCardRadius
        id: mediaCard
        Layout.row: 0
        Layout.column: 2
        Layout.fillWidth: true
        Layout.preferredWidth: Theme.dashboardMediaCardWidth
        // One height for playing and idle, so the row does not jump when
        // playback starts or stops; the idle state centres inside it.
        Layout.preferredHeight: playingContent.implicitHeight + Theme.space3 * 2
        Layout.fillHeight: true

        readonly property var player: MediaService.active
        readonly property real progress: (player && player.lengthSupported && player.length > 0)
            ? Math.max(0, Math.min(1, player.position / player.length)) : 0

        ColumnLayout {
            id: emptyContent
            anchors.fill: parent
            anchors.margins: Theme.space3
            spacing: Theme.space2
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
            anchors.margins: Theme.space3
            spacing: Theme.space2
            visible: mediaCard.player !== null

            Item {
                id: artWrap
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Theme.dashboardMediaArtSize + Theme.dashboardRingStroke * 2
                Layout.preferredHeight: Theme.dashboardMediaArtSize + Theme.dashboardRingStroke * 2

                // The SAME type the media tab uses, so the two cannot drift
                // apart again. It used to be a square sleeve with a half ring
                // behind it — and the sleeve's own corners hid the arc, which
                // is what two independent assemblies of one idea get you
                // (owner 2026-09-06).
                QsmShellComponents.Avatar {
                    anchors.centerIn: parent
                    size: Theme.dashboardMediaArtSize
                    background: Theme.overlay
                    source: mediaCard.player?.trackArtUrl ?? ""
                    icon: "music"
                    glyphSize: Theme.iconMd
                    progress: mediaCard.progress
                    progressColor: Theme.accent
                    ringWidth: Theme.dashboardRingStroke
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
                spacing: Theme.space4

                // IconButton, not a bare glyph + MouseArea: growing the hit
                // rect with a negative margin still left a 28px target under
                // the 44x44 pointer-affordance floor. Padding widens the
                // target itself (icon stays the mini-card's own size) and
                // the button carries hover/press/focus for free.
                QsmShellComponents.IconButton {
                    icon: "skip-back"
                    size: Theme.iconSm
                    padding: Theme.space4
                    enabled: mediaCard.player?.canGoPrevious ?? false
                    Accessible.name: "Previous track"
                    onClicked: mediaCard.player?.previous()
                }

                QsmShellComponents.IconButton {
                    icon: (mediaCard.player?.isPlaying ?? false) ? "pause" : "play"
                    size: Theme.iconMd
                    enabled: mediaCard.player?.canTogglePlaying ?? false
                    Accessible.name: mediaCard.player?.isPlaying ? "Pause" : "Play"
                    onClicked: mediaCard.player?.togglePlaying()
                }

                QsmShellComponents.IconButton {
                    icon: "skip-forward"
                    size: Theme.iconSm
                    padding: Theme.space4
                    enabled: mediaCard.player?.canGoNext ?? false
                    Accessible.name: "Next track"
                    onClicked: mediaCard.player?.next()
                }
            }
        }
    }

    // 3. DateTime card: stacked big hours/minutes, 24h, live.
    QsmShellComponents.Card {
        radius: Theme.panelCardRadius
        id: dateTimeCard
        Layout.row: 1
        Layout.column: 0
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: dateTimeContent.implicitHeight + Theme.space4 * 2

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
        radius: Theme.panelCardRadius
        Layout.row: 1
        Layout.column: 1
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: calendarContent.implicitHeight + Theme.space4 * 2

        QsmShellComponents.MonthCalendar {
            id: calendarContent
            anchors.fill: parent
            anchors.margins: Theme.space4
        }
    }

    // 5. Resources card: three vertical usage-% rings (CPU, memory, storage).
    QsmShellComponents.Card {
        radius: Theme.panelCardRadius
        Layout.row: 1
        Layout.column: 2
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: resourcesContent.implicitHeight + Theme.space4 * 2

        ColumnLayout {
            id: resourcesContent
            anchors.centerIn: parent
            spacing: Theme.space2

            QsmShellComponents.StatRing {
                Layout.alignment: Qt.AlignHCenter
                diameter: Theme.dashboardRingDiameter
                strokeWidth: Theme.dashboardRingStroke
                readingSize: Theme.textSm
                value: Math.max(0, PerformanceService.cpuUsage)
                reading: PerformanceService.cpuUsage < 0
                    ? "—" : `${Math.round(PerformanceService.cpuUsage * 100)}%`
                label: "CPU"
                fill: Theme.loadTone(PerformanceService.cpuUsage)
            }

            QsmShellComponents.StatRing {
                Layout.alignment: Qt.AlignHCenter
                diameter: Theme.dashboardRingDiameter
                strokeWidth: Theme.dashboardRingStroke
                readingSize: Theme.textSm
                value: Math.max(0, PerformanceService.memUsed)
                reading: PerformanceService.memUsed < 0
                    ? "—" : `${Math.round(PerformanceService.memUsed * 100)}%`
                label: "Memory"
                fill: Theme.loadTone(PerformanceService.memUsed)
            }

            QsmShellComponents.StatRing {
                Layout.alignment: Qt.AlignHCenter
                diameter: Theme.dashboardRingDiameter
                strokeWidth: Theme.dashboardRingStroke
                readingSize: Theme.textSm
                value: Math.max(0, PerformanceService.storageUsed)
                reading: PerformanceService.storageUsed < 0
                    ? "—" : `${Math.round(PerformanceService.storageUsed * 100)}%`
                label: "Storage"
                fill: Theme.loadTone(PerformanceService.storageUsed)
            }
        }
    }
}
