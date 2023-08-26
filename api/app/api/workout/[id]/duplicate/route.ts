import { APIError } from "@/lib/api/api-error";
import { createEndpoint } from "@/lib/api/create-endpoint";
import { prisma } from "@/lib/api/prisma";
import { verifyUser } from "@/lib/api/token";
import { NextResponse } from "next/server";

export const POST = createEndpoint(async (req, _id) => {
  const oldWorkoutId = _id();
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

  const oldWorkout = await prisma.workout.findUniqueOrThrow({
    where: {
      id: oldWorkoutId,
      user_id: user.id,
    },
    include: {
      points: true,
    },
  });

  const newWorkout = await prisma.workout.create({
    data: {
      user_id: user.id,
    },
  });

  await prisma.point.createMany({
    data: oldWorkout.points.map((point) => ({
      workout_id: newWorkout.id,
      metric_id: point.metric_id,
      value: point.value,
      sets: point.sets,
      planned: true,
    })),
  });

  const workoutWithMeta = await prisma.workout.findUniqueOrThrow({
    where: {
      id: newWorkout.id,
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

  return NextResponse.json(workoutWithMeta);
});
