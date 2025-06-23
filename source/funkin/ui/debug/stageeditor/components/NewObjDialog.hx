package funkin.ui.debug.stageeditor.components;

import haxe.ui.containers.dialogs.Dialog;
import funkin.ui.debug.stageeditor.handlers.AssetDataHandler;
import openfl.display.BitmapData;
import haxe.ui.notifications.NotificationType;
import haxe.ui.notifications.NotificationManager;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/stage-editor/dialogs/new-object.xml"))
class NewObjDialog extends Dialog
{
  var stageEditorState:StageEditorState;
  var bitmap:BitmapData;

  override public function new(state:StageEditorState, img:BitmapData = null)
  {
    super();

    stageEditorState = state;
    bitmap = img;

    field.onChange = function(_) {
      field.removeClasses(["invalid-value", "valid-value"]);
    }

    buttons = DialogButton.CANCEL | "{{Create}}";
    defaultButton = "{{Create}}";

    destroyOnClose = true;
  }

  public override function validateDialog(button:DialogButton, fn:Bool->Void)
  {
    var done = true;

    if (button == "{{Create}}")
    {
      var objNames = [for (obj in StageEditorState.instance.spriteArray) obj.name];

      if (field.text == "" || field.text == null || objNames.contains(field.text))
      {
        field.swapClass("invalid-value", "valid-value");
        done = false;
        NotificationManager.instance.addNotification(
          {
            title: "Problem Creating an Object",
            body: objNames.contains(field.text) ? "Object with the Name " + field.text + " already exists!" : "Invalid Object Name!",
            type: NotificationType.Error
          });
      }
      else
      {
        var spr = new StageEditorObject();

        if (bitmap != null)
        {
          var bitToLoad = stageEditorState.addBitmap(bitmap);
          spr.loadGraphic(stageEditorState.bitmaps[bitToLoad]);
        }
        else
          spr.loadGraphic(AssetDataHandler.getDefaultGraphic());

        spr.name = field.text;
        spr.screenCenter();

        var sprArray = stageEditorState.spriteArray;
        spr.zIndex = sprArray.length == 0 ? 0 : (sprArray[sprArray.length - 1].zIndex + 1);

        stageEditorState.selectedSprite = spr;
        stageEditorState.createAndPushAction(OBJECT_CREATED);

        stageEditorState.add(spr);
        stageEditorState.updateArray();
        stageEditorState.saved = false;

        NotificationManager.instance.addNotification(
          {
            title: "Object Creating Successful",
            body: "Successfully created an Object with the Name " + field.text + "!",
            type: NotificationType.Success
          });
      }
    }
    fn(done);
  }
}
