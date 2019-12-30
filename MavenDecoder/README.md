# MavenDecoder
Decrypt maven master password and "server" password

### Version
1.0.0

### Compile
```sh
javac MavenDecoder.java
```

### Usage
```sh
java MavenDecoder "{BASE64MASTER}" "{BASE64USER}"
```

### Examples

```sh
MASTER=`mvn --encrypt-master-password MavenDecoderMaster`
echo $MASTER

mkdir ~/.m2
cat > ~/.m2/settings-security.xml <<EOL
<settingsSecurity>
  <master>${MASTER}</master>
</settingsSecurity>
EOL

USERPASS=`mvn --encrypt-password MavenDecoderUser`
echo $USERPASS

java MavenDecoder ${MASTER} ${USERPASS}
```

### References
The tools is freely inspired by [Maven settings decoder](https://github.com/jelmerk/maven-settings-decoder). I just remove all dependencies by copying revelant part of the Sonatype source code, and using string as input instead of original file.
The process of encrypting and decrypting is however well-known as we can see in [StackOverflow](https://stackoverflow.com/questions/30769636/how-does-maven-3-password-encryption-work)
The procedure from maven can be found [here](http://maven.apache.org/guides/mini/guide-encryption.html)

### How to get master/password of Maven
On windows/linux the two files that stored maven password are located in a folder name .m2 inside the user home directory (c:\Users\{username}\.m2\ and /home/{username}/.m2
The file *settings-security.xml* contains the master password that are used as a key to encrypt password that are on the second file *settings.xml*
The file *settings.xml* may also contains url, proxy, and username that may be good to look at.

### Pentest tips
Maven password is often used with repositories like Nexus. You have to setup your maven password with the same login/password as the one you have in Nexus.
In Nexus, the user may have the capabilities to upload build, which is a good entry point.
Most Nexus configuration use LDAP or AD authentication, so instead of [passing the hash](https://beta.hackndo.com/pass-the-hash/) or [dump lsass](https://beta.hackndo.com/remote-lsass-dump-passwords/) you can just read plain text xml.
