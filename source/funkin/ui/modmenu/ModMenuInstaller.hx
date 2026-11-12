package funkin.ui.modmenu;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;
import funkin.modding.PolymodHandler;
import funkin.util.FileUtil;
import funkin.util.WindowUtil;
import haxe.io.Path;
import polymod.PolymodConfig;
#if FEATURE_ONE_CLICK_INSTALL
import funkin.modding.install.ModInstaller.OneClickMod;
import funkin.modding.install.ModInstaller.OneClickRequest;
import funkin.modding.install.ModInstaller;
import funkin.modding.install.OneClickInstallHandler;
#end

/**
 * Manages mod menu installing!
 * Drag and drop + One-click install are handled here.
 * It will NOT however handle the input or the lists, thats a different job.
 */
class ModMenuInstaller
{
  /**
   * How long would it take to reveal the drop overlay, in seconds.
   */
  static inline final SHOW_DURATION:Float = 0.5;

  /**
   * How long would it take to hide the drop overlay, in seconds.
   */
  static inline final HIDE_DURATION:Float = -0.2;

  /**
   * The max alpha for the dark background.
   */
  static inline final DARKNESS_MAX_ALPHA:Float = 0.72;

  /**
   * The zIndex value for the dark background.
   */
  static inline final DARKNESS_Z_INDEX:Int = 3000;

  /**
   * Called when the install finishes
   */
  final onInstalled:Void->Void;

  /**
   * Callback to disable/enable input.
   */
  final setInputEnabled:Bool->Void;

  /**
   * Whether the drop overlay is currently visible and hovering or not.
   */
  public var isHovering(default, null):Bool = false;

  /**
   * Gets the drop overlay zIndex, which is supposed to be at the very top
   */
  public var topZIndex(get, never):Int;

  /**
   * The dark bg behind the drop overlay.
   */
  var darkness:FunkinSprite;

  /**
   * The drop here to install overlay.
   */
  var dropTarget:FunkinSprite;

  /**
   * Current duration.
   */
  var duration:Float = SHOW_DURATION;

  /**
   * elapsed.
   */
  var elapsed:Float = 0;

  /**
   * Whether animation is done.
   * Defaults to finished so the first frames of the menu don't run the animation maths.
   */
  var animDone:Bool = true;

  #if FEATURE_ONE_CLICK_INSTALL
  /**
   * The pop up for one click install.
   */
  public var popup(default, null):ModMenuInstallPopup;

  /**
   * The pending installation we have.
   */
  var pendingInstall:Null<OneClickMod> = null;

  /**
   * Whether the installation was cancelled or not.
   */
  var installCancelled:Bool = false;
  #end

  /**
   * Creates a new installer instance.
   * @param onInstalled What to call once installing finishes.
   * @param setInputEnabled What to call to toggle the input.
   */
  public function new(onInstalled:Void->Void, setInputEnabled:Bool->Void)
  {
    this.onInstalled = onInstalled;
    this.setInputEnabled = setInputEnabled;
  }

  /**
   * Builds the drop overlay and the one-click install pop-up.
   * @param camera The camera to use.
   */
  public function build(camera:FlxCamera):Void
  {
    if (ModMenuState.instance == null) return;
    buildDropOverlay(camera);

    #if FEATURE_ONE_CLICK_INSTALL
    popup = new ModMenuInstallPopup();
    popup.zIndex = topZIndex + 1;
    popup.setCamera(camera);
    ModMenuState.instance.add(popup);
    #end
  }

  /**
   * Updates the installer, duh
   * @param delta Delta
   */
  public function update(delta:Float):Void
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

  // DRAG AND DROP OVERLAY //

  /**
   * Builds the drag and drop overlay then adds it to the mod menu.
   * @param camera The camera to use.
   */
  function buildDropOverlay(camera:FlxCamera):Void
  {
    if (ModMenuState.instance == null) return;

    darkness = new FunkinSprite();
    darkness.makeSolidColor(FlxG.width, FlxG.height, FlxColor.BLACK);
    darkness.scrollFactor.set(0, 0);
    darkness.alpha = 0;
    darkness.visible = false;
    darkness.zIndex = DARKNESS_Z_INDEX;
    darkness.camera = camera;
    ModMenuState.instance.add(darkness);

    dropTarget = new FunkinSprite().loadTexture('ui/mods/drop-hover');
    dropTarget.setGraphicSize(FlxG.width * 0.95, FlxG.height * 0.9);
    dropTarget.scrollFactor.set(0, 0);
    dropTarget.updateHitbox();
    dropTarget.x = FlxG.width / 2 - (dropTarget.width / 2);
    dropTarget.y = FlxG.height / 2 - (dropTarget.height / 2);
    dropTarget.visible = false;
    dropTarget.zIndex = darkness.zIndex + 1;
    dropTarget.camera = camera;
    ModMenuState.instance.add(dropTarget);
  }

  /**
   * Reveals the drag and drop overlay.
   */
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

  /**
   * Hides the drag and drop overlay.
   */
  public function hideDropOverlay():Void
  {
    isHovering = false;
    duration = HIDE_DURATION;
    elapsed = 0;
    animDone = false;
  }

  #if (sys || (js && html5))
  static function isArchiveModExtension(fileName:String):Bool
  {
    if (fileName == null) return false;
    final extension:String = Path.extension(fileName);
    final normalizedExtension = extension.toLowerCase();
    final archiveExtensions = PolymodConfig.archiveModExt ?? ['.zip'];

    for (archiveExtension in archiveExtensions)
    {
      final normalizedArchiveExtension = archiveExtension.toLowerCase();
      final withoutDot = normalizedArchiveExtension.startsWith('.') ? normalizedArchiveExtension.substr(1) : normalizedArchiveExtension;

      if (withoutDot == normalizedExtension) return true;
    }

    return false;
  }
  #end

  // DROPPED FILES //

  /**
   * Installs the dropped zip/folder, rejects it if it is neither.
   * @param file The file to install
   */
  public function installDropped(file:lime.utils.DroppedFile):Void
  {
    #if sys
    if (isArchiveModExtension(file.path))
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
    #elseif (js && html5)
    if (isArchiveModExtension(file.path))
    {
      file.readFile().onComplete(function(bytes:haxe.io.Bytes)
      {
        if (bytes == null)
        {
          WindowUtil.showError('Failed to load mod', 'Could not read the dropped archive file.');
          return;
        }

        PolymodHandler.addModByBytes(file.path, bytes);
      }).onError(function(error:Dynamic)
      {
          trace('Failed to read dropped archive: $error');
          WindowUtil.showError('Failed to load mod', 'Could not read the dropped archive file. Check logs for details.');
      });
    }
    #end
  }

  /**
   * Installs the zip dropped into the mod folder.
   * @param path The path to the zip to install.
   */
  function installZip(path:String):Void
  {
    var ext = Path.extension(path);
    var fileClean = StringTools.replace(path, '\\', '/');
    var fileName = StringTools.replace(path.substring(fileClean.lastIndexOf('/') + 1), '.$ext', '');
    var destPath = PolymodHandler.MOD_FOLDER + '/' + fileName + '.$ext';

    try
    {
      FileUtil.moveFile(path, destPath);
    }
    catch (e:Dynamic)
    {
      trace(' MOD MENU '.bold().bg_orange() + ' Failed to move file: ' + e);
      openFailedPrompt();
      return;
    }

    onInstalled();
  }

  /**
   * Installs the folder dropped into the mod folder
   * @param path The path to the folder to install.
   */
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
      trace(' MOD MENU '.bold().bg_orange() + ' Failed to move folder: ' + e);
      openFailedPrompt(false, true);
      return;
    }

    onInstalled();
  }

  /**
   * Triggers a prompt that tells you the file you dropped isn't supported.
   */
  function showInvalidPrompt():Void
  {
    setInputEnabled(false);

    WindowUtil.showError(
      'Failed to install mod',
      'Only ${(PolymodConfig.archiveModExt ?? ['.zip']).join(", ")} files and mod folders are supported for mod installation.'
    );
  }

  /**
   * Triggers a prompt that tells you installation failed and why.
   * @param metadata Whether its metadata related or not.
   * @param folder Whether its folder related or not.
   */
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

    WindowUtil.showError('Failed to install mod', description);
  }

  // ONE-CLICK INSTALL //

  #if FEATURE_ONE_CLICK_INSTALL
  /**
   * Begins the one click install
   * @param request The request to use.
   */
  public function beginOneClick(request:OneClickRequest):Void
  {
    // One at a time. A second link while one is running would fight over the popup.
    if (popup.isBlocking())
    {
      trace(' MOD MENU '.bold().bg_orange() + ' Ignoring a one-click install, one is already in progress.');
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

  /**
   * Is a one-click install happening right now or not.
   * @return Bool
   */
  public function isInstalling():Bool
  {
    return popup.isBlocking();
  }

  /**
   * Sets the queue amount of installs happening in the pop up.
   * @param count How many installs there are.
   */
  public function setQueueCount(count:Int):Void
  {
    popup.setQueueCount(count);
  }

  /**
   * Cancels the one click install (if one is happening right now).
   */
  public function cancelOneClick():Void
  {
    stop();
    popup.hide();
  }

  /**
   * Clears the one click install specifically.
   */
  function destroyOneClick():Void
  {
    stop();

    OneClickInstallHandler.clearQueue();
  }

  /**
   * Force stop the one click install.
   */
  function stop():Void
  {
    installCancelled = true;
    pendingInstall = null;
    ModInstaller.cancelDownload();
    ModInstaller.cancelInstall();
  }

  /**
   * Starts the download for the one click install.
   */
  function startDownload():Void
  {
    final mod:Null<OneClickMod> = pendingInstall;
    if (mod == null) return;

    // TODO: Could be done better..?? I don't know. Look into it moon. -Moon.

    final credit:String = 'by ${mod.author}  (${formatFilesize(mod.filesize)})';

    popup.showProgress(mod.name, '${credit}\nDownloading...', 0);

    ModInstaller.download(mod, function(bytesLoaded:Int, bytesTotal:Int):Void
    {
      if (installCancelled) return;

      final ratio:Float = bytesLoaded / bytesTotal;

      popup.showProgress(mod.name, '${credit}\nDownloading... ${Math.round(ratio * 100)}%\n${formatFilesize(bytesLoaded + 1)} out of ${formatFilesize(bytesTotal)}', ratio);
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

        onInstalled();
        popup.showResult(mod.name, 'Installed!');
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

  /**
   * Queue-install the requirements for the mod we want to download.
   * @param mod The mod we want to install.
   */
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

  /**
   * Formats the file size to MB.
   * @param bytes The bytes to format
   * @return String The string once formatted.
   */
  function formatFilesize(bytes:Int):String
  {
    if (bytes <= 0) return '';

    if (bytes < 1024 * 1024) return '${Math.round(bytes / 1024)} KB';

    return '${Math.round(bytes / (1024 * 1024))} MB';
  }
  #end

  /**
   * Destroys the installer.
   * TODO: Make this class a destroyable, maybe.. -Moon.
   */
  public function destroy():Void
  {
    #if FEATURE_ONE_CLICK_INSTALL
    destroyOneClick();
    #end
  }

  // Getters / helpers

  function get_topZIndex():Int
  {
    return dropTarget.zIndex;
  }
}
