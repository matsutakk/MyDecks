/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import * as functions from "firebase-functions";
import * as functions_v1 from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { onFileUpload } from "./functions/server/graph";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

exports.onFileUpload = functions.storage.onObjectFinalized(
  {
    region: "asia-northeast1",
    maxInstances: 100,
    timeoutSeconds: 540,
  },
  onFileUpload,
);

exports.onUserCreate = functions_v1.auth.user().onCreate(async (user) => {
  const userRef = admin.firestore().collection("users").doc(user.uid);
  try {
    const userData = {
      uid: user.uid,
      email: user.email,
      displayName: user.displayName || null,
      photoURL: user.photoURL || null,
      emailVerified: user.emailVerified,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
      nativeLanguage: "ja",
      targetLanguage: "en",
      proficiencyLevel: "intermediate",
      role: "user",
      isActive: true,
      userPreferences: {
        theme: "light",
        language: "ja",
        notifications: true,
      },
    };
    await userRef.set(userData);
    console.log(`Created new user document. UID: ${user.uid}`);
    return null;
  } catch (error) {
    console.error("Error occured(onUserCreate): ", error);
    return null;
  }
});

exports.onUserDelete = functions_v1.auth.user().onDelete(async (user) => {
  console.log(
    `Will clean up user data. UID: ${user.uid}`,
  );

  try {
    await admin
      .firestore()
      .recursiveDelete(admin.firestore().collection("users").doc(user.uid));
    console.log(`Deleted user document. UID: ${user.uid}`);

    const bucket = admin.storage().bucket();
    const [files] = await bucket.getFiles({
      prefix: `users/${user.uid}/`,
    });

    for (const file of files) {
      await file.delete();
      console.log(`Deleted user data in storage: ${file.name}`);
    }

    console.log(`Finished cleaning up of ${user.uid}`);
    return null;
  } catch (error) {
    console.error("Error occured(onUserDelete):", error);
    return null;
  }
});
