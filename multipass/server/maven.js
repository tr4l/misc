const fs = require('fs');
const xml2js = require('xml2js');
const crypto = require('crypto');
const bomstrip = require('bomstrip');
const parser = new xml2js.Parser({ attrkey: "ATTR" });

const SALT_SIZE = 8;
const SPICE_SIZE = 16;

function getCredentials(path, jsonFile){
    let creds = [];
    let rawdata = fs.readFileSync(path + jsonFile);
    jsonData = JSON.parse(rawdata.toString('utf8').replace(/^\uFEFF/, ''));
    let master;
    // Extract a master if we have a security.xml
    for(var file in jsonData.files){
        if (file.endsWith("settings-security.xml")){
            let rawContent = fs.readFileSync(path + file);
            let xml = parseSync(rawContent);
            if (xml.settingsSecurity && xml.settingsSecurity.master && xml.settingsSecurity.master[0]){
                master = decrypt64(xml.settingsSecurity.master[0], "settings.security");
                if (master){
                    let cred = {};
                    // Global stuff
                    cred.category = jsonData.category;
                    cred.software = jsonData.software;
                    cred.version = jsonData.version;
                    // Custom one

                    cred.username = "MASTER MAVEN";
                    cred.password = master;

                    creds.push (cred);
                }
            }
        }
    }
    for(var file in jsonData.files){
        if (file.endsWith("settings.xml")){
            let rawContent = fs.readFileSync(path + file);
            let xml = parseSync(rawContent);
            if (xml.settings && xml.settings.servers && xml.settings.servers[0].server) {
                for (let pos in xml.settings.servers[0].server){
                    let server = xml.settings.servers[0].server[pos];
                    let cred = {};
                    // Global stuff
                    cred.category = jsonData.category;
                    cred.software = jsonData.software;
                    cred.version = jsonData.version;
                    // Custom one

                    cred.username = server.username[0];
                    cred.password = server.password[0];
                    cred.assets = server.id[0];
                    if (master){
                    try {
                        let decrypt = decrypt64(server.password[0], master);
                        cred.password = decrypt;
                        }catch(e){}//either is not crypted or crypt doesn't work.
                    }
                    creds.push (cred);

                    //decrypt64("pp", "settings.security");
                }

            }
        }
    }
    return creds;
}
// Export the function for public access
module.exports.getCredentials = getCredentials;

function tmp() {
const b64Password = unDecorate(master);
var dMaster = decrypt64(b64Password, "settings.security");
console.log(dMaster);
console.log(decrypt64(unDecorate(password), dMaster));
}

function unDecorate(str) {
    const decoRegExp = /[^{]*{([^}]*)}.*/;

    if (decoRegExp.test(str)) {
        return str.match(decoRegExp)[1];
    } else {
        console.log("Not decorated")
    }
}
function decrypt64(encryptedText, password){
    //Text is pass as base64
    let buff = Buffer.from(encryptedText, 'base64');
    let salt = Buffer.allocUnsafe(SALT_SIZE);
    buff.copy(salt, 0, 0, SALT_SIZE);
    let padLen = buff[SALT_SIZE];
    let encryptedBytes = Buffer.allocUnsafe(buff.length - SALT_SIZE - 1 - padLen);
    buff.copy(encryptedBytes, 0, SALT_SIZE + 1, encryptedBytes.length+SALT_SIZE+1);
    let keyAndIv = computeKeyAndIv(password, salt);
    let key = Buffer.allocUnsafe(SPICE_SIZE);
    let iv = Buffer.allocUnsafe(SPICE_SIZE);
    keyAndIv.copy(key,0,0,SPICE_SIZE);
    keyAndIv.copy(iv,0,SPICE_SIZE,keyAndIv.length);
    encryptedBytes
    const decipher = crypto.createDecipheriv("aes-128-cbc", key, iv);
    let decrypted = decipher.update(encryptedBytes);
    decrypted += decipher.final();
    return decrypted;
}

function computeKeyAndIv(password, salt){
    // Simplyfing the java version. We always have salt, and sha256 always produce 32 byte as we need.
    let pasBuf = Buffer.from(password, 'utf8');
    const hash = crypto.createHash('sha256');
    let keyAndIv = Buffer.allocUnsafe(SPICE_SIZE * 2);
    let currentPos = 0;
    let result;
    hash.update(pasBuf);
    hash.update(salt);
    result = hash.digest();
    return result;
}
function parseSync (xml) {
    var json = null;
    xml2js.parseString(xml, function (innerError, innerJson) {
        json = innerJson;
    });

    return json;
}