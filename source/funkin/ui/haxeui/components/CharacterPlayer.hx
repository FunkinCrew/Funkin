package funkin.ui.haxeui.components;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxRect;
import funkin.modding.events.ScriptEvent;
import funkin.modding.IScriptedClass.IPlayStateScriptedClass;
import funkin.play.character.BaseCharacter;
import funkin.play.character.CharacterData.CharacterDataParser;
import haxe.ui.containers.Box;
import haxe.ui.core.Component;
import haxe.ui.core.IDataComponent;
import haxe.ui.data.DataSource;
import haxe.ui.events.AnimationEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.geom.Size;
import haxe.ui.layouts.DefaultLayout;
import haxe.ui.styles.Style;
import openfl.Assets;

private typedef AnimationInfo =
{
  var name:String;
  var prefix:String;
  var frameRate:Null<Int>; // default 30
  var looped:Null<Bool>; // default true
  var flipX:Null<Bool>; // default false
  var flipY:Null<Bool>; // default false
}

@:composite(Layout)
class CharacterPlayer extends Box
{
  var character:BaseCharacter;

  public function new(?defaultToBf:Bool = true)
  {
    super();
    this._overrideSkipTransformChildren = false;

    if (defaultToBf)
    {
      loadCharacter('bf');
    }
  }

  var _charId:String;

  public var charId(get, set):String;

  function get_charId():String
  {
    return _charId;
  }

  function set_charId(value:String):String
  {
    _charId = value;
    loadCharacter(_charId);
    return value;
  }

  var _redispatchLoaded:Bool = false; // possible haxeui bug: if listener is added after event is dispatched, event is "lost"... needs thinking about, is it smart to "collect and redispatch"? Not sure
  var _redispatchStart:Bool = false; // possible haxeui bug: if listener is added after event is dispatched, event is "lost"... needs thinking about, is it smart to "collect and redispatch"? Not sure

  public override function onReady()
  {
    super.onReady();

    invalidateComponentLayout();

    if (_redispatchLoaded)
    {
      _redispatchLoaded = false;
      dispatch(new AnimationEvent(AnimationEvent.LOADED));
    }

    if (_redispatchStart)
    {
      _redispatchStart = false;
      dispatch(new AnimationEvent(AnimationEvent.START));
    }

    parentComponent._overrideSkipTransformChildren = false;
  }

  public function loadCharacter(id:String)
  {
    if (id == null)
    {
      return;
    }

    if (character != null)
    {
      remove(character);
      character.destroy();
      character = null;
    }

    var newCharacter:BaseCharacter = CharacterDataParser.fetchCharacter(id);

    if (newCharacter == null)
    {
      return;
    }

    character = newCharacter;
    if (_characterType != null)
    {
      character.characterType = _characterType;
    }
    if (flip)
    {
      character.flipX = !character.flipX;
    }

    character.scale.x *= _scale;
    character.scale.y *= _scale;

    character.animation.callback = function(name:String = "", frameNumber:Int = -1, frameIndex:Int = -1) {
      @:privateAccess
      character.onAnimationFrame(name, frameNumber, frameIndex);
      dispatch(new AnimationEvent(AnimationEvent.FRAME));
    };
    character.animation.finishCallback = function(name:String = "") {
      @:privateAccess
      character.onAnimationFinished(name);
      dispatch(new AnimationEvent(AnimationEvent.END));
    };
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

  override function repositionChildren()
  {
    super.repositionChildren();

    @:privateAccess
    var animOffsets = character.animOffsets;

    character.x = this.screenX + ((this.width / 2) - (character.frameWidth / 2));
    character.x -= animOffsets[0];
    character.y = this.screenY + ((this.height / 2) - (character.frameHeight / 2));
    character.y -= animOffsets[1];
  }

  var _characterType:CharacterType;

  public function setCharacterType(value:CharacterType)
  {
    _characterType = value;
    if (character != null)
    {
      character.characterType = value;
    }
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

  var _scale:Float = 1.0;

  public function setScale(value)
  {
    _scale = value;
    if (character != null)
    {
      character.scale.x *= _scale;
      character.scale.y *= _scale;
    }
  }

  public function onUpdate(event:UpdateScriptEvent)
  {
    if (character != null) character.onUpdate(event);
  }

  public function onBeatHit(event:SongTimeScriptEvent):Void
  {
    if (character != null) character.onBeatHit(event);

    this.repositionChildren();
  }

  public function onStepHit(event:SongTimeScriptEvent):Void
  {
    if (character != null) character.onStepHit(event);
  }

  public function onNoteHit(event:NoteScriptEvent):Void
  {
    if (character != null) character.onNoteHit(event);

    this.repositionChildren();
  }

  public function onNoteMiss(event:NoteScriptEvent):Void
  {
    if (character != null) character.onNoteMiss(event);

    this.repositionChildren();
  }

  public function onNoteGhostMiss(event:GhostMissNoteScriptEvent):Void
  {
    if (character != null) character.onNoteGhostMiss(event);

    this.repositionChildren();
  }
}

@:access(funkin.ui.haxeui.components.CharacterPlayer)
private class Layout extends DefaultLayout
{
  public override function repositionChildren()
  {
    var player = cast(_component, CharacterPlayer);
    var sprite:BaseCharacter = player.character;
    if (sprite == null)
    {
      return super.repositionChildren();
    }

    @:privateAccess
    var animOffsets = sprite.animOffsets;

    sprite.x = _component.screenLeft + ((_component.width / 2) - (sprite.frameWidth / 2));
    sprite.x += animOffsets[0];
    sprite.y = _component.screenTop + ((_component.height / 2) - (sprite.frameHeight / 2));
    sprite.y += animOffsets[1];
  }

  public override function calcAutoSize(exclusions:Array<Component> = null):Size
  {
    var player = cast(_component, CharacterPlayer);
    var sprite = player.character;
    if (sprite == null)
    {
      return super.calcAutoSize(exclusions);
    }
    var size = new Size();
    size.width = sprite.frameWidth + paddingLeft + paddingRight;
    size.height = sprite.frameHeight + paddingTop + paddingBottom;
    return size;
  }
}
