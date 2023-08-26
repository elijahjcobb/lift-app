import { createEndpoint } from "@/lib/api/create-endpoint";
import { prisma } from "@/lib/api/prisma";
import { verifyUser } from "@/lib/api/token";
import { NextResponse } from "next/server";

export const POST = createEndpoint(async (req, _id) => {
  const id = _id();
  const user = await verifyUser(req);
  const point = await prisma.point.update({
    where: {
      id,
      workout: {
        user_id: user.id,
      },
    },
    data: {
      planned: false,
    },
  });

  const workout = await prisma.workout.findUniqueOrThrow({
    where: {
      id: point.workout_id,
      user_id: user.id,
    },
    include: {
      points: {
        include: {
          metric: true,
        },
      },
    },
  });

  return NextResponse.json(workout);
});
