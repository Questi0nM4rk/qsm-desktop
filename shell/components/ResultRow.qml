import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.components
import qs.theme

// One result row — shared by the launcher and the clipboard surface, which is
// why it lives in components rather than inside either one.
//
// It is the library's row plus THIS shell's model shape. The row itself knows
// nothing about `kind`, `appIcon` or `thumb`; those are the launcher's result
// objects, and translating them is exactly the job a consumer keeps.
//
// HOVER SELECTS. Pointer and keyboard drive ONE cursor rather than a hover
// highlight racing a separate selection highlight — the tick simply follows
// whichever you last used, and Enter always means the row you can see marked.
QsmShellComponents.ListRow {
    id: root

    // { kind, label, sub, icon (svg name) | appIcon (desktop icon name) | thumb }
    required property var item
    // Compact rows (clipboard, owner live-tune 2026-08-20): tighter height,
    // one text step down, one icon step down. The launcher keeps the RATIFIED
    // 57px default.
    property bool compact: false

    readonly property string _appIcon: root.item?.appIcon ?? ""
    readonly property url _thumb: root.item?.thumb ?? ""
    readonly property bool _isApp: root._appIcon.length > 0 || root.item?.kind === "app"

    // Action-picker group labels are model rows so the keyboard can preserve
    // its one cursor. They render as an inert divider, never as an action.
    header: (root.item?.kind ?? "") === "header"
    size: root.compact ? "md" : "lg"
    primary: root.item?.label ?? ""
    supporting: root.item?.sub ?? ""

    // Spec 07 RATIFIED heights, which sit a pixel off the library's control
    // scale. The library's row states the scale; a call site with a ratified
    // number states the number.
    headingHeight: root.header
        ? Theme.space4 + Theme.space2
        : (root.compact ? Theme.clipboardRowHeight : Theme.launcherRowHeight)

    // The leading slot: a wallpaper thumbnail, an application icon, or a
    // command glyph. All three sit in the row's own leading box, so the label
    // starts at the same x whichever one a given row has.
    leading: Item {
        anchors.fill: parent

        // Wallpaper thumbnail (>theme rows). 7:4, sized off the leading box so
        // compact rows shrink it with them.
        Rectangle {
            anchors.centerIn: parent
            visible: root._thumb.toString().length > 0
            height: parent.height
            width: height * 7 / 4
            radius: QsmShellStyle.Style.radiusSm
            color: QsmShellStyle.Style.surfaceRaised
            clip: true

            Image {
                anchors.fill: parent
                source: root._thumb
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        AppIcon {
            anchors.centerIn: parent
            visible: root._thumb.toString().length === 0 && root._isApp
            implicitSize: parent.height
            icon: root._appIcon
        }

        // The glyph keeps its own smaller size inside the shared box — a
        // command glyph should not be as loud as an application's icon, it
        // just has to start the text in the same place.
        QsmShellComponents.SvgIcon {
            anchors.centerIn: parent
            visible: root._thumb.toString().length === 0 && !root._isApp
            name: root.item?.icon ?? "sparkle"
            size: root.compact ? QsmShellStyle.Style.iconSm : QsmShellStyle.Style.iconMd
            // A kill row must not look like a launch row (owner 2026-08-21):
            // the glyph carries the danger colour; the text stays ordinary.
            color: (root.item?.kind ?? "").startsWith("kill")
                ? Theme.danger : Theme.text
        }
    }
}
