import { NextRequest } from "next/server";
import { TType } from "@elijahjcobb/typr";
import { APIError } from "./api-error";

export async function verifyBody<T>(
  req: NextRequest,
  type: TType<T>
): Promise<T> {
  let b = await req.json();
  const body = type.verify(b);
  if (!body)
    throw new APIError({
      code: "invalid_body",
      statusCode: 400,
      message: "Invalid request body. Your JSON is not the right structure.",
    });
  return body;
}
