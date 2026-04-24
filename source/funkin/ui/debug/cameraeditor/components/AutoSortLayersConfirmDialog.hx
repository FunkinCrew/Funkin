package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import funkin.ui.debug.cameraeditor.commands.AutoSortLayersCommand.AutoSortPlan;
import haxe.ui.containers.dialogs.Dialog;

@:xml('
<dialog width="460">
  <vbox width="100%" style="padding: 8px;">
    <label id="messageLabel" width="100%" textAlign="center" />
    <label id="previewLabel" width="100%" textAlign="left" style="padding-top: 8px;" />
    <label id="hintLabel" width="100%" textAlign="center" style="padding-top: 8px; color: #999999;" />
  </vbox>
</dialog>
')
class AutoSortLayersConfirmDialog extends Dialog
{
  var onSort:Void->Void;

  override public function new(currentLayerName:String, currentEventCount:Int, plan:AutoSortPlan, onSort:Void->Void)
  {
    super();

    addClass("no-title");
    this.onSort = onSort;

    var eventWord:String = currentEventCount == 1 ? "event" : "events";
    messageLabel.text = 'Detected that Camera events in this chart overlap on a single layer. Organize onto separate layers by event type?';

    var lines:Array<String> = [];
    lines.push("Before");
    lines.push('  $currentLayerName ($currentEventCount $eventWord)');
    lines.push("After");
    for (planLayer in plan.layers)
    {
      var moveWord:String = planLayer.events.length == 1 ? "event" : "events";
      lines.push('  ${planLayer.name} (moving ${planLayer.events.length} $moveWord)');
    }
    previewLabel.text = lines.join("\n");

    hintLabel.text = "You can run this later from the 'Generate' menu.";

    var skip:DialogButton = "{{Skip}}";
    var sort:DialogButton = "{{Sort}}";
    buttons = skip | sort;
    defaultButton = "{{Sort}}";
    destroyOnClose = true;
  }

  override public function validateDialog(button:DialogButton, fn:Bool->Void)
  {
    if (button == "{{Sort}}" && onSort != null) onSort();

    fn(true);
  }
}
#end
