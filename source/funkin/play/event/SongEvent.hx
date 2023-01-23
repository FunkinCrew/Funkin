package funkin.play.event;

import funkin.util.macro.ClassMacro;
import funkin.play.song.SongData.SongEventData;

/**
 * This class represents a handler for a type of song event.
 * It is used by the ScriptedSongEvent class to handle user-defined events.
 */
class SongEvent
{
  public var id:String;

  public function new(id:String)
  {
    this.id = id;
  }

  public function handleEvent(data:SongEventData)
  {
    throw 'SongEvent.handleEvent() must be overridden!';
  }

  public function getEventSchema():SongEventSchema
  {
    return null;
  }

  public function getTitle():String
  {
    return this.id.toTitleCase();
  }

  public function toString():String
  {
    return 'SongEvent(${this.id})';
  }
}

class SongEventParser
{
  /**
   * Every built-in event class must be added to this list.
   * Thankfully, with the power of `SongEventMacro`, this is done automatically.
   */
  private static final BUILTIN_EVENTS:List<Class<SongEvent>> = ClassMacro.listSubclassesOf(SongEvent);

  /**
   * Map of internal handlers for song events.
   * These may be either `ScriptedSongEvents` or built-in classes extending `SongEvent`.
   */
  static final eventCache:Map<String, SongEvent> = new Map<String, SongEvent>();

  public static function loadEventCache():Void
  {
    clearEventCache();

    //
    // BASE GAME EVENTS
    //
    registerBaseEvents();
    registerScriptedEvents();
  }

  static function registerBaseEvents()
  {
    trace('Instantiating ${BUILTIN_EVENTS.length} built-in song events...');
    for (eventCls in BUILTIN_EVENTS)
    {
      var eventClsName:String = Type.getClassName(eventCls);
      if (eventClsName == 'funkin.play.event.SongEvent' || eventClsName == 'funkin.play.event.ScriptedSongEvent')
        continue;

      var event:SongEvent = Type.createInstance(eventCls, ["UNKNOWN"]);

      if (event != null)
      {
        trace('  Loaded built-in song event: (${event.id})');
        eventCache.set(event.id, event);
      }
      else
      {
        trace('  Failed to load built-in song event: ${Type.getClassName(eventCls)}');
      }
    }
  }

  static function registerScriptedEvents()
  {
    var scriptedEventClassNames:Array<String> = ScriptedSongEvent.listScriptClasses();
    if (scriptedEventClassNames == null || scriptedEventClassNames.length == 0)
      return;

    trace('Instantiating ${scriptedEventClassNames.length} scripted song events...');
    for (eventCls in scriptedEventClassNames)
    {
      var event:SongEvent = ScriptedSongEvent.init(eventCls, "UKNOWN");

      if (event != null)
      {
        trace('  Loaded scripted song event: ${event.id}');
        eventCache.set(event.id, event);
      }
      else
      {
        trace('  Failed to instantiate scripted song event class: ${eventCls}');
      }
    }
  }

  public static function listEventIds():Array<String>
  {
    return eventCache.keys().array();
  }

  public static function listEvents():Array<SongEvent>
  {
    return eventCache.values();
  }

  public static function getEvent(id:String):SongEvent
  {
    return eventCache.get(id);
  }

  public static function getEventSchema(id:String):SongEventSchema
  {
    var event:SongEvent = getEvent(id);
    if (event == null)
      return null;

    return event.getEventSchema();
  }

  static function clearEventCache()
  {
    eventCache.clear();
  }

  public static function handleEvent(data:SongEventData):Void
  {
    var eventType:String = data.event;
    var eventHandler:SongEvent = eventCache.get(eventType);

    if (eventHandler != null)
    {
      eventHandler.handleEvent(data);
    }
    else
    {
      trace('WARNING: No event handler for event with id: ${eventType}');
    }

    data.activated = true;
  }

  public static inline function handleEvents(events:Array<SongEventData>):Void
  {
    for (event in events)
    {
      handleEvent(event);
    }
  }

  /**
   * Given a list of song events and the current timestamp,
   * return a list of events that should be handled.
   */
  public static function queryEvents(events:Array<SongEventData>, currentTime:Float):Array<SongEventData>
  {
    return events.filter(function(event:SongEventData):Bool
    {
      // If the event is already activated, don't activate it again.
      if (event.activated)
        return false;

      // If the event is in the future, don't activate it.
      if (event.time > currentTime)
        return false;

      return true;
    });
  }

  /**
   * Reset activation of all the provided events.
   */
  public static function resetEvents(events:Array<SongEventData>):Void
  {
    for (event in events)
    {
      event.activated = false;
      // TODO: Add an onReset() method to SongEvent?
    }
  }
}

enum abstract SongEventFieldType(String) from String to String
{
  /**
   * The STRING type will display as a text field.
   */
  var STRING = "string";

  /**
   * The INTEGER type will display as a text field that only accepts numbers.
   */
  var INTEGER = "integer";

  /**
   * The FLOAT type will display as a text field that only accepts numbers.
   */
  var FLOAT = "float";

  /**
   * The BOOL type will display as a checkbox.
   */
  var BOOL = "bool";

  /**
   * The ENUM type will display as a dropdown.
   * Make sure to specify the `keys` field in the schema.
   */
  var ENUM = "enum";
}

typedef SongEventSchemaField =
{
  /**
   * The name of the property as it should be saved in the event data.
   */
  name:String,

  /**
   * The title of the field to display in the UI.
   */
  title:String,

  /**
   * The type of the field.
   */
  type:SongEventFieldType,

  /**
   * Used for ENUM values.
   * The key is the display name and the value is the actual value.
   */
  ?keys:Map<String, Dynamic>,
  /**
   * Used for INTEGER and FLOAT values.
   * The minimum value that can be entered.
   */
  ?min:Float,
  /**
   * Used for INTEGER and FLOAT values.
   * The maximum value that can be entered.
   */
  ?max:Float,
  /**
   * Used for INTEGER and FLOAT values.
   * The step value that will be used when incrementing/decrementing the value.
   */
  ?step:Float,
  /**
   * An optional default value for the field.
   */
  ?defaultValue:Dynamic,
}

typedef SongEventSchema = Array<SongEventSchemaField>;
