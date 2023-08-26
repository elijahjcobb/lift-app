import { createEndpoint } from "@/lib/api/create-endpoint";
import { sendSMS } from "@/lib/api/sms";
import { NextResponse } from "next/server";

export const GET = createEndpoint(async () => {
  await sendSMS({
    to: "2065725052",
    message: "WELL HELLO THERE",
  });
  return NextResponse.json({});
});
