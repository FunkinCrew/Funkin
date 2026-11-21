package funkin.modding.install;

import flixel.FlxG;
import flixel.FlxState;
import funkin.ui.modmenu.ModMenuInstallPopup;
import funkin.ui.transition.Transition;
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

    #if ((windows || linux) && !mobile)
    OneClickBridge.claimLock();
    #end

    if (!ProtocolRegistrar.isRegistered()) ProtocolRegistrar.register();

    FlxG.stage.addEventListener(openfl.events.Event.ENTER_FRAME, onEnterFrame);

    #if ((windows || linux) && !mobile)
    openfl.Lib.application.onExit.add(function(_):Void
    {
      OneClickBridge.releaseLock();
    });
    #end

    #if (macos && cpp)
    funkin.external.apple.URLSchemeExtern.setCallback(cpp.Callable.fromStaticFunction(AppleURLCallbacks.onAppleURL));
    #elseif mobile
    funkin.util.mobile.FNFLoaderProvider.onFNFMODOpen.add(handleLink);
    #end

    #if ((windows || linux) && !mobile)
    // Anything queued while we were booting.
    for (link in OneClickBridge.drain()) handleLink(link);
    #end
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
   * Puts a link on the queue, to be installed as soon as an installer is free.
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
  static var activeInstaller:Null<funkin.ui.modmenu.ModMenuInstaller> = null;
  static var activeInstallProgress:Null<{
    title:String,
    detail:String,
    ratio:Null<Float>,
    estimate:String,
    icon:Null<openfl.utils.ByteArray>
  }> = null;
  static var attachedInstallPopup:Null<ModMenuInstallPopup> = null;
  static var installNotifications:Array<
    {name:String, detail:String, icon:Null<openfl.utils.ByteArray>}> = [];
  static var activeNotification:Null<ModMenuInstallPopup> = null;
  static var activeNotificationState:Null<FlxState> = null;

  public static function setActiveInstaller(installer:funkin.ui.modmenu.ModMenuInstaller):Void
  {
    activeInstaller = installer;
  }

  public static function onInstallerIdle(installer:funkin.ui.modmenu.ModMenuInstaller):Void
  {
    if (activeInstaller == installer && queue.length == 0 && !installer.isInstalling()) activeInstaller = null;
  }

  public static function isInstallerBusy():Bool
  {
    final installer:Null<funkin.ui.modmenu.ModMenuInstaller> = activeInstaller;
    return installer != null && installer.isInstalling();
  }

  public static function cancelActiveInstall():Void
  {
    final installer:Null<funkin.ui.modmenu.ModMenuInstaller> = activeInstaller;
    if (installer != null) installer.cancelOneClick();
  }

  public static function attachInstallPopup(popup:ModMenuInstallPopup):Void
  {
    attachedInstallPopup = popup;
    popup.setQueueCount(queue.length);

    final progress = activeInstallProgress;
    if (progress != null) showProgressOnPopup(popup, progress);
  }

  public static function detachInstallPopup(popup:ModMenuInstallPopup):Void
  {
    if (attachedInstallPopup == popup) attachedInstallPopup = null;
  }

  public static function updateInstallProgress(title:String, detail:String, ratio:Null<Float>, estimate:String = ''):Void
  {
    final previous = activeInstallProgress;
    final icon:Null<openfl.utils.ByteArray> = previous == null ? null : previous.icon;
    final progress = {
      title: title,
      detail: detail,
      ratio: ratio,
      estimate: estimate,
      icon: icon
    };
    activeInstallProgress = progress;

    final popup:Null<ModMenuInstallPopup> = attachedInstallPopup;
    if (popup != null) showProgressOnPopup(popup, progress);
  }

  public static function updateInstallIcon(icon:openfl.utils.ByteArray):Void
  {
    final progress = activeInstallProgress;
    if (progress == null) return;

    progress.icon = icon;

    final popup:Null<ModMenuInstallPopup> = attachedInstallPopup;
    if (popup != null) popup.setIcon(icon);
  }

  public static function reportInstallResult(name:String, detail:String, icon:Null<openfl.utils.ByteArray>):Void
  {
    final progress = activeInstallProgress;
    final resultIcon:Null<openfl.utils.ByteArray> = icon != null ? icon : (progress == null ? null : progress.icon);
    activeInstallProgress = null;

    final popup:Null<ModMenuInstallPopup> = attachedInstallPopup;
    if (popup != null)
    {
      if (resultIcon != null) popup.setIcon(resultIcon);
      popup.showResult(name, detail);
    }
    else
    {
      installNotifications.push({
        name: name,
        detail: detail,
        icon: resultIcon
      });
    }
  }

  public static function clearInstallProgress():Void
  {
    activeInstallProgress = null;

    final popup:Null<ModMenuInstallPopup> = attachedInstallPopup;
    if (popup != null) popup.hide();
  }

  public static function setInstallQueueCount(count:Int):Void
  {
    final popup:Null<ModMenuInstallPopup> = attachedInstallPopup;
    if (popup != null) popup.setQueueCount(count);
  }

  static function showProgressOnPopup(popup:ModMenuInstallPopup,
    progress:{
      title:String,
      detail:String,
      ratio:Null<Float>,
      estimate:String,
      icon:Null<openfl.utils.ByteArray>
    }):Void
  {
    if (progress.ratio == null)
    {
      popup.showBusy(progress.title, progress.detail);
    }
    else
    {
      popup.showProgress(progress.title, progress.detail, progress.ratio, progress.estimate);
    }

    final icon:Null<openfl.utils.ByteArray> = progress.icon;
    if (icon != null) popup.setIcon(icon);
  }

  static function onEnterFrame(_:openfl.events.Event):Void
  {
    // Moves a running download's progress and result off its thread and onto this one.
    ModInstaller.pump();
    pumpInstallNotifications();

    #if ((windows || linux) && !mobile)
    for (link in OneClickBridge.update()) handleLink(link);
    #end

    pumpQueue();
  }

  static function pumpInstallNotifications():Void
  {
    final state:Null<FlxState> = getNotificationState();
    final notification:Null<ModMenuInstallPopup> = activeNotification;
    final owner:Null<FlxState> = activeNotificationState;

    if (notification != null && owner != state)
    {
      activeNotification = null;
      activeNotificationState = null;
    }
    else if (notification != null && !notification.visible)
    {
      if (owner != null)
      {
        owner.remove(notification, true);
        notification.destroy();
      }

      activeNotification = null;
      activeNotificationState = null;
    }

    if (activeNotification != null || installNotifications.length == 0 || state == null) return;

    final cameras = FlxG.cameras.list;
    if (cameras.length == 0) return;

    final result = installNotifications.shift();
    if (result == null) return;

    final popup = new ModMenuInstallPopup();
    popup.zIndex = 1_000_000;
    popup.setCamera(cameras[cameras.length - 1]);
    popup.showResult(result.name, result.detail);
    final icon:Null<openfl.utils.ByteArray> = result.icon;
    if (icon != null) popup.setIcon(icon);
    state.add(popup);

    activeNotification = popup;
    activeNotificationState = state;
  }

  static function getNotificationState():Null<FlxState>
  {
    final state:Null<FlxState> = FlxG.state;
    if (state == null) return null;

    return state.subState == null ? state : state.subState;
  }

  static function pumpQueue():Void
  {
    if (queue.length == 0) return;

    final menu:Null<funkin.ui.modmenu.ModMenuState> = funkin.ui.modmenu.ModMenuState.instance;
    final installer:Null<funkin.ui.modmenu.ModMenuInstaller> = activeInstaller;

    if (installer != null && installer.isInstalling())
    {
      installer.setQueueCount(queue.length);
      return;
    }

    if (menu == null)
    {
      if (installer != null)
      {
        final request:Null<OneClickRequest> = queue.shift();
        if (request != null) installer.beginOneClick(request);
        installer.setQueueCount(queue.length);
        return;
      }

      // No trace here, this runs every frame and the player may sit on a queued link for a while.
      if (awaitingMenu || !canInterrupt()) return;

      awaitingMenu = true;
      Transition.switchState(() -> new funkin.ui.modmenu.ModMenuState(), {
        assetQuery: funkin.ui.modmenu.ModMenuState.queryAssets,
        transition: BlackScreen(None, Fade(South))
      });
      return;
    }

    awaitingMenu = false;

    if (!menu.installer.isInstalling())
    {
      activeInstaller = menu.installer;
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
