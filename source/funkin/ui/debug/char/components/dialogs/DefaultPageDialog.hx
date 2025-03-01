package funkin.ui.debug.char.components.dialogs;

import haxe.ui.containers.dialogs.CollapsibleDialog;

class DefaultPageDialog extends CollapsibleDialog
{
  public var page:CharCreatorDefaultPage = null;

  override public function new(page:CharCreatorDefaultPage)
  {
    super();

    modal = false;
    destroyOnClose = false;
    this.page = page;
  }

  override public function set_hidden(value:Bool)
  {
    var playSound = (hidden != value);

    if (playSound && !value) funkin.audio.FunkinSound.playOnce(Paths.sound('chartingSounds/openWindow'));
    else if (playSound && value) funkin.audio.FunkinSound.playOnce(Paths.sound('chartingSounds/exitWindow'));

    return super.set_hidden(value);
  }
}
