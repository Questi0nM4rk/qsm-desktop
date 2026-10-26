pragma Singleton

import QtQuick
import qs.state

// wttr.in weather for the dashboard (06 DEFAULT): cached 30 minutes,
// location string from persistence (empty = IP-based), `available` false
// while offline or unfetched — the dashboard block hides then. The mock
// record `weather` (Mock), a recorded wttr.in answer, stands in for the fetch.
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
        if (Mock.records.weather) {
            root.apply(Mock.records.weather);
            return;
        }

        const location = encodeURIComponent(ShellState.weatherLocation ?? "");
        const request = new XMLHttpRequest();
        request.onreadystatechange = () => {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;

            if (request.status !== 200) {
                available = false;
                return;
            }
            try {
                root.apply(JSON.parse(request.responseText));
            } catch (error) {
                available = false;
            }
        };
        request.open("GET", `https://wttr.in/${location}?format=j1`);
        request.send();
    }

    function apply(answer: var): void {
        try {
            const current = answer.current_condition[0];
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
