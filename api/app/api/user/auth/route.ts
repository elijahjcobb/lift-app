import { createEndpoint } from "@/lib/api/create-endpoint";
import { sendEmail } from "@/lib/api/email";
import { prisma } from "@/lib/api/prisma";
import { createTOTPForSMS } from "@/lib/api/totp";
import { verifyBody } from "@/lib/api/type-check";
import { T } from "@elijahjcobb/typr";
import { genSalt } from "bcrypt";
import { faker } from "@faker-js/faker";
import { NextResponse } from "next/server";
import { getDefaultTokenExpireDate, tokenSign } from "@/lib/api/token";
import { pick } from "@/lib/api/pick";
import { cleanPhoneNumber, sendSMS } from "@/lib/api/sms";
import { APIError } from "@/lib/api/api-error";

export const POST = createEndpoint(async (req) => {
  const { phoneNumber: p } = await verifyBody(
    req,
    T.object({ phoneNumber: T.string() })
  );

  const phoneNumber = cleanPhoneNumber(p);

  if (phoneNumber === "+1888") {
    const user = await prisma.user.create({
      data: {
        name: `${faker.person.firstName()} ${faker.person.lastName()}`,
        phone_number: cleanPhoneNumber(faker.phone.number("888-###-####")),
        dummy: true,
      },
    });
    const token = await prisma.token.create({
      data: {
        user_id: user.id,
        name: "dummy token",
        expires_at: getDefaultTokenExpireDate(),
      },
    });
    return NextResponse.json({
      type: "dummy",
      data: {
        user: pick.User(user),
        token: await tokenSign(token),
      },
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
      message:
        "Lift is in a private beta, you are not invited yet. Please email elijahjcobb@gmail.com for access.",
      statusCode: 401,
    });
  }

  const user = await prisma.user.findUnique({
    where: {
      phone_number: phoneNumber,
    },
  });

  let saltObj = await prisma.salt.findUnique({
    where: { phone_number: phoneNumber },
  });

  if (!saltObj) {
    const salt = await genSalt();
    saltObj = await prisma.salt.create({
      data: {
        phone_number: phoneNumber,
        salt,
      },
    });
  }

  const totp = await createTOTPForSMS({ phoneNumber, salt: saltObj.salt });
  await sendSMS({
    to: phoneNumber,
    message: `Your Lift APP 2FA code is:\n${totp}`,
  });
  return NextResponse.json({ type: user ? "sign-in" : "sign-up" });
});
