package funkin.ui.modmenu;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;
import funkin.modding.PolymodHandler;
import funkin.util.FileUtil;
import funkin.util.PromptUtil;
import haxe.io.Path;
import polymod.PolymodConfig;
#if FEATURE_ONE_CLICK_INSTALL
import funkin.modding.install.ModInstaller;
import funkin.modding.install.ModInstaller.OneClickMod;
import funkin.modding.install.ModInstaller.OneClickRequest;
import funkin.modding.install.OneClickInstallHandler;
#end

/**
 * Manages mod menu installing!
 * Drag and drop + One-click install are handled here.
 * It will NOT however handle the input or the lists, thats a different job.
 */
class ModMenuInstaller
{
  static inline final SHOW_DURATION:Float = 0.5;
  static inline final HIDE_DURATION:Float = -0.08;
  static inline final DARKNESS_MAX_ALPHA:Float = 0.72;
  static inline final DARKNESS_Z_INDEX:Int = 3000;

  final onInstalled:Void->Void;
  final setInputEnabled:Bool->Void;
  final onPromptClosed:Void->Void;

  public var isHovering(default, null):Bool = false;
  public var topZIndex(get, never):Int;

  var darkness:FunkinSprite;
  var dropTarget:FunkinSprite;
  var duration:Float = SHOW_DURATION;
  var elapsed:Float = 0;
  // Starts finished so the first frames of the menu don't run the animation maths.
  var animDone:Bool = true;

  #if FEATURE_ONE_CLICK_INSTALL
  public var popup(default, null):ModMenuInstallPopup;

  var pendingInstall:Null<OneClickMod> = null;
  var installCancelled:Bool = false;
  #end

  public function new(onInstalled:Void->Void, setInputEnabled:Bool->Void, onPromptClosed:Void->Void)
  {
    this.onInstalled = onInstalled;
    this.setInputEnabled = setInputEnabled;
    this.onPromptClosed = onPromptClosed;
  }

  /**
   * God chose me for this fight. God is the teacher, moon is the student and I am the executioner.
   * When I squeeze your lungs Moon, and you beg me for life, then your heart will open up to the lord.
   * When u eat through plastic tube, when you paralyze from waist down then your fmaily will gather down
   * the hostpial bed to see you there. gods lessons are so ebautiful
   * @param state
   * @param camera
   */
  public function build(state:FlxState, camera:FlxCamera):Void
  {
    buildDropOverlay(state, camera);

    #if FEATURE_ONE_CLICK_INSTALL
    popup = new ModMenuInstallPopup();
    popup.zIndex = topZIndex + 1;
    popup.setCamera(camera);
    state.add(popup);
    #end
  }

  public function update(delta:Float):Void
  {
    updateDropOverlay(delta);
  }

  public function destroy():Void
  {
    #if FEATURE_ONE_CLICK_INSTALL
    destroyOneClick();
    #end
  }

  // DRAG AND DROP OVERLAY //

  function buildDropOverlay(state:FlxState, camera:FlxCamera):Void
  {
    darkness = new FunkinSprite();
    darkness.makeSolidColor(FlxG.width, FlxG.height, FlxColor.BLACK);
    darkness.scrollFactor.set(0, 0);
    darkness.alpha = 0;
    darkness.visible = false;
    darkness.zIndex = DARKNESS_Z_INDEX;
    darkness.camera = camera;
    state.add(darkness);

    dropTarget = new FunkinSprite().loadTexture('ui/mods/drop-hover');
    dropTarget.setGraphicSize(FlxG.width * 0.95, FlxG.height * 0.9);
    dropTarget.scrollFactor.set(0, 0);
    dropTarget.updateHitbox();
    dropTarget.x = FlxG.width / 2 - (dropTarget.width / 2);
    dropTarget.y = FlxG.height / 2 - (dropTarget.height / 2);
    dropTarget.visible = false;
    dropTarget.zIndex = darkness.zIndex + 1;
    dropTarget.camera = camera;
    state.add(dropTarget);
  }

  public function showDropOverlay():Void
  {
    isHovering = true;
    duration = SHOW_DURATION;
    elapsed = 0;
    animDone = false;

    dropTarget.visible = true;
    darkness.visible = true;
    darkness.alpha = 0;
    dropTarget.alpha = 0;
  }

  public function hideDropOverlay():Void
  {
    isHovering = false;
    duration = HIDE_DURATION;
    elapsed = 0;
    animDone = false;
  }

  function updateDropOverlay(delta:Float):Void
  {
    if (animDone) return;

    elapsed += delta;
    var t = elapsed / duration;

    var adjustT = t;
    if (adjustT < 0) adjustT += 1;

    if (t > 1)
    {
      t = 1;
      animDone = true;
    }
    else if (t < -1)
    {
      t = -1;
      animDone = true;
      dropTarget.visible = false;
      darkness.visible = false;
    }

    dropTarget.alpha = FlxMath.lerp(0, 1, FlxEase.backOut(adjustT));
    darkness.alpha = FlxMath.lerp(0, DARKNESS_MAX_ALPHA, FlxEase.backOut(adjustT));
  }

  // DROPPED FILES //

  public function installDropped(file:lime.utils.DroppedFile):Void
  {
    if (StringTools.endsWith(file.path, '.zip'))
    {
      installZip(file.path);
    }
    else if (Path.isAbsolute(file.path) && FileUtil.directoryExists(file.path))
    {
      installFolder(file.path);
    }
    else
    {
      showInvalidPrompt();
    }
  }

  function installZip(path:String):Void
  {
    var fileClean = StringTools.replace(path, '\\', '/');
    var fileName = StringTools.replace(path.substring(fileClean.lastIndexOf('/') + 1), '.zip', '');
    var destPath = PolymodHandler.MOD_FOLDER + '/' + fileName + '.zip';

    try
    {
      FileUtil.moveFile(path, destPath);
    }
    catch (e:Dynamic)
    {
      trace('Failed to move file: ' + e);
      openFailedPrompt();
      return;
    }

    onInstalled();
  }

  function installFolder(path:String):Void
  {
    if (!FileUtil.pathExists(Path.join([path, PolymodConfig.modMetadataFile])))
    {
      openFailedPrompt(true);
      return;
    }

    try
    {
      FileUtil.copyDirectory(path, Path.join([PolymodHandler.MOD_FOLDER, Path.withoutDirectory(path)]));
    }
    catch (e:Dynamic)
    {
      trace('Failed to move folder: ' + e);
      openFailedPrompt(false, true);
      return;
    }

    onInstalled();
  }

  function showInvalidPrompt():Void
  {
    setInputEnabled(false);

    PromptUtil.openPrompt({
      icon: 'question',
      title: 'HEADS UP!',
      description: 'Only .zip files and mod folders are supported for mod installation.',
      buttons: [{
        text: 'Okay',
        defaultCancel: true,
        callback: onPromptClosed
      }]
    }, [0, 50]);
  }

  function openFailedPrompt(metadata:Bool = false, folder:Bool = false):Void
  {
    var description:String = '';
    if (metadata)
    {
      description = 'Could not find required metadata inside the folder, are you sure this is a mod pack?';
    }
    else if (folder)
    {
      description = 'Could not move the folder to the mods folder. Check the logs for details.';
    }
    else
    {
      description = 'Could not move the .zip file to the mods folder. Check the logs for details.';
    }

    PromptUtil.openPrompt({
      icon: 'warning',
      title: 'FAILED TO INSTALL!',
      description: description,
      buttons: [{
        text: 'Okay',
        defaultCancel: true,
        callback: onPromptClosed
      }]
    }, [0, 50]);
  }

  // ONE-CLICK INSTALL //
  #if FEATURE_ONE_CLICK_INSTALL
  public function beginOneClick(request:OneClickRequest):Void
  {
    // One at a time. A second link while one is running would fight over the popup.
    if (popup.isBlocking())
    {
      trace('Ignoring a one-click install, one is already in progress.');
      return;
    }

    pendingInstall = null;
    installCancelled = false;

    popup.showBusy('Mod Install', 'Looking this one up on GameBanana...');

    ModInstaller.fetchMetadata(request, function(mod:OneClickMod):Void
    {
      if (installCancelled) return;

      if (ModInstaller.isAlreadyInstalled(mod))
      {
        popup.showResult(mod.name, 'Already installed.');
        return;
      }

      pendingInstall = mod;

      startDownload();

      ModInstaller.downloadIcon(mod, function(bytes:openfl.utils.ByteArray):Void
      {
        if (installCancelled) return;

        popup.setIcon(bytes);
      });
    }, function(reason:String):Void
    {
      if (installCancelled) return;

      pendingInstall = null;
      popup.showResult('Mod Install Failed', reason);
    });
  }

  public function isInstalling():Bool
  {
    return popup.isBlocking();
  }

  public function setQueueCount(count:Int):Void
  {
    popup.setQueueCount(count);
  }

  public function cancelOneClick():Void
  {
    stop();
    popup.hide();
  }

  function destroyOneClick():Void
  {
    stop();

    OneClickInstallHandler.clearQueue();
  }

  function stop():Void
  {
    installCancelled = true;
    pendingInstall = null;
    ModInstaller.cancelDownload();
    ModInstaller.cancelInstall();
  }

  function startDownload():Void
  {
    final mod:Null<OneClickMod> = pendingInstall;
    if (mod == null) return;

    // TODO: Could be done better..?? I don't know. Look into it moon. -Moon.

    final credit:String = 'by ${mod.author}  (${formatFilesize(mod.filesize)})';

    popup.showProgress(mod.name, '${credit}\nDownloading...', 0);

    ModInstaller.download(mod, function(ratio:Float):Void
    {
      if (installCancelled) return;

      popup.showProgress(mod.name, '${credit}\nDownloading... ${Math.round(ratio * 100)}%', ratio);
    }, function(archivePath:String):Void
    {
      if (installCancelled) return;

      popup.showProgress(mod.name, '${credit}\nInstalling...', 0);

      ModInstaller.install(mod, archivePath, function(ratio:Float):Void
      {
        if (installCancelled) return;

        popup.showProgress(mod.name, '${credit}\nInstalling... ${Math.round(ratio * 100)}%', ratio);
      }, function(paths:Array<String>):Void
      {
        if (installCancelled) return;

        queueRequirements(mod);

        finish(mod);
      }, function(reason:String):Void
      {
        if (installCancelled) return;

        popup.showResult(mod.name, 'Install failed.\n${reason}');
      });
    }, function(reason:String):Void
    {
      if (installCancelled) return;

      popup.showResult(mod.name, reason);
    });
  }

  function queueRequirements(mod:OneClickMod):Void
  {
    final requests:Array<OneClickRequest> = [];

    for (requirement in mod.requirements)
    {
      final request:Null<OneClickRequest> = ModInstaller.requestForRequirement(requirement);

      if (request == null) continue;

      requests.push(request);
    }

    OneClickInstallHandler.enqueueNext(requests);
  }

  function finish(mod:OneClickMod):Void
  {
    onInstalled();

    popup.showResult(mod.name, 'Installed. Drag it over to turn it on.');
  }

  function formatFilesize(bytes:Int):String
  {
    if (bytes <= 0) return '';

    if (bytes < 1024 * 1024) return '${Math.round(bytes / 1024)} KB';

    return '${Math.round(bytes / (1024 * 1024))} MB';
  }
  #end

  // Getters / helpers

  function get_topZIndex():Int
  {
    return dropTarget.zIndex;
  }
}
