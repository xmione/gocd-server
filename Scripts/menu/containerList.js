// menu/containerList.js
// Reusable container listing for the remote VM

const { execSync } = require('child_process');

/**
 * Returns an array of container names (all states) from the remote VM.
 * @param {object} ctx – the shared context (must contain SSH_KEY_PATH, SSH_USER, VM_IP, log, etc.)
 * @returns {string[]} list of container names
 * @throws {Error} if the SSH command fails
 */
function listContainers(ctx) {
    const { execSync: exec, SSH_KEY_PATH, SSH_USER, VM_IP, log } = ctx;
    const sshCmd = `ssh -i "${SSH_KEY_PATH}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${SSH_USER}@${VM_IP} "docker ps -a --format '{{.Names}}'"`;
    const result = exec(sshCmd, { encoding: 'utf8', stdio: 'pipe' });
    return result.trim().split('\n').filter(Boolean);
}

module.exports = { listContainers };