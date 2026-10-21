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

    readonly property string _appIcon: root.item?.appIcon ?? ""
    readonly property url _thumb: root.item?.thumb ?? ""
    readonly property bool _isApp: root._appIcon.length > 0 || root.item?.kind === "app"
    // A wallpaper's aspect: the picture box is as tall as the leading box.
    readonly property real _thumbAspect: 7 / 4

    // Action-picker group labels are model rows so the keyboard can preserve
    // its one cursor. They render as an inert divider, never as an action.
    header: (root.item?.kind ?? "") === "header"
    primary: root.item?.label ?? ""
    supporting: root.item?.sub ?? ""

    // The leading slot: a wallpaper thumbnail, an application icon, or a
    // command glyph. All three sit in the row's own leading box, so the label
    // starts at the same x whichever one a given row has.
    leading: Item {
        id: lead
        anchors.fill: parent
        // The picture box exists only once the picture has loaded; until
        // then the app icon or glyph stays, so no empty box flashes.
        readonly property bool thumbReady: thumbImage.status === Image.Ready

        // Wallpaper thumbnail (>theme rows), sized off the leading box so
        // compact rows shrink it with them.
        Rectangle {
            anchors.centerIn: parent
            opacity: lead.thumbReady ? 1 : 0
            height: parent.height
            width: height * root._thumbAspect
            radius: QsmShellStyle.Style.radiusSm
            color: QsmShellStyle.Style.surface
            clip: true

            Behavior on opacity { NumberAnimation { duration: QsmShellStyle.Motion.fast; easing.type: QsmShellStyle.Motion.standardEasing } }

            Image {
                id: thumbImage
                anchors.fill: parent
                source: root._thumb
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        AppIcon {
            anchors.centerIn: parent
            visible: !lead.thumbReady && root._isApp
            implicitSize: parent.height
            icon: root._appIcon
        }

        // The row's own glyph size inside the shared box: a command glyph
        // is not as loud as an application's icon, it just has to start the
        // text in the same place.
        QsmShellComponents.SvgIcon {
            anchors.centerIn: parent
            visible: !lead.thumbReady && !root._isApp
            name: root.item?.icon ?? "sparkle"
            size: root.glyphSize
            // A kill row must not look like a launch row: the glyph carries
            // the danger colour; the text stays ordinary.
            color: (root.item?.kind ?? "").startsWith("kill")
                ? Theme.danger : Theme.text
        }
    }
}
