import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v2";
import { setGlobalOptions } from "firebase-functions/v2/options";
import { Request, Response } from "express";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onRequest } from "firebase-functions/https";

setGlobalOptions({ region: "asia-northeast3" });

const serviceAccount = require("../firebase_sdk_setting.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://mobility-1997a-default-rtdb.firebaseio.com",
});

const db = admin.database();
const messaging = admin.messaging();

/** 공통 CORS 설정 */
function handleCors(req: Request, res: Response): boolean {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  if (req.method === "OPTIONS") {
    res.status(204).send();
    return true;
  }
  return false;
}

/** NAVER 로그인 처리 */
export const naverLogin = functions.https.onRequest(
  async (req: Request, res: Response): Promise<void> => {
    if (handleCors(req, res)) return;

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
          await admin.auth().createUser({ uid, email, emailVerified: true });
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
      console.error("Naver 로그인 처리 실패:", error);
      res.status(500).json({ error: "Internal Server Error", details: error.message });
    }
  }
);

/** 한국어 날짜 문자열 파싱 */
function parseKoreanDateTime(dateTimeStr: string): Date | null {
  const [date, ampm, time] = dateTimeStr.split(" ");
  if (!date || !ampm || !time) return null;

  let [hour, minute] = time.split(":").map(Number);
  if (ampm === "오후" && hour < 12) hour += 12;
  if (ampm === "오전" && hour === 12) hour = 0;

  const parsed = new Date(`${date}T${hour.toString().padStart(2, "0")}:${minute.toString().padStart(2, "0")}:00+09:00`);
  return isNaN(parsed.getTime()) ? null : parsed;
}

/** 예약 만료 및 경고 자동 처리 */
export const autoDeleteExpiredReservations = onSchedule(
  {
    schedule: "* * * * *",
    region: "asia-northeast3",
    timeZone: "Asia/Seoul",
    retryCount: 3,
  },
  async (): Promise<void> => {
    const now = Date.now();
    const updates: Record<string, null> = {};
    const warningTasks: Promise<void>[] = [];

    // 위치 매핑 테이블
    const LOCATION_MAPPING: Record<string, string> = {
      '조선대학교 IT융합대학' : 'location1',
      '조선대학교 중앙도서관' : 'location2',
      '조선대학교 해오름관' : 'location3'
    }

    const locationSnap = await db.ref("location").once("value");
    const parkedStatus: Record<string, boolean> = {};

    locationSnap.forEach((locSnap)=> {
      const locKey = locSnap.key!;
      if(locSnap.child("parked").exists()) {
        parkedStatus[locKey] = locSnap.child("parked").val();
      }
    })

    const reservationSnap = await db.ref("reservations").once("value");

    reservationSnap.forEach((locSnap) => {
      const reservationLocName = locSnap.key!;
      const locationId = LOCATION_MAPPING[reservationLocName];
      const slots = locSnap.val();

      Object.entries(slots).forEach(async ([timeKey, data]: [string, any]) => {
        if (!data?.expireAt || !data?.beginAt) return;

        // 예약 만료
        if (data.expireAt < now && data.uid) {
          const [date, ...rest] = timeKey.split(" ");
          const time = rest.join(" ");
          updates[`users/${data.uid}/reservations/${date}/${time}`] = null;
        }

        // 입고 확인
        const lateStart = data.beginAt + 10 * 60 * 1000;
        const lateEnd = data.beginAt + 15 * 60 * 1000;
        if(
          now >= data.beginAt &&
          now <= lateStart &&
          parkedStatus[locationId] === true &&
          data.notified !== true &&
          data.uid
        ) {
          const tokenSnap = await admin.database().ref(`users/${data.uid}/fcmToken`).once("value");
          const fcmToken = tokenSnap.val();

          if (fcmToken) {
            await admin.messaging().send({
              token: fcmToken,
              notification: {
                title: "입고 확인 요청",
                body: `${reservationLocName} ${timeKey} 주차가 완료되었습니까?`,
              },
              data: { // 클라이언트에서 처리할 데이터
                type: "arrival_confirmation",
                location: reservationLocName,
                time: timeKey,
                uid: data.uid,
              },
            });
          }

          // 중복 알림 방지
          await admin.database().ref(`reservations/${reservationLocName}/${timeKey}/arrivalNotified`).set(true);
        }
        
        if (
          now >= lateStart &&
          now <= lateEnd &&
          parkedStatus[locationId] === false &&
          data.lateNotified !== true &&
          data.uid
        ) {
          warningTasks.push(handleWarningAndNotify(data.uid, reservationLocName, timeKey, "지각 알림", `${reservationLocName} ${timeKey} 예약 후 10분이 지났지만 아직 주차되지 않았습니다.`, `reservations/${reservationLocName}/${timeKey}/lateNotified`, false, false));
        }

        // 지각 알림 - 경고 후 예약삭제 
        const lateYetStart = data.beginAt + 15 * 60 * 1000;
        const lateYetEnd = data.beginAt + 20 * 60 * 1000;
        if (
          now >= lateYetStart &&
          now <= lateYetEnd &&
          parkedStatus[locationId] === false &&
          data.lateYetNotified !== true &&
          data.uid
        ) {
          warningTasks.push(handleWarningAndNotify(data.uid, reservationLocName, timeKey, "지각 알림", `${reservationLocName} ${timeKey} 예약 후 15분이 지났지만 아직 주차되지 않았습니다.`, `reservations/${reservationLocName}/${timeKey}/lateYetNotified`, true, true));
          updates[`reservations/${reservationLocName}/${timeKey}`] = null;
        }
        
        // 출고 안됨 경고 알림
        const notLeftStart = data.expireAt + 10 * 60 * 1000;
        const notLeftEnd = data.expireAt + 15 * 60 * 1000;
        if (
          now >= notLeftStart &&
          now <= notLeftEnd &&
          parkedStatus[locationId] === true &&
          data.notLeftNotified !== true &&
          data.uid
        ) {
          warningTasks.push(handleWarningAndNotify(data.uid, reservationLocName, timeKey, "출고 미완료 알림", `${reservationLocName} ${timeKey} 예약 종료 후 10분이 지났지만 아직 출고되지 않았습니다.`, `reservations/${reservationLocName}/${timeKey}/notLeftNotified`, false, false));
        }

        // 출고 안됨 삭제 알림
        const notLeftDeleteStart = data.expireAt + 15 * 60 * 1000;
        const notLeftDeleteEnd = data.expireAt + 20 * 60 * 1000;
        if (
          now >= notLeftDeleteStart &&
          now <= notLeftDeleteEnd &&
          parkedStatus[locationId] === true &&
          data.notLeftYetNotified !== true &&
          data.uid
        ) {
          warningTasks.push(handleWarningAndNotify(data.uid, reservationLocName, timeKey, "출고 미완료 알림", `${reservationLocName} ${timeKey} 예약 종료 후 15분이 지났지만 아직 출고되지 않았습니다. 경고가 누적됩니다.`, `reservations/${reservationLocName}/${timeKey}/notLeftYetNotified`, true, true));
          updates[`reservations/${reservationLocName}/${timeKey}`] = null;
          
        }
      });
    });

    // 사용자 예약 만료 확인
    const usersSnap = await db.ref("users").once("value");
    usersSnap.forEach((userSnap) => {
      const uid = userSnap.key!;
      const reservations = userSnap.child("reservations");

      if (reservations.exists()) {
        reservations.forEach((dateSnap) => {
          const dateKey = dateSnap.key!;
          dateSnap.forEach((timeSnap) => {
            const timeKey = timeSnap.key!;
            const fullStr = `${dateKey} ${timeKey}`;
            const parsed = parseKoreanDateTime(fullStr);
            if (parsed && parsed.getTime() < now) {
              updates[`users/${uid}/reservations/${dateKey}/${timeKey}`] = null;
            }
          });
        });
      }
    });

    if (Object.keys(updates).length > 0) {
      await db.ref().update(updates);
      functions.logger.log("만료된 예약 삭제 완료", { deletedCount: Object.keys(updates).length });
    } else {
      functions.logger.log("삭제할 만료된 예약 없음");
    }

    await Promise.all(warningTasks);
  }
);

/** 경고 처리 및 푸시 알림 전송 */
async function handleWarningAndNotify(
  uid: string,
  location: string,
  time: string,
  title: string,
  body: string,
  notifiedPath: string,
  addWarning: boolean,
  shouldDeleteReservation: boolean
): Promise<void> {
  try {
    if (addWarning) {
      await db.ref(`users/${uid}/warnings`).transaction((current) => {
        return (current || 0) + 1;
      });

      await checkWarningsAndBan(uid);
    }

    const tokenSnap = await db.ref(`users/${uid}/fcmToken`).once("value");
    const fcmToken = tokenSnap.val();

    if (fcmToken) {
      await messaging.send({ token: fcmToken, notification: { title, body } });
    }

    // 플래그 저장은 예약 삭제 안 할 때만
    if (!shouldDeleteReservation) {
      await db.ref(notifiedPath).set(true);
    }
  } catch (err) {
    console.error(`알림 또는 경고 처리 실패 (${uid}):`, err);
  }
}


/** 임시 비밀번호 생성 함수 */
function generateRandomPassword(): string {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*";
  return Array.from({ length: 10 }, () => chars.charAt(Math.floor(Math.random() * chars.length))).join("");
}

/** 임시 비밀번호 발급 */
export const generateTempPassword = onRequest(async (req, res) => {
  if (handleCors(req, res)) return;

  const { email, name, phone } = req.body;
  if (!email || !name || !phone) {
    res.status(400).send("email, name, phone 필수");
    return;
  }

  try {
    const user = await admin.auth().getUserByEmail(email);
    const userInfoSnap = await db.ref(`users/${user.uid}/additionalInfo`).once("value");
    const userInfo = userInfoSnap.val();

    if (!userInfo || userInfo.name !== name || userInfo.phone !== phone) {
      res.status(400).send("일치하는 사용자 정보가 없습니다.");
      return;
    }

    const tempPassword = generateRandomPassword();
    await admin.auth().updateUser(user.uid, { password: tempPassword });

    res.status(200).json({ tempPassword });
  } catch (error) {
    console.error("임시 비밀번호 발급 실패:", error);
    res.status(500).send("임시 비밀번호 발급 실패");
  }
});

/** 30분 전 푸시 알림 */
export const sendReservationReminders = onSchedule(
  {
    schedule: "* * * * *",
    timeZone: "Asia/Seoul",
  },
  async () => {
    const now = Date.now();
    const snapshot = await db.ref("reservations").once("value");

    snapshot.forEach((locSnap) => {
      const locKey = locSnap.key!;
      locSnap.forEach((timeSnap) => {
        const timeKey = timeSnap.key!;
        const data = timeSnap.val();
        const beginAt = data?.beginAt;
        if (!beginAt || data?.notified) return;

        const notifyWindowStart = beginAt - 30 * 60 * 1000;
        const notifyWindowEnd = notifyWindowStart + 5 * 60 * 1000;

        if (now >= notifyWindowStart && now <= notifyWindowEnd) {
          const uid = data.uid;
          sendNotification(uid, locKey, timeKey)
            .then(() =>
              db.ref(`reservations/${locKey}/${timeKey}/notified`).set(true)
            )
            .catch((err) => console.error("알림 전송 실패:", err));
        }
      });
    });
  }
);

/** 예약 푸시 알림 전송 */
async function sendNotification(uid: string, location: string, time: string): Promise<void> {
  try {
    const tokenSnap = await db.ref(`users/${uid}/fcmToken`).once("value");
    const fcmToken = tokenSnap.val();

    if (!fcmToken) return;

    await messaging.send({
      token: fcmToken,
      notification: {
        title: "예약 30분 전 알림",
        body: `${location} ${time} 예약이 30분 후 시작됩니다.`,
      },
    });

    console.log(`푸시 알림 전송 완료: ${uid}`);
  } catch (error) {
    console.error("푸시 알림 실패:", error);
  }
}

async function checkWarningsAndBan(uid: string): Promise<void> {
  try {
    console.log(`Checking warnings for user: ${uid}`);
    
    // 경고 횟수 조회
    const warningSnap = await db.ref(`users/${uid}/warnings`).once("value");
    const currentWarnings = warningSnap.exists() ? warningSnap.val() : 0;
    
    console.log(`Current warnings: ${currentWarnings}`);

    if (currentWarnings >= 3) {
      // 차량번호 리스트 조회 (단일 값 또는 배열 모두 처리)
      const carSnap = await db.ref(`users/${uid}/additionalInfo/carNumbers`).once("value");
      const carNumbersData = carSnap.exists() ? carSnap.val() : null;

      let carNumbers: string[] = [];

      if (carNumbersData && typeof carNumbersData === 'object') {
        carNumbers = Object.values(carNumbersData)
                          .filter((v): v is string => typeof v === 'string');
      }
      // 모든 차량번호를 bannedCars에 등록
      if (carNumbers.length > 0) {
        const banUpdates: Record<string, any> = {};
        const banTimestamp = Date.now();
        
        carNumbers.forEach(carNumber => {
          banUpdates[`bannedCars/${carNumber}`] = {
            bannedAt: banTimestamp,
            uid: uid,
          };
        });

        await db.ref().update(banUpdates);
        console.log(`Banned ${carNumbers.length} cars: ${carNumbers.join(', ')}`);
      } else {
        console.log(`No valid car numbers found for user ${uid}`);
      }
    }
  } catch (error) {
    console.error("checkWarningsAndBan error:", error);
    throw error;
  }
}
