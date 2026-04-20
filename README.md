# GoCD Server Setup

This repository provides a Docker-based setup for running a GoCD (Go Continuous Delivery) server with multiple agents. It automates the creation and management of CI/CD pipelines for various projects, including building Docker images, running containers, and deploying applications to cloud platforms like Azure.

## What This Application Does

GoCD is an open-source continuous delivery tool that helps automate the build, test, and deployment processes. This setup includes:

- **GoCD Server**: The central server that manages pipelines, agents, and configurations.
- **GoCD Agents**: Worker nodes that execute the pipeline jobs. Two agents are configured with different resources (e.g., for different projects).
- **Pre-configured Pipelines**: Sample pipelines for projects like "pearl-hello-world" (a simple web app) and "badminton_court" (with Azure deployment).
- **SSL/TLS Support**: Secure communication using certificates.
- **Docker Integration**: Agents can build and run Docker containers.
- **Scripts for Management**: PowerShell and shell scripts for setup, validation, and deployment.

The application is designed for developers and DevOps teams to quickly spin up a GoCD environment for continuous integration and deployment workflows.

## Prerequisites

- Docker and Docker Compose installed on your system.
- Git for cloning repositories.
- PowerShell (for Windows users) or Bash (for Linux/Mac).
- Azure CLI (if deploying to Azure).
- Node.js and npm (if needed for project builds).

## Installation and Setup

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/xmione/gocd-server.git
   cd gocd-server
   ```

2. **Generate Certificates**:
   Run the certificate generation script:
   ```bash
   # On Windows
   .\Scripts\generate-certs.ps1

   # On Linux/Mac
   ./Scripts/generate-certs.sh
   ```

3. **Set Up Environment Variables**:
   Create a `.env.docker` file with necessary environment variables (e.g., passwords, tokens). Use the provided `env.passphrase.txt` for encryption if needed.

4. **Build and Start the Containers**:
   Use the npm script or Docker Compose directly:
   ```bash
   npm run go
   # or
   docker-compose up --build
   ```

5. **Access the GoCD Server**:
   - Web UI: http://localhost:8153
   - SSL: https://localhost:8154
   - Default admin credentials: Check the generated password file or use the `getadminpassword.ps1` script.

## Usage

### Managing the Environment

- **Validate Setup**: `npm run validate`
- **View Errors**: `npm run geterror`
- **Open Management Menu**: `npm run menu`
- **Print Folder Structure**: `npm run pfs`

### Pipelines

The setup includes sample pipelines:

- **pearl-hello-world**: Builds and runs a simple Docker container, performs health checks.
- **badminton_court**: Builds the project and deploys to Azure VM.

To customize pipelines, edit `config/cruise-config.xml`.

### Agents

Agents are configured to auto-register with the server. Resources include:
- Agent 1: docker, linux, pearl-hello-world
- Agent 2: docker, linux, badminton_court

## Configuration

- **Server Config**: `config/cruise-config.xml` - Defines pipelines, security, and server settings.
- **Docker Compose**: `docker-compose.yml` - Services, ports, volumes.
- **Certificates**: `certs/` - SSL certificates for secure communication.
- **Scripts**: `Scripts/` - Automation scripts for various tasks.

## Deployment

### Local Development

Run `docker-compose up` to start the services locally.

### Azure Deployment

Refer to `Docs/Steps - Azure Deployment.md` for deploying pipelines to Azure VMs using Azure CLI.

Example pipeline task:
```xml
<exec command="az">
  <arg>vm</arg>
  <arg>run-command</arg>
  <arg>invoke</arg>
  <!-- ... additional args -->
</exec>
```

## Troubleshooting

- Check container logs: `docker-compose logs`
- Validate environment: `npm run validate`
- Get errors: `npm run geterror`

## Contributing

1. Fork the repository.
2. Create a feature branch.
3. Make changes and test.
4. Submit a pull request.

## License

ISC License - See package.json for details.

## Author

Solomio S. Sisante

## Repository

[https://github.com/xmione/gocd-server](https://github.com/xmione/gocd-server)</content>
<parameter name="filePath">c:\repo\gocd-server\README.md