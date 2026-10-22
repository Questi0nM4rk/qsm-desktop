import QtQuick
import qs.services
import qs.theme

// The quick-actions column (03): a SECOND rail, rolled out
// beside the first. Glyph cells stacked under each other, no labels — and
// anything that needs to say more expands once further right, exactly as the
// left band does.
//
// Everything here is a quality-of-life action two gestures
// away and nowhere else: stateful toggles, one irreversible sweep,
// one screen tool. Anything needing real UI belongs in its own popout or in a
// delegated app instead.
Item {
    id: root

    // The LEVEL-2 controller, not the rail's own. These cells roll their
    // detail out to the right of this column, so they must drive the host
    // that lives there — handed down rather than looked up so this component
    // stays a pure view over whatever host the scene gave it.
    required property var controller

    // What its cells did, named by the cell's own kind and carrying the cell's
    // own title. The column is the one place that knows which cell is which.
    signal interacted(string kind, string action, string title)

    // As tall as the colour menu that hangs off it needs, so the seam between
    // the two is one straight line, and its cells are centred in what that
    // leaves. The room above the first cell and below the last also keeps a
    // detail card's square edge off this column's own rounded corners.
    implicitWidth: Theme.railWidth
    implicitHeight: Math.max(cells.implicitHeight, Theme.colorMenuMinHeight)

    // The actual cells, by role. A host reaches the real control through
    // `control()`; it never re-derives one from a cell's position.
    readonly property var namedControls: ({
        "main-keyboard": keyboardCell,
        "awake": awakeCell,
        "night-light": nightLightCell,
        "colours": coloursCell,
        "clearcache": cacheCell
    })
    function control(name: string): var {
        return root.namedControls[name] ?? null;
    }

    Column {
        id: cells

        anchors.centerIn: parent
        width: parent.width
        spacing: Theme.railItemGap

        QuickActionCell {
            id: keyboardCell
            width: parent.width
            popouts: root.controller
            icon: MainKeyboardService.glyph
            iconColor: !MainKeyboardService.available ? Theme.textMuted
                : MainKeyboardService.disabled ? Theme.warning : Theme.text
            clickable: MainKeyboardService.available && !MainKeyboardService.busy
            popoutKind: "main-keyboard"
            popoutTitle: MainKeyboardService.actionLabel
            detail: MainKeyboardService.description
            Accessible.role: Accessible.Button
            Accessible.name: MainKeyboardService.actionLabel
            Accessible.description: MainKeyboardService.description
            onFired: MainKeyboardService.toggle()
            onEntered: MainKeyboardService.refresh()
            onInteraction: action => root.interacted("main-keyboard", action,
                keyboardCell.popoutTitle)
        }

        QuickActionCell {
            id: awakeCell
            width: parent.width
            popouts: root.controller
            // Icon-swap for state, never a glow (03): a full cup is inhibiting.
            icon: AwakeService.awake ? "coffee-full" : "coffee-empty"
            popoutKind: "keepawake"
            popoutTitle: "Keep awake"
            detail: AwakeService.awake
                ? "Inhibiting idle and sleep · click to allow sleep"
                : "Normal power management · click to inhibit idle"
            onFired: AwakeService.toggle()
            // Freshen before the card states it: both services poll coarsely
            // for outside changes, so hovering is the moment to be accurate.
            onEntered: AwakeService.refresh()
            onInteraction: action => root.interacted("keepawake", action,
                awakeCell.popoutTitle)
        }

        QuickActionCell {
            id: nightLightCell
            width: parent.width
            popouts: root.controller
            icon: NightLightService.active ? "moon" : "brightness"
            popoutTitle: "Night light"
            // Its own tier, because this one has a CONTROL and not just a
            // sentence: the warmth slider lives in the level-2 card, which is
            // the rail's own "expand one step further right" vocabulary and
            // therefore the single home for it (09 one-path).
            popoutKind: "nightlight"
            detail: NightLightService.active
                ? "Click for normal colour"
                : "Click to warm the screen"
            onFired: NightLightService.toggle()
            onEntered: NightLightService.refresh()
            onInteraction: action => root.interacted("nightlight", action,
                nightLightCell.popoutTitle)
        }

        QuickActionCell {
            id: cacheCell
            width: parent.width
            popouts: root.controller
            icon: "brush-cleaning"
            destructive: true
            popoutKind: "clearcache"
            popoutTitle: "Clean caches"
            // The result becomes the detail once it exists: the surface that
            // asked for confirmation is the one that reports what it did.
            detail: CacheService.busy
                ? "Working…"
                : CacheService.lastResult.length > 0
                    ? `${CacheService.lastResult} · click to sweep again`
                    : "Drop stale cache files and regenerable shader data"
            onFired: CacheService.clean()
            onInteraction: action => root.interacted("clearcache", action,
                cacheCell.popoutTitle)
        }

        QuickActionCell {
            id: coloursCell
            width: parent.width
            popouts: root.controller
            icon: "sparkle"
            popoutTitle: "Colours"
            // Its own tier, and a MENU rather than a card:
            // the current colour with its hex and a copy, a scrollable history
            // of picks, and an accent set generated from whichever one is
            // selected.
            popoutKind: "colorpick"
            detail: ""
            // HOVER ONLY. The pick starts from the swatch inside the menu, so a
            // click here would be a second door to it — the same reason the
            // `zap` cell above has nothing for a click to do (03).
            clickable: false
            onInteraction: action => root.interacted("colorpick", action,
                coloursCell.popoutTitle)
        }
    }
}
