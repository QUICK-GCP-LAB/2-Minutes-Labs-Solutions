# Download the script that adds the Ops Agent package repository
(New-Object Net.WebClient).DownloadFile(
    "https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.ps1",
    "$env:TEMP\add-google-cloud-ops-agent-repo.ps1"
)

# Run the downloaded script with the `-AlsoInstall` and `-Verbose` flags
powershell -ExecutionPolicy Unrestricted -File "$env:TEMP\add-google-cloud-ops-agent-repo.ps1" -AlsoInstall -Verbose