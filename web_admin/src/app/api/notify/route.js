import { NextResponse } from 'next/server';
import admin from 'firebase-admin';

// ─── Inicialización de Firebase Admin (igual que en otros routes) ───────────
if (!admin.apps.length) {
    try {
        let serviceAccount;
        const serviceAccountStr = process.env.FIREBASE_SERVICE_ACCOUNT;

        if (serviceAccountStr) {
            serviceAccount = JSON.parse(serviceAccountStr);
        } else {
            const fs = require('fs');
            const path = 'c:/Proyecto/Rutasegura/web_admin/scripts/serviceAccountKey.json';
            serviceAccount = JSON.parse(fs.readFileSync(path, 'utf8'));
        }

        if (serviceAccount) {
            if (serviceAccount.private_key) {
                serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
            }
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            });
        }
    } catch (error) {
        console.error('Error inicializando Firebase Admin:', error.message);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/notify
//
// Cuerpo esperado:
// {
//   "topic": "bus_CAD31",           // (opción A) enviar a todos los padres del bus
//   "token": "fCM_device_token",    // (opción B) enviar a un padre específico
//   "title": "...",
//   "body": "...",
//   "data": { ... }                 // opcional — datos extra para la app
// }
// ─────────────────────────────────────────────────────────────────────────────
export async function POST(request) {
    try {
        const { topic, token, title, body, data = {} } = await request.json();

        if (!title || !body) {
            return NextResponse.json({ error: 'Se requiere title y body' }, { status: 400 });
        }
        if (!topic && !token) {
            return NextResponse.json({ error: 'Se requiere topic o token' }, { status: 400 });
        }
        if (!admin.apps.length) {
            return NextResponse.json({ error: 'Firebase Admin no inicializado' }, { status: 500 });
        }

        // Configuración del mensaje FCM (alta prioridad, compatible Android)
        // IMPORTANTE: channelId DEBE coincidir con el canal creado en Flutter
        const messagePayload = {
            notification: { title, body },
            android: {
                priority: 'high',
                ttl: 0, // Entrega inmediata, sin retraso
                notification: {
                    sound: 'default',
                    channelId: 'ruta_segura_alerts_high_v2', // Debe coincidir con el canal de Flutter
                    priority: 'max',
                    visibility: 'PUBLIC', // Visible en pantalla de bloqueo
                    defaultVibrateTimings: true,
                    notificationCount: 1,
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                },
            },
            data: {
                ...data,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                title,
                body,
            },
        };

        let response;
        if (topic) {
            // Enviar a TODOS los padres suscritos al topic (ej: bus_CAD31)
            response = await admin.messaging().send({ ...messagePayload, topic });
            console.log(`✅ Push enviado al topic "${topic}":`, response);
        } else {
            // Enviar al dispositivo específico de un padre
            response = await admin.messaging().send({ ...messagePayload, token });
            console.log(`✅ Push enviado al token "${token?.slice(0,20)}...":`, response);
        }

        return NextResponse.json({ success: true, messageId: response });

    } catch (error) {
        console.error('Error enviando notificación push:', error.message);
        return NextResponse.json({ error: error.message }, { status: 500 });
    }
}
