import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.theme

// One rail cell. StateLayer is the only interaction source — the entry's own
// rectangle paints just the PERSISTENT state (active, selected, danger);
// hover and press belong to the layer, so every entry answers identically.
//
// Popouts are declarative: set popoutKind (+ title/detail/data) and hand the
// entry the bar's PopoutController; hovering then shows and releases the
// popout without any per-entry handler code.
Item {
    id: root

    default property alias content: contentSlot.data
    property string icon
    property color iconColor: Theme.text
    property bool active
    // Compact rows are reserved for controls within a rail group. Their 16px
    // glyphs stay legible while the group reads as a unit rather than five
    // isolated 40px buttons.
    property bool compact
    // Destructive-flavored entry (power): slight danger-tinted base.
    property bool danger
    property bool interactive
    property bool clickable: true
    // The narrow rail uses the compact 16px glyph step. The Arch logo is the
    // one deliberate 20px exception at the top of the band.
    property int iconSize: Theme.iconSm
    property var popouts: null
    property string popoutKind
    property string popoutTitle
    property string popoutDetail
    property var popoutData: null
    readonly property bool hovered: layer.hovered

    // The controller SNAPSHOTS title and detail when show() runs, so a cell
    // whose description changes WHILE its popout is open — a destructive action
    // arming, a result arriving, a toggle flipping — has to push the new text
    // or the card keeps displaying what was true at hover time.
    //
    // Guarded on `selected`: a kind is a component identity that many cells
    // share, and without this every cell of that kind in the rail would
    // overwrite the open card's text whenever its own description changed.
    onPopoutDetailChanged: {
        if (selected)
            popouts.detail = popoutDetail;
    }
    onPopoutTitleChanged: {
        if (selected)
            popouts.title = popoutTitle;
    }
    // This entry owns the open rail rollout: its selected pill stretches to
    // the rail's inner wall so it visually plugs into the column.
    readonly property bool selected: popouts !== null && popoutKind.length > 0
        && popouts.kind === popoutKind && popouts.anchor === root
    signal clicked
    // What this cell did, in the words the cell owns: hover-entered,
    // hover-left, clicked. The controller answers OPENING and nothing here
    // answered the pointer, so an observer of this rail could only ever see a
    // rollout move.
    signal interaction(string action)

    implicitWidth: Theme.railWidth
    implicitHeight: compact ? Theme.space6 : Theme.railWidth

    // A cell the pointer can act on is a keyboard stop too, and a screen
    // reader names it by what its popout names.
    activeFocusOnTab: interactive
    Accessible.role: Accessible.Button
    Accessible.name: popoutTitle
    Accessible.description: popoutDetail
    Accessible.onPressAction: root.activateByKey()

    // Return and Space do what the pointer's click does; a cell that only
    // reports hover (clickable false) opens its popout instead.
    function activateByKey(): void {
        if (layer.activate())
            return;
        if (root.popouts && root.popoutKind.length > 0)
            root.popouts.show(root.popoutKind, root, root.popoutTitle,
                root.popoutDetail, root.popoutData);
    }
    Keys.onReturnPressed: root.activateByKey()
    Keys.onEnterPressed: root.activateByKey()
    Keys.onSpacePressed: root.activateByKey()

    // Selected, active and danger are one state read three ways: the accent
    // (danger: the danger role) at opacitySelected over a transparent base,
    // which is Surface's own answer to "selected".
    QsmShellComponents.Surface {
        anchors.fill: parent
        // Selected: reach the band's inner wall — connected to the column.
        anchors.rightMargin: root.selected ? -(Theme.reservedLeft - Theme.railWidth) / 2 : 0
        radius: Theme.radiusMd
        // Plugged into the wall it reaches: square on that side, so the pill
        // joins the column instead of ending in two rounded notches.
        snapEdge: root.selected ? "right" : ""
        base: "transparent"
        accent: root.danger && !root.selected ? Theme.danger : Theme.accent
        selected: root.selected || root.danger || root.active
        hovered: layer.hovered
        pressed: layer.pressed

        Behavior on anchors.rightMargin {
            NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }
    }

    QsmShellComponents.SvgIcon {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        // An empty name means the cell paints its own content in the slot
        // below; loading "".svg would just log a miss.
        visible: root.icon.length > 0
        name: root.icon
        size: root.iconSize
        color: root.iconColor
    }

    // Custom cell content (the BLE cell's split glyph grid, and anything like
    // it later) belongs HERE — between the icon and the StateLayer, the same
    // place this entry's own icon sits. A child declared on the subclass lands
    // ABOVE the layer instead, which puts it outside the cell's own stacking
    // and lets it eat the pointer. One slot keeps every cell behaving and
    // looking identical no matter what it draws.
    Item {
        id: contentSlot
        anchors.fill: parent
    }

    QsmShellComponents.StateLayer {
        id: layer
        anchors.fill: parent
        // Fitts reach (audit X1): the hit area extends across the band's
        // outer 10px gutter to the TRUE screen edge — an edge-slammed cursor
        // lands on the entry, never on dead band. Visuals stay in the cell;
        // the tint is band-colored so the overhang never reads.
        anchors.leftMargin: -(Theme.reservedLeft - Theme.railWidth) / 2
        // The cell's Surface recolours on hover and press, so the layer only
        // grows it, and a press never resizes a body.
        hoverScale: QsmShellStyle.Motion.hoverScale
        focused: root.activeFocus
        focusRadius: Theme.radiusMd
        interactive: root.interactive
        clickable: root.clickable
        manualHoverOverride: root.selected
        onClicked: {
            root.interaction("clicked");
            root.clicked();
        }
        // Only genuine pointer entry opens; held visual hover is not input.
        // Rollout.keepOpen reports whether the surface should remain open.
        onHoveredEntered: {
            if (root.popouts && root.popoutKind.length > 0) {
                root.popouts.show(root.popoutKind, root, root.popoutTitle,
                    root.popoutDetail, root.popoutData);
            }
        }
    }

    // One arrival and one departure per gesture. `pointerHovered` rather than
    // `hovered`, so a cell that is merely HELD open by its own selection does
    // not report a pointer that never came.
    Connections {
        target: layer

        function onPointerHoveredChanged(): void {
            root.interaction(layer.pointerHovered ? "hover-entered" : "hover-left");
        }
    }
}
