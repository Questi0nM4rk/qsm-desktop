pragma Singleton

import QtQuick
import Quickshell.Io
import qs.state

// wttr.in weather for the dashboard (06 DEFAULT): cached 30 minutes,
// location string from persistence (empty = IP-based), `available` false
// while offline or unfetched — the dashboard block hides then. Fetched by
// `curl`, which a visual test run answers with a recorded wttr.in answer.
QtObject {
    id: root

    property bool available: false
    property string temperature: ""
    property string description: ""
    property string code: ""
    property string feelsLike: ""
    property double fetchedAt: 0

    function refresh(): void {
        if (Date.now() - fetchedAt < 30 * 60 * 1000)
            return;
        const location = encodeURIComponent(ShellState.weatherLocation ?? "");
        fetch.command = ["curl", "-sf", "--max-time", "10", `https://wttr.in/${location}?format=j1`];
        fetch.running = true;
    }

    // A failed fetch leaves stdout empty, so the parse fails and `available`
    // drops: one path for offline, an HTTP error and a broken answer.
    property Process fetch: Process {
        stdout: StdioCollector {
            onStreamFinished: root.apply(text)
        }
    }

    function apply(answer: string): void {
        try {
            const current = JSON.parse(answer).current_condition[0];
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
}
