pragma Singleton

import QtQuick
import Quickshell.Io

// Who and what: user, distro, WM and uptime for the dashboard identity card
// (06 DEFAULT). The card is an IDENTITY card, so it has to say whose session
// this is.
QtObject {
    id: root

    property string user: ""
    property string distro: ""
    readonly property string wm: "Hyprland"
    property string uptime: ""

    function refresh(): void {
        if (!probe.running)
            probe.running = true;
    }

    // "1 day, 2 hours" / "2 hours, 13 mins" / "13 mins" — largest two
    // non-zero components, correctly singular/plural (dashboard user card).
    function formatUptime(totalSeconds: int): string {
        const days = Math.floor(totalSeconds / 86400);
        const hours = Math.floor((totalSeconds % 86400) / 3600);
        const mins = Math.floor((totalSeconds % 3600) / 60);
        const unit = (count, singular, plural) => `${count} ${count === 1 ? singular : plural}`;
        const parts = [];
        if (days > 0)
            parts.push(unit(days, "day", "days"));
        if (days > 0 || hours > 0)
            parts.push(unit(hours, "hour", "hours"));
        if (parts.length < 2)
            parts.push(unit(mins, "min", "mins"));
        return parts.slice(0, 2).join(", ");
    }

    property Process probe: Process {
        id: probe
        command: ["bash", "-c",
            `id -un; . /etc/os-release && echo "$PRETTY_NAME"; awk '{print int($1)}' /proc/uptime`]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const [userLine, distroLine, uptimeLine] = text.trim().split("\n");
                root.user = userLine ?? "";
                root.distro = distroLine ?? "";
                root.uptime = root.formatUptime(parseInt(uptimeLine, 10) || 0);
            }
        }
    }
}
