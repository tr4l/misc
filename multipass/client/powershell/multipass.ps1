# For wifi password: https://www.powershellgallery.com/packages/wifiprofilemanagement/0.0.0.2/Content/wifiprofilemanagement.psm1
# https://0x00-0x00.github.io/research/2018/11/06/Recovering-Plaintext-Domain-Credentials-From-WPA2-Enterprise-on-a-compromised-host.html

# Set Global array for dependencies
#<% let assembly = new Set(); %>
#<% let utils = new Set(); %>
# Include MultiPassExport export class use by each module for export
<%- include('./core/MultiPassExport.ps1'); -%>

# Initiliaze the list of modules.
<#
<%
let modules = ['MultiPassDocker','MultiPassFireFox','MultiPassChrome','MultiPassCredMan',
               'MultiPassMaven', 'MultiPassEdge', 'MultiPassEdge80'];
%>                  
#>
$multiPassModules = @()
# Add defined modules
<% for (const module of modules){ %>
    <%- include('./modules/Invoke-'+module+'.ps1', {utils: utils, assembly: assembly}); -%>
    $multiPassModules += ,"Invoke-<%= module %>"
<% } %>
    
# Add any required assembly
<% for (var iterator = assembly.values(), ass= null; ass=iterator.next().value; ) { %>
Add-Type -AssemblyName <%= ass %>;
<% } %>

# Add any required utils class
<% for (var iterator = utils.values(), util= null; util=iterator.next().value; ) { %>
<%- include('./utils/' + util); -%>
<% } %>
    
# Call all of them
function Invoke-MultiPass
{
    foreach ($modules in $multiPassModules)
    {
        $result = & $modules
        $jsonResult = $result | ConvertTo-Json

        # Display result on console
        # Write-Output $jsonResult

        # Write result on json file on local folder
        Out-File -Encoding UTF8 -FilePath .\$modules.json -InputObject $jsonResult

        # Copy file to local folder
        foreach($file in $result.files.Keys){
            Copy-Item -Path $result.files[$file] -Destination $file
        }
    }
}

Invoke-MultiPass