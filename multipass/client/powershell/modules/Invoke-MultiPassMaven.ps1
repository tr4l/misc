
function Invoke-MultiPassMaven {
    <#
        .Synopsis
            Gets settings.xml and settings-security.xml to decode password offline if needed
    
        .Outputs
            MultiPassExport
    
        .Example
            $resultMultiPassExport = Invoke-MultiPassMaven
    
        .Example
            If the password is encrypted with the master and you got the master in settings-security.xml
            Then you can use https://github.com/tr4l/misc/tree/master/MavenDecoder to decode it
        #>    
    
        
        $export = New-Object MultiPassExport
        $export.category = "DevOps"
        $export.software = "Maven"
        $m2Path = "$($env:USERPROFILE)\.m2"
    
        if (Test-Path "$m2Path"){
            $user = $env:UserName
            if (Test-Path "${m2Path}\settings.xml"){
                $export.files["DevOps_Maven_${user}_settings.xml"] = "${m2Path}\settings.xml"
            }
            # Add check for settingsSecurity.relocation ?
            if (Test-Path "${m2Path}\settings-security.xml"){
                
                $export.files["DevOps_Maven_${user}_settings-security.xml"] = "${m2Path}\settings-security.xml"
            }
        }
    
        return $export
    }