package funkin.ui.haxeui.components;

import animate.internal.Timeline;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;
import funkin.modding.events.ScriptEvent.GhostMissNoteScriptEvent;
import funkin.modding.events.ScriptEvent.NoteScriptEvent;
import funkin.modding.events.ScriptEvent.HoldNoteScriptEvent;
import funkin.modding.events.ScriptEvent.HitNoteScriptEvent;
import funkin.modding.events.ScriptEvent.SongTimeScriptEvent;
import funkin.modding.events.ScriptEvent.UpdateScriptEvent;
import funkin.graphics.shaders.VerticalFadeShader;
import funkin.play.character.BaseCharacter;
import funkin.data.character.CharacterRegistry;
import haxe.ui.containers.Box;
import haxe.ui.core.Component;
import haxe.ui.events.AnimationEvent;
import haxe.ui.geom.Size;
import haxe.ui.layouts.DefaultLayout;

typedef AnimationInfo =
{
  var name:String;
  var prefix:String;
  var frameRate:Null<Int>; // default 30
  var looped:Null<Bool>; // default true
  var flipX:Null<Bool>; // default false
  var flipY:Null<Bool>; // default false
}

/**
 * A variant of SparrowPlayer which loads a BaseCharacter instead.
 * This allows it to play appropriate animations based on song events.
 */
@:composite(Layout)
class CharacterPlayer extends Box
{
  public var character:Null<BaseCharacter>;

  var characterBounds:Null<FlxRect> = null;

  public function new(defaultToBf:Bool = true)
  {
    super();
    // _overrideSkipTransformChildren = false;

    if (defaultToBf)
    {
      loadCharacter('bf');
    }
  }

  public var charId(get, set):String;

  function get_charId():String
  {
    return character?.characterId ?? '';
  }

  function set_charId(value:String):String
  {
    loadCharacter(value);
    return value;
  }

  public var charName(get, never):String;

  function get_charName():String
  {
    return character?.characterName ?? 'Unknown';
  }

  // possible haxeui bug: if listener is added after event is dispatched, event is "lost"... is it smart to "collect and redispatch"? Not sure
  var _redispatchLoaded:Bool = false;
  // possible haxeui bug: if listener is added after event is dispatched, event is "lost"... is it smart to "collect and redispatch"? Not sure
  var _redispatchStart:Bool = false;
  var _characterLoaded:Bool = false;

  /**
   * Loads a character by ID.
   * @param id The ID of the character to load.
   */
  @:access(funkin.play.character.BaseCharacter)
  public function loadCharacter(id:String):Void
  {
    if (id == null) return;

    if (character != null)
    {
      remove(character);
      character.destroy();
      character = null;
    }

    // Prevent script issues by fetching with debug=true.
    var newCharacter:BaseCharacter = CharacterRegistry.instance.fetchEntry(id, {
      debug: true
    });
    if (newCharacter == null)
    {
      character = null;
      return; // Fail if character doesn't exist.
    }

    // Assign character.
    character = newCharacter;

    // Set character properties.
    if (characterType != null) character.characterType = characterType;
    if (flip) character.flipX = !character.flipX;
    if (targetScale != 1.0) character.setScale(character.getBaseScale() * targetScale);

    measureCharacter();

    character.animation.onFrameChange.add(onFrame);
    character.animation.onFinish.add(onFinish);
    add(character);
    repositionChildren();

    invalidateComponentLayout();

    if (hasEvent(AnimationEvent.LOADED))
    {
      dispatch(new AnimationEvent(AnimationEvent.LOADED));
    }
    else
    {
      _redispatchLoaded = true;
    }
  }

  /**
   * The character type (such as BF, Dad, GF, etc).
   */
  public var characterType(default, set):CharacterType;

  function set_characterType(value:CharacterType):CharacterType
  {
    if (character != null) character.characterType = value;
    return characterType = value;
  }

  public var flip(default, set):Bool;

  function set_flip(value:Bool):Bool
  {
    if (value == flip) return value;

    if (character != null)
    {
      character.flipX = !character.flipX;
      measureCharacter();
    }

    return flip = value;
  }

  public var targetScale(default, set):Float = 1.0;

  function set_targetScale(value:Float):Float
  {
    if (value == targetScale) return value;

    if (character != null)
    {
      character.setScale(character.getBaseScale() * value);
      var measured:Null<FlxRect> = measuredBounds;
      if (measured != null && measuredScale != 0)
      {
        var ratio:Float = character.scale.x / measuredScale;
        if (characterBounds == null) characterBounds = FlxRect.get();
        characterBounds.set(measured.x * ratio, measured.y * ratio, measured.width * ratio, measured.height * ratio);
        invalidateComponentLayout();
      }
      else
      {
        measureCharacter();
      }
      repositionChildren();
    }

    return targetScale = value;
  }

  /**
   * The size that the CharacterPlayer should be to fit the character, including padding.
   */
  public function getFitSize():Null<Size>
  {
    if (character == null || characterBounds == null) return null;
    return new Size(characterBounds.width + (paddingLeft ?? 0) + (paddingRight ?? 0), characterBounds.height + (paddingTop ?? 0) + (paddingBottom ?? 0));
  }

  var measuredBounds:Null<FlxRect> = null;

  var measuredScale:Float = 0;

  @:access(funkin.play.stage.Bopper)
  function measureCharacter():Void
  {
    characterBounds = FlxDestroyUtil.put(characterBounds);
    if (character == null) return;

    for (animName in character.animation.getNameList())
    {
      if (animName.toLowerCase().contains('death')) continue;

      character.animation.play(animName, true);
      character.applyAnimationOffsets(animName);

      for (i in 0...character.animation.curAnim.numFrames)
      {
        character.animation.curAnim.curFrame = i;
        measureCurrentFrame();
      }
    }

    character.dance(true);

    measuredBounds = FlxDestroyUtil.put(measuredBounds);
    if (characterBounds != null)
    {
      measuredBounds = FlxRect.get().copyFrom(characterBounds);
      measuredScale = character.scale.x;
    }

    invalidateComponentLayout();
  }

  @:access(funkin.play.stage.Bopper)
  @:access(flixel.FlxSprite)
  function measureCurrentFrame():Void
  {
    var frameBounds:FlxRect = character.isAnimate ? character.getCurrentFrameBounds(FlxRect.get(), character.camera) : getSpriteFrameBounds(FlxRect.get());

    if (!frameBounds.isEmpty)
    {
      frameBounds.offset(-character.x, -character.y);
      characterBounds = (characterBounds == null) ? FlxRect.get().copyFrom(frameBounds) : characterBounds.union(frameBounds);
    }

    frameBounds.put();
  }

  @:access(flixel.FlxSprite)
  function getSpriteFrameBounds(rect:FlxRect):FlxRect
  {
    var frame = character.frame;
    if (frame == null) return rect.set(0, 0, 0, 0);

    var trimmedWidth:Float = (frame.angle == 0) ? frame.frame.width : frame.frame.height;
    var trimmedHeight:Float = (frame.angle == 0) ? frame.frame.height : frame.frame.width;
    var trimX:Float = character.checkFlipX() ? frame.sourceSize.x - frame.offset.x - trimmedWidth : frame.offset.x;
    var trimY:Float = character.checkFlipY() ? frame.sourceSize.y - frame.offset.y - trimmedHeight : frame.offset.y;

    // from FlxSprite
    var screenPos = character.getScreenPosition(null, character.camera);
    var scaleX:Float = Math.abs(character.scale.x);
    var scaleY:Float = Math.abs(character.scale.y);
    rect.set(screenPos.x - character.offset.x + character.origin.x - character.origin.x * scaleX + trimX * scaleX,
      screenPos.y - character.offset.y + character.origin.y - character.origin.y * scaleY + trimY * scaleY, trimmedWidth * scaleX, trimmedHeight * scaleY);
    screenPos.put();
    return rect;
  }

  /**
   * Whether a point in HaxeUI screen coordinates is over the character's current frame.
   */
  @:access(funkin.play.stage.Bopper)
  public function isPointOverCharacter(screenX:Float, screenY:Float):Bool
  {
    if (character == null || !character.visible || hidden) return false;
    var frameBounds:FlxRect = character.isAnimate ? character.getCurrentFrameBounds(FlxRect.get(), character.camera) : getSpriteFrameBounds(FlxRect.get());
    var px:Float = screenX * haxe.ui.Toolkit.scale;
    var py:Float = screenY * haxe.ui.Toolkit.scale;
    var result:Bool = !frameBounds.isEmpty && px >= frameBounds.left && px < frameBounds.right && py >= frameBounds.top && py < frameBounds.bottom;
    frameBounds.put();
    return result;
  }

  /**
   * Set once the mouse reaches the character, and kept while it stays inside the preview window.
   */
  public var previewHoverActive:Bool = false;

  function onFrame(name:String, frameNumber:Int, frameIndex:Int):Void
  {
    dispatch(new AnimationEvent(AnimationEvent.FRAME));
  }

  function onFinish(name:String):Void
  {
    dispatch(new AnimationEvent(AnimationEvent.END));
  }

  public function playAnimManually(name:String, restart:Bool = false, ignoreOther:Bool = false, reversed:Bool = false):Void
  {
    if (character != null) character.playAnimation(name, restart, ignoreOther, reversed);
  }

  public function setBopSpeed(speed:Float = 1):Void
  {
    if (character != null) character.danceEvery = speed;
  }

  override function repositionChildren():Void
  {
    super.repositionChildren();

    if (character == null || characterBounds == null) return;
    character.x = this.cachedScreenX + (paddingLeft ?? 0) - characterBounds.x;
    character.y = this.cachedScreenY + (paddingTop ?? 0) - characterBounds.y;
  }

  /**
   * If true, the character will be drawn with a reflection below it.
   */
  public var showReflection:Bool = false;

  static final REFLECTION_ALPHA:Float = 0.35;

  var reflectionShader:Null<VerticalFadeShader> = null;

  var lastReflectionTimeline:Null<Timeline> = null;
  var lastReflectionFrame:Int = -1;

  override public function draw():Void
  {
    super.draw();

    if (showReflection && visible && character != null && character.visible && characterBounds != null) drawReflection(character);
  }

  /**
   * Draws the character again, flipped about the bottom of its bounds and faded out toward the head.
   */
  @:access(funkin.play.stage.Bopper)
  @:access(animate.FlxAnimate)
  @:access(animate.internal.Timeline)
  function drawReflection(char:BaseCharacter):Void
  {
    var shader:VerticalFadeShader = reflectionShader ?? (reflectionShader = new VerticalFadeShader(0.7));

    var oldY:Float = char.y;
    var oldFlipY:Bool = char.flipY;
    var oldAlpha:Float = char.alpha;
    var oldShader = char.shader;
    var oldRenderTexture:Bool = char.useRenderTexture;

    var scaleY:Float = char.scale.y;
    var animOffsetY:Float = char.animOffsets[1] - char.globalOffsets[1];
    var boxHeight:Float = char.isAnimate ? char.timeline._bounds.height : char.frameHeight;

    var shown:FlxRect = char.isAnimate ? char.getCurrentFrameBounds(FlxRect.get(), char.camera) : getSpriteFrameBounds(FlxRect.get());
    var feetY:Float = shown.isEmpty ? oldY + characterBounds.bottom : shown.bottom;
    shown.put();
    char.y = 2 * feetY - oldY - scaleY * boxHeight + 2 * scaleY * animOffsetY;

    if (char.isAnimate)
    {
      // force to be a render texture or else it'll look weird
      char.useRenderTexture = true;
      if (char.timeline != lastReflectionTimeline || char.animation.frameIndex != lastReflectionFrame)
      {
        char._renderTextureDirty = true;
        lastReflectionTimeline = char.timeline;
        lastReflectionFrame = char.animation.frameIndex;
      }
    }

    char.flipY = !oldFlipY;
    char.alpha = oldAlpha * REFLECTION_ALPHA;
    char.shader = char.isAnimate ? shader : null;

    char.draw();

    char.flipY = oldFlipY;
    char.alpha = oldAlpha;
    char.shader = oldShader;
    char.useRenderTexture = oldRenderTexture;
    char.y = oldY;
  }

  /**
   * Called when an update event is hit in the song.
   * Used to play character animations.
   * @param event The event.
   */
  public function onUpdate(event:UpdateScriptEvent):Void
  {
    if (character != null) character.onUpdate(event);
  }

  /**
   * Called when an beat is hit in the song
   * Used to play character animations.
   * @param event The event.
   */
  public function onBeatHit(event:SongTimeScriptEvent):Void
  {
    if (character != null) character.onBeatHit(event);
  }

  /**
   * Called when a step is hit in the song
   * Used to play character animations.
   * @param event The event.
   */
  public function onStepHit(event:SongTimeScriptEvent):Void
  {
    if (character != null) character.onStepHit(event);
  }

  public function onNoteIncoming(event:NoteScriptEvent):Void
  {
    if (character != null) character.onNoteIncoming(event);
  }

  /**
   * Called when a note is hit in the song
   * Used to play character animations.
   * @param event The event.
   */
  public function onNoteHit(event:HitNoteScriptEvent):Void
  {
    if (character != null)
    {
      character.onNoteHit(event);

      if
        ((event.note.noteData.getMustHitNote() && characterType == BF)
          || (!event.note.noteData.getMustHitNote() && characterType == DAD)
        ) character.holdTimer = -event.note.noteData?.length / Constants.MS_PER_SEC;
      // At least i tried yaknow?
    }
  }

  /**
   * Called when a note is missed in the song
   * Used to play character animations.
   * @param event The event.
   */
  public function onNoteMiss(event:NoteScriptEvent):Void
  {
    if (character != null) character.onNoteMiss(event);
  }

  /**
   * Called when a hold note is dropped in the song
   * Used to play character animations.
   * @param event The event.
   */
  public function onNoteHoldDrop(event:HoldNoteScriptEvent):Void
  {
    if (character != null) character.onNoteHoldDrop(event);
  }

  /**
   * Called when a key is pressed but no note is hit in the song
   * Used to play character animations.
   * @param event The event.
   */
  public function onNoteGhostMiss(event:GhostMissNoteScriptEvent):Void
  {
    if (character != null) character.onNoteGhostMiss(event);
  }
}

@:access(funkin.ui.haxeui.components.CharacterPlayer)
@:access(funkin.play.character.BaseCharacter)
private class Layout extends DefaultLayout
{
  override public function resizeChildren():Void
  {
    super.resizeChildren();

    var player:CharacterPlayer = cast(_component, CharacterPlayer);
    var character:BaseCharacter = player.character;
    if (character == null)
    {
      return super.resizeChildren();
    }

    character.cornerPosition.set(0, 0);
  }

  override public function calcAutoSize(?exclusions:Array<Component>):Size
  {
    var player:CharacterPlayer = cast(_component, CharacterPlayer);
    if (player.characterBounds == null)
    {
      return super.calcAutoSize(exclusions);
    }
    var size:Size = new Size();

    size.width = player.characterBounds.width + paddingLeft + paddingRight;
    size.height = player.characterBounds.height + paddingTop + paddingBottom;

    return size;
  }
}
