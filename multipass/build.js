let ejs = require('ejs');
let data = null;
let options = null;
ejs.renderFile("./client/powershell/multipass.ps1", data, options, function(err, str){
    if (!err) {
        console.log(str);
    }else{
        console.log("Write-Output \"An error occurs during the generation of the script $PSCommandPath\"");
        console.log("Get-Content $PSCommandPath | Select-Object -skip 3  | Select-Object -SkipLast 19");
        console.log("<#");
        console.log(err);
        console.log("#>");
        console.log("[console]::beep(440,500)");
        console.log("[console]::beep(440,500)");
        console.log("[console]::beep(440,500)");
        console.log("[console]::beep(349,350)");
        console.log("[console]::beep(523,150)");
        console.log("[console]::beep(440,500)");
        console.log("[console]::beep(349,350)");
        console.log("[console]::beep(523,150)");
        console.log("[console]::beep(440,1000)");
        console.log("[console]::beep(659,500)");
        console.log("[console]::beep(659,500)");
        console.log("[console]::beep(659,500)");
        console.log("[console]::beep(698,350)");
        console.log("[console]::beep(523,150)");
        console.log("[console]::beep(415,500)");
        console.log("[console]::beep(349,350)");
        console.log("[console]::beep(523,150)");
        console.log("[console]::beep(440,1000)");      
    }
});
