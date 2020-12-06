Write-Host '----------------------------------------------------'
Write-Host 'Clearing existing TLS certs'
Write-Host '----------------------------------------------------'
Get-ChildItem -Path *.crt -Recurse | Remove-Item
Get-ChildItem -Path *.key -Recurse | Remove-Item

Write-Host '----------------------------------------------------'
Write-Host 'Generating new TLS certs'
Write-Host '----------------------------------------------------'

mkcert\mkcert -install
mkcert\mkcert -cert-file k8s\secrets\tls\global-cm\tls.crt -key-file k8s\secrets\tls\global-cm\tls.key "cm.globalhost"
mkcert\mkcert -cert-file k8s\secrets\tls\global-cd\tls.crt -key-file k8s\secrets\tls\global-cd\tls.key "cd.globalhost"
mkcert\mkcert -cert-file k8s\secrets\tls\global-id\tls.crt -key-file k8s\secrets\tls\global-id\tls.key "id.globalhost"

$sitecoreRepo = Get-PSRepository -Name "SitecoreGallery" -ErrorAction SilentlyContinue

if(!$sitecoreRepo)
{
    Write-Host '----------------------------------------------------'
    Write-Host 'Registering sitecore powershell repository'
    Write-Host '----------------------------------------------------'

    Register-PSRepository -Name "SitecoreGallery" -SourceLocation "https://sitecore.myget.org/F/sc-powershell/api/v2"
    Install-Module SitecoreDockerTools
}

Write-Host '----------------------------------------------------'
Write-Host 'Generating and Updating Secrets'
Write-Host '----------------------------------------------------'

Import-Module SitecoreDockerTools

Write-Host 'Generating certificate for identity server..'
$idCertPassword = Get-SitecoreRandomString 12 -DisallowSpecial
$identityCertificate = (Get-SitecoreCertificateAsBase64String -DnsName "localhost" -Password (ConvertTo-SecureString -String $idCertPassword -Force -AsPlainText))
Set-Content -Path ".\k8s\secrets\sitecore-identitycertificate.txt" -Value $identityCertificate -NoNewline
Set-Content -Path ".\k8s\secrets\sitecore-identitycertificatepassword.txt" -Value $idCertPassword -NoNewline

Write-Host 'Setting up sitecore admin password..'
Set-Content -Path ".\k8s\secrets\sitecore-adminpassword.txt" -Value "Password12345" -NoNewline

Write-Host 'Generating passwords for database users..'
Set-Content -Path ".\k8s\secrets\sitecore-collection-shardmapmanager-database-password.txt" -Value ((Get-SitecoreRandomString 32 -DisallowSpecial) + "!!") -NoNewline
Set-Content -Path ".\k8s\secrets\sitecore-core-database-password.txt" -Value ((Get-SitecoreRandomString 32 -DisallowSpecial) + "!!") -NoNewline
Set-Content -Path ".\k8s\secrets\sitecore-databasepassword.txt" -Value ((Get-SitecoreRandomString 32 -DisallowSpecial) + "!!") -NoNewline
Set-Content -Path ".\k8s\secrets\sitecore-exm-master-database-password.txt" -Value ((Get-SitecoreRandomString 32 -DisallowSpecial) + "!!") -NoNewline
Set-Content -Path ".\k8s\secrets\sitecore-forms-database-password.txt" -Value ((Get-SitecoreRandomString 32 -DisallowSpecial) + "!!") -NoNewline
Set-Content -Path ".\k8s\secrets\sitecore-marketing-automation-database-password.txt" -Value ((Get-SitecoreRandomString 32 -DisallowSpecial) + "!!") -NoNewline
Set-Content -Path ".\k8s\secrets\sitecore-master-database-password.txt" -Value ((Get-SitecoreRandomString 32 -DisallowSpecial) + "!!") -NoNewline
Set-Content -Path ".\k8s\secrets\sitecore-messaging-database-password.txt" -Value ((Get-SitecoreRandomString 32 -DisallowSpecial) + "!!") -NoNewline
Set-Content -Path ".\k8s\secrets\sitecore-processing-engine-storage-database-password.txt" -Value ((Get-SitecoreRandomString 32 -DisallowSpecial) + "!!") -NoNewline
Set-Content -Path ".\k8s\secrets\sitecore-processing-engine-tasks-database-password.txt" -Value ((Get-SitecoreRandomString 32 -DisallowSpecial) + "!!") -NoNewline
Set-Content -Path ".\k8s\secrets\sitecore-processing-pools-database-password.txt" -Value ((Get-SitecoreRandomString 32 -DisallowSpecial) + "!!") -NoNewline
Set-Content -Path ".\k8s\secrets\sitecore-processing-tasks-database-password.txt" -Value ((Get-SitecoreRandomString 32 -DisallowSpecial) + "!!") -NoNewline
Set-Content -Path ".\k8s\secrets\sitecore-reference-data-database-password.txt" -Value ((Get-SitecoreRandomString 32 -DisallowSpecial) + "!!") -NoNewline
Set-Content -Path ".\k8s\secrets\sitecore-reporting-database-password.txt" -Value ((Get-SitecoreRandomString 32 -DisallowSpecial) + "!!") -NoNewline
Set-Content -Path ".\k8s\secrets\sitecore-web-database-password.txt" -Value ((Get-SitecoreRandomString 32 -DisallowSpecial) + "!!") -NoNewline

Write-Host 'Generating api and encryption keys..'
Set-Content -Path ".\k8s\secrets\sitecore-reportingapikey.txt" -Value (Get-SitecoreRandomString 64 -DisallowSpecial) -NoNewline
Set-Content -Path ".\k8s\secrets\sitecore-telerikencryptionkey.txt" -Value (Get-SitecoreRandomString 128 -DisallowSpecial) -NoNewline
Set-Content -Path ".\k8s\secrets\sitecore-identitysecret.txt" -Value (Get-SitecoreRandomString 64 -DisallowSpecial) -NoNewline

Write-Host 'Extracting sitecore license..'
Set-Content -Path ".\k8s\secrets\sitecore-license.txt" -Value (ConvertTo-CompressedBase64String -Path "C:\License\license.xml") -NoNewline
