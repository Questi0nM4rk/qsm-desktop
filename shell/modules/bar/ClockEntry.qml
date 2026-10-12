import QtQuick
import Quickshell
import qs.QsmShell.Components as QsmShellComponents
import qs.theme

// Clock entry (03 RATIFIED, amended 2026-08-17 — caelestia anatomy): HOURS
// stacked over MINUTES as the large digits — digit width metric-locked
// against a "00" template so 11 vs 08 never wobbles the column — with the
// DATE beneath at the small size, all inside the pill. Text only, no clock
// icon. Hovering opens the calendar popout like every other hover entry.
// No background (owner 2026-08-18): the pill measured 1.29:1 against the band
// and read as the same plane anyway — the group divider lines carry the
// separation now.
Item {
    id: root

    property var popouts: null
    readonly property date now: clock.date

    width: Theme.railWidth
    implicitHeight: content.implicitHeight + Theme.space2 * 2

    // Hover-enter opens the calendar; whether it STAYS open is EdgeScene's
    // geometric region test, not a leave-time close call here (03-rail
    // "Popouts", RATIFIED 2026-09-07).
    HoverHandler {
        onHoveredChanged: {
            if (hovered)
                root.popouts?.show("calendar", root,
                    Qt.formatDate(root.now, "MMMM yyyy"), "", null);
        }
    }

    // One shared system clock at minute precision — the display shows no
    // seconds, so a per-instance 1s timer was 60x the wakeups for nothing.
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Metric-locks the digit column against a fixed "00" template — the
    // hour/minute Text elements below share this width so an 11 vs 08
    // reading never shifts the pill's content (03 amended).
    TextMetrics {
        id: digitMetrics
        font.family: Theme.technicalFontFamily
        font.pixelSize: Theme.railClockDigitSize
        font.weight: Theme.weightBold
        text: "00"
    }

    component RollingDigits: Item {
        id: digits

        required property string value
        property string previous: value
        property string current: value
        property bool ready: false
        property real progress: 1

        TextMetrics {
            id: metrics
            font.family: Theme.technicalFontFamily
            font.pixelSize: Theme.railClockDigitSize
            font.weight: Theme.weightBold
            text: "00"
        }

        implicitWidth: metrics.width
        implicitHeight: metrics.height
        clip: true

        onValueChanged: {
            if (!ready) {
                current = value;
                previous = value;
                return;
            }
            previous = current;
            current = value;
            progress = 0;
            Qt.callLater(() => progress = 1);
        }
        Component.onCompleted: ready = true

        Behavior on progress {
            NumberAnimation { duration: Motion.fast; easing.type: Motion.emphasizedEasing }
        }

        QsmShellComponents.Prose {
            role: "hero"
            technical: true
            anchors.horizontalCenter: parent.horizontalCenter
            y: -digits.progress * height
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: digits.previous
            opacity: 1 - digits.progress
            font.pixelSize: Theme.railClockDigitSize
        }

        QsmShellComponents.Prose {
            role: "hero"
            technical: true
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - digits.progress * height
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: digits.current
            opacity: digits.progress
            font.pixelSize: Theme.railClockDigitSize
        }
    }

    Column {
        id: content
        anchors.centerIn: parent
        spacing: 0

        RollingDigits {
            anchors.horizontalCenter: parent.horizontalCenter
            value: Qt.formatTime(root.now, "HH")
        }

        RollingDigits {
            anchors.horizontalCenter: parent.horizontalCenter
            value: Qt.formatTime(root.now, "mm")
        }

        // The date is its own line, clearly parted from the digits, at the
        // largest size that still fits the band — HorizontalFit is the
        // preferred/maximum law applied to type: ask for 12, accept down to 9
        // rather than eliding or overflowing.
        QsmShellComponents.Prose {
            // A date reading, not a rule or a caption — same family as the
            // hour/minute pair above it, at its own token size.
            role: "reading"
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: Theme.space1
            width: Theme.railWidth - Theme.space1
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDate(root.now, "dd MMM")
            font.pixelSize: Theme.railClockDateSize
            font.weight: Theme.weightMedium
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: Theme.textXs
            // Prose elides every non-wrapping role by default; this line's
            // whole design is HorizontalFit down to minimumPixelSize instead
            // of an ellipsis (03: "rather than eliding or overflowing").
            elide: Text.ElideNone
        }
    }
}
