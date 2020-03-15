$uriSlack = "https://hooks.slack.com/services/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"

$body = ConvertTo-Json @{
    pretext = "Test implementare"
    text = "Hello from powershell!!!"
    color = "#FF0000"
}


try {
    Invoke-RestMethod -uri $uriSlack -Method Post -body $body -ContentType 'application/json' | Out-Null
} catch {
    Write-Error (Get-Date) ": Update to Slack went wrong..."
}