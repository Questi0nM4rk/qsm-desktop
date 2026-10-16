import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.QsmShell.Components as QsmShellComponents
import qs.services
import qs.theme

// Media tab (06 RATIFIED, per references/media-tab.png): circular artwork
// with a progress ring, title/album/artist, transport + seek, per-player
// source picker. Fallbacks (DEFAULT): no artwork -> type glyph in the
// circle; no player -> centered "nothing playing". Three zones (owner
// caelestia-parity ruling, keep-it-simple): artwork | title/seek/transport |
// per-player source picker. Cava/lyrics/bongocat are explicitly not ported.

Item {
    id: root

    readonly property var player: MediaService.active
    readonly property real progress: (MediaService.lengthSupported && MediaService.length > 0)
        ? Math.max(0, Math.min(1, MediaService.position / MediaService.length)) : 0

    implicitWidth: Math.max(Theme.mediaContentWidth, mediaRow.implicitWidth + Theme.space4 * 2)
    implicitHeight: Math.max(mediaRow.implicitHeight, Theme.mediaArtSize + Theme.space4 * 2)

    // Same empty-state pattern as the launcher and clipboard surfaces.
    QsmShellComponents.EmptyState {
        anchors.centerIn: parent
        visible: root.player === null
        title: "Nothing playing"
    }

    RowLayout {
        id: mediaRow
        anchors.fill: parent
        anchors.margins: Theme.space4
        visible: root.player !== null
        spacing: Theme.space5

        // LEFT: artwork circle + progress ring; clicking the ring seeks.
        Item {
            id: artwork
            Layout.preferredWidth: Theme.mediaArtSize
            Layout.preferredHeight: Theme.mediaArtSize
            Layout.alignment: Qt.AlignVCenter

            // The artwork AND how far through it we are: one thing, one type.
            // This surface and the dashboard used to assemble it separately
            // and reached two different pictures, which is the proof it never
            // belonged to either of them.
            QsmShellComponents.Avatar {
                anchors.centerIn: parent
                size: Theme.mediaArtSize - 24
                background: Theme.surface
                source: root.player?.trackArtUrl ?? ""
                icon: "music"
                // The size this fallback had before the migration; Avatar's
                // two-fifths default is the rule for initials, not for a glyph.
                glyphSize: Theme.iconXl
                progress: root.progress
                ringWidth: 5
            }

            // Seek by clicking the ring's angle (12 o'clock = 0).
            MouseArea {
                anchors.fill: parent
                enabled: MediaService.canSeek && MediaService.lengthSupported
                onClicked: event => {
                    const dx = event.x - width / 2;
                    const dy = event.y - height / 2;
                    let angle = Math.atan2(dy, dx) + Math.PI / 2;
                    if (angle < 0)
                        angle += Math.PI * 2;
                    MediaService.seek(angle / (Math.PI * 2));
                }
            }
        }

        // CENTER: title/artist/album, seek row, transport row of five.
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.space2

            QsmShellComponents.Prose {
                role: "heading"
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.player?.trackTitle || "Unknown title"
                textFormat: Text.PlainText
            }

            QsmShellComponents.Prose {
                role: "supporting"
                Layout.fillWidth: true
                elide: Text.ElideRight
                visible: text.length > 0
                text: root.player?.trackArtist ?? ""
                textFormat: Text.PlainText
            }

            QsmShellComponents.Prose {
                role: "metadata"
                Layout.fillWidth: true
                elide: Text.ElideRight
                visible: text.length > 0
                text: root.player?.trackAlbum ?? ""
                textFormat: Text.PlainText
            }

            // Seek row: position label — slider — duration label. Labels are
            // width-locked to a zeroed "00:00" template so digit-width churn
            // (e.g. 0:59 -> 1:00) never nudges the slider ends.
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Theme.space2
                spacing: Theme.space2

                TextMetrics {
                    id: timeTemplate
                    font.family: Theme.technicalFontFamily
                    font.pixelSize: Theme.textXs
                    text: "00:00"
                }

                QsmShellComponents.Prose {
                    role: "metadata"
                    technical: true
                    Layout.preferredWidth: timeTemplate.width
                    horizontalAlignment: Text.AlignRight
                    text: MediaService.formatTime(MediaService.position)
                }

                // No wheelUnits: scrubbing a track wants a deliberate pointer,
                // not something a stray scroll over the panel can do.
                QsmShellComponents.Slider {
                    id: seekSlider
                    Layout.fillWidth: true
                    enabled: MediaService.canSeek && MediaService.lengthSupported && MediaService.length > 0
                    value: root.progress
                    onMoved: MediaService.seek(seekSlider.value)
                }

                QsmShellComponents.Prose {
                    role: "metadata"
                    technical: true
                    Layout.preferredWidth: timeTemplate.width
                    horizontalAlignment: Text.AlignLeft
                    text: MediaService.formatTime(MediaService.length)
                }
            }

            // Transport: shuffle, previous, play/pause, next, repeat. Every
            // one is an IconButton — a real target with the shell's one
            // hover/press response, not a bare glyph with a MouseArea.
            RowLayout {
                Layout.topMargin: Theme.space2
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.space2

                QsmShellComponents.IconButton {
                    icon: "shuffle"
                    size: Theme.iconMd
                    color: MediaService.shuffle ? Theme.accent : Theme.text
                    enabled: MediaService.shuffleSupported
                    onClicked: MediaService.toggleShuffle()
                }

                QsmShellComponents.IconButton {
                    icon: "skip-back"
                    size: Theme.iconLg
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: root.player?.previous()
                }

                QsmShellComponents.IconButton {
                    icon: (root.player?.isPlaying ?? false) ? "pause" : "play"
                    size: Theme.iconXl
                    enabled: root.player?.canTogglePlaying ?? false
                    Accessible.name: root.player?.isPlaying ? "Pause" : "Play"
                    onClicked: root.player?.togglePlaying()
                }

                QsmShellComponents.IconButton {
                    icon: "skip-forward"
                    size: Theme.iconLg
                    enabled: root.player?.canGoNext ?? false
                    onClicked: root.player?.next()
                }

                QsmShellComponents.IconButton {
                    icon: MediaService.loopState === MprisLoopState.Track ? "repeat-1" : "repeat"
                    size: Theme.iconMd
                    color: MediaService.loopState !== MprisLoopState.None ? Theme.accent : Theme.text
                    enabled: MediaService.loopSupported
                    onClicked: MediaService.cycleLoop()
                }
            }
        }

        // RIGHT: per-player source picker (all MPRIS players); a lone
        // player needs no picker, so this stays hidden until there's a
        // choice to make.
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            visible: MediaService.players.length > 1
            spacing: Theme.space2

            Repeater {
                model: MediaService.players

                QsmShellComponents.Capsule {
                    required property var modelData
                    icon: "music"
                    label: modelData.identity || "player"
                    active: MediaService.active === modelData
                    onClicked: MediaService.selected = modelData
                }
            }
        }
    }
}
