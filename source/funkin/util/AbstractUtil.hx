package funkin.util;

import flixel.util.FlxSignal;

/**
 * Class for scripts to use to use various abstracts.
 * TODO: Remove this once Polymod supports instances of abstract classes.
 */
class AbstractUtil
{
  /**
   * Creates a new FlxSignal.
   */
  public static function createFlxSignal():FlxSignal
  {
    return new FlxSignal();
  }
}
