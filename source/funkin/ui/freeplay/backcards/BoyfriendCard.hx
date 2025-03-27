package funkin.ui.freeplay.backcards;

import funkin.ui.freeplay.FreeplayState;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.graphics.FunkinSprite;
import funkin.ui.freeplay.charselect.PlayableCharacter;
import funkin.ui.MusicBeatSubState;
import openfl.display.BlendMode;
import flixel.group.FlxSpriteGroup;

class BoyfriendCard extends BackingCard
{
  public var moreWays:BGScrollingText;
  public var funnyScroll:BGScrollingText;
  public var txtNuts:BGScrollingText;
  public var funnyScroll2:BGScrollingText;
  public var moreWays2:BGScrollingText;
  public var funnyScroll3:BGScrollingText;

  var glow:FlxSprite;
  var glowDark:FlxSprite;

  public override function applyExitMovers(?exitMovers:FreeplayState.ExitMoverData, ?exitMoversCharSel:FreeplayState.ExitMoverData):Void
  {
    super.applyExitMovers(exitMovers, exitMoversCharSel);
    if (exitMovers == null || exitMoversCharSel == null) return;
    exitMovers.set([moreWays],
      {
        x: FlxG.width * 2,
        speed: 0.4,
      });
    exitMovers.set([funnyScroll],
      {
        x: -funnyScroll.width * 2,
        y: funnyScroll.y,
        speed: 0.4,
        wait: 0
      });
    exitMovers.set([txtNuts],
      {
        x: FlxG.width * 2,
        speed: 0.4,
      });
    exitMovers.set([funnyScroll2],
      {
        x: -funnyScroll2.width * 2,
        speed: 0.5,
      });
    exitMovers.set([moreWays2],
      {
        x: FlxG.width * 2,
        speed: 0.4
      });
    exitMovers.set([funnyScroll3],
      {
        x: -funnyScroll3.width * 2,
        speed: 0.3
      });

    exitMoversCharSel.set([moreWays, funnyScroll, txtNuts, funnyScroll2, moreWays2, funnyScroll3],
      {
        y: -60,
        speed: 0.8,
        wait: 0.1
      });
  }

  public override function enterCharSel():Void
  {
    FlxTween.tween(funnyScroll, {speed: 0}, 0.8, {ease: FlxEase.sineIn});
    FlxTween.tween(funnyScroll2, {speed: 0}, 0.8, {ease: FlxEase.sineIn});
    FlxTween.tween(moreWays, {speed: 0}, 0.8, {ease: FlxEase.sineIn});
    FlxTween.tween(moreWays2, {speed: 0}, 0.8, {ease: FlxEase.sineIn});
    FlxTween.tween(txtNuts, {speed: 0}, 0.8, {ease: FlxEase.sineIn});
    FlxTween.tween(funnyScroll3, {speed: 0}, 0.8, {ease: FlxEase.sineIn});
  }

  public override function new(currentCharacter:PlayableCharacter)
  {
    super(currentCharacter);

    funnyScroll = new BGScrollingText(0, 220, currentCharacter.getFreeplayDJText(1), FlxG.width / 2, false, 60);
    funnyScroll2 = new BGScrollingText(0, 335, currentCharacter.getFreeplayDJText(1), FlxG.width / 2, false, 60);
    moreWays = new BGScrollingText(0, 160, currentCharacter.getFreeplayDJText(2), FlxG.width, true, 43);
    moreWays2 = new BGScrollingText(0, 397, currentCharacter.getFreeplayDJText(2), FlxG.width, true, 43);
    txtNuts = new BGScrollingText(0, 285, currentCharacter.getFreeplayDJText(3), FlxG.width / 2, true, 43);
    funnyScroll3 = new BGScrollingText(0, orangeBackShit.y + 10, currentCharacter.getFreeplayDJText(1), FlxG.width / 2, 60);
  }

  public override function init():Void
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

    moreWays.visible = false;
    funnyScroll.visible = false;
    txtNuts.visible = false;
    funnyScroll2.visible = false;
    moreWays2.visible = false;
    funnyScroll3.visible = false;

    moreWays.funnyColor = 0xFFFFF383;
    moreWays.speed = 6.8;
    add(moreWays);

    funnyScroll.funnyColor = 0xFFFF9963;
    funnyScroll.speed = -3.8;
    add(funnyScroll);

    txtNuts.speed = 3.5;
    add(txtNuts);

    funnyScroll2.funnyColor = 0xFFFF9963;
    funnyScroll2.speed = -3.8;
    add(funnyScroll2);

    moreWays2.funnyColor = 0xFFFFF383;
    moreWays2.speed = 6.8;
    add(moreWays2);

    funnyScroll3.funnyColor = 0xFFFEA400;
    funnyScroll3.speed = -3.8;
    add(funnyScroll3);

    glowDark = new FlxSprite(-300, 330).loadGraphic(Paths.image('freeplay/beatglow'));
    glowDark.blend = BlendMode.MULTIPLY;
    add(glowDark);

    glow = new FlxSprite(-300, 330).loadGraphic(Paths.image('freeplay/beatglow'));
    glow.blend = BlendMode.ADD;
    add(glow);

    glowDark.visible = false;
    glow.visible = false;

    add(cardGlow);
  }

  var beatFreq:Int = 1;
  var beatFreqList:Array<Int> = [1, 2, 4, 8];

  public override function beatHit():Void
  {
    // increases the amount of beats that need to go by to pulse the glow because itd flash like craazy at high bpms.....
    beatFreq = beatFreqList[Math.floor(Conductor.instance.bpm / 140)];

    if (Conductor.instance.currentBeat % beatFreq != 0) return;
    FlxTween.cancelTweensOf(glow);
    FlxTween.cancelTweensOf(glowDark);

    glow.alpha = 0.8;
    FlxTween.tween(glow, {alpha: 0}, 16 / 24, {ease: FlxEase.quartOut});
    glowDark.alpha = 0;
    FlxTween.tween(glowDark, {alpha: 0.6}, 18 / 24, {ease: FlxEase.quartOut});
  }

  public override function introDone():Void
  {
    super.introDone();
    moreWays.visible = true;
    funnyScroll.visible = true;
    txtNuts.visible = true;
    funnyScroll2.visible = true;
    moreWays2.visible = true;
    funnyScroll3.visible = true;
    // grpTxtScrolls.visible = true;
    glowDark.visible = true;
    glow.visible = true;
  }

  public override function confirm():Void
  {
    super.confirm();
    // FlxTween.color(bgDad, 0.33, 0xFFFFFFFF, 0xFF555555, {ease: FlxEase.quadOut});

    moreWays.visible = false;
    funnyScroll.visible = false;
    txtNuts.visible = false;
    funnyScroll2.visible = false;
    moreWays2.visible = false;
    funnyScroll3.visible = false;
    glowDark.visible = false;
    glow.visible = false;
  }

  public override function disappear():Void
  {
    super.disappear();

    moreWays.visible = false;
    funnyScroll.visible = false;
    txtNuts.visible = false;
    funnyScroll2.visible = false;
    moreWays2.visible = false;
    funnyScroll3.visible = false;
    glowDark.visible = false;
    glow.visible = false;
  }
}
