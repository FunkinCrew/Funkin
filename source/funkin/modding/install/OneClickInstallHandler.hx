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
   * Links waiting to be installed, oldest first.
   */
  static var queue:Array<OneClickRequest> = [];

  static var awaitingMenu:Bool = false;

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

    openfl.Lib.application.onExit.add(function(_):Void
    {
      OneClickBridge.releaseLock();
    });

    #if (macos && cpp)
    funkin.external.apple.URLSchemeExtern.setCallback(cpp.Callable.fromStaticFunction(AppleURLCallbacks.onAppleURL));
    #elseif mobile
    funkin.mobile.util.FNFLoaderProvider.onFNFMODOpen.add(handleLink);
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
    return queue.length > 0;
    #else
    return false;
    #end
  }

  /**
   * Holds onto the link that launched the game, for the mod menu to pick up once it opens.
   * @param link The link from the command line, if there was one.
   * @return Whether the link was valid enough to be worth opening the mod menu for.
   */
  public static function stashLaunchLink(link:Null<String>):Bool
  {
    #if (FEATURE_ONE_CLICK_INSTALL && sys)
    if (link == null) return false;

    switch (ModInstaller.parseLink(link))
    {
      case Accepted(request):
        queue.push(request);

        return true;

      case Rejected(reason):
        trace('Ignoring the one-click link "${link}": ${reason}');

        return false;
    }
    #else
    return false;
    #end
  }

  /**
   * Puts a link on the queue, to be installed as soon as the mod menu is open and free.
   * @param link The full `funkin:` URL.
   */
  public static function handleLink(link:String):Void
  {
    #if (FEATURE_ONE_CLICK_INSTALL && sys)
    switch (ModInstaller.parseLink(link))
    {
      case Accepted(request):
        focusWindow();

        queue.push(request);

        pumpQueue();

      case Rejected(reason):
        trace('Ignoring the one-click link "${link}": ${reason}');
        funkin.util.WindowUtil.showWarning('Mod install failed', reason);
    }
    #end
  }

  /**
   * Lines a mod up behind whatever is already going.
   *
   * @param request The submission to install.
   */
  public static function enqueue(request:OneClickRequest):Void
  {
    #if (FEATURE_ONE_CLICK_INSTALL && sys)
    queue.push(request);
    #end
  }

  /**
   * Puts mods at the front of the queue, keeping the order they were given in.
   * @param requests The submissions to install next.
   */
  public static function enqueueNext(requests:Array<OneClickRequest>):Void
  {
    #if (FEATURE_ONE_CLICK_INSTALL && sys)
    if (requests.length == 0) return;

    queue = requests.concat(queue);
    #end
  }

  /**
   * Throws away everything still queued.
   */
  public static function clearQueue():Void
  {
    #if (FEATURE_ONE_CLICK_INSTALL && sys)
    queue = [];
    awaitingMenu = false;
    #end
  }

  #if (FEATURE_ONE_CLICK_INSTALL && sys)
  static function onEnterFrame(_:openfl.events.Event):Void
  {
    // Moves a running download's progress and result off its thread and onto this one.
    ModInstaller.pump();

    for (link in OneClickBridge.update()) handleLink(link);

    pumpQueue();
  }

  /**
   * Pumps the queue, opening the mod menu if necessary and starting the next install if possible.
   */
  static function pumpQueue():Void
  {
    if (queue.length == 0) return;

    final menu:Null<funkin.ui.modmenu.ModMenuState> = funkin.ui.modmenu.ModMenuState.instance;

    if (menu == null)
    {
      // No trace here, this runs every frame and the player may sit on a queued link for a while.
      if (awaitingMenu || !canInterrupt()) return;

      awaitingMenu = true;
      FlxG.switchState(() -> new funkin.ui.modmenu.ModMenuState());
      return;
    }

    awaitingMenu = false;

    if (!menu.isInstalling())
    {
      final request:Null<OneClickRequest> = queue.shift();
      if (request != null) menu.beginOneClickInstall(request);
    }

    // Shown on the card, so the player can tell more mods are lined up behind this one.
    menu.setInstallQueueCount(queue.length);
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
}

#if (macos && cpp)
/**
 * Receives the URL from the Apple Event handler and passes it to the OneClickInstallHandler.
 */
@:nullSafety
@:allow(funkin.modding.install.OneClickInstallHandler)
private class AppleURLCallbacks
{
  /**
   * Called from the Apple Event handler. Has to be a plain static function to be callable from C++.
   */
  static function onAppleURL(url:cpp.ConstCharStar):Void
  {
    final link:Null<String> = url == null ? null : Std.string(url);
    if (link == null || link == '') return;

    OneClickInstallHandler.handleLink(link);
  }
}
#end
