pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Sensor sampling for the Performance tab (06 DEFAULT sources, amended for
// the caelestia-parity card grid): CPU usage from /proc/stat deltas, CPU
// temp from hwmon (k10temp/coretemp/zenpower autodetect), GPU from amdgpu
// hwmon or nvidia-smi, memory from /proc/meminfo, storage from df /,
// network rx/tx rate + session totals from /proc/net/dev (lo excluded).
// CPU/memory poll while a visible handle watches; details only while a tab polls.
// A missing sensor leaves its
// value at -1 — its ring/row hides. A visual test run (DRIVE_FIXTURES, a
// directory) reads fixed readings from performance.json instead, so the tab
// shows the same machine on every run.
QtObject {
    id: root

    readonly property string fixtures: Quickshell.env("DRIVE_FIXTURES") ?? ""

    property var detailedOwners: []
    readonly property bool polling: detailedOwners.length > 0
    property var watchers: ({})
    readonly property bool sampling: polling || Object.keys(watchers).length > 0

    function watch(name: string, enabled: bool): void {
        if (!!watchers[name] === enabled) return;
        const next = Object.assign({}, watchers);
        if (enabled) next[name] = true;
        else delete next[name];
        watchers = next;
    }

    // Instance identity, not a tab kind: two panel hosts can overlap at handoff.
    function watchDetails(owner: var, enabled: bool): void {
        if (detailedOwners.includes(owner) === enabled) return;
        detailedOwners = enabled ? detailedOwners.concat([owner])
            : detailedOwners.filter(candidate => candidate !== owner);
    }

    property real cpuUsage: -1
    property int cpuTemp: -1
    property real gpuUsage: -1
    property int gpuTemp: -1
    property real memUsed: -1
    property string memText: ""
    property string storageText: ""
    property real storageUsed: -1

    // Network: rate in bytes/sec (-1 = not yet computed), session totals
    // are the raw cumulative hwmon-style counters formatted for display,
    // history arrays feed the sparkline — fixed length, reassigned (not
    // pushed-into) on every sample so bindings fire.
    property real netRxRate: -1
    property real netTxRate: -1
    property string netRxRateText: "—"
    property string netTxRateText: "—"
    property string netRxTotalText: ""
    property string netTxTotalText: ""
    property var netRxHistory: []
    property var netTxHistory: []
    // Sparkline sample cap — a service-owned data-shape decision, not a
    // presentation token.
    readonly property int netHistorySamples: 60

    // Previous /proc/stat cpu totals for the usage delta.
    property double prevTotal: 0
    property double prevIdle: 0

    // Previous /proc/net/dev totals + wall-clock time for the rate delta.
    property double netPrevRx: -1
    property double netPrevTx: -1
    property double netPrevTime: 0

    function formatBytes(bytes: real): string {
        if (!(bytes > 0))
            return "0 B";
        const units = ["B", "KiB", "MiB", "GiB", "TiB"];
        let value = bytes;
        let unit = 0;
        while (value >= 1024 && unit < units.length - 1) {
            value /= 1024;
            unit += 1;
        }
        return `${value.toFixed(unit === 0 ? 0 : 1)} ${units[unit]}`;
    }

    function pushSample(history: var, value: real): var {
        const next = history.concat([value]);
        return next.length > netHistorySamples
            ? next.slice(next.length - netHistorySamples) : next;
    }

    onSamplingChanged: {
        if (sampling) {
            prevTotal = 0;
            sample.running = true;
            pollTimer.start();
        } else {
            pollTimer.stop();
        }
    }

    property Timer pollTimer: Timer {
        interval: 2000
        repeat: true
        onTriggered: {
            if (!sample.running)
                sample.running = true;
        }
    }

    property Process sample: Process {
        id: sample
        command: root.fixtures.length > 0 ? ["cat", `${root.fixtures}/performance.json`] : ["bash", "-c", `
cpu=$(head -1 /proc/stat)
mem=$(awk '/^MemTotal|^MemAvailable/ {print $2}' /proc/meminfo | tr '\\n' ' ')
echo "CPU|$cpu"
echo "MEM|$mem"
[ "$1" = detailed ] || exit 0
disk=$(df --output=used,size -k / 2>/dev/null | tail -1)
net=$(awk -F: 'NR>2{gsub(/^[ \\t]+/,"",$1); if($1!="lo"){split($2,f," "); rx+=f[1]; tx+=f[9]}} END{print rx" "tx}' /proc/net/dev)
ctemp=""
gtemp=""
gbusy=""
for d in /sys/class/hwmon/*; do
  [ -r "$d/name" ] || continue
  n=$(<"$d/name")
  case "$n" in
    k10temp|coretemp|zenpower)
      [ -r "$d/temp1_input" ] && ctemp=$(( $(<"$d/temp1_input") / 1000 )) ;;
    amdgpu)
      [ -r "$d/temp1_input" ] && gtemp=$(( $(<"$d/temp1_input") / 1000 ))
      dev=$(readlink -f "$d/device" 2>/dev/null)
      [ -n "$dev" ] && [ -r "$dev/gpu_busy_percent" ] && gbusy=$(<"$dev/gpu_busy_percent") ;;
  esac
done
if [ -z "$gtemp" ] && command -v nvidia-smi >/dev/null 2>&1; then
  line=$(nvidia-smi --query-gpu=temperature.gpu,utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
  gtemp=$(echo "$line" | cut -d, -f1 | tr -d ' ')
  gbusy=$(echo "$line" | cut -d, -f2 | tr -d ' ')
fi
echo "DISK|$disk"
echo "NET|$net"
echo "CTEMP|$ctemp"
echo "GTEMP|$gtemp"
echo "GBUSY|$gbusy"
`, "qsm-performance", root.polling ? "detailed" : "glance"]

        stdout: StdioCollector {
            onStreamFinished: root.fixtures.length > 0 ? root.applyReadings(text) : root.parse(text)
        }
    }

    function applyReadings(text: string): void {
        const readings = JSON.parse(text);
        for (const key of Object.keys(readings))
            root[key] = readings[key];
    }

    function parse(text: string): void {
        for (const line of text.split("\n")) {
            const sep = line.indexOf("|");
            if (sep === -1)
                continue;

            const key = line.slice(0, sep);
            const value = line.slice(sep + 1).trim();
            if (key === "CPU") {
                // guest/guest_nice are already included in user/nice totals.
                const fields = value.split(/\s+/).slice(1, 9).map(Number);
                const idle = fields[3] + (fields[4] ?? 0);
                const total = fields.reduce((sum, field) => sum + (field || 0), 0);
                if (prevTotal > 0 && total > prevTotal) {
                    const usage = Math.max(0, Math.min(1, 1 - (idle - prevIdle) / (total - prevTotal)));
                    cpuUsage = cpuUsage < 0 ? usage : cpuUsage + 0.3 * (usage - cpuUsage);
                }
                prevTotal = total;
                prevIdle = idle;
            } else if (key === "MEM") {
                const [totalKb, availKb] = value.split(/\s+/).map(Number);
                if (totalKb > 0) {
                    memUsed = (totalKb - availKb) / totalKb;
                    memText = `${((totalKb - availKb) / 1048576).toFixed(1)} / ${(totalKb / 1048576).toFixed(1)} GiB`;
                }
            } else if (key === "DISK") {
                const [usedKb, sizeKb] = value.split(/\s+/).map(Number);
                if (sizeKb > 0) {
                    storageText = `${(usedKb / 1048576).toFixed(1)} / ${(sizeKb / 1048576).toFixed(1)} GiB`;
                    storageUsed = usedKb / sizeKb;
                }
            } else if (key === "NET") {
                const [rx, tx] = value.split(/\s+/).map(Number);
                const now = Date.now();
                if (netPrevTime > 0 && rx >= netPrevRx && tx >= netPrevTx) {
                    const dt = (now - netPrevTime) / 1000;
                    if (dt > 0) {
                        netRxRate = (rx - netPrevRx) / dt;
                        netTxRate = (tx - netPrevTx) / dt;
                        netRxRateText = `${formatBytes(netRxRate)}/s`;
                        netTxRateText = `${formatBytes(netTxRate)}/s`;
                        netRxHistory = pushSample(netRxHistory, netRxRate);
                        netTxHistory = pushSample(netTxHistory, netTxRate);
                    }
                }
                netRxTotalText = formatBytes(rx);
                netTxTotalText = formatBytes(tx);
                netPrevRx = rx;
                netPrevTx = tx;
                netPrevTime = now;
            } else if (key === "CTEMP") {
                cpuTemp = value.length > 0 ? parseInt(value, 10) : -1;
            } else if (key === "GTEMP") {
                gpuTemp = value.length > 0 ? parseInt(value, 10) : -1;
            } else if (key === "GBUSY") {
                gpuUsage = value.length > 0 ? parseInt(value, 10) / 100 : -1;
            }
        }
    }
}
