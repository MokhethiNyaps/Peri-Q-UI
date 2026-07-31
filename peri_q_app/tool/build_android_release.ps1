param(
    [ValidateSet('apk', 'appbundle', 'all')]
    [string]$Target = 'all'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$releaseConfigPath = Join-Path $projectRoot 'release-config.json'
$signingConfigPath = Join-Path $projectRoot 'android\key.properties'
$symbolsPath = Join-Path $projectRoot 'release\android\symbols-v1.0.1-build2-order-details'

if (-not (Test-Path -LiteralPath $releaseConfigPath)) {
    throw "Missing ignored release configuration: $releaseConfigPath"
}
if (-not (Test-Path -LiteralPath $signingConfigPath)) {
    throw "Missing ignored Android signing configuration: $signingConfigPath"
}

$releaseConfig = Get-Content -Raw -LiteralPath $releaseConfigPath |
    ConvertFrom-Json
$supabaseUrl = [string]$releaseConfig.SUPABASE_URL
$supabasePublishableKey = [string]$releaseConfig.SUPABASE_PUBLISHABLE_KEY

if ([string]::IsNullOrWhiteSpace($supabaseUrl) -or
    [string]::IsNullOrWhiteSpace($supabasePublishableKey)) {
    throw 'Release configuration is missing required Supabase values.'
}

$commonArguments = @(
    '--release',
    '--no-pub',
    '--obfuscate',
    "--split-debug-info=$symbolsPath",
    "--dart-define=SUPABASE_URL=$supabaseUrl",
    "--dart-define=SUPABASE_PUBLISHABLE_KEY=$supabasePublishableKey"
)

Push-Location $projectRoot
try {
    if ($Target -in @('apk', 'all')) {
        & flutter build apk @commonArguments
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }
    if ($Target -in @('appbundle', 'all')) {
        & flutter build appbundle @commonArguments
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }
}
finally {
    Pop-Location
}
