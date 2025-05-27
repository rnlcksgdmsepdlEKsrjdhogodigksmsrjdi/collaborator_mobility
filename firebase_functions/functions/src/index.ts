import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v2";
import { setGlobalOptions } from "firebase-functions/v2/options";
import { Request, Response } from "express";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onRequest } from "firebase-functions/https";

// Firebase 기본 설정
setGlobalOptions({ region: "asia-northeast3" });
const serviceAccount = require("../firebase_sdk_setting.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://mobility-1997a-default-rtdb.firebaseio.com",
});

const db = admin.database();
const messaging = admin.messaging();

/** Naver 로그인 처리 */
export const naverLogin = functions.https.onRequest(
  async (req: Request, res: Response): Promise<void> => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST");

    if (req.method === "OPTIONS") {
      res.status(204).send();
      return;
    }

    const { naverId, email, accessToken } = req.body;
    if (!naverId || !email || !accessToken) {
      res.status(400).json({ error: "Missing required fields" });
      return;
    }

    const uid = `naver:${naverId}`;

    try {
      try {
        await admin.auth().getUser(uid);
      } catch (error: any) {
        if (error.code === "auth/user-not-found") {
          await admin.auth().createUser({
            uid,
            email,
            emailVerified: true,
          });
        } else {
          throw error;
        }
      }

      const customToken = await admin.auth().createCustomToken(uid, {
        provider: "naver",
        accessToken,
      });

      res.status(200).json({ customToken });
    } catch (error: any) {
      console.error("Error:", error);
      res.status(500).json({
        error: "Internal server error",
        details: error.message || String(error),
      });
    }
  }
);

interface ReservationData {
  expireAt?: number;
  uid?: string;
}

/** 만료된 예약 자동 삭제 */
export const autoDeleteExpiredReservations = onSchedule(
  {
    schedule: "0 */4 * * *",
    region: "asia-northeast3",
    timeZone: "Asia/Seoul",
    retryCount: 3,
  },
  async (): Promise<void> => {
    const now = new Date();
    const updates: Record<string, null> = {};

    const globalSnapshot = await db.ref("reservations").once("value");

    globalSnapshot.forEach((locationSnap) => {
      const locationKey = locationSnap.key;
      const timeSlots: Record<string, ReservationData> = locationSnap.val();

      Object.entries(timeSlots).forEach(([timeKey, data]) => {
        if (data?.expireAt && data.expireAt < Date.now()) {
          updates[`reservations/${locationKey}/${timeKey}`] = null;

          if (data.uid) {
            const [datePart, ...rest] = timeKey.split(" ");
            const timePart = rest.join(" ");
            updates[`users/${data.uid}/reservations/${datePart}/${timePart}`] = null;
          }
        }
      });
    });

    const usersSnapshot = await db.ref("users").once("value");

    usersSnapshot.forEach((userSnap) => {
      const uid = userSnap.key;
      const reservations = userSnap.child("reservations");

      if (reservations.exists()) {
        reservations.forEach((dateSnap) => {
          const dateKey = dateSnap.key;
          dateSnap.forEach((timeSnap) => {
            const timeKey = timeSnap.key;

            const dateTimeStr = `${dateKey} ${timeKey}`;
            const parsedDate = parseKoreanDateTime(dateTimeStr);
            if (parsedDate && parsedDate < now) {
              updates[`users/${uid}/reservations/${dateKey}/${timeKey}`] = null;
            }
          });
        });
      }
    });

    if (Object.keys(updates).length > 0) {
      await db.ref().update(updates);
      functions.logger.log("만료된 예약 삭제 완료", {
        deletedCount: Object.keys(updates).length,
      });
    } else {
      functions.logger.log("삭제할 만료된 예약 없음");
    }
  }
);

/** 한국어 날짜 파싱 */
function parseKoreanDateTime(dateTimeStr: string): Date | null {
  const [date, ampm, time] = dateTimeStr.split(" ");
  if (!date || !ampm || !time) return null;

  let [hour, minute] = time.split(":").map(Number);
  if (ampm === "오후" && hour < 12) hour += 12;
  if (ampm === "오전" && hour === 12) hour = 0;

  const parsed = new Date(
    `${date}T${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}:00+09:00`
  );
  return isNaN(parsed.getTime()) ? null : parsed;
}

/** 임시 비밀번호 발급 */
export const generateTempPassword = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");

  if (req.method === "OPTIONS") {
    res.status(204).send();
    return;
  }

  const { email, name, phone } = req.body;
  if (!email || !name || !phone) {
    res.status(400).send("email, name, phone 필수");
    return;
  }

  try {
    const userRecord = await admin.auth().getUserByEmail(email);
    const uid = userRecord.uid;

    const userSnapshot = await db.ref(`users/${uid}/additionalInfo`).once("value");
    const userData = userSnapshot.val();

    if (!userData || userData.name !== name || userData.phone !== phone) {
      res.status(400).send("일치하는 사용자 정보가 없습니다.");
      return;
    }

    const tempPassword = generateRandomPassword();
    await admin.auth().updateUser(uid, { password: tempPassword });

    res.status(200).json({ tempPassword });
  } catch (error) {
    console.error("임시 비밀번호 발급 실패:", error);
    res.status(500).send("임시 비밀번호 발급 실패");
  }
});

/** 임시 비밀번호 생성 */
function generateRandomPassword(): string {
  const chars =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*";
  let password = "";
  for (let i = 0; i < 10; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
}

/** 30분 전 예약 푸시 알림 */
export const sendReservationReminders = onSchedule(
  {
    schedule: "every 30 minutes",
    timeZone: "Asia/Seoul",
  },
  async () => {
    const now = Date.now();
    const snapshot = await db.ref("reservations").once("value");

    snapshot.forEach((locationSnap) => {
      const locationKey = locationSnap.key!;
      locationSnap.forEach((timeSnap) => {
        const timeKey = timeSnap.key!;
        const reservation = timeSnap.val();
        const expireAt = reservation.expireAt;
        const thirtyMinutesBefore = expireAt - 30 * 60 * 1000;

        const alreadyNotified = reservation.notified;

        if (
          !alreadyNotified &&
          now >= thirtyMinutesBefore &&
          now <= thirtyMinutesBefore + 5 * 60 * 1000
        ) {
          const uid = reservation.uid;

          sendNotification(uid, locationKey, timeKey)
            .then(() => {
              // 알림 보낸 뒤 notified true로 표시
              return db.ref(`reservations/${locationKey}/${timeKey}/notified`).set(true);
            })
            .catch((error) => {
              console.error("알림 전송 실패:", error);
            });
        }
      });
    });
  }
);


/** 푸시 알림 전송 */
async function sendNotification(
  uid: string,
  location: string,
  time: string
): Promise<void> {
  try {
    const tokenSnap = await db.ref(`users/${uid}/fcmToken`).once("value");
    const fcmToken = tokenSnap.val();

    if (!fcmToken) return;

    const message = {
      token: fcmToken,
      notification: {
        title: "예약 30분 전 알림",
        body: `${location} ${time} 예약이 30분 후 시작됩니다.`,
      },
    };

    await messaging.send(message);
    console.log(`Notification sent to ${uid}`);
  } catch (error) {
    console.error("Failed to send notification:", error);
  }
}
