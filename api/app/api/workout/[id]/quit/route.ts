import { APIError } from "@/lib/api/api-error";
import { createEndpoint } from "@/lib/api/create-endpoint";
import { pick } from "@/lib/api/pick";
import { prisma } from "@/lib/api/prisma";
import { verifyUser } from "@/lib/api/token";
import { NextResponse } from "next/server";

export const POST = createEndpoint(async (req, _id) => {
  const id = _id();
  const user = await verifyUser(req);
  let workout = await prisma.workout.findUniqueOrThrow({
    where: { id, user_id: user.id },
  });
  if (workout.end_date) {
    throw new APIError({
      code: "invalid_request",
      message: "You cannot quit a workout that has already ended.",
      statusCode: 400,
    });
  }

  workout = await prisma.workout.update({
    where: {
      id: workout.id,
      user_id: user.id,
    },
    data: {
      end_date: new Date(),
      archived: true,
    },
    include: {
      points: {
        include: {
          metric: true,
        },
      },
    },
  });
  return NextResponse.json(pick.Workout(workout));
});
