package funkin.ui.freeplay;

import flixel.FlxObject;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxSort;

// its kinda like marqeee html lol!
@:nullSafety
class BGScrollingText extends FlxSpriteGroup
{
  var grpTexts:FlxTypedSpriteGroup<FlxText>;

  public var widthShit:Float = FlxG.width;
  public var placementOffset:Float = 20;
  public var speed:Float = 1;
  public var size(default, set):Int = 48;

  public var funnyColor(default, set):Int = 0xFFFFFFFF;

  public function new(x:Float, y:Float, text:String, widthShit:Float = 100, ?bold:Bool = false, ?size:Int = 48)
  {
    super(x, y);

    grpTexts = new FlxTypedSpriteGroup<FlxText>();
    add(grpTexts);

    this.widthShit = widthShit;
    if (size != null) this.size = size;

    var testText:FlxText = new FlxText(0, 0, 0, text, this.size);
    testText.font = "5by7";
    testText.bold = bold ?? false;
    testText.updateHitbox();
    grpTexts.add(testText);

    var needed:Int = Math.ceil(widthShit / testText.frameWidth) + 1;

    for (i in 0...needed)
    {
      var lmfao:Int = i + 1;

      var coolText:FlxText = new FlxText((lmfao * testText.frameWidth) + (lmfao * 20), 0, 0, text, this.size);

      coolText.font = "5by7";
      coolText.bold = bold ?? false;
      coolText.updateHitbox();
      grpTexts.add(coolText);
    }
  }

  function set_size(value:Int):Int
  {
    if (grpTexts != null)
    {
      grpTexts.forEach(function(txt:FlxText) {
        txt.size = value;
      });
    }
    this.size = value;
    return value;
  }

  function set_funnyColor(col:Int):Int
  {
    grpTexts.forEach(function(txt) {
      txt.color = col;
    });

    return col;
  }

  override public function update(elapsed:Float)
  {
    for (txt in grpTexts.group)
    {
      if (txt == null) continue;
      txt.x -= 1 * (speed * (elapsed / (1 / 60)));

      if (speed > 0)
      {
        if (txt.x < -txt.frameWidth)
        {
          txt.x = grpTexts.group.members[grpTexts.length - 1].x + grpTexts.group.members[grpTexts.length - 1].frameWidth + placementOffset;

          sortTextShit();
        }
      }
      else
      {
        if (txt.x > txt.frameWidth * 2)
        {
          txt.x = grpTexts.group.members[0].x - grpTexts.group.members[0].frameWidth - placementOffset;

          sortTextShit();
        }
      }
    }

    super.update(elapsed);
  }

  function sortTextShit():Void
  {
    grpTexts.sort(function(Order:Int, Obj1:FlxObject, Obj2:FlxObject) {
      return FlxSort.byValues(Order, Obj1.x, Obj2.x);
    });
  }
}
