import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.theme

// The space between two rail groups: one 8 high step, which with the column's
// 4 on each side makes the 16 that tells a group boundary from an item gap.
// Space groups by itself; `line` adds the library's rule, centred in the step
// and inset from both walls, only where the groups either side are alike
// (a list's ends, glyph beside glyph) and space alone would not say where one
// ends.
Item {
    id: root

    property bool line: false

    implicitWidth: Theme.railWidth
    implicitHeight: QsmShellStyle.Style.space2

    QsmShellComponents.Divider {
        anchors.fill: parent
        visible: root.line
        inset: Theme.railDividerInset
    }
}
