#pragma once

#define APPLE_MOD_DOWNLOAD_IDLE 0
#define APPLE_MOD_DOWNLOAD_RUNNING 1
#define APPLE_MOD_DOWNLOAD_FINISHED 2
#define APPLE_MOD_DOWNLOAD_FAILED 3

/**
 * Starts downloading a file with NSURLSession, streaming it straight to disk.
 *
 * @param url The HTTPS URL to download.
 * @param destPath The absolute path to write the file to.
 * @param userAgent The User-Agent header to send.
 * @param allowedDomains Comma separated hosts that the download, and any redirect, may point at.
 * @param timeout How long the connection can go without receiving anything, in seconds.
 * @return Whether the download was started.
 */
bool Apple_ModDownload_Start(const char *url, const char *destPath, const char *userAgent, const char *allowedDomains, double timeout);

/**
 * Stops the running download, if there is one. Nothing is written to the file after this returns.
 */
void Apple_ModDownload_Cancel();

/**
 * @return One of the APPLE_MOD_DOWNLOAD_ values.
 */
int Apple_ModDownload_GetState();

/**
 * @return How many bytes have been written so far.
 */
double Apple_ModDownload_GetBytesLoaded();

/**
 * @return How many bytes the server said it would send, or 0 if it didn't say.
 */
double Apple_ModDownload_GetBytesTotal();

/**
 * @return Why the download failed
 */
const char *Apple_ModDownload_GetError();

/**
 * @return The MD5 of the file as lowercase hex.
 */
const char *Apple_ModDownload_GetDigest();
