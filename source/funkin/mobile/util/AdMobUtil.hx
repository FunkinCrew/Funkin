package funkin.mobile.util;

#if FEATURE_MOBILE_ADVERTISEMENTS
import extension.admob.Admob;
import extension.admob.AdmobBannerAlign;
import extension.admob.AdmobBannerSize;
import extension.admob.AdmobEvent;
import flixel.FlxG;
import funkin.play.cutscene.VideoCutscene;

/**
 * Provides utility functions for working with admob advertisements.
 */
@:build(funkin.util.macro.EnvironmentMacro.build())
@:nullSafety
class AdMobUtil
{
  /**
   * The maximum number of actions or events allowed before an advertisement is shown.
   */
  public static final MAX_BEFORE_AD:UInt = 3;

  /**
   * Counter that tracks the number of times a blueball event or a victory occurs.
   */
  public static var PLAYING_COUNTER:UInt = 0;

  /**
   * The AdMob Interstitial Preload ID used for loading interstitial ads.
   */
  static final ADMOB_INTERSTITIAL_PRELOAD_ID:String = "FNF_INTERSTITIAL_PRELOAD_ID";

  /**
   * The number of interstitial ads to preload and keep in buffer for AdMob.
   */
  static final ADMOB_INTERSTITIAL_PRELOAD_BUFFER_SIZE:Int = 5;

  /**
   * AdMob publisher ID used for the application.
   */
  #if NO_TESTING_ADS
  @:envField({mandatoryIfDefined: "FEATURE_MOBILE_ADVERTISEMENTS"})
  static final ADMOB_PUBLISHER:Null<String>;
  #else
  static final ADMOB_PUBLISHER:Null<String> = "ca-app-pub-3940256099942544";
  #end

  /**
   * Ad unit ID for displaying banner ads.
   */
  #if NO_TESTING_ADS
  @:envField({mandatoryIfDefined: "FEATURE_MOBILE_ADVERTISEMENTS"})
  static final ADMOB_BANNER_AD_UNIT_ID:Null<String>;
  #else
  static final ADMOB_BANNER_AD_UNIT_ID:Null<String> = #if android "9214589741" #elseif ios "2435281174" #else null #end;
  #end

  /**
   * Ad unit ID for displaying interstitial ads.
   */
  #if NO_TESTING_ADS
  @:envField({mandatoryIfDefined: "FEATURE_MOBILE_ADVERTISEMENTS"})
  static final ADMOB_INTERSTITIAL_AD_UNIT_ID:Null<String>;
  #else
  static final ADMOB_INTERSTITIAL_AD_UNIT_ID:Null<String> = #if android "1033173712" #elseif ios "4411468910" #else null #end;
  #end

  /**
   * Initializes the AdMob SDK and sets up event listeners for interstitial and rewarded ads.
   *
   * The listeners display ads automatically when they are loaded.
   */
  public static function init():Void
  {
    Admob.onEvent.add(function(event:AdmobEvent):Void {
      if (event.name == AdmobEvent.INIT_OK)
      {
        if (AdMobUtil.ADMOB_PUBLISHER != null && AdMobUtil.ADMOB_INTERSTITIAL_AD_UNIT_ID != null)
        {
          final adUnitID:String = [AdMobUtil.ADMOB_PUBLISHER, AdMobUtil.ADMOB_INTERSTITIAL_AD_UNIT_ID].join('/');

          Admob.startInterstitialPreloader(AdMobUtil.ADMOB_INTERSTITIAL_PRELOAD_ID, adUnitID, AdMobUtil.ADMOB_INTERSTITIAL_PRELOAD_BUFFER_SIZE);
        }
      }
      #if ios
      else if (event.name == AdmobEvent.AVM_WILL_PLAY_AUDIO)
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

      Sys.println(event.toString());
    });

    Admob.configureUnity(Admob.getTCFConsentForPurpose(0) == 1, StringTools.startsWith(Admob.getUSPrivacy(), '1Y'));

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
    if (InAppPurchasesUtil.isPurchased(InAppPurchasesUtil.UPGRADE_PRODUCT_ID))
    {
      return;
    }
    #end

    if (AdMobUtil.ADMOB_PUBLISHER != null && AdMobUtil.ADMOB_BANNER_AD_UNIT_ID != null)
    {
      Admob.showBanner([AdMobUtil.ADMOB_PUBLISHER, AdMobUtil.ADMOB_BANNER_AD_UNIT_ID].join('/'), size, align);
    }
  }

  /**
   * Removes the currently displayed banner ad, if any.
   */
  public static inline function removeBanner():Void
  {
    #if FEATURE_MOBILE_IAP
    if (InAppPurchasesUtil.isPurchased(InAppPurchasesUtil.UPGRADE_PRODUCT_ID))
    {
      return;
    }
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
      if (onInterstitialFinish != null)
      {
        onInterstitialFinish();
      }

      return;
    }
    #end

    if (AdMobUtil.ADMOB_PUBLISHER != null && AdMobUtil.ADMOB_INTERSTITIAL_AD_UNIT_ID != null)
    {
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
          if (onInterstitialFinish != null)
          {
            onInterstitialFinish();
          }

          Admob.onEvent.remove(interstitialEvent);
        }
      }

      Admob.onEvent.add(interstitialEvent);

      if (Admob.isInterstitialAdAvailable(AdMobUtil.ADMOB_INTERSTITIAL_PRELOAD_ID))
      {
        Admob.loadInterstitialFromPreloader(AdMobUtil.ADMOB_INTERSTITIAL_PRELOAD_ID);
      }
      else
      {
        Admob.loadInterstitial([AdMobUtil.ADMOB_PUBLISHER, AdMobUtil.ADMOB_INTERSTITIAL_AD_UNIT_ID].join('/'));
      }
    }
    else
    {
      if (onInterstitialFinish != null)
      {
        onInterstitialFinish();
      }
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
