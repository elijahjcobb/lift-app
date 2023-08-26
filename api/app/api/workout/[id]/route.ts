import { createEndpoint } from "@/lib/api/create-endpoint";
import { pick } from "@/lib/api/pick";
import { prisma } from "@/lib/api/prisma";
import { verifyUser } from "@/lib/api/token";
import { NextResponse } from "next/server";

export const GET = createEndpoint(async (req, _id) => {
  const id = _id();
  const user = await verifyUser(req);
  const workout = await prisma.workout.findUniqueOrThrow({
    where: {
      id,
      user_id: user.id,
    },
  });
  return NextResponse.json(pick.Workout(workout));
});

export const DELETE = createEndpoint(async (req, _id) => {
  const id = _id();
  const user = await verifyUser(req);
  const workout = await prisma.workout.update({
    where: {
      id,
      user_id: user.id,
    },
    data: {
      archived: true,
    },
  });
  return NextResponse.json(pick.Workout(workout));
});
