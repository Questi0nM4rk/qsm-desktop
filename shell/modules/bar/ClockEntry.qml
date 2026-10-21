import QtQuick
import Quickshell
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.theme

// The larger time sits above one smaller numeric date, all in the technical face.
Item {
    id: root

    property var popouts: null
    readonly property date now: clock.date

    width: Theme.railWidth
    implicitHeight: content.implicitHeight + QsmShellStyle.Style.space2 * 2

    function openCalendar(): void {
        root.popouts?.show("calendar", root, Qt.formatDate(root.now, "MMMM yyyy"), "", null);
    }

    // Hover, click and keys open the same calendar.
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: "Calendar"
    Accessible.onPressAction: root.openCalendar()
    Keys.onReturnPressed: root.openCalendar()
    Keys.onEnterPressed: root.openCalendar()
    Keys.onSpacePressed: root.openCalendar()

    // Hover-enter opens the calendar; whether it STAYS open is EdgeScene's
    // geometric region test, not a leave-time close call here (03-rail
    // "Popouts", RATIFIED 2026-09-07).
    HoverHandler {
        onHoveredChanged: {
            if (hovered)
                root.openCalendar();
        }
    }

    // Click and the keyboard ring only: the reading does not grow or recolour.
    QsmShellComponents.StateLayer {
        anchors.fill: parent
        target: null
        focused: root.activeFocus
        focusRadius: QsmShellStyle.Style.radiusMd
        onClicked: root.openCalendar()
    }

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
        id: content
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
            topPadding: QsmShellStyle.Style.space1
            width: Theme.railWidth - QsmShellStyle.Style.space1
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDate(root.now, "dd.MM")
            font.pixelSize: Theme.railClockDateSize
            font.weight: QsmShellStyle.Style.weightMedium
            elide: Text.ElideNone
        }
    }
}
