// import {
//   AgentFilterInfo,
//   AgentFunctionContext,
//   GraphAI,
//   GraphData,
// } from "graphai";
// import * as agents from "@graphai/agents";
// import "dotenv/config";
// import { streamAgentFilterGenerator } from "@graphai/agent_filters";
// import * as fs from "fs";

// interface DbClient {
//   putWord(wordLine: string): Promise<void>;
// }

// class FileDbClient implements DbClient {
//   private filePath: string;
//   private isHeaderWritten: boolean = false;

//   constructor(filePath: string = "./words_db.csv") {
//     this.filePath = filePath;
//     if (!fs.existsSync(filePath)) {
//       this.isHeaderWritten = false;
//     } else {
//       this.isHeaderWritten = true;
//     }
//   }

//   async putWord(wordLine: string): Promise<void> {
//     if (!this.isHeaderWritten) {
//       fs.writeFileSync(
//         this.filePath,
//         "word,definition_native,definition_target,example1_native,example1_target,example2_native,example2_target,difficulty\n",
//       );
//       this.isHeaderWritten = true;
//     }

//     fs.appendFileSync(this.filePath, wordLine + "\n");
//     console.log(`Added word to DB: ${wordLine.split(",")[0]}`);
//   }
// }

// class CsvLineParser {
//   private buffer: string = "";
//   private db: DbClient;
//   private headerSkipped: boolean = false;

//   constructor(db: DbClient) {
//     this.db = db;
//   }

//   processChunk(chunk: string): void {
//     this.buffer += chunk;
//     this.processLines();
//   }

//   private processLines(): void {
//     const lines = this.buffer.split("\n");
//     this.buffer = lines.pop() || "";

//     for (const line of lines) {
//       const trimmedLine = line.trim();
//       if (trimmedLine) {
//         if (!this.headerSkipped) {
//           this.headerSkipped = true;
//         } else {
//           this.db.putWord(trimmedLine);
//         }
//       }
//     }
//   }

//   async finalize(): Promise<void> {
//     if (this.buffer.trim()) {
//       await this.db.putWord(this.buffer.trim());
//     }
//   }
// }

// export const word_graph_from_image: GraphData = {
//   version: 0.5,
//   nodes: {
//     extract_words: {
//       agent: "openAIAgent",
//       params: {
//         model: "gpt-4o-mini",
//         stream: true,
//         verbose: true,
//       },
//       inputs: {
//         system: `あなたは有用な単語帳の作成者です。与えられたコンテンツからユーザーの学習言語にパーソナライズされた単語帳を作成してください。
// ユーザー情報:
// - 母国語: \${:nativeLanguage}
// - 学習言語: \${:targetLanguage}
// - 熟練度: \${:proficiencyLevel}

// 指示:
// 1. \${:targetLanguage}で学習者にとって価値のある10〜20の有用な単語やフレーズを抽出・作成してください。
// 2. ユーザーの熟練度に合わせた難易度の単語を選んでください。
// 3. 各単語について以下の情報を提供してください:
//    - 単語/フレーズ
//    - 両言語での定義
//    - 両言語での例文（各単語につき2つ）
//    - 難易度レベル（初級/中級/上級）

// 4. CSVフォーマットで返信してください。以下のようにヘッダー行から始めてください:
// word,definition_native,definition_target,example1_native,example1_target,example2_native,example2_target,difficulty

// 5. 各フィールドに特殊文字（カンマ、引用符など）が含まれる場合は、ダブルクォートで囲んでください。
// 6. 各単語を新しい行に記載してください。`,
//         prompt: ":content",
//       },
//       isResult: true,
//     },
//   },
// };

// const main = async () => {
//   const db = new FileDbClient();
//   const parser = new CsvLineParser(db);

//   const graph_data: GraphData = {
//     version: 0.5,
//     nodes: {
//       content_input: {
//         agent: "textInputAgent",
//         params: {
//           message: "コンテンツの入力:",
//         },
//       },
//       tutor: {
//         agent: "nestedAgent",
//         inputs: {
//           nativeLanguage: "ja",
//           targetLanguage: "ko",
//           proficiencyLevel: "intermediate",
//           content: ":content_input.text",
//         },
//         isResult: true,
//         graph: word_graph_from_image,
//       },
//     },
//   };
//   const streamCallback = (context: AgentFunctionContext, data: string) => {
//     console.log(`受信: ${data.substring(0, 50)}...`);
//     parser.processChunk(data);
//   };

//   const streamAgentFilter = streamAgentFilterGenerator(streamCallback);
//   const agentFilters: AgentFilterInfo[] = [
//     {
//       name: "streamAgentFilter",
//       agent: streamAgentFilter,
//       agentIds: ["openAIAgent"],
//     },
//   ];

//   const graph = new GraphAI(graph_data, agents, { agentFilters });
//   await graph.run();
//   await parser.finalize();
//   console.log("処理完了。最終結果:");
// };

// if (require.main === module) {
//   main();
// }
