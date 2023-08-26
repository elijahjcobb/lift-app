import { APIError } from "@/lib/api/api-error";
import { createEndpoint } from "@/lib/api/create-endpoint";
import { prisma } from "@/lib/api/prisma";
import { verifyUser } from "@/lib/api/token";
import { NextResponse } from "next/server";

export const POST = createEndpoint(async (req, _id) => {
  const id = _id();
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

  const plan = await prisma.workoutPlan.findUniqueOrThrow({
    where: {
      id,
      user_id: user.id,
    },
    include: {
      points: true,
    },
  });

  const workout = await prisma.workout.create({
    data: {
      user_id: user.id,
      plan_id: plan.id,
    },
  });

  const points = await Promise.all(
    plan.points.map((point) =>
      prisma.point.create({
        data: {
          workout_id: workout.id,
          metric_id: point.metric_id,
          value: point.value,
          sets: point.sets,
          planned: true,
        },
      })
    )
  );

  return NextResponse.json({ workout, points });
});
