# plugEvents

![example workflow](https://github.com/autosysops/PowerShell_plugEvents/actions/workflows/build.yml/badge.svg)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/plugEvents.svg)](https://www.powershellgallery.com/packages/plugEvents/)

PowerShell module to interact with [Plug.Events](https://plug.events) — a platform for community events focused on folk dance and music.

## Installation

You can install the module from the [PSGallery](https://www.powershellgallery.com/packages/plugEvents) by using the following command.

```PowerShell
Install-Module -Name PlugEvents
```

Or if you are using PowerShell 7.4 or higher you can use:

```PowerShell
Install-PSResource -Name PlugEvents
```

## Usage

### Import the module

```PowerShell
Import-Module -Name PlugEvents
```

On first import you will receive a message about telemetry being enabled (see [Telemetry](#telemetry) below).

---

### Connecting and disconnecting

All data functions communicate over a persistent WebSocket connection to the Plug.Events back-end. You must connect before calling any data functions, and disconnect when you are done.

**Connect anonymously:**

```PowerShell
Connect-PlugEvents
```

`Connect-PlugEvents` automatically resolves the production endpoint and connection token, opens a WebSocket session, and performs the SignalR JSON handshake. You can supply a custom endpoint or token if needed:

```PowerShell
Connect-PlugEvents -Endpoint "eu1.plug.events" -ConnectionToken "your-token"
```

**Connect with a Plug.Events account:**

Pass a `PSCredential` object (username = email address, password = account password) to authenticate after the WebSocket handshake. The password is sent in plain text over the WebSocket, which is itself secured by TLS (`wss://`). You will be prompted to confirm this before the password is transmitted.

```PowerShell
$cred = Get-Credential          # enter your Plug.Events email and password
Connect-PlugEvents -Credential $cred
```

For unattended scripts, add `-SkipWarning` to suppress the confirmation prompt:

```PowerShell
$cred = Get-Credential
Connect-PlugEvents -Credential $cred -SkipWarning
```

If authentication fails (wrong email or password) the connection is closed automatically and a descriptive error is thrown.

**Disconnect:**

```PowerShell
Disconnect-PlugEvents
```

This closes the WebSocket gracefully and disposes of the underlying connection objects.

---

### Retrieving an organization view

`Get-PlugEventsOrgView` returns the full profile for a single organization or person by their slug. The slug is the URL-friendly identifier used in Plug.Events URLs (e.g. `https://plug.events/leo-visser` → slug `leo-visser`).

```PowerShell
Connect-PlugEvents

$org = Get-PlugEventsOrgView -Id "balfolk-nl"

# Access specific fields on the result
$org.capitalScalar.name
$org.capitalScalar.description
$org.smLinks          # social media links
$org.bannerImageUrl
```

The returned object mirrors the `result` property of the WebSocket response and contains fields such as `capitalScalar`, `orgScalar`, `brands`, `capitalExtra`, `smLinks`, and image URLs.

---

### Searching for organizations

`Get-PlugEventsOrg` searches across all organizations and returns a list of matching items. Useful for discovering organizations by name, interest, or location.

```PowerShell
Connect-PlugEvents

# Find all organizations tagged with the "balfolk" interest
$orgs = Get-PlugEventsOrg -Interest "balfolk" -Top 50

# Search by name
$orgs = Get-PlugEventsOrg -Filter "folk" -Top 20

# Combine filters
$orgs = Get-PlugEventsOrg -Filter "dance" -Interest "balfolk" -Locale "netherlands" -Top 100

$orgs | Select-Object name, slug
```

Parameters:

| Parameter | Description | Required |
|---|---|---|
| `-Filter` | Free-text search term | No |
| `-Interest` | Interest category slug (e.g. `balfolk`, `dance`) | No |
| `-SubInterest` | Sub-interest slug | No |
| `-Locale` | Locale slug (e.g. `netherlands`) | No |
| `-Top` | Maximum number of results (default: 999) | No |

---

### Retrieving events under an umbrella organization

`Get-PlugEventsUmbrellaEvent` returns all events that are published under a specific umbrella organization, optionally filtered by date range.

```PowerShell
Connect-PlugEvents

# Get all BalfolkNL events in 2025
$events = Get-PlugEventsUmbrellaEvent -Id "balfolk-nl" `
              -StartDate (Get-Date "2025-01-01") `
              -EndDate   (Get-Date "2025-12-31")

$events | Select-Object title, startTime, slug

# Get upcoming events (default window is the last 30 days up to today)
$events = Get-PlugEventsUmbrellaEvent -Id "balfolk-nl"
```

Parameters:

| Parameter | Description | Required |
|---|---|---|
| `-Id` | Slug of the umbrella organization | Yes |
| `-StartDate` | Start of the date window (default: 30 days ago) | No |
| `-EndDate` | End of the date window (default: today) | No |
| `-Top` | Maximum number of results (default: 999) | No |

---

### Retrieving an event view

`Get-PlugEventsEventView` returns the full details for a single event by its slug. The slug is the URL-friendly identifier found in Plug.Events event URLs.

```PowerShell
Connect-PlugEvents

$event = Get-PlugEventsEventView -Id "my-event-2026"

# Access fields on the result
$event.eventScalar.name
$event.eventScalar.description
$event.startTime
$event.venue
```

---

### Adding members to an organization

`Add-PlugEventsOrgMember` adds an organization to another organization with a specified role. **This function requires an authenticated connection** — connect using `Connect-PlugEvents -Credential` before calling it.

```PowerShell
$cred = Get-Credential
Connect-PlugEvents -Credential $cred

# Add "yourorg" to "balfolk-nl" with the role "teacher"
Add-PlugEventsOrgMember -Id "balfolk-nl" -Role "teacher" -Org "yourorg"
```

Parameters:

| Parameter | Description | Required | Parameter set |
|---|---|---|---|
| `-Id` | Slug of the organization to add the member to | Yes | All |
| `-Role` | Role the added organization will receive (e.g. `teacher`, `performer`) | Yes | All |
| `-Org` | Slug of the organization to add as a member | Yes | `Org` (default) |

If you call this function without being authenticated, it throws an error immediately without sending any request.

---

### Sending and receiving messages manually

For advanced use cases you can send arbitrary SignalR messages directly over the open WebSocket connection.

**Send a message:**

```PowerShell
$message = '{"target":"GetLocalesBySlug","arguments":[["netherlands"]],"invocationId":"1","type":1}'
Send-PlugEventsMessage -Message $message
```

The end-of-message marker (`0x1e`) is appended automatically if missing. Use `-Async` to fire-and-forget without waiting for send confirmation. The `-Timeout` parameter (default: 5 seconds) controls how long to wait for the send to complete.

**Receive a response:**

```PowerShell
$raw = Receive-PlugEventsMessage -Timeout 30 -IgnoreKeepAlive
$data = $raw | ConvertFrom-Json
```

`-IgnoreKeepAlive` skips keep-alive pings and blocks until a real data message arrives. The raw return value is a JSON string; use `ConvertFrom-Json` to work with the object.

**Full manual example:**

```PowerShell
Connect-PlugEvents

Send-PlugEventsMessage -Message '{"target":"GetLocalesBySlug","arguments":[["netherlands"]],"invocationId":"1","type":1}'
$response = Receive-PlugEventsMessage -Timeout 30 -IgnoreKeepAlive
($response | ConvertFrom-Json).result

Disconnect-PlugEvents
```

---

### Full end-to-end example

```PowerShell
Import-Module -Name PlugEvents

Connect-PlugEvents

# Look up an organization profile
$org = Get-PlugEventsOrgView -Id "balfolk-nl"
Write-Host "Organization: $($org.capitalScalar.name)"
Write-Host "Description:  $($org.capitalScalar.description)"

# List its upcoming events
$events = Get-PlugEventsUmbrellaEvent -Id "balfolk-nl" `
              -StartDate (Get-Date) `
              -EndDate   (Get-Date).AddMonths(3) `
              -Top 10

$events | ForEach-Object { Write-Host "$($_.title) — $($_.startTime)" }

Disconnect-PlugEvents
```

---

## Telemetry

This module collects anonymous usage telemetry (function names and non-identifiable parameter metadata) via the [TelemetryHelper module](https://github.com/nyanhp/TelemetryHelper). No personal data or parameter values are transmitted. You can opt out by following the instructions shown on first import.

## Credits

The module is using the [Telemetryhelper module](https://github.com/nyanhp/TelemetryHelper) to gather telemetry.
The module is made using the [PSModuleDevelopment module](https://github.com/PowershellFrameworkCollective/PSModuleDevelopment) to get a template for a module.
