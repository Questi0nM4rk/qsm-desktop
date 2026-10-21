import QtQuick
import Quickshell
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.theme

// The larger time sits above one smaller numeric date, all in the technical
// face, inside the rail's one capsule: hover, click and keys open the calendar
// like every other cell's rollout, with its pill, its growth and its hit area.
RailEntry {
    id: root

    readonly property date now: clock.date

    // Tall enough for its three lines at their reading sizes.
    implicitHeight: stack.implicitHeight + QsmShellStyle.Style.space2 * 2

    interactive: true
    // Hover and the keys open the calendar; a click would only repeat it.
    clickable: false
    popoutKind: "calendar"
    popoutTitle: Qt.formatDate(root.now, "MMMM yyyy")
    Accessible.name: "Calendar"

    // One shared system clock at minute precision — the display shows no
    // seconds, so a per-instance 1s timer was 60x the wakeups for nothing.
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
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
            font: currentReading.font
            text: "00"
        }

        // The rail's width and the next step of the 4 rhythm above the line,
        // so every box of the clock sits on whole device pixels.
        implicitWidth: Theme.railWidth
        implicitHeight: Math.ceil(metrics.height / QsmShellStyle.Style.space1) * QsmShellStyle.Style.space1
        clip: true

        onValueChanged: {
            if (!ready || Theme.reducedMotion) {
                current = value;
                previous = value;
                progress = 1;
                return;
            }
            previous = current;
            current = value;
            progress = 0;
            Qt.callLater(() => progress = 1);
        }
        Component.onCompleted: ready = true

        Behavior on progress {
            enabled: !Theme.reducedMotion
            NumberAnimation { duration: QsmShellStyle.Motion.fast; easing.type: QsmShellStyle.Motion.emphasizedEasing }
        }

        QsmShellComponents.Prose {
            role: "hero"
            technical: true
            y: -digits.progress * height
            width: parent.width
            height: parent.height
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: digits.previous
            opacity: 1 - digits.progress
            font.pixelSize: Theme.railClockDigitSize
            font.weight: QsmShellStyle.Style.weightBold
            elide: Text.ElideNone
        }

        QsmShellComponents.Prose {
            id: currentReading
            role: "hero"
            technical: true
            y: parent.height - digits.progress * height
            width: parent.width
            height: parent.height
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: digits.current
            opacity: digits.progress
            font.pixelSize: Theme.railClockDigitSize
            font.weight: QsmShellStyle.Style.weightBold
            elide: Text.ElideNone
        }
    }

    Column {
        id: stack
        anchors.centerIn: parent
        width: parent.width
        spacing: 0

        RollingDigits { value: Qt.formatTime(root.now, "HH") }
        RollingDigits { value: Qt.formatTime(root.now, "mm") }
        QsmShellComponents.Prose {
            role: "reading"
            technical: true
            topPadding: QsmShellStyle.Style.space1
            width: parent.width
            height: Math.ceil(implicitHeight / QsmShellStyle.Style.space1) * QsmShellStyle.Style.space1
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: Qt.formatDate(root.now, "dd.MM")
            font.pixelSize: Theme.railClockDateSize
            font.weight: QsmShellStyle.Style.weightMedium
            elide: Text.ElideNone
        }
    }
}
