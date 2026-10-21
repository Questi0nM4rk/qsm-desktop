import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle

Item {
    id: root

    required property var surface
    required property var scene
    readonly property vector4d shaderHandle: Qt.vector4d(surface.handleCenter.x,
        surface.handleCenter.y, scene.fullscreen || scene.focusMode ? 0 : surface.handleRadius, 1)
    readonly property alias glyphItem: glyph

    anchors.fill: parent

    function renderFacts(coordinateRoot: Item): var {
        const center = root.mapToItem(coordinateRoot,
            root.surface.handleCenter.x, root.surface.handleCenter.y);
        const glyphOrigin = glyph.mapToItem(coordinateRoot, 0, 0);
        const surfaceOrigin = root.surface.mapToItem(coordinateRoot, 0, 0);
        const corridor = root.surface.corridorZone;
        return {
            vector: Qt.vector4d(center.x, center.y, root.shaderHandle.z, root.shaderHandle.w),
            glyphVisible: glyph.visible,
            glyphRect: Qt.rect(glyphOrigin.x, glyphOrigin.y, glyph.width, glyph.height),
            glyphRotation: glyph.rotation,
            glyphCorners: [glyph.mapToItem(coordinateRoot, 0, 0),
                glyph.mapToItem(coordinateRoot, glyph.width, 0),
                glyph.mapToItem(coordinateRoot, glyph.width, glyph.height),
                glyph.mapToItem(coordinateRoot, 0, glyph.height)],
            corridorLocal: corridor,
            corridorRoot: Qt.rect(surfaceOrigin.x + corridor.x, surfaceOrigin.y + corridor.y,
                corridor.width, corridor.height)
        };
    }

    QsmShellComponents.SvgIcon {
        id: glyph
        visible: !root.scene.fullscreen && !root.scene.focusMode
        name: "chevron-left"
        size: QsmShellStyle.Style.iconXs
        x: root.surface.handleCenter.x - width / 2
        y: root.surface.handleCenter.y - height / 2
        rotation: root.surface.openFraction * 180
    }
}
