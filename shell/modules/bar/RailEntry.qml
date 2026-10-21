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
    // Destructive-flavored entry (power): slight danger-tinted base.
    property bool danger
    property bool interactive
    property bool clickable: true
    // A rail cell carries no label, so its glyph takes the small icon step.
    // The Arch logo is the one deliberate larger glyph, at the top of the band.
    property int iconSize: QsmShellStyle.Style.iconSm
    // How far a selected pill reaches to the right: to the wall of the rollout
    // it joins, which is the band's own wall for the left rail.
    property real reach: Theme.railReach
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
    implicitHeight: Theme.railCellHeight

    // A cell the pointer can act on is a keyboard stop too, and a screen
    // reader names it by what its popout names.
    activeFocusOnTab: interactive
    Accessible.role: interactive ? Accessible.Button : Accessible.Graphic
    Accessible.name: interactive ? popoutTitle : ""
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
        // Hover grows the body by whole device pixels on every side and leaves
        // the glyph alone. Selected: the right side reaches the band's inner
        // wall instead, exactly, so the pill joins the rollout's own edge and
        // never overshoots it.
        anchors.margins: -layer.growth
        anchors.rightMargin: root.selected ? -root.reach : -layer.growth
        radius: QsmShellStyle.Style.radiusMd
        // Plugged into the wall it reaches: square on that side, so the pill
        // joins the column instead of ending in two rounded notches.
        snapEdge: root.selected ? "right" : ""
        base: "transparent"
        accent: root.danger && !root.selected ? Theme.danger : Theme.accent
        selected: root.selected || root.danger || root.active
        hovered: layer.hovered
        pressed: layer.pressed

        Behavior on anchors.rightMargin {
            NumberAnimation { duration: QsmShellStyle.Motion.micro; easing.type: QsmShellStyle.Motion.standardEasing }
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
        // Fitts reach: the hit area extends across the band's
        // outer gutter to the TRUE screen edge — an edge-slammed cursor
        // lands on the entry, never on dead band. Visuals stay in the cell;
        // the tint is band-colored so the overhang never reads.
        anchors.leftMargin: -Theme.railGutter
        // The cell's Surface recolours on hover and press and grows by
        // `growth`, applied above, so a press never resizes a body. Growth is
        // capped by the rail's gap, because the open cell stays grown while the
        // next one is entered, so two neighbours can be grown at once.
        growthCap: QsmShellStyle.Motion.hoverGrowthWithin(Theme.railItemGap)
        focused: root.activeFocus
        focusRadius: QsmShellStyle.Style.radiusMd
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
