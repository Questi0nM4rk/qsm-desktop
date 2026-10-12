pragma Singleton

import QtQuick

// The icon shed: the one place that knows which glyph in `assets/icons`
// stands for which KIND of thing. Callers pass what the outside world told
// them (a BlueZ icon name, a device name) and get back a name from our set —
// never a raw upstream string, which is how the rail ended up rendering the
// generic placeholder for every connected device.
//
// Freedesktop/BlueZ icon names are the primary key; the device's own name is
// the fallback sniff, because plenty of devices report `unknown` or nothing
// at all while calling themselves "… Buds" or "… Keyboard".
QtObject {
    id: root

    readonly property string deviceFallback: "bluetooth-connected"

    // Freedesktop icon name -> our glyph.
    readonly property var deviceIcons: ({
        "input-keyboard": "keyboard",
        "input-mouse": "mouse",
        "input-tablet": "tablet",
        "input-gaming": "gamepad",
        "audio-headset": "headset",
        "audio-headphones": "headphones",
        "audio-card": "speaker",
        "audio-speakers": "speaker",
        "audio-input-microphone": "microphone",
        "multimedia-player": "music",
        "phone": "smartphone",
        "computer": "monitor",
        "video-display": "monitor",
        "printer": "printer"
    })

    // Substring of the device's own name -> our glyph. Ordered by how
    // specific the hint is: "headset" must beat "head", "gamepad" must beat
    // "pad", so the longest match wins rather than the first.
    readonly property var deviceNameHints: ({
        "keyboard": "keyboard",
        "keeb": "keyboard",
        "mouse": "mouse",
        "trackpad": "tablet",
        "tablet": "tablet",
        "controller": "gamepad",
        "gamepad": "gamepad",
        "dualsense": "gamepad",
        "dualshock": "gamepad",
        "xbox": "gamepad",
        "headset": "headset",
        "headphone": "headphones",
        "buds": "headphones",
        "pods": "headphones",
        "speaker": "speaker",
        "soundbar": "speaker",
        "boom": "speaker",
        "mic": "microphone",
        "watch": "watch",
        "band": "watch",
        "phone": "smartphone",
        "printer": "printer"
    })

    // A connected device's glyph: declared icon first, then a name sniff,
    // then the neutral bluetooth mark.
    function forDevice(icon: string, name: string): string {
        const declared = deviceIcons[String(icon ?? "").toLowerCase()];
        if (declared)
            return declared;

        const haystack = String(name ?? "").toLowerCase();
        let best = "";
        let bestLength = 0;
        for (const hint in deviceNameHints) {
            if (haystack.includes(hint) && hint.length > bestLength) {
                best = deviceNameHints[hint];
                bestLength = hint.length;
            }
        }
        return best.length > 0 ? best : root.deviceFallback;
    }
}
