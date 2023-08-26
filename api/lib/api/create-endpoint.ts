import { APIError } from "./api-error";
import { NextRequest, NextResponse } from "next/server";
import { PrismaClientKnownRequestError } from "@prisma/client/runtime/library";
import { rateLimit, type RateLimitWindow } from "./rate-limit";

export function createEndpoint(
  handler: (req: NextRequest, id: () => string) => Promise<NextResponse>,
  options?: {
    rateLimit?: {
      tokens?: number;
      window?: RateLimitWindow;
      disable?: boolean;
    };
  }
): (
  req: NextRequest,
  { params }: { params: { id: string } }
) => Promise<NextResponse> {
  return async (
    req: NextRequest,
    { params }: { params: { id: string } }
  ): Promise<NextResponse> => {
    try {
      if (!(options?.rateLimit?.disable ?? false)) {
        await rateLimit({
          identifier: req.headers.get("authorization") ?? req.ip ?? "global",
          tokens: options?.rateLimit?.tokens ?? 100,
          window: options?.rateLimit?.window ?? "1m",
          endpoint: req.nextUrl.pathname,
        });
      }

      return await handler(req, () => {
        const id = params.id as string | undefined;
        if (!id) {
          throw new APIError({
            statusCode: 400,
            message: "Missing id parameter.",
            code: "invalid_query",
          });
        }
        return id;
      });
    } catch (e) {
      console.error(e);
      if (e instanceof APIError) {
        return NextResponse.json(
          { message: e.message, code: e.code, statusCode: e.statusCode },
          { status: e.statusCode }
        );
      } else if (e instanceof PrismaClientKnownRequestError) {
        if (e.code === "P2025" || e.code === "P2023") {
          return NextResponse.json(
            {
              message: "Item not found.",
              code: "resource_not_found",
              statusCode: 404,
            },
            { status: 404 }
          );
        }
      }
      return NextResponse.json(
        {
          message: "Internal server error.",
          code: "internal_server_error",
          statusCode: 500,
        },
        { status: 500 }
      );
    }
  };
}
