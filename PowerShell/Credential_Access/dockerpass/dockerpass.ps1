# powershell -executionpolicy bypass -file dockerpass.ps1
function Invoke-dockerpass
{
# Try to get config.json on default path
$configPath = "$($env:USERPROFILE)\.docker\config.json"
if (Test-Path $configPath){
    Write-Output "config.json found on $configPath"
    $config = Get-Content -Raw -Path $configPath | ConvertFrom-Json
    if( $null -ne $config.auths ){
        $jAuths = $config.auths| ConvertTo-Json | ConvertFrom-Json
        foreach($url in $jAuths.psobject.properties.name){
            $b64Cred = "not on config.json"
            if ($null -ne $jAuths.$url.auth){
                $b64Cred = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($jAuths.$url.auth))
            }
            Write-Output "Credentials for URL $url are $b64Cred"
        }
    }
    if( $null -ne $config.credsStore ){
        Write-Output "Config.json is configured to use the credStore:$($config.credsStore)"
    }

    #Write-Output $config.auths
}else{
    Write-Output "config.json not found on default place"
}
#credsStore

# Get all docker.exe installed
$dock = Get-Command -all docker.exe
foreach($command in $dock){
    # For each docker we found, list all credential helpers
    $dpath = Split-Path -Path $command.source
    Write-Output "Path to docker.exe found: $dpath";
    $dcreds = Get-ChildItem -Path $dpath\docker-credential-*.exe;
    foreach($dcred in $dcreds){
        # For each helper, list all credentials
        
        $tmpcred = & $dcred.Name list;
        #Write-Output $tmpcred;
        $jsonCred = ConvertFrom-Json -InputObject $tmpcred
        # and for each credentials, dump them
        foreach($url in $jsonCred.psobject.properties.name)
        {
            $out = Write-Output $url | & $dcred.Name get;

            Write-Output "$($dcred.Name) ->  $out"
        }
    }

}
}