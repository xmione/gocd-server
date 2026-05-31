// Scripts/menu/certDomainStatus.js
module.exports = async function certDomainStatus(ctx) {
  const { execSync, log, ask, pause } = ctx;
  const PROJECT_ID = process.env.GCP_PROJECT_ID;
  if (!PROJECT_ID) {
    log('ERROR: GCP_PROJECT_ID not set.', '\x1b[31m');
    await pause();
    return;
  }

  // 1. Fetch all certificates
  let certs;
  try {
    const raw = execSync(
      `gcloud compute ssl-certificates list --global --project=${PROJECT_ID} --format="json"`,
      { encoding: 'utf8', stdio: 'pipe' }
    );
    certs = JSON.parse(raw);
  } catch (e) {
    log('Failed to fetch certificates.', '\x1b[31m');
    await pause();
    return;
  }

  if (!certs || certs.length === 0) {
    log('No certificates found.', '\x1b[33m');
    await pause();
    return;
  }

  // 2. Show list
  console.log('\n\x1b[36mAvailable certificates:\x1b[0m');
  certs.forEach((cert, i) => {
    console.log(`  [${i + 1}] ${cert.name} (${cert.managed?.status || 'UNKNOWN'})`);
  });

  const choice = await ask('Enter the number of the certificate to inspect: ');
  const idx = parseInt(choice, 10) - 1;
  if (isNaN(idx) || idx < 0 || idx >= certs.length) {
    log('Invalid selection.', '\x1b[31m');
    await pause();
    return;
  }

  const selected = certs[idx];

  // 3. Get detailed domain status
  let details;
  try {
    details = execSync(
      `gcloud compute ssl-certificates describe ${selected.name} --global --project=${PROJECT_ID} --format="json"`,
      { encoding: 'utf8', stdio: 'pipe' }
    );
    details = JSON.parse(details);
  } catch (e) {
    log(`Failed to get details for ${selected.name}.`, '\x1b[31m');
    await pause();
    return;
  }

  console.log(`\n\x1b[36mCertificate: ${selected.name}\x1b[0m`);
  console.log(`  Type: ${details.type}`);
  console.log(`  Overall status: ${details.managed?.status || 'N/A'}`);
  console.log(`  Domains:`);
  if (details.managed && details.managed.domainStatus) {
    for (const [domain, status] of Object.entries(details.managed.domainStatus)) {
      let color = '\x1b[32m';
      if (status === 'PROVISIONING') color = '\x1b[33m';
      if (status.startsWith('FAILED')) color = '\x1b[31m';
      console.log(`    ${domain}: ${color}${status}\x1b[0m`);
    }
  } else {
    console.log('    (no per‑domain status available)');
  }

  await pause();
};