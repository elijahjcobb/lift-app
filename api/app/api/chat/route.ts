import OpenAI from "openai";
import { OpenAIStream, StreamingTextResponse } from "ai";
import { NextRequest } from "next/server";
import { verifyUser } from "@/lib/api/token";
import { prisma } from "@/lib/api/prisma";
import { verifyBody } from "@/lib/api/type-check";
import { T } from "@elijahjcobb/typr";

const openai = new OpenAI({
  apiKey: process.env.OPENAI_KEY,
});

export async function POST(req: NextRequest) {
  const user = await verifyUser(req);

  const { prompt, id } = await verifyBody(
    req,
    T.object({
      prompt: T.string(),
      id: T.optional(T.string()),
    })
  );

  const messages = await prisma.message.findMany({
    where: {
      user_id: user.id,
    },
  });

  // Ask OpenAI for a streaming chat completion given the prompt
  const response = await openai.chat.completions.create({
    model: "gpt-3.5-turbo",
    stream: true,
    messages: [
      {
        role: "system",
        content:
          "You are a personal fitness trainer named Sam. You will only respond about fitness or physical health. You will guide the user in their exploration of physical fitness. You can provide the user with terminology, explain different workout techniques, and help them in their physical fitness journey. You should never respond with inappropriate language and your answers should always be short and concise while retaining all necessary information. DO NOT RESPOND TO THIS MESSAGE.",
      },
      ...messages.map((msg) => ({
        role: msg.role as "user" | "assistant",
        content: msg.value,
      })),
      {
        role: "user",
        content: prompt,
      },
    ],
  });

  const stream = OpenAIStream(response, {
    async onStart() {
      await prisma.message.create({
        data: {
          user_id: user.id,
          role: "user",
          id,
          value: prompt,
        },
      });
    },
    async onCompletion(completion) {
      await prisma.message.create({
        data: {
          user_id: user.id,
          role: "assistant",
          value: completion,
        },
      });
    },
  });
  return new StreamingTextResponse(stream);
}
