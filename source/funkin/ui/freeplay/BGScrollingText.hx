package funkin.ui.freeplay;

import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSort;

// its kinda like marqeee html lol!
@:nullSafety
class BGScrollingText extends FlxText
{
  var _textPositions:Array<FlxPoint> = [];
  var _positionCache:FlxPoint = FlxPoint.get();

  public var widthShit:Float = FlxG.width;
  public var placementOffset:Float = 20;
  public var speed:Float = 1;

  @:deprecated("Use color instead")
  public var funnyColor(get, set):FlxColor;

  function get_funnyColor():FlxColor return color;

  function set_funnyColor(c:FlxColor):FlxColor
  {
    return color = c;
  }

  public function new(x:Float, y:Float, text:String, widthShit:Float = 100, ?bold:Bool = false, ?size:Int = 48)
  {
    super(x, y, 0, text, size);
    _positionCache = FlxPoint.get(x, y);
    font = "5by7";
    this.bold = bold ?? false;

    this.widthShit = widthShit;

    @:privateAccess
    regenGraphic();

    var needed:Int = Math.ceil(widthShit / frameWidth) + 1;

    for (i in 0...needed)
    {
      _textPositions.push(FlxPoint.get((i * frameWidth) + (i * 20), 0));
    }
  }

  public function updateText(newText:String)
  {
    this.text = newText;

    @:privateAccess
    regenGraphic();

    var needed:Int = Math.ceil(widthShit / frameWidth) + 1;

    _textPositions.clear();

    for (i in 0...needed)
    {
      _textPositions.push(FlxPoint.get((i * frameWidth) + (i * 20), 0));
    }
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    for (txtPosition in _textPositions)
    {
      if (txtPosition == null) continue;
      txtPosition.x -= 1 * (speed * (elapsed / (1 / 60)));

      if (speed > 0) // Going left
      {
        if (txtPosition.x < -frameWidth)
        {
          txtPosition.x = _textPositions[_textPositions.length - 1].x + frameWidth + placementOffset;
          sortTextShit();
        }
      }
      else // Going right
      {
        if (txtPosition.x > frameWidth * 2)
        {
          txtPosition.x = _textPositions[0].x - frameWidth - placementOffset;
          sortTextShit();
        }
      }
    }
  }

  override public function draw():Void
  {
    _positionCache.set(x, y);
    for (position in _textPositions)
    {
      setPosition(_positionCache.x + position.x, _positionCache.y + position.y);
      super.draw();
    }
    setPosition(_positionCache.x, _positionCache.y);
  }

  function sortTextShit():Void
  {
    _textPositions.sort(function(Obj1:FlxPoint, Obj2:FlxPoint)
    {
      return FlxSort.byValues(FlxSort.ASCENDING, Obj1.x, Obj2.x);
    });
  }
}
