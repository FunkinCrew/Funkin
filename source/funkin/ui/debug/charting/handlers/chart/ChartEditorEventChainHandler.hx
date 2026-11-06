package funkin.ui.debug.charting.handlers.chart;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongEventData;
using Lambda;

@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorEventChainHandler
{
  static final CHAIN_STEP_PRECISION:Float = 1000;

  /**
   * Which spot an event is on
   */
  public static function eventChainKey(state:ChartEditorState, event:SongEventData):Int
  {
    return Math.round(Conductor.instance.getTimeInSteps(event.time) * CHAIN_STEP_PRECISION);
  }

  /**
   * Every event in the same chain as an event, including it, in chart order.
   */
  public static function eventChainOf(state:ChartEditorState, event:SongEventData):Array<SongEventData>
  {
    var key:Int = state.eventChainKey(event);
    var chain:Array<SongEventData> = [for (other in state.currentSongChartEventData) if (other == event || state.eventChainKey(other) == key) other];
    if (!chain.contains(event)) chain.push(event);
    return chain;
  }

  /**
   * The events given, plus every event in a chain with any of them.
   */
  public static function withEventChains(state:ChartEditorState, events:Array<SongEventData>):Array<SongEventData>
  {
    if (events.length == 0) return events;
    var result:Array<SongEventData> = [];
    for (event in events)
    {
      for (member in state.eventChainOf(event)) if (!result.contains(member)) result.push(member);
    }
    return result;
  }

  /**
   * Whether the events are all one chain, or one event on its own.
   */
  public static function isOneEventChain(state:ChartEditorState, events:Array<SongEventData>):Bool
  {
    if (events.length == 0) return false;
    var key:Int = state.eventChainKey(events[0]);
    for (event in events) if (state.eventChainKey(event) != key) return false;
    return true;
  }

  public static function rebuildEventChains(state:ChartEditorState):Void
  {
    state.eventChainFollowers.clear();
    state.eventChainRest.clear();
    var sorted:Array<SongEventData> = [for (event in state.currentSongChartEventData) if (event != null) event];
    haxe.ds.ArraySort.sort(sorted, (a, b) -> a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
    var leader:Null<SongEventData> = null;
    var leaderKey:Int = 0;
    for (event in sorted)
    {
      var key:Int = state.eventChainKey(event);
      if (leader != null && key == leaderKey)
      {
        state.eventChainFollowers.set(event, true);
        state.eventChainRest.get(leader).push(event);
      }
      else
      {
        leader = event;
        leaderKey = key;
        state.eventChainRest.set(leader, []);
      }
    }
  }

  public static function isEventSelected(state:ChartEditorState, event:Null<SongEventData>):Bool
  {
    return event != null && state.currentEventSelection.indexOf(event) != -1;
  }

  public static function isEventInvalidated(state:ChartEditorState, event:Null<SongEventData>, force:Bool = false):Bool
  {
    if (event == null) return false;

    // Events are shared with every difficulty, validate against all of them.
    var errors:Array<String> = state.currentSongChartData.validateChartEvent(event);

    // Cache the errors we found to avoid spam.
    @:privateAccess
    event.cacheValidationErrors(errors);

    // No errors.
    return errors.length > 0;
  }
}
#end
