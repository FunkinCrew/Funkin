package funkin.ui.debug.mods.components;

import flixel.graphics.frames.FlxFrame;
import haxe.ui.containers.windows.Window;

@:xml('
  <?xml version="1.0" encoding="utf-8"?>
  <window title="Image File" width="350" height="350">
    <scrollview width="100%" height="100%" contentWidth="100%">
      <image id="modWindowFileImage"/>
    </scrollview>
  </window>
')
class ModImageFileViewer extends Window
{
  override public function new(img:FlxFrame)
  {
    super();

    modWindowFileImage.resource = img;
  }
}
