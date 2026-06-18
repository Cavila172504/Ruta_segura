const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

const FCM_CHANNEL_ID = "ruta_segura_alerts_high_v2";

async function sendPushToToken(token, title, body, data = {}) {
  try {
    await messaging.send({
      token,
      notification: { title, body },
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channelId: FCM_CHANNEL_ID,
          priority: "max",
          defaultVibrateTimings: true,
        },
      },
      data: { ...data, click_action: "FLUTTER_NOTIFICATION_CLICK" },
    });
    logger.info(`Push enviado a token: ${token.slice(0, 20)}...`);
  } catch (e) {
    logger.warn(`Error enviando push: ${e.message}`);
  }
}

async function sendPushToTopic(topic, title, body, data = {}) {
  try {
    await messaging.send({
      topic,
      notification: { title, body },
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channelId: FCM_CHANNEL_ID,
          priority: "max",
          defaultVibrateTimings: true,
        },
      },
      data: { ...data, click_action: "FLUTTER_NOTIFICATION_CLICK" },
    });
    logger.info(`Push enviado al topic: ${topic}`);
  } catch (e) {
    logger.warn(`Error enviando push al topic: ${e.message}`);
  }
}

exports.onNewParentNotification = onDocumentCreated(
  "users/parents/members/{parentId}/notifications/{notifId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const { parentId } = event.params;
    const notif = snap.data();
    const title = notif.title || "RutaSegura";
    const body = notif.message || notif.body || "";

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

exports.onRouteStatusChange = onDocumentUpdated(
  "companies/{unitCode}/live_tracking/{driverId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after) return;

    if (before.status === after.status) return;
    if (after.status !== "on_route") return;

    const { unitCode } = event.params;
    const routeType = after.routeType;
    const directionText =
      routeType === "to_school" ? "hacia el colegio 🏫" : "de retorno a casa 🏠";
    const title = "🚌 ¡El bus ha iniciado su recorrido!";
    const body = `Tu transporte escolar ha comenzado su recorrido ${directionText}. Mantente pendiente.`;

    await sendPushToTopic(`bus_${unitCode}`, title, body, {
      type: "trip_started",
      unitCode,
    });
  }
);

exports.resetDailyAttendance = onSchedule(
  {
    schedule: "0 1 * * *",
    timeZone: "America/Guayaquil",
  },
  async () => {
    logger.info("Iniciando reinicio diario de asistencias...");

    try {
      const studentsSnap = await db.collectionGroup("students").get();

      let batch = db.batch();
      let batchCount = 0;
      let resetCount = 0;

      for (const docSnap of studentsSnap.docs) {
        const data = docSnap.data();
        if (data.attendance_status) {
          const now = new Date();
          const dateKey = now.toLocaleDateString("en-CA", { timeZone: "America/Guayaquil" });
          const reportCode =
            ["absent_today", "absent"].includes(data.attendance_status) ? "F" :
            ["arrived_at_school", "in_bus", "dropped_off_at_home", "present"].includes(data.attendance_status) ? "P" :
            "-";

          if (reportCode !== "-") {
            const logId = `${docSnap.id}_${dateKey}`;
            batch.set(
              docSnap.ref.parent.parent.collection("attendance_logs").doc(logId),
              {
                studentId: docSnap.id,
                studentName: data.studentName || "",
                grade: data.grade || "",
                driverId: data.driverId || "",
                date: dateKey,
                status: data.attendance_status,
                reportCode,
                source: "system",
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              },
              { merge: true }
            );
            batchCount++;
          }

          batch.update(docSnap.ref, {
            attendance_status: admin.firestore.FieldValue.delete(),
          });
          batchCount++;
          resetCount++;

          if (batchCount >= 400) {
            await batch.commit();
            batch = db.batch();
            batchCount = 0;
          }
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      logger.info(`Reinicio completado. Se limpiaron ${resetCount} registros.`);
    } catch (error) {
      logger.error("Error en el cron job de reinicio:", error);
    }
  }
);
