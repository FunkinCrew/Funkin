package funkin.external.android;

#if android
import lime.system.JNI;
import flixel.util.FlxSignal;

/**
 * A Utility class to handle Android API level callbacks and events.
 */
class CallbackUtil #if (lime >= "8.0.0") implements JNISafety #end
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
  public static var onFNCOpen:FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

  /**
   * Initializes the callback utility.
   */
  public static function init():Void
  {
    final initCallBackJNI:Null<Dynamic> = JNIUtil.createStaticMethod('funkin/extensions/CallbackUtil', 'initCallBack', '(Lorg/haxe/lime/HaxeObject;)V');

    if (initCallBackJNI != null)
    {
      initCallBackJNI(new CallbackUtil());
    }
  }

  /**
   * Get an Array that contains every static field from this class
   * @return Array<Dynamic>
   */
  private static function listStaticFields():Array<Dynamic>
  {
    return Type.getClassFields(CallbackUtil);
  }

  @:noCompletion
  private function new() {}

  @:noCompletion
  @:keep
  #if (lime >= "8.0.0")
  @:runOnMainThread
  #end
  private function dispatchCallback(callbackName:String, arguments:Array<Dynamic>)
  {
    // TODO: Figure out a way to check if it's a FlxSignal? Don't know if it's possible due to how FlxTypedSignal works
    if (listStaticFields().contains(callbackName))
    {
      // trace('[CALLBACK] Calling ${callbackName} with args ${arguments == null ? "[]" : '[${arguments.join(',')}]'}');
      final field = Reflect.field(CallbackUtil, callbackName);
      final method = Reflect.field(field, "dispatch");
      Reflect.callMethod(field, method, arguments);
    }
    else
    {
      trace('[CALLBACK] Callback "${callbackName}" not found.');
    }
  }
}
#end
