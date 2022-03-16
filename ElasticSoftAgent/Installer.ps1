$CurrentWindowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$CurrentWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($CurrentWindowsIdentity)
$IsAdmin = $CurrentWindowsPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if($IsAdmin){

    Write-Output "Configure service :"
    $endpoint = Read-Host -Prompt "Endpoint"
    $passwordAPI = Read-Host -Prompt "API Password"
    $engine = Read-Host -Prompt "Engine"
    
    Write-Output "Creating new registry key..."
    
    try{
    New-Item -Path "HKLM:\SOFTWARE" -Name "ElasticSoftAgent" -ErrorAction Stop
    }
    catch [System.IO.IOException]{
    Write-Output "ElasticSoftAgent key already exist"
    }
    
    Try{
    $null = New-ItemProperty -Path "HKLM:\SOFTWARE\ElasticSoftAgent" -Name "endpoint" -Value $endpoint -ErrorAction Stop
    }
    Catch{
        Write-Output 'Registry Key "endpoint" already exist'
        try{
            $null = Set-ItemProperty -Path "HKLM:\SOFTWARE\ElasticSoftAgent" -Name "endpoint" -Value $endpoint -ErrorAction Stop
            Write-Output "The value has been changed correctly"
        }catch{Write-Output "WARNING : Impossible to change the value !"}
    }
    
    Try{
    $null = New-ItemProperty -Path "HKLM:\SOFTWARE\ElasticSoftAgent" -Name "passwordAPI" -Value $passwordAPI -ErrorAction Stop
    }
    Catch{
        Write-Output 'Registry Key "passwordAPI" already exist'
        try{
            $null = Set-ItemProperty -Path "HKLM:\SOFTWARE\ElasticSoftAgent" -Name "passwordAPI" -Value $passwordAPI -ErrorAction Stop
            Write-Output "The value has been changed correctly"
        }catch{Write-Output "WARNING : Impossible to change the value !"}
    }
    
    Try{
    $null = New-ItemProperty -Path "HKLM:\SOFTWARE\ElasticSoftAgent" -Name "engine" -Value $engine -ErrorAction Stop
    }
    Catch{
        Write-Output 'Registry Key "engine" already exist'
        try{
            $null = Set-ItemProperty -Path "HKLM:\SOFTWARE\ElasticSoftAgent" -Name "engine" -Value $engine -ErrorAction Stop
            Write-Output "The value has been changed correctly"
        }catch{Write-Output "WARNING : Impossible to change the value !"}
    }
    
    Write-Output "Creating the task scheduled..."
    
    schtasks.exe /create /sc MINUTE /mo 10 /tn ElasticSoftAgent /F /tr "powershell.exe -File 'C:\Program Files\ElasticSoftAgent\ElasticSoftAgent.ps1'" /ru 'SYSTEM'

} else {

    Write-Output "Run the script with admin privileges !"
    sleep 30

}
