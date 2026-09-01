package funkin.util.assets;

import flixel.util.FlxSignal.FlxTypedSignal;
#if FEATURE_MULTITHREADING
import hx.concurrent.collection.SynchronizedMap;
#end

/**
 * Represents a three-stage asset cache, which is useful for managing and tracking assets that are in use by the game.
 */
@:nullSafety
@:allow(funkin.assets.FunkinAssetCache, funkin.assets.FunkinBitmapFrontend)
class StagedCache<T> implements IStagedCache
{
  /**
   * The permanent cache, containing assets which always stay in memory and are never purged.
   */
  #if FEATURE_MULTITHREADING
  final permanent:SynchronizedMap<String, T>;
  #else
  final permanent:Map<String, T>;
  #end
  /**
   * The currently cached assets. Won't be purged until the next purge cycle.
   */
  #if FEATURE_MULTITHREADING
  final current:SynchronizedMap<String, T>;
  #else
  final current:Map<String, T>;
  #end
  /**
   * The assets that were previously cached. May be re-cached, but if not, they will be purged.
   */
  #if FEATURE_MULTITHREADING
  final previous:SynchronizedMap<String, T>;
  #else
  final previous:Map<String, T>;
  #end

  /**
   * An FlxSignal which is dispatched when an asset is removed. Typically used for cleanup of assets that need to be manually destroyed (e.g. FlxGraphics).
   */
  public var onRemove(default, never):FlxTypedSignal<(String, T) -> Void> = new FlxTypedSignal<(String, T) -> Void>();

  /**
   * An FlxSignal which is dispatched when an asset is reused (i.e. moved from `previous` to `current`).
   */
  public var onReuse(default, never):FlxTypedSignal<(String, T) -> Void> = new FlxTypedSignal<(String, T) -> Void>();

  /**
   * Dispatched for each asset right before a purge begins.
   */
  public var onPrePurge(default, never):FlxTypedSignal<(String, T) -> Void> = new FlxTypedSignal<(String, T) -> Void>();

  /**
   * Dispatched for each asset right after a its removal on purge.
   */
  public var onPostPurge(default, never):FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

  public function new()
  {
    // The cache maps are final to prevent them from being overridden,
    // but they are still mutable.
    #if FEATURE_MULTITHREADING
    permanent = SynchronizedMap.newStringMap();
    current = SynchronizedMap.newStringMap();
    previous = SynchronizedMap.newStringMap();
    #else
    permanent = [];
    current = [];
    previous = [];
    #end
  }

  /**
   * Tries to retrieve an asset by its key, if it exists in the cache.
   * If the asset exists in the previous cache, transfer it over.
   *
   * @param key The key of the asset to retrieve.
   * @param reuse Whether to reuse the asset if its found in previous. True by default.
   * @return The asset, if it exists in the cache. Otherwise, `null`.
   */
  public function get(key:String, reuse:Bool = true):Null<T>
  {
    // Use the existing cache first.
    if (existsPermanent(key)) return permanent.get(key);
    if (existsCurrent(key)) return current.get(key);

    if (existsPrevious(key)) return (reuse) ? reusePrevious(key) : previous.get(key);

    // The asset isn't cached.
    return null;
  }

  /**
   * Reuse an asset from the previous cache to the current cache.
   *
   * @param key The key of the asset to transfer.
   * @return The asset that was reused.
   */
  function reusePrevious(key:String):T
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('StagedCache.reusePrevious($key)');
    #end
    // Transfer to the current asset cache.
    var asset:Null<T> = previous.get(key);
    previous.remove(key);
    if (asset != null)
    {
      current.set(key, asset);
      // Dispatch that the asset was reused.
      onReuse.dispatch(key, asset);
      return asset;
    }
    else
    {
      throw 'Bwuh?';
    }
  }

  /**
   * Add the provided asset to the cache.
   * It will be discarded later if the asset cache is purged.
   *
   * @param key The key of the asset to cache.
   * @param asset The asset to store in the cache.
   */
  public function cache(key:String, asset:T):Void
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('StagedCache.cache($key)');
    #end
    if (asset == null) return;
    if (permanent.exists(key))
    {
      cachePermanent(key, asset);
      return;
    }

    if (previous.exists(key))
    {
      if (previous.get(key) != asset) onRemove.dispatch(key, asset); // We only call onRemove if the asset is different.
      previous.remove(key);
    }
    current.set(key, asset);
  }

  /**
   * Add the provided asset to the PERMANENT cache.
   * It will not be discarded later, so be cautious with what you cache with this.
   *
   * @param key The key of the asset to cache.
   * @param asset The asset to store in the cache.
   */
  public function cachePermanent(key:String, asset:T):Void
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('StagedCache.cachePermanent($key)');
    #end
    if (asset == null) return;
    if (previous.exists(key))
    {
      if (previous.get(key) != asset) onRemove.dispatch(key, asset); // We only call onRemove if the asset is different.
      previous.remove(key);
    }
    if (current.exists(key))
    {
      if (current.get(key) != asset) onRemove.dispatch(key, asset); // We only call onRemove if the asset is different.
      current.remove(key);
    }

    permanent.set(key, asset);
  }

  /**
   * Checks if the cache contains an asset with the given key.
   * NOTE: Returns `true` even if the asset is "unused" and will be purged later,
   * make sure to call `get()` if you want to keep it around.
   *
   * @param key The key of the asset to check for.
   * @return `true` if the asset exists in the cache, otherwise `false`.
   */
  public function exists(key:String):Bool
  {
    return existsPermanent(key) || existsCurrent(key) || existsPrevious(key);
  }

  inline function existsPermanent(key:String):Bool
  {
    return permanent.exists(key) && permanent.get(key) != null;
  }

  inline function existsCurrent(key:String):Bool
  {
    return current.exists(key) && current.get(key) != null;
  }

  inline function existsPrevious(key:String):Bool
  {
    return previous.exists(key) && previous.get(key) != null;
  }

  /**
   * @return A list of keys for all currently cached assets.
   */
  public function keys():Array<String>
  {
    var keys:Array<String> = [];
    #if FEATURE_MULTITHREADING
    // MapTools can't be used for SynchronizedMap.
    keys.appendUnique([for (k => v in permanent) k]);
    keys.appendUnique([for (k => v in current) k]);
    keys.appendUnique([for (k => v in previous) k]);
    #else
    keys.appendUnique(permanent.keyValues());
    keys.appendUnique(current.keyValues());
    keys.appendUnique(previous.keyValues());
    #end
    return keys;
  }

  /**
   * Prepares the cache for purging unused assets.
   * This moves all the assets from the `current` cache to the `previous` cache.
   * When `purgeCache()` gets called later, any `previous` assets that weren't re-cached will be purged.
   */
  public function preparePurgeCache():Void
  {
    // Move all the `current` assets to the `previous` cache.
    for (key => asset in current)
    {
      if (existsPermanent(key)) continue;

      onPrePurge.dispatch(key, asset);
      previous.set(key, asset);
    }

    current.clear();
  }

  /**
   * Purges all unused assets from the asset cache.
   * Make sure to call `preparePurgeCache()`, then re-fetch each asset you want to keep
   * before calling this function.
   */
  public function purgeCache():Void
  {
    for (key => asset in previous)
    {
      if (key == null || asset == null) continue;
      if (existsPermanent(key)) continue;
      if (existsCurrent(key)) continue;

      remove(key);
      onPostPurge.dispatch(key);
    }
  }

  /**
   * Purges unused assets from the asset cache, if they match the provided predicate.
   * Make sure to call `preparePurgeCache()`, then re-fetch each asset you want to keep
   * before calling this function.
   *
   * @param predicate A function to call. If `true` is returned, the asset will be purged.
   */
  public function purgeCacheByPredicate(predicate:(String, T) -> Bool):Void
  {
    for (key => asset in previous)
    {
      if (key == null || asset == null) continue;
      if (existsPermanent(key)) continue;
      if (existsCurrent(key)) continue;
      if (!predicate(key, asset)) continue;

      remove(key);
      onPostPurge.dispatch(key);
    }
  }

  /**
   * Purges unused assets from the asset cache, that start with the given prefix.
   *
   * @param prefix The prefix to filter by.
   */
  public function purgeCacheByPrefix(prefix:String):Void
  {
    purgeCacheByPredicate((key, asset) -> key.startsWith(prefix));
  }

  /**
   * Forcibly purges all assets from the cache, even ones that are in use.
   *
   * @param clearPermanent Whether to also clear permanently cached assets.
   */
  public function clearCache(clearPermanent:Bool = false):Void
  {
    for (key in keys())
    {
      var asset:Null<T> = get(key);
      if (asset == null) continue;
      remove(key, clearPermanent);
    }
    if (clearPermanent) permanent.clear();
    current.clear();
    previous.clear();
  }

  /**
   * Forcibly purges all assets from the cache, even ones that are in use, that meet a given condition.
   *
   * @param predicate A function to call. If `true` is returned, the asset will be purged.
   * @param clearPermanent Whether to also clear permanently cached assets.
   */
  public function clearCacheByPredicate(predicate:(String, T) -> Bool, clearPermanent:Bool = false):Void
  {
    for (key in keys())
    {
      var asset:Null<T> = get(key);
      if (asset == null) continue;
      if (predicate(key, asset)) remove(key, clearPermanent);
    }
  }

  /**
   * Forcibly purges all assets from the cache, even ones that are in use, that start with the given prefix.
   *
   * @param prefix The prefix to filter by.
   * @param clearPermanent Whether to also clear permanently cached assets.
   */
  public function clearCacheByPrefix(prefix:String, clearPermanent:Bool = false):Void
  {
    clearCacheByPredicate((key, asset) -> key.startsWith(prefix), clearPermanent);
  }

  /**
   * Forcibly purges a specific asset from the cache.
   *
   * @param key The key of the asset to purge.
   * @param purgePermanent Whether to also purge permanently cached assets.
   * @return Whether the asset was purged successfully.
   */
  public function remove(key:String, purgePermanent:Bool = false):Bool
  {
    var result:Bool = false;

    if (existsPrevious(key))
    {
      var asset:Null<T> = previous.get(key);

      // Null safety a little dumb...
      if (asset != null)
      {
        if (onRemove != null) onRemove.dispatch(key, asset);
        previous.remove(key);

        result = true;
      }
    }

    if (existsCurrent(key))
    {
      var asset:Null<T> = current.get(key);

      // Null safety a little dumb...
      if (asset != null)
      {
        if (onRemove != null) onRemove.dispatch(key, asset);
        current.remove(key);

        result = true;
      }
    }

    if (purgePermanent && existsPermanent(key))
    {
      var asset:Null<T> = permanent.get(key);
      if (asset != null)
      {
        if (onRemove != null) onRemove.dispatch(key, asset);
        permanent.remove(key);

        result = true;
      }
    }

    return result;
  }

  /**
   * Helper function to remove a key from the cache without removing the graphic from memory.
   * Useful to correct incorrect asset caches of unique graphics.
   * @param key The key of the asset to purge.
   * @param purgePermanent Whether to also purge permanently cached assets.
   * @return Whether the asset was purged successfully.
   */
  public function removeKey(key:String, purgePermanent:Bool = false):Bool
  {
    var result:Bool = false;

    if (existsPrevious(key))
    {
      previous.remove(key);
      result = true;
    }

    if (existsCurrent(key))
    {
      current.remove(key);

      result = true;
    }

    if (purgePermanent && existsPermanent(key))
    {
      permanent.remove(key);
      result = true;
    }

    return result;
  }
}

/**
 * An interface containing all the methods common to StagedCaches.
 * This allows you to create arrays and functions that take StagedCaches of any type.
 */
@SuppressWarnings('checkstyle:FieldDocComment')
interface IStagedCache
{
  // get() has different typing for each cache
  // cache() has different typing for each cache
  // cachePermanent() has different typing for each cache
  public function exists(key:String):Bool;
  public function keys():Array<String>;
  public function preparePurgeCache():Void;
  public function purgeCache():Void;
  // purgeCacheByPredicate() has different typing for each cache
  public function purgeCacheByPrefix(prefix:String):Void;
  public function clearCache(clearPermanent:Bool = false):Void;
  // clearCacheByPredicate() has different typing for each cache
  public function clearCacheByPrefix(prefix:String, clearPermanent:Bool = false):Void;
  public function remove(key:String, purgePermanent:Bool = false):Bool;
}
