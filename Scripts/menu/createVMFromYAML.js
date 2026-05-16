// menu/createVMFromYAML.js

const { execSync } = require('child_process');
const fs = require('fs');

module.exports = async function createVMFromYAML(ctx) {
    const yamlFile = await ctx.ask('YAML config file (default: gocd-deploy-target-config.yaml): ') || 'gocd-deploy-target-config.yaml';
    if (!fs.existsSync(yamlFile)) {
        ctx.log(`File not found: ${yamlFile}`, '\x1b[31m');
    } else {
        let vmExists = false;
        try {
            execSync(`gcloud compute instances describe ${ctx.GCP_VM_NAME} --project=${ctx.GCP_PROJECT_ID} --zone=${ctx.GCP_ZONE}`, { stdio: 'pipe' });
            vmExists = true;
        } catch (_) { /* VM does not exist */ }

        if (vmExists) {
            ctx.log(`ℹ️  VM "${ctx.GCP_VM_NAME}" already exists.`, '\x1b[33m');
            ctx.log('    If it needs configuration, proceed with the setup steps below.', '\x1b[33m');
            ctx.log('    To recreate a fresh VM, delete it first (option 6.12) or use 6.14.', '\x1b[33m');
        } else {
            const yaml = fs.readFileSync(yamlFile, 'utf8');
            const machineType = (yaml.match(/machineType:\s*.*\/([^/\s]+)/) || [])[1] || 'e2-medium';
            const image       = (yaml.match(/sourceImage:\s*(.+)/) || [])[1]?.trim() || 'projects/debian-cloud/global/images/family/debian-11';
            const bootDiskSize = (yaml.match(/diskSizeGb:\s*(\d+)/) || [])[1] || '20';
            const network     = (yaml.match(/network:\s*.*\/([^/\s]+)/) || [])[1] || 'default';
            const subnetwork  = (yaml.match(/subnetwork:\s*.*\/([^/\s]+)/) || [])[1] || '';
            const hasExternalIp = yaml.includes('natIP:');
            const externalIPFlag = hasExternalIp ? '' : '--no-address';

            let createCmd = `gcloud compute instances create ${ctx.GCP_VM_NAME}`;
            createCmd += ` --project=${ctx.GCP_PROJECT_ID}`;
            createCmd += ` --zone=${ctx.GCP_ZONE}`;
            createCmd += ` --machine-type=${machineType}`;
            createCmd += ` --image=${image}`;
            createCmd += ` --boot-disk-size=${bootDiskSize}GB`;
            createCmd += ` --network=${network}`;
            if (subnetwork) createCmd += ` --subnet=${subnetwork}`;
            if (externalIPFlag) createCmd += ` ${externalIPFlag}`;

            const result = ctx.sh(createCmd);
            if (result && result.success) {
                ctx.log('VM created from saved settings.', '\x1b[32m');
            } else {
                ctx.log('⚠️  VM creation failed. Check the error above.', '\x1b[31m');
            }
        }

        ctx.log('', '\x1b[36m');
        ctx.log('📋 Recommended next steps for this VM:', '\x1b[33m');
        ctx.log('   6.2  – Configure firewall rules', '\x1b[33m');
        ctx.log('   6.3  – Setup agent SSH keys', '\x1b[33m');
        ctx.log('   6.4  – Install / Verify tools on VM', '\x1b[33m');
        ctx.log('   6.5  – Setup GCP Secret Manager access', '\x1b[33m');
        ctx.log('   6.6  – Check VM reachability', '\x1b[33m');
        ctx.log('', '\x1b[36m');
        ctx.log('💡 Pro tip: Use option 6.15 to run all of them at once.', '\x1b[36m');
        ctx.log('⚠️ Before using option 6.14: The YAML file "gocd-deploy-target-config.yaml" will be overwritten.', '\x1b[33m');
        ctx.log('⚠️ All the existing settings of a fully setup VM will be lost.', '\x1b[33m');
    }
    await ctx.pause();
};