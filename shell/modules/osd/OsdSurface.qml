import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.state
import qs.theme

Item {
    id: root

    required property var targetScreen
    required property var scene
    required property var host
    readonly property bool active: OsdState.visible && OsdState.targetScreen === root.targetScreen
    readonly property bool fullscreen: root.scene.fullscreen
    readonly property real leadingEdgeX: rollout.x
    readonly property real openFraction: rollout.width / Theme.osdWidth
    readonly property real rolloutTop: rollout.y
    readonly property real rolloutBottom: rollout.y + rollout.height
    readonly property real handleRadius: Theme.handleRadius
    readonly property point handleCenter: Qt.point(root.leadingEdgeX + Theme.osdHandleProud
        - root.handleRadius, root.height / 2)
    readonly property real _zoneLeft: root.handleCenter.x - Theme.iconXs / 2 - Theme.space2
    readonly property real _zoneSpan: root.width - _zoneLeft
    readonly property rect _closedCorridor: Qt.rect(_zoneLeft,
        root.handleCenter.y - root.handleRadius - 30, _zoneSpan, (root.handleRadius + 30) * 2)
    readonly property rect _openCorridor: Qt.rect(_zoneLeft,
        root.rolloutTop - Theme.space2, _zoneSpan,
        root.rolloutBottom - root.rolloutTop + Theme.space2 * 2)
    readonly property rect corridorZone: (root.scene.fullscreen || root.scene.focusMode)
        ? Qt.rect(0, 0, 0, 0)
        : (root.openFraction > 0 ? _openCorridor : _closedCorridor)
    readonly property rect capsuleInputRect: capsule.shown && capsule.acceptsInput
        ? Qt.rect(capsule.x, capsule.y, capsule.width, capsule.height)
        : Qt.rect(0, 0, 0, 0)
    readonly property var outputTarget: osdContent.outputTarget
    readonly property var microphoneTarget: osdContent.microphoneTarget
    readonly property var brightnessTarget: osdContent.brightnessTarget
    readonly property var fullscreenCapsule: capsule
    readonly property var rolloutPresentation: rollout
    readonly property bool fullscreenPresentation: root.fullscreen

    // Capsule keepOpen includes focus, which would latch expiry after a click.
    readonly property bool pointerIntent: root.fullscreen
        ? capsule.pointerHovered
        : rollout.wantsOpen
    readonly property bool retentionHeld: root.active
        && (root.pointerIntent || osdContent.interactionHeld)

    // Whole-shape centring must still leave the outside ring and grown thumb
    // inside the clip aperture.
    readonly property real _focusGap: QsmShellStyle.Style.spaceTight
    function channelEnvelopeHalf(channel: OsdChannel): real {
        if (!channel || !channel.visible)
            return 0;
        const ring = channel.thickness / 2 + root._focusGap;
        return Math.max(channel.implicitWidth / 2, ring);
    }
    readonly property real contentEnvelopeHalf: Math.max(
        osdContent.implicitWidth / 2,
        root.channelEnvelopeHalf(osdContent.outputTarget),
        root.channelEnvelopeHalf(osdContent.microphoneTarget),
        root.channelEnvelopeHalf(osdContent.brightnessTarget))
    readonly property real apertureHalf: (root.fullscreen
        ? capsule.bodySize
        : rollout.bodyWidth) / 2
    readonly property real _contentOffsetLimit: Math.max(0,
        root.apertureHalf - root.contentEnvelopeHalf)
    readonly property real contentCenterOffsetX: Math.max(
        -root._contentOffsetLimit,
        Math.min(root._contentOffsetLimit,
            root.fullscreen ? 0 : rollout.contentCenterOffsetX))

    anchors.fill: parent

    function syncRetention(): void {
        OsdState.setRetention(root.targetScreen, root.retentionHeld);
    }

    function renderFacts(coordinateRoot: Item): var {
        const capsuleOrigin = capsule.mapToItem(coordinateRoot, 0, 0);
        const rolloutOrigin = rollout.mapToItem(coordinateRoot, 0, 0);
        const capsuleRect = Qt.rect(capsuleOrigin.x, capsuleOrigin.y,
            capsule.width, capsule.height);
        const rolloutRect = Qt.rect(rolloutOrigin.x, rolloutOrigin.y,
            rollout.width, rollout.height);
        const bulge = root.host.bulgeRegions[root.rolloutPresentation.rolloutId] ?? null;
        return {
            coordinateSpace: {
                mapped: "story-root",
                local: "item-parent",
                host: "shell-border"
            },
            mode: root.fullscreen ? "capsule" : "rollout",
            active: root.active,
            retention: {
                stateHovered: OsdState.hovered,
                effective: root.retentionHeld,
                pointerIntent: root.pointerIntent,
                contentInteractionHeld: osdContent.interactionHeld,
                contentFocusHeld: osdContent.focusHeld
            },
            capsule: {
                selected: root.active && root.fullscreen,
                shown: capsule.shown,
                present: capsule.present,
                acceptsInput: capsule.acceptsInput,
                keepOpen: capsule.keepOpen,
                pointerHovered: capsule.pointerHovered,
                localRect: Qt.rect(capsule.x, capsule.y, capsule.width, capsule.height),
                rootRect: capsuleRect,
                actualWidth: capsule.width,
                actualHeight: capsule.height,
                preferredWidth: capsule.orientation === Qt.Horizontal
                    ? capsule.preferredLength : capsule.bodySize,
                preferredHeight: capsule.orientation === Qt.Horizontal
                    ? capsule.bodySize : capsule.preferredLength,
                radius: capsule.radius,
                cornerRadii: Qt.vector4d(capsule.radius, capsule.radius,
                    capsule.radius, capsule.radius),
                inputRectSurface: root.capsuleInputRect,
                inputRectRoot: capsule.acceptsInput && capsule.shown ? capsuleRect
                    : Qt.rect(0, 0, 0, 0)
            },
            rollout: {
                selected: root.active && !root.fullscreen,
                visible: rollout.visible,
                localRect: Qt.rect(rollout.x, rollout.y, rollout.width, rollout.height),
                rootRect: rolloutRect,
                actualWidth: rollout.width,
                actualHeight: rollout.height,
                preferredWidth: rollout.bodyWidth,
                preferredHeight: rollout.bodyHeight,
                silhouetteRectHost: rollout.silhouetteRect,
                viewportRectHost: rollout.viewportRect,
                clampedRadius: rollout.clampedRadius,
                cornerRadii: rollout.cornerRadii,
                hostBulge: bulge,
                shaderInputs: bulge ? {
                    rect: bulge.rect,
                    cornerRadii: bulge.radius,
                    blend: bulge.blend,
                    deform: bulge.deform,
                    minEig: bulge.minEig,
                    outness: bulge.outness,
                    originBits: bulge.originBits,
                    edgeBits: bulge.edgeBits
                } : null
            },
            channels: [
                root.channelFacts("output", outputTarget, coordinateRoot),
                root.channelFacts("microphone", microphoneTarget, coordinateRoot),
                root.channelFacts("brightness", brightnessTarget, coordinateRoot)
            ]
        };
    }

    function channelFacts(name: string, channel: OsdChannel, coordinateRoot: Item): var {
        const origin = channel.mapToItem(coordinateRoot, 0, 0);
        const thumb = channel.second.handle;
        const thumbOrigin = thumb.mapToItem(coordinateRoot, 0, 0);
        return {
            name: name,
            visible: channel.visible,
            localRect: Qt.rect(channel.x, channel.y, channel.width, channel.height),
            rootRect: Qt.rect(origin.x, origin.y, channel.width, channel.height),
            actualWidth: channel.width,
            actualHeight: channel.height,
            preferredWidth: channel.implicitWidth,
            preferredHeight: channel.implicitHeight,
            value: channel.value,
            thumbSize: channel.thumbSize,
            thickness: channel.thickness,
            trackMainSpan: channel.vertical ? channel.availableHeight : channel.availableWidth,
            thumbLocalRect: Qt.rect(thumb.x, thumb.y, thumb.width, thumb.height),
            thumbRootRect: Qt.rect(thumbOrigin.x, thumbOrigin.y, thumb.width, thumb.height)
        };
    }

    onActiveChanged: syncRetention()
    onTargetScreenChanged: syncRetention()
    onFullscreenChanged: syncRetention()
    onRetentionHeldChanged: syncRetention()

    Component.onDestruction: OsdState.setRetention(root.targetScreen, false)

    QsmShellComponents.Rollout {
        id: rollout
        host: root.host
        rolloutId: "osd"
        edges: ["right"]
        tier: "small"
        shouldBeActive: root.active
        suppressed: root.fullscreen
        fullscreenDetached: false
        fullscreenCapsule: false
        bodyWidth: Theme.osdWidth
        bodyHeight: osdContent.implicitHeight + Theme.space4 * 2
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        triggerAreas: [root._closedCorridor]
        hoverAreas: [root._openCorridor]
    }

    QsmShellComponents.DataCapsule {
        id: capsule
        objectName: "osd-capsule"
        shown: root.active && root.fullscreen
        timeout: 0
        hoverStay: true
        enabled: root.active && root.fullscreen
        bodySize: Theme.osdWidth
        orientation: Qt.Vertical
        preferredLength: osdContent.implicitHeight + Theme.space4 * 2
        padding: 0
        anchors.right: parent.right
        anchors.rightMargin: Theme.space4
        anchors.verticalCenter: parent.verticalCenter
    }

    OsdContent {
        id: osdContent
        targetScreen: root.targetScreen
        parent: root.fullscreen ? capsule.contentItem : rollout.contentItem
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: root.contentCenterOffsetX
        anchors.verticalCenter: parent.verticalCenter
    }

    Connections {
        target: rollout
        function onTriggeredChanged(): void {
            if (rollout.triggered && root.scene.handlesArmed)
                OsdState.show("output", root.targetScreen);
        }
    }
}
