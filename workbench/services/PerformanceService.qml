pragma Singleton
import QtQuick

QtObject {
    id: root
    property real cpuUsage: 0.23
    property real memUsed: 0.46
    property int cpuTemp: 52
    property real gpuUsage: 0.18
    property int gpuTemp: 45
    property string memText: "7.4 / 16.0 GiB"
    property real storageUsed: 0.38
    property string storageText: "182.4 / 480.0 GiB"
    property real netRxRate: 524288
    property real netTxRate: 24576
    property string netRxRateText: "512.0 KiB/s"
    property string netTxRateText: "24.0 KiB/s"
    property string netRxTotalText: "1.8 GiB"
    property string netTxTotalText: "126.0 MiB"
    property var netRxHistory: [180000, 310000, 250000, 420000, 350000, 524288]
    property var netTxHistory: [8000, 12000, 18000, 14000, 22000, 24576]
    property var detailedOwners: []
    readonly property bool polling: detailedOwners.length > 0
    function watch(name: string, enabled: bool): void {}
    function watchDetails(owner: var, enabled: bool): void {
        if (detailedOwners.includes(owner) === enabled) return;
        detailedOwners = enabled ? detailedOwners.concat([owner])
            : detailedOwners.filter(candidate => candidate !== owner);
    }

    function reset(): void {
        root.cpuUsage = 0.23;
        root.memUsed = 0.46;
        root.cpuTemp = 52;
        root.gpuUsage = 0.18;
        root.gpuTemp = 45;
        root.memText = "7.4 / 16.0 GiB";
        root.storageUsed = 0.38;
        root.storageText = "182.4 / 480.0 GiB";
        root.netRxRate = 524288;
        root.netTxRate = 24576;
        root.netRxRateText = "512.0 KiB/s";
        root.netTxRateText = "24.0 KiB/s";
        root.netRxTotalText = "1.8 GiB";
        root.netTxTotalText = "126.0 MiB";
        root.netRxHistory = [180000, 310000, 250000, 420000, 350000, 524288];
        root.netTxHistory = [8000, 12000, 18000, 14000, 22000, 24576];
    }
}
