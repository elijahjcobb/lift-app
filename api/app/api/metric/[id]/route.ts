import { createEndpoint } from "@/lib/api/create-endpoint";
import { pick } from "@/lib/api/pick";
import { prisma } from "@/lib/api/prisma";
import { verifyUser } from "@/lib/api/token";
import { verifyBody } from "@/lib/api/type-check";
import { T } from "@elijahjcobb/typr";
import { NextResponse } from "next/server";

export const GET = createEndpoint(async (req, _id) => {
  const id = _id();
  const user = await verifyUser(req);
  const metric = await prisma.metric.findUniqueOrThrow({
    where: {
      user_id: user.id,
      id,
    },
  });
  return NextResponse.json(pick.Metric(metric));
});

export const PATCH = createEndpoint(async (req, _id) => {
  const id = _id();
  let { name, unit, stepSize, defaultValue, defaultSets } = await verifyBody(
    req,
    T.object({
      name: T.string(),
      unit: T.optional(T.string()),
      stepSize: T.optional(T.union(T.number(), T.null())),
      defaultValue: T.optional(T.union(T.number(), T.null())),
      defaultSets: T.optional(T.union(T.number(), T.null())),
    })
  );

  if (unit) {
    unit = unit.trim();
    if (unit === "none") unit = undefined;
  }

  const user = await verifyUser(req);
  const metric = await prisma.metric.update({
    data: {
      name,
      unit: unit ?? null,
      ...(stepSize !== undefined ? { step_size: stepSize } : {}),
      ...(defaultValue !== undefined ? { default_value: defaultValue } : {}),
      ...(defaultSets !== undefined ? { default_sets: defaultSets } : {}),
    },
    where: {
      user_id: user.id,
      id,
    },
  });

  return NextResponse.json(pick.Metric(metric));
});

export const DELETE = createEndpoint(async (req, _id) => {
  const id = _id();
  const user = await verifyUser(req);
  const metric = await prisma.metric.delete({
    where: {
      user_id: user.id,
      id,
    },
  });
  return NextResponse.json(pick.Metric(metric));
});
