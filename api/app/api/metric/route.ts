import { createEndpoint } from "@/lib/api/create-endpoint";
import { pick } from "@/lib/api/pick";
import { prisma } from "@/lib/api/prisma";
import { verifyUser } from "@/lib/api/token";
import { verifyBody } from "@/lib/api/type-check";
import { T } from "@elijahjcobb/typr";
import { NextResponse } from "next/server";

export const POST = createEndpoint(async (req) => {
  const { name, unit, stepSize, defaultValue, defaultSets } = await verifyBody(
    req,
    T.object({
      name: T.string(),
      unit: T.optional(T.union(T.string(), T.null())),
      stepSize: T.optional(T.union(T.number(), T.null())),
      defaultValue: T.optional(T.union(T.number(), T.null())),
      defaultSets: T.optional(T.union(T.number(), T.null())),
    })
  );

  const user = await verifyUser(req);

  const metric = await prisma.metric.create({
    data: {
      name: name.trim(),
      user_id: user.id,
      unit: unit ? (unit === "none" ? null : unit.trim()) : null,
      default_value: defaultValue ?? null,
      step_size: stepSize ?? null,
      default_sets: defaultSets ?? null,
    },
  });

  return NextResponse.json(pick.Metric(metric));
});
