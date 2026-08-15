#Requires -Version 5.1
# À lancer sur le PC Windows. Ne touche pas au VPS tout seul :
# affiche les commandes et crée la clé locale.

$ErrorActionPreference = "Stop"
$sshDir = Join-Path $env:USERPROFILE ".ssh"
$keyPath = Join-Path $sshDir "ovh_vps"
$configPath = Join-Path $sshDir "config"

if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir | Out-Null
}

if (-not (Test-Path $keyPath)) {
    ssh-keygen -t ed25519 -f $keyPath -C "louzza-ovh-vps" -N '""'
}

$stanza = @"
Host ovh-vps
    HostName vps-b377201e.vps.ovh.net
    User ubuntu
    IdentityFile ~/.ssh/ovh_vps
    IdentitiesOnly yes
"@

if (-not (Test-Path $configPath) -or -not (Select-String -Path $configPath -Pattern "Host ovh-vps" -Quiet)) {
    Add-Content -Path $configPath -Value $stanza
}

Write-Host "Cle publique a installer sur le VPS :"
Get-Content "$keyPath.pub"
Write-Host ""
Write-Host "Commande suivante (mot de passe ubuntu, une derniere fois) :"
Write-Host 'type $env:USERPROFILE\.ssh\ovh_vps.pub | ssh ubuntu@vps-b377201e.vps.ovh.net "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"'
