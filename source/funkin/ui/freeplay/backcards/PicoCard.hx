package funkin.ui.freeplay.backcards;

import funkin.ui.freeplay.FreeplayState;
import flash.display.BitmapData;
import flixel.FlxCamera;
import flixel.math.FlxMath;
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
import funkin.graphics.shaders.AdjustColorShader;
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.display.FlxBackdrop;

class PicoCard extends BackingCard
{
  var scrollBack:FlxBackdrop;
  var scrollLower:FlxBackdrop;
  var scrollTop:FlxBackdrop;
  var scrollMiddle:FlxBackdrop;

  var glow:FlxSprite;
  var glowDark:FlxSprite;
  var blueBar:FlxSprite;

  var confirmAtlas:FlxAtlasSprite;

  public override function enterCharSel():Void
  {
    FlxTween.tween(scrollBack.velocity, {x: 0}, 0.8, {ease: FlxEase.sineIn});
    FlxTween.tween(scrollLower.velocity, {x: 0}, 0.8, {ease: FlxEase.sineIn});
    FlxTween.tween(scrollTop.velocity, {x: 0}, 0.8, {ease: FlxEase.sineIn});
    FlxTween.tween(scrollMiddle.velocity, {x: 0}, 0.8, {ease: FlxEase.sineIn});
  }

  public override function applyExitMovers(?exitMovers:FreeplayState.ExitMoverData, ?exitMoversCharSel:FreeplayState.ExitMoverData):Void
  {
    super.applyExitMovers(exitMovers, exitMoversCharSel);
    if (exitMovers == null || exitMoversCharSel == null) return;

    exitMoversCharSel.set([scrollTop],
      {
        y: -90,
        speed: 0.8,
        wait: 0.1
      });

    exitMoversCharSel.set([scrollMiddle],
      {
        y: -80,
        speed: 0.8,
        wait: 0.1
      });

    exitMoversCharSel.set([blueBar],
      {
        y: -70,
        speed: 0.8,
        wait: 0.1
      });

    exitMoversCharSel.set([scrollLower],
      {
        y: -60,
        speed: 0.8,
        wait: 0.1
      });

    exitMoversCharSel.set([scrollBack],
      {
        y: -50,
        speed: 0.8,
        wait: 0.1
      });
  }

  public override function init():Void
  {
    FlxTween.tween(pinkBack, {x: 0}, 0.6, {ease: FlxEase.quartOut});
    add(pinkBack);

    confirmTextGlow.blend = BlendMode.ADD;
    confirmTextGlow.visible = false;

    confirmGlow.blend = BlendMode.ADD;

    confirmGlow.visible = false;
    confirmGlow2.visible = false;

    scrollBack = new FlxBackdrop(Paths.image('freeplay/backingCards/pico/lowerLoop'), X, 20);
    scrollBack.setPosition(0, 200);
    scrollBack.flipX = true;
    scrollBack.alpha = 0.39;
    scrollBack.velocity.x = 110;
    add(scrollBack);

    scrollLower = new FlxBackdrop(Paths.image('freeplay/backingCards/pico/lowerLoop'), X, 20);
    scrollLower.setPosition(0, 406);
    scrollLower.velocity.x = -110;
    add(scrollLower);

    blueBar = new FlxSprite(0, 239).loadGraphic(Paths.image('freeplay/backingCards/pico/blueBar'));
    blueBar.blend = BlendMode.MULTIPLY;
    blueBar.alpha = 0.4;
    add(blueBar);

    scrollTop = new FlxBackdrop(null, X, 20);
    scrollTop.setPosition(0, 80);
    scrollTop.velocity.x = -220;

    scrollTop.frames = Paths.getSparrowAtlas('freeplay/backingCards/pico/topLoop');
    scrollTop.animation.addByPrefix('uzi', 'uzi info', 24, false);
    scrollTop.animation.addByPrefix('sniper', 'sniper info', 24, false);
    scrollTop.animation.addByPrefix('rocket launcher', 'rocket launcher info', 24, false);
    scrollTop.animation.addByPrefix('rifle', 'rifle info', 24, false);
    scrollTop.animation.addByPrefix('base', 'base', 24, false);
    scrollTop.animation.play('base');

    add(scrollTop);

    scrollMiddle = new FlxBackdrop(Paths.image('freeplay/backingCards/pico/middleLoop'), X, 15);
    scrollMiddle.setPosition(0, 346);
    add(scrollMiddle);
    scrollMiddle.velocity.x = 220;

    glowDark = new FlxSprite(-300, 330).loadGraphic(Paths.image('freeplay/backingCards/pico/glow'));
    glowDark.blend = BlendMode.MULTIPLY;
    add(glowDark);

    glow = new FlxSprite(-300, 330).loadGraphic(Paths.image('freeplay/backingCards/pico/glow'));
    glow.blend = BlendMode.ADD;
    add(glow);

    blueBar.visible = false;
    scrollBack.visible = false;
    scrollLower.visible = false;
    scrollTop.visible = false;
    scrollMiddle.visible = false;
    glow.visible = false;
    glowDark.visible = false;

    confirmAtlas = new FlxAtlasSprite(5, 55, Paths.animateAtlas("freeplay/backingCards/pico/pico-confirm"));
    confirmAtlas.visible = false;
    add(confirmAtlas);

    cardGlow.blend = BlendMode.ADD;
    cardGlow.visible = false;
    add(cardGlow);
  }

  override public function confirm():Void
  {
    confirmAtlas.visible = true;
    confirmAtlas.anim.play("");

    FlxTween.color(instance.bgDad, 10 / 24, 0xFFFFFFFF, 0xFF8A8A8A,
      {
        ease: FlxEase.expoOut,
        onUpdate: function(_) {
          instance.angleMaskShader.extraColor = instance.bgDad.color;
        }
      });

    new FlxTimer().start(10 / 24, function(_) {
      // shoot
      FlxTween.color(instance.bgDad, 3 / 24, 0xFF343036, 0xFF696366,
        {
          ease: FlxEase.expoOut,
          onUpdate: function(_) {
            instance.angleMaskShader.extraColor = instance.bgDad.color;
          }
        });
    });

    new FlxTimer().start(14 / 24, function(_) {
      // shoot
      FlxTween.color(instance.bgDad, 3 / 24, 0xFF27292D, 0xFF686A6F,
        {
          ease: FlxEase.expoOut,
          onUpdate: function(_) {
            instance.angleMaskShader.extraColor = instance.bgDad.color;
          }
        });
    });

    new FlxTimer().start(18 / 24, function(_) {
      // shoot
      FlxTween.color(instance.bgDad, 3 / 24, 0xFF2D282D, 0xFF676164,
        {
          ease: FlxEase.expoOut,
          onUpdate: function(_) {
            instance.angleMaskShader.extraColor = instance.bgDad.color;
          }
        });
    });

    new FlxTimer().start(21 / 24, function(_) {
      // shoot
      FlxTween.color(instance.bgDad, 3 / 24, 0xFF29292F, 0xFF62626B,
        {
          ease: FlxEase.expoOut,
          onUpdate: function(_) {
            instance.angleMaskShader.extraColor = instance.bgDad.color;
          }
        });
    });

    new FlxTimer().start(24 / 24, function(_) {
      // shoot
      FlxTween.color(instance.bgDad, 3 / 24, 0xFF29232C, 0xFF808080,
        {
          ease: FlxEase.expoOut,
          onUpdate: function(_) {
            instance.angleMaskShader.extraColor = instance.bgDad.color;
          }
        });
    });
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

    glow.alpha = 1;
    FlxTween.tween(glow, {alpha: 0}, 16 / 24, {ease: FlxEase.quartOut});
    glowDark.alpha = 0;
    FlxTween.tween(glowDark, {alpha: 1}, 18 / 24, {ease: FlxEase.quartOut});
  }

  public override function introDone():Void
  {
    pinkBack.color = 0xFF98A2F3;

    blueBar.visible = true;
    scrollBack.visible = true;
    scrollLower.visible = true;
    scrollTop.visible = true;
    scrollMiddle.visible = true;
    glowDark.visible = true;
    glow.visible = true;

    cardGlow.visible = true;
    FlxTween.tween(cardGlow, {alpha: 0, "scale.x": 1.2, "scale.y": 1.2}, 0.45, {ease: FlxEase.sineOut});
  }

  public override function disappear():Void
  {
    FlxTween.color(pinkBack, 0.25, 0xFF98A2F3, 0xFFFFD0D5, {ease: FlxEase.quadOut});

    blueBar.visible = false;
    scrollBack.visible = false;
    scrollLower.visible = false;
    scrollTop.visible = false;
    scrollMiddle.visible = false;
    glowDark.visible = false;
    glow.visible = false;

    cardGlow.visible = true;
    cardGlow.alpha = 1;
    cardGlow.scale.set(1, 1);
    FlxTween.tween(cardGlow, {alpha: 0, "scale.x": 1.2, "scale.y": 1.2}, 0.25, {ease: FlxEase.sineOut});
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);
    var scrollProgress:Float = Math.abs(scrollTop.x % (scrollTop.frameWidth + 20));

    if (scrollTop.animation.curAnim.finished == true)
    {
      if (FlxMath.inBounds(scrollProgress, 500, 700) && scrollTop.animation.curAnim.name != 'sniper')
      {
        scrollTop.animation.play('sniper', true, false);
      }

      if (FlxMath.inBounds(scrollProgress, 700, 1300) && scrollTop.animation.curAnim.name != 'rifle')
      {
        scrollTop.animation.play('rifle', true, false);
      }

      if (FlxMath.inBounds(scrollProgress, 1450, 2000) && scrollTop.animation.curAnim.name != 'rocket launcher')
      {
        scrollTop.animation.play('rocket launcher', true, false);
      }

      if (FlxMath.inBounds(scrollProgress, 0, 300) && scrollTop.animation.curAnim.name != 'uzi')
      {
        scrollTop.animation.play('uzi', true, false);
      }
    }
  }
}
