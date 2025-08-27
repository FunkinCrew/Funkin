package funkin;

#if mobile
import funkin.mobile.ui.FunkinHitbox;
import funkin.mobile.util.InAppPurchasesUtil;
#end
import funkin.save.Save;
import funkin.util.WindowUtil;
import funkin.util.HapticUtil.HapticsMode;
import haxe.ds.Either;

typedef PreferenceData =
{
  var name:String;
  var desc:String;
  var saveId:String;

  @:jcustomparse(funkin.data.DataParse.dynamicValue)
  @:jcustomwrite(funkin.data.DataWrite.dynamicValue)
  var defaultValue:Dynamic;

  var type:String; // checkbox, number, percent, enum

  // number / percent
  @:optional
  @:default(0)
  var min:Float;

  @:optional
  @:default(100)
  var max:Float;

  // percent
  @:optional
  @:default(1)
  var step:Float;

  @:optional
  @:default(1)
  var precision:Int;

  // enum
  @:optional
  @:default([])
  var options:Map<String, String>;

  @:optional
  @:default("")
  var script:String;
}

typedef EnumPreferenceData =
{
  var key:String;
  var value:Dynamic;
}

@:hscriptClass
class ScriptedPreference extends Preference implements polymod.hscript.HScriptedClass {}

class Preference
{
  // public var data:PreferenceData;
  public var name:String;
  public var desc:String;

  public var defaultValue:Dynamic;

  // number
  // Can be set up via script.
  public var valueFormatter:Float->String = null;

  // number / precent
  // Using Dynamic cuz Either doesnt work 🙄
  public var min:Dynamic;
  public var max:Dynamic;

  public var step:Float;
  public var precision:Int;

  public var options:Map<String, String>;

  public var type:String;

  public var saveId:String;

  public var isMod:Bool;

  public function new(data:PreferenceData, ?modded:Bool)
  {
    name = data.name;
    desc = data.desc;

    defaultValue = data.defaultValue;

    min = data.min;
    max = data.max;
    step = data.step;
    precision = data.precision;

    options = data.options;

    type = data.type;
    saveId = data.saveId;

    isMod = modded;
  }

  // Override this function with your script.
  public function allowThisPreference():Bool
  {
    return true;
  }

  // Override this function with your script.
  public function isAvailable():Bool
  {
    return true;
  }

  public function loadDefaultValue()
  {
    if ((!isMod ? Save.instance.preferences : Save.instance.modOptions)[saveId] == null) updatePreference(defaultValue);
  }

  public function updatePreference(newVal:Dynamic)
  {
    final saveInstance = !isMod ? Save.instance.preferences : Save.instance.modOptions;
    saveInstance[saveId] = newVal;
    Save.instance.flush();

    return saveInstance[saveId];
  }

  /**
   * Returns value of current pref.
   */
  public function getValue()
  {
    if (!allowThisPreference()) return defaultValue;

    final saveInstance = !isMod ? Save.instance.preferences : Save.instance.modOptions;
    if (saveInstance[saveId] == null)
    {
      saveInstance[saveId] = defaultValue;
      Save.instance.flush();
    }

    return saveInstance[saveId];
  }

  public function getEnumKeyFromValue():String
  {
    var key:String = defaultValue;
    final currentValue = getValue();
    if (defaultValue != currentValue) for (mKey => mValue in options)
      if (mValue == currentValue) return mKey;

    return key;
  }

  public function onInit() {}

  public function toString():String
    return 'Preference(saveId: $saveId)';
}

/**
 * A core class which provides a store of user-configurable, globally relevant values.
 */
@:nullSafety
class Preferences
{
  public static var defaultPreferencesIds:Array<String> = [];

  public static var loadedPreferencesArrayIds:Array<String> = [];
  public static var loadedPreferences:Map<String, Preference> = [];

  public static function loadPreferences(?loadIds:Bool):Void
  {
    if (loadIds == null) loadIds = false;
    final prefDataPath:String = Paths.json('preferences');
    final prefData:String = Assets.getText(prefDataPath);

    var parsedData:Array<PreferenceData>;
    var parser = new json2object.JsonParser<Array<PreferenceData>>();
    parser.ignoreUnknownVariables = false;
    trace('[PREFERENCES] Parsing preferences data...');
    parser.fromJson(prefData, prefDataPath);

    if (parser.errors.length > 0)
    {
      trace('[PREFERENCES] Failed to parse preferences data!');
      for (error in parser.errors)
        funkin.data.DataError.printError(error);
      parsedData = [];
    }
    else
      parsedData = parser.value;

    if (loadIds)
    {
      if (loadIds) for (prefData in parsedData)
        defaultPreferencesIds.push(prefData.saveId);
    }
    else
    {
      if (parsedData.length < defaultPreferencesIds.length) trace('WARNING: After-Modded preferences length is LESS than default.');

      var _scriptName:Null<String> = null;
      final scriptedClassesList:Array<String> = ScriptedPreference.listScriptClasses();
      for (prefData in parsedData)
      {
        _scriptName = (prefData?.script ?? "").trim();
        var preferenceItem:Null<Preference> = (_scriptName != ""
          && scriptedClassesList.contains(_scriptName)) ? (ScriptedPreference.init(_scriptName, prefData,
            !defaultPreferencesIds.contains(prefData.saveId))) : (new Preference(prefData, !defaultPreferencesIds.contains(prefData.saveId)));

        preferenceItem.loadDefaultValue();
        loadedPreferencesArrayIds.push(preferenceItem.saveId);
        loadedPreferences.set(preferenceItem.saveId, preferenceItem);
      }
      _scriptName = null;
    }
  }

  // Shortcut
  public static inline function getPref(id:String, ?defVal:Dynamic):Null<Dynamic>
  {
    return getPreference(id, defVal);
  }

  public static function getPreference(id:String, ?defVal:Dynamic):Null<Dynamic>
  {
    return loadedPreferences.exists(id) ? loadedPreferences.get(id)?.getValue() ?? defVal : defVal;
  }

  /**
   * Loads the user's preferences from the save data and apply them.
   */
  public static function init():Void
  {
    #if mobile
    // Apply the allowScreenTimeout setting.
    lime.system.System.allowScreenTimeout = Preferences.screenTimeout;
    #end

    for (pref in loadedPreferences)
      pref.onInit();
  }

  /**
   * A global audio offset in milliseconds.
   * This is used to sync the audio.
   * @default `0`
   */
  public static var globalOffset(get, set):Int;

  static function get_globalOffset():Int
  {
    return Save?.instance?.options?.globalOffset ?? 0;
  }

  static function set_globalOffset(value:Int):Int
  {
    var save:Save = Save.instance;
    save.options.globalOffset = value;
    save.flush();
    return value;
  }

  #if web
  // We create a haxe version of this just for readability.
  // We use these to override `window.requestAnimationFrame` in Javascript to uncap the framerate / "animation" request rate
  // Javascript is crazy since u can just do stuff like that lol

  public static function unlockedFramerateFunction(callback, element)
  {
    var currTime = Date.now().getTime();
    var timeToCall = 0;
    var id = js.Browser.window.setTimeout(function() {
      callback(currTime + timeToCall);
    }, timeToCall);
    return id;
  }

  // Lime already implements their own little framerate cap, so we can just use that
  // This also gets set in the init function in Main.hx, since we need to definitely override it
  public static var lockedFramerateFunction = untyped js.Syntax.code("window.requestAnimationFrame");
  #end

  static function toggleFramerateCap(unlocked:Bool):Void
  {
    #if web
    var framerateFunction = unlocked ? unlockedFramerateFunction : lockedFramerateFunction;
    untyped js.Syntax.code("window.requestAnimationFrame = framerateFunction;");
    #end
  }

  static function toggleDebugDisplay(show:Bool):Void
  {
    if (show)
    {
      // Enable the debug display.
      FlxG.game.parent.addChild(Main.fpsCounter);

      #if !html5
      FlxG.game.parent.addChild(Main.memoryCounter);
      #end
    }
    else
    {
      // Disable the debug display.
      FlxG.game.parent.removeChild(Main.fpsCounter);

      #if !html5
      FlxG.game.parent.removeChild(Main.memoryCounter);
      #end
    }
  }

  #if mobile
  /**
   * If enabled, device will be able to sleep on its own.
   * @default `false`
   */
  public static var screenTimeout(get, set):Bool;

  static function get_screenTimeout():Bool
  {
    return Save?.instance?.mobileOptions?.screenTimeout ?? false;
  }

  static function set_screenTimeout(value:Bool):Bool
  {
    if (value != Save.instance.mobileOptions.screenTimeout) lime.system.System.allowScreenTimeout = value;

    var save:Save = Save.instance;
    save.mobileOptions.screenTimeout = value;
    save.flush();
    return value;
  }

  /**
   * Controls Scheme for the hitbox.
   * @default `4 Lanes`
   */
  public static var controlsScheme(get, set):String;

  static function get_controlsScheme():String
  {
    return Save?.instance?.mobileOptions?.controlsScheme ?? FunkinHitboxControlSchemes.Arrows;
  }

  static function set_controlsScheme(value:String):String
  {
    var save:Save = Save.instance;
    save.mobileOptions.controlsScheme = value;
    save.flush();
    return value;
  }

  #if FEATURE_MOBILE_IAP
  /**
   * If bought, the game will not show any ads.
   * @default `false`
   */
  @:unreflective
  public static var noAds(get, set):Bool;

  @:unreflective
  static function get_noAds():Bool
  {
    if (InAppPurchasesUtil.hasInitialized) noAds = InAppPurchasesUtil.isPurchased(InAppPurchasesUtil.UPGRADE_PRODUCT_ID);
    var returnedValue = Save?.instance?.mobileOptions?.noAds ?? false;
    return returnedValue;
  }

  @:unreflective
  static function set_noAds(value:Bool):Bool
  {
    var save:Save = Save.instance;
    save.mobileOptions.noAds = value;
    save.flush();
    return value;
  }
  #end
  #end
}
