import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.UPower
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.services
import qs.theme

// Battery popout (03 DEFAULT, per references/battery-popout-corner-join.png):
// charge % + time estimate (or "No battery detected"), the live DRAW, and a
// profile switch row (powerprofilesctl).
//
// THE ESTIMATE IS DERIVED HERE, not taken from UPower's time-to-empty.
//
// UPower smooths time-to-empty over its own history and re-reads the battery on
// its own ~30s cadence, so selecting performance left this card claiming the
// same hours as eco for a minute afterwards — which is the "performance and eco
// have the same battery life" symptom. UPower
// implements no Refresh() to poke either: it is introspectable on the device
// interface and answers UnknownMethod. Beating that cadence means reading the
// same kernel file UPower reads.
//
// So: energy / draw, with the draw read from sysfs every 2s WHILE THIS CARD IS
// ON SCREEN. The popout's Loader owns this component's lifetime, so the poll
// exists exactly as long as someone is looking at it — no singleton, no reading
// the battery when nobody asked.
ColumnLayout {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool present: device?.isLaptopBattery ?? false
    readonly property string profile: PowerProfileService.profile
    signal interacted(string action, var payload)
    readonly property bool charging: device?.state === UPowerDeviceState.Charging
    readonly property bool full: device?.state === UPowerDeviceState.FullyCharged

    // power_now is MICROWATTS. Zero or missing is normal — a charged battery on
    // AC publishes 0, and some batteries only publish current_now (µA, which
    // needs the voltage to become power). Either way the fallback below covers
    // it rather than this guessing.
    property real kernelWatts: 0

    // The SMOOTHED draw, and the reason the estimate stopped lying.
    //
    // power_now is an instantaneous reading, and instantaneous power on a
    // laptop swings with whatever the CPU did in the last half second. Divided
    // straight into the remaining energy it produced an estimate that climbed
    // three minutes and then fell back — the owner watched it do exactly that
    // — which is worse than no estimate, because a number that moves the wrong
    // way is one you learn to distrust.
    //
    // An exponential average over roughly the last ten seconds (2s poll, 0.3
    // weight per sample) settles the number without deadening it: a power
    // profile change still shows up within a couple of samples, which is the
    // whole reason this reads the kernel file rather than UPower's own rate.
    // The first sample seeds it outright, so opening the card shows a figure
    // immediately instead of easing up from zero.
    property real smoothedWatts: 0

    function sampleDraw(watts: real): void {
        root.kernelWatts = watts;
        if (watts <= 0)
            return;

        root.smoothedWatts = root.smoothedWatts > 0
            ? root.smoothedWatts * 0.7 + watts * 0.3
            : watts;
    }

    // The number that MOVES when the profile changes, which is the whole point.
    readonly property real draw: smoothedWatts > 0
        ? smoothedWatts
        : Math.abs(root.device?.changeRate ?? 0)

    // Wh still to spend, or Wh still to take on.
    readonly property real energyToGo: root.charging
        ? Math.max(0, (root.device?.energyCapacity ?? 0) - (root.device?.energy ?? 0))
        : (root.device?.energy ?? 0)

    function formatHours(hours: real): string {
        const whole = Math.floor(hours);
        const minutes = Math.floor((hours - whole) * 60);
        return `${whole}h ${minutes}m`;
    }

    readonly property string estimate: {
        if (root.draw > 0 && root.energyToGo > 0)
            return `${root.formatHours(root.energyToGo / root.draw)} ${root.charging ? "to full" : "left"}`;

        // No draw to divide by. UPower's own figure is better than nothing if
        // it has one, and "Charged" is the honest answer when it does not.
        const seconds = root.charging ? root.device?.timeToFull : root.device?.timeToEmpty;
        if (seconds > 0) {
            const hours = Math.floor(seconds / 3600);
            const minutes = Math.floor((seconds % 3600) / 60);
            return `${hours}h ${minutes}m ${root.charging ? "to full" : "left"}`;
        }

        return root.full ? "Charged" : "";
    }

    // sysfs does not emit change notifications worth trusting, so this is a
    // plain poll rather than watchChanges. Re-read the instant the profile
    // changes too: that press is exactly when the number is being watched.
    property FileView drawFile: FileView {
        id: drawFile
        path: `/sys/class/power_supply/${root.device?.nativePath ?? "BAT0"}/power_now`
        printErrors: false
        onLoaded: root.sampleDraw((parseFloat(text()) || 0) / 1000000)
        onLoadFailed: root.sampleDraw(0)
    }

    property Timer drawPoll: Timer {
        interval: 2000
        repeat: true
        running: root.present
        triggeredOnStart: true
        onTriggered: drawFile.reload()
    }

    onProfileChanged: drawFile.reload()

    spacing: QsmShellStyle.Style.space2

    Component.onCompleted: PowerProfileService.refresh()

    function setProfile(name: string): void {
        if (!PowerProfileService.available) return;
        root.interacted("profile", { profile: name });
        PowerProfileService.setProfile(name);
    }

    QsmShellComponents.Prose {
        role: "body"
        muted: true
        visible: !root.present
        text: "No battery detected"
    }

    // Charge: the NUMBER leads, the estimate supports it. Both used to sit in
    // one bold mono string ("99% · 2h 30m left"), which gave a reading and a
    // guess the same weight.
    RowLayout {
        visible: root.present
        Layout.fillWidth: true
        spacing: QsmShellStyle.Style.space2

        QsmShellComponents.SvgIcon {
            name: root.charging ? "battery-charging" : "battery"
            size: QsmShellStyle.Style.iconMd
            color: root.charging ? Theme.success : Theme.text
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            QsmShellComponents.Prose {
                role: "heading"
                technical: true
                text: `${Math.round((root.device?.percentage ?? 0) * 100)}%`
            }

            QsmShellComponents.Prose {
                role: "metadata"
                visible: text.length > 0
                // The WATTS ride with the estimate, and they are the reason
                // this row answers a profile change at all: the hours only
                // round differently once the draw has moved a fair bit, but
                // the wattage moves the moment the governor does. "3h 12m
                // left · 14.1 W" says what the estimate is made of, so a
                // profile switch has something visible to change.
                text: root.draw > 0 && root.estimate.length > 0
                    ? `${root.estimate} · ${root.draw.toFixed(1)} W`
                    : root.estimate
            }
        }
    }

    // The same slim level bar the OSD, the seek row and the thermal readout
    // use — a battery popout with no battery in it was the one surface here
    // that showed a level without drawing one.
    QsmShellComponents.Meter {
        visible: root.present
        Layout.fillWidth: true
        value: root.device?.percentage ?? 0
        // Charging is not a threshold breach and low is not a warning here, so
        // the colour is stated rather than derived: Meter's own `low` would
        // paint amber where this surface means danger.
        fill: (root.device?.percentage ?? 1) < Theme.lowBatteryFraction && !root.charging
            ? Theme.danger : root.charging ? Theme.success : Theme.accent
    }

    // Empty/unavailable state comes before the happy one: with no provider
    // running, the switch row below cannot exist, and saying nothing looked
    // like a missing feature rather than a missing daemon.
    QsmShellComponents.Prose {
        role: "metadata"
        visible: !PowerProfileService.available
        // What happened AND how to fix it — the old wording described the
        // daemon's absence without saying what to do about it.
        text: "No power profiles — install power-profiles-daemon"
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }

    // The library's segmented control, one glyph per profile; the sliding
    // indicator, keyboard wrap and focus ring are its own.
    QsmShellComponents.Segmented {
        id: profileSwitch

        readonly property var profiles: ["power-saver", "balanced", "performance"]

        visible: root.profile.length > 0
        Layout.fillWidth: true
        size: "sm"
        options: profiles.map(name => ({ icon: PowerProfileService.iconFor(name), name: name.replace("-", " ") }))
        currentIndex: profiles.indexOf(root.profile)
        Accessible.name: "Power profile"
        onSelected: index => root.setProfile(profiles[index])
    }

    // The active profile names itself under the control it belongs to, rather
    // than as a "Profile: balanced" line above it (visual-craft: fold the
    // label into the value).
    QsmShellComponents.Prose {
        role: "metadata"
        visible: root.profile.length > 0
        Layout.alignment: Qt.AlignHCenter
        text: root.profile.replace("-", " ")
    }
}
