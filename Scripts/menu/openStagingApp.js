// menu/openStagingApp.js

module.exports = async function openStagingApp(ctx) {
    const stagingUrl = `http://${ctx.VM_IP}:8001`;
    ctx.openUrl(stagingUrl);
    ctx.log(`Opening staging app: ${stagingUrl}`, '\x1b[32m');
    await ctx.pause();
};