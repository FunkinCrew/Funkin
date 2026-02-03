package funkin.data.event;

@:nullSafety
@:forward(name, title, type, keys, min, max, step, units, defaultValue, iterator)
abstract SongEventSchema(SongEventSchemaRaw)
{
  /**
   * These units look better when placed immediately next to the value, rather than after a space.
   */
  static final NO_SPACE_UNITS:Array<String> = ['x', '°', '%'];

  public function new(?fields:Array<SongEventSchemaField>)
  {
    this = fields ?? [];
  }

  /**
   * Retrieve a SongEventSchemaField by name. This works even if the field is inside a Frame.
   * You can use array access to call this function; `schema["field_name"]`
   *
   * @param name The name of the field to retreive.
   * @return The retrieved field, or null if not found.
   */
  @:arrayAccess
  public function getByName(name:String):Null<SongEventSchemaField>
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
  public function getFirstField():Null<SongEventSchemaField>
  {
    return this[0];
  }

  /**
   * Retrieve a field from the schema by numeric index.
   * @param key The index of the field to retrieve.
   * @return The retrieved field.
   */
  @:arrayAccess
  public inline function get(key:Int):Null<SongEventSchemaField>
  {
    return this[key];
  }

  /**
   * Write a field to the schema by numeric index.
   * @param k The index of the field to write.
   * @param v The new field value to write.
   * @return The assigned value.
   */
  @:arrayAccess
  public inline function arrayWrite(k:Int, v:SongEventSchemaField):SongEventSchemaField
  {
    return this[k] = v;
  }

  /**
   * For a given song event field, retrieve its default value.
   * @param name The name of the field to retrieve.
   * @return The default value of the field, or null if not found.
   */
  public function getDefaultFieldValue(name:String):Null<Dynamic>
  {
    return getByName(name)?.defaultValue;
  }

  /**
   * For a given song event field, convert the value into a string.
   * This is particularly useful for ENUM fields.
   *
   * @param name The name of the field to display.
   * @param value The value of the field to convert.
   * @param addUnits Whether to add the units specified by the schema to the resulting string.
   * @return The resulting string.
   */
  public function stringifyFieldValue(name:String, value:Dynamic, addUnits:Bool = true):String
  {
    var field:Null<SongEventSchemaField> = getByName(name);
    if (field == null) return 'Unknown';

    switch (field.type)
    {
      case SongEventFieldType.STRING:
        return Std.string(value);
      case SongEventFieldType.INTEGER:
        var returnValue:String = Std.string(value);
        if (addUnits) return addUnitsToString(returnValue, field);
        return returnValue;
      case SongEventFieldType.FLOAT:
        var returnValue:String = Std.string(value);
        if (addUnits) return addUnitsToString(returnValue, field);
        return returnValue;
      case SongEventFieldType.BOOL:
        return Std.string(value);
      case SongEventFieldType.ENUM:
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
   * Apply the song event field's specified units to the value.
   * @param value The value to add the units to.
   * @param field The field to get the units from.
   * @return The resulting string.
   */
  function addUnitsToString(value:String, field:SongEventSchemaField):String
  {
    if (field.units == null || field.units == '') return value;

    var unit:String = field.units;

    return value + (NO_SPACE_UNITS.contains(unit) ? '' : ' ') + '${unit}';
  }

  /**
   * Build a flat list of all the fields in the schema. Frames containing children are parsed recursively.
   *
   * @param schema The song event schema schema to parse.
   * @return The array of fields, parsed recursively from the schema and its child frames.
   */
  function listAllFields(schema:SongEventSchemaRaw):Array<SongEventSchemaField>
  {
    var result:Array<SongEventSchemaField> = [];

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
    return listAllFields(this).map((field:SongEventSchemaField) -> field.name);
  }
}

/**
 * The raw underlying data for a song event schema is an array of fields.
 */
typedef SongEventSchemaRaw = Array<SongEventSchemaField>;

/**
 * The individual fields of a song event schema.
 */
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
   * Used for INTEGER and FLOAT values.
   * The units that the value is expressed in (pixels, percent, etc).
   */
  ?units:String,

  /**
   * Used for FRAME values.
   * The child components that this frame contains.
   */
  ?children:SongEventSchemaRaw,

  /**
   * Used for FRAME values.
   * Whether to make the frame be collapsible.
   */
  ?collapsible:Bool,

  /**
   * An optional default value for the field.
   */
  ?defaultValue:Dynamic,
}

/**
 * The available field types for a song event schema.
 */
enum abstract SongEventFieldType(String) from String to String
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
