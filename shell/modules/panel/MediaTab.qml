import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.services
import qs.theme

// Media tab (06, per references/media-tab.png): circular artwork
// with a progress ring, title/album/artist, transport + seek, per-player
// source picker. Fallbacks (DEFAULT): no artwork -> type glyph in the
// circle; no player -> centered "nothing playing". Three zones
// (keep-it-simple, caelestia parity): artwork | title, seek, transport
// and the per-player source row. Cava/lyrics/bongocat are explicitly not
// ported. The tab is as tall as the panel's body, always, so nothing in it
// moves when a track, a player or the artwork appears.

Item {
    id: root

    readonly property var player: MediaService.active
    readonly property real progress: (MediaService.lengthSupported && MediaService.length > 0)
        ? Math.max(0, Math.min(1, MediaService.position / MediaService.length)) : 0

    // A constant: the tab fills the panel's column and never asks for more,
    // so a long title or a second player cannot widen it (the row's own
    // implicit width follows its text, which is why it is not read here).
    implicitWidth: Theme.mediaContentWidth
    // The panel body less its own margins, the tab bar and the gap under it
    // (PanelSurface's column); the viewport scrolls when a screen is shorter.
    implicitHeight: Theme.panelHeight - QsmShellStyle.Style.rolloutPadding * 2 - Theme.panelTabBarHeight - QsmShellStyle.Style.space3

    // The artwork grows to the body, up to a third of the column so the text
    // keeps the rest.
    readonly property real artBox: Math.min(implicitHeight - QsmShellStyle.Style.rolloutPadding * 2, Theme.mediaContentWidth / 3)
    // How far an arrow key moves the playhead.
    readonly property real seekStepSeconds: 5

    // Down from the tab bar (06): the seek ring when it can seek, else the
    // first transport button.
    function focusFirst(): void {
        const first = artwork.canSeek ? artwork : shuffleButton;
        if (first.enabled)
            first.forceActiveFocus();
    }

    // Same empty-state pattern as the launcher and clipboard surfaces.
    QsmShellComponents.EmptyState {
        anchors.centerIn: parent
        visible: root.player === null
        title: "Nothing playing"
    }

    RowLayout {
        id: mediaRow
        anchors.fill: parent
        anchors.margins: QsmShellStyle.Style.rolloutPadding
        visible: root.player !== null
        spacing: QsmShellStyle.Style.space5

        // LEFT: artwork circle + progress ring; clicking the ring seeks, and so
        // do the arrow keys while it holds keyboard focus.
        Item {
            id: artwork
            readonly property bool canSeek: MediaService.canSeek && MediaService.lengthSupported && MediaService.length > 0
            Layout.preferredWidth: root.artBox
            Layout.preferredHeight: root.artBox
            Layout.alignment: Qt.AlignVCenter
            activeFocusOnTab: canSeek
            Accessible.role: Accessible.Slider
            Accessible.name: "Seek"

            function seekBy(seconds: real): void {
                if (canSeek)
                    MediaService.seek(Math.max(0, Math.min(1,
                        (MediaService.position + seconds) / MediaService.length)));
            }
            Keys.onLeftPressed: event => { event.accepted = canSeek; seekBy(-root.seekStepSeconds); }
            Keys.onRightPressed: event => { event.accepted = canSeek; seekBy(root.seekStepSeconds); }

            // The artwork AND how far through it we are: one thing, one type.
            // The dashboard shares the same type.
            QsmShellComponents.Avatar {
                id: avatar
                anchors.centerIn: parent
                size: artwork.width - 2 * (Theme.artworkRingStroke + QsmShellStyle.Style.spaceTight)
                background: Theme.surface
                source: root.player?.trackArtUrl ?? ""
                icon: "music"
                // The size this fallback had before the migration; Avatar's
                // two-fifths default is the rule for initials, not for a glyph.
                glyphSize: QsmShellStyle.Style.iconXl
                progress: root.progress
                // The ring is the seek affordance: accent while it can be
                // sought, dimmed into the band when the player cannot.
                progressColor: artwork.canSeek ? Theme.accent : QsmShellStyle.Style.disabled(Theme.accent)
                ringWidth: Theme.artworkRingStroke
            }

            // Only the focus ring: the seek target is the ring band, not the
            // picture, so nothing grows or turns into a hand over the whole
            // circle.
            QsmShellComponents.StateLayer {
                anchors.fill: parent
                interactive: artwork.canSeek
                clickable: false
                target: null
                focused: artwork.activeFocus
                focusRadius: QsmShellStyle.Style.radiusPill
            }

            // Seek by clicking the ring's angle (12 o'clock = 0). A tap on the
            // picture inside the ring, or on the corner outside it, is not a seek.
            TapHandler {
                enabled: artwork.canSeek
                onTapped: (eventPoint, button) => {
                    const dx = eventPoint.position.x - artwork.width / 2;
                    const dy = eventPoint.position.y - artwork.height / 2;
                    const r = Math.hypot(dx, dy);
                    if (r < avatar.size / 2 || r > Math.max(avatar.implicitWidth, artwork.width) / 2)
                        return;
                    let angle = Math.atan2(dy, dx) + Math.PI / 2;
                    if (angle < 0)
                        angle += Math.PI * 2;
                    MediaService.seek(angle / (Math.PI * 2));
                }
            }
        }

        // CENTER: title/artist/album, seek row, transport row of five, source
        // row. Centred on the artwork; every line keeps its slot (an empty
        // line still has its height) and the source row is always there, so
        // a track with no album or a second player never moves the rows.
        ColumnLayout {
            Layout.fillWidth: true
            // Zero preferred width: the text's own width never sets the
            // column's, the row's remainder does, so ElideRight fires.
            Layout.preferredWidth: 0
            Layout.alignment: Qt.AlignVCenter
            spacing: QsmShellStyle.Style.space2

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
                text: root.player?.trackArtist ?? ""
                textFormat: Text.PlainText
            }

            QsmShellComponents.Prose {
                role: "metadata"
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.player?.trackAlbum ?? ""
                textFormat: Text.PlainText
            }

            // Seek row: position label — slider — duration label. Labels are
            // width-locked to the widest reachable reading ("000:00",
            // minutes past 99) so digit-width churn (0:59 -> 1:00) and a long
            // track never nudge the slider ends or truncate.
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: QsmShellStyle.Style.space2
                spacing: QsmShellStyle.Style.space2

                TextMetrics {
                    id: timeTemplate
                    font.family: Theme.technicalFontFamily
                    font.pixelSize: QsmShellStyle.Style.textSm
                    text: "000:00"
                }

                QsmShellComponents.Prose {
                    role: "supporting"
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
                    size: "sm"
                    accessibleName: "Seek"
                    enabled: MediaService.canSeek && MediaService.lengthSupported && MediaService.length > 0
                    value: root.progress
                    onMoved: MediaService.seek(seekSlider.value)
                }

                QsmShellComponents.Prose {
                    role: "supporting"
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
                Layout.topMargin: QsmShellStyle.Style.space2
                Layout.alignment: Qt.AlignHCenter
                spacing: QsmShellStyle.Style.space2

                QsmShellComponents.IconButton {
                    id: shuffleButton
                    icon: "shuffle"
                    size: "md"
                    color: MediaService.shuffle ? Theme.accent : Theme.text
                    enabled: MediaService.shuffleSupported
                    onClicked: MediaService.toggleShuffle()
                }

                QsmShellComponents.IconButton {
                    icon: "skip-back"
                    size: "lg"
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: root.player?.previous()
                }

                QsmShellComponents.IconButton {
                    icon: (root.player?.isPlaying ?? false) ? "pause" : "play"
                    size: "xl"
                    enabled: root.player?.canTogglePlaying ?? false
                    Accessible.name: root.player?.isPlaying ? "Pause" : "Play"
                    onClicked: root.player?.togglePlaying()
                }

                QsmShellComponents.IconButton {
                    icon: "skip-forward"
                    size: "lg"
                    enabled: root.player?.canGoNext ?? false
                    onClicked: root.player?.next()
                }

                QsmShellComponents.IconButton {
                    icon: MediaService.loopState === MprisLoopState.Track ? "repeat-1" : "repeat"
                    size: "md"
                    color: MediaService.loopState !== MprisLoopState.None ? Theme.accent : Theme.text
                    enabled: MediaService.loopSupported
                    onClicked: MediaService.cycleLoop()
                }
            }

            // Source row: every MPRIS player. A lone player shows as the one
            // active capsule, so the row is always there and the transport
            // above never moves when a second player appears.
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: QsmShellStyle.Style.space2
                spacing: QsmShellStyle.Style.space2

                Repeater {
                    model: MediaService.players

                    QsmShellComponents.Capsule {
                        required property var modelData
                        icon: "music"
                        label: modelData.identity || "player"
                        checkable: true
                        active: MediaService.active === modelData
                        onClicked: MediaService.selected = modelData
                    }
                }
            }
        }
    }
}
