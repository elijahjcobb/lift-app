import { APIError } from "@/lib/api/api-error";
import { createEndpoint } from "@/lib/api/create-endpoint";
import { pick } from "@/lib/api/pick";
import { prisma } from "@/lib/api/prisma";
import { cleanPhoneNumber } from "@/lib/api/sms";
import { getDefaultTokenExpireDate, tokenSign } from "@/lib/api/token";
import { verifyTOTPForSMS } from "@/lib/api/totp";
import { verifyBody } from "@/lib/api/type-check";
import { T } from "@elijahjcobb/typr";
import { User } from "@prisma/client";
import { NextResponse } from "next/server";

export const POST = createEndpoint(async (req) => {
  const {
    code,
    phoneNumber: p,
    name,
  } = await verifyBody(
    req,
    T.object({
      phoneNumber: T.string(),
      code: T.string(),
      name: T.string(),
    })
  );

  const phoneNumber = cleanPhoneNumber(p);

  const saltObj = await prisma.salt.findUniqueOrThrow({
    where: { phone_number: phoneNumber },
  });

  const itTOTPCorrect = await verifyTOTPForSMS({
    phoneNumber,
    salt: saltObj.salt,
    code,
  });

  if (!itTOTPCorrect) {
    throw new APIError({
      code: "incorrect_totp_token",
      message: "That is not the correct code.",
      statusCode: 401,
    });
  }

  const isWhiteListed =
    (await prisma.whiteList.count({
      where: {
        phone_number: phoneNumber,
      },
    })) > 0;

  if (!isWhiteListed) {
    throw new APIError({
      code: "sign_up_blocked",
      message: "Lift is in a private beta, you are not on the white-list.",
      statusCode: 401,
    });
  }

  let user: User;

  try {
    user = await prisma.user.create({
      data: {
        name,
        phone_number: phoneNumber,
      },
    });
  } catch (e) {
    if (e && typeof e === "object" && "code" in e && e.code === "P2002") {
      throw new APIError({
        code: "invalid_username",
        message: "An account already exists with this email.",
        statusCode: 400,
      });
    }
    throw e;
  }

  const token = await prisma.token.create({
    data: {
      user_id: user.id,
      expires_at: getDefaultTokenExpireDate(),
    },
  });

  return NextResponse.json({
    user: pick.User(user),
    token: await tokenSign(token),
  });
});
