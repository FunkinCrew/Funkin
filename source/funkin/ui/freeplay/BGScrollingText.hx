package funkin.ui.freeplay;

import flixel.FlxObject;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxSort;
import flixel.FlxSprite;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxColor;

// its kinda like marqeee html lol!
@:nullSafety
class BGScrollingText extends FlxSpriteGroup
{
  var grpTexts:FlxTypedSpriteGroup<FlxSprite>;
  var sourceText:FlxText;

  public var widthShit:Float = FlxG.width;
  public var placementOffset:Float = 20;
  public var speed:Float = 1;
  public var size(default, set):Int = 48;

  public var funnyColor(default, set):FlxColor = 0xFFFFFFFF;

  public function new(x:Float, y:Float, text:String, widthShit:Float = 100, ?bold:Bool = false, ?size:Int = 48)
  {
    super(x, y);

    grpTexts = new FlxTypedSpriteGroup<FlxSprite>();

    this.widthShit = widthShit;

    // Only keep one FlxText graphic at a time for batching
    sourceText = new FlxText(0, 0, 0, text, size ?? this.size);
    sourceText.font = "5by7";
    sourceText.bold = bold ?? false;

    @:privateAccess
    sourceText.regenGraphic();

    var needed:Int = Math.ceil(widthShit / sourceText.frameWidth) + 1;

    for (i in 0...needed)
    {
      var coolText = new FlxSprite((i * sourceText.frameWidth) + (i * 20), 0);
      grpTexts.add(coolText);
    }

    if (size != null) this.size = size;

    add(grpTexts);
  }

  function reloadGraphics()
  {
    if (grpTexts != null)
    {
      @:privateAccess
      sourceText.regenGraphic();
      grpTexts.forEach(function(txt:FlxSprite) {
        txt.loadGraphic(sourceText.graphic);
        txt.updateHitbox();
      });
    }
  }

  function set_size(value:Int):Int
  {
    sourceText.size = value;
    reloadGraphics();
    this.size = value;
    return value;
  }

  function set_funnyColor(value:FlxColor):FlxColor
  {
    sourceText.color = value;
    reloadGraphics();
    this.funnyColor = value;
    return value;
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

  override function destroy():Void
  {
    super.destroy();
    sourceText = FlxDestroyUtil.destroy(sourceText);
  }
}
