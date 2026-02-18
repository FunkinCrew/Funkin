package funkin.util.collection;

import haxe.Constraints.IMap;
import flixel.util.FlxSignal;
import flixel.util.FlxSignal.FlxTypedSignal;

/**
 * A wrapper for a `Map<String, V>` which receives callbacks when elements are added, removed, or accessed.
 * Due to weird issues with Haxe's maps, you can only make a map with String keys with this.
 */
@:nullSafety
class CallbackMap<V> implements IMap<String, V>
{
  var map:Map<String, V>;

  public function new()
  {
    this.map = [];
  }

  /**
   * A signal which is dispatched when the map is cleared.
   */
  public var onClear:FlxSignal = new FlxSignal();

  /**
   * A signal which is dispatched when the map is iterated over.
   */
  public var onIterator:FlxSignal = new FlxSignal();

  /**
   * A signal which is dispatched when the map's key-value pairs are iterated over.
   */
  public var onKeyValueIterator:FlxSignal = new FlxSignal();

  /**
   * A signal which is dispatched when the map's keys are iterated over.
   */
  public var onKeys:FlxSignal = new FlxSignal();

  /**
   * A signal which is dispatched when the existence of a key is checked.
   */
  public var onExists:FlxTypedSignal<String->Void> = new FlxTypedSignal();

  /**
   * A signal which is dispatched when a key's value is retrieved.
   */
  public var onGet:FlxTypedSignal<String->Void> = new FlxTypedSignal();

  /**
   * A signal which is dispatched when a key's value is set.
   */
  public var onSet:FlxTypedSignal<String->V->Void> = new FlxTypedSignal();

  /**
   * A signal which is dispatched when a key is removed.
   */
  public var onRemove:FlxTypedSignal<String->Void> = new FlxTypedSignal();

  /**
   * Clears the contents of the map.
   */
  public function clear():Void
  {
    onClear.dispatch();
    map.clear();
  }

  /**
   * Returns a copy of the map.
   * @return A copy of the map.
   */
  public function copy():IMap<String, V>
  {
    throw 'CallbackMap.copy() is not implemented';
  }

  /**
   * Checks if the map contains a key.
   * @param key The key to check.
   * @return Whether the map contains the key.
   */
  public function exists(key:String):Bool
  {
    onExists.dispatch(key);
    return map.exists(key);
  }

  /**
   * Retrieves a value from the map.
   * @param key The key to retrieve.
   * @return The value associated with the key, or `null` if the key does not exist.
   */
  public function get(key:String):Null<V>
  {
    onGet.dispatch(key);
    return map.get(key);
  }

  /**
   * Returns an iterator over the map.
   * @return An iterator over the map.
   */
  public function iterator():Iterator<V>
  {
    onIterator.dispatch();
    return map.iterator();
  }

  /**
   * Returns an iterator over the map's key-value pairs.
   * @return An iterator over the map's key-value pairs.
   */
  public function keyValueIterator():KeyValueIterator<String, V>
  {
    onKeyValueIterator.dispatch();
    return map.keyValueIterator();
  }

  /**
   * Returns an iterator over the map's keys.
   * @return An iterator over the map's keys.
   */
  public function keys():Iterator<String>
  {
    onKeys.dispatch();
    return map.keys();
  }

  /**
   * Removes a key from the map.
   * @param key The key to remove.
   * @return Whether the key was removed.
   */
  public function remove(key:String):Bool
  {
    onRemove.dispatch(key);
    return map.remove(key);
  }

  /**
   * Sets a key's value in the map.
   * @param key The key to set.
   * @param value The value to set.
   */
  public function set(key:String, value:V):Void
  {
    onSet.dispatch(key, value);
    map.set(key, value);
  }

  /**
   * @return A string representation of the map.
   */
  public function toString():String
  {
    return 'CallbackMap(${map.toString()})';
  }
}
