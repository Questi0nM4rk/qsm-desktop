## ADDED Requirements

### Requirement: Session dialogs inherit qsm deep-night
The desktop session SHALL export `QT_QPA_PLATFORMTHEME=qt6ct` before Qt portal
processes launch. qt5ct, qt6ct, GTK3, and GTK4 user configuration SHALL map
qsm deep-night background, surface, text, accent, focus, and danger roles into
newly opened dialogs.

#### Scenario: Hyprland share picker starts
- **WHEN** a new Qt6 `hyprland-share-picker` process starts from the portal
- **THEN** it MUST inherit qt6ct and use the qsm deep-night palette rather than
  a white Fusion fallback

#### Scenario: GTK authentication dialog starts
- **WHEN** a new GTK authentication or standard dialog starts
- **THEN** it MUST use qsm dark background, accent focus, and raised controls

### Requirement: Dialog bridge activation is non-disruptive
Applying a bridge update SHALL reload Hyprland configuration and restart only
the portal backends that need the new environment. It MUST NOT restart
Quickshell or unrelated applications.

#### Scenario: Bridge update completes
- **WHEN** the active dialog bridge configuration changes
- **THEN** new portal dialogs MUST receive the new environment while existing
  third-party dialogs remain untouched until reopened
