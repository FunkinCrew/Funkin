package funkin.data.event;

import flixel.util.FlxSort;
import funkin.data.song.SongData.SongEventData;
import funkin.play.event.ScriptedSongEvent;
import funkin.play.event.SongEvent;
import funkin.util.macro.ClassMacro;
import funkin.util.SortUtil;

/**
 * This class statically handles the parsing of internal and scripted song event handlers.
 */
@:nullSafety
class SongEventRegistry
{
  /**
   * Every built-in event class must be added to this list.
   * Thankfully, with the power of `ClassMacro`, this is done automatically.
   */
  static final BUILTIN_EVENTS:List<Class<SongEvent>> = ClassMacro.listSubclassesOf(SongEvent);

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
      if (eventClsName == 'funkin.play.event.SongEvent' || eventClsName == 'funkin.play.event.ScriptedSongEvent') continue;

      var event:SongEvent = Type.createInstance(eventCls, ["UNKNOWN"]);

      if (event != null)
      {
        trace(' Loaded built-in song event: ${event.id}');
        eventCache.set(event.id, event);
      }
      else
      {
        trace(' Failed to load built-in song event: ${Type.getClassName(eventCls)}');
      }
    }
  }

  static function registerScriptedEvents()
  {
    var scriptedEventClassNames:Array<String> = ScriptedSongEvent.listScriptClasses();
    trace('Instantiating ${scriptedEventClassNames.length} scripted song events...');
    if (scriptedEventClassNames == null || scriptedEventClassNames.length == 0) return;

    for (eventCls in scriptedEventClassNames)
    {
      var event:SongEvent = ScriptedSongEvent.init(eventCls, "UKNOWN");

      if (event != null)
      {
        trace(' Loaded scripted song event: ${event.id}');
        eventCache.set(event.id, event);
      }
      else
      {
        trace(' Failed to instantiate scripted song event class: ${eventCls}');
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

  public static function getEvent(id:String):Null<SongEvent>
  {
    return eventCache.get(id);
  }

  public static function getEventSchema(id:String):Null<SongEventSchema>
  {
    var event:Null<SongEvent> = getEvent(id);
    if (event == null) return null;

    return event.getEventSchema();
  }

  static function clearEventCache()
  {
    eventCache.clear();
  }

  public static function handleEvent(data:SongEventData):Void
  {
    var eventHandler:Null<SongEvent> = getEvent(data.eventKind);

    if (eventHandler != null)
    {
      eventHandler.handleEvent(data);
    }
    else
    {
      trace('WARNING: No event handler for event with kind: ${data.eventKind}');
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
   * @param events The list of available song events.
   * @param currentTime The current time in milliseconds.
   * @return The list of events which haven't been handled yet.
   */
  public static function queryEvents(events:Array<SongEventData>, currentTime:Float):Array<SongEventData>
  {
    var result:Array<SongEventData> = events.filter(function(event:SongEventData):Bool {
      // If the event is already activated, don't activate it again.
      if (event.activated) return false;

      // If the event is in the future, don't activate it.
      if (event.time > currentTime) return false;

      return true;
    });

    result.sort(SortUtil.eventDataByTime.bind(FlxSort.ASCENDING));

    return result;
  }

  /**
   * The currentTime has jumped far ahead or back.
   * If we moved back in time, we need to reset all the events in that space.
   * If we moved forward in time, we need to skip all the events in that space.
   */
  public static function handleSkippedEvents(events:Array<SongEventData>, currentTime:Float):Void
  {
    for (event in events)
    {
      // Deactivate future events.
      if (event.time > currentTime)
      {
        event.activated = false;
      }

      // Skip past events.
      if (event.time < currentTime)
      {
        event.activated = true;
      }
    }
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
