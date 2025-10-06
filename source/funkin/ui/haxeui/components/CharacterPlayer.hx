package funkin.ui.haxeui.components;

import funkin.modding.events.ScriptEvent.GhostMissNoteScriptEvent;
import funkin.modding.events.ScriptEvent.NoteScriptEvent;
import funkin.modding.events.ScriptEvent.HoldNoteScriptEvent;
import funkin.modding.events.ScriptEvent.HitNoteScriptEvent;
import funkin.modding.events.ScriptEvent.SongTimeScriptEvent;
import funkin.modding.events.ScriptEvent.UpdateScriptEvent;
import funkin.play.character.BaseCharacter;
import funkin.data.character.CharacterData.CharacterDataParser;
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
    if (targetScale != 1.0) character.setScale(character.isPixel ? targetScale * Constants.PIXEL_ART_SCALE : targetScale);

    character.animation.onFrameChange.add(onFrame);
    character.animation.onFinish.add(onFinish);
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
      character.setScale(character.isPixel ? value * Constants.PIXEL_ART_SCALE : value);
    }

    return targetScale = value;
  }

  public var xOffset(default, set):Float = 0;

  function set_xOffset(value:Float):Float
  {
    if (value == xOffset) return value;

    if (character != null)
    {
      character.x = this.cachedScreenX + xOffset;
    }

    return xOffset = value;
  }

  public var yOffset(default, set):Float = 0;

  function set_yOffset(value:Float):Float
  {
    if (value == yOffset) return value;

    if (character != null)
    {
      character.y = this.cachedScreenY + yOffset;
    }

    return yOffset = value;
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

    character.x = this.cachedScreenX + xOffset;
    character.y = this.cachedScreenY + yOffset;
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
    if (character != null)
    {
      character.onNoteHit(event);

      if ((event.note.noteData.getMustHitNote() && characterType == BF)
        || (!event.note.noteData.getMustHitNote() && characterType == DAD)) character.holdTimer = event.note.noteData.length / -1000;
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
