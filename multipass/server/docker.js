const fs = require('fs');
const bomstrip = require('bomstrip');

function getCredentials(path, jsonFile){
    let creds = [];
    let rawdata = fs.readFileSync(path + jsonFile);
    jsonData = JSON.parse(rawdata.toString('utf8').replace(/^\uFEFF/, ''));
    for(var key in jsonData.data){
        if (key.startsWith('credStore:')){
            // We got a credentails in the store
            let cred = {};
            
            // Global stuff
            cred.category = jsonData.category;
            cred.software = jsonData.software;
            cred.version = jsonData.version;

            // Custom one
            let jsonCreds = JSON.parse(jsonData.data[key]);
            cred.username = jsonCreds.Username;
            cred.password = jsonCreds.Secret;
            cred.assets = jsonCreds.ServerURL;
            let ks = key.split(':')
            cred.realm = ks[ks.length-1];

            creds.push (cred);
        }
    }
    return creds;
}
// Export the function for public access
module.exports.getCredentials = getCredentials;
