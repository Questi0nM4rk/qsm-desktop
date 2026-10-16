import QtQuick

// Desktop-owned notification policy and lifetime, independent of the bus and
// persistence transport. Production and Workbench instantiate this same type.
QtObject {
    id: root

    readonly property int popupLimit: 5
    readonly property int defaultTimeoutMs: 5000
    readonly property int bodyByteLimit: 16384
    readonly property int archiveRecordLimit: 200
    readonly property int archiveByteLimit: 16 * 1024 * 1024

    property bool dnd: false
    property var history: []
    property var live: []
    property int nextId: 1
    property var closeSource: null
    property var invokeSourceAction: null

    readonly property var popups: live
        .filter(entry => !dnd || entry.urgency === "critical")
        .slice(0, popupLimit)
        .map(entry => entry.presentationRecord)
    readonly property var archive: (history ?? []).filter(record => root.isValidRecord(record))
    // Unread = archived without the person having touched it: an expired
    // popup. A dismissed one, or one whose action ran, was seen.
    readonly property int unreadCount: archive.filter(record => record.read === false).length
    readonly property var urgencyNames: ["low", "normal", "critical"]

    signal notifyRejected(string field, string message)
    signal publication(int notificationId, string operation)

    property Component entryComponent: Component { NotificationEntry {} }

    function copyActions(actions: var): var {
        if (!Array.isArray(actions))
            return [];
        return actions.map(action => root.copyRecord(action));
    }

    function copyRecord(record: var): var {
        const copy = ({});
        for (const key of Object.keys(record ?? {}))
            copy[key] = record[key];
        return copy;
    }

    function sanitize(raw: var): string {
        const capped = String(raw ?? "").slice(0, bodyByteLimit);
        return capped
            .replace(/<(?!\/?(b|i|u|br)\b)[^<>]*>/gi, "")
            .replace(/<(\/?)(b|i|u|br)\b[^<>]*>/gi, "<$1$2>");
    }

    function resolveExpiry(urgency: string, timeoutMs: int): int {
        if (timeoutMs > 0)
            return timeoutMs;
        if (urgency === "critical")
            return -1;
        return urgency === "low" ? 3000 : defaultTimeoutMs;
    }

    function notify(summary: var, options: var): int {
        if (typeof summary !== "string" || summary.length === 0)
            return reject("summary", "must be a non-empty string");
        const supplied = options ?? ({});
        if (typeof supplied !== "object" || Array.isArray(supplied))
            return reject("options", "must be a named options object");
        const allowed = ["appName", "body", "urgency", "imagePath", "timeoutMs", "isTransient", "replaceId"];
        for (const key of Object.keys(supplied))
            if (!allowed.includes(key))
                return reject(key, "is not a supported notification option");
        const urgency = supplied.urgency ?? "normal";
        if (!urgencyNames.includes(urgency))
            return reject("urgency", "must be low, normal, or critical");
        for (const key of ["appName", "body", "imagePath"])
            if (supplied[key] !== undefined && typeof supplied[key] !== "string")
                return reject(key, "must be a string");
        if (supplied.timeoutMs !== undefined
                && (!Number.isInteger(supplied.timeoutMs) || supplied.timeoutMs < 0))
            return reject("timeoutMs", "must be a non-negative integer");
        if (supplied.isTransient !== undefined && typeof supplied.isTransient !== "boolean")
            return reject("isTransient", "must be a boolean");
        if (supplied.replaceId !== undefined
                && (!Number.isInteger(supplied.replaceId) || supplied.replaceId <= 0))
            return reject("replaceId", "must be a positive notification ID");

        const timeoutMs = supplied.timeoutMs;
        const expiryMs = timeoutMs === undefined ? resolveExpiry(urgency, 0)
            : timeoutMs === 0 ? 0 : resolveExpiry(urgency, timeoutMs);
        return publish({
            appName: supplied.appName ?? "qsm-desktop",
            summary: summary.slice(0, 1024),
            body: sanitize(supplied.body ?? ""),
            urgency: urgency,
            imagePath: supplied.imagePath ?? "",
            actions: [],
            isTransient: supplied.isTransient ?? false,
            expiryMs: expiryMs
        }, supplied.replaceId ?? 0);
    }

    function post(appName: string, summary: string, body: string,
            urgency: string, timeoutMs: int, replaceId: int, isTransient: bool): int {
        const normalized = urgencyNames.includes(urgency) ? urgency : "normal";
        return publish({
            appName: appName || "qsm-desktop",
            summary: String(summary ?? "").slice(0, 1024),
            body: sanitize(body),
            urgency: normalized,
            imagePath: "",
            actions: [],
            isTransient: isTransient,
            expiryMs: resolveExpiry(normalized, timeoutMs)
        }, replaceId);
    }

    function reject(field: string, message: string): int {
        notifyRejected(field, message);
        return 0;
    }

    function publish(record: var, replaceId: int): int {
        const existing = replaceId > 0
            ? live.find(entry => entry.notificationId === replaceId) : null;
        if (existing) {
            const next = copyRecord(record);
            next.notificationId = existing.notificationId;
            next.createdAt = existing.createdAt;
            next.paused = existing.paused;
            existing.commit(next);
            publication(existing.notificationId, "replaced");
            return existing.notificationId;
        }
        const notificationId = nextId++;
        const initial = copyRecord(record);
        initial.notificationId = notificationId;
        initial.createdAt = Date.now();
        initial.paused = false;
        initial.actions = copyActions(record.actions);
        const entry = entryComponent.createObject(root, { notificationId, data: initial,
            invokeActionCallback: (id, actionId) => root.invokeAction(id, actionId) }) as NotificationEntry;
        entry.expired.connect(id => root.close(id, "expired"));
        live = [entry].concat(live);
        publication(notificationId, "posted");
        return notificationId;
    }

    // Called by the production protocol bridge with a fully normalized,
    // source-free record. Existing identity, timestamp and paused state remain.
    function syncSource(notificationId: int, record: var): bool {
        const entry = live.find(candidate => candidate.notificationId === notificationId);
        if (!entry)
            return false;
        const next = copyRecord(record);
        next.actions = copyActions(record.actions);
        next.notificationId = notificationId;
        next.createdAt = entry.createdAt;
        next.paused = entry.paused;
        entry.commit(next);
        publication(notificationId, "replaced");
        return true;
    }

    function addSource(record: var): int {
        const notificationId = nextId++;
        const initial = copyRecord(record);
        initial.notificationId = notificationId;
        initial.createdAt = Date.now();
        initial.paused = false;
        initial.actions = copyActions(record.actions);
        const entry = entryComponent.createObject(root, { notificationId, data: initial,
            invokeActionCallback: (id, actionId) => root.invokeAction(id, actionId) }) as NotificationEntry;
        entry.expired.connect(id => root.close(id, "expired"));
        live = [entry].concat(live);
        publication(notificationId, "posted");
        return notificationId;
    }

    function setPaused(notificationId: int, paused: bool): void {
        const entry = live.find(candidate => candidate.notificationId === notificationId);
        if (entry && entry.paused !== paused) {
            entry.setPaused(paused);
            publication(notificationId, paused ? "paused" : "resumed");
        }
    }

    function invokeAction(notificationId: int, actionId: string): bool {
        const entry = live.find(candidate => candidate.notificationId === notificationId);
        if (!entry || !actionId || !entry.actions.some(
                action => String(action.id) === actionId && !(action.disabled ?? false)))
            return false;
        return !!invokeSourceAction && invokeSourceAction(notificationId, actionId) === true;
    }

    function invokeDefault(notificationId: int): bool {
        return root.invokeAction(notificationId, "default");
    }

    function dismiss(notificationId: int): bool { return close(notificationId, "dismissed"); }

    function dismissAll(): bool {
        const entries = live;
        if (entries.length === 0)
            return false;
        // Withdraw the whole window once, so its complete last body can retract.
        live = [];
        for (const entry of entries)
            retire(entry, "dismissed");
        return true;
    }

    function close(notificationId: int, reason: string): bool {
        const entry = live.find(candidate => candidate.notificationId === notificationId);
        if (!entry)
            return false;
        live = live.filter(candidate => candidate.notificationId !== notificationId);
        retire(entry, reason);
        return true;
    }

    function retire(entry: var, reason: string): void {
        const notificationId = entry.notificationId;
        if (!entry.isTransient)
            archiveRecord(entry, reason);
        entry.expiryTimer.stop();
        entry.destroy();
        if (reason !== "closed" && closeSource)
            closeSource(notificationId, reason);
        publication(notificationId, reason);
    }

    function clearArchive(): void { history = []; }

    function removeArchived(record: var): bool {
        if (!isValidRecord(record)) return false;
        const index = history.findIndex(candidate => record.archiveId
            ? candidate.archiveId === record.archiveId
            : candidate.archivedAt === record.archivedAt && candidate.appName === record.appName
                && candidate.summary === record.summary && candidate.body === record.body
                && candidate.urgency === record.urgency);
        if (index < 0) return false;
        history = history.filter((candidate, at) => at !== index);
        return true;
    }

    function markRead(record: var): bool {
        if (!isValidRecord(record) || !record.archiveId) return false;
        const index = history.findIndex(candidate => candidate.archiveId === record.archiveId);
        if (index < 0 || history[index].read !== false) return false;
        history = history.map((candidate, at) => at === index
            ? Object.assign({}, candidate, { read: true }) : candidate);
        return true;
    }

    function markAllRead(): bool {
        if (unreadCount === 0) return false;
        history = history.map(candidate => candidate.read === false
            ? Object.assign({}, candidate, { read: true }) : candidate);
        return true;
    }

    function archiveRecord(entry: var, reason: string): void {
        const now = Date.now();
        const record = { archiveId: `${now}-${entry.notificationId}`, archivedAt: now, appName: entry.appName,
            summary: entry.summary, body: entry.body, urgency: entry.urgency,
            read: reason !== "expired" };
        let records = [record].concat(history ?? []);
        if (records.length > archiveRecordLimit)
            records = records.slice(0, archiveRecordLimit);
        while (records.length > 1 && JSON.stringify(records).length > archiveByteLimit)
            records = records.slice(0, records.length - 1);
        history = records;
    }

    function isValidRecord(record: var): bool {
        return record && typeof record.summary === "string"
            && typeof record.appName === "string" && typeof record.body === "string"
            && typeof record.urgency === "string" && typeof record.archivedAt === "number";
    }

    function reset(): void {
        const entries = live;
        live = [];
        for (const entry of entries) {
            entry.expiryTimer.stop();
            entry.destroy();
        }
        history = [];
        nextId = 1;
    }
}
