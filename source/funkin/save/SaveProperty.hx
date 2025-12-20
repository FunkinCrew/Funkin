package funkin.save;

import flixel.util.FlxSignal.FlxTypedSignal;

@:nullSafety
class SaveProperty<T>
{
  var _value:T;
  var _getter:Null<Void->T>;
  var _setter:Null<T->Void>;
  var _autoFlush:Bool;

  public var onChange(default, null):FlxTypedSignal<T->Void>;

  public var value(get, set):T;

  function get_value():T
  {
    return _getter != null ? _getter() : _value;
  }

  function set_value(newValue:T):T
  {
    var oldValue:T = get_value();

    if (oldValue != newValue)
    {
      if (_setter != null) _setter(newValue);
      else
        _value = newValue;

      if (_autoFlush) Save.system.flush();

      trace('[Save Property]: Changing value of $oldValue TO $newValue');

      onChange.dispatch(newValue);
    }

    return newValue;
  }

  public function new(initialValue:T, ?getter:Void->T, ?setter:T->Void, autoFlush:Bool = true)
  {
    _value = initialValue;
    _getter = getter;
    _setter = setter;
    _autoFlush = autoFlush;
    onChange = new FlxTypedSignal<T->Void>();
  }

  public function bind(callback:T->Void, fireImmediately:Bool = true):Void
  {
    onChange.add(callback);
    if (fireImmediately) callback(get_value());
  }

  public function bindOnce(callback:T->Void, fireImmediately:Bool = true):Void
  {
    onChange.addOnce(callback);
    if (fireImmediately) callback(get_value());
  }

  public function unbind(callback:T->Void):Void
  {
    onChange.remove(callback);
  }

  public function unbindAll():Void
  {
    onChange.removeAll();
  }

  public function destroy():Void
  {
    onChange.destroy();
    _getter = null;
    _setter = null;
  }

  @:op(A == B)
  public function equals(other:T):Bool
  {
    return get_value() == other;
  }

  @:op(A != B)
  public function notEquals(other:T):Bool
  {
    return get_value() != other;
  }

  public function toString():String
  {
    return Std.string(get_value());
  }
}
