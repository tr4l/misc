const fs = require('fs');
const path = require('path');
const ObjectsToCsv = require('objects-to-csv')

const chromium = require('./server/chromium.js');
const docker = require('./server/docker.js');
const edge = require('./server/edge.js');
const ff = require('./server/firefox.js');
const mvn = require('./server/maven.js');

var dataPath = "c:\\dev\\temp\\out\\";
dataPath = "/mnt/c/dev/temp/out/";
let credentials = [];

if (fs.existsSync(path.join(dataPath, "Invoke-MultiPassChrome.json"))) {
    let chromCreds = chromium.getCredentials(dataPath, 'Invoke-MultiPassChrome.json');
    credentials = credentials.concat(chromCreds);
}

if (fs.existsSync(path.join(dataPath, "Invoke-MultiPassEdge80.json"))) {
    let edgaCreds = chromium.getCredentials(dataPath, 'Invoke-MultiPassEdge80.json');
    credentials = credentials.concat(edgaCreds);
}

if (fs.existsSync(path.join(dataPath, "Invoke-MultiPassDocker.json"))) {
    let dockerCreds = docker.getCredentials(dataPath, 'Invoke-MultiPassDocker.json');
    credentials = credentials.concat(dockerCreds);
}

if (fs.existsSync(path.join(dataPath, "Invoke-MultiPassEdge.json"))) {
    let edgeCreds = edge.getCredentials(dataPath, 'Invoke-MultiPassEdge.json');
    credentials = credentials.concat(edgeCreds);
}

if (fs.existsSync(path.join(dataPath, "Invoke-MultiPassFirefox.json"))) {
    let ffCreds = ff.getCredentials(dataPath, 'Invoke-MultiPassFirefox.json');
    credentials = credentials.concat(ffCreds);
}

if (fs.existsSync(path.join(dataPath, "Invoke-MultiPassMaven.json"))) {
    let mvnCreds = mvn.getCredentials(dataPath, 'Invoke-MultiPassMaven.json');
    credentials = credentials.concat(mvnCreds);
}

const csv = new ObjectsToCsv(credentials)
csv.toDisk('./report.csv')
