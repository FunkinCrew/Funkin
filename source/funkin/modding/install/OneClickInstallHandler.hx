package funkin.modding.install;

import flixel.FlxG;
import funkin.modding.install.ModInstaller.OneClickRequest;
import funkin.util.protocol.OneClickBridge;
import funkin.util.protocol.ProtocolRegistrar;

/**
 * Handles the one-click install feature.
 */
@:nullSafety
class OneClickInstallHandler
{
  static var initialized:Bool = false;

  /**
   * A link that arrived while the player was somewhere we shouldn't yank them out of.
   * The mod menu picks it up the next time it opens.
   */
  static var pendingLink:Null<String> = null;

  /**
   * Whether the feature is compiled in and the platform can actually support it.
   */
  public static function isSupported():Bool
  {
    #if (FEATURE_ONE_CLICK_INSTALL && sys)
    return true;
    #else
    return false;
    #end
  }

  /**
   * Starts listening for incoming links and takes ownership of the handoff lock.
   * Safe to call more than once.
   */
  public static function initialize():Void
  {
    #if (FEATURE_ONE_CLICK_INSTALL && sys)
    if (initialized) return;
    initialized = true;

    OneClickBridge.claimLock();

    if (!ProtocolRegistrar.isRegistered()) ProtocolRegistrar.register();

    FlxG.stage.addEventListener(openfl.events.Event.ENTER_FRAME, onEnterFrame);

    openfl.Lib.application.onExit.add(function(_:Int):Void
    {
      OneClickBridge.releaseLock();
    }, 100);

    #if (macos && cpp)
    funkin.external.apple.URLSchemeExtern.setCallback(cpp.Callable.fromStaticFunction(onAppleURL));
    #end

    // Anything queued while we were booting.
    for (link in OneClickBridge.drain()) handleLink(link);
    #end
  }

  /**
   * Whether a link is waiting for the mod menu to open.
   */
  public static function hasPendingLink():Bool
  {
    #if (FEATURE_ONE_CLICK_INSTALL && sys)
    return pendingLink != null;
    #else
    return false;
    #end
  }

  /**
   * Holds onto the link that launched the game, for the mod menu to pick up once it opens.
   *
   * @param link The link from the command line, if there was one.
   * @return Whether the link was valid enough to be worth opening the mod menu for.
   */
  public static function stashLaunchLink(link:Null<String>):Bool
  {
    #if (FEATURE_ONE_CLICK_INSTALL && sys)
    if (link == null) return false;

    if (ModInstaller.parseLink(link) == null)
    {
      trace('Ignoring a malformed or untrusted one-click link: ${link}');
      return false;
    }

    pendingLink = link;

    return true;
    #else
    return false;
    #end
  }

  /**
   * Routes a link, either straight into an open mod menu or into the pending slot.
   *
   * @param link The full `funkin-mod:` URL.
   */
  public static function handleLink(link:String):Void
  {
    #if (FEATURE_ONE_CLICK_INSTALL && sys)
    final request:Null<OneClickRequest> = ModInstaller.parseLink(link);

    if (request == null)
    {
      trace('Ignoring a malformed or untrusted one-click link: ${link}');
      funkin.util.WindowUtil.showWarning('Mod install failed', 'That install link is malformed, or points at a site we don\'t download from.');
      return;
    }

    focusWindow();

    final menu:Null<funkin.ui.modmenu.ModMenuState> = funkin.ui.modmenu.ModMenuState.instance;

    if (menu != null)
    {
      menu.beginOneClickInstall(request);
      return;
    }

    pendingLink = link;

    if (canInterrupt())
    {
      FlxG.switchState(() -> new funkin.ui.modmenu.ModMenuState());
    }
    else
    {
      trace('Holding a one-click install until the mod menu is opened.');
    }
    #end
  }

  /**
   * Hands over a link that arrived while the mod menu was closed, and clears it.
   *
   * @return The pending request, or null if there isn't one.
   */
  public static function consumePending():Null<OneClickRequest>
  {
    #if (FEATURE_ONE_CLICK_INSTALL && sys)
    if (pendingLink == null) return null;

    final link:String = pendingLink;
    pendingLink = null;

    return ModInstaller.parseLink(link);
    #else
    return null;
    #end
  }

  #if (FEATURE_ONE_CLICK_INSTALL && sys)
  static function onEnterFrame(_:openfl.events.Event):Void
  {
    // Moves a running download's progress and result off its thread and onto this one.
    ModInstaller.pump();

    for (link in OneClickBridge.update()) handleLink(link);
  }

  /**
   * Whether it's reasonable to pull the player into the mod menu right now.
   */
  static function canInterrupt():Bool
  {
    if (FlxG.state == null) return false;
    if (FlxG.state.subState != null) return false;

    return Std.isOfType(FlxG.state, funkin.ui.title.TitleState) || Std.isOfType(FlxG.state, funkin.ui.mainmenu.MainMenuState);
  }

  static function focusWindow():Void
  {
    try
    {
      FlxG.stage.window.focus();
    }
    catch (e:Dynamic)
    {
      trace('Failed to focus the window for a one-click install: ${e}');
    }
  }
  #end

  #if (macos && cpp)
  /**
   * Called from the Apple Event handler. Has to be a plain static function to be callable from C++.
   */
  static function onAppleURL(url:cpp.ConstCharStar):Void
  {
    final link:Null<String> = url == null ? null : Std.string(url);
    if (link == null || link == '') return;

    handleLink(link);
  }
  #end
}
