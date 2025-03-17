package funkin.ui.debug.mods.components;

import haxe.ui.containers.windows.Window;

@:xml('
  <?xml version="1.0" encoding="utf-8"?>
  <window title="Text File" width="350" height="350">
    <scrollview width="100%" height="100%" contentWidth="100%">
      <label id="modWindowFileLabel"/>
    </scrollview>
  </window>
')
class ModTxtFileViewer extends Window
{
  override public function new(txt:String)
  {
    super();

    modWindowFileLabel.text = txt;
  }
}
