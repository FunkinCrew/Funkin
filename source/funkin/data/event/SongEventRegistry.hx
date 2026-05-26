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
  static final EVENT_CACHE:Map<String, SongEvent> = new Map<String, SongEvent>();

  /**
   * Instantiate the singleton instances of every song event handler class.
   */
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

      var event:SongEvent = Type.createInstance(eventCls, ['UNKNOWN']);

      if (event != null)
      {
        trace(' Loaded built-in song event: ${event.id}');
        EVENT_CACHE.set(event.id, event);
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
      var event:SongEvent = ScriptedSongEvent.scriptInit(eventCls, 'UKNOWN');

      if (event != null)
      {
        trace(' Loaded scripted song event: ${event.id}');
        EVENT_CACHE.set(event.id, event);
      }
      else
      {
        trace(' Failed to instantiate scripted song event class: ${eventCls}');
      }
    }
  }

  /**
   * @return A list of IDs for every song event handler class.
   */
  public static function listEventIds():Array<String>
  {
    return EVENT_CACHE.keys().array();
  }

  /**
   * @return A list of every song event handler class singleton.
   */
  public static function listEvents():Array<SongEvent>
  {
    return EVENT_CACHE.values();
  }

  /**
   * Retrieve the song event handler singleton instance, based on the given ID.
   *
   * @param id The ID of the event handler to retrieve.
   * @return The song event handler instance, or `null` if none exists for that type.
   */
  public static function getEvent(id:String):Null<SongEvent>
  {
    return EVENT_CACHE.get(id);
  }

  /**
   * Retrieve the song event schema, based on the ID.
   * The schema provides data to build the form for the event panel in the chart editor.
   *
   * @param id The ID of the event to retrieve the schema for.
   * @return The song event schema data.
   */
  public static function getEventSchema(id:String):Null<SongEventSchema>
  {
    var event:Null<SongEvent> = getEvent(id);
    if (event == null) return null;

    return event.getEventSchema();
  }

  static function clearEventCache():Void
  {
    EVENT_CACHE.clear();
  }

  /**
   * Activate the song event handler for the provided event.
   *
   * @param data The song event to process.
   */
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

  /**
   * Activate the song event handler for all the provided events.
   *
   * @param events The list of song events to process.
   */
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

    for (index => event in events)
    {
      if (event.activated) continue;

      var activationTime:Float = event.getActivationTime();

      if (activationTime > currentTime)
      {
        nextEventIndex = index;
        return result;
      }

      result.push(event);
    }

    return result;
  }

  /**
   * The currentTime has jumped far ahead or back.
   * If we moved back in time, we need to reset all the events in that space.
   * If we moved forward in time, we need to skip all the events in that space.
   *
   * @param events The list of song events to process.
   * @param currentTime The new conductor timestamp, in milliseconds.
   */
  public static function handleSkippedEvents(events:Array<SongEventData>, currentTime:Float):Void
  {
    for (event in events)
    {
      var activationTime:Float = event.getActivationTime();

      // Deactivate future events.
      if (activationTime > currentTime)
      {
        event.activated = false;
      }

      // Skip past events.
      if (activationTime < currentTime)
      {
        event.activated = true;
      }
    }
  }

  /**
   * Reset activation of all the provided events.
   * This is useful when restarting a song.
   *
   * @param events The list of events to reset.
   */
  public static function resetEvents(events:Array<SongEventData>):Void
  {
    // Ensure each
    events.sort(SortUtil.eventDataByActivationTime.bind(FlxSort.ASCENDING));
    nextEventIndex = 0;
    allEventHandlers.resize(0);

    for (event in events)
    {
      event.activated = false;

      var handler:Null<SongEvent> = getEvent(event.eventKind);
      if (handler != null) allEventHandlers.pushUnique(handler);
    }
  }

  static var allEventHandlers:Array<SongEvent> = [];

  /**
   * Dispatch script events to every Song Event handler associated with events in the current song.
   * This means that `onUpdate`, `onBeatHit`, `onStepHit`, and more will be called for every `SongEvent` handler class.
   *
   * @param scriptEvent The script event to dispatch.
   */
  public static inline function callEvent(scriptEvent:ScriptEvent):Void
  {
    for (event in allEventHandlers)
    {
      ScriptEventDispatcher.callEvent(event, scriptEvent);
    }
  }
}
