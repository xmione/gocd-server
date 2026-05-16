// menu/clearSSHHostKey.js

module.exports = async function clearSSHHostKey(ctx) {
    ctx.log(`Removing cached host key for ${ctx.VM_IP}...`, '\x1b[33m');
    ctx.sh(`ssh-keygen -R ${ctx.VM_IP}`);
    ctx.log('Host key cleared. Next connection will accept the new key.', '\x1b[32m');
    await ctx.pause();
};