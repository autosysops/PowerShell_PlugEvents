# ===================================================================
# ================== WEBSOCKET ======================================
# ===================================================================

# Create env variables
$Script:websocket = [System.Net.WebSockets.ClientWebSocket]::new()
$Script:cancellationToken = [System.Threading.CancellationTokenSource]::new()

# ===================================================================
# ================== TELEMETRY ======================================
# ===================================================================

# Create env variables
$Env:PLUGEVENTS_TELEMETRY_OPTIN = (-not $Evn:POWERSHELL_TELEMETRY_OPTOUT) # use the invert of default powershell telemetry setting

# Set up the telemetry
Initialize-THTelemetry -ModuleName "plugEvents"
Set-THTelemetryConfiguration -ModuleName "plugEvents" -OptInVariableName "PLUGEVENTS_TELEMETRY_OPTIN" -StripPersonallyIdentifiableInformation $true -Confirm:$false
Add-THAppInsightsConnectionString -ModuleName "plugEvents" -ConnectionString "InstrumentationKey=df9757a1-873b-41c6-b4a2-2b93d15c9fb1;IngestionEndpoint=https://westeurope-5.in.applicationinsights.azure.com/;LiveEndpoint=https://westeurope.livediagnostics.monitor.azure.com/"

# Create a message about the telemetry
Write-Information ("Telemetry for plugEvents module is $(if([string] $Env:PLUGEVENTS_TELEMETRY_OPTIN -in ("no","false","0")){"NOT "})enabled. Change the behavior by setting the value of " + '$Env:PLUGEVENTS_TELEMETRY_OPTIN') -InformationAction Continue

# Send a metric for the installation of the module
Send-THEvent -ModuleName "plugEvents" -EventName "Import Module plugEvents"