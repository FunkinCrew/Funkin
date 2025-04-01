package funkin.ui.debug.stage;

import flixel.FlxSprite;
import flixel.input.mouse.FlxMouseEvent;
import flixel.math.FlxPoint;

class SprStage extends FlxSprite
{
  public var imgName:String = '';

  public var layer:Int = 0;
  public var mousePressing:Bool = false;

  public var mouseOffset:FlxPoint = FlxPoint.get(0, 0);
  public var oldPos:FlxPoint = FlxPoint.get(0, 0);

  public function new(?x:Float = 0, ?y:Float = 0, dragShitFunc:SprStage->Void)
  {
    super(x, y);

    FlxMouseEvent.add(this, dragShitFunc, null, function(spr:SprStage) {
      if (isSelected() || StageBuilderState.curTool == SELECT) alpha = 0.5;
    }, function(spr:SprStage) {
      alpha = 1;
    }, false, true, true);
  }

  public function isSelected():Bool
  {
    return StageBuilderState.curSelectedSpr == this;
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (mousePressing && isSelected())
    {
      this.x = FlxG.mouse.x - mouseOffset.x;
      this.y = FlxG.mouse.y - mouseOffset.y;
    }

    if (FlxG.mouse.justReleased)
    {
      mousePressing = false;
      StageBuilderState.changeTool(GRAB);
    }
  }
}
