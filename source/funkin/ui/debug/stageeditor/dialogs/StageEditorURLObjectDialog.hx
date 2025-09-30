package funkin.ui.debug.stageeditor.dialogs;

import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogParams;
import lime.utils.Bytes;
import haxe.ui.components.TextField;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.SecurityErrorEvent;
import openfl.utils.ByteArray;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/stage-editor/dialogs/load-url.xml"))
class StageEditorURLObjectDialog extends StageEditorBaseDialog
{
  var callback:Bytes->Void;
  var onFail:Void->Void;
  var loader:URLLoader;

  public function new(state2:StageEditorState, callback:Bytes->Void, onFail:Void->Void, params2:DialogParams)
  {
    super(state2, params2);

    this.callback = callback;

    buttons = DialogButton.CANCEL | "{{Load}}";
    defaultButton = "{{Load}}";

    loader = new URLLoader();
    loader.dataFormat = BINARY;

    if (loader != null) loader.addEventListener(Event.COMPLETE, function(event:Event) {
      var bytes:Bytes = cast(loader.data, ByteArray);

      if (callback != null) callback(bytes);

      @:privateAccess
      loader.__removeAllListeners();

      this.hideDialog(DialogButton.CANCEL);
    });

    if (loader != null) loader.addEventListener(IOErrorEvent.IO_ERROR, function(event:IOErrorEvent) {
      if (onFail != null) onFail();
    });

    if (loader != null) loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(event:SecurityErrorEvent) {
      if (onFail != null) onFail();
    });

    this.onDialogClosed = function(e:DialogEvent)
    {
      if (e.button.toString() == '{{Load}}')
      {
        e.cancel();
        loader.load(new URLRequest(inputURL.text));
      }
    }
  }

  public static function build(stageEditorState:StageEditorState, callback:Bytes->Void, onFail:Void->Void, ?modal:Bool):StageEditorURLObjectDialog
  {
    var dialog = new StageEditorURLObjectDialog(stageEditorState, callback, onFail,
      {
        closable: false,
        modal: modal ?? true
      });

    dialog.showDialog(modal ?? true);

    return dialog;
  }
}
