import { Mutex } from "redis-semaphore";
import Redis from "ioredis";

const url = process.env.KV_URL;
if (!url) throw new Error("KV_URL is not set");

const redis = new Redis(url);

export async function withMutex<T>(
  identifier: string,
  fn: () => Promise<T>
): Promise<T> {
  const mutex = new Mutex(redis, `mutex:${identifier}`);
  await mutex.acquire();
  try {
    return await fn();
  } finally {
    await mutex.release();
  }
}
