import type { Token, User } from "@prisma/client";
import {
  JsonWebTokenError,
  sign,
  TokenExpiredError,
  verify,
} from "jsonwebtoken";
import { APIError } from "./api-error";
import { NextRequest } from "next/server";
import { prisma } from "./prisma";
import { TOKEN_AGE_SEC } from "../token-expire";

export interface TokenData {
  tokenId: string;
}

export interface IToken extends TokenData {
  iat: number;
  exp: number;
}

export const DEFAULT_TOKEN_EXPIRE_MS = 1000 * 60 * 60 * 24 * 7 * 4; // 1 month

/**
 * @returns a date one month in the future
 */
export function getDefaultTokenExpireDate(): Date {
  return new Date(Date.now() + DEFAULT_TOKEN_EXPIRE_MS);
}

const SECRET = process.env.TOKEN_SECRET as string;
if (!SECRET) throw new Error("TOKEN_SECRET is undefined.");

export function tokenSign(token: Token): Promise<string> {
  const t: TokenData = { tokenId: token.id };
  return new Promise((res, rej) => {
    sign(t, SECRET, { expiresIn: TOKEN_AGE_SEC }, (err, signedToken) => {
      if (err || !signedToken) rej(err);
      else res(signedToken);
    });
  });
}

function tokenVerifyInternal(token: string): Promise<IToken> {
  return new Promise((res, rej) => {
    verify(token, SECRET, (err, decoded) => {
      if (err || !decoded) rej(err);
      else res(decoded as IToken);
    });
  });
}

export async function tokenVerifyString(token: string): Promise<IToken> {
  try {
    return await tokenVerifyInternal(token);
  } catch (e) {
    if (e instanceof TokenExpiredError) {
      throw new APIError({
        statusCode: 401,
        code: "auth_expired",
        message: "Authentication expired.",
      });
    } else if (e instanceof JsonWebTokenError) {
      throw new APIError({
        statusCode: 401,
        code: "auth_invalid",
        message: "Authentication invalid.",
      });
    }
    throw e;
  }
}

export async function tokenVerifyRequest(req: NextRequest): Promise<IToken> {
  let token: string | undefined = req.cookies.get("token")?.value;
  if (!token) {
    const authHeader = req.headers.get("authorization") ?? "";
    const arr = authHeader.split(" ");
    const bearer = arr[1];
    if (bearer) {
      token = bearer.trim();
    }
  }

  if (!token || token.length === 0) {
    throw new APIError({
      statusCode: 401,
      code: "auth_missing",
      message: "Authentication token missing from headers or cookies.",
    });
  }

  return tokenVerifyString(token);
}

export async function verifyUser(req: NextRequest): Promise<User> {
  const { tokenId } = await tokenVerifyRequest(req);
  const token = await prisma.token.findUnique({
    where: { id: tokenId },
    include: { user: true },
  });
  if (!token)
    throw new APIError({
      statusCode: 401,
      code: "auth_invalid",
      message: "Authenticated user is invalid.",
    });
  if (token.expires_at < new Date())
    throw new APIError({
      code: "auth_expired",
      message:
        "Your authentication token has expired, please sign in again or create a new token.",
      statusCode: 401,
    });
  return token.user;
}
