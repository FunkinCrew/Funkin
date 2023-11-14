package funkin.util;

/**
 * Utilities for performing operations on dates.
 */
class DateUtil
{
  public static function generateTimestamp(?date:Date = null):String
  {
    if (date == null) date = Date.now();

    return
      '${date.getFullYear()}-${Std.string(date.getMonth() + 1).lpad('0', 2)}-${Std.string(date.getDate()).lpad('0', 2)}-${Std.string(date.getHours()).lpad('0', 2)}-${Std.string(date.getMinutes()).lpad('0', 2)}-${Std.string(date.getSeconds()).lpad('0', 2)}';
  }
}
