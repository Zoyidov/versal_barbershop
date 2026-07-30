/** `JSON.stringify(new Error('x'))` is `{}` - `Error#message`/`#stack` are
 * inherited, non-enumerable properties, so passing a raw caught error to
 * `logger.error(msg, { error })` silently drops the actual reason from
 * Cloud Logging. Every catch block in this backend should log
 * `errorMessage(error)` instead of the raw error - under a key OTHER than
 * `message` (e.g. `reason`), since `firebase-functions`' logger treats a
 * `message` property in the metadata object as reserved and silently
 * overwrites it with its own stack trace for the `logger.error(...)` call
 * site, discarding whatever string was passed in. */
export function errorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return String(error);
}
