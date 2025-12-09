package funkin.external.android;

#if android
import lime.system.JNI;
import flixel.util.FlxSignal;
import haxe.ds.Map;

/**
 * A Utility class to handle Android API level callbacks and events.
 */
class CallbackUtil #if (lime >= "8.0.0") implements JNISafety #end
{
  /**
   * The result code for `DATA_FOLDER_CLOSED` activity.
   */
  public static var DATA_FOLDER_CLOSED(get, never):Int;

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
  public static var onFNFCOpen:FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

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

  @:noCompletion
  static function get_DATA_FOLDER_CLOSED():Int
  {
    final field:Null<Dynamic> = JNIUtil.createStaticField('funkin/extensions/CallbackUtil', 'DATA_FOLDER_CLOSED', 'I');

    return field != null ? field.get() : 0;
  }

  @:noCompletion
  private static var __staticFields:Array<Dynamic> = null;

  @:noCompletion
  public static var __callbacksFields:Map<String, Dynamic> = new Map<String, Dynamic>();

  @:noCompletion
  private static function listStaticFields():Array<Dynamic>
  {
    if (__staticFields != null) return __staticFields;
    __staticFields = Type.getClassFields(CallbackUtil);
    __staticFields = __staticFields.filter((field) -> Std.isOfType(Reflect.field(CallbackUtil, field), IFlxSignal));
    return __staticFields;
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
    if (listStaticFields().contains(callbackName))
    {
      final field = Reflect.field(CallbackUtil, callbackName);

      if (!__callbacksFields.exists(callbackName))
      {
        __callbacksFields.set(callbackName, Reflect.field(field, "dispatch"));
      }
      Reflect.callMethod(field, __callbacksFields.get(callbackName), arguments);
    }
    else
    {
      trace('[CALLBACK] Callback "${callbackName}" not found.');
    }
  }
}
#end
