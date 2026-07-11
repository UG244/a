$files = Get-ChildItem -Path lib -Filter *.dart -Recurse
foreach ($file in $files) {
    $content = Get-Content $file.FullName
    $newContent = $content -replace '\.withValues\(alpha: ([0-9.]+)\)', '.withOpacity($1)'
    Set-Content -Path $file.FullName -Value $newContent
}
Write-Host "Fixed withValues in all Dart files"