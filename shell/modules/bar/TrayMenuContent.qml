import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.QsmShell.Components as QsmShellComponents
import qs.theme

// A tray item's DBusMenu tree as popout rows (03 DEFAULT): separators as
// faded short lines, submenus expand INLINE (indented) on click, checkable
// items use the icon-swap law, disabled items dim to 40%.
ColumnLayout {
    id: root

    // The SystemTrayItem (popout controller data).
    property var trayItem: null

    spacing: Theme.spaceTight

    QsMenuOpener {
        id: opener
        menu: root.trayItem?.menu ?? null
    }

    Repeater {
        model: opener.children

        MenuRow { required property var modelData; entry: modelData }
    }

    QsmShellComponents.Prose {
        role: "metadata"
        visible: (opener.children?.values?.length ?? 0) === 0
        text: "No menu"
    }
}
