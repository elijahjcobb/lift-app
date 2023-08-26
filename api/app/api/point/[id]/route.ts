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
  const point = await prisma.point.findUniqueOrThrow({
    where: {
      id,
      workout: {
        user_id: user.id,
      },
      metric: {
        user_id: user.id,
      },
    },
  });
  return NextResponse.json(pick.Point(point));
});

export const DELETE = createEndpoint(async (req, _id) => {
  const id = _id();
  const user = await verifyUser(req);
  const point = await prisma.point.delete({
    where: {
      id,
      workout: {
        user_id: user.id,
      },
      metric: {
        user_id: user.id,
      },
    },
    include: {
      metric: true,
    },
  });
  return NextResponse.json(point);
});

export const PATCH = createEndpoint(async (req, _id) => {
  const id = _id();
  const [user, { value, sets }] = await Promise.all([
    verifyUser(req),
    verifyBody(
      req,
      T.object({
        value: T.optional(T.union(T.number(), T.null())),
        sets: T.number(),
      })
    ),
  ]);

  const point = await prisma.point.update({
    data: {
      value: value ? value : null,
      sets,
    },
    where: {
      id,
      workout: {
        user_id: user.id,
      },
      metric: {
        user_id: user.id,
      },
    },
  });
  return NextResponse.json(pick.Point(point));
});
