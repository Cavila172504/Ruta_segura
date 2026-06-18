import fs from 'fs';
import path from 'path';
import admin from 'firebase-admin';

function normalizeServiceAccount(serviceAccount) {
  if (serviceAccount?.private_key) {
    serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
  }
  return serviceAccount;
}

function parseServiceAccountJson(raw) {
  try {
    return normalizeServiceAccount(JSON.parse(raw));
  } catch (error) {
    console.error('FIREBASE_SERVICE_ACCOUNT inválido:', error.message);
    return null;
  }
}

function loadServiceAccountFromFile(filePath) {
  try {
    const absolute = path.isAbsolute(filePath)
      ? filePath
      : path.join(process.cwd(), filePath);
    if (!fs.existsSync(absolute)) {
      console.error(`No se encontró el archivo de cuenta de servicio: ${absolute}`);
      return null;
    }
    const raw = fs.readFileSync(absolute, 'utf8');
    return parseServiceAccountJson(raw);
  } catch (error) {
    console.error('FIREBASE_SERVICE_ACCOUNT_PATH inválido:', error.message);
    return null;
  }
}

function loadServiceAccount() {
  const inline = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (inline?.trim()) {
    return parseServiceAccountJson(inline);
  }

  const filePath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (filePath?.trim()) {
    return loadServiceAccountFromFile(filePath.trim());
  }

  return null;
}

if (!admin.apps.length) {
  const serviceAccount = loadServiceAccount();
  if (serviceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  } else {
    try {
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
      });
      console.info('Firebase Admin: usando Application Default Credentials.');
    } catch (adcError) {
      if (process.env.NODE_ENV !== 'production') {
        console.warn(
          'Firebase Admin no inicializado. En web_admin/.env.local define FIREBASE_SERVICE_ACCOUNT_PATH o FIREBASE_SERVICE_ACCOUNT.',
        );
      } else {
        console.error('Firebase Admin no disponible en producción:', adcError?.message);
      }
    }
  }
}

export const isAdminInitialized = () => admin.apps.length > 0;

export const adminDb = isAdminInitialized() ? admin.firestore() : null;
export const adminAuth = isAdminInitialized() ? admin.auth() : null;
export const adminMessaging = isAdminInitialized() ? admin.messaging() : null;
