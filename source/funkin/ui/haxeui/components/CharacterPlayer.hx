package funkin.ui.haxeui.components;

import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;
import funkin.modding.events.ScriptEvent.GhostMissNoteScriptEvent;
import funkin.modding.events.ScriptEvent.NoteScriptEvent;
import funkin.modding.events.ScriptEvent.HoldNoteScriptEvent;
import funkin.modding.events.ScriptEvent.HitNoteScriptEvent;
import funkin.modding.events.ScriptEvent.SongTimeScriptEvent;
import funkin.modding.events.ScriptEvent.UpdateScriptEvent;
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
      measureCharacter();
      repositionChildren();
    }

    return targetScale = value;
  }

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
    invalidateComponentLayout();
  }

  function measureCurrentFrame():Void
  {
    var frameBounds:FlxRect = character.getCurrentFrameBounds(FlxRect.get(), character.camera);

    if (!frameBounds.isEmpty)
    {
      frameBounds.offset(-character.x, -character.y);
      characterBounds = (characterBounds == null) ? FlxRect.get().copyFrom(frameBounds) : characterBounds.union(frameBounds);
    }

    frameBounds.put();
  }

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
