import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions";

admin.initializeApp();

const resendApiKey = defineSecret("RESEND_API_KEY");
const fromEmail = defineSecret("MILEMAID_FROM_EMAIL");

/**
 * When the app queues users/{uid}/mail_outbox/{id} with status=pending,
 * send the message via Resend and mark the doc sent or failed.
 *
 * Deploy:
 *   firebase functions:secrets:set RESEND_API_KEY
 *   firebase functions:secrets:set MILEMAID_FROM_EMAIL
 *   cd functions && npm i && npm run deploy
 */
export const sendMailOutbox = onDocumentCreated(
  {
    document: "users/{uid}/mail_outbox/{mailId}",
    secrets: [resendApiKey, fromEmail],
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data();
    if (data.status !== "pending") return;

    const to = String(data.to ?? "");
    const subject = String(data.subject ?? "MileMaid");
    const body = String(data.body ?? "");
    if (!to || !body) {
      await snap.ref.update({ status: "failed", error: "missing to/body" });
      return;
    }

    const key = resendApiKey.value();
    const from = fromEmail.value() || "MileMaid <noreply@milemaid.app>";
    if (!key) {
      await snap.ref.update({
        status: "failed",
        error: "RESEND_API_KEY not configured",
      });
      return;
    }

    try {
      const res = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${key}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from,
          to: [to],
          subject,
          text: body,
        }),
      });
      if (!res.ok) {
        const errText = await res.text();
        logger.error("Resend failed", { status: res.status, errText });
        await snap.ref.update({ status: "failed", error: errText });
        return;
      }
      await snap.ref.update({
        status: "sent",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.error("sendMailOutbox error", e);
      await snap.ref.update({
        status: "failed",
        error: e instanceof Error ? e.message : String(e),
      });
    }
  }
);
