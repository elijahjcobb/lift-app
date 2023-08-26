export const TOKEN_AGE_SEC = 60 * 60 * 24 * 30;
export const TOKEN_EXPIRES = () => new Date(Date.now() + TOKEN_AGE_SEC * 1000);
