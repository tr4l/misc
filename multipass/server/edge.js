const fs = require('fs');
const bomstrip = require('bomstrip');

function getCredentials(path, jsonFile){
    let creds = [];
    let rawdata = fs.readFileSync(path + jsonFile);
    jsonData = JSON.parse(rawdata.toString('utf8').replace(/^\uFEFF/, ''));
    for(var key in jsonData.data){
        let ks = key.split(":");
        let pos = ks[1];
        let cred;
        if (!creds[pos]){
            // Global stuff
            cred = {};
            cred.category = jsonData.category;
            cred.software = jsonData.software;
            cred.version = jsonData.version;
            creds[pos] = cred;
        }else{
            cred = creds[pos];
        }
        switch (ks[2]) {
            case "Username":
                cred.username = jsonData.data[key];
                break;
            case "Password":
                cred.password = jsonData.data[key];
                break;
            case "Resource":
                cred.assets = jsonData.data[key];
                break;
        }
    }
    return creds;
}
// Export the function for public access
module.exports.getCredentials = getCredentials;
