package funkin.ui.stageBuildShit;

import flixel.FlxSprite;

/**
 * Very similar to eric's implementation
 * see funkin.ui.debug.charting.ChartEditorCommand and ChartEditorState
 * for more documentation since I am lazy to document!
 */
interface StageEditorCommand
{
  public function execute(state:StageOffsetSubstate):Void;
  public function undo(state:StageOffsetSubstate):Void;
  public function toString():String;
}

class MovePropCommand implements StageEditorCommand
{
  var xDiff:Float;
  var yDiff:Float;

  public function new(xDiff:Float = 0, yDiff:Float = 0)
  {
    this.xDiff = xDiff;
    this.yDiff = yDiff;
  }

  public function execute(state:StageOffsetSubstate):Void
  {
    state.char.x += xDiff;
    state.char.y += yDiff;
  }

  public function undo(state:StageOffsetSubstate):Void
  {
    state.char.x -= xDiff;
    state.char.y -= yDiff;
  }

  public function toString():String
  {
    return "Moved char";
  }
}

class SelectPropCommand implements StageEditorCommand
{
  var prop:FlxSprite;
  var prevProp:FlxSprite;

  public function new(prop:FlxSprite)
  {
    this.prop = prop;
  }

  public function execute(state:StageOffsetSubstate):Void
  {
    this.prevProp = state.char;
    state.char = prop;
  }

  public function undo(state:StageOffsetSubstate):Void
  {
    state.char = this.prevProp;
  }

  public function toString():String
  {
    return "Selected" + prop;
  }
}
