pragma Singleton

import QtQuick

QtObject {
    property bool fullscreen: false

    function fullscreenFor(screen: var): bool { return fullscreen; }
    function reset(): void { fullscreen = false; }
}
