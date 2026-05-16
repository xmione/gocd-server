// menu/healthCheckStaging.js

module.exports = async function healthCheckStaging(ctx) {
    ctx.log('Performing health check on staging (port 8001)...', '\x1b[33m');
    ctx.sh(`ssh -i "${ctx.SSH_KEY_PATH}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${ctx.SSH_USER}@${ctx.VM_IP} "curl -s -o /dev/null -w '%{http_code}' http://localhost:8001/ || echo 'Failed'"`);
    await ctx.pause();
};