import QtQuick
import qs.QsmShell.Style as QsmShellStyle
import qs.theme

// The space between two rail groups: one 8 high step, which with the column's
// 4 on each side makes the 16 that tells a group boundary from an item gap.
// Space groups by itself; `line` adds a short rule, centred on the rail's axis
// and in the step, only where the groups either side are alike (a list's ends,
// glyph beside glyph) and space alone would not say where one ends. Half the
// capsule long and two device pixels thick, so it reads as a mark and not as
// an edge.
Item {
    id: root

    property bool line: false

    implicitWidth: Theme.railWidth
    implicitHeight: QsmShellStyle.Style.space2

    Rectangle {
        readonly property real thickness: 2 * QsmShellStyle.Style.stroke(QsmShellStyle.Style.hairline, root)

        visible: root.line
        width: Theme.railSeparatorWidth
        height: thickness
        x: QsmShellStyle.Style.snap((parent.width - width) / 2, root)
        y: QsmShellStyle.Style.snap((parent.height - height) / 2, root)
        antialiasing: false
        color: Qt.alpha(QsmShellStyle.Style.textMuted, QsmShellStyle.Style.dividerOpacity)
    }
}
