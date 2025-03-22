import {
  AgentFilterInfo,
  AgentFunctionContext,
  GraphAI,
  GraphData,
} from "graphai";
import * as agents from "@graphai/agents";
import "dotenv/config";
import { streamAgentFilterGenerator } from "@graphai/agent_filters";

export const graph: GraphData = {
  version: 0.5,
  nodes: {
    fetch_content: {
      agent: "vanillaFetchAgent",
      inputs: {
        url: ":url",
      },
      params: {
        type: "text",
      },
    },
    extract_words: {
      agent: "openAIAgent",
      params: {
        model: "gpt-4o-mini",
        stream: true,
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
      "synonyms": [
        {
          "word": "類義語1",
        },
        {
          "word": "類義語2",
        }
      ],
      "antonyms": [
        {
          "word": "反対語1",
        },
        {
          "word": "反対語2",
        }
      ],
      "collocations": [
        {
          "phrase": "よく一緒に使われるフレーズ1",
          "translation": "\${:nativeLanguage}での翻訳",
          "example": "コロケーションを使った例文"
        },
        {
          "phrase": "よく一緒に使われるフレーズ2",
          "translation": "\${:nativeLanguage}での翻訳",
          "example": "コロケーションを使った例文"
        }
      ],
      "difficulty": "beginner/intermediate/advanced",
    }
  ]
}`,
        prompt: ":fetch_content",
        response_format: { type: "json_object" },
      },
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
  const graph_data: GraphData = {
    version: 0.5,
    nodes: {
      content_input: {
        agent: "textInputAgent",
        params: {
          message: "コンテンツの入力:",
        },
      },
      tutor: {
        agent: "nestedAgent",
        inputs: {
          url: ":content_input.text",
          nativeLanguage: "ja",
          targetLanguage: "ko",
          proficiencyLevel: "intermediate",
        },
        isResult: true,
        graph: graph,
      },
    },
  };

  const myCallback = (context: AgentFunctionContext, data: string) => {
    console.log(data);
  };
  const streamAgentFilter = streamAgentFilterGenerator(myCallback);
  const agentFilters: AgentFilterInfo[] = [
    {
      name: "streamAgentFilter",
      agent: streamAgentFilter,
      agentIds: ["openAIAgent"],
    },
  ];
  const graphAI = new GraphAI(graph_data, agents, { agentFilters });
  // const graphAI = new GraphAI(graph_data, agents);
  const result = await graphAI.run();
  console.log(JSON.stringify(result, null, 2));
};

if (require.main === module) {
  main();
}
