import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.theme

// One cell in the quick-actions column. A RailEntry by construction, not by
// resemblance — the column is a second rail, so its cells must BE rail cells:
// same box, same growth response, same selected pill plugging into the
// column it belongs to.
//
// There is no label. What the glyph means lives in the level-2 rollout to the
// right (a description tier, which exists for exactly this: "an icon-only
// rail names nothing and promises nothing"). Every cell here declares its own
// kind, because a kind is the component's identity and a generic one would
// make two cells indistinguishable. That makes the rollout load-bearing rather
// than decorative, and it is why destructive actions confirm THERE — arming an
// unlabelled glyph with no words anywhere would be a trap.
RailEntry {
    id: root

    property bool destructive: false
    // What the level-2 rollout says at rest. Arming replaces it, so the same
    // surface that names the action is the one that asks for confirmation.
    property string detail
    signal fired
    // Pointer arrived. A separate signal because an instance declaring
    // `onHoveredChanged` would REPLACE this component's own handler below and
    // silently take the disarm-on-leave with it.
    signal entered

    readonly property bool armed: confirm.armed

    interactive: true
    iconSize: QsmShellStyle.Style.iconSm
    // The column sits inside its rollout's padding: the pill reaches that
    // rollout's edge, where the level-2 card begins.
    reach: QsmShellStyle.Style.rolloutPadding
    required popoutKind
    popoutDetail: root.armed ? "Click again to confirm — this cannot be undone" : detail
    iconColor: root.armed ? Theme.danger : Theme.text

    onClicked: confirm.trigger()

    // Arriving by keyboard names the cell the way hovering does: the glyph
    // carries no label, so the card is where its name and state are read.
    onActiveFocusChanged: {
        if (activeFocus)
            root.reveal();
    }

    // Escape abandons an armed confirmation first; with nothing armed it
    // passes up so the popout closes.
    Keys.onEscapePressed: event => {
        if (root.armed)
            confirm.disarm();
        else
            event.accepted = false;
    }

    // Leaving the cell abandons the intent: an "armed" that outlives the
    // gesture is a trap laid for the next click.
    onHoveredChanged: {
        if (hovered)
            root.entered();
        else
            confirm.disarm();
    }

    // The confirmation this cell's click goes through is observable state, so
    // arming and abandoning it are observable facts and not silence.
    onArmedChanged: root.interaction(root.armed ? "armed" : "disarmed")

    // Connections, not `onFired`: a cell instance declares `onFired` to say
    // what firing MEANS, and that handler would replace this one.
    Connections {
        target: confirm

        function onFired(): void {
            root.interaction("fired");
        }
    }

    // The arm-then-fire behaviour is the library's and is shared with the
    // session tiles: a confirmation that behaves differently in two places is
    // worse than none, because a person learns the lenient one and is caught
    // by the strict one.
    property QsmShellComponents.ArmedAction confirm: QsmShellComponents.ArmedAction {
        id: confirm
        destructive: root.destructive
        onFired: root.fired()
    }
}
