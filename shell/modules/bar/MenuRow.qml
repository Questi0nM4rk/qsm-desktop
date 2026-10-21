import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.QsmShell.Components as QsmShellComponents
import qs.theme

// One DBusMenu row (03 DEFAULT tray-menu rendering). Submenus expand
// inline, indented, on click. The rows are the library's, so a library `Menu`
// above this finds them (also those of an open submenu) and steps through
// them by keyboard; `structureChanged` tells it when the set grew or shrank.
ColumnLayout {
    id: root

    required property var entry
    property int depth: 0
    property bool expanded: false
    readonly property bool hasSubmenu: entry.hasChildren ?? false

    // The row set below this one changed: a submenu opened, closed or loaded.
    signal structureChanged
    onExpandedChanged: root.structureChanged()

    Layout.fillWidth: true
    spacing: Theme.spaceTight

    // Separator: a SHORT faded line (03).
    QsmShellComponents.Divider {
        visible: root.entry.isSeparator
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Theme.menuSeparatorWidth
        strength: Theme.menuSeparatorStrength
    }

    // The row, its dimming when disabled and its press are the library's;
    // its focus ring is bound below. A row with a submenu toggles it instead of firing.
    QsmShellComponents.ListRow {
        id: row
        visible: !root.entry.isSeparator
        // A separator keeps its row so the menu's document order is the
        // entry's, but it is not a target.
        interactive: !root.entry.isSeparator
        Layout.fillWidth: true
        Layout.leftMargin: root.depth * Theme.space3
        size: "sm"
        recede: false
        // The library's focused default is false; Menu grants real focus to
        // the row, so the keyboard ring follows it.
        focused: row.activeFocus
        primary: root.entry.text || "…"
        disabled: root.entry.enabled === false
        // Checkable state via icon swap, never a glow.
        icon: (root.entry.buttonType ?? 0) === 0 ? ""
            : root.entry.checkState === 2 ? "pin" : "pin-off"
        onActivated: {
            if (root.hasSubmenu)
                root.expanded = !root.expanded;
            else
                root.entry.triggered();
        }

        QsmShellComponents.SvgIcon {
            visible: root.hasSubmenu
            name: root.expanded ? "chevron-down" : "chevron-right"
            size: Theme.iconXs
            color: Theme.textMuted
        }
    }

    // Inline submenu. QML forbids direct recursive instantiation, so child
    // rows load through a Loader with runtime-resolved source.
    QsMenuOpener {
        id: subOpener
        menu: root.expanded && root.hasSubmenu ? root.entry : null
    }

    Repeater {
        model: root.expanded ? subOpener.children : null

        Loader {
            required property var modelData
            Layout.fillWidth: true
            Component.onCompleted: setSource("MenuRow.qml",
                { entry: modelData, depth: root.depth + 1 })
            onLoaded: root.structureChanged()

            Connections {
                target: parent.item
                function onStructureChanged(): void { root.structureChanged(); }
            }
        }
    }
}
