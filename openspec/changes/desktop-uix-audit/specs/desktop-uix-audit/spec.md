## ADDED Requirements

### Requirement: Every desktop surface has an audited record

The desktop SHALL hold one record per surface covering purpose and consequence, supported states,
controls, the real pointer, keyboard, wheel, focus and accessibility routes, input geometry with
hitbox and pointer-path mathematics, motion and its reduced-motion form, and findings separated
into source-backed defects, redesign proposals, source conflicts and hypotheses. A surface with
no pointer action SHALL say so and SHALL still be reviewed.

#### Scenario: A surface is reachable only by hover

- **WHEN** a rail entry opens its popout on hover
+- **THEN** the record SHALL name the hover zone, the trigger, the panel and the corridor between
+  them, SHALL state the closing delay, and SHALL show the click and keyboard route as well
+
+#### Scenario: A glyph surface is captured off-screen
+
+- **WHEN** a capture of a glyph-bearing surface is empty
+- **THEN** the record SHALL name the off-screen rasterisation limit and SHALL mark the visual
+  finding as needing a real window, rather than filing it as a missing control
+
+### Requirement: Pointer acquisition is computed, never assumed

+Each interactive target SHALL record the input shape apart from the painted size, the
+representative origins, the distance and the width along the approach direction, the difficulty
+in bits, the landing tolerance, the interfering neighbours, and for hover surfaces the
+trigger-to-panel travel. Model assumptions and weights SHALL be labelled, and no human average
+movement time, miss rate or probability SHALL be published without real user data.
+
+#### Scenario: Two controls sit close on the rail
+
+- **WHEN** two rail entries are closer than the pointer's approach tolerance
+- **THEN** the record SHALL give both hit shapes, the gap in logical pixels, the resulting
+  difficulty per approach, and a finding naming the mis-click risk
+
+### Requirement: Evidence is stated per surface and state
+
+Each record and the coverage SHALL separate source-reviewed, runtime-exercised and
+owner-accepted. Runtime findings SHALL cite the exercised state and its artefact. Routes that
+need a real window, a physical device or a screen reader SHALL be named as untested with the
+exact steps and the pass criterion.
+
+#### Scenario: A surface was only read in the source
+
+- **WHEN** a surface's behaviour was traced in the code but never driven
+- **THEN** the record SHALL mark it source-reviewed and untested, and SHALL NOT list it as
+  passing
+
+### Requirement: The audit precedes owner-led repairs
+
+The complete surface audit SHALL be delivered before any desktop surface is repaired. The repair
+order SHALL be chosen with the owner. Repairs SHALL happen one surface at a time with owner
+acceptance, each in its own scoped change, and each accepted decision SHALL be written into the
+existing spec in the same move, citing the owner. Production SHALL NOT be restarted, no service
+SHALL be mutated and no desktop input SHALL be injected without the owner's explicit go.
+
+#### Scenario: An audit finding contradicts an existing spec line
+
+- **WHEN** a measured finding conflicts with a line in the desktop spec
+- **THEN** the finding SHALL be filed as a source conflict and SHALL NOT change the spec until
+  the owner rules on it
