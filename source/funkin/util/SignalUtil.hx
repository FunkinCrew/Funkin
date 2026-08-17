package funkin.util;

import flixel.util.FlxSignal.IFlxSignal;

/**
 * Helpers for working with signals from scripts, mostly for CPPIA.
 */
class SignalUtil
{
  /**
   * Subscribe to a signal.
   * @param signal The signal to subscribe to.
   * @param listener The function to call when the signal dispatches.
   * @return Whether the listener was added.
   */
  public static function add(signal:Dynamic, listener:Dynamic):Bool
  {
    var target = resolve(signal, listener, 'add');
    if (target == null) return false;

    target.add(listener);
    return true;
  }

  /**
   * Subscribe to a signal, then drop the listener after it fires once.
   * @param signal The signal to subscribe to.
   * @param listener The function to call when the signal dispatches.
   * @return Whether the listener was added.
   */
  public static function addOnce(signal:Dynamic, listener:Dynamic):Bool
  {
    var target = resolve(signal, listener, 'addOnce');
    if (target == null) return false;

    target.addOnce(listener);
    return true;
  }

  /**
   * Unsubscribe from a signal.
   * @param signal The signal to unsubscribe from.
   * @param listener The function that was subscribed.
   * @return Whether the listener was removed.
   */
  public static function remove(signal:Dynamic, listener:Dynamic):Bool
  {
    var target = resolve(signal, listener, 'remove');
    if (target == null) return false;

    target.remove(listener);
    return true;
  }

  /**
   * Whether a signal already has the given listener.
   * @param signal The signal to query.
   * @param listener The function to look for.
   * @return Whether the listener is subscribed.
   */
  public static function has(signal:Dynamic, listener:Dynamic):Bool
  {
    var target = resolve(signal, listener, 'has');
    if (target == null) return false;

    return target.has(listener);
  }

  /**
   * Drop every listener on a signal.
   * @param signal The signal to clear.
   * @return Whether the signal was cleared.
   */
  public static function removeAll(signal:Dynamic):Bool
  {
    if (signal == null)
    {
      trace('[SignalUtil] removeAll was given a null signal.');
      return false;
    }

    var target:IFlxSignal<Dynamic> = cast signal;
    target.removeAll();
    return true;
  }

  static function resolve(signal:Dynamic, listener:Dynamic, action:String):Null<IFlxSignal<Dynamic>>
  {
    if (signal == null)
    {
      trace('[SignalUtil] $action was given a null signal.');
      return null;
    }

    if (listener == null)
    {
      trace('[SignalUtil] $action was given a null listener.');
      return null;
    }

    if (!Reflect.isFunction(listener))
    {
      trace('[SignalUtil] $action was given a listener that is not a function.');
      return null;
    }

    if (!Std.isOfType(signal, IFlxSignal))
    {
      trace('[SignalUtil] $action was given a ${Type.getClassName(Type.getClass(signal))}, which is not a signal.');
      return null;
    }

    return cast signal;
  }
}
