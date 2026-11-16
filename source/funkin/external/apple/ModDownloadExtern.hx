package funkin.external.apple;

#if ((ios || macos) && cpp)
/**
 * An external interface for downloading mods on Apple platforms.
 */
@:build(funkin.util.macro.LinkerMacro.xml('project/Build.xml'))
@:include('ModDownloadExtern.hpp')
@:unreflective
extern class ModDownloadExtern
{
  /**
   * Starts streaming a file straight to disk.
   * @param url The HTTPS URL to download.
   * @param destPath The absolute path to write the file to. It is overwritten.
   * @param userAgent The User-Agent header to send.
   * @param allowedDomains Comma separated hosts that the download, and any redirect, may point at.
   * @param timeout How long the connection can go without receiving anything, in seconds.
   * @return Whether the download was started.
   */
  @:native('Apple_ModDownload_Start')
  static function start(url:cpp.ConstCharStar,
    destPath:cpp.ConstCharStar,
    userAgent:cpp.ConstCharStar,
    allowedDomains:cpp.ConstCharStar,
    timeout:Float):Bool;

  /**
   * Stops the running download. Nothing is written to the file after this returns.
   */
  @:native('Apple_ModDownload_Cancel')
  static function cancel():Void;

  /**
   * @return 0 when idle, 1 while running, 2 once finished, 3 once failed.
   */
  @:native('Apple_ModDownload_GetState')
  static function getState():Int;

  /**
   * @return How many bytes have been written so far.
   */
  @:native('Apple_ModDownload_GetBytesLoaded')
  static function getBytesLoaded():Float;

  /**
   * @return How many bytes the server said it would send, or 0 if it didn't say.
   */
  @:native('Apple_ModDownload_GetBytesTotal')
  static function getBytesTotal():Float;

  /**
   * @return Why the download failed.
   */
  @:native('Apple_ModDownload_GetError')
  static function getError():cpp.ConstCharStar;

  /**
   * @return The file's MD5 as lowercase hex.
   */
  @:native('Apple_ModDownload_GetDigest')
  static function getDigest():cpp.ConstCharStar;
}
#end
