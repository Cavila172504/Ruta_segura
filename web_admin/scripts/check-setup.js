const fs = require('fs');
const path = require('path');

require('dotenv').config({ path: path.join(__dirname, '..', '.env.local') });

const root = path.join(__dirname, '..');
let ok = true;

function fail(msg) {
  console.error('X', msg);
  ok = false;
}

function pass(msg) {
  console.log('OK', msg);
}

const requiredPublic = [
  'NEXT_PUBLIC_FIREBASE_API_KEY',
  'NEXT_PUBLIC_FIREBASE_PROJECT_ID',
];

for (const key of requiredPublic) {
  if (process.env[key]) pass(`${key} definido`);
  else fail(`Falta ${key} en .env.local`);
}

const inline = process.env.FIREBASE_SERVICE_ACCOUNT?.trim();
const filePath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH?.trim();

if (inline) {
  try {
    JSON.parse(inline);
    pass('FIREBASE_SERVICE_ACCOUNT (JSON inline) valido');
  } catch {
    fail('FIREBASE_SERVICE_ACCOUNT no es JSON valido');
  }
} else if (filePath) {
  const abs = path.isAbsolute(filePath) ? filePath : path.join(root, filePath);
  if (fs.existsSync(abs)) pass(`Archivo de cuenta de servicio: ${abs}`);
  else {
    fail(`No existe el archivo: ${abs}`);
    console.error('  Firebase Console -> Service accounts -> Generate new private key');
    console.error('  Guardalo en web_admin/secrets/ y actualiza FIREBASE_SERVICE_ACCOUNT_PATH');
  }
} else {
  fail('Falta FIREBASE_SERVICE_ACCOUNT o FIREBASE_SERVICE_ACCOUNT_PATH');
}

console.log('');
if (ok) {
  console.log('Listo para: npm run dev');
  console.log('Prueba: http://localhost:3000/api/health');
} else {
  console.log('Corrige los puntos anteriores y reinicia npm run dev');
  process.exit(1);
}