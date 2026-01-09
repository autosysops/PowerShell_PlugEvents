# plugEvents

![example workflow](https://github.com/autosysops/PowerShell_plugEvents/actions/workflows/build.yml/badge.svg)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/plugEvents.svg)](https://www.powershellgallery.com/packages/plugEvents/)

PowerShell module to interact with Plug.Events

## Installation

You can install the module from the [PSGallery](https://www.powershellgallery.com/packages/plugEvents) by using the following command.

```PowerShell
Install-Module -Name PlugEvents
```

Or if you are using PowerShell 7.4 or higher you can use

```PowerShell
Install-PSResource -Name PlugEvents
```

## Usage

To use the module first import it.

```PowerShell
Import-Module -Name PlugEvents
```

You will receive a message about telemetry being enabled. After that you can use the command `Connect-PlugEvents` to use the module.

Check out the Get-Help for more information on how to use the function.

## Credits

The module is using the [Telemetryhelper module](https://github.com/nyanhp/TelemetryHelper) to gather telemetry.
The module is made using the [PSModuleDevelopment module](https://github.com/PowershellFrameworkCollective/PSModuleDevelopment) to get a template for a module.
