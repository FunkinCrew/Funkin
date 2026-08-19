package funkin.data.event;

import flixel.util.FlxSort;
import funkin.data.BaseRegistry.LoadEntriesResult;
import funkin.data.song.SongData.SongEventData;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.event.SongEvent;
import funkin.util.SortUtil;
import funkin.util.macro.ClassMacro;
import funkin.util.tasks.TaskHandler;
import funkin.util.tasks.TaskHandler.Task;
import lime.app.Promise;
#if FEATURE_MULTITHREADING
import hx.concurrent.collection.SynchronizedArray;
import hx.concurrent.collection.SynchronizedMap;
#end

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
  #if FEATURE_MULTITHREADING
  static final BUILTIN_EVENTS:SynchronizedArray<Class<SongEvent>> = new SynchronizedArray<Class<SongEvent>>(
    ClassMacro.listSubclassesOf(SongEvent).filter((cls:Class<SongEvent>) -> !['funkin.play.event.SongEvent'].contains(Type.getClassName(cls)))
  );
  #else
  static final BUILTIN_EVENTS:Array<Class<SongEvent>> = ClassMacro
    .listSubclassesOf(SongEvent)
    .filter((cls:Class<SongEvent>) -> !['funkin.play.event.SongEvent'].contains(Type.getClassName(cls)));
  #end
  /**
   * Map of internal handlers for song events.
   * These may be either `ScriptedSongEvents` or built-in classes extending `SongEvent`.
   */
  #if FEATURE_MULTITHREADING
  static final EVENT_CACHE:SynchronizedMap<String, SongEvent> = SynchronizedMap.newStringMap();
  #else
  static final EVENT_CACHE:Map<String, SongEvent> = new Map<String, SongEvent>();
  #end

  /**
   * Instantiate the singleton instances of every song event handler class.
   */
  public static function loadEventCache():Void
  {
    clearEventCache();

    trace('Instantiating ${BUILTIN_EVENTS.length} built-in song events...');
    for (eventCls in BUILTIN_EVENTS)
    {
      var event:SongEvent = Type.createInstance(eventCls, ['UNKNOWN']);

      if (event != null)
      {
        trace(' Loaded built-in song event: ${event.id}');
        EVENT_CACHE.set(event.id, event);
      }
      else
      {
        trace(' Failed to load built-in song event: ${eventCls}');
      }
    }

    var scriptedEventClassNames:Array<String> = SongEvent.listScriptClasses();
    trace('Instantiating ${scriptedEventClassNames.length} scripted song events...');
    if (scriptedEventClassNames == null || scriptedEventClassNames.length == 0) return;

    for (eventCls in scriptedEventClassNames)
    {
      var event:Null<SongEvent> = SongEvent.scriptInit(eventCls, 'UKNOWN');

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

  #if FEATURE_MULTITHREADING
  public static function loadEventCacheAsync():lime.app.Future<LoadEntriesResult>
  {
    clearEventCache();

    var perf:funkin.util.logging.Perf = new funkin.util.logging.Perf('loadEventCacheAsync');
    var promise:lime.app.Promise<LoadEntriesResult> = new lime.app.Promise<LoadEntriesResult>();
    var entryErrors:SynchronizedArray<
      {eventId:String, error:Any, ?eventCls:String}> = new SynchronizedArray();

    var entryCount:Int = 0;
    var scriptedEventClassNames:SynchronizedArray<String> = new SynchronizedArray<String>();
    var loadedBaseEvents:Bool = false;

    var loadBaseEventsAsync:Void->Void = () -> {};
    var loadScriptedEventsAsync:Void->Void = () -> {};

    var checkAsyncProgress:Void->Void = () ->
    {
      var current:Int = EVENT_CACHE.size() + entryErrors.length;
      if (current == entryCount)
      {
        if (!loadedBaseEvents)
        {
          // Start loading scripted events now.
          loadedBaseEvents = true;
          loadScriptedEventsAsync();
          trace('Finished loading built-in song events (1/2) ($current / $entryCount)');
        }
        else
        {
          trace('Finished loading scripted song events (2/2) ($current / $entryCount)');
          promise.complete({
            entriesLoaded: EVENT_CACHE.size(),
            entriesFailed: entryErrors.length
          });
          perf.print();
        }
      }
    }

    // Callback when one task completes with failure
    var onError:(String,
      {error:Any, eventCls:Null<String>}) -> Void = (eventId, state) ->
      {
        entryErrors.push({
          eventId: eventId,
          error: state.error
        });
        trace('  Failed to load song event (${eventId}): ${state.error}');
        checkAsyncProgress();
      };

    var performLoadScriptedEvent:Task = (currentState:State, workOutput:WorkOutput) ->
    {
      var eventCls:String = currentState.eventCls;
      try
      {
        var event:Null<SongEvent> = SongEvent.scriptInit(eventCls, 'UNKNOWN');
        if (event != null)
        {
          workOutput.sendComplete({
            event: event,
            eventCls: eventCls
          }, []);
        }
        else
        {
          workOutput.sendError({
            eventCls: eventCls,
            error: 'Failed to create scripted song event (${eventCls})'
          });
        }
      }
      catch (e)
      {
        workOutput.sendError({
          eventCls: eventCls,
          error: e,
        });
      }
    }

    // Task to perform for each unscripted entry
    var performLoadBaseEvent:Task = (currentState:State, workOutput:WorkOutput) ->
    {
      var eventCls:Class<SongEvent> = currentState.eventCls;
      try
      {
        var event:Null<SongEvent> = Type.createInstance(eventCls, ['UNKNOWN']);
        if (event != null)
        {
          workOutput.sendComplete({
            event: event
          }, []);
        }
        else
        {
          workOutput.sendError({
            eventId: currentState.eventId,
            error: 'Failed to create song event (${currentState.eventId})'
          });
        }
      }
      catch (e)
      {
        workOutput.sendError({
          eventId: currentState.eventId,
          error: e
        });
      }
    }

    // Callback when one task completes with success
    var onBaseEventLoadedAsync:(String,
      {event:SongEvent}) -> Void = (eventId, state) ->
      {
        EVENT_CACHE.set(state.event.id, state.event);
        trace(' Loaded song event: ${state.event.id}');
        checkAsyncProgress();
      };

    var onScriptedEventLoadedAsync:(String,
      {event:SongEvent, eventCls:String}) -> Void = (_, state) ->
      {
        var eventId:String = state.event.id;
        EVENT_CACHE.set(eventId, state.event);

        trace('  Loaded scripted song event: ${eventId} (${state.eventCls}) (${EVENT_CACHE.size()} + ${entryErrors.length} / ${entryCount})');
        checkAsyncProgress();
      };

    loadScriptedEventsAsync = () ->
    {
      scriptedEventClassNames = new SynchronizedArray<String>(SongEvent.listScriptClasses());
      entryCount = EVENT_CACHE.size() + scriptedEventClassNames.length;

      trace('Instantiating ${scriptedEventClassNames.length} scripted song events...');

      if (scriptedEventClassNames.length == 0)
      {
        checkAsyncProgress();
      }
      else
      {
        for (eventCls in scriptedEventClassNames)
        {
          var loadScriptedEventFuture = TaskHandler.performTask({
            task: performLoadScriptedEvent,
            initialState: {
              eventCls: eventCls
            }
          }, new Promise<
            {
              event:SongEvent,
              eventCls:String
            }>());
          loadScriptedEventFuture.onError(onError.bind(eventCls));
          loadScriptedEventFuture.onComplete(onScriptedEventLoadedAsync.bind(eventCls));
        }
      }
    }

    // Start loading base events first.
    loadBaseEventsAsync = () ->
    {
      entryCount = BUILTIN_EVENTS.length;
      trace('Instantiating ${entryCount} built-in song events...');

      if (BUILTIN_EVENTS.length == 0)
      {
        checkAsyncProgress();
      }
      else
      {
        for (event in BUILTIN_EVENTS)
        {
          var eventId:String = Type.getClassName(event);

          var loadBaseEventFuture = TaskHandler.performTask({
            task: performLoadBaseEvent,
            initialState: {
              eventCls: event,
              eventId: eventId,
            }
          }, new Promise<
            {
              event:SongEvent
            }>());

          loadBaseEventFuture.onError(onError.bind(eventId));
          loadBaseEventFuture.onComplete(onBaseEventLoadedAsync.bind(eventId));
        }
      }
    }

    // Start loading base events first.
    loadBaseEventsAsync();

    return promise.future;
  }
  #end

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
    // MapTools doesn't work for SynchronizedMap shrug
    // *mercy.gif* SynchronizedMapTools
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

    return funkin.modding.ScriptGuard.get(event, 'a request for the "$id" event schema', event.getEventSchema, null);
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
      funkin.modding.ScriptGuard.run(eventHandler, 'the "${data.eventKind}" song event', () -> eventHandler.handleEvent(data));
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
