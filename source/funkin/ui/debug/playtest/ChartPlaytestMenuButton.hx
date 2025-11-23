package funkin.ui.debug.playtest;

#if sys
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import funkin.util.MathUtil;
#if FEATURE_TOUCH_CONTROLS
import funkin.util.TouchUtil;
#end

class ChartPlaytestMenuButtonBase extends FlxText
{
  var currentScale:Float = 1;
  var targetScale:Float = 1;

  public function new(x:Float, y:Float, text:String)
  {
    super(x, y, 0, text, 30);

    setFormat(Paths.font('vcr.ttf'), 50, FlxColor.WHITE, FlxTextAlign.CENTER);
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    currentScale = MathUtil.smoothLerpPrecision(currentScale, targetScale, elapsed, 0.2);
    scale.x = currentScale;
    scale.y = currentScale;

    if (#if NO_FEATURE_TOUCH_CONTROLS FlxG.mouse.overlaps(this) #else TouchUtil.overlapsComplex(this) #end)
    {
      targetScale = 0.9;

      if (#if NO_FEATURE_TOUCH_CONTROLS FlxG.mouse.justPressed #else TouchUtil.justPressed #end)
      {
        onButtonPressed();
      }
    }
    else
    {
      targetScale = 1;
    }
  }

  function onButtonPressed():Void {}
}

class ChartPlaytestMenuButton extends ChartPlaytestMenuButtonBase
{
  var onPressed:Void->Void;

  public function new(x:Float, y:Float, text:String, onPressed:Void->Void)
  {
    super(x, y, text);

    this.onPressed = onPressed;
  }

  override function onButtonPressed():Void
  {
    if (onPressed != null) onPressed();
  }
}

class ChartPlaytestMenuButtonListToggle extends ChartPlaytestMenuButtonBase
{
  var title:String;
  var list:Array<String>;
  var onPressed:String->Void;

  var curSelected:Int = 0;

  public function new(x:Float, y:Float, title:String, list:Array<String>, onPressed:String->Void)
  {
    super(x, y, getCurrentText(title, list[curSelected]));

    this.title = title;
    this.list = list;
    this.onPressed = onPressed;
  }

  override function onButtonPressed():Void
  {
    curSelected++;

    if (curSelected > list.length - 1)
    {
      curSelected = 0;
    }
    else if (curSelected < 0)
    {
      curSelected = list.length - 1;
    }

    text = getCurrentText(title, list[curSelected]);

    if (onPressed != null) onPressed(list[curSelected]);
  }

  function getCurrentText(title:String, selectedItem:String):String
  {
    return '$title: $selectedItem';
  }
}
#end
