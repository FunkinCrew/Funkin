package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import haxe.ui.components.Button;
import haxe.ui.containers.dialogs.Dialog;

@:xml('
<dialog width="400">
  <vbox width="100%">
    <label id="messageLabel" width="100%" textAlign="center" />
  </vbox>
</dialog>
')
class DeleteLayerConfirmDialog extends Dialog
{
  var onFlatten:Void->Void;
  var onDelete:Void->Void;

  override public function new(layerName:String, eventCount:Int, onFlatten:Void->Void, onDelete:Void->Void)
  {
    super();

    addClass("no-title");
    this.onFlatten = onFlatten;
    this.onDelete = onDelete;

    var eventWord = eventCount == 1 ? "event" : "events";
    messageLabel.text = 'Delete the layer "$layerName" ($eventCount $eventWord)?';
    var nevermind:DialogButton = "{{Nevermind...}}";
    var flatten:DialogButton = "{{Flatten}}";
    var delete_:DialogButton = "{{Delete}}";
    buttons = nevermind | flatten | delete_;
    defaultButton = "{{Flatten}}";
    destroyOnClose = true;
  }

  override private function onReady()
  {
    super.onReady();
    var flattenBtn = findComponent("{{flatten}}", Button, true);
    var deleteBtn = findComponent("{{delete}}", Button, true);
    if (flattenBtn != null)
      flattenBtn.tooltip = "Remove the layer but move its events to Default layer";
    if (deleteBtn != null)
      deleteBtn.tooltip = "Remove the layer and all its events";
  }

  override public function validateDialog(button:DialogButton, fn:Bool->Void)
  {
    if (button == "{{Flatten}}" && onFlatten != null)
      onFlatten();
    else if (button == "{{Delete}}" && onDelete != null)
      onDelete();

    fn(true);
  }
}
#end
