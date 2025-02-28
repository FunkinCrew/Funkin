package funkin.modding;

import haxe.ds.StringMap;

/**
 * Temporary persistent data storage for mods to use.
 */
class ModStore
{
  /**
   * All registered stores for this runtime.
   */
  public static final stores:StringMap<Dynamic> = new StringMap<Dynamic>();

  /**
   * Registers a new store with the given ID.
   * If a store with the same ID already exists, it will be returned instead.
   * 
   * @id The ID for this store.
   * @data Optional initial data for this store. If none, it'll use an empty object.
   * @return The store data.
   */
  public static function register(id:String, ?data:Dynamic):Dynamic
  {
    if (stores.exists(id)) return stores.get(id);

    data = data ?? {};
    stores.set(id, data);
    return data;
  }

  /**
   * Helper function to get a store by ID.
   * If the store does not exist, one will be created under the ID with an empty object.
   */
  public static function get(id:String):Dynamic
  {
    if (stores.exists(id)) return stores.get(id);
    return register(id, {});
  }

  /**
   * Removes a store by ID and returns whatever data it had, if any.
   * 
   * @id The ID of the store.
   * @return The store data, or `null` if the store did not exist.
   */
  public static function remove(id:String):Null<Dynamic>
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