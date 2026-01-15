package funkin.ui.haxeui.components.editors.camera;

import haxe.ui.events.UIEvent;
import haxe.ui.core.ItemRenderer;

@:xml('
  <item-renderer layout="horizontal" width="100%" height="40">
      <hbox>
        <textfield id="layerName" verticalAlign="center" horizontalAlign="left"/>
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
  // note: for some reason the SUBMIT UI event doesn't occur. HaxeUI related issue on the flixel backend perchance.
  // perhaps this has been fixed upstream?
  //
  // @:bind(layerName, UIEvent.SUBMIT)
  // function onLayerNameSubmit(e):Void
  // {
  //   trace("Submit text" + e.value);
  //   layerName.focus = false;
  // }
}
