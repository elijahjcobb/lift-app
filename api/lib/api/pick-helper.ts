import { pick } from "./pick";

export function p<O>(...keys: (keyof O)[]) {
  return function (obj: O): Pick<O, keyof O> {
    const ret = {} as Pick<O, keyof O>;
    for (const key of keys) {
      ret[key] = obj[key];
    }
    return ret;
  };
}

export type Picks = {
  [P in keyof typeof pick]: ReturnType<(typeof pick)[P]>;
};
