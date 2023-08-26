import { createEndpoint } from "@/lib/api/create-endpoint";
import { prisma } from "@/lib/api/prisma";
import { NextResponse } from "next/server";

export const GET = createEndpoint(async () => {
  const { count } = await prisma.user.deleteMany({
    where: {
      dummy: true,
    },
  });
  return NextResponse.json({ count });
});
