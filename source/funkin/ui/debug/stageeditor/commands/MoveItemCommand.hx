package funkin.ui.debug.stageeditor.commands;

import funkin.ui.debug.stageeditor.components.StageEditorObject;
import funkin.play.character.BaseCharacter;
import flixel.FlxSprite;

using StringTools;

@:nullSafety
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class MoveItemCommand implements StageEditorCommand
{
  var sprite:Null<FlxSprite>;
  var initialPosition:Array<Float>;
  var endPosition:Array<Float>;

  public function new(sprite:FlxSprite, initialPosition:Array<Float>, endPosition:Array<Float>)
  {
    this.sprite = sprite;
    this.initialPosition = initialPosition;
    this.endPosition = endPosition;
  }

  public function execute(state:StageEditorState):Void
  {
    if (sprite == null) return;

    sprite.x = endPosition[0];
    sprite.y = endPosition[1];

    state.playSound(Paths.sound('chartingSounds/noteLay'));

    state.saveDataDirty = true;

    state.sortObjects();
  }

  public function undo(state:StageEditorState):Void
  {
    if (sprite == null) return;

    sprite.x = initialPosition[0];
    sprite.y = initialPosition[1];

    state.updateVisuals(false); // We do not want to redraw the camera bounds each time, as we are just moving the character.

    state.playSound(Paths.sound('chartingSounds/undo'));

    state.saveDataDirty = true;

    state.sortObjects();
  }

  public function shouldAddToHistory(state:StageEditorState):Bool
  {
    return true;
  }

  public function toString():String
  {
    var objectID:String = 'Unknown';
    if (Std.isOfType(sprite, StageEditorObject)) objectID = (cast sprite : StageEditorObject).name;
    else if (Std.isOfType(sprite, BaseCharacter)) objectID = Std.string((cast sprite : BaseCharacter).characterType).toTitleCase();
    return 'Move $objectID';
  }
}
