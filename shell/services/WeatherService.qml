pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.state

// wttr.in weather for the dashboard (06 DEFAULT): cached 30 minutes,
// location string from persistence (empty = IP-based), `available` false
// while offline or unfetched — the dashboard block hides then. A visual test
// run (DRIVE_FIXTURES, a directory) reads a recorded answer from weather.json.
QtObject {
    id: root

    readonly property string fixtures: Quickshell.env("DRIVE_FIXTURES") ?? ""

    property bool available: false
    property string temperature: ""
    property string description: ""
    property string code: ""
    property string feelsLike: ""
    property double fetchedAt: 0

    function refresh(): void {
        if (Date.now() - fetchedAt < 30 * 60 * 1000)
            return;
        // A fixture run reads its answer once, through fixtureFile.
        if (root.fixtures.length > 0)
            return;

        const location = encodeURIComponent(ShellState.weatherLocation ?? "");
        const request = new XMLHttpRequest();
        request.onreadystatechange = () => {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;

            if (request.status !== 200) {
                available = false;
                return;
            }
            root.apply(request.responseText);
        };
        request.open("GET", `https://wttr.in/${location}?format=j1`);
        request.send();
    }

    function apply(text: string): void {
        try {
            const current = JSON.parse(text).current_condition[0];
            temperature = `${current.temp_C}°`;
            feelsLike = `feels ${current.FeelsLikeC}°`;
            description = current.weatherDesc?.[0]?.value ?? "";
            code = String(current.weatherCode ?? "");
            fetchedAt = Date.now();
            available = true;
        } catch (error) {
            available = false;
        }
    }

    property FileView fixtureFile: FileView {
        path: root.fixtures.length > 0 ? `${root.fixtures}/weather.json` : ""
        onLoaded: root.apply(text())
        onLoadFailed: console.error(`WeatherService: no fixture at ${path}`)
    }
}
