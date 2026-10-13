## ADDED Requirements

### Requirement: Modal suppression is monitor-local
The desktop SHALL suppress discovery handles and dismiss rail popouts only
on the scene occupied by the global modal. One global modal remains the policy.

#### Scenario: Modal on one output
- **WHEN** the modal is shown on one normal workspace
- **THEN** another output's normal scene does not inherit its handle suppression

### Requirement: Keyboard claims carry owner and screen identity
A non-modal keyboard claim SHALL identify the actual owning surface and screen.
Only that scene SHALL receive exceptional focus/retention. Release by another
surface MUST NOT clear the claim; owner retirement or monitor departure SHALL
clear the prompt and secret.

#### Scenario: Password prompt and another monitor
- **WHEN** a prompt owns keyboard input and focus moves to another output
- **THEN** the obsolete prompt retires instead of granting keyboard focus or
  keeping unrelated popouts open on the newly focused scene

### Requirement: Hidden launcher work retires
Launcher cleanup SHALL follow its own host activation, not only the global
modal name. Retirement SHALL clear editor secrets, cancel its own read-only
work and prevent late callbacks from reopening/refocusing hidden content.
Accepted launch and clipboard-copy consequences MUST NOT be cancelled.

#### Scenario: Monitor migration with an editor or pending result
- **WHEN** the launcher's local host becomes inactive while the global modal
  remains launcher
- **THEN** that instance clears its editor and rejects obsolete focus/result work

### Requirement: Secret disposal does not depend on accepted submission
The launcher SHALL clear the supplied Wi-Fi password when handing it to the
backend, whether the backend accepts or rejects the operation.

#### Scenario: Backend refuses an operation start
- **WHEN** a password submission reaches a rejecting backend
- **THEN** the surface retains no supplied password and offers only truthful
  operation/error state without logging or persisting the secret
