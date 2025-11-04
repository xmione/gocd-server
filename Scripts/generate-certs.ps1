# Scripts/generate-certs.ps1
$certsDir = Join-Path $PSScriptRoot "..\certs"
New-Item -ItemType Directory -Force -Path $certsDir | Out-Null

if (-Not (Test-Path "$certsDir\ca.key")) {
    & openssl genrsa -out "$certsDir\ca.key" 4096
    & openssl req -x509 -new -nodes -key "$certsDir\ca.key" -sha256 -days 3650 `
        -subj "/CN=GoCD-Local-CA" -out "$certsDir\ca.crt"
}

& openssl genrsa -out "$certsDir\server.key" 2048
& openssl req -new -key "$certsDir\server.key" -subj "/CN=gocd-server" -out "$certsDir\server.csr"
& openssl x509 -req -in "$certsDir\server.csr" -CA "$certsDir\ca.crt" -CAkey "$certsDir\ca.key" -CAcreateserial `
    -out "$certsDir\server.crt" -days 825 -sha256

Write-Host "✅ Certificates generated in $certsDir"
