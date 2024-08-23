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
import lime.utils.Assets;
import openfl.display.BlendMode;
import flixel.group.FlxSpriteGroup;

/**
 * A class for the backing cards so they dont have to be part of freeplayState......
 */
class PicoCard extends BackingCard
{
  public override function init():Void
  {
    FlxTween.tween(pinkBack, {x: 0}, 0.6, {ease: FlxEase.quartOut});
    add(pinkBack);

    // add(orangeBackShit);

    // add(alsoOrangeLOL);

    // FlxSpriteUtil.alphaMaskFlxSprite(orangeBackShit, pinkBack, orangeBackShit);
    // orangeBackShit.visible = false;
    // alsoOrangeLOL.visible = false;

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

  public override function applyStyle(_freeplayState:FreeplayState):Void {}

  public override function introDone():Void
  {
    pinkBack.color = 0xFF98A2F3;
    // orangeBackShit.visible = true;
    // alsoOrangeLOL.visible = true;
    cardGlow.visible = true;
    FlxTween.tween(cardGlow, {alpha: 0, "scale.x": 1.2, "scale.y": 1.2}, 0.45, {ease: FlxEase.sineOut});
  }
}
