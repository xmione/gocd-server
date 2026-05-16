// menu/triggerPipeline.js
// Handles pipeline trigger (option 2.1) with optional VM container check

const fs = require('fs');
const path = require('path');
const { listContainers } = require('./containerList');

module.exports = async function triggerPipeline(ctx) {
    const { execSync: exec, log, setErrorDisplayed, GOCD_BASE, PROJECT_ROOT,
            SSH_KEY_PATH, SSH_USER, VM_IP } = ctx;
    const inquirer = (await import('inquirer')).default;
    ctx.rl.pause();

    // 1. Read pipeline names from cruise-config.xml
    const configPath = path.join(__dirname, '..', '..', 'config', 'cruise-config.xml');
    let pipelines = [];
    try {
        const xml = fs.readFileSync(configPath, 'utf8');
        const regex = /<pipeline\s+[^>]*name\s*=\s*["']([^"']+)["'][^>]*>/gi;
        let match;
        while ((match = regex.exec(xml)) !== null) pipelines.push(match[1]);
    } catch (e) {
        ctx.rl.resume();
        setErrorDisplayed(true);
        process.stdout.write('\x1Bc');
        log('❌ Could not read cruise-config.xml.', '\x1b[31m');
        console.error(e.message);
        await inquirer.prompt({ type: 'input', name: 'dummy', message: 'Press Enter to return to the menu...' });
        return;
    }
    if (pipelines.length === 0) {
        ctx.rl.resume();
        setErrorDisplayed(true);
        process.stdout.write('\x1Bc');
        log('No pipelines found in cruise-config.xml.', '\x1b[31m');
        await inquirer.prompt({ type: 'input', name: 'dummy', message: 'Press Enter to return to the menu...' });
        return;
    }

    // 2. Always ask for a fresh cookie
    log('🔐 A GoCD session cookie is required for every trigger.', '\x1b[33m');
    log('   Open http://localhost:8153/go/pipelines, log in, F12 → Application → Cookies.', '\x1b[33m');
    log('   Copy the value of the JSESSIONID cookie.', '\x1b[33m');
    const { cookie } = await inquirer.prompt({
        type: 'input', name: 'cookie', message: 'Paste JSESSIONID:'
    });
    const sessionCookie = (cookie || '').trim();
    if (!sessionCookie) {
        ctx.rl.resume();
        setErrorDisplayed(true);
        process.stdout.write('\x1Bc');
        log('❌ No cookie – cannot trigger.', '\x1b[31m');
        await inquirer.prompt({ type: 'input', name: 'dummy', message: 'Press Enter to return to the menu...' });
        return;
    }

    // ----- Optional: interactive container check (same as 6.16) -----
    try {
        const { doCheck } = await inquirer.prompt({
            type: 'confirm',
            name: 'doCheck',
            message: 'Check VM containers before triggering?',
            default: true
        });
        if (doCheck) {
            const containers = listContainers(ctx);
            if (containers.length === 0) {
                log('⚠ No containers found on VM – the pipeline may fail.', '\x1b[33m');
            } else {
                const { chosenContainer } = await inquirer.prompt({
                    type: 'list',
                    name: 'chosenContainer',
                    message: 'Select a container to view its state:',
                    choices: containers
                });
                // Show the last 10 lines of the chosen container's log
                const logCmd = `ssh -i "${SSH_KEY_PATH}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${SSH_USER}@${VM_IP} "docker logs --tail 10 ${chosenContainer}"`;
                const logResult = exec(logCmd, { encoding: 'utf8', stdio: 'pipe' });
                console.log(logResult);
            }
            await inquirer.prompt({ type: 'input', name: 'dummy', message: 'Press Enter to continue...' });
        }
    } catch (e) {
        log('⚠ Could not check VM containers. Proceeding anyway.', '\x1b[33m');
        console.error(e.stderr || e.message);
        await inquirer.prompt({ type: 'input', name: 'dummy', message: 'Press Enter to continue...' });
    }

    // 3. Choose pipeline
    const { selectedPipeline } = await inquirer.prompt({
        type: 'list', name: 'selectedPipeline',
        message: 'Select a pipeline to trigger:', choices: pipelines
    });
    ctx.rl.resume();

    // 4. Trigger exactly like the manual command
    const url = GOCD_BASE + '/go/api/pipelines/' + selectedPipeline + '/schedule';
    const curlCmd = `docker exec gocd-server curl -s -H "Accept: application/vnd.go.cd.v1+json" -H "Content-Type: application/json" -H "X-GoCD-Confirm: true" -b "JSESSIONID=${sessionCookie}" -X POST -d "{\\"isTrusted\\":true}" "${url}"`;

    try {
        const result = exec(curlCmd, { encoding: 'utf8', stdio: 'pipe', cwd: PROJECT_ROOT });
        if (result.includes('accepted')) {
            log('✅ Pipeline ' + selectedPipeline + ' triggered.', '\x1b[32m');
            await inquirer.prompt({ type: 'input', name: 'dummy', message: 'Press Enter to continue...' });
        } else {
            throw new Error(result.trim());
        }
    } catch (err) {
        setErrorDisplayed(true);
        process.stdout.write('\x1Bc');
        log('❌ Failed to trigger pipeline.', '\x1b[31m');
        console.error(err.stderr || err.message || err.toString());
        await inquirer.prompt({ type: 'input', name: 'dummy', message: 'Press Enter to return to the menu...' });
    }
};