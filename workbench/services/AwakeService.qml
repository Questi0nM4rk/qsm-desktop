pragma Singleton

import QtQuick

QtObject {
    property bool awake: false

    function refresh(): void {}
    function toggle(): void { awake = !awake; }
    function reset(): void { awake = false; }
}
