import QtQuick

// The one owner of the bar popout's WHAT: which popout is up, what it says,
// and where it anchors. The popout's HOME is FIXED (owner law: a predefined
// bottom-left corner rollout that only expands — it never follows the
// cursor), so showing is just content + kind; RailPopout fades fresh content
// in on kind changes.
//
// The WHEN — whether the popout stays open — is NOT this object's job
// (03-rail "Popouts": a rollout is held open by WHERE
// THE POINTER IS, decided by one geometric region test against the live
// rects). That test needs both hosts and the scene's own hover point, so it
// lives on EdgeScene, which owns both controllers already. This object only
// records the open request and answers it.
QtObject {
    id: root

    property string kind
    property string title
    property string detail
    property var data: null
    // The hovered entry's vertical center in WINDOW coordinates — the
    // popout card centers on it (clamped to the frame).
    property real currentCenter
    // The cell that opened this popout. Kind is the COMPONENT's identity, and
    // a component may appear many times over — every app row is an `app`, every
    // tray icon a `tray` — so the anchor is what makes this one particular
    // cell; comparing kinds alone made all of them believe they were the
    // selected one.
    property Item anchor: null
    readonly property bool active: kind.length > 0

    function show(newKind: string, item: Item, newTitle: string, newDetail: string,
        newData: var): void {
        anchor = item;
        currentCenter = item.mapToItem(null, 0, item.height / 2).y;
        title = newTitle;
        detail = newDetail;
        data = newData;
        kind = newKind; // last: flips `active`
    }

    function dismiss(): void {
        kind = "";
    }
}
