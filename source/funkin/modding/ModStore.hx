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
   * Registers a new store with the given ID.
   * If a store with the same ID already exists, it will be returned instead.
   * 
   * @id The ID for this store. Make sure it's unique!
   * @data Optional initial data for this store. Uses an empty object by default.
   * @return The store data at the given ID.
   */
  public static function register(id:String, ?data:Dynamic):Dynamic
  {
    if (stores.exists(id)) return stores.get(id);
    stores.set(id, data ??= {});
    return data;
  }

  /**
   * Removes a store by ID and returns whatever data it had.
   * 
   * @id The ID of the store.
   * @return The store data, or `null` if the store did not exist.
   */
  public static function remove(id:String):Dynamic
  {
    if (stores.exists(id))
    {
      var data:Dynamic = stores.get(id);
      stores.remove(id);
      return data;
    }

    return null;
  }
}