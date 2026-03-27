package funkin.data.event;

import flixel.util.FlxSort;
import funkin.data.song.SongData.SongEventData;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.event.ScriptedSongEvent;
import funkin.play.event.SongEvent;
import funkin.util.SortUtil;
import funkin.util.macro.ClassMacro;

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
      var event:SongEvent = ScriptedSongEvent.scriptInit(eventCls, "UKNOWN");

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
   * Caching the index for the next event to query greatly reduces lag.
   * Kinda nasty that it's tied to a static class though.
   */
  static var nextEventIndex:Int = 0;

  /**
   * Retrieve the list of events to activate this frame.
   *
   * @param events The list of available song events.
   * @param currentTime The current time in milliseconds.
   * @param startIndex The index to start querying from.
   *   Defaults to the index of the last event handled.
   * @return The list of events which haven't been handled yet.
   */
  public static function queryEvents(events:Array<SongEventData>, currentTime:Float, ?startIndex:Int):Array<SongEventData>
  {
    startIndex ??= nextEventIndex;

    var result:Array<SongEventData> = [];

    for (i in startIndex...events.length)
    {
      if (events[i].activated) continue;

      if (events[i].time > currentTime)
      {
        nextEventIndex = i;
        return result;
      }

      result.push(events[i]);
    }

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
    events.sort(SortUtil.eventDataByTime.bind(FlxSort.ASCENDING));
    nextEventIndex = 0;
    allEventHandlers.resize(0);

    for (event in events)
    {
      event.activated = false;

      var handler:Null<SongEvent> = getEvent(event.eventKind);
      if (handler != null && !allEventHandlers.contains(handler)) allEventHandlers.push(handler);
    }
  }

  static var allEventHandlers:Array<SongEvent> = [];

  public static inline function callEvent(scriptEvent:ScriptEvent):Void
  {
    for (event in allEventHandlers)
    {
      ScriptEventDispatcher.callEvent(event, scriptEvent);
    }
  }
}
