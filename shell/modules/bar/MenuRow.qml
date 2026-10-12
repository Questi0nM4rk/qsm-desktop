import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.QsmShell.Components as QsmShellComponents
import qs.theme

// One DBusMenu row (03 DEFAULT tray-menu rendering). Submenus expand
// inline, indented, on click.
ColumnLayout {
    id: root

    required property var entry
    property int depth: 0
    property bool expanded: false
    readonly property bool hasSubmenu: entry.hasChildren ?? false

    Layout.fillWidth: true
    spacing: Theme.spaceTight

    // Separator: a SHORT faded line.
    QsmShellComponents.Divider {
        visible: root.entry.isSeparator
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 96
        strength: 0.25
    }

    Item {
        visible: !root.entry.isSeparator
        Layout.fillWidth: true
        Layout.preferredHeight: Theme.controlHeightSm
        opacity: root.entry.enabled === false ? 0.4 : 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.depth * Theme.space3
            spacing: Theme.space2

            // Checkable state via icon swap, never a glow.
            QsmShellComponents.SvgIcon {
                visible: (root.entry.buttonType ?? 0) !== 0
                name: root.entry.checkState === 2 ? "pin" : "pin-off"
                size: Theme.iconXs
                color: Theme.textMuted
            }

            QsmShellComponents.Prose {
                // The row's own name — label, the default role for a
                // control's name.
                role: "label"
                Layout.fillWidth: true
                text: root.entry.text || "…"
            }

            QsmShellComponents.SvgIcon {
                visible: root.hasSubmenu
                name: "chevron-left"
                size: Theme.iconXs // on the icon ladder (was an off-scale 10)
                color: Theme.textMuted
                rotation: root.expanded ? 90 : 180
            }
        }

        QsmShellComponents.StateLayer {
            anchors.fill: parent
            // A menu row grows gently — it sits in a column of identical rows,
            // where a large step reads as the list jumping.
            hoverScale: 1.02
            pressScale: 0.98
            onClicked: {
                if (root.hasSubmenu)
                    root.expanded = !root.expanded;
                else if (root.entry.enabled !== false)
                    root.entry.triggered();
            }
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
        }
    }
}
