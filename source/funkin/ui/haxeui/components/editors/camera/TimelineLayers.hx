package funkin.ui.haxeui.components.editors.camera;

import haxe.ui.events.UIEvent;
import haxe.ui.containers.ListView;
import haxe.ui.containers.HBox;
import haxe.ui.containers.Grid;

@:xml('
<listview style="background-color: #222222" width="100%" height="200">
  <data>
    <item layerName="Layer 1"/>
    <item layerName="Layer 2"/>
  </data>
</listview>
')
class TimelineLayers extends ListView
{
  public function new()
  {
    super();
    itemRendererClass = LayerItemRenderer;
  }
}
