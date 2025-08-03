package funkin.ui.mainmenu;

import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.math.FlxRect;

class UpgradeSparkle extends FlxSprite
{
  var sparkleTimer:FlxTimer;

  public var bounds:FlxRect;

  public function new(_x:Float, _y:Float, _width:Float, _height:Float, big:Bool)
  {
    super(0, 0);
    bounds = FlxRect.get(_x, _y, _width, _height);
    if (big)
    {
      loadGraphic(Paths.image('mainmenu/upgradeshine_big'));
    }
    else
    {
      loadGraphic(Paths.image('mainmenu/upgradeshine_small'));
    }
    sparkleTimer = new FlxTimer().start(FlxG.random.float(2, 7), sparkleEffect);
    visible = false;
  }

  public function cancelSparkle():Void
  {
    if (sparkleTimer != null) sparkleTimer.cancel();
    FlxTween.cancelTweensOf(this);
    alpha = 0;
  }

  public function restartSparkle():Void
  {
    if (sparkleTimer != null) sparkleTimer.cancel();
    FlxTween.cancelTweensOf(this);
    alpha = 1;
    sparkleTimer = new FlxTimer().start(FlxG.random.float(2, 7), sparkleEffect);
  }

  function sparkleEffect(timer:FlxTimer):Void
  {
    visible = true;
    alpha = 1;

    flipX = !flipX;

    var targetScale:Float = FlxG.random.float(0.6, 1);
    scale.set(targetScale, targetScale);
    updateHitbox();

    setPosition(FlxG.random.float(bounds.x, bounds.x + bounds.width), FlxG.random.float(bounds.y, bounds.y + bounds.height));
    x -= width / 2;
    y -= height / 2;

    angle += 70;

    var targetVelocity:Float = FlxG.random.float(120, 300);
    if (FlxG.random.bool(50)) targetVelocity = targetVelocity * -1;
    angularVelocity = targetVelocity;
    angularDrag = 200;

    var targetTime:Float = FlxG.random.float(0.3, 0.8);
    FlxTween.tween(this.scale, {x: targetScale * 0.001, y: targetScale * 0.001}, targetTime, {ease: FlxEase.backIn});
    FlxTween.tween(this, {alpha: 0}, targetTime, {ease: FlxEase.quintIn});

    sparkleTimer = new FlxTimer().start(FlxG.random.float(2, 7), sparkleEffect);
  }
}
