import { createEndpoint } from "@/lib/api/create-endpoint";
import { pick } from "@/lib/api/pick";
import { prisma } from "@/lib/api/prisma";
import { verifyUser } from "@/lib/api/token";
import { NextResponse } from "next/server";

export const GET = createEndpoint(async (req) => {
  const user = await verifyUser(req);

  const workouts = await prisma.workout.findMany({
    where: {
      user_id: user.id,
      end_date: { not: null },
      archived: { not: true },
    },
    include: {
      points: {
        include: {
          metric: true,
        },
      },
    },
    orderBy: {
      end_date: "desc",
    },
  });

  const metrics = await prisma.metric.findMany({
    where: {
      user_id: user.id,
    },
    orderBy: {
      updated_at: "desc",
    },
  });

  const currentWorkout = await prisma.workout.findFirst({
    where: {
      user_id: user.id,
      end_date: null,
    },
    include: {
      points: {
        include: {
          metric: true,
        },
        orderBy: {
          created_at: "desc",
        },
      },
    },
  });

  if (currentWorkout) {
    currentWorkout.points.sort(
      (a, b) => a.created_at.getTime() - b.created_at.getTime()
    );
  }

  const messages = await prisma.message.findMany({
    where: {
      user_id: user.id,
    },
  });

  const plans = await prisma.workoutPlan.findMany({
    where: {
      user_id: user.id,
    },
    include: {
      points: true,
    },
  });

  return NextResponse.json({
    metrics: metrics.map(pick.Metric),
    user: pick.User(user),
    workout: currentWorkout,
    messages,
    workouts,
    plans,
  });
});
