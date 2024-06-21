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
   * Custom parameters for the chart editor
   */
  public var params:Array<NoteKindParam>;

  public function new(noteKind:String, description:String = "", ?noteStyleId:String, ?params:Array<NoteKindParam>)
  {
    this.noteKind = noteKind;
    this.description = description;
    this.noteStyleId = noteStyleId;
    this.params = params ?? [];
  }

  public function toString():String
  {
    return noteKind;
  }

  /**
   * Retrieve the param with the given name
   * If there exists no param with the given name then `null` is returned
   * @param name Name of the param
   * @return Null<NoteKindParam>
   */
  public function getParam(name:String):Null<NoteKindParam>
  {
    for (param in params)
    {
      if (param.name == name)
      {
        return param;
      }
    }

    return null;
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
}

/**
 * Abstract for setting the type of the `NoteKindParam`
 * This was supposed to be an enum but polymod kept being annoying
 */
abstract NoteKindParamType(String)
{
  public static var STRING:String = "String";

  public static var INT:String = "Int";

  public static var RANGED_INT:String = "RangedInt";

  public static var FLOAT:String = "Float";

  public static var RANGED_FLOAT:String = "RangedFloat";
}

typedef NoteKindParamData =
{
  /**
   * Only used for `RangedInt` and `RangedFloat`
   */
  var min:Null<Float>;

  /**
   * Only used for `RangedInt` and `RangedFloat`
   */
  var max:Null<Float>;

  var value:Dynamic;
}

/**
 * Typedef for creating custom parameters in the chart editor
 */
typedef NoteKindParam =
{
  var name:String;
  var description:String;
  var type:NoteKindParamType;
  var data:NoteKindParamData;
}
