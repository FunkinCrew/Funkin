package funkin.ui.freeplay.backcards;

import funkin.ui.freeplay.FreeplayState;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSpriteUtil;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.graphics.FunkinSprite;
import funkin.ui.freeplay.charselect.PlayableCharacter;
import openfl.display.BlendMode;
import flixel.group.FlxSpriteGroup;
import funkin.modding.IScriptedClass.IBPMSyncedScriptedClass;
import funkin.modding.IScriptedClass.IStateChangingScriptedClass;
import funkin.modding.events.ScriptEvent;
import funkin.ui.FullScreenScaleMode;
import funkin.util.BitmapUtil;
import openfl.utils.Assets;

/**
 * A class for the backing cards so they dont have to be part of freeplayState......
 */
class BackingCard extends FlxSpriteGroup implements IBPMSyncedScriptedClass implements IStateChangingScriptedClass
{
  public var backingTextYeah:FlxAtlasSprite;
  public var orangeBackShit:FunkinSprite;
  public var alsoOrangeLOL:FunkinSprite;
  public var pinkBack:FunkinSprite;
  public var confirmGlow:FlxSprite;
  public var confirmGlow2:FlxSprite;
  public var confirmTextGlow:FlxSprite;
  public var cardGlow:FlxSprite;

  var _exitMovers:Null<FreeplayState.ExitMoverData>;
  var _exitMoversCharSel:Null<FreeplayState.ExitMoverData>;

  public var instance:FreeplayState;
  public var currentCharacter:String;

  public function new(currentCharacter:String)
  {
    super();

    this.currentCharacter = currentCharacter;

    var bitmap = BitmapUtil.scalePartByWidth(Assets.getBitmapData(Paths.image('freeplay/cardGlow')), FreeplayState.CUTOUT_WIDTH);
    cardGlow = new FlxSprite(-30, -30).loadGraphic(bitmap);

    confirmGlow = new FlxSprite((FreeplayState.CUTOUT_WIDTH * FreeplayState.DJ_POS_MULTI) + -30, 240).loadGraphic(Paths.image('freeplay/confirmGlow'));
    confirmTextGlow = new FlxSprite((FreeplayState.CUTOUT_WIDTH * FreeplayState.DJ_POS_MULTI) + -8, 115).loadGraphic(Paths.image('freeplay/glowingText'));

    var bitmap = BitmapUtil.scalePartByWidth(Assets.getBitmapData(Paths.image('freeplay/pinkBack')), FreeplayState.CUTOUT_WIDTH);
    pinkBack = new FunkinSprite();
    pinkBack.loadGraphic(bitmap);

    orangeBackShit = new FunkinSprite(84, 440).makeSolidColor(Std.int(pinkBack.width), 75, 0xFFFEDA00);
    alsoOrangeLOL = new FunkinSprite(0, orangeBackShit.y).makeSolidColor(100, Std.int(orangeBackShit.height), 0xFFFFD400);
    confirmGlow2 = new FlxSprite(confirmGlow.x, confirmGlow.y).loadGraphic(Paths.image('freeplay/confirmGlow2'));
    backingTextYeah = new FlxAtlasSprite((FreeplayState.CUTOUT_WIDTH * FreeplayState.DJ_POS_MULTI) + 640, 370,
      Paths.animateAtlas("freeplay/backing-text-yeah"), {
        FrameRate: 24.0,
        Reversed: false,
        // ?OnComplete:Void -> Void,
        ShowPivot: false,
        Antialiasing: true,
        ScrollFactor: new FlxPoint(1, 1),
      });

    pinkBack.color = 0xFFFFD4E9; // sets it to pink!
    pinkBack.x -= pinkBack.width;
  }

  /**
   * Apply exit movers for the pieces of the backing card.
   * @param exitMovers The exit movers to apply.
   */
  public function applyExitMovers(?exitMovers:FreeplayState.ExitMoverData, ?exitMoversCharSel:FreeplayState.ExitMoverData):Void
  {
    if (exitMovers == null)
    {
      exitMovers = _exitMovers;
    }
    else
    {
      _exitMovers = exitMovers;
    }

    if (exitMovers == null) return;

    if (exitMoversCharSel == null)
    {
      exitMoversCharSel = _exitMoversCharSel;
    }
    else
    {
      _exitMoversCharSel = exitMoversCharSel;
    }

    if (exitMoversCharSel == null) return;

    exitMovers.set([pinkBack, orangeBackShit, alsoOrangeLOL],
      {
        x: -pinkBack.width,
        y: pinkBack.y,
        speed: 0.4,
        wait: 0
      });

    exitMoversCharSel.set([pinkBack],
      {
        y: -100,
        speed: 0.8,
        wait: 0.1
      });

    exitMoversCharSel.set([orangeBackShit, alsoOrangeLOL],
      {
        y: -40,
        speed: 0.8,
        wait: 0.1
      });
  }

  /**
   * Helper function to snap the back of the card to its final position.
   * Used when returning from character select, as we dont want to play the full animation of everything sliding in.
   */
  public function skipIntroTween():Void
  {
    FlxTween.cancelTweensOf(pinkBack);
    pinkBack.x = 0;
  }

  /**
   * Called after the dj finishes their start animation.
   */
  public function introDone():Void
  {
    pinkBack.color = 0xFFFFD863;
    orangeBackShit.visible = true;
    alsoOrangeLOL.visible = true;
    cardGlow.visible = true;
    FlxTween.tween(cardGlow, {alpha: 0, "scale.x": 1.2, "scale.y": 1.2}, 0.45, {ease: FlxEase.sineOut});
  }

  /**
   * Called when selecting a song.
   */
  public function confirm():Void
  {
    FlxTween.color(pinkBack, 0.33, 0xFFFFD0D5, 0xFF171831, {ease: FlxEase.quadOut});
    orangeBackShit.visible = false;
    alsoOrangeLOL.visible = false;

    confirmGlow.visible = true;
    confirmGlow2.visible = true;

    backingTextYeah.anim.play("");
    confirmGlow2.alpha = 0;
    confirmGlow.alpha = 0;

    FlxTween.color(instance.backingImage, 0.5, 0xFFA8A8A8, 0xFF646464,
      {
        onUpdate: function(_) {
          instance.angleMaskShader.extraColor = instance.backingImage.color;
        }
      });
    FlxTween.tween(confirmGlow2, {alpha: 0.5}, 0.33,
      {
        ease: FlxEase.quadOut,
        onComplete: function(_) {
          confirmGlow2.alpha = 0.6;
          confirmGlow.alpha = 1;
          confirmTextGlow.visible = true;
          confirmTextGlow.alpha = 1;
          FlxTween.tween(confirmTextGlow, {alpha: 0.4}, 0.5);
          FlxTween.tween(confirmGlow, {alpha: 0}, 0.5);
          FlxTween.color(instance.backingImage, 2, 0xFFCDCDCD, 0xFF555555,
            {
              ease: FlxEase.expoOut,
              onUpdate: function(_) {
                instance.angleMaskShader.extraColor = instance.backingImage.color;
              }
            });
        }
      });
  }

  /**
   * Called when entering character select, does nothing by default.
   */
  public function enterCharSel():Void {}

  /**
   * Called on each beat in freeplay state.
   */
  public function beatHit():Void {}

  /**
   * Called when exiting the freeplay menu.
   */
  public function disappear():Void
  {
    FlxTween.color(pinkBack, 0.25, 0xFFFFD863, 0xFFFFD0D5, {ease: FlxEase.quadOut});

    cardGlow.visible = true;
    cardGlow.alpha = 1;
    cardGlow.scale.set(1, 1);
    FlxTween.tween(cardGlow, {alpha: 0, "scale.x": 1.2, "scale.y": 1.2}, 0.25, {ease: FlxEase.sineOut});

    orangeBackShit.visible = false;
    alsoOrangeLOL.visible = false;
  }

  public function onScriptEvent(event:ScriptEvent):Void {}

  /**
   * Called in create. Adds sprites and tweens.
   */
  public function onCreate(event:ScriptEvent):Void
  {
    FlxTween.tween(pinkBack, {x: 0}, 0.6, {ease: FlxEase.quartOut});
    add(pinkBack);

    add(orangeBackShit);

    add(alsoOrangeLOL);

    FlxSpriteUtil.alphaMaskFlxSprite(orangeBackShit, pinkBack, orangeBackShit);
    orangeBackShit.visible = false;
    alsoOrangeLOL.visible = false;

    confirmTextGlow.blend = BlendMode.ADD;
    confirmTextGlow.visible = false;

    confirmGlow.blend = BlendMode.ADD;

    confirmGlow.visible = false;
    confirmGlow2.visible = false;

    add(confirmGlow2);
    add(confirmGlow);

    add(confirmTextGlow);

    add(backingTextYeah);

    cardGlow.blend = BlendMode.ADD;
    cardGlow.visible = false;

    add(cardGlow);
  }

  public function onDestroy(event:ScriptEvent):Void {}

  public function onUpdate(event:UpdateScriptEvent):Void {}

  public function onStepHit(event:SongTimeScriptEvent):Void {}

  public function onBeatHit(event:SongTimeScriptEvent):Void {}

  public function onStateChangeBegin(event:StateChangeScriptEvent):Void {}

  public function onStateChangeEnd(event:StateChangeScriptEvent):Void {}

  public function onSubStateOpenBegin(event:SubStateScriptEvent):Void {}

  public function onSubStateOpenEnd(event:SubStateScriptEvent):Void {}

  public function onSubStateCloseBegin(event:SubStateScriptEvent):Void {}

  public function onSubStateCloseEnd(event:SubStateScriptEvent):Void {}

  public function onFocusLost(event:FocusScriptEvent):Void {}

  public function onFocusGained(event:FocusScriptEvent):Void {}

  public function centerObjectOnCard(object:flixel.FlxObject)
  {
    if (pinkBack != null) object.x = (x + ((pinkBack.width - object.width) / 2)) * 0.74;
  }
}
