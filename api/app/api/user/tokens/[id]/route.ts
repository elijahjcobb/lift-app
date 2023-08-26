import { createEndpoint } from "@/lib/api/create-endpoint";
import { prisma } from "@/lib/api/prisma";
import { tokenSign, tokenVerifyString, verifyUser } from "@/lib/api/token";
import { NextResponse } from "next/server";

export const DELETE = createEndpoint(async (req, _id) => {
  const id = _id();
  const user = await verifyUser(req);

  const { tokenId } = await tokenVerifyString(id);

  const token = await prisma.token.update({
    data: {
      expires_at: new Date(Date.now() - 1),
    },
    where: {
      id: tokenId,
      user_id: user.id,
    },
  });

  return NextResponse.json({ token: await tokenSign(token) });
});
