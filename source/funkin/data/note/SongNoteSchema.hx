package funkin.data.note;

@:forward(name, title, type, min, max, step, precision, keys, defaultValue, iterator)
abstract SongNoteSchema(SongNoteSchemaRaw)
{
  public function new(?fields:Array<SongNoteSchemaField>)
  {
    this = fields;
  }

  /**
   * Retrieve a SongNoteSchemaField by name. This works even if the field is inside a Frame.
   * You can use array access to call this function; `schema["field_name"]`
   *
   * @param name The name of the field to retreive.
   * @return The retrieved field, or null if not found.
   */
  @:arrayAccess
  public function getByName(name:String):SongNoteSchemaField
  {
    var allFields = listAllFields(this);

    for (field in allFields)
    {
      if (field.name == name) return field;
    }

    return null;
  }

  /**
   * Return whether the field with the given name exists.
   * @param name The name of the field to check.
   * @return Whether the field exists.
   */
  public function hasField(name:String):Bool
  {
    return abstract.getByName(name) != null;
  }

  /**
   * Retrieve the first field in the schema.
   * @return The first field.
   */
  public function getFirstField():SongNoteSchemaField
  {
    return this[0];
  }

  /**
   * Retrieve a field from the schema by numeric index.
   * @param key The index of the field to retrieve.
   * @return The retrieved field.
   */
  @:arrayAccess
  public inline function get(index:Int):SongNoteSchemaField
  {
    return this[index];
  }

  /**
   * Write a field to the schema by numeric index.
   * @param k The index of the field to write.
   * @param v The new field value to write.
   * @return The assigned value.
   */
  @:arrayAccess
  public inline function set(index:Int, value:SongNoteSchemaField):SongNoteSchemaField
  {
    return this[index] = value;
  }

  /**
   * For a given note kind field, retrieve its default value.
   * @param name The name of the field to retrieve.
   * @return The default value of the field, or null if not found.
   */
  public function getDefaultFieldValue(name:String):Null<Dynamic>
  {
    return getByName(name)?.defaultValue;
  }

  /**
   * For a given note kind field, convert the value into a string.
   * This is particularly useful for ENUM fields.
   *
   * @param name The name of the field to display.
   * @param value The value of the field to convert.
   * @return The resulting string.
   */
  public function stringifyFieldValue(name:String, value:Dynamic):String
  {
    var field:SongNoteSchemaField = getByName(name);
    if (field == null) return 'Unknown';

    switch (field.type)
    {
      case SongNoteFieldType.STRING | SongNoteFieldType.INTEGER | SongNoteFieldType.FLOAT | SongNoteFieldType.BOOL:
        return Std.string(value);
      case SongNoteFieldType.ENUM:
        var valueString:String = Std.string(value);
        var fieldKeys:Array<String> = field.keys?.keyValues() ?? [];
        for (key in fieldKeys)
        {
          var value:Null<Dynamic> = field.keys?.get(key) ?? null;
          // Comparing these values as strings because comparing Dynamic variables is jank.
          if (Std.string(value) == valueString) return key;
        }
        return valueString;
      default:
        return 'Unknown';
    }
  }

  /**
   * Build a flat list of all the fields in the schema. Frames containing children are parsed recursively.
   *
   * @param schema The song note schema schema to parse.
   * @return The array of fields, parsed recursively from the schema and its child frames.
   */
  function listAllFields(schema:SongNoteSchemaRaw):Array<SongNoteSchemaField>
  {
    var result:Array<SongNoteSchemaField> = [];

    for (field in schema)
    {
      if (field.children == null)
      {
        result.push(field);
      }
      else
      {
        result = result.concat(field.children);
      }
    }

    return result;
  }

  /**
   * Get a list of all the field names in the schema, so they can be iterated over and retrieved.
   * @return The list of field names.
   */
  public function listAllFieldNames():Array<String>
  {
    return listAllFields(this).map((field:SongNoteSchemaField) -> field.name);
  }
}

typedef SongNoteSchemaRaw = Array<SongNoteSchemaField>;

typedef SongNoteSchemaField =
{
  /**
   * The name of the property as it should be saved in the note params.
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
   * Used for INTEGER and FLOAT values.
   * The units that the value is expressed in (pixels, percent, etc).
   */
  ?units:String,
  /**
   * Used for FRAME values.
   * The child components that this frame contains.
   */
  ?children:SongNoteSchemaRaw,
  /**
   * Used for FRAME values.
   * Whether to make the frame be collapsible.
   */
  ?collapsible:Bool,
  /**
   * An optional default value for the field.
   */
  ?defaultValue:Dynamic
}

enum abstract SongNoteFieldType(String) from String to String
{
  /**
   * The STRING type will display as a text field.
   */
  public var STRING = "string";

  /**
   * The INTEGER type will display as a text field that only accepts numbers.
   */
  public var INTEGER = "integer";

  /**
   * The FLOAT type will display as a text field that only accepts numbers.
   */
  public var FLOAT = "float";

  /**
   * The BOOL type will display as a checkbox.
   */
  public var BOOL = "bool";

  /**
   * The ENUM type will display as a dropdown.
   * Make sure to specify the `keys` field in the schema.
   */
  public var ENUM = "enum";

  /**
   * The FRAME type will display a frame with child components.
   * Make sure to specify the `children` field in the schema.
   */
  public var FRAME = "frame";
}
