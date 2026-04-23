#!/usr/bin/env node
// Scripts/entrypoint.js
'use strict';

const fs = require('fs');
const crypto = require('crypto');
const { execSync, spawnSync } = require('child_process');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function log(msg) {
  process.stdout.write(`[entrypoint.js] ${msg}\n`);
}

function sh(cmd) {
  return execSync(cmd, { encoding: 'utf8' }).trim();
}

function uuidv4() {
  return crypto.randomUUID ? crypto.randomUUID() : sh('uuidgen');
}

function replaceInFile(filePath, search, replace) {
  const content = fs.readFileSync(filePath, 'utf8');
  fs.writeFileSync(filePath, content.split(search).join(replace));
}

// ---------------------------------------------------------------------------
log('======================================');
log('entrypoint.js is running!');
log(`Node.js version: ${process.version}`);
log(`Working directory: ${process.cwd()}`);
log('======================================');

// ---------------------------------------------------------------------------
// PERSISTENT SERVER ID LOGIC
// ---------------------------------------------------------------------------

log('STEP 1: Checking server ID...');
const SERVER_ID_FILE     = '/godata/.server-id';
const BUILD_TIME_ID_FILE = '/etc/server-id';

fs.mkdirSync('/godata/config', { recursive: true });

if (!fs.existsSync(SERVER_ID_FILE)) {
  log('No server ID found in persistent storage. Generating a new one...');
  if (fs.existsSync(BUILD_TIME_ID_FILE)) {
    fs.writeFileSync(SERVER_ID_FILE, fs.readFileSync(BUILD_TIME_ID_FILE, 'utf8'));
    log('Using build-time server ID and saving to persistent storage.');
  } else {
    fs.writeFileSync(SERVER_ID_FILE, uuidv4());
    log('Generated a new runtime server ID and saved to persistent storage.');
  }
} else {
  log('Using existing server ID from persistent storage.');
}

const SERVER_ID = fs.readFileSync(SERVER_ID_FILE, 'utf8').trim();
log(`Server ID: ${SERVER_ID}`);

// ---------------------------------------------------------------------------
// CONFIG FILE CUSTOMIZATION
// Always recreate cruise-config.xml from the template to ensure
// placeholders are always replaced, even if a stale file exists.
// ---------------------------------------------------------------------------

log('STEP 2: Recreating cruise-config.xml from template...');
const CRUISE_CONFIG   = '/godata/config/cruise-config.xml';
const CRUISE_TEMPLATE = '/tmp/cruise-config.xml.template';

log(`Template exists: ${fs.existsSync(CRUISE_TEMPLATE)}`);

if (!fs.existsSync(CRUISE_TEMPLATE)) {
  log('ERROR: Template file not found at /tmp/cruise-config.xml.template. Exiting.');
  process.exit(1);
}

// Always delete and recreate to avoid stale placeholder issues
if (fs.existsSync(CRUISE_CONFIG)) {
  fs.unlinkSync(CRUISE_CONFIG);
  log('Deleted existing cruise-config.xml.');
}

fs.copyFileSync(CRUISE_TEMPLATE, CRUISE_CONFIG);
log('Template copied successfully.');

replaceInFile(CRUISE_CONFIG, '__SERVER_ID__', SERVER_ID);
log('Injected server ID.');

const { GITHUB_TOKEN, GIT_REPO_PROTOCOL, GIT_REPO_DOMAIN, GIT_REPO_USERNAME,
        GIT_REPO_REPONAME, GIT_PEARL_HELLO_WORLD_REPONAME, GIT_SOLVPN_REPONAME } = process.env;

log('STEP 3: Checking env vars...');
log(`  GIT_REPO_PROTOCOL             : ${GIT_REPO_PROTOCOL || 'MISSING'}`);
log(`  GIT_REPO_DOMAIN               : ${GIT_REPO_DOMAIN || 'MISSING'}`);
log(`  GIT_REPO_USERNAME             : ${GIT_REPO_USERNAME || 'MISSING'}`);
log(`  GITHUB_TOKEN                  : ${GITHUB_TOKEN ? 'SET' : 'MISSING'}`);
log(`  GIT_REPO_REPONAME             : ${GIT_REPO_REPONAME || 'MISSING'}`);
log(`  GIT_PEARL_HELLO_WORLD_REPONAME: ${GIT_PEARL_HELLO_WORLD_REPONAME || 'MISSING'}`);
log(`  GIT_SOLVPN_REPONAME           : ${GIT_SOLVPN_REPONAME || 'MISSING'}`);

if (!GITHUB_TOKEN || !GIT_REPO_PROTOCOL || !GIT_REPO_DOMAIN || !GIT_REPO_USERNAME) {
  log('ERROR: One or more required Git environment variables are missing. Exiting.');
  process.exit(1);
}

const makeUrl = (repo) =>
  `${GIT_REPO_PROTOCOL}://${GITHUB_TOKEN}@${GIT_REPO_DOMAIN}/${GIT_REPO_USERNAME}/${repo}.git`;

log('STEP 4: Injecting Git URLs...');

if (GIT_REPO_REPONAME) {
  replaceInFile(CRUISE_CONFIG, '__GIT_REPO_URL_WITH_CREDENTIALS__', makeUrl(GIT_REPO_REPONAME));
  log('Injected URL for badminton_court.');
} else {
  log('WARNING: GIT_REPO_REPONAME is missing, skipping badminton_court.');
}

if (GIT_PEARL_HELLO_WORLD_REPONAME) {
  replaceInFile(CRUISE_CONFIG, '__PEARL_REPO_URL_WITH_CREDENTIALS__', makeUrl(GIT_PEARL_HELLO_WORLD_REPONAME));
  log('Injected URL for pearl-hello-world.');
} else {
  log('WARNING: GIT_PEARL_HELLO_WORLD_REPONAME is missing, skipping pearl-hello-world.');
}

if (GIT_SOLVPN_REPONAME) {
  replaceInFile(CRUISE_CONFIG, '__SOLVPN_REPO_URL_WITH_CREDENTIALS__', makeUrl(GIT_SOLVPN_REPONAME));
  log('Injected URL for solvpn.');
} else {
  log('WARNING: GIT_SOLVPN_REPONAME is missing, skipping solvpn.');
}

log('Credential injection complete.');

// ---------------------------------------------------------------------------
// PASSWORD CONFIGURATION
// ---------------------------------------------------------------------------

log('STEP 5: Configuring admin password...');
const { GOCD_ADMIN_PASSWORD } = process.env;

if (GOCD_ADMIN_PASSWORD) {
  log('Hashing and writing admin password...');
  const htpasswd = sh(`htpasswd -nbB admin "${GOCD_ADMIN_PASSWORD}"`);
  const hashed   = htpasswd.replace(/^admin:/, '');
  fs.writeFileSync('/godata/config/password.properties', `admin=${hashed}\n`);
  log('Admin password file created/updated.');
} else {
  log('WARNING: GOCD_ADMIN_PASSWORD not set. Using default password.');
}

// ---------------------------------------------------------------------------
// FIX PERMISSIONS
// ---------------------------------------------------------------------------

log('STEP 6: Fixing permissions on /godata/config...');
sh('chown -R 1000:1000 /godata/config');
log('Permissions set.');

// ---------------------------------------------------------------------------
// HAND OFF TO GOCD
// ---------------------------------------------------------------------------

log('STEP 7: Handing off to GoCD via gosu...');
const args   = process.argv.slice(2);
const result = spawnSync('gosu', ['go', '/docker-entrypoint.sh', ...args], { stdio: 'inherit' });

log(`gosu exited with code: ${result.status}`);
process.exit(result.status ?? 0);