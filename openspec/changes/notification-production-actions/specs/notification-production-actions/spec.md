## ADDED Requirements

### Requirement: Existing server remains the single live protocol owner
The desktop SHALL use the existing Quickshell notification server and shared store rather than a new daemon or duplicate lifetime owner. External publication, replacement, sender close, expiry and action invocation SHALL follow the installed upstream protocol semantics. The adapter SHALL normalize protocol expiry units at ingress, preserve explicit sticky timeout and urgency defaults, respect transient archive exclusion and DND policy, and advertise only implemented capabilities. Live protocol identifiers SHALL remain distinct from archive identity.

#### Scenario: Client publishes or replaces a notification
- **WHEN** an external client publishes a notification or replaces its current protocol ID
- **THEN** the shared store presents the current content and action set without creating a second notification owner or invoking a superseded action

#### Scenario: Client supplies an explicit lifetime
- **WHEN** an external client supplies zero, a positive timeout, or the protocol default timeout
- **THEN** the adapter preserves sticky, correctly normalized explicit expiry, or the existing urgency default respectively

#### Scenario: Notification closes through the protocol
- **WHEN** a sender closes a notification, the user dismisses it, or its lifetime expires
- **THEN** the upstream server reports the appropriate protocol close outcome and the store removes live action availability without a duplicate close

#### Scenario: Notification is transient or suppressed by DND
- **WHEN** a transient notification closes or a noncritical notification arrives under DND
- **THEN** transient content is excluded from the archive and noncritical popup display follows existing DND policy without misrepresenting the live source

### Requirement: Popup exposes only the live default action
The popup SHALL invoke only an action whose identifier is exactly `default`, and only from explicit pointer, accessibility or programmatic body activation, or Enter/Space when a focus-capable host grants keyboard focus. The shared card SHALL report one primary-activation intent, enabled only when its host provides the current default-action availability; these routes SHALL call its same listed action function. The desktop host SHALL resolve and invoke the live protocol action, at most once per activation. The production popup SHALL preserve its keyboard-passive window policy and SHALL NOT steal focus on arrival; the existing notification center remains the desktop keyboard route and the surface for explicitly choosing named actions. The popup SHALL NOT guess from named actions or show duplicate named-action buttons.

#### Scenario: Default action is provided
- **WHEN** a current live popup offers identifier `default` and the person clicks its body, or presses Enter/Space in a focus-capable host
- **THEN** the current protocol-backed action is invoked once through the shared action route

#### Scenario: Popup arrives while another application has keyboard focus
- **WHEN** a notification appears in the keyboard-passive production popup
- **THEN** the foreground application keeps keyboard focus and keyboard interaction remains available through the existing notification-center route

#### Scenario: No default action is provided
- **WHEN** a popup has no action with identifier `default`
- **THEN** body activation does not invoke another action and the body does not falsely present itself as actionable

#### Scenario: Programmatic activation uses the component action
- **WHEN** the host programmatically requests primary activation while a current default action is available
- **THEN** the shared card routes it through the same listed action function as pointer and keyboard activation

#### Scenario: A named action is selected in the center
- **WHEN** a person deliberately selects a named action in the notification center
- **THEN** that selected live action is invoked through the same service action seam

### Requirement: Action validity follows protocol lifetime
An action SHALL be resolved from the current live source when activated, not a cached action callback. Replacement SHALL use the replacement's current action set; expired, dismissed, closed, or retiring rows SHALL NOT invoke stale actions. The host SHALL honor upstream resident/nonresident invocation and close semantics without issuing a duplicate dismissal. Middle-click and completed swipe dismissal SHALL remain distinct from body activation.

#### Scenario: Live notification is replaced
- **WHEN** a notification is replaced with a new action set before activation
- **THEN** only the replacement's current `default` action can be invoked

#### Scenario: Notification is no longer actionable
- **WHEN** a row expires, is dismissed, is closed by its sender, or starts retiring before activation
- **THEN** it cannot invoke its former action

#### Scenario: Dismiss gesture completes
- **WHEN** a person middle-clicks a row or completes a dismissing swipe
- **THEN** the row is dismissed and no default action is invoked

#### Scenario: Swipe returns without dismissal
- **WHEN** a swipe remains below the dismissal threshold and springs back
- **THEN** the notification remains live and no default action is invoked

### Requirement: Useful provided message content is visible at rest
The resting popup SHALL show app identity using provided identity/icon data or an honest fallback, the provided summary, and a bounded readable preview of up to two body lines without requiring hover. Longer content SHALL remain readable through bounded expansion or scrolling and SHALL NOT make the stack grow without bound. The presentation SHALL NOT invent sender, channel, server, or other metadata absent from the client record. The new composition supersedes the previous one-line 36px collapsed-row acceptance; its dimensions SHALL come from the theme/component design decision, not hardcoded speculative measurements.

#### Scenario: Message has useful body text
- **WHEN** a live notification has a non-empty sanitized body
- **THEN** its resting popup shows a readable bounded body preview alongside app identity and summary

#### Scenario: Message is longer than the preview
- **WHEN** a live notification body exceeds the resting preview
- **THEN** the preview remains bounded and the person can read the remaining provided text through expansion or scrolling

#### Scenario: Client provides no body or structured author context
- **WHEN** the notification contains only app identity and summary, or no author/channel fields
- **THEN** the popup shows the available facts without fabricating body or Discord context

### Requirement: Text archive remains distinct from live protocol persistence
The bounded JSON archive SHALL preserve searchable app/title/body text but SHALL NOT claim protocol persistence or restore live notification IDs, action callbacks, or unacknowledged protocol objects after sender or shell loss. Archived rows SHALL remain inert for protocol actions; archive removal SHALL use archive identity rather than dismissing a missing live notification ID.

#### Scenario: Shell restarts with archived text
- **WHEN** the shell reloads its bounded JSON notification history
- **THEN** searchable text history may be restored but no live action or protocol notification is resurrected

#### Scenario: Archived record is removed
- **WHEN** the person removes an archived-only entry
- **THEN** only that archive record is removed and no protocol dismissal is sent with an absent live ID

### Requirement: Invocation and application activation are reported separately
The shell SHALL report an action as invoked only when the current client-provided action callback is actually invoked. It SHALL NOT claim that a target application or conversation opened solely from action invocation; focus/open success requires independent evidence and any activation mechanism supported by the installed protocol implementation.

#### Scenario: Client action callback is invoked
- **WHEN** a controlled external notification client supplies a default action and handles its callback
- **THEN** the observed result records exact-once action invocation separately from any application focus or conversation opening

#### Scenario: No supported activation token is available
- **WHEN** the installed Quickshell/protocol path does not provide a usable activation token
- **THEN** the shell makes no promise to focus or open the client's application target
