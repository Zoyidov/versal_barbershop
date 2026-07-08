/** `JSON.stringify(new Error('x'))` is `{}` - `Error#message`/`#stack` are
 * inherited, non-enumerable properties, so passing a raw caught error to
 * `logger.error(msg, { error })` silently drops the actual reason from
 * Cloud Logging. Every catch block in this backend should log
 * `errorMessage(error)` alongside (or instead of) the raw error. */
export function errorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return String(error);
}
