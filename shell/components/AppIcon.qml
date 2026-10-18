pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle

// Application icon: the one place that knows how a desktop-entry icon name
// resolves and what to show when it does not.
//
// This is the consumer's job and stays here. The caller hands us a WINDOW
// CLASS, which is not an icon name: Zen reports class "zen" while its icon is
// "zen-browser" (zen.desktop: Icon=zen-browser). Feeding the class straight to
// `iconPath()` made every app whose class differs from its icon name fall back
// to the placeholder. So: class -> desktop entry -> that entry's declared icon,
// and only then the theme lookup. `DesktopEntries` and `iconPath` are
// Quickshell's; a component library has no business knowing either.
//
// The FALLBACK comes from the library's icon set and takes the theme's colour.
// It used to be a raw SVG out of a second copy of that set living in this
// repo — 79 files, byte-identical to the library's, kept alive by this one
// reference. A themed glyph is also the better answer: a flat white
// placeholder among themed icons reads as a rendering fault.
Item {
    id: root

    property string icon: ""
    property int implicitSize: QsmShellStyle.Style.iconLg
    // Transparent keeps the application's own colours (launcher, workspace
    // tiles). A colour makes the bitmap one tone of the glyph set: the rail
    // paints apps as outline glyphs, and a sampled #3C3E40 disc beside them
    // reads as a hole.
    property color tint: "transparent"
    readonly property bool tinted: tint.a > 0

    readonly property var entry: icon.length > 0
        ? DesktopEntries.heuristicLookup(icon)
        : null
    readonly property string iconName: {
        const declared = entry?.icon ?? "";
        return declared.length > 0 ? declared : icon;
    }
    readonly property string resolved: iconName.length > 0
        ? Quickshell.iconPath(iconName, true)
        : ""

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    IconImage {
        anchors.fill: parent
        visible: root.resolved.length > 0
        source: root.resolved
        asynchronous: true
        layer.enabled: root.tinted
        layer.effect: MultiEffect {
            // Luminance times colour, like SvgIcon; the lift keeps a dark
            // disc from tinting to near black.
            colorization: 1
            colorizationColor: root.tint
            brightness: 0.5
        }
    }

    QsmShellComponents.SvgIcon {
        anchors.centerIn: parent
        visible: root.resolved.length === 0
        name: "application"
        size: root.implicitSize
        color: QsmShellStyle.Style.textMuted
    }
}
