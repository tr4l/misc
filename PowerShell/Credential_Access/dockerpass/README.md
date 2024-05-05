# dockerpass

**`dockerpass`** is a post-exploitation powershell tool that extract password from several docker "store"

# Description

dockerpass check:
1 To get the docker config file on .docker\config.json
2 Extract base64 creds from this file
3 Locate docker.exe and all docker-credential-*.exe in the same path
4 Ask politely for each credential executable to give password 


