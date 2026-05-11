package funkin.memory;

import flixel.graphics.FlxGraphic;
import openfl.media.Sound;

class StagedCache<T>
{
  // The maps are now internal to this specific instance
  public var current:Map<String, T>;
  public var previous:Map<String, T>;
  public var onPurge:T->Void;
  public var onReuse:T->Void;

  public function new(onPurge:T->Void, onReuse:T->Void)
  {
    current = new Map();
    previous = new Map();
    this.onPurge = onPurge;
    this.onReuse = onReuse;
  }

  public function preparePurge():Void
  {
    for (key in current.keys())
    {
      previous.set(key, current.get(key));
    }

    current.clear();
  }

  // Returns the asset if it exists, otherwise null. If it exists in the previous cache, it'll be moved to the current cache and calls onReuse.

  public function get(key:String):T
  {
    if (current.exists(key)) return current.get(key);

    var asset:Null<T> = null;

    if (previous.exists(key))
    {
      // Found it in the old cache! Move it to current.
      asset = previous.get(key);
      previous.remove(key);
      current.set(key, asset);
      onReuse(asset);
    }

    return asset;
  }

  public function exists(key:String):Bool
  {
    if (previous.exists(key))
    {
      // Found it in the old cache! Move it to current.
      var asset:T = previous.get(key);
      previous.remove(key);
      current.set(key, asset);
      onReuse(asset);
    }
    return current.exists(key);
  }

  public function remove(key:String):Bool
  {
    var result:Bool = false;

    if (previous.exists(key))
    {
      var asset:T = previous.get(key);
      if (onPurge != null) onPurge(asset);
      previous.remove(key);
      result = true;
    }

    if (current.exists(key))
    {
      var asset:T = current.get(key);
      if (onPurge != null) onPurge(asset);
      current.remove(key);
      result = true;
    }

    return result;
  }

  public function set(key:String, asset:T):Void
  {
    current.set(key, asset);
  }

  public function purge():Void
  {
    for (asset in previous)
    {
      if (onPurge != null) onPurge(asset);
    }
    previous.clear();
  }

  public function allKeys():Array<String>
  {
    var keys:Array<String> = [];
    for (key in current.keys())
    {
      keys.push(key);
    }
    for (key in previous.keys())
    {
      keys.push(key);
    }
    return keys;
  }
}
