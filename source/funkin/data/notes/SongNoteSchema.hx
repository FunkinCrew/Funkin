package funkin.data.notes;

@:forward(name, title, type, min, max, step, precision, keys, defaultValue, iterator)
abstract SongNoteSchema(SongNoteSchemaRaw)
{
  public function new(?fields:Array<SongNoteSchemaField>)
  {
    this = fields;
  }

  @:arrayAccess
  public function getByName(name:String):SongNoteSchemaField
  {
    for (field in this)
    {
      if (field.name == name) return field;
    }

    return null;
  }

  public function getFirstField():SongNoteSchemaField
  {
    return this[0];
  }

  @:arrayAccess
  public inline function get(index:Int):SongNoteSchemaField
  {
    return this[index];
  }

  @:arrayAccess
  public inline function set(index:Int, value:SongNoteSchemaField):SongNoteSchemaField
  {
    return this[index] = value;
  }

  public function stringifyFieldValue(name:String, value:Dynamic):String
  {
    var field:SongNoteSchemaField = getByName(name);
    if (field == null) return 'Unknown';

    switch (field.type)
    {
      case SongNoteFieldType.STRING:
        return Std.string(value);
      case SongNoteFieldType.INTEGER | SongNoteFieldType.FLOAT | SongNoteFieldType.BOOL:
        var returnValue:String = Std.string(value);
        return returnValue;
      case SongNoteFieldType.ENUM:
        var valueString:String = Std.string(value);
        for (key in field.keys.keys())
        {
          // Comparing these values as strings because comparing Dynamic variables is jank.
          if (Std.string(field.keys.get(key)) == valueString) return key;
        }
        return valueString;
      default:
        return 'Unknown';
    }
  }
}

typedef SongNoteSchemaRaw = Array<SongNoteSchemaField>;

typedef SongNoteSchemaField =
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
  type:SongNoteFieldType,

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
   * Used for INTEGER and FLOAT values.
   * The amount of decimal places.
   * @default `0`
   */
  ?precision:Int,

  /**
   * Used only for ENUM values.
   * The key is the display name and the value is the actual value.
   */
  ?keys:Map<String, Dynamic>,

  /**
   * An optional default value for the field.
   */
  ?defaultValue:Dynamic,
}

enum abstract SongNoteFieldType(String) from String to String
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
