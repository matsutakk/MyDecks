import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { GraphAI, GraphData } from "graphai";
import * as agents from "@graphai/agents";
import { sttOpenaiAgent } from "@graphai/stt_openai_agent";
import * as graph_image from "../graphs/graph_image";
import * as graph_text from "../graphs/graph_text";
import * as graph_audio from "../graphs/graph_audio";
import * as graph_url from "../graphs/graph_url";


// import * as fs from "fs";
import * as path from "path";
import { v4 as uuidv4 } from "uuid";

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();
const bucket = admin.storage().bucket();

interface Translation {
  [language: string]: string;
}

interface Example {
  [language: string]: string;
}

interface SynonymOrAntonym {
  word: string;
}

interface Collocation {
  phrase: string;
  translation: string;
  example: string;
}

interface WordData {
  word: string;
  definition: Translation;
  examples: Example[];
  synonyms: SynonymOrAntonym[];
  antonyms: SynonymOrAntonym[];
  collocations: Collocation[];
  difficulty?: "beginner" | "intermediate" | "advanced";
  [key: string]: any;
}

interface DeckResult {
  result: {
    title: String;
    words: WordData[];
  };
  [key: string]: any;
}

interface UserLanguagePreference {
  nativeLanguage: string;
  targetLanguage: string;
  proficiencyLevel?: string;
}

/**
 * Firebase Storage v2 trigger function for word deck generation
 */
export const onFileUpload = async (event: functions.storage.StorageEvent) => {
  const object = event.data;
  if (!object) return;

  const filePath = object.name;
  if (!filePath) return;

  // Extract user ID from file path (assuming format: users/{userId}/files/{fileName})
  const pathSegments = filePath.split("/");
  let userId: string | null = null;
  if (pathSegments.length >= 3 && pathSegments[0] === "users") {
    userId = pathSegments[1];
  } else {
    console.log("Could not extract userId from path:", filePath);
    return;
  }

  console.log(`Processing file: ${filePath} for user: ${userId}`);

  // Generate a unique ID for the deck set
  const setId = `deck_${Date.now()}_${uuidv4().substring(0, 8)}`;

  try {
    // Fetch user's language preferences
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      throw new Error(`User ${userId} not found`);
    }

    const userData = userDoc.data();
    const userLanguagePrefs: UserLanguagePreference = {
      nativeLanguage: userData?.nativeLanguage || "ja",
      targetLanguage: userData?.targetLanguage || "en",
      proficiencyLevel: userData?.proficiencyLevel || "intermediate",
    };

    // // Create temp file path
    // const tempFilePath = path.join(os.tmpdir(), path.basename(filePath));
    // // Download file to temp location
    // await bucket.file(filePath).download({ destination: tempFilePath });
    // Extract content from file based on file type
    // let content = await extractContentFromFile(tempFilePath, fileType);
    // // Clean up temp file
    // fs.unlinkSync(tempFilePath);

    // fetch content
    const file = bucket.file(filePath);
    const [data] = await file.download();
    const [metadata] = await file.getMetadata();
    let fileType = metadata.metadata?.fileType;
    const fileExtension = path.extname(filePath).toLowerCase();
    if (!fileType) {
      if (metadata.contentType) {
        if (metadata.contentType.startsWith("image/")) {
          fileType = "image";
        } else if (metadata.contentType.startsWith("audio/")) {
          fileType = "audio";
        } else if (metadata.contentType.startsWith("text/")) {
          fileType = "text";
        } else if (
          metadata.contentType === "application/x-www-form-urlencoded"
        ) {
          fileType = "url";
        } else {
          if (
            ["jpg", "jpeg", "png", "gif", "svg", "webp"].includes(fileExtension)
          ) {
            fileType = "image";
          } else if (["mp3", "wav", "ogg", "m4a"].includes(fileExtension)) {
            fileType = "audio";
          } else if (["txt", "md", "csv", "json"].includes(fileExtension)) {
            fileType = "text";
          } else {
            fileType = "unknown";
          }
        }
      } else {
        if (
          ["jpg", "jpeg", "png", "gif", "svg", "webp"].includes(fileExtension)
        ) {
          fileType = "image";
        } else if (["mp3", "wav", "ogg", "m4a"].includes(fileExtension)) {
          fileType = "audio";
        } else if (["txt", "md", "csv", "json"].includes(fileExtension)) {
          fileType = "text";
        } else {
          fileType = "unknown";
        }
      }
    }

    const deckRef = db.collection(`users/${userId}/decks`).doc(setId);
    await deckRef.set(
      {
        sourceFile: filePath,
        fileType: fileType,
        status: "processing",
        languagePreferences: userLanguagePrefs,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    let graph_data: GraphData = {
      version: 0.5,
      nodes: {},
    };

    if (fileType == "image") {
      const url = await bucket.file(filePath).getSignedUrl({
        action: "read",
        expires: Date.now() + 1 * 60 * 1000, // 1 min
      });
      graph_data.nodes = {
        deck: {
          agent: "nestedAgent",
          inputs: {
            nativeLanguage: userLanguagePrefs.nativeLanguage,
            targetLanguage: userLanguagePrefs.targetLanguage,
            proficiencyLevel: userLanguagePrefs.proficiencyLevel,
            imageUrl: url[0],
          },
          isResult: true,
          graph: graph_image.graph,
        },
      };
    } else if (fileType == "audio") {
      graph_data.nodes = {
        deck: {
          agent: "nestedAgent",
          inputs: {
            stream: data,
            nativeLanguage: userLanguagePrefs.nativeLanguage,
            targetLanguage: userLanguagePrefs.targetLanguage,
            proficiencyLevel: userLanguagePrefs.proficiencyLevel,
          },
          isResult: true,
          graph: graph_audio.graph,
        },
      };
    } else if (fileType == "text") {
      graph_data.nodes = {
        deck: {
          agent: "nestedAgent",
          inputs: {
            text: data.toString("utf-8"),
            nativeLanguage: userLanguagePrefs.nativeLanguage,
            targetLanguage: userLanguagePrefs.targetLanguage,
            proficiencyLevel: userLanguagePrefs.proficiencyLevel,
          },
          isResult: true,
          graph: graph_text.graph,
        },
      };
    } else if (fileType == "url") {
      graph_data.nodes = {
        deck: {
          agent: "nestedAgent",
          inputs: {
            url: data.toString("utf-8"),
            nativeLanguage: userLanguagePrefs.nativeLanguage,
            targetLanguage: userLanguagePrefs.targetLanguage,
            proficiencyLevel: userLanguagePrefs.proficiencyLevel,
          },
          isResult: true,
          graph: graph_url.graph,
        },
      };
    } else {
      throw new Error(`invalid fileType: ${fileType}`);
    }

    // Run the AI processing
    const graph = new GraphAI(graph_data, {
        ...agents,
        sttOpenaiAgent
    });
    const result = await graph.run();
    let deckResult: DeckResult = result.deck as DeckResult;

    console.log(deckResult);
    console.log(deckResult.result.words);
    console.log(
      `Successfully processed file ${filePath} and created deck set ${setId} for user ${userId}`,
    );

    // Update Firestore with the generated deck
    await deckRef.update({
      status: "completed",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      title: deckResult.result.title,
    });

    if (
      deckResult.result &&
      deckResult.result.words &&
      Array.isArray(deckResult.result.words) &&
      deckResult.result.words.length > 0
    ) {
      const batch = db.batch();

      for (const wordData of deckResult.result.words) {
        if (typeof wordData === "object" && wordData.word) {
          const wordId = `${setId}_${wordData.word}`;
          const wordRef = db
            .collection(`users/${userId}/decks/${setId}/words`)
            .doc(wordId);

          const firestoreData = {
            word: wordData.word,
            definition: wordData.definition || null,
            examples: wordData.examples || null,
            synonyms: wordData.synonyms || null,
            antonyms: wordData.antonyms || null,
            collocations: wordData.collocations || null,
            difficulty: wordData.difficulty || "intermediate",
            source: setId,
            targetLanguage: userLanguagePrefs.targetLanguage,
            nativeLanguage: userLanguagePrefs.nativeLanguage,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          };

          batch.set(wordRef, firestoreData, { merge: true });
        } else {
          console.warn(`Invalid word data found: ${JSON.stringify(wordData)}`);
        }
      }

      await batch.commit();
      console.log(
        `Created ${deckResult.result.words.length} individual word entries for user ${userId}`,
      );

      await db
        .collection("users")
        .doc(userId)
        .update({
          "stats.totalDeckSets": admin.firestore.FieldValue.increment(1),
          "stats.totalWords": admin.firestore.FieldValue.increment(
            deckResult.result.words.length,
          ),
          "stats.lastActivity": admin.firestore.FieldValue.serverTimestamp(),
        });
    } else {
      console.log("No valid words array found in the result");
    }
  } catch (error: unknown) {
    let errorMessage = "Unknown error";
    if (error instanceof Error) {
      errorMessage = error.message;
      console.error("Error processing file:", error);
    } else if (typeof error === "string") {
      errorMessage = error;
      console.error("Error processing file:", error);
    } else {
      console.error("Unknown error type:", error);
    }
    const deckRef = db.collection(`users/${userId}/decks`).doc(setId);
    await deckRef.update({
      status: "error",
      errorMessage: errorMessage,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
};

// async function extractContentFromFile(
//   filePath: string,
//   fileType: string,
// ): Promise<string> {
//   switch (true) {
//     case fileType === ".txt": {
//       return fs.readFileSync(filePath, "utf8");
//     }
//     case fileType === ".pdf": {
//       const pdfParse = require("pdf-parse");
//       const dataBuffer = fs.readFileSync(filePath);
//       const pdfData = await pdfParse(dataBuffer);
//       return pdfData.text;
//     }
//     case fileType === ".csv": {
//       return fs.readFileSync(filePath, "utf8");
//     }
//     default:
//       return `invalid fileType: ${fileType}`;
//   }
// }
