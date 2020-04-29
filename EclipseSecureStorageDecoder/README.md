# EclipseSecureStorageDecoder
Decrypt information (like password) stored on the Eclipse Secure Storage.
This version is for windows 64, but may work for other version if you have the master

### Version
1.0.0

### Compile
```sh
javac EclipseSecureStorageDecoder.java
```

### Usage
```sh
java EclipseSecureStorageDecoder
```

### Examples

```sh
java EclipseSecureStorageDecoder 
```

### References
The tools is inspired by the [equinox secure storage](https://github.com/eclipse/rt.equinox.bundles/) source code.
I remove all dependencies by copying revelant part of the source code, and tweaking some part of the code.
This also use a well known powershell trick to decode the master key with the DPAPI

### How to get the master key.

### Pentest tips
For pentesting a devops company, getting eclipse paswword can help during lateral movement phase. Ideally you should have a small powershell script that read the secure storage file, get the crypted master, decrypt it, then sent the file and the password back for safe decrypting.

Lot of devops tools/plugins use the secure storage to save the credentials like the [CxSAST Eclipse Plugin](https://checkmarx.atlassian.net/wiki/spaces/KC/pages/1186398436/Setting+Up+the+CxSAST+Eclipse+Plugin+v9.0.0+and+up) of Checkmarx.

If the target tools are connected to a LDAP (which is often [the case](https://checkmarx.atlassian.net/wiki/spaces/KC/pages/301466125/LDAP+Management+v8.8.0+to+V8.9.0) you get password to reuse on the pentest
