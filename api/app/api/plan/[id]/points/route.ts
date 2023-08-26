import { APIError } from "@/lib/api/api-error";
import { createEndpoint } from "@/lib/api/create-endpoint";
import { prisma } from "@/lib/api/prisma";
import { verifyUser } from "@/lib/api/token";
import { verifyBody } from "@/lib/api/type-check";
import { T } from "@elijahjcobb/typr";
import { NextResponse } from "next/server";

export const POST = createEndpoint(async (req, _id) => {
  const workoutPlanId = _id();
  const {
    metricId,
    value,
    sets: maybeSets,
  } = await verifyBody(
    req,
    T.object({
      metricId: T.string(),
      value: T.optional(T.number()),
      sets: T.optional(T.number()),
    })
  );
  const user = await verifyUser(req);
  const metric = await prisma.metric.findUniqueOrThrow({
    where: {
      id: metricId,
      user_id: user.id,
    },
  });
  const sets = maybeSets ?? metric.default_sets;

  if (!sets)
    throw new APIError({
      code: "invalid_body",
      message:
        "You did not supply a `sets` value and the metric does not have a default value.",
      statusCode: 400,
    });

  const point = await prisma.pointPlan.create({
    data: {
      workout_plan_id: workoutPlanId,
      metric_id: metric.id,
      value: value ?? metric.default_value,
      sets,
    },
  });

  return NextResponse.json(point);
});

export const DELETE = createEndpoint(async (req, _id) => {
  const workoutPlanId = _id();
  const { id } = await verifyBody(
    req,
    T.object({
      id: T.string(),
    })
  );
  const user = await verifyUser(req);

  const point = await prisma.pointPlan.delete({
    where: {
      id,
      workout_plan_id: workoutPlanId,
      workout_plan: {
        user_id: user.id,
      },
    },
  });

  return NextResponse.json(point);
});
