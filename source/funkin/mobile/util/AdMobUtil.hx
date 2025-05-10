package funkin.mobile.util;

#if FEATURE_MOBILE_ADVERTISEMENTS
import extension.admob.Admob;
import extension.admob.AdmobBannerAlign;
import extension.admob.AdmobBannerSize;
import extension.admob.AdmobEvent;
import funkin.util.macro.EnvironmentConfigMacro;

/**
 * Utility class for managing AdMob advertisements in a mobile application.
 * This class provides functions to initialize AdMob, manage ad events,
 * and control the display of different ad types, including banners,
 * interstitial ads, and rewarded ads.
 */
class AdMobUtil
{
  #if NO_TESTING_ADS
  /**
   * AdMob publisher ID used for the application.
   */
  private static final ADMOB_PUBLISHER:String = EnvironmentConfigMacro.environmentConfig.get("GLOBAL_ADMOB_PUBLISHER");

  /**
   * Test ad unit IDs for development and testing purposes.
   * These IDs are provided by Google AdMob for testing ads without incurring costs.
   * They should not be used in production applications.
   */
  /**
   * Ad unit ID for displaying banner ads.
   */
  private static final BANNER_AD_UNIT_ID:String = #if mobile EnvironmentConfigMacro.environmentConfig.get(#if android "ANDROID_ADMOB_BANNER_ID" #else "IOS_ADMOB_BANNER_ID" #end) #else "" #end;

  /**
   * Ad unit ID for displaying interstitial ads.
   */
  private static final INTERSTITIAL_AD_UNIT_ID:String = #if mobile EnvironmentConfigMacro.environmentConfig.get(#if android "ANDROID_ADMOB_INTERSTITIAL_ID" #else "IOS_ADMOB_INTERSTITIAL_ID" #end) #else "" #end;

  /**
   * Ad unit ID for displaying interstitial video ads.
   */
  private static final INTERSTITIAL_VIDEO_AD_UNIT_ID:String = "";
  #else

  /**
   * AdMob publisher ID used for the application.
   * This ID is a test publisher ID provided by Google AdMob.
   * Replace with your actual publisher ID for production.
   */
  private static final ADMOB_PUBLISHER:String = "ca-app-pub-3940256099942544";

  /**
   * Ad unit ID for displaying banner ads.
   * Test IDs are used for Android and iOS platforms, while non-supported platforms default to an empty string.
   * Replace with your actual banner ad unit ID for production.
   *
   * - Android: "6300978111" (test ad unit ID)
   * - iOS: "2934735716" (test ad unit ID)
   */
  private static final BANNER_AD_UNIT_ID:String = #if android "6300978111" #elseif ios "2934735716" #else "" #end;

  /**
   * Ad unit ID for displaying interstitial ads.
   * Test IDs are used for Android and iOS platforms, while non-supported platforms default to an empty string.
   * Replace with your actual interstitial ad unit ID for production.
   *
   * - Android: "1033173712" (test ad unit ID)
   * - iOS: "4411468910" (test ad unit ID)
   */
  private static final INTERSTITIAL_AD_UNIT_ID:String = #if android "1033173712" #elseif ios "4411468910" #else "" #end;

  /**
   * Ad unit ID for displaying interstitial video ads.
   * Test IDs are used for Android and iOS platforms, while non-supported platforms default to an empty string.
   * Replace with your actual interstitial video ad unit ID for production.
   *
   * - Android: "8691691433" (test ad unit ID)
   * - iOS: "5135589807" (test ad unit ID)
   */
  private static final INTERSTITIAL_VIDEO_AD_UNIT_ID:String = #if android "8691691433" #elseif ios "5135589807" #else "" #end;
  #end

  /**
   * Initializes the AdMob SDK and sets up event listeners for interstitial and rewarded ads.
   *
   * The listeners display ads automatically when they are loaded.
   */
  public static function init():Void
  {
    Admob.onEvent.add(function(event:String, message:String):Void {
      switch (event)
      {
        case AdmobEvent.INTERSTITIAL_LOADED:
          Admob.showInterstitial();
      }

      logMessage(message.length > 0 ? '$event:$message' : event);
    });

    Admob.configureConsentMetadata(Admob.getTCFConsentForPurpose(0) == 1, StringTools.startsWith(Admob.getUSPrivacy(), '1Y'));

    Admob.init(#if TESTING_ADS true #else false #end);
  }

  /**
   * Adds a banner ad at the specified size and alignment.
   * @param size The size of the banner ad, defaulting to the standard banner size.
   * @param align The alignment of the banner ad, defaulting to the bottom of the screen.
   */
  public static inline function addBanner(size:Int = AdmobBannerSize.BANNER, align:Int = AdmobBannerAlign.BOTTOM_CENTER):Void
  {
    Admob.showBanner([AdMobUtil.ADMOB_PUBLISHER, AdMobUtil.BANNER_AD_UNIT_ID].join('/'), size, align);
  }

  /**
   * Removes the currently displayed banner ad, if any.
   */
  public static inline function removeBanner():Void
  {
    Admob.hideBanner();
  }

  /**
   * Loads an interstitial ad. It loads either a video (if avalible) or a standard interstitial ad (it uses a 50% chance to decide that).
   */
  public static inline function loadInterstitial():Void
  {
    if (FlxG.random.bool(50) && AdMobUtil.INTERSTITIAL_VIDEO_AD_UNIT_ID.length > 0)
    {
      Admob.loadInterstitial([AdMobUtil.ADMOB_PUBLISHER, AdMobUtil.INTERSTITIAL_VIDEO_AD_UNIT_ID].join('/'));
    }
    else
    {
      Admob.loadInterstitial([AdMobUtil.ADMOB_PUBLISHER, AdMobUtil.INTERSTITIAL_AD_UNIT_ID].join('/'));
    }
  }

  /**
   * Sets the volume level for ads with sound, allowing control over ad audio playback.
   * @param volume A Float representing the desired volume (0 = mute, 1 = full volume).
   */
  public static inline function setVolume(volume:Float):Void
  {
    Admob.setVolume(volume);
  }

  /**
   * Checks whether consent for a specific advertising purpose has been granted.
   * @param purpose The purpose for which consent is required.
   * @return An Int indicating consent status (-1 for no consent, 1 for granted).
   */
  public static inline function getTCFConsentForPurpose(purpose:Int):Int
  {
    return Admob.getTCFConsentForPurpose(purpose);
  }

  /**
   * Checks if the user has given consent for all ad purposes.
   * This is typically required for GDPR compliance, where each purpose (0-9) needs to be individually consented.
   * @return Bool indicating whether the user has consented to all purposes.
   */
  public static function hasFullTCFConsent():Bool
  {
    for (purpose in 0...Admob.getTCFPurposeConsent().length)
    {
      if (Admob.getTCFConsentForPurpose(purpose) != 1) return false;
    }

    return true;
  }

  /**
   * Retrieves the current user's consent status as a string.
   * Useful for GDPR compliance to understand if ads can be personalized.
   * @return A String with the consent status.
   */
  public static inline function getTCFPurposeConsent():String
  {
    return Admob.getTCFPurposeConsent();
  }

  /**
   * Determines if showing a privacy options form is required based on regional laws.
   * @return A Bool indicating if a privacy options form is required (true if required, false if not required).
   */
  public static inline function isPrivacyOptionsRequired():Bool
  {
    return Admob.isPrivacyOptionsRequired();
  }

  /**
   * Displays the privacy options form to the user, allowing them to adjust consent.
   * Useful for GDPR and other privacy regulations compliance.
   */
  public static inline function showPrivacyOptionsForm():Void
  {
    Admob.showPrivacyOptionsForm();
  }

  @:noCompletion
  private static function logMessage(message:String):Void
  {
    #if android
    extension.androidtools.widget.Toast.makeText(message, extension.androidtools.widget.Toast.LENGTH_SHORT);
    #end

    Sys.println(message);
  }
}
#end
