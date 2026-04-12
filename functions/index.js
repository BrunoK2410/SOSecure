const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

admin.initializeApp();

/**
 * Triggered when a new SOS signal is created in the 'alerts' collection.
 */
exports.onSosAlert = onDocumentCreated(
    "alerts/{alertId}",
    async (event) => {
      const snapshot = event.data;
      if (!snapshot) {
        logger.error("No data associated with the event");
        return null;
      }

      const alertId = event.params.alertId;
      const alertData = snapshot.data();
      const {senderName, recipientIds} = alertData;

      if (!recipientIds || recipientIds.length === 0) {
        logger.info("No recipients for this alert");
        return null;
      }

      logger.info(`Processing SOS Alert ${alertId} from ${senderName} ` +
                  `for ${recipientIds.length} users`);

      try {
        // 1. Fetch FCM push tokens for each recipient ID
        const tokens = [];
        const userPromises = recipientIds.map((uid) =>
          admin.firestore().collection("users").doc(uid).get(),
        );
        const userSnapshots = await Promise.all(userPromises);

        for (const userDoc of userSnapshots) {
          if (userDoc.exists) {
            const token = userDoc.data().fcmToken;
            if (token) tokens.push(token);
          }
        }

        if (tokens.length === 0) {
          logger.info("None of the recipients have an active FCM token");
          return null;
        }

        // 2. Prepare the Notification Payload
        const message = {
          notification: {
            title: "🚨 EMERGENCY SOS",
            body: `${senderName} has triggered an SOS alert! ` +
                  `Tap to see their location.`,
          },
          data: {
            alertId: alertId,
            senderId: alertData.senderId || "",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          tokens: tokens,
          android: {
            priority: "high",
            notification: {
              channelId: "emergency_alerts_channel",
              priority: "max",
              sound: "default",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        // 3. Send the messages via Multicast (FCM)
        const response = await admin.messaging().sendEachForMulticast(message);
        logger.info(`Alert broadcast complete: ` +
                    `${response.successCount} successful, ` +
                    `${response.failureCount} failed`);

        // Log individual failures for debugging
        if (response.failureCount > 0) {
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              logger.warn(`Failed to send to token ${tokens[idx]}: ` +
                          `${resp.error?.message}`);
            }
          });
        }

        return null;
      } catch (error) {
        logger.error("Error sending SOS notification", error);
        return null;
      }
    });

