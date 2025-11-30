package funkin.ui.charSelect;

import funkin.graphics.FunkinSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxPoint;
import openfl.display.BlendMode;
import flixel.group.FlxSpriteContainer.FlxTypedSpriteContainer;
import funkin.util.MathUtil;

class CharSelectCursors extends FlxTypedSpriteContainer<FunkinSprite>
{
  public var main:FunkinSprite;

  var lightBlue:FunkinSprite;
  var darkBlue:FunkinSprite;

  var cursorConfirmed:FunkinSprite;
  var cursorDenied:FunkinSprite;

  public function new()
  {
    super();

    darkBlue = new FunkinSprite(0, 0);
    lightBlue = new FunkinSprite(0, 0);
    main = new FunkinSprite(0, 0);

    cursorConfirmed = new FunkinSprite(0, 0);
    cursorDenied = new FunkinSprite(0, 0);

    darkBlue.loadGraphic(Paths.image('charSelect/charSelector'));
    lightBlue.loadGraphic(Paths.image('charSelect/charSelector'));
    main.loadGraphic(Paths.image('charSelect/charSelector'));

    darkBlue.color = 0xFF3C74F7;
    lightBlue.color = 0xFF3EBBFF;
    main.color = 0xFFFFFF00;
    FlxTween.color(main, 0.2, 0xFFFFFF00, 0xFFFFCC00, {type: PINGPONG});

    darkBlue.blend = BlendMode.SCREEN;
    lightBlue.blend = BlendMode.SCREEN;

    add(darkBlue);
    add(lightBlue);
    add(main);

    cursorConfirmed.frames = Paths.getSparrowAtlas("charSelect/charSelectorConfirm");
    cursorConfirmed.animation.addByPrefix("idle", "cursor ACCEPTED instance 1", 24, true);
    cursorConfirmed.visible = false;
    add(cursorConfirmed);

    cursorDenied.frames = Paths.getSparrowAtlas("charSelect/charSelectorDenied");
    cursorDenied.animation.addByPrefix("idle", "cursor DENIED instance 1", 24, false);
    cursorDenied.visible = false;
    add(cursorDenied);

    scrollFactor.set();
  }

  public function confirm():Void
  {
    cursorConfirmed.visible = true;
    cursorConfirmed.animation.play("idle", true);

    main.visible = lightBlue.visible = darkBlue.visible = false;
  }

  public function resetDeny():Void
  {
    cursorDenied.visible = false;
  }

  public function deny():Void
  {
    cursorDenied.visible = true;
    cursorDenied.animation.play('idle', true);
    cursorDenied.animation.onFinish.add((_) -> {
      cursorDenied.visible = false;
    });
  }

  public function unconfirm():Void
  {
    cursorConfirmed.visible = false;
    main.visible = lightBlue.visible = darkBlue.visible = true;
  }

  public function lerpToLocation(intendedPosition:FlxPoint):Void
  {
    main.x = MathUtil.snap(MathUtil.smoothLerpPrecision(main.x, intendedPosition.x, FlxG.elapsed, 0.1), intendedPosition.x, 1);
    main.y = MathUtil.snap(MathUtil.smoothLerpPrecision(main.y, intendedPosition.y, FlxG.elapsed, 0.1), intendedPosition.y, 1);

    lightBlue.x = MathUtil.smoothLerpPrecision(lightBlue.x, main.x, FlxG.elapsed, 0.202);
    lightBlue.y = MathUtil.smoothLerpPrecision(lightBlue.y, main.y, FlxG.elapsed, 0.202);

    darkBlue.x = MathUtil.smoothLerpPrecision(darkBlue.x, intendedPosition.x, FlxG.elapsed, 0.404);
    darkBlue.y = MathUtil.smoothLerpPrecision(darkBlue.y, intendedPosition.y, FlxG.elapsed, 0.404);

    cursorConfirmed.x = main.x - 2;
    cursorConfirmed.y = main.y - 4;

    cursorDenied.x = main.x - 2;
    cursorDenied.y = main.y - 4;
  }
}
