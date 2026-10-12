pragma Singleton

import QtQuick

QtObject {
    property bool available: true
    property bool initialized: true
    property bool reconciling: false
    property real value: 0.72
    property real restoreValue: 0.72

    signal operated(string operation, string phase, var value)

    function setValue(nextValue: real): void {
        if (!available)
            return;
        value = Math.max(0.01, Math.min(1, nextValue));
        operated("brightness-level", "completed", value);
    }

    function reset(): void {
        available = true;
        initialized = true;
        reconciling = false;
        value = 0.72;
        restoreValue = 0.72;
    }

    function toggle(): void {
        if (!available) return;
        if (value > 0.01) { restoreValue = value; setValue(0.01); }
        else setValue(restoreValue);
    }
}
