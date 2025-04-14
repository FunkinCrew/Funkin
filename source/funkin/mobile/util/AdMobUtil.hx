package funkin.mobile.util;

import admob.Admob;
import admob.AdmobBannerAlign;
import admob.AdmobBannerSize;
import admob.AdmobEvent;

/**
 * Utility class for managing AdMob advertisements in a mobile application.
 * This class provides functions to initialize AdMob, manage ad events,
 * and control the display of different ad types, including banners,
 * interstitial ads, and rewarded ads.
 */
class AdMobUtil
{
  /**
   * Production ad unit IDs (to be set for actual ad campaigns).
   */
  #if !TESTING_ADS
  private static final BANNER_AD_UNIT_ID:String = #if android "" #elseif ios "" #else "" #end;
  private static final INTERSTITIAL_AD_UNIT_ID:String = #if android "" #elseif ios "" #else "" #end;
  private static final INTERSTITIAL_VIDEO_AD_UNIT_ID:String = "";
  private static final REWARDED_AD_UNIT_ID:String = "";

  #else
  /**
   * Test ad unit IDs for development and testing purposes.
   * These IDs are provided by Google AdMob for testing ads without incurring costs.
   * They should not be used in production applications.
   */
  /**
   * Test ad unit ID for banner ads, used during development.
   */
  private static final BANNER_AD_UNIT_ID:String = #if android "ca-app-pub-3940256099942544/6300978111" #elseif ios "ca-app-pub-3940256099942544/2934735716" #else "" #end;

  /**
   * Test ad unit ID for interstitial ads, used during development.
   */
  private static final INTERSTITIAL_AD_UNIT_ID:String = #if android "ca-app-pub-3940256099942544/1033173712" #elseif ios "ca-app-pub-3940256099942544/4411468910" #else "" #end;

  /**
   * Test ad unit ID for interstitial video ads, used during development.
   */
  private static final INTERSTITIAL_VIDEO_AD_UNIT_ID:String = #if android "ca-app-pub-3940256099942544/8691691433" #elseif ios "ca-app-pub-3940256099942544/5135589807" #else "" #end;

  /**
   * Test ad unit ID for rewarded ads, used during development.
   */
  private static final REWARDED_AD_UNIT_ID:String = #if android "ca-app-pub-3940256099942544/5224354917" #elseif ios "ca-app-pub-3940256099942544/1712485313" #else "" #end;
  #end

  /**
   * Initializes the AdMob SDK and sets up event listeners for interstitial and rewarded ads.
   * The listeners display ads automatically when they are loaded.
   */
  public static inline function init():Void
  {
    Admob.onStatus.add(function(event:String, message:String):Void {
      switch (event)
      {
        case AdmobEvent.INTERSTITIAL_LOADED:
          Admob.showInterstitial();
        case AdmobEvent.REWARDED_LOADED:
          Admob.showRewarded();
      }

      #if android
      android.widget.Toast.makeText(message.length > 0 ? '$event:$message' : event, android.widget.Toast.LENGTH_SHORT);
      #else
      lime.utils.Log.info(message.length > 0 ? '$event:$message' : event);
      #end
    });

    Admob.init(#if TESTING_ADS true #else false #end);
  }

  /**
   * Loads an interstitial ad. Depending on the forceVideo parameter or random selection,
   * it loads either a video or a standard interstitial ad.
   * @param forceVideo If true, forces loading an interstitial video ad. Otherwise, it uses a 50% chance.
   */
  public static inline function loadInterstitial():Void
  {
    Admob.loadInterstitial(#if TESTING_ADS FlxG.random.bool(50) ? AdMobUtil.INTERSTITIAL_VIDEO_AD_UNIT_ID : #end AdMobUtil.INTERSTITIAL_AD_UNIT_ID);
  }

  /**
   * Adds a banner ad at the specified size and alignment.
   * @param size The size of the banner ad, defaulting to the standard banner size.
   * @param align The alignment of the banner ad, defaulting to the bottom of the screen.
   */
  public static inline function addBanner(size:Int = AdmobBannerSize.BANNER, align:Int = AdmobBannerAlign.BOTTOM):Void
  {
    Admob.showBanner(AdMobUtil.BANNER_AD_UNIT_ID, size, align);
  }

  /**
   * Removes the currently displayed banner ad, if any.
   */
  public static inline function removeBanner():Void
  {
    Admob.hideBanner();
  }

  /**
   * Loads a rewarded ad, preparing it to be displayed once loaded.
   * Rewarded ads typically grant rewards upon user completion, like game items or bonuses.
   */
  public static inline function loadRewarded():Void
  {
    Admob.loadRewarded(AdMobUtil.REWARDED_AD_UNIT_ID);
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
  public static inline function hasConsentForPurpose(purpose:Int):Int
  {
    return Admob.hasConsentForPurpose(purpose);
  }

  /**
   * Checks if the user has given consent for all ad purposes.
   * This is typically required for GDPR compliance, where each purpose (0-9) needs to be individually consented.
   * @return Bool indicating whether the user has consented to all purposes.
   */
  public static function hasFullConsent():Bool
  {
    for (purpose in 0...10)
    {
      if (Admob.hasConsentForPurpose(purpose) != 1) return false;
    }

    return true;
  }

  /**
   * Retrieves the current user's consent status as a string.
   * Useful for GDPR compliance to understand if ads can be personalized.
   * @return A String with the consent status.
   */
  public static inline function getConsent():String
  {
    return Admob.getConsent();
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
}
