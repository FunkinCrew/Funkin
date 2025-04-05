package funkin.ui.debug.stageeditor.components;

import haxe.ui.containers.dialogs.Dialog;
import lime.utils.Bytes;
import haxe.ui.components.TextField;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.SecurityErrorEvent;
import openfl.utils.ByteArray;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/stage-editor/dialogs/load-url.xml"))
class LoadFromUrlDialog extends Dialog
{
  var urlField:TextField;
  var loader:URLLoader;

  override public function new(successCallback:Bytes->Void = null, failCallback:String->Void = null)
  {
    super();
    destroyOnClose = true;

    loader = new URLLoader();
    loader.dataFormat = BINARY;

    urlField.text = "";

    loader.addEventListener(Event.COMPLETE, function(event:Event) {
      var bytes:Bytes = cast(loader.data, ByteArray);

      if (successCallback != null) successCallback(bytes);

      trace("loaded the image and did success callback");

      @:privateAccess
      loader.__removeAllListeners();

      hideDialog(DialogButton.CANCEL);
    });

    loader.addEventListener(IOErrorEvent.IO_ERROR, function(event:IOErrorEvent) {
      if (failCallback != null) failCallback(urlField.text);

      trace("error with this shit");
    });

    loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(event:SecurityErrorEvent) {
      if (failCallback != null) failCallback(urlField.text);

      trace("error with this shit");
    });

    buttons = DialogButton.CANCEL | "{{Load}}";
    defaultButton = "{{Load}}";
  }

  override public function validateDialog(button:DialogButton, fn:Bool->Void)
  {
    if (button == DialogButton.CANCEL)
    {
      fn(true);
    }
    else
    {
      loader.load(new URLRequest(urlField.text));
    }
  }
}
