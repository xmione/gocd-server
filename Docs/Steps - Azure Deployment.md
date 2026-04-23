# Azure Deployment Steps

This document outlines the steps for deploying GoCD pipelines to Azure VMs using Azure CLI.

## Prerequisites

- Azure CLI installed and authenticated (`az login`).
- Azure VM created with necessary permissions.
- Deploy script (`deploy-script.sh`) prepared on the VM or in the repository.

## Pipeline Configuration

Add the following task to your GoCD pipeline stage:

```xml
<pipeline name="badminton_court">
  <materials>
    <git url="__GIT_REPO_URL_WITH_CREDENTIALS__" branch="master" />
  </materials>
  <stage name="deploy">
    <jobs>
      <job name="deploy_to_azure">
        <tasks>
          <!-- Deploy to Azure VM -->
          <exec command="az">
            <arg>vm</arg>
            <arg>run-command</arg>
            <arg>invoke</arg>
            <arg>--resource-group</arg>
            <arg>your-resource-group</arg>
            <arg>--name</arg>
            <arg>badminton-vm</arg>
            <arg>--command-id</arg>
            <arg>RunShellScript</arg>
            <arg>--scripts</arg>
            <arg>@deploy-script.sh</arg>
          </exec>
        </tasks>
      </job>
    </jobs>
  </stage>
</pipeline>
```

## Steps

1. **Prepare Deploy Script**:
   Create `deploy-script.sh` with deployment commands (e.g., pull code, build, restart services).

2. **Configure Azure VM**:
   - Ensure VM has Azure CLI or necessary tools.
   - Set up SSH keys or authentication.

3. **Update Pipeline**:
   - Replace placeholders: `__GIT_REPO_URL_WITH_CREDENTIALS__`, resource group, VM name.
   - Ensure the agent has Azure CLI installed.

4. **Run Pipeline**:
   Trigger the pipeline in GoCD. The deploy job will execute the Azure CLI command to run the script on the VM.

## Notes

- Use secure credentials for Git URLs.
- Test the deploy script locally first.
- Monitor deployment logs in GoCD and Azure portal.