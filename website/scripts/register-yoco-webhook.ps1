$ErrorActionPreference = 'Stop'
Write-Host 'Register the RastasperiQ webhook with Yoco. Start with your TEST secret key.'
$secureYocoKey = Read-Host 'Yoco secret key (input is hidden)' -AsSecureString
$yocoKeyValue = [System.Net.NetworkCredential]::new('', $secureYocoKey).Password
try {
    if ($yocoKeyValue -notmatch '^sk_(test|live)_') { throw 'Enter a Yoco secret key starting sk_test_ or sk_live_. A public key cannot register webhooks.' }
    $registrationBody = @{
        name = 'rastasperiq-website'
        url = 'https://rastasperiq.co.za/api/yoco/webhook/'
    } | ConvertTo-Json
    $registration = Invoke-RestMethod -Method Post -Uri 'https://payments.yoco.com/api/webhooks' -Headers @{ Authorization = "Bearer $yocoKeyValue" } -ContentType 'application/json' -Body $registrationBody
    if (!$registration.secret) { throw 'Yoco did not return a webhook secret. Inspect your Yoco account before registering again.' }
    Write-Host 'Webhook registered. Copy this secret into Vercel Production as YOCO_WEBHOOK_SECRET:'
    Write-Host $registration.secret
    Write-Host 'Keep the secret private. Yoco provides it only once. Redeploy Vercel after saving it.'
} finally {
    $yocoKeyValue = $null
    $secureYocoKey = $null
}
Read-Host 'Press Enter after saving the webhook secret'
