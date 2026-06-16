/**
 * Convierte archivos de config corruptos (UTF-16) a UTF-8 y asegura plantillas locales.
 * Uso: node scripts/fix-config-encoding.js
 */
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');

function readText(filePath) {
  const buf = fs.readFileSync(filePath);
  if (buf.length > 1 && buf[1] === 0) {
    return buf.toString('utf16le').replace(/^\uFEFF/, '');
  }
  return buf.toString('utf8').replace(/^\uFEFF/, '');
}

function writeUtf8(filePath, content) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  const normalized = content.endsWith('\n') ? content : `${content}\n`;
  fs.writeFileSync(filePath, normalized, 'utf8');
}

function ensureFromExample(target, example, transform) {
  if (!fs.existsSync(example)) return;
  let content = fs.existsSync(target) ? readText(target) : readText(example);
  if (transform) content = transform(content);
  writeUtf8(target, content);
  console.log(`OK ${path.relative(root, target)}`);
}

// 1) env.json UTF-8
const envExample = path.join(root, 'env.example.json');
const envJson = path.join(root, 'env.json');
let envData;
if (fs.existsSync(envJson)) {
  envData = JSON.parse(readText(envJson));
} else {
  envData = JSON.parse(readText(envExample));
}
if (!envData.GOOGLE_MAPS_API_KEY || envData.GOOGLE_MAPS_API_KEY === 'TU_CLAVE_GOOGLE_MAPS') {
  console.warn('WARN: Edita env.json y pon tu GOOGLE_MAPS_API_KEY real.');
}
writeUtf8(envJson, JSON.stringify(envData, null, 2));

const mapsKey = envData.GOOGLE_MAPS_API_KEY || 'TU_CLAVE_GOOGLE_MAPS';

// 2) Android / iOS secrets
writeUtf8(
  path.join(root, 'android', 'secrets.properties'),
  `GOOGLE_MAPS_API_KEY=${mapsKey}\n`
);
writeUtf8(
  path.join(root, 'ios', 'Flutter', 'Secrets.xcconfig'),
  `GOOGLE_MAPS_API_KEY=${mapsKey}\n`
);

// 3) web_admin .env.local — fusionar ejemplo + existente
const envExampleWeb = path.join(root, 'web_admin', '.env.example');
const envLocalWeb = path.join(root, 'web_admin', '.env.local');
const parseEnv = (text) => {
  const out = {};
  for (const line of text.split(/\r?\n/)) {
    const t = line.trim();
    if (!t || t.startsWith('#')) continue;
    const i = t.indexOf('=');
    if (i === -1) continue;
    out[t.slice(0, i)] = t.slice(i + 1);
  }
  return out;
};
const stringifyEnv = (obj, template) => {
  const lines = [];
  const used = new Set();
  for (const line of template.split(/\r?\n/)) {
    const t = line.trim();
    if (!t || t.startsWith('#')) {
      lines.push(line);
      continue;
    }
    const i = t.indexOf('=');
    if (i === -1) {
      lines.push(line);
      continue;
    }
    const key = t.slice(0, i);
    used.add(key);
    lines.push(`${key}=${obj[key] ?? ''}`);
  }
  for (const [key, value] of Object.entries(obj)) {
    if (!used.has(key) && value) lines.push(`${key}=${value}`);
  }
  return lines.join('\n');
};

if (fs.existsSync(envExampleWeb)) {
  const template = readText(envExampleWeb);
  const merged = {
    ...parseEnv(template),
    ...(fs.existsSync(envLocalWeb) ? parseEnv(readText(envLocalWeb)) : {}),
  };
  writeUtf8(envLocalWeb, stringifyEnv(merged, template));
  console.log(`OK ${path.relative(root, envLocalWeb)}`);
}

// 4) Normalizar firestore.* si hiciera falta
for (const rel of ['firestore.rules', 'firestore.indexes.json']) {
  const p = path.join(root, rel);
  if (!fs.existsSync(p)) continue;
  const buf = fs.readFileSync(p);
  if (buf.length > 1 && buf[1] === 0) {
    writeUtf8(p, readText(p));
    console.log(`Converted UTF-16 -> UTF-8: ${rel}`);
  }
}

console.log('Config local reparada (UTF-8).');
