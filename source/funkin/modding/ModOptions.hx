package funkin.modding;

import haxe.ds.StringMap;
import funkin.save.Save;
import funkin.util.SortUtil;

/**
 * The params for a mod option.
 */
typedef ModOptionParams =
{
  type:ModOptionType,
  name:String,
  desc:String,

  // Checkbox
  ?available:Bool,

  // Number
  ?min:Float,
  ?max:Float,
  ?step:Float,
  ?precision:Int,
  ?valueFormatter:Float->String,

  // Enum
  ?values:Map<String, EnumValue>,

  onChange:Dynamic
}

/**
 * An enum of all the different mod option types.
 */
enum ModOptionType
{
  CHECKBOX;
  NUMBER;
  PERCENTAGE;
  ENUM;
}

/**
 * A class for allowing mods to easily make their own custom options, or preferences.
 */
class ModOptions
{
  /**
   * All registered mod options.
   */
  public static final options:StringMap<Dynamic> = new StringMap<Dynamic>();

  /**
   * Registers a checkbox mod option under `id`.
   * If a mod option under `id` already exists, that option will be replaced.
   * @param id The unique id for the option.
   * @param defaultValue The default value for when the option had never been saved.
   * @param onChange Gets called when the option gets its value changed.
   * @return The option's data.
   */
  public static function registerCheckbox(id:String, name:String, desc:String, defaultValue:Bool, available:Bool = true, ?onChange:Bool->Void):ModOptionParams
  {
    remove(id);

    if (!(getValue(id) is Bool)) setValue(id, defaultValue);

    var data:ModOptionParams =
      {
        type: ModOptionType.CHECKBOX,
        name: name,
        desc: desc,
        available: available,
        onChange: function(value:Bool):Void {
          if (onChange != null) onChange(value);
          setValue(id, value, true);
        }
      }

    options.set(id, data);

    return data;
  }

  /**
   * Registers a number mod option under `id`.
   * If a mod option under `id` already exists, that option will be replaced.
   * @param id The unique id for the option.
   * @param defaultValue The default value for when the option had never been saved.
   * @param min The minimum value.
   * @param max The maximum value.
   * @param step How much the value gets incremented/decremented.
   * @param precision The amount of digits to round up to.
   * @param valueFormatter Gets called every time the game needs to display the float value; use this to change how the displayed value looks.
   * @param onChange Gets called when the option gets its value changed.
   * @return The option's data.
   */
  public static function registerNumber(id:String, name:String, desc:String, defaultValue:Float, min:Float, max:Float, step:Float, precision:Int,
      ?valueFormatter:Float->String, ?onChange:Float->Void):ModOptionParams
  {
    remove(id);

    if (!(getValue(id) is Float)) setValue(id, defaultValue);

    var data:ModOptionParams =
      {
        type: ModOptionType.NUMBER,
        name: name,
        desc: desc,
        min: min,
        max: max,
        step: step,
        precision: precision,
        valueFormatter: valueFormatter,
        onChange: function(value:Float):Void {
          if (onChange != null) onChange(value);
          setValue(id, value, true);
        }
      }

    options.set(id, data);

    return data;
  }

  /**
   * Registers a percentage mod option under `id`.
   * If a mod option under `id` already exists, that option will be replaced.
   * @param id The unique id for the option.
   * @param defaultValue The default value for when the option had never been saved.
   * @param min The minimum value.
   * @param max The maximum value.
   * @param onChange Gets called when the option gets its value changed.
   * @return The option's data.
   */
  public static function registerPercentage(id:String, name:String, desc:String, defaultValue:Int, min:Int, max:Int, ?onChange:Int->Void):ModOptionParams
  {
    remove(id);

    if (!(getValue(id) is Int)) setValue(id, defaultValue);

    var data:ModOptionParams =
      {
        type: ModOptionType.PERCENTAGE,
        name: name,
        desc: desc,
        min: min,
        max: max,
        onChange: function(value:Int):Void {
          if (onChange != null) onChange(value);
          setValue(id, value, true);
        }
      }

    options.set(id, data);

    return data;
  }

  /**
   * Registers an enum mod option under `id`.
   * If a mod option under `id` already exists, that option will be replaced.
   * @param id The unique id for the option.
   * @param defaultValue The default value for when the option had never been saved.
   * @param values Maps enum values to display strings.
   * @param onChange Gets called when the option gets its value changed.
   * @return The option's data.
   */
  public static function registerEnum(id:String, name:String, desc:String, defaultValue:String, values:Map<String, EnumValue>,
      ?onChange:String->EnumValue->Void):ModOptionParams
  {
    remove(id);

    if (!(getValue(id) is String)) setValue(id, defaultValue);

    var data:ModOptionParams =
      {
        type: ModOptionType.ENUM,
        name: name,
        desc: desc,
        values: values,
        onChange: function(key:String, value:EnumValue):Void {
          if (onChange != null) onChange(key, value);
          setValue(id, key, true);
        }
      }

    options.set(id, data);

    return data;
  }

  /**
   * A helper function for retrieving a mod option.
   * @param id The unique id for the option.
   * @return The option's data.
   */
  public static function get(id:String):ModOptionParams
  {
    return options.get(id);
  }

  /**
   * A helper function for retrieving the value of a mod option.
   * @param id The unique id for the option.
   * @return The value of the option.
   */
  public static function getValue(id:String):Dynamic
  {
    return Save.instance.modOptions.get(id);
  }

  /**
   * A helper function for setting the value of a mod option.
   * @param id The unique id for the option.
   * @param value The value to set the option to.
   * @param flush Whether to force the value to be saved into disk.
   */
  public static function setValue(id:String, value:Dynamic, flush:Bool = false):Void
  {
    Save.instance.modOptions.set(id, value);
    if (flush) Save.instance.flush();
  }

  /**
   * A helper function for getting a list of all registered mod options.
   * @return A list of all the mod options sorted alphabetically.
   */
  public static function list():Array<String>
  {
    var list:Array<String> = options.keys().array();
    list.sort(SortUtil.alphabetically);
    return list;
  }

  /**
   * A helper function for removing a mod option.
   * @param id The unique id for the option.
   */
  public static function remove(id:String):Void
  {
    options.remove(id);
  }

  /**
   * A helper function for clearing all mod options.
   */
  public static function clear():Void
  {
    options.clear();
  }
}
