package funkin.modding;

import haxe.ds.StringMap;

/**
 * Temporary persistent data storage for mods to use.
 */
@:nullSafety
class ModStore
{
  /**
   * All registered stores for this session.
   */
  public static final stores:StringMap<Dynamic> = new StringMap<Dynamic>();

  /**
   * Attempts to register a new store with the given ID and return it.
   * If a store with the same ID already exists, that store will be returned instead (discards `data`).
   *
   * @id The unique ID for this store.
   * @data Optional initial data, uses an empty object by default.
   * @return The store data at the given ID.
   */
  public static function register(id:String, ?data:Dynamic):Dynamic
  {
    if (stores.exists(id)) return stores.get(id);
    stores.set(id, data ??= {});
    return data;
  }

  /**
   * Helper function to get a store by ID.
   *
   * @id The target ID of the store.
   * @return The store data, or `null` if the store did not exist.
   */
  public static function get(id:String):Null<Dynamic>
  {
    return stores.get(id);
  }

  /**
   * Helper function to remove a store by ID and return it.
   *
   * @id The target ID of the store.
   * @return The store data, or `null` if the store did not exist.
   */
  public static function remove(id:String):Null<Dynamic>
  {
    var data:Null<Dynamic> = stores.get(id);
    stores.remove(id);
    return data;
  }
}
