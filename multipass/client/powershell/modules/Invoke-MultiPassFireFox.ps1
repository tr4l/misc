# Add utils dependencies
# <% utils.add("Get-IniContent.ps1") %>

function Invoke-MultiPassFireFox {
    <#
        .Synopsis
            Gets key4.db and login.json to decode password offline
    
        .Outputs
            MultiPassExport
    
        .Example
            $resultMultiPassExport = Invoke-MultiPassFireFox
    
        .Example
            To decode with version 74 of firefox:
            - Copy both key4.db and login.json in an empty folder
            - Run firefox inside that folder with the command line
            - "C:\Program Files\Mozilla Firefox\firefox.exe" -profile . "about:logins"
        #>    
        
        $ff = New-Object MultiPassExport
        $ff.category = "Browser"
        $ff.software = "Firefox"
        $profilePath = "$($env:APPDATA)\Mozilla\Firefox"
    
        if (Test-Path "$profilePath\profiles.ini"){
            $ff.data["path:profiles.ini"] = "$profilePath"
            $profiles = Get-IniContent "$profilePath\profiles.ini"
            foreach($key in $profiles.Keys){
                if ($profiles.Item($key)["Path"]){
                    $ff.data["$key"] = $profiles.Item($key)["Path"]
                    $dataPath = $profiles.Item($key)["Path"]
                    
                    if ($profiles.Item($key)["IsRelative"] -eq "1"){
                        $dbpath = "$profilePath/" + $dataPath
                    }

                    if (Test-Path "$dbpath/key4.db"){
                        $ff.files["Browser_FireFox_${key}_key4.db"] = "$dbpath/key4.db"
                        $ff.files["Browser_FireFox_${key}_logins.json"] = "$dbpath/logins.json"
                    }
                }
            }
        }
        return $ff
    }