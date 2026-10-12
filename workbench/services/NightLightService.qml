pragma Singleton

import QtQuick

QtObject {
    readonly property int neutralTemperature: 6000
    readonly property int warmestTemperature: 2500
    property int temperature: 4200
    property bool active: false
    readonly property real strength: (neutralTemperature - temperature)
        / (neutralTemperature - warmestTemperature)

    function refresh(): void {}
    function toggle(): void { active = !active; }
    function reset(): void {
        active = false;
        temperature = 4200;
    }
    function setStrength(value: real): void {
        const clamped = Math.max(0, Math.min(1, value));
        temperature = Math.round(neutralTemperature
            - clamped * (neutralTemperature - warmestTemperature));
        active = true;
    }
}
