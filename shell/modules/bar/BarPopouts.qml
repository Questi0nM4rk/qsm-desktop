pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.services
import qs.theme

// The rail's named content loader. Geometry, clipping, anchor nudge, hover
// intent, shader registration and nested seams all belong to Rollout; this
// wrapper only selects and sizes the content a rail item asked for.
QsmShellComponents.Rollout {
    id: root

    required property var controller
    signal interacted(string kind, string action, var payload)
    // Instantiated twice: the rail's first layer and its quick-action detail
    // layer. Each still owns a registry id and named content controller.
    property string bulgeId: "bar-popout"
    // A nested host derives its seam from the parent's settled geometry. This
    // composes for any depth within the host's active silhouette-slot budget;
    // consumers never read an animated parent width.
    property var parentHost: null
    // Handed to content that hosts its own nested cells, so the column inside
    // this host can drive the host to ITS right.
    property var subController: null
    property rect hostBandArea: Qt.rect(0, 0, 0, 0)

    readonly property bool hasCurrent: controller.active && !suppressed
    property string renderKind: ""
    rolloutId: bulgeId
    edges: ["left"]
    tier: "small"
    radius: Theme.railPopoutRadius
    // Retaining the source while its retired child is still painted is
    // Rollout's own rule (see `childHost`): it holds the source and reports
    // that it is still in motion, so this host states only what its controller
    // asked for and the retained picture is never read as an open one.
    shouldBeActive: hasCurrent
    anchorItem: controller.anchor
    placementBounds: Qt.rect(0, QsmShellStyle.Style.frameThickness, host.width,
        host.height - QsmShellStyle.Style.frameThickness * 2)
    triggerAreas: anchorItem ? [anchorRect] : []
    hoverAreas: {
        const anchor = anchorRect;
        const card = root.settledBodyRect;
        const areas = [hostBandArea, anchor, card];
        if (root.pointer && anchor.width > 0 && card.height > 0)
            areas.push(root.pointer.triangleArea(
                Qt.point(anchor.x + anchor.width, anchor.y + anchor.height / 2),
                Qt.point(card.x, card.y), Qt.point(card.x, card.y + card.height)));
        return areas;
    }
    parentRollout: parentHost
    childRollout: childHost

    // The active per-entry loader drives the TARGET size (their
    // nonAnimWidth/Height — the clamp must use the destination size, never
    // the mid-animation one).
    readonly property var currentPopout: contentColumn.children.find(child => child.shouldBeRendered) ?? null
    readonly property var currentBody: hasCurrent && currentPopout?.shouldBeActive ? currentPopout.item : null
    readonly property alias bodyItem: content
    // The interactive item the currently loaded tier names, and a line of text
    // it renders. Both answer from the tier's own content: a host never reaches
    // into a tier's tree, and a tier that is not loaded answers null.
    function control(name: string): var {
        const body = root.currentBody;
        return body && typeof body.control === "function" ? body.control(name) : null;
    }
    function readout(name: string): var {
        const body = root.currentBody;
        return body && typeof body.readout === "function" ? body.readout(name) : null;
    }
    readonly property real nonAnimWidth: (currentPopout?.implicitWidth ?? 0) + Theme.railPopoutPadding * 2
    // "match" copies the parent rollout's height so the seam between them is a
    // straight line with no step; anything else hugs its content.
    readonly property real nonAnimHeight: currentPopout?.sizing === "match" && root.matchHeight > 0
        ? root.matchHeight
        : Math.ceil(((currentPopout?.implicitHeight ?? 0) + Theme.railPopoutPadding * 2)
            / Theme.popoutBodyStep) * Theme.popoutBodyStep

    function syncRenderKind(): void {
        if (suppressed) {
            renderKind = "";
        } else if (controller.active) {
            renderKind = controller.kind;
        } else if (!visible) {
            renderKind = "";
        }
    }

    Component.onCompleted: syncRenderKind()

    Connections {
        target: root.controller
        function onKindChanged(): void { root.syncRenderKind(); }
    }

    Connections {
        target: root
        function onVisibleChanged(): void { root.syncRenderKind(); }
        function onSuppressedChanged(): void { root.syncRenderKind(); }
    }

    // The height of the rollout this host hangs off. Which tiers USE it is the
    // tier's own choice — see `Popout.sizing` at the bottom of this file. A
    // host-level force would size every tier the same, and a description card
    // and a full menu are not the same kind of surface.
    property real matchHeight: 0

    // The shared Rollout keeps a full-span parent/child seam exact while
    // preserving smooth joins into the frame and short-child T-junctions.
    property var childHost: null

    // A child that MEETS this host's corners, which is what a `sizing: "match"`
    // child does by construction. A short description card sits mid-flank,
    // nowhere near either corner.
    //
    bodyWidth: root.nonAnimWidth
    bodyHeight: root.nonAnimHeight
    // Matched extents already follow the parent's body morph.
    animateBodySize: currentPopout?.sizing !== "match"

    // The shared Rollout owns the clipped extrusion and size morph. This item
    // is only the body content selected by the rail controller.
    Item {
        id: content

        width: root.bodyWidth
        height: root.bodyHeight

        Item {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: Theme.railPopoutPadding

            Popout {
                name: "network"
                sourceComponent: PopoutBody {
                    title: "Network"
                    NetworkPopoutContent {
                        onInteracted: (action, payload) => root.interacted("network", action, payload)
                    }
                }
            }

            Popout {
                name: "bluetooth"
                sourceComponent: PopoutBody {
                    title: "Bluetooth"
                    BluetoothPopoutContent {
                        onInteracted: (action, payload) => root.interacted("bluetooth", action, payload)
                    }
                }
            }

            Popout {
                name: "battery"
                sourceComponent: PopoutBody {
                    title: "Power"
                    BatteryPopoutContent {
                        onInteracted: (action, payload) => root.interacted("battery", action, payload)
                    }
                }
            }

            Popout {
                name: "sound"
                sourceComponent: PopoutBody {
                    title: "Sound"
                    SoundPopoutContent {
                        onInteracted: (action, payload) => root.interacted("sound", action, payload)
                    }
                }
            }

            // A DESCRIPTION tier: name, current state, what a click will do.
            // An icon-only rail names nothing and promises nothing, so a cell
            // with no richer content still rolls out. Cells that own real
            // content override this with theirs.
            //
            // One body, many kinds: identity is the KIND a component declares,
            // not the body it renders, and there is no generic fallback — every
            // cell registers a kind of its own. Two cells of one kind (app rows,
            // tray icons) are told apart by the anchor, not by a new kind.
            DescriptionPopout { name: "updates" }
            DescriptionPopout { name: "railpin" }
            DescriptionPopout { name: "session" }
            DescriptionPopout { name: "keepawake" }
            DescriptionPopout { name: "main-keyboard" }
            DescriptionPopout { name: "clearcache" }

            // The colour-picker's workspace tier: swatch, harmony, shades,
            // copy-on-click. Same reason as the night-light tier — a quick
            // action with something to DO after it fires needs more than a
            // sentence, and the level-2 card is where that lives.
            // NOT wrapped in PopoutBody: this tier is a MENU, not a card. It
            // draws its own heading, splits its groups with the rail's own
            // divider line, and fills the column's height instead of hugging
            // its content — none of which a Column that sizes to its children
            // can do. The `actions` and `calendar` tiers skip PopoutBody too.
            Popout {
                name: "colorpick"
                sizing: "match"
                sourceComponent: ColorPickContent {
                    spanHeight: root.matchHeight - Theme.railPopoutPadding * 2
                }
            }

            // The night-light tier: the one quick action with a CONTROL
            // rather than a sentence. The warmth slider lives here because
            // the level-2 card IS the rail's "expand one step further right"
            // vocabulary, which makes it the single home for the setting
            // (09 one-path) — the cell keeps click-to-toggle.
            //
            // It reads the service DIRECTLY rather than the controller's
            // title/detail, which are snapshotted at hover time and would
            // freeze mid-drag.
            Popout {
                name: "nightlight"
                sourceComponent: NightLightBody {}
            }

            // App row identity + live context. The rail cell shows only the
            // icon; the words live here, horizontal and unelided, because a
            // 40px band cannot carry readable text (03's sideways caption is
            // not used).
            Popout {
                name: "app"
                sourceComponent: PopoutBody {
                    title: root.controller.title
                    QsmShellComponents.Prose {
                        role: "body"
                        muted: true
                        visible: text.length > 0
                        width: Theme.popoutContentWidth
                        text: root.controller.detail
                        // Prose leaves a wrapping role's elide at None
                        // ("somewhere to go"); this one is capped at two
                        // lines by design, so it still needs the ellipsis.
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }
            }

            // No PopoutBody: this is not a card, it is a second RAIL. A title
            // header would make a 72px-wide strip of glyphs pretend to be a
            // titled panel, and the cells inside carry their own names in the
            // level-2 rollout anyway.
            Popout {
                name: "actions"
                sourceComponent: QuickActionsColumn {
                    controller: root.subController
                }
            }

            // No PopoutBody title: MonthCalendar draws its own month header
            // with the ‹ › navigation in it. A second "MMMM yyyy" above that
            // was not merely redundant — it was pinned to `new Date()`, so
            // paging to another month left a header stating the wrong one.
            Popout {
                name: "calendar"
                sourceComponent: QsmShellComponents.MonthCalendar {
                    width: Theme.popoutContentWidth
                }
            }

            Popout {
                name: "tray"
                sourceComponent: PopoutBody {
                    title: root.controller.title
                    TrayMenuContent {
                        trayItem: root.controller.data
                    }
                }
            }
        }
    }

    component Popout: Loader {
        id: popout

        required property string name
        // HOW THIS TIER IS SIZED:
        //
        //   "content"  hug what the tier draws. A description or tooltip card:
        //              the right size for a sentence about the cell you hovered.
        //   "match"    copy the height of the rollout this one came out of. For
        //              a surface that is a MENU rather than a note — it needs
        //              the room whatever it is showing, and the shared height
        //              makes the seam a straight line.
        property string sizing: "content"
        readonly property bool shouldBeActive: root.hasCurrent && root.controller.kind === name
        readonly property bool shouldBeRendered: root.renderKind === name
        readonly property real dpr: Window.window?.devicePixelRatio ?? 1

        // Centred in the padded body, on a whole device pixel: the body is
        // taller than its content by up to a step, and half of that is
        // seldom a whole pixel.
        x: Math.round((parent.width - width) / 2 * dpr) / dpr
        y: Math.round((parent.height - height) / 2 * dpr) / dpr

        active: shouldBeRendered
        enabled: shouldBeActive
    }

    // A DESCRIPTION tier: the shared body reading the controller's own
    // snapshot. What a kind renders is written once; the kind is what names
    // the component, so several components can share this body without
    // becoming indistinguishable.
    component DescriptionPopout: Popout {
        sourceComponent: PopoutBody {
            title: root.controller.title
            QsmShellComponents.Prose {
                role: "body"
                muted: true
                width: Theme.popoutContentWidth
                text: root.controller.detail
            }
        }
    }

    // Shared card body: title header + one content child.
    component PopoutBody: Column {
        id: body

        default property alias content: inner.data
        property string title

        width: Theme.popoutContentWidth
        spacing: QsmShellStyle.Style.space2

        QsmShellComponents.Prose {
            role: "title"
            // The card's inner width, so a long title elides instead of
            // running past the card's edge.
            width: parent.width
            // A line box of font metrics falls between device pixels and would
            // carry every row below it off the grid; the rhythm step does not.
            height: QsmShellStyle.Style.rhythm(implicitHeight)
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: body.title
            textFormat: Text.PlainText
        }

        Column {
            id: inner
            width: parent.width
            spacing: QsmShellStyle.Style.space2

            // Content components are ColumnLayouts — pin their width to the
            // card so fillWidth rows actually fill.
            Component.onCompleted: {
                for (const child of children)
                    child.width = Qt.binding(() => inner.width);
            }
        }
    }

    component NightLightBody: PopoutBody {
        id: nightLight

        title: "Night light"

        // The slider and the line that states what it is set to, as the actual
        // rendered items: input reaches the control itself and the readout is
        // read from the control's own text.
        readonly property Item warmthControl: warmthSlider
        readonly property string warmthReadout: warmthText.text

        function control(name: string): var {
            return name === "warmth" ? nightLight.warmthControl : null;
        }
        function readout(name: string): var {
            return name === "warmth" ? nightLight.warmthReadout : null;
        }

        ColumnLayout {
            width: Theme.popoutContentWidth
            spacing: QsmShellStyle.Style.space2

            RowLayout {
                Layout.fillWidth: true
                spacing: QsmShellStyle.Style.space2

                QsmShellComponents.SvgIcon {
                    name: "brightness"
                    size: QsmShellStyle.Style.iconSm
                    color: Theme.textMuted
                }

                QsmShellComponents.Slider {
                    id: warmthSlider
                    Layout.fillWidth: true
                    value: NightLightService.strength
                    wheelUnits: Math.round(Theme.osdWheelStep / stepSize)
                    // Warm, because that is what the level means.
                    fill: Theme.warning
                    onMoved: NightLightService.setStrength(warmthSlider.value)
                }

                QsmShellComponents.SvgIcon {
                    name: "moon"
                    size: QsmShellStyle.Style.iconSm
                    color: Theme.textMuted
                }
            }

            // The value WHILE moving (09: "I moved it to 62%", not
            // "I moved it"). Kelvin rides along because it is the
            // number hyprsunset's own docs and every other night-
            // light tool speak in.
            QsmShellComponents.Prose {
                id: warmthText
                // The line explaining what the slider above it is
                // currently set to.
                role: "supporting"
                Layout.fillWidth: true
                text: NightLightService.active
                    ? `Warmth ${Math.round(NightLightService.strength * 100)}% · ${NightLightService.temperature}K`
                    : "Off · drag to warm the screen"
            }

            QsmShellComponents.Prose {
                role: "metadata"
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.controller.detail
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
            }
        }
    }
}
