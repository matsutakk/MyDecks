import { GraphAI, GraphData } from "graphai";
import * as agents from "@graphai/agents";
import "dotenv/config";
import { sttOpenaiAgent } from "@graphai/stt_openai_agent";
import * as path from "path";
import * as fs from "fs";

export const graph: GraphData = {
  version: 0.5,
  nodes: {
    extract_transcription: {
      agent: "sttOpenaiAgent",
      inputs: {
        stream: ":stream",
        model: "gpt-4o-mini-transcribe",
      },
    },
    extract_words: {
      agent: "openAIAgent",
      params: {
        model: "gpt-4o-mini",
        verbose: true,
      },
      inputs: {
        system: `あなたは有用な単語帳の作成者です。与えられたコンテンツからユーザーの学習言語にパーソナライズされた単語帳を作成してください。
ユーザー情報:
- 母国語: \${:nativeLanguage}
- 学習言語: \${:targetLanguage}
- 熟練度: \${:proficiencyLevel}


指示:
1. \${:targetLanguage}で学習者にとって価値のある10〜20の有用な単語やフレーズを抽出・作成してください。
2. ユーザーの熟練度に合わせた難易度の単語を選んでください。
3. 各単語について以下の情報を提供してください:
   - 単語/フレーズ
   - 両言語での定義
   - 両言語での例文（各単語につき2つ）
   - 難易度レベル（初級/中級/上級）
4. 以下の形式のJSONで返してください:
{
  "title": "単語帳のタイトル"
  "words": [
    {
      "word": "学習言語\${:targetLanguage}の単語またはフレーズ",
      "definition": {
        "\${:nativeLanguage}": "\${:nativeLanguage}での定義",
        "\${:targetLanguage}": "\${:targetLanguage}での定義"
      },
      "examples": [
        {
          "\${:nativeLanguage}": "\${:nativeLanguage}での例文",
          "\${:targetLanguage}": "\${:targetLanguage}での例文"
        },
        {
          "\${:nativeLanguage}": "\${:nativeLanguage}での2つ目の例文",
          "\${:targetLanguage}": "\${:targetLanguage}での2つ目の例文"
        }
      ],
      "difficulty": "beginner/intermediate/advanced",
    }
  ]
}`,
        prompt: ":extract_transcription.text",
        response_format: { type: "json_object" },
      },
      isResult: true,
    },

    result: {
      agent: "jsonParserAgent",
      isResult: true,
      inputs: {
        text: ":extract_words.text",
      },
    },
  },
};

const main = async () => {
  const filePath = path.resolve(path.join(__dirname, "test.m4a"));
  const file = fs.createReadStream(filePath);
  // const res = await sttOpenaiAgent.agent({
  //   params: {
  //     stream: file,
  //     throwErrors: true,
  //   },
  //   namedInputs: {},
  //   debugInfo: {
  //     retry: 1,
  //     nodeId: "",
  //     verbose: true,
  //     state: "",
  //     subGraphs: new Map(),
  //   },
  //   filterParams: [],
  // });
  // console.log(res);
  const graph_data: GraphData = {
    version: 0.5,
    nodes: {
      mydecks: {
        agent: "nestedAgent",
        inputs: {
          stream: file,
          nativeLanguage: "ja",
          targetLanguage: "en",
          proficiencyLevel: "intermediate",
        },
        isResult: true,
        graph: graph,
      },
    },
  };

  const graphAI = new GraphAI(graph_data, {
    ...agents,
    sttOpenaiAgent,
  });
  const result = await graphAI.run();
  console.log(JSON.stringify(result, null, 2));
};

if (require.main === module) {
  main();
}
