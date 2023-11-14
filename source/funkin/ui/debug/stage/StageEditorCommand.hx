package funkin.ui.debug.stage;

import funkin.ui.debug.stage.StageOffsetSubState;
import flixel.FlxSprite;

/**
 * Very similar to eric's implementation
 * see funkin.ui.debug.charting.ChartEditorCommand and ChartEditorState
 * for more documentation since I am lazy to document!
 */
interface StageEditorCommand
{
  public function execute(state:StageOffsetSubState):Void;
  public function undo(state:StageOffsetSubState):Void;
  public function toString():String;
}

class MovePropCommand implements StageEditorCommand
{
  var xDiff:Float;
  var yDiff:Float;
  var realMove:Bool; // if needs a move!

  public function new(xDiff:Float = 0, yDiff:Float = 0, realMove:Bool = true)
  {
    this.xDiff = xDiff;
    this.yDiff = yDiff;
    this.realMove = realMove;
  }

  public function execute(state:StageOffsetSubState):Void
  {
    if (realMove)
    {
      state.char.x += xDiff;
      state.char.y += yDiff;
    }
  }

  public function undo(state:StageOffsetSubState):Void
  {
    state.char.x -= xDiff;
    state.char.y -= yDiff;
  }

  public function toString():String
  {
    return "Moved char " + xDiff + " " + yDiff + " " + realMove;
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

  public function execute(state:StageOffsetSubState):Void
  {
    this.prevProp = state.char;
    state.char = prop;
  }

  public function undo(state:StageOffsetSubState):Void
  {
    var funnyShader = state.char.shader;
    if (state.char != null) state.char.shader = null;
    state.char = this.prevProp;

    // I KNOW, TWO DAMN NULL CHECKS IN A SINGLE FUNCTION! FUK U
    if (state.char != null) state.char.shader = funnyShader;
  }

  public function toString():String
  {
    return "Selected" + prop;
  }
}
