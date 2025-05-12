package funkin.ui.haxeui.components;

import funkin.modding.events.ScriptEvent.GhostMissNoteScriptEvent;
import funkin.modding.events.ScriptEvent.NoteScriptEvent;
import funkin.modding.events.ScriptEvent.HoldNoteScriptEvent;
import funkin.modding.events.ScriptEvent.HitNoteScriptEvent;
import funkin.modding.events.ScriptEvent.SongTimeScriptEvent;
import funkin.modding.events.ScriptEvent.UpdateScriptEvent;
import funkin.play.character.BaseCharacter;
import funkin.play.character.CharacterData.CharacterDataParser;
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
  var character:Null<BaseCharacter>;

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
    return character?.characterName ?? "Unknown";
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
    var newCharacter:BaseCharacter = CharacterDataParser.fetchCharacter(id, true);
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
    if (targetScale != 1.0) character.setScale(targetScale);

    character.animation.onFrameChange.add(function(name:String = '', frameNumber:Int = -1, frameIndex:Int = -1) {
      dispatch(new AnimationEvent(AnimationEvent.FRAME));
    });
    character.animation.onFinish.add(function(name:String = '') {
      dispatch(new AnimationEvent(AnimationEvent.END));
    });
    add(character);

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
    }

    return flip = value;
  }

  public var targetScale(default, set):Float = 1.0;

  function set_targetScale(value:Float):Float
  {
    if (value == targetScale) return value;

    if (character != null)
    {
      character.setScale(value);
    }

    return targetScale = value;
  }

  function onFrame(name:String, frameNumber:Int, frameIndex:Int):Void
  {
    dispatch(new AnimationEvent(AnimationEvent.FRAME));
  }

  function onFinish(name:String):Void
  {
    dispatch(new AnimationEvent(AnimationEvent.END));
  }

  override function repositionChildren():Void
  {
    super.repositionChildren();
    character.x = this.cachedScreenX;
    character.y = this.cachedScreenY;

    // Apply animation offsets, so the character is positioned correctly based on the animation.
    @:privateAccess var animOffsets:Array<Float> = character.animOffsets;

    character.x -= animOffsets[0] * targetScale * (flip ? -1 : 1);
    character.y -= animOffsets[1] * targetScale;
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

  public function onNoteIncoming(event:NoteScriptEvent)
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
    if (character != null) character.onNoteHit(event);
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
private class Layout extends DefaultLayout
{
  public override function resizeChildren():Void
  {
    super.resizeChildren();

    var player:CharacterPlayer = cast(_component, CharacterPlayer);
    var character:BaseCharacter = player.character;
    if (character == null)
    {
      return super.resizeChildren();
    }

    character.cornerPosition.set(0, 0);
    // character.setGraphicSize(Std.int(innerWidth), Std.int(innerHeight));
  }

  public override function calcAutoSize(exclusions:Array<Component> = null):Size
  {
    var player:CharacterPlayer = cast(_component, CharacterPlayer);
    var character:BaseCharacter = player.character;
    if (character == null)
    {
      return super.calcAutoSize(exclusions);
    }
    var size:Size = new Size();
    size.width = character.width + paddingLeft + paddingRight;
    size.height = character.height + paddingTop + paddingBottom;
    return size;
  }
}
