package funkin.mobile.external.android;

import lime.system.JNI;
import flixel.util.FlxSignal;

/**
 * A Utility class to handle Android API level callbacks and events.
 */
@:unreflective
class CallbackUtil
{
  #if android
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
  #end
}

/**
 * Internal class to handle native callback events.
 */
class CallbackHandler #if (lime >= "8.0.0") implements JNISafety #end
{
  #if android
  @:allow(funkin.mobile.external.android.CallbackUtil)
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
  #end
}
