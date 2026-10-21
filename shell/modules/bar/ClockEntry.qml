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

        // The glyph bounds can be narrower than the text's layout advance.
        implicitWidth: Math.ceil(Math.max(metrics.advanceWidth, metrics.width))
        implicitHeight: Math.ceil(metrics.height)
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
            anchors.horizontalCenter: parent.horizontalCenter
            y: -digits.progress * height
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
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
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - digits.progress * height
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
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
        spacing: 0

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            RollingDigits { value: Qt.formatTime(root.now, "HH") }
            RollingDigits { value: Qt.formatTime(root.now, "mm") }
        }
        QsmShellComponents.Prose {
            anchors.horizontalCenter: parent.horizontalCenter
            role: "reading"
            technical: true
            width: Theme.railCapsule - QsmShellStyle.Style.space1
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDate(root.now, "dd.MM")
            font.pixelSize: Theme.railClockDateSize
            font.weight: QsmShellStyle.Style.weightMedium
            elide: Text.ElideNone
        }
    }
}
