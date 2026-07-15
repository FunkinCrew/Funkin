package funkin.util.collection;

import haxe.Constraints.IMap;
import flixel.util.FlxSignal;
import flixel.util.FlxSignal.FlxTypedSignal;
#if FEATURE_MULTITHREADING
import hx.concurrent.collection.SynchronizedMap;
#end

/**
 * A wrapper for a `Map<String, V>` which receives callbacks when elements are added, removed, or accessed.
 */
@:forward
abstract CallbackMap<V>(CallbackMapImpl<V>) from CallbackMapImpl<V> to CallbackMapImpl<V>
{
  /**
   * Get an element from the map.
   * @param k The key to get.
   * @return The value associated with the key, or `null` if the key does not exist.
   */
  @:arrayAccess
  public inline function get(k:String):Null<V>
  {
    return this.get(k);
  }

  /**
   * Set an element in the map.
   * @param k The key to set.
   * @param v The value to set to.
   * @return The value that was set.
   */
  @:arrayAccess
  public inline function set(k:String, v:V):V
  {
    this.set(k, v);
    return v;
  }

  public function new()
  {
    this = new CallbackMapImpl<V>();
  }
}

/**
 * The underlying implementation of `CallbackMap`.
 * We need an abstract to allow you to do map[key] instead of map.get(key)
 */
@:nullSafety
class CallbackMapImpl<V> implements IMap<String, V>
{
  /**
   * The actual data being stored.
   * We use a synchronized map to make it thread-safe.
   */
  #if FEATURE_MULTITHREADING
  final map:SynchronizedMap<String, V>;
  #else
  final map:Map<String, V>;
  #end

  public function new()
  {
    #if FEATURE_MULTITHREADING
    this.map = SynchronizedMap.newStringMap();
    #else
    this.map = [];
    #end
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
   * Returns an array of the map's keys.
   * @return An array of the map's keys.
   */
  public function keyValues():Array<String>
  {
    return keys().array();
  }

  /**
   * @return The number of keys currently in the map.
   */
  public function size<K, T>():Int
  {
    if (map == null) return 0;
    return keyValues().length;
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
