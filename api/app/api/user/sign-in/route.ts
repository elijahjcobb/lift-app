import { APIError } from "@/lib/api/api-error";
import { createEndpoint } from "@/lib/api/create-endpoint";
import { pick } from "@/lib/api/pick";
import { prisma } from "@/lib/api/prisma";
import { cleanPhoneNumber } from "@/lib/api/sms";
import { getDefaultTokenExpireDate, tokenSign } from "@/lib/api/token";
import { verifyTOTPForSMS } from "@/lib/api/totp";
import { verifyBody } from "@/lib/api/type-check";
import { T } from "@elijahjcobb/typr";
import { NextResponse } from "next/server";

export const POST = createEndpoint(async (req) => {
  const { phoneNumber: p, code } = await verifyBody(
    req,
    T.object({
      phoneNumber: T.string(),
      code: T.string(),
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

  const user = await prisma.user.findUnique({
    where: {
      phone_number: phoneNumber,
    },
  });

  if (!user) {
    throw new APIError({
      code: "invalid_request",
      message: "You must first sign up.",
      statusCode: 400,
    });
  }

  const token = await prisma.token.create({
    data: {
      user_id: user.id,
      name: req.headers.get("user-agent"),
      expires_at: getDefaultTokenExpireDate(),
    },
  });

  return NextResponse.json({
    user: pick.User(user),
    token: await tokenSign(token),
  });
});
