package funkin.util.macro;

import haxe.rtti.Meta;

using funkin.util.AnsiUtil;

/**
 * A complement to `ClassMacro`. See `ClassMacro` for more information.
 */
@:nullSafety
class CompiledClassList
{
  /**
   * The name for the Haxe resource that stores Generation Metadata.
   */
  static inline final METADATA_RESOURCE_NAME:String = 'Funkin_CompiledClassList';

  static var classLists:Map<String, List<Class<Dynamic>>> = [];
  static var initialized:Bool = false;

  /**
   * Class lists are injected into this class's metadata during the typing phase.
   * This function extracts the metadata, at runtime, and stores it in `classLists`.
   */
  static function init():Void
  {
    initialized = true;

    var metadata:Array<Array<String>> = fetchMetadata();

    if (metadata != null)
    {
      for (data in metadata)
      {
        // First element is the list ID.
        var id:String = data[0];

        // All other elements are class types.
        var classes:List<Class<Dynamic>> = new List();
        for (i in 1...data.length)
        {
          var className:String = data[i];
          var classType:Class<Dynamic> = Type.resolveClass(className);
          classes.push(classType);
        }

        classLists.set(id, classes);
      }
    }
    else
    {
      throw 'Class lists not properly generated. Try cleaning out your export folder, restarting your IDE, and rebuilding your project.';
    }
  }

  static var _metadata:Dynamic = null;

  static function fetchMetadata():Dynamic
  {
    if (_metadata != null) return _metadata;

    var classListsHXSF:String = haxe.Resource.getString(METADATA_RESOURCE_NAME);
    _metadata = haxe.Unserializer.run(classListsHXSF);
    return _metadata;
  }

  /**
   * Request a list of classes that match the specified criteria.
   *
   * @param request The request. See `ClassMacro` for more information.
   * @return The list of matching classes.
   */
  public static function get(request:String):List<Class<Dynamic>>
  {
    if (!initialized) init();

    if (!classLists.exists(request))
    {
      trace(' WARNING '.bg_yellow().bold() + ' Class list $request not properly generated. Please debug the build macro.');
      classLists.set(request, new List()); // Make the error only appear once.
    }

    // A faulty request sets the value to an empty list above so this will never be null
    @:nullSafety(Off)
    return classLists.get(request);
  }

  /**
   * Request a list of classes that match the specified criteria.
   * Casts the list to match the specified type.
   *
   * @param request The request. See `ClassMacro` for more information.
   * @param type The type of classes to cast the list to.
   * @return The list of matching classes.
   */
  public static inline function getTyped<T>(request:String, type:Class<T>):List<Class<T>>
  {
    return cast get(request);
  }
}
