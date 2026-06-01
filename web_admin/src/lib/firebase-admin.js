import admin from 'firebase-admin';

function loadServiceAccount() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) {
    return null;
  }
  try {
    const serviceAccount = JSON.parse(raw);
    if (serviceAccount.private_key) {
      serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
    }
    return serviceAccount;
  } catch (error) {
    console.error('FIREBASE_SERVICE_ACCOUNT inválido:', error.message);
    return null;
  }
}

if (!admin.apps.length) {
  const serviceAccount = loadServiceAccount();
  if (serviceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  } else if (process.env.NODE_ENV !== 'production') {
    console.warn(
      'Firebase Admin no inicializado: define FIREBASE_SERVICE_ACCOUNT (JSON) en el entorno del servidor.'
    );
  }
}

export const isAdminInitialized = () => admin.apps.length > 0;

export const adminDb = isAdminInitialized() ? admin.firestore() : null;
export const adminAuth = isAdminInitialized() ? admin.auth() : null;
export const adminMessaging = isAdminInitialized() ? admin.messaging() : null;
