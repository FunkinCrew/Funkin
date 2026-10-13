package funkin.ui.modmenu;

import funkin.modding.PolymodHandler;
import funkin.util.FileUtil;
import funkin.util.PromptUtil;
import haxe.io.Path;
import polymod.PolymodConfig;

class ModMenuFileInstaller
{
  final onInstalled:Void->Void;
  final setInputEnabled:Bool->Void;
  final onPromptClosed:Void->Void;

  public function new(onInstalled:Void->Void, setInputEnabled:Bool->Void, onPromptClosed:Void->Void)
  {
    this.onInstalled = onInstalled;
    this.setInputEnabled = setInputEnabled;
    this.onPromptClosed = onPromptClosed;
  }

  public function install(file:lime.utils.DroppedFile):Void
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
}
