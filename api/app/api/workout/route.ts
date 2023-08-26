import { APIError } from "@/lib/api/api-error";
import { createEndpoint } from "@/lib/api/create-endpoint";
import { prisma } from "@/lib/api/prisma";
import { verifyUser } from "@/lib/api/token";
import { NextResponse } from "next/server";

export const POST = createEndpoint(async (req) => {
  const user = await verifyUser(req);

  const activeWorkout = await prisma.workout.findFirst({
    where: {
      end_date: null,
    },
  });

  if (activeWorkout) {
    throw new APIError({
      statusCode: 400,
      code: "invalid_request",
      message: "You already have an active workout.",
    });
  }

  const workout = await prisma.workout.create({
    data: {
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
