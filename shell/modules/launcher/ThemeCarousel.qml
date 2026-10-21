pragma ComponentBehavior: Bound
import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.theme

// >theme carousel (07 N-theme picker, caelestia WallpaperList idea
// simplified to a keyboard-driven horizontal ListView instead of a PathView
// arc). One card per Theme.themes entry (via LauncherSurface.results) — a
// new theme JSON adds a card with zero code. Centering + keyboard nav are
// index-driven from the host (LauncherSurface owns arrow-key handling on
// the search field); this component only renders and reports clicks.
Item {
    id: root

    // Result-shaped entries: { kind: "theme", label, sub, thumb, data }.
    required property var items
    property int currentIndex: 0
    signal activated(int index)
    // One cursor: a hovered card asks the host to select it; the host
    // owns the index (it also drives it from the search field's arrows).
    signal hoverSelect(int index)

    QsmShellComponents.EmptyState {
        anchors.centerIn: parent
        visible: root.items.length === 0
        icon: "search"
        title: "No matching themes"
        detail: "Try another name"
    }

    ListView {
        id: view

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.launcherThemeCardHeight
        orientation: ListView.Horizontal
        clip: true
        interactive: false // index is keyboard-driven from the host, not dragged
        model: root.items
        currentIndex: root.currentIndex
        spacing: QsmShellStyle.Style.space4
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: width / 2 - Theme.launcherThemeCardWidth / 2
        preferredHighlightEnd: width / 2 + Theme.launcherThemeCardWidth / 2
        highlightMoveDuration: Motion.morphGlide

        delegate: ThemeCard {
            required property var modelData
            required property int index
            item: modelData
            centered: index === view.currentIndex
            onActivated: root.activated(index)
            onHoveredEntered: root.hoverSelect(index)
        }
    }
}
