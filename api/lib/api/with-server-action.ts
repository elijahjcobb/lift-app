import { type APIErrorType, APIError } from "./api-error";

interface Base {
  type: "data" | "error";
}

export interface Data<T> extends Base {
  type: "data";
  data: T;
}

export interface Error extends Base {
  type: "error";
  error: APIErrorType;
}

export type ServerActionReturn<T> = Data<T> | Error;

export function withServerAction<T, R>(
  func: (props: T) => Promise<R>
): (props: T) => Promise<ServerActionReturn<R>> {
  return async (props: T): Promise<ServerActionReturn<R>> => {
    try {
      return {
        type: "data",
        data: await func(props),
      };
    } catch (e) {
      let error: APIErrorType;
      if (e instanceof APIError) {
        error = {
          code: e.code,
          statusCode: e.statusCode,
          message: e.message,
        };
      } else {
        error = {
          code: "internal_server_error",
          statusCode: 500,
          message: "Internal server error.",
        };
      }
      return { type: "error", error };
    }
  };
}
