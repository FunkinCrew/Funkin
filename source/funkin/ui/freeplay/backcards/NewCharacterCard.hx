package funkin.ui.freeplay.backcards;

import funkin.ui.freeplay.FreeplayState;
import flixel.math.FlxMath;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.modding.events.ScriptEvent;
import openfl.display.BlendMode;
import funkin.util.BitmapUtil;
import openfl.utils.Assets;

class NewCharacterCard extends BackingCard
{
  var confirmAtlas:FlxAtlasSprite;

  var darkBg:FlxSprite;
  var lightLayer:FlxSprite;
  var multiply1:FlxSprite;
  var multiply2:FlxSprite;
  var lightLayer2:FlxSprite;
  var lightLayer3:FlxSprite;
  var yellow:FlxSprite;
  var multiplyBar:FlxSprite;

  var bruh:FlxSprite;

  public var friendFoe:BGScrollingText;
  public var newUnlock1:BGScrollingText;
  public var waiting:BGScrollingText;
  public var newUnlock2:BGScrollingText;
  public var friendFoe2:BGScrollingText;
  public var newUnlock3:BGScrollingText;

  public override function applyExitMovers(?exitMovers:FreeplayState.ExitMoverData, ?exitMoversCharSel:FreeplayState.ExitMoverData):Void
  {
    super.applyExitMovers(exitMovers, exitMoversCharSel);
    if (exitMovers == null || exitMoversCharSel == null) return;
    exitMovers.set([friendFoe],
      {
        x: FlxG.width * 2,
        speed: 0.4,
      });
    exitMovers.set([newUnlock1],
      {
        x: -newUnlock1.width * 2,
        y: newUnlock1.y,
        speed: 0.4,
        wait: 0
      });
    exitMovers.set([waiting],
      {
        x: FlxG.width * 2,
        speed: 0.4,
      });
    exitMovers.set([newUnlock2],
      {
        x: -newUnlock2.width * 2,
        speed: 0.5,
      });
    exitMovers.set([friendFoe2],
      {
        x: FlxG.width * 2,
        speed: 0.4
      });
    exitMovers.set([newUnlock3],
      {
        x: -newUnlock3.width * 2,
        speed: 0.3
      });

    exitMoversCharSel.set([friendFoe, newUnlock1, waiting, newUnlock2, friendFoe2, newUnlock3, multiplyBar], {
      y: -60,
      speed: 0.8,
      wait: 0.1
    });
  }

  public override function introDone():Void
  {
    // pinkBack.color = 0xFFFFD863;

    darkBg.visible = true;
    friendFoe.visible = true;
    newUnlock1.visible = true;
    waiting.visible = true;
    newUnlock2.visible = true;
    friendFoe2.visible = true;
    newUnlock3.visible = true;
    multiplyBar.visible = true;
    lightLayer.visible = true;
    multiply1.visible = true;
    multiply2.visible = true;
    lightLayer2.visible = true;
    yellow.visible = true;
    lightLayer3.visible = true;

    cardGlow.visible = true;
    FlxTween.tween(cardGlow, {alpha: 0, "scale.x": 1.2, "scale.y": 1.2}, 0.45, {ease: FlxEase.sineOut});
  }

  public override function enterCharSel():Void
  {
    FlxTween.tween(friendFoe, {speed: 0}, 0.8, {ease: FlxEase.sineIn});
    FlxTween.tween(newUnlock1, {speed: 0}, 0.8, {ease: FlxEase.sineIn});
    FlxTween.tween(waiting, {speed: 0}, 0.8, {ease: FlxEase.sineIn});
    FlxTween.tween(newUnlock2, {speed: 0}, 0.8, {ease: FlxEase.sineIn});
    FlxTween.tween(friendFoe2, {speed: 0}, 0.8, {ease: FlxEase.sineIn});
    FlxTween.tween(newUnlock3, {speed: 0}, 0.8, {ease: FlxEase.sineIn});
  }

  public override function onCreate(event:ScriptEvent):Void
  {
    FlxTween.tween(pinkBack, {x: 0}, 0.6, {ease: FlxEase.quartOut});
    add(pinkBack);

    confirmTextGlow.blend = BlendMode.ADD;
    confirmTextGlow.visible = false;

    confirmGlow.blend = BlendMode.ADD;

    confirmGlow.visible = false;
    confirmGlow2.visible = false;

    friendFoe = new BGScrollingText(0, 163, "COULD IT BE A NEW FRIEND? OR FOE??", FlxG.width, true, 43);
    newUnlock1 = new BGScrollingText(-440, 215, 'NEW UNLOCK!', FlxG.width / 2, true, 80);
    waiting = new BGScrollingText(0, 286, "SOMEONE'S WAITING!", FlxG.width / 2, true, 43);
    newUnlock2 = new BGScrollingText(-220, 331, 'NEW UNLOCK!', FlxG.width / 2, true, 80);
    friendFoe2 = new BGScrollingText(0, 402, 'COULD IT BE A NEW FRIEND? OR FOE??', FlxG.width, true, 43);
    newUnlock3 = new BGScrollingText(0, 458, 'NEW UNLOCK!', FlxG.width / 2, true, 80);

    var bitmap = BitmapUtil.scalePartByWidth(Assets.getBitmapData(Paths.image('freeplay/backingCards/newCharacter/darkback')), FreeplayState.CUTOUT_WIDTH);
    darkBg = new FlxSprite(0, 0).loadGraphic(bitmap);
    add(darkBg);

    friendFoe.funnyColor = 0xFF139376;
    friendFoe.speed = -4;
    add(friendFoe);

    newUnlock1.funnyColor = 0xFF99BDF2;
    newUnlock1.speed = 2;
    add(newUnlock1);

    waiting.funnyColor = 0xFF40EA84;
    waiting.speed = -2;
    add(waiting);

    newUnlock2.funnyColor = 0xFF99BDF2;
    newUnlock2.speed = 2;
    add(newUnlock2);

    friendFoe2.funnyColor = 0xFF139376;
    friendFoe2.speed = -4;
    add(friendFoe2);

    newUnlock3.funnyColor = 0xFF99BDF2;
    newUnlock3.speed = 2;
    add(newUnlock3);

    var bitmap = BitmapUtil.scalePartByWidth(Assets.getBitmapData(Paths.image('freeplay/backingCards/newCharacter/multiplyBar')), FreeplayState.CUTOUT_WIDTH);
    multiplyBar = new FlxSprite(-10, 440).loadGraphic(bitmap);
    multiplyBar.blend = BlendMode.MULTIPLY;
    add(multiplyBar);

    lightLayer = new FlxSprite((FreeplayState.CUTOUT_WIDTH * FreeplayState.DJ_POS_MULTI) + -360,
      230).loadGraphic(Paths.image('freeplay/backingCards/newCharacter/orange gradient'));
    lightLayer.blend = BlendMode.ADD;
    add(lightLayer);

    var bitmap = BitmapUtil.scalePartByWidth(Assets.getBitmapData(Paths.image('freeplay/backingCards/newCharacter/red')), FreeplayState.CUTOUT_WIDTH);
    multiply1 = new FlxSprite(-15, -125).loadGraphic(bitmap);
    multiply1.blend = BlendMode.MULTIPLY;
    add(multiply1);

    multiply2 = new FlxSprite(-15, -125).loadGraphic(bitmap);
    multiply2.blend = BlendMode.MULTIPLY;
    add(multiply2);

    lightLayer2 = new FlxSprite((FreeplayState.CUTOUT_WIDTH * FreeplayState.DJ_POS_MULTI) + -360,
      230).loadGraphic(Paths.image('freeplay/backingCards/newCharacter/orange gradient'));
    lightLayer2.blend = BlendMode.ADD;
    add(lightLayer2);

    var bitmap = BitmapUtil.scalePartByWidth(Assets.getBitmapData(Paths.image('freeplay/backingCards/newCharacter/yellow bg piece')),
      FreeplayState.CUTOUT_WIDTH);
    yellow = new FlxSprite(0, 0).loadGraphic(bitmap);
    yellow.blend = BlendMode.MULTIPLY;
    add(yellow);

    lightLayer3 = new FlxSprite((FreeplayState.CUTOUT_WIDTH * FreeplayState.DJ_POS_MULTI) + -360,
      290).loadGraphic(Paths.image('freeplay/backingCards/newCharacter/red gradient'));
    lightLayer3.blend = BlendMode.ADD;
    add(lightLayer3);

    cardGlow.blend = BlendMode.ADD;
    cardGlow.visible = false;

    add(cardGlow);

    darkBg.visible = false;
    friendFoe.visible = false;
    newUnlock1.visible = false;
    waiting.visible = false;
    newUnlock2.visible = false;
    friendFoe2.visible = false;
    newUnlock3.visible = false;
    multiplyBar.visible = false;
    lightLayer.visible = false;
    multiply1.visible = false;
    multiply2.visible = false;
    lightLayer2.visible = false;
    yellow.visible = false;
    lightLayer3.visible = false;
  }

  var _timer:Float = 0;

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    _timer += elapsed * 2;
    var sinTest:Float = (Math.sin(_timer) + 1) / 2;
    lightLayer.alpha = FlxMath.lerp(0.4, 1, sinTest);
    lightLayer2.alpha = FlxMath.lerp(0.2, 0.5, sinTest);
    lightLayer3.alpha = FlxMath.lerp(0.1, 0.7, sinTest);

    multiply1.alpha = FlxMath.lerp(1, 0.21, sinTest);
    multiply2.alpha = FlxMath.lerp(1, 0.21, sinTest);

    yellow.alpha = FlxMath.lerp(0.2, 0.72, sinTest);

    if (instance != null)
    {
      instance.angleMaskShader.extraColor = FlxColor.interpolate(0xFF2E2E46, 0xFF60607B, sinTest);
    }
  }

  public override function disappear():Void
  {
    FlxTween.color(pinkBack, 0.25, 0xFF05020E, 0xFFFFD0D5, {ease: FlxEase.quadOut});

    darkBg.visible = false;
    friendFoe.visible = false;
    newUnlock1.visible = false;
    waiting.visible = false;
    newUnlock2.visible = false;
    friendFoe2.visible = false;
    newUnlock3.visible = false;
    multiplyBar.visible = false;
    lightLayer.visible = false;
    multiply1.visible = false;
    multiply2.visible = false;
    lightLayer2.visible = false;
    yellow.visible = false;
    lightLayer3.visible = false;

    cardGlow.visible = true;
    cardGlow.alpha = 1;
    cardGlow.scale.set(1, 1);
    FlxTween.tween(cardGlow, {alpha: 0, "scale.x": 1.2, "scale.y": 1.2}, 0.25, {ease: FlxEase.sineOut});
  }

  override public function confirm():Void
  {
    // confirmAtlas.visible = true;
    // confirmAtlas.anim.play("");
  }
}
