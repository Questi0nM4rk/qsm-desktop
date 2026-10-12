pragma Singleton
import QtQuick

QtObject {
    property real cpuUsage: 0.23
    property real memUsed: 0.46
    function watch(name: string, enabled: bool): void {}
}
