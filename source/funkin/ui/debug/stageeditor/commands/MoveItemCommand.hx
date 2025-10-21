package funkin.ui.debug.stageeditor.commands;

import funkin.ui.debug.stageeditor.components.StageEditorObject;
import funkin.play.character.BaseCharacter;
import funkin.data.stage.StageData.StageDataCharacter;
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

    if (Std.isOfType(sprite, BaseCharacter))
    {
      var character:BaseCharacter = cast sprite;
      var data:StageDataCharacter = Reflect.field(state.currentCharacters, Std.string(character.characterType).toLowerCase());
      data.position = [
        character.feetPosition.x - character.globalOffsets[0],
        character.feetPosition.y - character.globalOffsets[1]
      ];
      state.refreshToolbox(StageEditorState.STAGE_EDITOR_TOOLBOX_CHARACTER_LAYOUT);
    }

    state.playSound(Paths.sound('chartingSounds/noteLay'));

    state.saveDataDirty = true;

    state.sortObjects();
  }

  public function undo(state:StageEditorState):Void
  {
    if (sprite == null) return;

    sprite.x = initialPosition[0];
    sprite.y = initialPosition[1];

    if (Std.isOfType(sprite, BaseCharacter))
    {
      var character:BaseCharacter = cast sprite;
      var data:StageDataCharacter = Reflect.field(state.currentCharacters, Std.string(character.characterType).toLowerCase());
      data.position = [
        character.feetPosition.x - character.globalOffsets[0],
        character.feetPosition.y - character.globalOffsets[1]
      ];
      state.refreshToolbox(StageEditorState.STAGE_EDITOR_TOOLBOX_CHARACTER_LAYOUT);
    }

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
