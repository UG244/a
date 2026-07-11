$files = Get-ChildItem -Path lib -Filter *.dart -Recurse
foreach ($file in $files) {
    $content = Get-Content $file.FullName
    $newContent = $content -replace '\.withOpacity\(([0-9.]+)\)', '.withValues(alpha: $1)'
    Set-Content -Path $file.FullName -Value $newContent
}
Write-Host "Reverted withOpacity back to withValues in all Dart files"