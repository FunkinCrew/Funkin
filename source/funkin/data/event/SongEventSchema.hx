package funkin.data.event;

import funkin.play.event.SongEvent;
import funkin.data.event.SongEventSchema;
import funkin.data.song.SongData.SongEventData;
import funkin.util.macro.ClassMacro;
import funkin.play.event.ScriptedSongEvent;

@:forward(name, tittlte, type, keys, min, max, step, defaultValue, iterator)
abstract SongEventSchema(SongEventSchemaRaw)
{
  public function new(?fields:Array<SongEventSchemaField>)
  {
    this = fields;
  }

  @:arrayAccess
  public inline function getByName(name:String):SongEventSchemaField
  {
    for (field in this)
    {
      if (field.name == name) return field;
    }

    return null;
  }

  public function getFirstField():SongEventSchemaField
  {
    return this[0];
  }

  @:arrayAccess
  public inline function get(key:Int)
  {
    return this[key];
  }

  @:arrayAccess
  public inline function arrayWrite(k:Int, v:SongEventSchemaField):SongEventSchemaField
  {
    return this[k] = v;
  }
}

typedef SongEventSchemaRaw = Array<SongEventSchemaField>;

typedef SongEventSchemaField =
{
  /**
   * The name of the property as it should be saved in the event data.
   */
  name:String,

  /**
   * The title of the field to display in the UI.
   */
  title:String,

  /**
   * The type of the field.
   */
  type:SongEventFieldType,

  /**
   * Used only for ENUM values.
   * The key is the display name and the value is the actual value.
   */
  ?keys:Map<String, Dynamic>,

  /**
   * Used for INTEGER and FLOAT values.
   * The minimum value that can be entered.
   * @default No minimum
   */
  ?min:Float,

  /**
   * Used for INTEGER and FLOAT values.
   * The maximum value that can be entered.
   * @default No maximum
   */
  ?max:Float,

  /**
   * Used for INTEGER and FLOAT values.
   * The step value that will be used when incrementing/decrementing the value.
   * @default `0.1`
   */
  ?step:Float,

  /**
   * An optional default value for the field.
   */
  ?defaultValue:Dynamic,
}

enum abstract SongEventFieldType(String) from String to String
{
  /**
   * The STRING type will display as a text field.
   */
  var STRING = "string";

  /**
   * The INTEGER type will display as a text field that only accepts numbers.
   */
  var INTEGER = "integer";

  /**
   * The FLOAT type will display as a text field that only accepts numbers.
   */
  var FLOAT = "float";

  /**
   * The BOOL type will display as a checkbox.
   */
  var BOOL = "bool";

  /**
   * The ENUM type will display as a dropdown.
   * Make sure to specify the `keys` field in the schema.
   */
  var ENUM = "enum";
}
