const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
// Usa el serviceAccount.json si existe, o las credenciales de web_admin
// Necesitamos un service account. El web_admin usa firebase de cliente.
// No puedo ejecutar un script admin de firebase tan facilmente si no tengo la llave.
