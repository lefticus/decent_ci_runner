# try several times because it's possible choco might not work :(

choco install --yes --acceptlicense git
Start-Sleep -seconds 5
choco upgrade --yes --acceptlicense git
Start-Sleep -seconds 5
choco upgrade --yes --acceptlicense git

