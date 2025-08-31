package funkin.external.android;

#if android
import lime.system.JNI;
import flixel.util.FlxSignal;

/**
 * A Utility class to handle Android API level callbacks and events.
 */
@:unreflective
class CallbackUtil
{
  /**
   * The result code for `DATA_FOLDER_CLOSED` activity.
   */
  public static var DATA_FOLDER_CLOSED(get, never):Int;

  @:noCompletion
  static function get_DATA_FOLDER_CLOSED():Int
  {
    final field:Null<Dynamic> = JNIUtil.createStaticField('funkin/extensions/CallbackUtil', 'DATA_FOLDER_CLOSED', 'I');

    return field != null ? field.get() : 0;
  }

  /**
   * Signal triggered when an activity result is received.
   *
   * First argument is the request code, second is the result code.
   */
  public static var onActivityResult:FlxTypedSignal<Int->Int->Void> = new FlxTypedSignal<Int->Int->Void>();

  /**
   * Signal triggered when the user opens a FNFC file with the game in runtime.
   *
   * First argument is the FNFC file path.
   */
  public static var onOpenFNFC:FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

  /**
   * Initializes the callback utility.
   */
  public static function init():Void
  {
    final initCallBackJNI:Null<Dynamic> = JNIUtil.createStaticMethod('funkin/extensions/CallbackUtil', 'initCallBack', '(Lorg/haxe/lime/HaxeObject;)V');

    if (initCallBackJNI != null)
    {
      initCallBackJNI(new CallbackHandler());
    }
  }
}

/**
 * Internal class to handle native callback events.
 */
class CallbackHandler #if (lime >= "8.0.0") implements JNISafety #end
{
  @:allow(funkin.external.android.CallbackUtil)
  function new():Void {}

  /**
   * Handles the activity result callback from native code.
   *
   * @param requestCode The request code of the acitivty.
   * @param resultCode  The result code of the acitivty.
   */
  @:keep
  #if (lime >= "8.0.0")
  @:runOnMainThread
  #end
  public function onActivityResult(requestCode:Int, resultCode:Int):Void
  {
    if (CallbackUtil.onActivityResult != null) CallbackUtil.onActivityResult.dispatch(requestCode, resultCode);
  }

  /**
   * Handles the onOpenFNFC callback from native code.
   *
   * @param file Path to the FNFC file that was opened.
   */
  @:keep
  #if (lime >= "8.0.0")
  @:runOnMainThread
  #end
  public function onOpenFNFC(file:String):Void
  {
    if (CallbackUtil.onOpenFNFC != null) CallbackUtil.onOpenFNFC.dispatch(file);
  }
}
#end
