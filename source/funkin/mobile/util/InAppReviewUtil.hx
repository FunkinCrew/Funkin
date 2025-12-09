package funkin.mobile.util;

#if FEATURE_MOBILE_IAR
#if android
import extension.iarcore.android.IARAndroid as IAR;
#elseif ios
import extension.iarcore.ios.IARIOS as IAR;
#end
#end

/**
 * Provides utility functions for working with in-app reviews.
 * @see https://developer.android.com/guide/playcore/in-app-review
 */
@:nullSafety
class InAppReviewUtil
{
  /**
   * Chance for exiting the Results screen to display a prompt to review the game, as a percent.
   */
  public static var ODDS:UInt = 5;

  /**
   * Initializes callbacks tied to the In-App Review functionality.
   */
  public static function init():Void
  {
    #if FEATURE_MOBILE_IAR
    #if android
    trace('[IAR] Initializing callbacks...');

    IAR.onLog.add(function(message:String):Void {
      trace('[IAR] Error occurred: "$message"');
    });
    IAR.onReviewCompleted.add(function(success:Bool):Void {
      trace('[IAR] Review completed: "${success ? 'Success' : 'Failure'}"');
    });
    IAR.onReviewError.add(function(message:String):Void {
      trace('[IAR] Review failed: "$message"');
    });
    #end
    #else
    trace('[IAR] IAR is disabled...');
    #end
  }

  /**
   * When called, displays a card which prompts the user to provide a review of the game,
   * which will be posted to the respective app store.
   *
   * Google Play will throttle this for us t
   */
  public static function requestReview():Void
  {
    #if FEATURE_MOBILE_IAR
    trace('[IAR] Sending in-app review request...');
    #if android
    IAR.init();

    #if FEATURE_DEBUG_FUNCTIONS
    IAR.requestAndLaunchFakeReviewFlow();
    #else
    IAR.requestAndLaunchReviewFlow();
    #end
    #else
    IAR.requestReview();
    #end
    #else
    trace('[IAR] IAR is disabled...');
    #end
  }
}
