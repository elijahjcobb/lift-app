export function generateKey(data: {
  nutId: string;
  userId: string;
  nutUserId: string;
  type: string;
}): string {
  return `${data.nutId}:${data.userId}:${data.nutUserId}:${data.type}`;
}
