Function MultiPassChromium {
    param(
        [Parameter()]
        [string]$userPath
    )
    $obj = New-Object MultiPassExport

    $configPath = "$userPath\Local State"
    if (Test-Path $configPath){
        $config = Get-Content -Raw -Path $configPath | ConvertFrom-Json

        if( $null -ne $config.browser ){
            $browser = $config.browser| ConvertTo-Json | ConvertFrom-Json
            $obj.version = $browser.browser_build_version
        }

        if( $null -ne $config.os_crypt ){
            $crypt = $config.os_crypt| ConvertTo-Json | ConvertFrom-Json
            [byte[]] $hexCreds = [System.Convert]::FromBase64String($crypt.encrypted_key)

            $tmp = $hexCreds[5..$hexCreds.Length]

            # We need to get the master key on client computer because this is protected by DPAPI
            $master = [Security.Cryptography.ProtectedData]::Unprotect($tmp, $null, 'CurrentUser')
            $obj.data["master_key.hexa"] = [System.Convert]::ToBase64String($master)
            $profiles = @()
            $profiles+= ,"" #Current folder aka "no profile"
            $profiles+= ,"Default"
            foreach($profile in $config.profile.info_cache.psobject.properties.name){
                $profiles+=$profile
            }
            # Maybe we can also get folder starting with "Profile"
            foreach( $profile in $profiles){
                $ldPath = "$userPath\$profile\Login Data"
                if (Test-Path $ldPath){
                    $obj.files["Browser_Chrome_${profile}_LoginData"] = "$ldPath"
                }
                $ldPath = "$userPath\$profile\Login Data For Account"
                if (Test-Path $ldPath){
                    $obj.files["Browser_Chrome_${profile}_LoginDataForAccount"] = "$ldPath"
                }

            }
        }
        
    }
    return $obj
}