import QtQuick

Item {
    id: root

    required property var host
    signal interacted(string kind, string action, var payload)
    property rect hostBandArea: Qt.rect(0, 0, 0, 0)
    property bool keyboardRetained: false
    property bool suppressed: false

    property alias parentController: parentController
    property alias childController: childController
    property alias parentPopout: parentPopout
    property alias childPopout: childPopout
    readonly property rect parentRect: parentPopout.settledBodyRect
    readonly property rect childRect: childPopout.settledBodyRect
    readonly property string parentKind: parentController.kind
    readonly property string childKind: childController.kind
    readonly property bool parentHeld: parentPopout.keepOpen
    readonly property bool childHeld: childPopout.keepOpen
    property bool reevaluationPending: false

    function scheduleDismissalReevaluation() {
        if (reevaluationPending)
            return;
        reevaluationPending = true;
        Qt.callLater(() => {
            reevaluationPending = false;
            reevaluateDismissal();
        });
    }

    function reevaluateDismissal() {
        if (keyboardRetained)
            return;
        if (parentController.active && !parentHeld)
            parentController.dismiss();
        if (childController.active && !childHeld)
            childController.dismiss();
    }

    onKeyboardRetainedChanged: scheduleDismissalReevaluation()
    onParentHeldChanged: scheduleDismissalReevaluation()
    onChildHeldChanged: scheduleDismissalReevaluation()

    PopoutController {
        id: parentController

        onKindChanged: {
            if (kind !== "actions" && childController.active)
                childController.dismiss();
            root.scheduleDismissalReevaluation();
        }

        onActiveChanged: root.scheduleDismissalReevaluation()
    }

    PopoutController {
        id: childController
        onActiveChanged: root.scheduleDismissalReevaluation()
    }

    BarPopouts {
        id: parentPopout
        host: root.host
        controller: parentController
        subController: childController
        hostBandArea: root.hostBandArea
        childHost: childPopout
        suppressed: root.suppressed
        onInteracted: (kind, action, payload) => root.interacted(kind, action, payload)
    }

    BarPopouts {
        id: childPopout
        host: root.host
        controller: childController
        bulgeId: "bar-action-popout"
        parentHost: parentPopout
        suppressed: root.suppressed
        matchHeight: parentPopout.bodyHeight
        onInteracted: (kind, action, payload) => root.interacted(kind, action, payload)
        hostBandArea: root.parentRect
    }
}
