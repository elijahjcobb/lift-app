import { createEndpoint } from "@/lib/api/create-endpoint";
import { pick } from "@/lib/api/pick";
import { prisma } from "@/lib/api/prisma";
import { verifyUser } from "@/lib/api/token";
import { verifyBody } from "@/lib/api/type-check";
import { T } from "@elijahjcobb/typr";
import { NextResponse } from "next/server";

export const POST = createEndpoint(async (req, _id) => {
  const user = await verifyUser(req);
  const id = _id();
  const { metricId, value, sets } = await verifyBody(
    req,
    T.object({
      metricId: T.string(),
      value: T.optional(T.union(T.number(), T.null())),
      sets: T.optional(T.union(T.number(), T.null())),
    })
  );

  const [metric, workout] = await Promise.all([
    prisma.metric.findUniqueOrThrow({
      where: {
        id: metricId,
        user_id: user.id,
      },
    }),
    prisma.workout.findUniqueOrThrow({
      where: {
        id,
        user_id: user.id,
      },
    }),
  ]);

  const point = await prisma.point.create({
    data: {
      metric_id: metric.id,
      workout_id: workout.id,
      value: value ? value : metric.default_value ?? 0,
      sets: sets ? sets : metric.default_sets ?? 0,
    },
    include: {
      metric: true,
    },
  });

  return NextResponse.json(point);
});

export const GET = createEndpoint(async (req, _id) => {
  const id = _id();
  const user = await verifyUser(req);
  const workout = await prisma.workout.findUniqueOrThrow({
    where: {
      id,
      user_id: user.id,
    },
  });
  const points = await prisma.point.findMany({
    where: {
      workout_id: workout.id,
    },
  });
  return NextResponse.json(points.map(pick.Point));
});
