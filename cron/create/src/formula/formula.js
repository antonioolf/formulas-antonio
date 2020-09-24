const clc = require("cli-color");
const prompts = require('prompts');
const { readFile, writeFile, lstatSync, readdirSync } = require('fs')
const { join } = require('path');
const util = require('util');
const homedir = require('os').homedir();
const { exit } = require("process");

const readFileFS = util.promisify(readFile);
const writeFileFS = util.promisify(writeFile);

let globalInfo = '# created by "rit cron create" command';

const isDirectory = source => {
    return lstatSync(source).isDirectory();
};

const isVisible = source => {
    return source[0] !== '.';
};

const getDirectories = (source) => {
    return readdirSync(source).filter(isVisible).map(name => join(source, name)).filter(isDirectory);
};

const isFormula = async (dir) => {
    let files;
    try {
        files = readdirSync(dir).filter(isVisible).map(name => join(dir, name));
    } catch (err) {
      console.log(err);
    }

    let requireds = [
        { name: 'Makefile', isDirectory: false },
        { name: 'config.json', isDirectory: false },
        { name: 'src', isDirectory: true }
    ];

    let requiredChecks = 0;
    let satisfied = false;
    
    for (let i = 0; i < files.length; i++) {        
        for (let y = 0; y < requireds.length; y++) {
            
            let fileName = files[i].split('/').pop();
            
            if (requireds[y].name == fileName && isDirectory(files[i]) == requireds[y].isDirectory) {
                satisfied = true;
                break;
            }
        }

        if (satisfied) {
            requiredChecks++;
            satisfied = false;
        }
    }

    return requiredChecks == requireds.length;
};

async function askCommand() {
    // Select workspace
    let workspaces;
    try {
        formulaWorkspacesJson = await readFileFS(homedir + '/.rit/formula_workspaces.json', 'utf8');
        workspaces = JSON.parse(formulaWorkspacesJson);
    } catch (err) {
        console.log(err);
    }

    let selectedWorkspace = await prompts({
        type: 'select',
        name: 'value',
        message: 'Select a formula workspace:',
        choices: Object.keys(workspaces).map(item => {
            return { title: item + " ("+ workspaces[item] + ")", value: workspaces[item] };
        })
    });

    // Select formula
    let currentDir = selectedWorkspace;
    while (true) {
        let isFormulaResult = await isFormula(currentDir.value);
        if (isFormulaResult) {
            break;
        }

        folders = getDirectories(currentDir.value);
      
        currentDir = await prompts({
            type: 'select',
            name: 'value',
            message: 'Select a formula or group:',
            choices: folders.map(item => {
                return { title: item.split('/').pop(), value: item }
            })
        });
    }

    let workspaceName = selectedWorkspace.value.split('/').pop();
    let command = currentDir.value.split('/').reduce((total, item, i) => {        
        if (i > currentDir.value.split('/').indexOf(workspaceName)) {
            total += item + ' ';
        }

        return total;
    }, '');

    return 'rit ' + command.trim();
}

const askPeriod = () => {
    return '* * * * *';
}

const writeIntoCrontabFile = async (command, period) => {
    let crontabPath = '/etc/crontab';
    let cronLine = period +' '+ command +' '+ globalInfo;

    try {
        crontabStr = await readFileFS(crontabPath, 'utf8');

        if (crontabStr.indexOf(cronLine) === -1) {
            crontabStr += '\n' + cronLine;
            await writeFileFS(crontabPath, crontabStr, 'utf8');
        } else {
            console.log(clc.yellow('Command "'+ command +'" already exists in crontab'));
            return false;
        }
        
    } catch (err) {
        console.log(err);
    }

    return true;
}

async function Run() {
    let command = await askCommand();
    let period = askPeriod();
    let result = await writeIntoCrontabFile(command, period);

    console.log(result);
}

const formula = Run;
module.exports = formula;
