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