const fs = require('fs');
const path = require('path');

const secretsDir = path.join(__dirname, '..', 'secrets');
const envPath = path.join(__dirname, '..', '.env.local');

function listJsonFiles(dir) {
  const results = [];
  if (!fs.existsSync(dir)) return results;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...listJsonFiles(full));
    } else if (entry.isFile() && entry.name.endsWith('.json')) {
      results.push(full);
    }
  }
  return results;
}

const jsonFiles = listJsonFiles(secretsDir);
if (!jsonFiles.length) {
  console.error('No se encontro ningun JSON en web_admin/secrets/');
  process.exit(1);
}

const source = jsonFiles[0];
const targetName = path.basename(source);
const target = path.join(secretsDir, targetName);

if (source === target) {
  console.log('OK El JSON ya esta en la ubicacion correcta:', target);
  process.exit(0);
}

fs.renameSync(source, target);

for (const entry of fs.readdirSync(secretsDir, { withFileTypes: true })) {
  if (!entry.isDirectory()) continue;
  const dirPath = path.join(secretsDir, entry.name);
  if (!fs.readdirSync(dirPath).length) {
    fs.rmdirSync(dirPath);
  }
}

const relPath = `secrets/${targetName}`;
console.log('Movido a:', target);
console.log('Actualiza .env.local con:');
console.log(`FIREBASE_SERVICE_ACCOUNT_PATH=${relPath}`);

if (fs.existsSync(envPath)) {
  const env = fs.readFileSync(envPath, 'utf8');
  if (env.includes('FIREBASE_SERVICE_ACCOUNT_PATH=')) {
    const updated = env.replace(
      /^FIREBASE_SERVICE_ACCOUNT_PATH=.*$/m,
      `FIREBASE_SERVICE_ACCOUNT_PATH=${relPath}`
    );
    fs.writeFileSync(envPath, updated, 'utf8');
    console.log('OK .env.local actualizado');
  }
}
