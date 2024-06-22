package funkin.play.notes.notekind;

import funkin.modding.IScriptedClass.INoteScriptedClass;
import funkin.modding.events.ScriptEvent;
import flixel.math.FlxMath;

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
   * Retrieve the value of the param with the given name
   * If there exists no param with the given name then `null` is returned
   * @param name Name of the param
   * @return Null<Dynamic>
   */
  public function getParam(name:String):Null<Dynamic>
  {
    for (param in params)
    {
      if (param.name == name)
      {
        return param.data.value;
      }
    }

    return null;
  }

  /**
   * Set the value of the param with the given name
   * @param name Name of the param
   * @param value New value
   */
  public function setParam(name:String, value:Dynamic):Void
  {
    for (param in params)
    {
      if (param.name == name)
      {
        if (param.type == NoteKindParamType.INT || param.type == NoteKindParamType.FLOAT)
        {
          param.data.value = FlxMath.bound(value, param.data.min, param.data.max);
        }
        else
        {
          param.data.value = value;
        }

        break;
      }
    }
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
abstract NoteKindParamType(String) to String
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
  var min:Null<Float>;

  /**
   * If `max` is null, there is no maximum
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
