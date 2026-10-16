import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.theme

// One rail readout (03 RATIFIED 2026-10-16): a 14px glyph and a 12px tabular
// number as ONE item. The whole item is textMuted below 70 percent, warning
// from 70, danger from 90. An unavailable value shows an em dash. A readout
// has a number and no click: it is not a button.
Item {
    id: root

    required property string icon
    // 0..1, or below 0 when the service has no reading.
    required property real value
    // CPU jitters sample to sample; an exponential average (0.3 per sample)
    // shows the load, not the last half second.
    property bool smoothed: false
    property real _average: -1

    readonly property real shown: smoothed ? _average : value
    readonly property bool available: Number.isFinite(shown) && shown >= 0
    readonly property real percent: available ? Math.min(1, shown) * 100 : 0
    readonly property color tone: !available ? Theme.textMuted
        : percent >= 90 ? Theme.danger
        : percent >= 70 ? Theme.warning
        : Theme.textMuted

    onValueChanged: {
        if (!smoothed)
            return;
        if (!Number.isFinite(value) || value < 0) {
            _average = -1;
            return;
        }
        _average = _average < 0 ? value : _average + 0.3 * (value - _average);
    }

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.iconMd

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.space1

        QsmShellComponents.SvgIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: Theme.railReadoutGlyph
            color: root.tone

            Behavior on color {
                ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
            }
        }

        QsmShellComponents.Prose {
            anchors.verticalCenter: parent.verticalCenter
            role: "metadata"
            technical: true
            text: root.available ? String(Math.round(root.percent)) : "—"
            color: root.tone
            elide: Text.ElideNone

            Behavior on color {
                ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
            }
        }
    }
}
