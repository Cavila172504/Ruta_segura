import { NextResponse } from 'next/server';
import { adminMessaging, isAdminInitialized } from '@/lib/firebase-admin';
import { verifyApiAuth } from '@/lib/api-auth';

export async function POST(request) {
  const authResult = await verifyApiAuth(request, {
    roles: ['admin', 'super_admin', 'driver'],
  });
  if (authResult.error) return authResult.error;

  try {
    const { topic, token, title, body, data = {}, unitCode } = await request.json();

    if (!title || !body) {
      return NextResponse.json({ error: 'Se requiere title y body' }, { status: 400 });
    }
    if (!topic && !token) {
      return NextResponse.json({ error: 'Se requiere topic o token' }, { status: 400 });
    }
    if (!isAdminInitialized()) {
      return NextResponse.json({ error: 'Firebase Admin no inicializado' }, { status: 503 });
    }

    const { user } = authResult;

    if (user.role === 'driver') {
      const driverUnit = user.profile?.unitCode;
      if (topic) {
        const expectedTopic = `bus_${driverUnit}`;
        if (topic !== expectedTopic) {
          return NextResponse.json({ error: 'Topic no permitido para este conductor' }, { status: 403 });
        }
      }
      if (unitCode && unitCode !== driverUnit) {
        return NextResponse.json({ error: 'unitCode no coincide con tu unidad' }, { status: 403 });
      }
    }

    const messagePayload = {
      notification: { title, body },
      android: {
        priority: 'high',
        ttl: 0,
        notification: {
          sound: 'default',
          channelId: 'ruta_segura_alerts_high_v2',
          priority: 'max',
          visibility: 'PUBLIC',
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
      response = await adminMessaging.send({ ...messagePayload, topic });
    } else {
      response = await adminMessaging.send({ ...messagePayload, token });
    }

    return NextResponse.json({ success: true, messageId: response });
  } catch (error) {
    console.error('Error enviando notificación push:', error.message);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
