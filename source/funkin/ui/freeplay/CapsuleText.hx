package funkin.ui.freeplay;

import funkin.assets.Paths;
import funkin.ui.MarqueeText;
import openfl.filters.BitmapFilterQuality;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import funkin.graphics.shaders.GaussianBlurShader;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import openfl.display.BlendMode;
import flixel.util.FlxColor;

@:nullSafety
class CapsuleText extends FlxSpriteGroup
{
  public var blurredText:MarqueeText;

  var whiteText:MarqueeText;

  public var text(default, set):Null<String>;
  public var clipWidth(default, set):Int = 255;
  public var tooLong:Bool = false;

  var glowColor:FlxColor = 0xFF00ccff;

  static var sharedBlurShader:Null<GaussianBlurShader> = null;

  static function getSharedBlurShader():GaussianBlurShader
  {
    if (sharedBlurShader == null) sharedBlurShader = new GaussianBlurShader(1.0);
    return sharedBlurShader;
  }

  static var glowFilterCache:Map<Int, openfl.filters.GlowFilter> = new Map();

  static function getGlowFilter(color:FlxColor):openfl.filters.GlowFilter
  {
    final key:Int = color;
    var filter = glowFilterCache.get(key);
    if (filter == null)
    {
      filter = new openfl.filters.GlowFilter(color, 1, 5, 5, 210, BitmapFilterQuality.MEDIUM);
      glowFilterCache.set(key, filter);
    }
    return filter;
  }

  // hello full control over values... i guess
  static inline var MARQUEE_MOVE_DURATION:Float = 2.25;
  static inline var MARQUEE_START_DELAY_RATIO:Float = 0.3;
  static inline var MARQUEE_EDGE_PAUSE_RATIO:Float = 0.175;
  static inline var MARQUEE_RETURN_PAUSE_RATIO:Float = 0.3;
  static inline var MARQUEE_FADE_IN_RATIO:Float = 0.12;
  static inline var MARQUEE_FADE_IN_RIGHT_RATIO:Float = 0.14;
  static inline var MARQUEE_FADE_OUT_RATIO:Float = 0.16;
  static inline var MARQUEE_FADE_STAGGER_RATIO:Float = 0.05;
  static inline var MARQUEE_FADE:Float = 0.1;
  static inline var MARQUEE_FADE_RIGHT:Float = 0.08;
  static inline var MARQUEE_FADE_RIGHT_MOVING:Float = 0.075;
  static inline var FADE_IN_DURATION:Float = MARQUEE_MOVE_DURATION * MARQUEE_FADE_IN_RATIO;
  static inline var FADE_OUT_DURATION:Float = MARQUEE_MOVE_DURATION * MARQUEE_FADE_OUT_RATIO;
  static inline var TEXT_VERTICAL_OFFSET:Float = -6;

  var panelHeight:Float;

  public function new(x:Float, y:Float, songTitle:String, size:Float)
  {
    super(x, y);

    panelHeight = Math.ceil(size * 1.3);
    blurredText = CapsuleText.initText(songTitle, size, clipWidth, panelHeight, true);
    blurredText.textColor = glowColor;
    blurredText.color = FlxColor.WHITE;
    whiteText = CapsuleText.initText(songTitle, size, clipWidth, panelHeight);
    text = songTitle;

    checkClipWidth();

    blurredText.shader = getSharedBlurShader();

    add(blurredText);
    add(whiteText);
  }

  static function initText(songTitle:String, size:Float, panelWidth:Float, panelHeight:Float, useExternalShader:Bool = false):MarqueeText
  {
    var text = new MarqueeText(
      0,
      TEXT_VERTICAL_OFFSET,
      panelWidth,
      panelHeight,
      songTitle,
      Std.int(size),
      0,
      0,
      MARQUEE_FADE,
      MARQUEE_FADE_RIGHT,
      0.65,
      FlxColor.TRANSPARENT,
      FlxColor.WHITE,
      Paths.font('ui/fonts/5by7'),
      0.35,
      useExternalShader
    );
    text.alignment = LEFT;
    text.bounceMode = true;
    return text;
  }

  public function applyStyle(styleData:FreeplayStyle):Void
  {
    glowColor = styleData.getCapsuleSelCol();
    blurredText.textColor = glowColor;
    blurredText.color = FlxColor.WHITE;
    whiteText.textField.textField.filters = [getGlowFilter(glowColor)];
  }

  function set_clipWidth(value:Int):Int
  {
    var newWidth:Int = Std.int(Math.max(1, value));
    if (newWidth == clipWidth) return clipWidth;
    resetText();
    clipWidth = newWidth;
    whiteText.setPanelSize(newWidth, panelHeight);
    blurredText.setPanelSize(newWidth, panelHeight);
    checkClipWidth(newWidth);
    return clipWidth;
  }

  /**
   * Checks if the text if it's too long, and start bounce sequence if it is
   * @param wid
   */
  function checkClipWidth(?wid:Int):Void
  {
    if (wid == null) wid = clipWidth;

    tooLong = whiteText.bounceRange > 0.5;
    syncBounceOffset();
    resetFade();
  }

  function set_text(value:String):String
  {
    if (value == null) return value;

    var childrenChanged:Bool = whiteText.text != value || blurredText.text != value;
    if (childrenChanged)
    {
      whiteText.text = value;
      blurredText.text = value;
      resetText();
      checkClipWidth();
    }

    if (text != value || childrenChanged) whiteText.textField.textField.filters = [getGlowFilter(glowColor)];

    return text = value;
  }

  var moveTimer:FlxTimer = new FlxTimer();
  var moveTween:Null<FlxTween> = null;
  var fadeLeftTween:Null<FlxTween> = null;
  var fadeRightTween:Null<FlxTween> = null;
  var fadeLeftAmount:Float = 0;
  var fadeRightAmount:Float = 0;

  public function initMove():Void
  {
    resetText();
    if (!tooLong || whiteText.bounceRange <= 0) return;

    whiteText.bounceOffset = 0;
    syncBounceOffset();
    moveTimer.start(MARQUEE_MOVE_DURATION * MARQUEE_START_DELAY_RATIO, (_) -> moveTextRight());
  }

  function moveTextRight():Void
  {
    fadeInEdges();
    var distToMove:Float = whiteText.bounceRange + getFadeWidth();
    moveTween = FlxTween.tween(whiteText, {
      bounceOffset: distToMove
    }, MARQUEE_MOVE_DURATION, {
      onUpdate: (_) -> syncBounceOffset(),
      onComplete: (_) -> moveTimer.start(MARQUEE_MOVE_DURATION * MARQUEE_EDGE_PAUSE_RATIO, (_) -> moveTextLeft()),
      ease: FlxEase.sineInOut
    });
  }

  function moveTextLeft():Void
  {
    moveTween = FlxTween.tween(whiteText, {
      bounceOffset: 0
    }, MARQUEE_MOVE_DURATION, {
      onUpdate: (_) -> syncBounceOffset(),
      onComplete: (_) ->
      {
        syncBounceOffset();
        fadeOutEdges();
        moveTimer.start(FADE_OUT_DURATION + MARQUEE_MOVE_DURATION * MARQUEE_RETURN_PAUSE_RATIO, (_) -> moveTextRight());
      },
      ease: FlxEase.sineInOut
    });
  }

  function fadeInEdges():Void
  {
    cancelFadeTweens();
    fadeLeftAmount = 0;
    fadeRightAmount = MARQUEE_FADE_RIGHT;
    setFadeLeft(fadeLeftAmount);
    setFadeRight(fadeRightAmount);
    setFadeEnabled(tooLong);

    fadeLeftTween = FlxTween.num(fadeLeftAmount, MARQUEE_FADE, FADE_IN_DURATION, {
      ease: FlxEase.sineOut
    }, (value:Float) ->
      {
        fadeLeftAmount = value;
        setFadeLeft(value);
      });

    fadeRightTween = FlxTween.num(fadeRightAmount, MARQUEE_FADE_RIGHT_MOVING, MARQUEE_MOVE_DURATION * MARQUEE_FADE_IN_RIGHT_RATIO, {
      ease: FlxEase.sineOut,
      startDelay: MARQUEE_MOVE_DURATION * MARQUEE_FADE_STAGGER_RATIO
    }, (value:Float) ->
      {
        fadeRightAmount = value;
        setFadeRight(value);
      });
  }

  function fadeOutEdges():Void
  {
    cancelFadeTweens();

    fadeLeftTween = FlxTween.num(fadeLeftAmount, 0, FADE_OUT_DURATION, {
      ease: FlxEase.sineIn
    }, (value:Float) ->
      {
        fadeLeftAmount = value;
        setFadeLeft(value);
      });

    fadeRightTween = FlxTween.num(fadeRightAmount, MARQUEE_FADE_RIGHT, FADE_OUT_DURATION, {
      ease: FlxEase.sineIn,
      startDelay: MARQUEE_MOVE_DURATION * MARQUEE_FADE_STAGGER_RATIO
    }, (value:Float) ->
      {
        fadeRightAmount = value;
        setFadeRight(value);
      });
  }

  inline function setFadeLeft(value:Float):Void
  {
    whiteText.setFadeLeft(value);
    blurredText.setFadeLeft(value);
  }

  inline function setFadeRight(value:Float):Void
  {
    whiteText.setFadeRight(value);
    blurredText.setFadeRight(value);
  }

  function setFadeEnabled(value:Bool):Void
  {
    whiteText.setFadeEnabled(value);
    blurredText.setFadeEnabled(value);
  }

  function cancelFadeTweens():Void
  {
    fadeLeftTween?.cancel();
    fadeRightTween?.cancel();
    fadeLeftTween = null;
    fadeRightTween = null;
  }

  function resetFade():Void
  {
    cancelFadeTweens();
    fadeLeftAmount = 0;
    fadeRightAmount = tooLong ? MARQUEE_FADE_RIGHT : 0;
    setFadeLeft(fadeLeftAmount);
    setFadeRight(fadeRightAmount);
    setFadeEnabled(tooLong);
  }

  inline function getFadeWidth():Float
  {
    return Math.ceil(clipWidth * MARQUEE_FADE_RIGHT_MOVING);
  }

  inline function syncBounceOffset():Void
  {
    blurredText.bounceOffset = whiteText.bounceOffset;
  }

  public function resetText():Void
  {
    scale.set(1, 1);
    moveTween?.cancel();
    moveTween = null;
    moveTimer.cancel();
    whiteText.bounceOffset = 0;
    blurredText.bounceOffset = 0;
    resetFade();
    whiteText.resetScroll();
    blurredText.resetScroll();
  }

  var flickerState:Bool = false;
  var flickerTimer:Null<FlxTimer>;

  public function flickerText():Void
  {
    resetText();
    flickerTimer = new FlxTimer().start(1 / 24, flickerProgress, 19);
  }

  function flickerProgress(timer:FlxTimer):Void
  {
    if (flickerState == true)
    {
      whiteText.blend = BlendMode.ADD;
      blurredText.blend = BlendMode.ADD;
      blurredText.textColor = 0xFFFFFFFF;
      blurredText.color = FlxColor.WHITE;
      whiteText.color = 0xFFFFFFFF;
      whiteText.textField.textField.filters = [getGlowFilter(0xFFFFFF)];
    }
    else
    {
      whiteText.blend = BlendMode.NORMAL;
      blurredText.blend = BlendMode.NORMAL;
      blurredText.textColor = glowColor;
      blurredText.color = FlxColor.WHITE;
      whiteText.color = 0xFFDDDDDD;
      whiteText.textField.textField.filters = [getGlowFilter(0xDDDDDD)];
    }
    flickerState = !flickerState;
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);
    syncBounceOffset();
  }
}
