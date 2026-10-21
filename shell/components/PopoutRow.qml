import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.theme

// One row in a rail popout list: the library's row, plus the trailing
// composition every one of these lists uses.
//
// THE ROW IS THE CONTROL. Clicking it does the row's obvious thing — connect,
// select, join — and the current one is marked with the accent tick, not with
// a button whose label states what it already is. A button per row would make
// nothing primary, stack filled boxes in a surface the design keeps boxless,
// and leave the device name too little width to read.
//
// It does NOT recede its neighbours. A launcher list dims everything that is
// not current because you want one thing from it; this is a list you READ, and
// dimming nine network names to mark the tenth costs you the other nine.
QsmShellComponents.ListRow {
    id: root

    property string label: ""
    // Right-aligned reading — "connected", "72%", a signal strength. This is
    // DATA, and it is styled as data: caption size, muted, never a pill.
    property string value: ""
    property bool active: false
    // A small qualifier glyph before the reading — wifi's padlock. Info, not a
    // control.
    property string badgeIcon: ""
    // A rare extra the row itself cannot express (forget this device, bring
    // this connection down). Tertiary by law: present, but at low contrast
    // until the row is under the pointer — never competing with the row's own
    // action, and never hidden outright either.
    property string actionIcon: ""
    property bool actionDanger: false

    signal clicked
    signal actionTriggered

    // The compact row: a device list is a scan target, and a roomier pitch
    // fills the popout with air.
    size: "sm"
    recede: false
    primary: root.label
    selected: root.active
    // Tab reaches the row; a click on a plain Item does not take focus, so the
    // ring shows for the keyboard only.
    activeFocusOnTab: root.selectable
    focused: root.activeFocus
    onActivated: root.clicked()
    Keys.onReturnPressed: root.activate()
    Keys.onEnterPressed: root.activate()
    Keys.onSpacePressed: root.activate()

    QsmShellComponents.SvgIcon {
        visible: root.badgeIcon.length > 0
        name: root.badgeIcon
        size: QsmShellStyle.Style.iconXs
        color: QsmShellStyle.Style.textMuted
    }

    QsmShellComponents.Prose {
        visible: root.value.length > 0
        // Mono only when the reading is a NUMBER. Spec 11 reserves the mono
        // face for technical values: "72%" is one, "connected" is a word, and
        // deciding that per call site is how the two drifted apart.
        role: /\d/.test(root.value) ? "reading" : "metadata"
        font.pixelSize: QsmShellStyle.Style.textXs
        muted: true
        text: root.value
    }

    QsmShellComponents.IconButton {
        visible: root.actionIcon.length > 0
        icon: root.actionIcon
        size: "xs"
        // Destructive is not the same as red-at-rest. A non-primary
        // destructive action gets tertiary treatment and only takes the danger
        // colour once the pointer is on its row — three red bins down the side
        // of a device list shout louder than anything the list is for.
        color: !root.hovered ? QsmShellStyle.Style.disabled(Theme.textMuted)
            : root.actionDanger ? Theme.danger : Theme.textMuted
        onClicked: root.actionTriggered()

        Behavior on color {
            ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }
    }
}
