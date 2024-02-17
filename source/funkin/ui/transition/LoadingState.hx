package funkin.ui.transition;

import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import funkin.graphics.shaders.ScreenWipeShader;
import funkin.play.PlayState;
import funkin.play.PlayStatePlaylist;
import funkin.play.song.Song.SongDifficulty;
import funkin.ui.MusicBeatState;
import haxe.io.Path;
import funkin.graphics.FunkinSprite;
import lime.app.Future;
import lime.app.Promise;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.Assets as LimeAssets;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets;
import flixel.util.typeLimit.NextState;

class LoadingState extends MusicBeatState
{
  inline static var MIN_TIME = 1.0;

  var target:NextState;
  var playParams:Null<PlayStateParams>;
  var stopMusic:Bool = false;
  var callbacks:MultiCallback;
  var danceLeft:Bool = false;

  var loadBar:FlxSprite;
  var funkay:FlxSprite;

  function new(target:NextState, stopMusic:Bool, playParams:Null<PlayStateParams> = null)
  {
    super();
    this.target = target;
    this.playParams = playParams;
    this.stopMusic = stopMusic;
  }

  override function create():Void
  {
    var bg:FlxSprite = new FunkinSprite().makeSolidColor(FlxG.width, FlxG.height, 0xFFcaff4d);
    add(bg);

    funkay = new FlxSprite();
    funkay.loadGraphic(Paths.image('funkay'));
    funkay.setGraphicSize(0, FlxG.height);
    funkay.updateHitbox();
    add(funkay);
    funkay.scrollFactor.set();
    funkay.screenCenter();

    loadBar = new FunkinSprite(0, FlxG.height - 20).makeSolidColor(FlxG.width, 10, 0xFFff16d2);
    loadBar.screenCenter(X);
    add(loadBar);

    initSongsManifest().onComplete(function(lib) {
      callbacks = new MultiCallback(onLoad);
      var introComplete = callbacks.add('introComplete');

      if (playParams != null)
      {
        // Load and cache the song's charts.
        if (playParams.targetSong != null)
        {
          playParams.targetSong.cacheCharts(true);
        }

        // Preload the song for the play state.
        var difficulty:String = playParams.targetDifficulty ?? Constants.DEFAULT_DIFFICULTY;
        var variation:String = playParams.targetVariation ?? Constants.DEFAULT_VARIATION;
        var targetChart:SongDifficulty = playParams.targetSong?.getDifficulty(difficulty, variation);
        var instPath:String = Paths.inst(targetChart.song.id);
        var voicesPaths:Array<String> = targetChart.buildVoiceList();

        checkLoadSong(instPath);
        for (voicePath in voicesPaths)
        {
          checkLoadSong(voicePath);
        }
      }

      checkLibrary('shared');
      checkLibrary(PlayStatePlaylist.campaignId);
      checkLibrary('tutorial');

      var fadeTime:Float = 0.5;
      FlxG.camera.fade(FlxG.camera.bgColor, fadeTime, true);
      new FlxTimer().start(fadeTime + MIN_TIME, function(_) introComplete());
    });
  }

  function checkLoadSong(path:String):Void
  {
    if (!Assets.cache.hasSound(path))
    {
      var library = Assets.getLibrary('songs');
      var symbolPath = path.split(':').pop();
      // @:privateAccess
      // library.types.set(symbolPath, SOUND);
      // @:privateAccess
      // library.pathGroups.set(symbolPath, [library.__cacheBreak(symbolPath)]);
      var callback = callbacks.add('song:' + path);
      Assets.loadSound(path).onComplete(function(_) {
        callback();
      });
    }
  }

  function checkLibrary(library:String):Void
  {
    trace(Assets.hasLibrary(library));
    if (Assets.getLibrary(library) == null)
    {
      @:privateAccess
      if (!LimeAssets.libraryPaths.exists(library)) throw 'Missing library: ' + library;

      var callback = callbacks.add('library:' + library);
      Assets.loadLibrary(library).onComplete(function(_) {
        callback();
      });
    }
  }

  override function beatHit():Bool
  {
    // super.beatHit() returns false if a module cancelled the event.
    if (!super.beatHit()) return false;

    danceLeft = !danceLeft;

    return true;
  }

  var targetShit:Float = 0;

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    funkay.setGraphicSize(Std.int(FlxMath.lerp(FlxG.width * 0.88, funkay.width, 0.9)));
    funkay.updateHitbox();
    // funkay.updateHitbox();

    if (controls.ACCEPT)
    {
      funkay.setGraphicSize(Std.int(funkay.width + 60));
      funkay.updateHitbox();
      // funkay.setGraphicSize(0, Std.int(funkay.height + 50));
      // funkay.updateHitbox();
      // funkay.screenCenter();
    }

    if (callbacks != null)
    {
      targetShit = FlxMath.remapToRange(callbacks.numRemaining / callbacks.length, 1, 0, 0, 1);

      loadBar.scale.x = FlxMath.lerp(loadBar.scale.x, targetShit, 0.50);
      FlxG.watch.addQuick('percentage?', callbacks.numRemaining / callbacks.length);
    }

    #if debug
    if (FlxG.keys.justPressed.SPACE) trace('fired: ' + callbacks.getFired() + ' unfired:' + callbacks.getUnfired());
    #end
  }

  function onLoad():Void
  {
    if (stopMusic && FlxG.sound.music != null) FlxG.sound.music.stop();

    FlxG.switchState(target);
  }

  static function getSongPath():String
  {
    return Paths.inst(PlayState.instance.currentSong.id);
  }

  /**
   * Starts the transition to a new `PlayState` to start a new song.
   * First switches to the `LoadingState` if assets need to be loaded.
   * @param params The parameters for the next `PlayState`.
   * @param shouldStopMusic Whether to stop the current music while loading.
   */
  public static function loadPlayState(params:PlayStateParams, shouldStopMusic = false):Void
  {
    Paths.setCurrentLevel(PlayStatePlaylist.campaignId);
    var playStateCtor:NextState = () -> new PlayState(params);

    #if NO_PRELOAD_ALL
    // Switch to loading state while we load assets (default on HTML5 target).
    var loadStateCtor:NextState = () -> new LoadingState(playStateCtor, shouldStopMusic, params);
    FlxG.switchState(loadStateCtor);
    #else
    // All assets preloaded, switch directly to play state (defualt on other targets).
    if (shouldStopMusic && FlxG.sound.music != null)
    {
      FlxG.sound.music.stop();
    }

    // Load and cache the song's charts.
    if (params?.targetSong != null)
    {
      params.targetSong.cacheCharts(true);
    }

    FlxG.switchState(playStateCtor);
    #end
  }

  #if NO_PRELOAD_ALL
  static function isSoundLoaded(path:String):Bool
  {
    return Assets.cache.hasSound(path);
  }

  static function isLibraryLoaded(library:String):Bool
  {
    return Assets.getLibrary(library) != null;
  }
  #end

  override function destroy():Void
  {
    super.destroy();

    callbacks = null;
  }

  static function initSongsManifest():Future<AssetLibrary>
  {
    var id = 'songs';
    var promise = new Promise<AssetLibrary>();

    var library = LimeAssets.getLibrary(id);

    if (library != null)
    {
      return Future.withValue(library);
    }

    var path = id;
    var rootPath = null;

    @:privateAccess
    var libraryPaths = LimeAssets.libraryPaths;
    if (libraryPaths.exists(id))
    {
      path = libraryPaths[id];
      rootPath = Path.directory(path);
    }
    else
    {
      if (path.endsWith('.bundle'))
      {
        rootPath = path;
        path += '/library.json';
      }
      else
      {
        rootPath = Path.directory(path);
      }
      @:privateAccess
      path = LimeAssets.__cacheBreak(path);
    }

    AssetManifest.loadFromFile(path, rootPath).onComplete(function(manifest) {
      if (manifest == null)
      {
        promise.error('Cannot parse asset manifest for library \'' + id + '\'');
        return;
      }

      var library = AssetLibrary.fromManifest(manifest);

      if (library == null)
      {
        promise.error('Cannot open library \'' + id + '\'');
      }
      else
      {
        @:privateAccess
        LimeAssets.libraries.set(id, library);
        library.onChange.add(LimeAssets.onChange.dispatch);
        promise.completeWith(Future.withValue(library));
      }
    }).onError(function(_) {
      promise.error('There is no asset library with an ID of \'' + id + '\'');
    });

    return promise.future;
  }
}

class MultiCallback
{
  public var callback:Void->Void;
  public var logId:String = null;
  public var length(default, null) = 0;
  public var numRemaining(default, null) = 0;

  var unfired = new Map<String, Void->Void>();
  var fired = new Array<String>();

  public function new(callback:Void->Void, logId:String = null)
  {
    this.callback = callback;
    this.logId = logId;
  }

  public function add(id = 'untitled'):Void->Void
  {
    id = '$length:$id';
    length++;
    numRemaining++;
    var func:Void->Void = null;
    func = function() {
      if (unfired.exists(id))
      {
        unfired.remove(id);
        fired.push(id);
        numRemaining--;

        if (logId != null) log('fired $id, $numRemaining remaining');

        if (numRemaining == 0)
        {
          if (logId != null) log('all callbacks fired');
          callback();
        }
      }
      else
        log('already fired $id');
    }
    unfired[id] = func;
    return func;
  }

  inline function log(msg):Void
  {
    if (logId != null) trace('$logId: $msg');
  }

  public function getFired():Array<String>
    return fired.copy();

  public function getUnfired():Array<Void->Void>
    return unfired.array();

  public static function coolSwitchState(state:NextState, transitionTex:String = "shaderTransitionStuff/coolDots", time:Float = 2)
  {
    var screenShit:FlxSprite = new FlxSprite().loadGraphic(Paths.image("shaderTransitionStuff/coolDots"));
    var screenWipeShit:ScreenWipeShader = new ScreenWipeShader();

    screenWipeShit.funnyShit.input = screenShit.pixels;
    FlxTween.tween(screenWipeShit, {daAlphaShit: 1}, time,
      {
        ease: FlxEase.quadInOut,
        onComplete: function(twn) {
          screenShit.destroy();
          FlxG.switchState(state);
        }
      });
    FlxG.camera.filters = [new ShaderFilter(screenWipeShit)];
  }
}
