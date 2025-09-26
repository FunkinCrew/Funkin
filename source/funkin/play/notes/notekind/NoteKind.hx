package funkin.play.notes.notekind;

import funkin.modding.IScriptedClass.INoteScriptedClass;
import funkin.modding.events.ScriptEvent;

/**
 * Class for note scripts
 */
class NoteKind implements INoteScriptedClass
{
  /**
   * The name of the note kind
   */
  public var noteKind:String;

  /**
   * Description used in chart editor
   */
  public var description:String;

  /**
   * Custom note style
   */
  public var noteStyleId:Null<String>;

  /**
   * Whether or not the sing animation should play.
   */
  public var noanim:Bool;

  /**
   * The animation suffix to use.
   */
  public var suffix:String;

  /**
   * Custom parameters for the chart editor
   */
  public var params:Array<NoteKindParam>;

  /**
   * If this note kind is scoreable (ie, counted towards score and accuracy)
   * Only accessible in scripts
   * Defaults to true
   */
  public var scoreable:Bool = true;

  public function new(noteKind:String, description:String = "", ?noteStyleId:String, ?params:Array<NoteKindParam>, ?noanim:Bool, ?suffix:String)
  {
    this.noteKind = noteKind;
    this.description = description;
    this.noteStyleId = noteStyleId;
    this.params = params ?? [];
    this.noanim = noanim ?? false;
    this.suffix = suffix ?? '';
  }

  public function toString():String
  {
    return noteKind;
  }

  /**
   * Retrieve all notes of this kind
   * @return Array<NoteSprite>
   */
  function getNotes():Array<NoteSprite>
  {
    var allNotes:Array<NoteSprite> = PlayState.instance.playerStrumline.notes.members.concat(PlayState.instance.opponentStrumline.notes.members);
    return allNotes.filter(function(note:NoteSprite) {
      return note != null && note.noteData.kind == this.noteKind;
    });
  }

  public function onScriptEvent(event:ScriptEvent):Void {}

  public function onCreate(event:ScriptEvent):Void {}

  public function onDestroy(event:ScriptEvent):Void {}

  public function onUpdate(event:UpdateScriptEvent):Void {}

  public function onNoteIncoming(event:NoteScriptEvent):Void {}

  public function onNoteHit(event:HitNoteScriptEvent):Void {}

  public function onNoteMiss(event:NoteScriptEvent):Void {}

  public function onNoteHoldDrop(event:HoldNoteScriptEvent) {}
}

/**
 * Abstract for setting the type of the `NoteKindParam`
 * This was supposed to be an enum but polymod kept being annoying
 */
abstract NoteKindParamType(String) from String to String
{
  public static final STRING:String = 'String';

  public static final INT:String = 'Int';

  public static final FLOAT:String = 'Float';
}

typedef NoteKindParamData =
{
  /**
   * If `min` is null, there is no minimum
   */
  ?min:Null<Float>,

  /**
   * If `max` is null, there is no maximum
   */
  ?max:Null<Float>,

  /**
   * If `step` is null, it will use 1.0
   */
  ?step:Null<Float>,

  /**
   * If `precision` is null, there will be 0 decimal places
   */
  ?precision:Null<Int>,

  ?defaultValue:Dynamic
}

/**
 * Typedef for creating custom parameters in the chart editor
 */
typedef NoteKindParam =
{
  name:String,
  description:String,
  type:NoteKindParamType,
  ?data:NoteKindParamData
}
