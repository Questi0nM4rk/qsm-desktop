## ADDED Requirements

### Requirement: One network status, the most important first

The desktop SHALL publish one network status, the first that holds in this order: `unavailable`
(NetworkManager does not answer), `portal`, `offline` (a link is up and NetworkManager reports a
captive portal, or no or limited Internet), `connecting`, `ethernet`, `wifi`, `idle` (no link,
the radio on or no Wi-Fi device), `radio-off` (no link, the radio off). An unknown connectivity
SHALL NOT make a status `portal` or `offline`.

#### Scenario: a portal outranks the Wi-Fi it is on

- **WHEN** Wi-Fi is connected and NetworkManager reports connectivity `portal`
- **THEN** the status is `portal`

#### Scenario: no Internet without a link is not a problem status

- **WHEN** the radio is off, no device is connected and connectivity is `none`
- **THEN** the status is `radio-off`

#### Scenario: a stopped NetworkManager forgets the last link

- **WHEN** Wi-Fi was connected and the device read then fails
- **THEN** the status is `unavailable` and no link is reported up

### Requirement: The status draws its own glyph

The rail's network cell and the launcher's network entry SHALL draw the status's glyph:
`unavailable` and `idle` `network`, `portal` `circle-alert`, `offline` `alert-triangle`,
`connecting` `link`, `ethernet` `cable`, `wifi` `wifi` at a signal of 55 or more and `wifi-low`
below it, `radio-off` `wifi-off`.

#### Scenario: every status reads apart on the rail

- **WHEN** the atlas shoots the rail in each of the seven fake-machine states
- **THEN** no two states share a glyph and colour, except `unavailable` and `idle`, which share
  the muted `network` glyph and differ in the popout's reason line

### Requirement: A status without a connection is muted, and connecting pulses

The rail SHALL draw `unavailable`, `idle` and `radio-off` in the muted text colour and every
other status in the text colour. The `connecting` glyph SHALL pulse, slower under reduced motion.

#### Scenario: connecting pulses on the rail

- **WHEN** the status is `connecting`
- **THEN** the rail's `link` glyph changes opacity in a loop, and with reduced motion the loop's
  period is twice as long

### Requirement: A changed status notifies once it holds

When the status changes, the desktop SHALL send one notification after the new status has held
for 3 seconds. `connecting` SHALL never notify, and the status a session first settles in SHALL
NOT notify. A move from one network to another SHALL notify.

#### Scenario: a status that flips back does not notify

- **WHEN** Wi-Fi drops and returns within 3 seconds
- **THEN** no notification is sent

#### Scenario: losing the Internet notifies once

- **WHEN** a connected Wi-Fi's connectivity turns `none` and stays
- **THEN** one notification arrives about 3 seconds later, and no second one follows while it
  stays

#### Scenario: connecting then connected notifies the result only

- **WHEN** an ethernet device goes from connecting to connected
- **THEN** one notification names the wired connection, and none was sent for connecting

### Requirement: A notification names the result

A network notification SHALL name the result: the network joined, the cable connected, the link
lost, the radio off, no Internet, a sign-in needed, or NetworkManager stopped. A Wi-Fi or
ethernet result SHALL name its connection. A problem SHALL be a normal notification and a
connection a low one.

#### Scenario: no Internet says which connection has none

- **WHEN** the status settles on `offline` while Wi-Fi "Dusk Loft" is connected
- **THEN** the notification reads "No Internet connection" and names "Dusk Loft", at normal
  urgency

### Requirement: A change is seen as it happens

The desktop SHALL learn of a NetworkManager change from NetworkManager's own change stream,
within a second, and SHALL read the Wi-Fi signal at least every 10 seconds. A change stream that
ends SHALL be started again.

#### Scenario: the rail follows a dropped cable at once

- **WHEN** the connected ethernet device turns `unavailable` in the fake machine
- **THEN** the rail draws the next status's glyph within a second, not at the next poll

### Requirement: The popout names the problem

The network popout SHALL state the reason for an `unavailable`, `portal`, `offline` or
`radio-off` status in its reason line, and SHALL NOT state that the radio is off when
NetworkManager is not running.

#### Scenario: a stopped NetworkManager says so

- **WHEN** the status is `unavailable`
- **THEN** the popout says NetworkManager is not running, and its Wi-Fi capsule is disabled
