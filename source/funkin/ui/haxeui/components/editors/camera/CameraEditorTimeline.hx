package funkin.ui.haxeui.components.editors.camera;

import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;

@:xml('
<vbox width="100%">
  <TimelineControls id="timelineControls"/>
  <TimelineLayers id="timelineLayers"/>
</vbox>
')
class CameraEditorTimeline extends VBox
{
  public function new()
  {
    super();
  }

  @:bind(timelineControls.btnAddLayer, MouseEvent.CLICK)
  function clickAdd(_):Void
  {
    timelineLayers.dataSource.add({layerName: 'Layer ${timelineLayers.dataSource.size + 1}'});
  }

  @:bind(timelineControls.btnRemoveLayer, MouseEvent.CLICK)
  function clickRemove(_):Void
  {
    timelineLayers.dataSource.remove(timelineLayers.selectedItem);
  }
}
