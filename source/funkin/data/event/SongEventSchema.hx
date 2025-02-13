package funkin.data.event;

@:forward(name, title, type, keys, min, max, step, units, defaultValue, iterator)
abstract SongEventSchema(SongEventSchemaRaw)
{
  /**
   * These units look better when placed immediately next to the value, rather than after a space.
   */
  static final NO_SPACE_UNITS:Array<String> = ['x', '°', '%'];

  public function new(?fields:Array<SongEventSchemaField>)
  {
    this = fields;
  }

  @:arrayAccess
  public function getByName(name:String):SongEventSchemaField
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

  public function stringifyFieldValue(name:String, value:Dynamic, addUnits:Bool = true):String
  {
    var field:SongEventSchemaField = getByName(name);
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

  function addUnitsToString(value:String, field:SongEventSchemaField)
  {
    if (field.units == null || field.units == '') return value;

    var unit:String = field.units;

    return value + (NO_SPACE_UNITS.contains(unit) ? '' : ' ') + '${unit}';
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
   * Used for INTEGER and FLOAT values.
   * The units that the value is expressed in (pixels, percent, etc).
   */
  ?units:String,

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
