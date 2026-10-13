package funkin.ui.modmenu;

#if FEATURE_ONE_CLICK_INSTALL
import funkin.modding.install.ModInstaller;
import funkin.modding.install.ModInstaller.OneClickMod;
import funkin.modding.install.ModInstaller.OneClickRequest;
import funkin.modding.install.OneClickInstallHandler;

class ModMenuOneClickInstall
{
  final popup:ModMenuInstallPopup;
  final onInstalled:Void->Void;
  var pendingInstall:Null<OneClickMod> = null;
  var installCancelled:Bool = false;

  public function new(popup:ModMenuInstallPopup, onInstalled:Void->Void)
  {
    this.popup = popup;
    this.onInstalled = onInstalled;
  }

  public function begin(request:OneClickRequest):Void
  {
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

  public function cancel():Void
  {
    stop();
    popup.hide();
  }

  public function destroy():Void
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
}
#end
