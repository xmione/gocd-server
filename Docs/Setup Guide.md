# GoCD Server Setup Guide

This guide provides detailed instructions for setting up and configuring the GoCD server environment.

## Initial Setup

1. **Clone and Navigate**:
   ```bash
   git clone https://github.com/xmione/gocd-server.git
   cd gocd-server
   ```

2. **Install Dependencies**:
   - Ensure Docker and Docker Compose are installed.
   - For Azure deployment, install Azure CLI.

3. **Generate Certificates**:
   Run the certificate generation script to create SSL certificates:
   ```powershell
   .\Scripts\generate-certs.ps1
   ```
   This creates `certs/server.crt`, `certs/server.key`, and other certificate files.

4. **Environment Configuration**:
   - Copy `env.passphrase.txt` and set up encryption for sensitive data.
   - Create `.env.docker` with required environment variables.

5. **Build and Run**:
   ```bash
   npm run go
   ```
   This builds the Docker images and starts the containers.

## Configuration Files

### cruise-config.xml

The main configuration file for GoCD pipelines and server settings.

- **Server Settings**: Auto-registration key, security configurations.
- **Pipelines**: Defined in `<pipelines>` section.
- **Security**: Authentication configs, roles, admins.

### Docker Compose

- **gocd-server**: Main server service with SSL ports 8153/8154.
- **gocd-agent-1/2**: Agents with specific resources and volumes.

## Pipeline Configuration

Pipelines are defined in XML format. Example structure:

```xml
<pipeline name="my-pipeline">
  <materials>
    <git url="https://github.com/user/repo.git" branch="master" />
  </materials>
  <stage name="build">
    <jobs>
      <job name="build_job">
        <resources>
          <resource>docker</resource>
        </resources>
        <tasks>
          <exec command="docker">
            <arg>build</arg>
            <arg>-t</arg>
            <arg>my-image</arg>
            <arg>.</arg>
          </exec>
        </tasks>
      </job>
    </jobs>
  </stage>
</pipeline>
```

## Agent Resources

Agents are tagged with resources for job assignment:

- **docker**: For Docker-related tasks.
- **linux**: General Linux environment.
- **Project-specific**: e.g., pearl-hello-world, badminton_court.

## Security

- SSL enabled on port 8154.
- Password file authentication.
- Admin user: admin (password generated during setup).

## Monitoring and Logs

- Access logs via Docker: `docker-compose logs gocd-server`
- Web UI for pipeline monitoring.
- Use `npm run validate` for environment checks.

## Troubleshooting

- **Container Issues**: Check Docker logs.
- **Pipeline Failures**: Review job logs in GoCD UI.
- **SSL Problems**: Verify certificate paths and permissions.</content>
<parameter name="filePath">c:\repo\gocd-server\Docs/Setup Guide.md