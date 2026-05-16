// menu/viewLogs.js
// Interactive container log viewer for the remote VM

const { listContainers } = require('./containerList');

module.exports = async function viewLogs(ctx) {
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
            message: 'Select a container to view logs:',
            choices: containers
        });
        ctx.rl.resume();
        ctx.sh(`ssh -i "${ctx.SSH_KEY_PATH}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${ctx.SSH_USER}@${ctx.VM_IP} "docker logs -f --tail 50 ${service}"`);
        await ctx.pause();
    } catch (e) {
        ctx.rl.resume();
        ctx.setErrorDisplayed(true);
        process.stdout.write('\x1Bc');
        ctx.log('❌ Failed to list containers or view logs.', '\x1b[31m');
        console.error(e.stderr || e.message);
        await ctx.ask('Press Enter to return to the menu...');
    }
};