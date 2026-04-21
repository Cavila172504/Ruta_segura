const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: Enviar push a un token FCM individual
// ─────────────────────────────────────────────────────────────────────────────
async function sendPushToToken(token, title, body, data = {}) {
  try {
    await messaging.send({
      token,
      notification: { title, body },
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channelId: "ruta_segura_alerts",
          priority: "max",
          defaultVibrateTimings: true,
        },
      },
      data: { ...data, click_action: "FLUTTER_NOTIFICATION_CLICK" },
    });
    logger.info(`✅ Push enviado a token: ${token.slice(0, 20)}...`);
  } catch (e) {
    logger.warn(`⚠️ Error enviando push: ${e.message}`);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: Enviar push a un Topic FCM (todos los suscritos al bus)
// ─────────────────────────────────────────────────────────────────────────────
async function sendPushToTopic(topic, title, body, data = {}) {
  try {
    await messaging.send({
      topic,
      notification: { title, body },
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channelId: "ruta_segura_alerts",
          priority: "max",
          defaultVibrateTimings: true,
        },
      },
      data: { ...data, click_action: "FLUTTER_NOTIFICATION_CLICK" },
    });
    logger.info(`✅ Push enviado al topic: ${topic}`);
  } catch (e) {
    logger.warn(`⚠️ Error enviando push al topic: ${e.message}`);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FUNCIÓN 1: Cuando se crea una notificación en Firestore para un padre
// Ruta: users/parents/members/{parentId}/notifications/{notifId}
// Dispara un push al dispositivo del padre aunque la app esté cerrada.
// ─────────────────────────────────────────────────────────────────────────────
exports.onNewParentNotification = onDocumentCreated(
  "users/parents/members/{parentId}/notifications/{notifId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const { parentId } = event.params;
    const notif = snap.data();
    const title = notif.title || "RutaSegura";
    const body = notif.message || notif.body || "";

    // Obtener el token FCM del padre desde su documento de perfil
    const parentRef = db
      .collection("users")
      .doc("parents")
      .collection("members")
      .doc(parentId);

    const parentSnap = await parentRef.get();
    if (!parentSnap.exists) {
      logger.info(`Padre ${parentId} no encontrado`);
      return;
    }

    const fcmToken = parentSnap.data()?.fcmToken;
    if (!fcmToken) {
      logger.info(`Padre ${parentId} sin token FCM`);
      return;
    }

    await sendPushToToken(fcmToken, title, body, { type: notif.type || "general" });
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// FUNCIÓN 2: Cuando el conductor cambia el estado de la ruta a "on_route"
// Ruta: companies/{unitCode}/live_tracking/{driverId}
// Envía un push al topic del bus para que TODOS los padres lo reciban.
// ─────────────────────────────────────────────────────────────────────────────
exports.onRouteStatusChange = onDocumentCreated(
  "companies/{unitCode}/live_tracking/{driverId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const { unitCode } = event.params;
    const data = snap.data();

    if (data?.status !== "on_route") return; // Solo nos interesa cuando inicia

    const routeType = data?.routeType;
    const directionText =
      routeType === "to_school" ? "hacia el colegio 🏫" : "de retorno a casa 🏠";
    const title = "🚌 ¡El bus ha iniciado su recorrido!";
    const body = `Tu transporte escolar ha comenzado su recorrido ${directionText}. Mantente pendiente.`;

    // Enviar push a todos los padres suscritos al topic de esta unidad
    await sendPushToTopic(`bus_${unitCode}`, title, body, {
      type: "trip_started",
      unitCode,
    });
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// FUNCIÓN 3: Guardar el token FCM del padre cuando se actualiza su perfil
// Dispara cuando un padre guarda su token en Firestore.
// (La app flutter debe llamar updateFcmToken al iniciar sesión)
// ─────────────────────────────────────────────────────────────────────────────
exports.onLiveTrackingUpdate = onDocumentCreated(
  "companies/{unitCode}/live_tracking/{driverId}",
  async (event) => {
    // Esta función complementa la anterior para rastrear cambios de posición
    // y guardar el estado del conductor en Firestore para propósitos de auditoría.
    const snap = event.data;
    if (!snap) return;

    const { unitCode, driverId } = event.params;
    logger.info(
      `Tracking actualizado: unitCode=${unitCode}, driverId=${driverId}`
    );
  }
);
