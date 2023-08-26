import { createEndpoint } from "@/lib/api/create-endpoint";
import { prisma } from "@/lib/api/prisma";
import { verifyUser } from "@/lib/api/token";
import { verifyBody } from "@/lib/api/type-check";
import { T } from "@elijahjcobb/typr";
import { NextResponse } from "next/server";

export const POST = createEndpoint(async (req) => {
  const { name } = await verifyBody(
    req,
    T.object({
      name: T.string(),
    })
  );
  const user = await verifyUser(req);

  const plan = await prisma.workoutPlan.create({
    data: {
      name,
      user_id: user.id,
    },
  });

  return NextResponse.json({
    ...plan,
    points: [],
  });
});
