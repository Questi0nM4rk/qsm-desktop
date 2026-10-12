pragma Singleton
import QtQuick

QtObject {
    signal operated(string operation, string phase, var value)

    function open(role: string): bool {
        operated("delegate", "refused", { role: role, reason: "External applications are isolated in this preview" });
        return false;
    }
}
