import { createEndpoint } from "@/lib/api/create-endpoint";
import { prisma } from "@/lib/api/prisma";
import { verifyUser } from "@/lib/api/token";
import { verifyBody } from "@/lib/api/type-check";
import { T } from "@elijahjcobb/typr";
import { NextResponse } from "next/server";

export const PATCH = createEndpoint(async (req, _id) => {
  const id = _id();
  const { name } = await verifyBody(
    req,
    T.object({
      name: T.string(),
    })
  );
  const user = await verifyUser(req);

  const plan = await prisma.workoutPlan.update({
    where: {
      id,
      user_id: user.id,
    },
    data: {
      name,
    },
    include: {
      points: true,
    },
  });

  return NextResponse.json(plan);
});

export const DELETE = createEndpoint(async (req, _id) => {
  const id = _id();
  const user = await verifyUser(req);

  const plan = await prisma.workoutPlan.update({
    where: {
      id,
      user_id: user.id,
    },
    data: {
      archived: true,
    },
    include: {
      points: true,
    },
  });

  return NextResponse.json(plan);
});
