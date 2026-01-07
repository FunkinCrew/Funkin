package funkin.ui.haxeui.components.editors.camera;

import haxe.ui.containers.HBox;

@:xml('
<hbox width="100%">
  <label text="Layer Controls!" />
  <button id="btnRemoveLayer" text="Remove Layer" />
  <button id="btnAddLayer" text="Add Layer" />
  <button text="Play/Pause" toggle="true" />

</hbox>
')
class TimelineControls extends HBox
{
  public function new()
  {
    super();
  }
}
