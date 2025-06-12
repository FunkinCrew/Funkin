package funkin.mobile.util;

#if FEATURE_MOBILE_ADVERTISEMENTS
import extension.admob.Admob;
import extension.admob.AdmobBannerAlign;
import extension.admob.AdmobBannerSize;
import extension.admob.AdmobEvent;
import flixel.FlxG;
import funkin.play.cutscene.VideoCutscene;
import funkin.util.macro.EnvironmentConfigMacro;

/**
 * Provides utility functions for working with admob advertisements.
 */
@:nullSafety
class AdMobUtil
{
  /**
   * Counter that tracks the number of times a blueball event or a victory occurs.
   */
  public static var PLAYING_COUNTER:UInt = 0;

  /**
   * The maximum number of actions or events allowed before an advertisement is shown.
   */
  public static final MAX_BEFORE_AD:UInt = 3;

  #if NO_TESTING_ADS
  /**
   * AdMob publisher ID used for the application.
   */
  static final ADMOB_PUBLISHER:String = EnvironmentConfigMacro.environmentConfig.get("GLOBAL_ADMOB_PUBLISHER");

  /**
   * Test ad unit IDs for development and testing purposes.
   * These IDs are provided by Google AdMob for testing ads without incurring costs.
   * They should not be used in production applications.
   */
  /**
   * Ad unit ID for displaying banner ads.
   */
  static final BANNER_AD_UNIT_ID:String = #if mobile EnvironmentConfigMacro.environmentConfig.get(#if android "ANDROID_ADMOB_BANNER_ID" #else "IOS_ADMOB_BANNER_ID" #end) #else "" #end;

  /**
   * Ad unit ID for displaying interstitial ads.
   */
  static final INTERSTITIAL_AD_UNIT_ID:String = #if mobile EnvironmentConfigMacro.environmentConfig.get(#if android "ANDROID_ADMOB_INTERSTITIAL_ID" #else "IOS_ADMOB_INTERSTITIAL_ID" #end) #else "" #end;

  /**
   * Ad unit ID for displaying rewarded ads.
   */
  static final REWARDED_AD_UNIT_ID:String = "";
  #else

  /**
   * AdMob publisher ID used for the application.
   * This ID is a test publisher ID provided by Google AdMob.
   * Replace with your actual publisher ID for production.
   */
  static final ADMOB_PUBLISHER:String = "ca-app-pub-3940256099942544";

  /**
   * Ad unit ID for displaying banner ads.
   * Test IDs are used for Android and iOS platforms, while non-supported platforms default to an empty string.
   * Replace with your actual banner ad unit ID for production.
   *
   * - Android: "9214589741" (test ad unit ID)
   * - iOS: "2435281174" (test ad unit ID)
   */
  static final BANNER_AD_UNIT_ID:String = #if android "9214589741" #elseif ios "2435281174" #else "" #end;

  /**
   * Ad unit ID for displaying interstitial ads.
   * Test IDs are used for Android and iOS platforms, while non-supported platforms default to an empty string.
   * Replace with your actual interstitial ad unit ID for production.
   *
   * - Android: "1033173712" (test ad unit ID)
   * - iOS: "4411468910" (test ad unit ID)
   */
  static final INTERSTITIAL_AD_UNIT_ID:String = #if android "1033173712" #elseif ios "4411468910" #else "" #end;

  /**
   * Ad unit ID for displaying rewarded ads.
   * Test IDs are used for Android and iOS platforms, while non-supported platforms default to an empty string.
   * Replace with your actual interstitial video ad unit ID for production.
   *
   * - Android: "8691691433" (test ad unit ID)
   * - iOS: "5135589807" (test ad unit ID)
   */
  static final REWARDED_AD_UNIT_ID:String = #if android "8691691433" #elseif ios "5135589807" #else "" #end;
  #end

  /**
   * Initializes the AdMob SDK and sets up event listeners for interstitial and rewarded ads.
   *
   * The listeners display ads automatically when they are loaded.
   */
  public static function init():Void
  {
    Admob.onEvent.add(function(event:AdmobEvent):Void {
      #if ios
      if (event.name == AdmobEvent.AVM_WILL_PLAY_AUDIO)
      {
        if (FlxG.sound.music != null) FlxG.sound.music.pause();

        for (sound in FlxG.sound.list)
        {
          if (sound != null) sound.pause();
        }

        #if hxvlc
        @:privateAccess
        if (VideoCutscene.vid != null) VideoCutscene.vid.pause();
        #end
      }
      else if (event.name == AdmobEvent.AVM_DID_STOP_PLAYING_AUDIO)
      {
        if (FlxG.sound.music != null) FlxG.sound.music.resume();

        for (sound in FlxG.sound.list)
        {
          if (sound != null) sound.resume();
        }

        #if hxvlc
        @:privateAccess
        if (VideoCutscene.vid != null) VideoCutscene.vid.resume();
        #end
      }
      #end

      trace(event.toString());
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
    #if FEATURE_MOBILE_IAP
    if (InAppPurchasesUtil.isPurchased(InAppPurchasesUtil.UPGRADE_PRODUCT_ID)) return;
    #end
    Admob.showBanner([AdMobUtil.ADMOB_PUBLISHER, AdMobUtil.BANNER_AD_UNIT_ID].join('/'), size, align);
  }

  /**
   * Removes the currently displayed banner ad, if any.
   */
  public static inline function removeBanner():Void
  {
    #if FEATURE_MOBILE_IAP
    if (InAppPurchasesUtil.isPurchased(InAppPurchasesUtil.UPGRADE_PRODUCT_ID)) return;
    #end
    Admob.hideBanner();
  }

  /**
   * Loads an interstitial ad using AdMob.
   *
   * @param onInterstitialFinish Callback function to be called when the rewarded ad has been completed by the user.
   */
  public static function loadInterstitial(onInterstitialFinish:Void->Void):Void
  {
    #if FEATURE_MOBILE_IAP
    if (InAppPurchasesUtil.isPurchased(InAppPurchasesUtil.UPGRADE_PRODUCT_ID))
    {
      if (onInterstitialFinish != null) onInterstitialFinish();

      return;
    }
    #end

    function interstitialEvent(event:AdmobEvent):Void
    {
      if (event.name == AdmobEvent.INTERSTITIAL_LOADED)
      {
        Admob.showInterstitial();
      }
      else if (event.name == AdmobEvent.INTERSTITIAL_DISMISSED
        || event.name == AdmobEvent.INTERSTITIAL_FAILED_TO_LOAD
        || event.name == AdmobEvent.INTERSTITIAL_FAILED_TO_SHOW)
      {
        if (onInterstitialFinish != null) onInterstitialFinish();

        Admob.onEvent.remove(interstitialEvent);
      }
    }

    Admob.onEvent.add(interstitialEvent);

    Admob.loadInterstitial([AdMobUtil.ADMOB_PUBLISHER, AdMobUtil.INTERSTITIAL_AD_UNIT_ID].join('/'));
  }

  /**
   * Loads a rewarded ad using Admob.
   *
   * @param onRewardedFinish Callback function to be called when the rewarded ad has been completed by the user.
   */
  public static function loadRewarded(onRewardedFinish:Void->Void):Void
  {
    #if FEATURE_MOBILE_IAP
    if (InAppPurchasesUtil.isPurchased(InAppPurchasesUtil.UPGRADE_PRODUCT_ID))
    {
      if (onRewardedFinish != null) onRewardedFinish();

      return;
    }
    #end

    function rewardedEvent(event:AdmobEvent):Void
    {
      if (event.name == AdmobEvent.REWARDED_LOADED)
      {
        Admob.showRewarded();
      }
      else if (event.name == AdmobEvent.REWARDED_DISMISSED
        || event.name == AdmobEvent.REWARDED_FAILED_TO_LOAD
        || event.name == AdmobEvent.REWARDED_FAILED_TO_SHOW)
      {
        if (onRewardedFinish != null) onRewardedFinish();

        Admob.onEvent.remove(rewardedEvent);
      }
    }

    Admob.onEvent.add(rewardedEvent);

    Admob.loadRewarded([AdMobUtil.ADMOB_PUBLISHER, AdMobUtil.REWARDED_AD_UNIT_ID].join('/'));
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

  /**
   * Opens the Ad Inspector interface.
   * This method works for test devices registered programmatically or in the AdMob UI.
   */
  public static inline function openAdInspector():Void
  {
    Admob.openAdInspector();
  }
}
#end
