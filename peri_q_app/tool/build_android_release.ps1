param(
    [ValidateSet('apk', 'appbundle', 'all')]
    [string]$Target = 'all'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$releaseConfigPath = Join-Path $projectRoot 'release-config.json'
$signingConfigPath = Join-Path $projectRoot 'android\key.properties'
$pubspecPath = Join-Path $projectRoot 'pubspec.yaml'

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
$versionLine = Select-String -LiteralPath $pubspecPath -Pattern '^version:\s*(?<name>[^+]+)\+(?<code>\d+)\s*$' |
    Select-Object -First 1

if ($null -eq $versionLine) {
    throw "Could not parse Flutter version from $pubspecPath"
}

$buildName = $versionLine.Matches[0].Groups['name'].Value.Trim()
$buildNumber = $versionLine.Matches[0].Groups['code'].Value.Trim()
$releaseOutputPath = Join-Path $projectRoot 'release\android'
$releaseStem = "rastasperiq-v$buildName-build$buildNumber-closed-test-release"
$symbolsPath = Join-Path $releaseOutputPath "symbols-v$buildName-build$buildNumber-closed-test"

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
    New-Item -ItemType Directory -Path $releaseOutputPath -Force | Out-Null

    if ($Target -in @('apk', 'all')) {
        & flutter build apk @commonArguments
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
        Copy-Item -LiteralPath (Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-release.apk') `
            -Destination (Join-Path $releaseOutputPath "$releaseStem.apk") -Force
    }
    if ($Target -in @('appbundle', 'all')) {
        & flutter build appbundle @commonArguments
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
        Copy-Item -LiteralPath (Join-Path $projectRoot 'build\app\outputs\bundle\release\app-release.aab') `
            -Destination (Join-Path $releaseOutputPath "$releaseStem.aab") -Force
    }
}
finally {
    Pop-Location
}
