import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle

// A tray item's DBusMenu tree as popout rows (03 DEFAULT): separators as
// faded short lines, submenus expand INLINE (indented) on click, checkable
// items use the icon-swap law, disabled items dim by colour. The rows live in
// the library's `Menu`, which owns the selection thumb and steps through them
// with the arrow keys, submenu rows included.
ColumnLayout {
    id: root

    // The SystemTrayItem (popout controller data).
    property var trayItem: null

    // The item has a menu but its entries have not arrived yet: the fetch is
    // asynchronous, and "No menu" is only true when there is none to wait for.
    readonly property bool _loading: root.trayItem?.menu != null && (opener.children?.values?.length ?? 0) === 0

    spacing: QsmShellStyle.Style.spaceTight

    QsMenuOpener {
        id: opener
        menu: root.trayItem?.menu ?? null
    }

    QsmShellComponents.Menu {
        id: menu
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight
        spacing: QsmShellStyle.Style.spaceTight
        visible: !root._loading && (opener.children?.values?.length ?? 0) > 0
        model: opener.children
        delegate: MenuRow {
            required property var modelData
            entry: modelData
            onStructureChanged: Qt.callLater(menu.resync)
        }
    }

    RowLayout {
        visible: root._loading
        spacing: QsmShellStyle.Style.space2

        QsmShellComponents.Spinner { size: QsmShellStyle.Style.iconSm }
        QsmShellComponents.Prose {
            role: "metadata"
            text: "Loading…"
        }
    }

    QsmShellComponents.Prose {
        role: "metadata"
        visible: !root._loading && (opener.children?.values?.length ?? 0) === 0
        text: "No menu"
    }
}
