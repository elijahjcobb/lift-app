import { createEndpoint } from "@/lib/api/create-endpoint";
import { pick } from "@/lib/api/pick";
import { verifyUser } from "@/lib/api/token";
import { NextResponse } from "next/server";

export const GET = createEndpoint(async (req) => {
  const user = await verifyUser(req);
  return NextResponse.json(pick.User(user));
});
