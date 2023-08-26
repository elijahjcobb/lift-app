import { APIError } from "@/lib/api/api-error";
import { createEndpoint } from "@/lib/api/create-endpoint";
import { pick } from "@/lib/api/pick";
import { prisma } from "@/lib/api/prisma";
import { verifyUser } from "@/lib/api/token";
import { put } from "@vercel/blob";
import { NextResponse } from "next/server";

const ALLOWED_CONTENT_TYPES = {
  "image/jpeg": "jpeg",
  "image/png": "png",
  "image/jpg": "jpg",
} as const;

const ALLOWED_CONTENT_TYPES_NAMES = Object.keys(ALLOWED_CONTENT_TYPES).join(
  " or "
);

function getPath(userId: string): string {
  return `avatar/${userId}`;
}

export const POST = createEndpoint(async (req) => {
  let user = await verifyUser(req);

  console.log("UPLOAD AVATAR");

  const contentType = req.headers.get("content-type");

  if (!contentType || !(contentType in ALLOWED_CONTENT_TYPES)) {
    throw new APIError({
      statusCode: 400,
      message: `Invalid content type, allowed content-types: ${ALLOWED_CONTENT_TYPES_NAMES}`,
      code: "invalid_body",
    });
  }

  const data = await req.blob();

  const blob = await put(getPath(user.id), data, {
    access: "public",
    contentType,
  });

  user = await prisma.user.update({
    where: {
      id: user.id,
    },
    data: {
      avatar: blob.url,
    },
  });

  return NextResponse.json(pick.User(user));
});
