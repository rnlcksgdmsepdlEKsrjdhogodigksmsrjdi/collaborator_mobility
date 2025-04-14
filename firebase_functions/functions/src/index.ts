/* 
Firebase Functions 관련 함수 지정 
건들지 말아주세요
*/

import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { setGlobalOptions } from "firebase-functions/v2/options";
import { Request, Response } from "express";

// Firebase functions을 위해 IAM 지역 / functions 지역 동기화
setGlobalOptions({ region: "asia-northeast3" });
const serviceAccount = require("../mobility-1997a-firebase-adminsdk-fbsvc-971110be01.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

export const naverLogin = functions.https.onRequest(
  async (req: Request, res: Response): Promise<void> => {
    // CORS 설정
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST");

    // 1. Preflight 요청 처리
    if (req.method === "OPTIONS") {
      res.status(204).send();
      return;
    }

    // 2. 파라미터 검증
    const { naverId, email, accessToken } = req.body;
    if (!naverId || !email || !accessToken) {
      res.status(400).json({ error: "Missing required fields" });
      return;
    }

    const uid = `naver:${naverId}`;

    try {
      // 3. 사용자 조회/생성 (에러 코드 문자열로 직접 비교)
      try {
        await admin.auth().getUser(uid);
      } catch (error: unknown) {
        if (error instanceof Error && 'code' in error && error.code === 'auth/user-not-found') {
          await admin.auth().createUser({
            uid,
            email,
            emailVerified: true
          });
        } else {
          throw error;
        }
      }

      // 4. 커스텀 토큰 생성
      const customToken = await admin.auth().createCustomToken(uid, {
        provider: "naver",
        accessToken
      });

      res.status(200).json({ customToken });
    } catch (error: unknown) {
      console.error("Error:", error);
      res.status(500).json({ 
        error: "Internal server error",
        details: error instanceof Error ? error.message : String(error)
      });
    }
  }
);