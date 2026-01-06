package funkin.ui.haxeui.components.editors.camera;

import haxe.ui.containers.Grid;

@:xml('
<grid>
                <box width="70" height="25" style="background-color: #B41C2B;border:1px solid #B41C2B;background-opacity: .1" />
                <box width="100%" height="25" style="background-color: #B41C2B;border:1px solid #B41C2B;background-opacity: .1" />
                <box width="70" height="25" style="background-color: #B41C2B;border:1px solid #B41C2B;background-opacity: .1" />

                <box width="70" height="100%" style="background-color: #009F42;border:1px solid #009F42;background-opacity: .1" />
                <box width="100%" height="100%" style="background-color: #009F42;border:1px solid #009F42;background-opacity: .1" />
                <box width="70" height="100%" style="background-color: #009F42;border:1px solid #009F42;background-opacity: .1" />

                <box width="70" height="25" style="background-color: #2D70E7;border:1px solid #2D70E7;background-opacity: .1" />
                <box width="100%" height="25" style="background-color: #2D70E7;border:1px solid #2D70E7;background-opacity: .1" />
                <box width="70" height="25" style="background-color: #2D70E7;border:1px solid #2D70E7;background-opacity: .1" />
</grid>
')
class CameraEditorTimeline extends Grid
{
  public function new()
  {
    super();
  }
}
