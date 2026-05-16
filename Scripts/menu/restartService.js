// menu/restartService.js
// Interactive container restart for the remote VM

const { listContainers } = require('./containerList');

module.exports = async function restartService(ctx) {
    try {
        ctx.rl.pause();
        const inquirer = (await import('inquirer')).default;
        const containers = listContainers(ctx);
        if (containers.length === 0) {
            ctx.log('No containers found on VM.', '\x1b[33m');
            ctx.rl.resume();
            await ctx.pause();
            return;
        }
        const { service } = await inquirer.prompt({
            type: 'list',
            name: 'service',
            message: 'Select a container to restart:',
            choices: containers
        });
        ctx.rl.resume();
        ctx.sh(`ssh -i "${ctx.SSH_KEY_PATH}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${ctx.SSH_USER}@${ctx.VM_IP} "docker restart ${service}"`);
        ctx.log(`${service} restarted.`, '\x1b[32m');
        await ctx.pause();
    } catch (e) {
        ctx.rl.resume();
        ctx.setErrorDisplayed(true);
        process.stdout.write('\x1Bc');
        ctx.log('❌ Failed to list containers or restart service.', '\x1b[31m');
        console.error(e.stderr || e.message);
        await ctx.ask('Press Enter to return to the menu...');
    }
};