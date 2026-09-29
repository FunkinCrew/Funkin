package funkin.external.apple;

#if (macos && cpp)
/**
 * A utility class for owning a custom URL scheme on macOS.
 * Listens for an apple event of type kAEGetURL and invokes a callback for each incoming URL.
 */
@:build(funkin.util.macro.LinkerMacro.xml('project/Build.xml'))
@:include('URLSchemeExtern.hpp')
@:unreflective
extern class URLSchemeExtern
{
  /**
   * Claims the apple event that carries incoming URLs.
   */
  @:native('Apple_URLScheme_InstallHandler')
  static function installHandler():Void;

  /**
   * Registers this application bundle as the default handler for the given URL scheme.
   * The bundle must also declare the scheme in CFBundleURLTypes for this to stick.
   * @param scheme The scheme name, without the trailing colon.
   * @return Whether this bundle owns the scheme once the call returns.
   */
  @:native('Apple_URLScheme_Register')
  static function register(scheme:cpp.ConstCharStar):Bool;

  /**
   * Checks whether this application bundle is already the default handler for the given scheme.
   * @param scheme The scheme name, without the trailing colon.
   * @return Whether this bundle currently owns the scheme.
   */
  @:native('Apple_URLScheme_IsRegistered')
  static function isRegistered(scheme:cpp.ConstCharStar):Bool;

  /**
   * Installs the callback that receives URLs opened through a registered scheme.
   * URLs that arrived before this call are buffered and replayed immediately.
   * @param callback The function to invoke for each incoming URL.
   */
  @:native('Apple_URLScheme_SetCallback')
  static function setCallback(callback:cpp.Callable<(url:cpp.ConstCharStar) -> Void>):Void;
}
#end
