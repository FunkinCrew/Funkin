package funkin.play.event;

import funkin.data.event.SongEventSchema;
import funkin.data.song.SongData.SongEventData;
import funkin.Conductor;
import funkin.modding.events.ScriptEvent.CustomEventScriptEvent;
import funkin.play.PlayState;

/**
 * A named custom event that allows for custom progress handling.
 *
 * ```haxe
 * override function onCustomEvent(event:CustomEventScriptEvent):Void
 * {
 *   super.onCustomEvent(event);
 *   switch (event.name)
 *   {
 *     case 'fadeOut':
 *       cover.alpha = 1 - event.eased;
 *   }
 * }
 * ```
 */
class CustomSongEvent extends SongEvent
{
  public static inline var KIND:String = 'CustomEvent';
  public static inline var PARAMS_FIELD:String = 'params';

  public static function nameOf(data:SongEventData):String
  {
    if (data.eventKind != KIND) return '';
    return data.getString('name') ?? '';
  }

  public static function paramsOf(data:SongEventData):Array<CustomEventParam>
  {
    return readParams(data.getDynamic(PARAMS_FIELD));
  }

  public static function readParams(raw:Dynamic):Array<CustomEventParam>
  {
    var result:Array<CustomEventParam> = [];
    if (raw == null || !Std.isOfType(raw, Array)) return result;
    var list:Array<Dynamic> = cast raw;
    for (entry in list)
    {
      if (entry == null) continue;
      var name:Dynamic = Reflect.field(entry, 'name');
      var value:Dynamic = Reflect.field(entry, 'value');
      result.push({name: name != null ? Std.string(name) : '', value: value != null ? Std.string(value) : ''});
    }
    return result;
  }

  public static function copyParams(params:Array<CustomEventParam>):Array<CustomEventParam>
  {
    return [for (param in params) {name: param.name, value: param.value}];
  }

  public static function param(data:SongEventData, name:String):Null<String>
  {
    for (entry in paramsOf(data))
    {
      if (entry.name == name) return entry.value;
    }
    return null;
  }

  public static function paramFloat(data:SongEventData, name:String, defaultValue:Float = 0):Float
  {
    var text:Null<String> = param(data, name);
    if (text == null) return defaultValue;
    var value:Float = Std.parseFloat(text);
    return Math.isNaN(value) ? defaultValue : value;
  }

  public static function paramInt(data:SongEventData, name:String, defaultValue:Int = 0):Int
  {
    var text:Null<String> = param(data, name);
    if (text == null) return defaultValue;
    return Std.parseInt(text) ?? defaultValue;
  }

  public static function paramBool(data:SongEventData, name:String, defaultValue:Bool = false):Bool
  {
    var text:Null<String> = param(data, name);
    if (text == null) return defaultValue;
    return ['true', 'yes', 'on', '1'].contains(StringTools.trim(text).toLowerCase());
  }

  // If you want to use a list just separate the values with commas.
  // "true (true.gif), false (false.gif)"
  public static function paramList(data:SongEventData, name:String):Array<String>
  {
    var text:Null<String> = param(data, name);
    if (text == null || StringTools.trim(text).length == 0) return [];
    return [for (part in text.split(',')) StringTools.trim(part)];
  }

  public static function paramBoolList(data:SongEventData, name:String):Array<Bool>
  {
    return [for (part in paramList(data, name)) ['true', 'yes', 'on', '1'].contains(part.toLowerCase())];
  }

  public static function paramFloatList(data:SongEventData, name:String):Array<Float>
  {
    var result:Array<Float> = [];
    for (part in paramList(data, name))
    {
      var value:Float = Std.parseFloat(part);
      result.push(Math.isNaN(value) ? 0 : value);
    }
    return result;
  }

  public function new()
  {
    super(KIND, {
      processOldEvents: true
    });
  }

  static var tagCache:Map<String, String> = [];

  public static function tagFor(name:Null<String>):String
  {
    if (name == null) return '';
    var cached:Null<String> = tagCache.get(name);
    if (cached != null) return cached;
    var tag:String = buildTag(name);
    tagCache.set(name, tag);
    return tag;
  }

  static function buildTag(name:Null<String>):String
  {
    if (name == null) return '';
    var words:Array<String> = ~/[^A-Za-z0-9]+/g.split(name).filter(word -> word.length > 0); // words with spaces
    if (words.length == 1) words = ~/([a-z0-9])(?=[A-Z])/g.replace(words[0], '$1 ').split(' '); // camelCase
    if (words.length == 0) return '';
    if (words.length == 1) return words[0].substr(0, 2).toUpperCase();
    return (words[0].charAt(0) + words[1].charAt(0)).toUpperCase();
  }

  override public function calculateActivationTime(data:SongEventData, conductor:Conductor):Float
  {
    return super.calculateActivationTime(data, conductor) + (data.getFloat('offset') ?? 0);
  }

  override public function handleEvent(data:SongEventData):Void
  {
    PlayState.instance?.customEvents.start(data);
  }

  public static function durationStepsOf(data:SongEventData):Float
  {
    return Math.max(0, data.getFloat('duration') ?? 0);
  }

  public static function easeOf(data:SongEventData):Float->Float
  {
    var ease:String = data.getString('ease') ?? 'linear';
    if (ease == 'linear') return flixel.tweens.FlxEase.linear;
    var dir:String = data.getString('easeDir') ?? 'InOut';
    var func:Null<Float->Float> = Reflect.field(flixel.tweens.FlxEase, ease + dir);
    return func ?? flixel.tweens.FlxEase.linear;
  }

  override public function getTitle():String
  {
    return 'Custom Event';
  }

  override public function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'name',
        title: 'Name',
        defaultValue: '',
        type: SongEventFieldType.STRING
      },
      {
        name: 'offset',
        title: 'Activation Offset',
        defaultValue: 0,
        step: 1,
        type: SongEventFieldType.FLOAT,
        units: 'ms'
      },
      {
        name: 'duration',
        title: 'Duration',
        defaultValue: 0,
        min: 0,
        step: 0.5,
        type: SongEventFieldType.FLOAT,
        units: 'steps'
      },
      {
        name: 'ease',
        title: 'Easing Type',
        defaultValue: 'linear',
        type: SongEventFieldType.ENUM,
        keys: [
          'Linear' => 'linear',
          'Sine' => 'sine',
          'Quad' => 'quad',
          'Cube' => 'cube',
          'Quart' => 'quart',
          'Quint' => 'quint',
          'Expo' => 'expo',
          'Smooth Step' => 'smoothStep',
          'Smoother Step' => 'smootherStep',
          'Elastic' => 'elastic',
          'Back' => 'back',
          'Bounce' => 'bounce',
          'Circ' => 'circ'
        ]
      },
      {
        name: 'easeDir',
        title: 'Easing Direction',
        defaultValue: 'InOut',
        type: SongEventFieldType.ENUM,
        keys: ['In' => 'In', 'Out' => 'Out', 'In/Out' => 'InOut']
      }
    ]);
  }
}

typedef CustomEventParam =
{
  var name:String;
  var value:String;
}

/**
 * Tracks active custom events and dispatches their script events.
 */
class CustomEventRunner
{
  var active:Array<RunningCustomEvent> = [];

  public function new() {}

  public function clear():Void
  {
    active = [];
  }

  public function start(data:SongEventData, ?conductor:Conductor):Void
  {
    var conductor:Conductor = conductor ?? Conductor.instance;
    var startMs:Float = data.getActivationTime(conductor);
    var steps:Float = CustomSongEvent.durationStepsOf(data);
    var endMs:Float = steps > 0 ? conductor.getStepTimeInMs(conductor.getTimeInSteps(startMs) + steps) : startMs;
    active.push({data: data, startMs: startMs, endMs: endMs, started: false});
  }

  public function update(songMs:Float, dispatch:CustomEventScriptEvent->Void, isReplay:Bool = false, ?finished:Bool):Void
  {
    if (active.length == 0) return;
    var running:Array<RunningCustomEvent> = active.copy();
    for (entry in running)
    {
      if (songMs < entry.startMs)
      {
        if (entry.started) active.remove(entry);
        continue;
      }
      var durationMs:Float = entry.endMs - entry.startMs;
      var progress:Float = durationMs > 0 ? Math.min(1, Math.max(0, (songMs - entry.startMs) / durationMs)) : 1;
      var isLast:Bool = progress >= 1;
      if (finished != null && finished != isLast) continue;
      var eased:Float = isLast ? 1 : CustomSongEvent.easeOf(entry.data)(progress);
      var isFirst:Bool = !entry.started;
      entry.started = true;
      if (isLast) active.remove(entry);
      dispatch(new CustomEventScriptEvent(entry.data, progress, eased, Math.max(0, songMs - entry.startMs), durationMs, isFirst, isLast, isReplay));
    }
  }
}

typedef RunningCustomEvent =
{
  var data:SongEventData;
  var startMs:Float;
  var endMs:Float;
  var started:Bool;
}
