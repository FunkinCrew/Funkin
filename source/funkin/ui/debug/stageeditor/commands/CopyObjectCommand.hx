package funkin.ui.debug.stageeditor.commands;

import funkin.ui.debug.stageeditor.components.StageEditorObject;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

@:nullSafety
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class CopyObjectCommand implements StageEditorCommand
{
  var object:StageEditorObject;

  public function new(object:StageEditorObject)
  {
    this.object = object;
  }

  public function execute(state:StageEditorState):Void
  {
    StageEditorAssetHandler.writeItemsToClipboard(
      {
        object: object.toData()
      });

    // Display the "Copied X Object" text.
    if (state.copyNotificationText != null)
    {
      FlxTween.globalManager.cancelTweensOf(state.copyNotificationText);

      state.copyNotificationText.visible = true;
      state.copyNotificationText.text = 'Copied ${object.name} to clipboard';
      state.copyNotificationText.x = FlxG.mouse.x - (state.copyNotificationText.width / 2);
      state.copyNotificationText.y = FlxG.mouse.y - 16;
      state.copyNotificationText.scale.set(1 / FlxG.camera.zoom, 1 / FlxG.camera.zoom);
      FlxTween.tween(state.copyNotificationText, {y: state.copyNotificationText.y - (32 / FlxG.camera.zoom)}, 0.5,
        {
          type: FlxTweenType.ONESHOT,
          ease: FlxEase.quadOut,
          onComplete: function(_) {
            state.copyNotificationText.visible = false;
          }
        });
    }
  }

  public function undo(state:StageEditorState):Void
  {
    // This command is not undoable. Do nothing.
  }

  public function shouldAddToHistory(state:StageEditorState):Bool
  {
    // This command is not undoable. Don't add it to the history.
    return false;
  }

  public function toString():String
  {
    var objectID = (object != null) ? object.name : 'Unknown';
    return 'Copy $objectID to Clipboard';
  }
}
