import { createEndpoint } from "@/lib/api/create-endpoint";
import { prisma } from "@/lib/api/prisma";
import {
  getDefaultTokenExpireDate,
  tokenSign,
  verifyUser,
} from "@/lib/api/token";
import { verifyBody } from "@/lib/api/type-check";
import { T } from "@elijahjcobb/typr";
import { NextResponse } from "next/server";

const TOKEN_REVEAL = 4;

export const POST = createEndpoint(async (req) => {
  const { expiresInMS, name } = await verifyBody(
    req,
    T.object({
      expiresInMS: T.optional(T.number()),
      name: T.optional(T.string()),
    })
  );
  const user = await verifyUser(req);

  const expires_at = expiresInMS
    ? new Date(Date.now() + expiresInMS)
    : getDefaultTokenExpireDate();

  const token = await prisma.token.create({
    data: {
      user_id: user.id,
      expires_at,
      name,
    },
  });

  return NextResponse.json({ token: await tokenSign(token) });
});

export const GET = createEndpoint(async (req) => {
  const user = await verifyUser(req);

  const rawTokens = await prisma.token.findMany({
    where: {
      user_id: user.id,
    },
  });

  const tokens: {
    token: string;
    expires_at: Date;
    name: string | null;
    created_at: Date;
  }[] = await Promise.all(
    rawTokens.map(async (token) => {
      const signed = await tokenSign(token);

      return {
        token: `${signed.slice(0, TOKEN_REVEAL)}...${signed.slice(
          -TOKEN_REVEAL
        )}`,
        expires_at: token.expires_at,
        name: token.name,
        created_at: token.created_at,
      };
    })
  );

  return NextResponse.json({
    tokens,
  });
});
