package funkin.ui.haxeui.components.editors.camera;

import haxe.ui.containers.HBox;

@:xml('
<hbox width="100%" backgroundColor="#222222">
  <label text="Layer Controls!" />
  <button id="btnRemoveLayer" text="Remove Layer" />
  <button id="btnAddLayer" text="Add Layer" />
  <button id="btnTogglePlayback" text="Play/Pause" allowFocus="false" />
  <label id="lblTime" text="0:00.00/0:00.00" />
</hbox>
')
class TimelineControls extends HBox
{
  public function new()
  {
    super();
  }
}
