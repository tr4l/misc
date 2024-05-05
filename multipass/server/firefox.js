//const sqlite3 = require('sqlite3').verbose();
const sqlite3 = require('better-sqlite3');
const crypto = require('crypto');
const fs = require('fs');
const bomstrip = require('bomstrip');

function getCredentials(path, jsonFile){
    let creds = [];
    let rawdata = fs.readFileSync(path + jsonFile);
    ff = JSON.parse(rawdata.toString('utf8').replace(/^\uFEFF/, ''));

    for(var file in ff.files){
        if (file.endsWith("logins.json")){
            let rawlogins = fs.readFileSync(path + file);
            logins = JSON.parse(rawlogins.toString('utf8').replace(/^\uFEFF/, ''));
            for(const pos in logins.logins){
                let login = logins.logins[pos];
                let cred = {};
                // Global stuff
                cred.category = ff.category;
                cred.software = ff.software;
                cred.version = ff.version;
                // Custom one

                cred.username = "*ENCRYPTED*";
                cred.password = "Need manual decrypt";
                cred.assets = login.hostname;
                cred.realm = login.httpRealm;

                creds.push (cred);
            }
        }
    }
    return creds;
}
// Export the function for public access
module.exports.getCredentials = getCredentials;


