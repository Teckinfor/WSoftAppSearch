function Get-Software
{
    param
    (
    [string]
    $DisplayName = '*'
    )

        $Values = 'DisplayName','DisplayVersion'


        [string[]]$visible = 'DisplayName','DisplayVersion'
        [Management.Automation.PSMemberInfo[]]$visibleProperties = [System.Management.Automation.PSPropertySet]::new('DefaultDisplayPropertySet',$visible)

        New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS -ErrorAction SilentlyContinue
        $users = Get-ChildItem -Path "HKU:\"
        
        $list = @()
        
        foreach ($item in $users){
            
            $path1 = "HKU:\" +$item.Name+ "\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
            $path2 = "HKU:\" +$item.Name+ "\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        
            $list = $list + $path1 + $path2
        }

        $list = $list + 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' + 
                            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' +
                            'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' +
                            'HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'

        $object = foreach($path in $list ) {
 
            Get-ItemProperty -Path $path -ErrorAction Ignore |

            Where-Object DisplayName |

            Where-Object { $_.DisplayName -like $DisplayName } |

            Select-Object -Property $values |


            Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $visibleProperties -PassThru

        }

        $object
        $HKURemoved = $object.ForEach({ if($_.Name -ne "HKU"){$_} })
        $HKURemoved
}

$software = Get-Software | Select-Object DisplayName, DisplayVersion

$softcomputer = @{id = $env:COMPUTERNAME}

Remove-Item $Object -ErrorAction Ignore
$Object = New-Object PSObject -Property $softcomputer

foreach ($soft in $software){

    if ($soft.DisplayName -ne $null){
        $Object | Add-Member -MemberType NoteProperty -Force -Name $soft.DisplayName.replace(' ', '_').replace('.', '_').replace('"', '').replace("-","_").replace("(", "").replace(")", "").ToLower() -Value $soft.DisplayVersion -ErrorAction Ignore
    }
            
}

$doc = ConvertTo-JSON $Object

### Send information to elastic

$endpoint = Get-ItemProperty -Path "HKLM:\SOFTWARE\ElasticSoftAgent" -Name "endpoint"
$endpoint = $endpoint.endpoint

$passwordAPI = Get-ItemProperty -Path "HKLM:\SOFTWARE\ElasticSoftAgent" -Name "passwordAPI"
$passwordAPI = $passwordAPI.passwordAPI

$engine = Get-ItemProperty -Path "HKLM:\SOFTWARE\ElasticSoftAgent" -Name "engine"
$engine = $engine.engine

$uri = "{0}/api/as/v1/engines/{1}/documents" -f $endpoint,$engine

$header = @{
    "Authorization"="Bearer "+$passwordAPI
    "Content-Type"="application/json"
}

Invoke-RestMethod -Uri $uri -Method Post -Body $doc -Headers $header
