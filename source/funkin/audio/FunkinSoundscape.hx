package funkin.audio;

import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.util.FlxTimer;

/**
 * Settings for a `FunkinSoundscape`
 */
typedef FunkinSoundscapeSettings =
{
  /**
   * The base ambience path.
   */
  var baseAmbiencePath:String;

  /**
   * The folder containing the random sound files.
   */
  var randomSoundPath:String;

  /**
   * The amount of time in seconds before random sounds can start playing.
   */
  var randomSoundWait:Float;

  /**
   * A random time range in seconds to wait before playing another random sound.
   */
  var randomTimeRange:FlxPoint;

  /**
   * The amount of time in seconds to fade in the ambience.
   */
  var fadeInTime:Float;
}

/**
 * `FunkinSoundscape` is a base class for... a soundscape.
 * It plays a base ambience, and random sound effects from a given pool.
 */
@:nullSafety
class FunkinSoundscape implements IFlxDestroyable
{
  /**
   * The parameters for this soundscape.
   */
  public var params:FunkinSoundscapeSettings;

  /**
   * The list of available sounds.
   * This is loaded from the folder specified when a new instance.
   *
   * Each file follows a unique naming convention:
   * - `{weight}_{sound-name}.ogg`
   *
   * The weight is the chance that the sound will play.
   * A higher weight will make the sound more likely to play.
   */
  public var soundList:Array<String> = [];

  var weights:Array<Float> = [];
  var _currentSFX:Null<FunkinSound> = null;
  var _usedInGroup:Map<String, Array<String>> = [];

  public function new(params:FunkinSoundscapeSettings)
  {
    this.params = params;

    var paths:Array<String> = Assets.list().filter((path) ->
    {
      return path.contains(params.randomSoundPath) && path.endsWith(Constants.EXT_SOUND);
    });

    // Sorts the paths by weight from lowest to highest
    paths.sort((a, b) ->
    {
      var aName:String = a.substring(a.lastIndexOf('/') + 1);
      var bName:String = b.substring(b.lastIndexOf('/') + 1);
      var aWeight:Null<Int> = weightOf(a);
      var bWeight:Null<Int> = weightOf(b);

      if (aWeight != bWeight && aWeight != null && bWeight != null)
      {
        return aWeight < bWeight ? -1 : aWeight > bWeight ? 1 : 0;
      }

      return aName < bName ? -1 : aName > bName ? 1 : 0;
    });

    paths.reverse();

    soundList = paths.filter((path) ->
    {
      var weight:Null<Int> = weightOf(path);
      if (weight != null && weight > 0)
      {
        weights.push(weight);
        return true;
      }

      return false;
    });
  }

  /**
   * Plays the ambience.
   * Waits 7 seconds before pulling a random sound from the list.
   */
  public function initialize():Void
  {
    FunkinSound.playMusic(params.baseAmbiencePath, {
      startingVolume: 0.0,
      overrideExisting: true,
      restartTrack: true
    });

    FlxG.sound.music.fadeIn(4.0, 0.0, 1.0, onSoundFadeIn);
  }

  /**
   * Pulls a random sound from the list and plays it.
   */
  public function playRandomSound():Void
  {
    if (soundList.length == 0) return;

    var candidates:Array<String> = soundList.filter((s) ->
    {
      var g:String = groupOf(s);
      var usedList:Null<Array<String>> = _usedInGroup.get(g);
      return usedList == null || usedList.indexOf(s) == -1;
    });
    var candidateWeights:Array<Float> = candidates.map((s) -> weights[soundList.indexOf(s)]);

    var randomSound:String = FlxG.random.getObject(candidates, candidateWeights);
    if (randomSound == null) return;

    var group:String = groupOf(randomSound);
    var groupSounds:Array<String> = soundList.filter((s) -> groupOf(s) == group);
    var used:Array<String> = _usedInGroup.get(group) ?? [];
    used.push(randomSound);
    used = (used.length >= groupSounds.length) ? [] : used;
    _usedInGroup.set(group, used);

    _currentSFX = FunkinSound.playOnce(randomSound, 1.0, () ->
    {
      FlxTimer.wait(FlxG.random.float(params.randomTimeRange.x, params.randomTimeRange.y), () ->
      {
        playRandomSound();
      });
    });
  }

  /**
   * @return The base name for a sound.
   * (ex. `beep1` and `beep2` both return `beep`),
   */
  function groupOf(path:String):String
  {
    var name:String = path.substring(path.lastIndexOf('/') + 1);
    name = name.substring(name.indexOf('_') + 1, name.lastIndexOf('.'));
    return ~/[0-9]+$/.replace(name, '');
  }

  /**
   * @return The weight of a sound.
   * (ex. assets/ui/mods/sounds/600_beep1.ogg -> 600)
   */
  function weightOf(path:String):Null<Int>
  {
    var name:String = path.substring(path.lastIndexOf('/') + 1);
    var weight:Null<Int> = Std.parseInt(name.split('_')[0]);

    return weight;
  }

  function onSoundFadeIn(tween:FlxTween):Void
  {
    // Wait however long the timer is before pulling a random sound from the list.
    FlxTimer.wait(params.randomSoundWait, () ->
    {
      playRandomSound();
    });
  }

  /**
   * Destroys the ambience.
   */
  public function destroy():Void
  {
    // Failsafe to make sure that no random sounds play when the Soundscape is destroyed.
    FlxTimer.globalManager.clear();

    if (_currentSFX != null) _currentSFX.destroy();
  }
}
