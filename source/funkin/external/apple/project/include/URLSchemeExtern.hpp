#pragma once

/**
 * Function pointer type used to deliver an incoming URL to the Haxe side.
 *
 * @param url The full URL that was opened, as a null-terminated string.
 */
typedef void (*URLSchemeCallback)(const char *url);

/**
 * Registers this application bundle as the default handler for the given URL scheme.
 *
 * @param scheme The scheme name, without the trailing colon.
 * @return True if this bundle is the handler once the call returns.
 */
bool Apple_URLScheme_Register(const char *scheme);

/**
 * Checks whether this application bundle is already the default handler for the given scheme.
 *
 * @param scheme The scheme name, without the trailing colon.
 * @return True if this bundle currently owns the scheme.
 */
bool Apple_URLScheme_IsRegistered(const char *scheme);

/**
 * Installs the callback that receives URLs opened through a registered scheme.
 *
 * @param callback The function to invoke for each incoming URL.
 */
void Apple_URLScheme_SetCallback(URLSchemeCallback callback);
