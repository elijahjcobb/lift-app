import { hash } from "bcrypt";
import { totp } from "otplib";

totp.options = {
  digits: 6,
  step: 60,
  window: 1,
};

const SECRET = process.env.TOTP_SECRET;

export async function createSecret({
  salt,
  phoneNumber,
}: {
  phoneNumber: string;
  salt: string;
}): Promise<string> {
  if (!SECRET) throw new Error("Secret is undefined.");
  return await hash(`${SECRET}:${phoneNumber}`, salt);
}

export async function createTOTPForSMS({
  salt,
  phoneNumber,
}: {
  phoneNumber: string;
  salt: string;
}): Promise<string> {
  const secret = await createSecret({ salt, phoneNumber });
  return totp.generate(secret);
}

export async function verifyTOTPForSMS({
  salt,
  phoneNumber,
  code,
}: {
  phoneNumber: string;
  salt: string;
  code: string;
}): Promise<boolean> {
  const secret = await createSecret({ salt, phoneNumber });
  return totp.verify({ token: code, secret });
}
