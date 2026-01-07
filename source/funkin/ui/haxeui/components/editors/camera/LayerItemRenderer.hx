package funkin.ui.haxeui.components.editors.camera;

import haxe.ui.events.UIEvent;
import haxe.ui.core.ItemRenderer;

@:xml('
  <item-renderer layout="horizontal" width="100%" height="40">
      <hbox>
        <label id="layerName" verticalAlign="center" horizontalAlign="left"/>
      </hbox>
      <vbox width="80%" height="100%" id="layerFrames">
          <label text="Layer stuff here" />
      </vbox>
  </item-renderer>
  ')
class LayerItemRenderer extends ItemRenderer
{
  public function new():Void
  {
    super();
  }

}
