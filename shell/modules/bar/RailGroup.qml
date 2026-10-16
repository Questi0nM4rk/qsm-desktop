import QtQuick
import qs.theme

// A rail group with a PREFERRED and a MAXIMUM size (owner 2026-08-18).
//
// Every group asks for the size its contents want (`preferredHeight`) and is
// never given more than `maximumHeight`. When the rail cannot afford even the
// preferred size, the group does NOT clip and does not re-flow: it scales its
// whole content down as one block, so the arrangement a reader learned stays
// the same arrangement, just smaller. Scaling from the top-centre keeps the
// group anchored where the column expects it.
//
// No background: groups are separated by spacing.
Item {
    id: root

    default property alias content: inner.data

    // What the contents want, and the ceiling the rail will honour.
    property real preferredHeight: inner.childrenRect.height
    property real maximumHeight: preferredHeight
    // Never scale below this or the glyphs stop being readable; past it the
    // caller should be dropping items instead.
    property real minimumScale: 0.7

    readonly property real fittedScale: preferredHeight > 0
        ? Math.max(minimumScale, Math.min(1, height / preferredHeight))
        : 1

    implicitWidth: Theme.railWidth
    implicitHeight: Math.min(maximumHeight, preferredHeight)

    Item {
        id: inner

        width: parent.width
        height: root.preferredHeight
        transformOrigin: Item.Top
        scale: root.fittedScale
    }
}
