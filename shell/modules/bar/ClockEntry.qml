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

    // The two digit pairs swap in place: the clock changes every minute, a
    // thousand times a day, and a roll on each is motion nobody asked for. A
    // box is the rail's width and the next step of the 4 rhythm above the
    // line, so every box of the clock sits on whole device pixels.
    component Digits: QsmShellComponents.Prose {
        role: "hero"
        technical: true
        width: Theme.railWidth
        height: Math.ceil(implicitHeight / QsmShellStyle.Style.space1) * QsmShellStyle.Style.space1
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: Theme.railClockDigitSize
        font.weight: QsmShellStyle.Style.weightBold
        elide: Text.ElideNone
    }

    Column {
        id: stack
        anchors.centerIn: parent
        width: parent.width
        spacing: 0

        Digits { text: Qt.formatTime(root.now, "HH") }
        Digits { text: Qt.formatTime(root.now, "mm") }
        QsmShellComponents.Prose {
            role: "reading"
            technical: true
            topPadding: QsmShellStyle.Style.space1
            width: parent.width
            // The cell is a multiple of 8 high, so its centre is a multiple of
            // 4 and the calendar centred on it lands on whole device pixels.
            height: QsmShellStyle.Style.space5
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: Qt.formatDate(root.now, "dd.MM")
            font.pixelSize: Theme.railClockDateSize
            font.weight: QsmShellStyle.Style.weightMedium
            elide: Text.ElideNone
        }
    }
}
