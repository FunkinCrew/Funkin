package funkin.mobile.util;

#if FEATURE_MOBILE_AGESIGNALS
import extension.agesignals.AgeSignals;
import extension.agesignals.AgeSignalsResult;

/**
 * Provides utility functions for working with `AgeSignals`.
 */
@:unreflective
class AgeSignalsUtil
{
  /**
   * The currrent result from `AgeSignals`
   */
  public static var result(default, null):Null<AgeSignalsResult> = null;

  /**
   * Initializes the AgeSignals.
   */
  public static function init():Void
  {
    AgeSignals.onCheckAgeSignalsSuccess.add(function(result:AgeSignalsResult):Void
    {
      AgeSignalsUtil.result = result;
    });

    AgeSignals.onCheckAgeSignalsError.add(function(error:String):Void
    {
      AgeSignalsUtil.result = null;
    });

    AgeSignals.init();

    AgeSignals.check([13]);
  }
}
#end
