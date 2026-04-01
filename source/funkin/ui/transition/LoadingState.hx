package funkin.ui.transition;

import funkin.data.notestyle.NoteStyleRegistry;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.typeLimit.NextState;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.ScreenWipeShader;
import funkin.play.PlayState;
import funkin.play.PlayStatePlaylist;
import funkin.play.song.Song.SongDifficulty;
import funkin.play.stage.Stage;
import haxe.io.Path;
import lime.app.Future;
import lime.app.Promise;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.Assets as LimeAssets;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets as OpenFLAssets;

@:nullSafety
class LoadingState extends MusicBeatSubState
{
  inline static var MIN_TIME = 1.0;

  var asSubState:Bool = false;
  var target:NextState;
  var playParams:Null<PlayStateParams>;
  var stopMusic:Bool = false;
  var callbacks:Null<MultiCallback>;
  var danceLeft:Bool = false;
  var loadBar:FlxSprite;
  var funkay:FlxSprite;

  function new(target:NextState, stopMusic:Bool, ?playParams:PlayStateParams)
  {
    super();
    this.target = target;
    this.playParams = playParams;
    this.stopMusic = stopMusic;

    this.loadBar = new FunkinSprite(0, FlxG.height - 20).makeSolidColor(0, 10, 0xFFff16d2);
    this.funkay = FunkinSprite.create('ui/loading/funkay');
  }

  override function create():Void
  {
    var bg:FunkinSprite = new FunkinSprite().makeSolidColor(FlxG.width, FlxG.height, 0xFFcaff4d);
    add(bg);

    funkay.setGraphicSize(0, FlxG.height);
    funkay.updateHitbox();
    add(funkay);
    funkay.scrollFactor.set();
    funkay.screenCenter();

    add(loadBar);

    callbacks = new MultiCallback(onLoad);
    var introComplete = callbacks.add('introComplete');

    if (playParams != null)
    {
      // Load and cache the song's charts.
      if (playParams.targetSong == null)
      {
        throw 'Invalid parameter: Target song should not be null';
      }

      playParams.targetSong.cacheCharts(true);

      // Preload the song for the play state.
      var difficulty:String = playParams.targetDifficulty ?? Constants.DEFAULT_DIFFICULTY;
      var variation:String = playParams.targetVariation ?? Constants.DEFAULT_VARIATION;
      var targetChart:Null<SongDifficulty> = playParams.targetSong.getDifficulty(difficulty, variation);
      if (targetChart == null)
      {
        throw 'Couldn\'t retrieve chart data for song "${playParams.targetSong.songName}" on difficulty "$difficulty" and variation "$variation"';
      }
      var instPath:String = targetChart.getInstPath(playParams.targetInstrumental);
      var voicesPaths:Array<String> = targetChart.buildVoiceList();

      checkLoadSong(instPath);
      for (voicePath in voicesPaths)
      {
        checkLoadSong(voicePath);
      }
    }

    var fadeTime:Float = 0.5;
    FlxG.camera.fade(FlxG.camera.bgColor, fadeTime, true);
    new FlxTimer().start(fadeTime + MIN_TIME, function(_) introComplete());
  }

  function checkLoadSong(path:String):Void
  {
    if (!OpenFLAssets.cache.hasSound(path))
    {
      var library = Assets.getLibrary('songs');
      var symbolPath = path.split(':').pop();
      // @:privateAccess
      // library.types.set(symbolPath, SOUND);
      // @:privateAccess
      // library.pathGroups.set(symbolPath, [library.__cacheBreak(symbolPath)]);
      var callback = callbacks?.add('song:' + path);
      Assets.loadSound(path).onComplete(function(_)
      {
        if (callback != null) callback();
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

      var callback = callbacks?.add('library:' + library);
      Assets.loadLibrary(library).onComplete(function(_)
      {
        if (callback != null) callback();
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

    if (controls.ACCEPT_P)
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

      var lerpWidth:Int = Std.int(FlxMath.lerp(loadBar.width, FlxG.width * targetShit, 0.2));
      // this if-check prevents the setGraphicSize function
      // from setting the width of the loadBar to the height of the loadBar
      // this is a behaviour that is implemented in the setGraphicSize function
      // if the width parameter is equal to 0
      if (lerpWidth > 0)
      {
        loadBar.setGraphicSize(lerpWidth, loadBar.height);
        loadBar.updateHitbox();
      }
      FlxG.watch.addQuick('percentage?', callbacks.numRemaining / callbacks.length);
    }
  }

  @:nullSafety(Off) // why isn't FlxG.sound.music nullable
  function onLoad():Void
  {
    // Stop the instrumental.
    if (stopMusic && FlxG.sound.music != null)
    {
      FlxG.sound.music.destroy();
      FlxG.sound.music = null;
    }

    if (asSubState)
    {
      this.close();
      // We will assume the target is a valid substate.
      FlxG.state.openSubState(cast target);
    }
    else
    {
      FlxG.switchState(target);
    }
  }

  /**
   * Starts the transition to a new `PlayState` to start a new song.
   * First switches to the `LoadingState` if assets need to be loaded.
   * @param params The parameters for the next `PlayState`.
   * @param asSubState Whether to open as a substate rather than switching to the `PlayState`.
   * @param shouldStopMusic Whether to stop the current music while loading.
   */
  public static function loadPlayState(params:PlayStateParams, shouldStopMusic = false, asSubState = false, ?onConstruct:PlayState->Void):Void
  {
    var daChart:Null<SongDifficulty> = params.targetSong?.getDifficulty(params.targetDifficulty ?? Constants.DEFAULT_DIFFICULTY,
      params.targetVariation ?? Constants.DEFAULT_VARIATION);

    var daStage = funkin.data.stage.StageRegistry.instance.fetchEntry(daChart?.stage ?? Constants.DEFAULT_STAGE);

    if (funkin.ui.FullScreenScaleMode.instance != null) funkin.ui.FullScreenScaleMode.instance.onMeasurePostAwait();

    var playStateCtor:() -> PlayState = function()
    {
      return new PlayState(params);
    };

    if (onConstruct != null)
    {
      playStateCtor = function()
      {
        var result = new PlayState(params);
        onConstruct(result);
        return result;
      };
    }

    #if NO_PRELOAD_ALL
    // Switch to loading state while we load assets (default on HTML5 target).
    var loadStateCtor = function()
    {
      var result = new LoadingState(playStateCtor, shouldStopMusic, params);
      @:privateAccess
      result.asSubState = asSubState;
      return result;
    }
    if (asSubState)
    {
      FlxG.state.openSubState(cast loadStateCtor());
    }
    else
    {
      FlxG.switchState(loadStateCtor);
    }
    #else
    // All assets preloaded, switch directly to play state (defualt on other targets).
    @:nullSafety(Off)
    if (shouldStopMusic && FlxG.sound.music != null)
    {
      FlxG.sound.music.destroy();
      FlxG.sound.music = null;
    }

    // Load and cache the song's charts.
    // Don't do this if we already provided the music and charts.
    if (!(params.overrideMusic ?? false))
    {
      params.targetSong.cacheCharts(true);
    }

    var shouldPreloadLevelAssets:Bool = !(params?.minimalMode ?? false);

    if (shouldPreloadLevelAssets)
    {
      preloadLevelAssets();

      // Cache the note style.
      var songDifficulty = params.targetSong.getDifficulty(params.targetDifficulty, params.targetVariation);
      if (songDifficulty != null)
      {
        var noteStyle = NoteStyleRegistry.instance.fetchEntry(songDifficulty.noteStyle ?? '');
        if (noteStyle == null) noteStyle = NoteStyleRegistry.instance.fetchDefault();
        FunkinMemory.cacheNoteStyle(noteStyle);
      }

      // TODO: This sucks lol.
      if (params.targetSong.songName == "2hot")
      {
        var spritesToCache = [
          "gameplay/songs/darnell/cutscene/cutscene-can",
          "gameplay/songs/2hot/graphics/spraycan-explosion-ez",
          "gameplay/songs/2hot/graphics/can-impact"
        ];

        var soundsToCache = [
          "gameplay/songs/2hot/sounds/darnell-lighter",
          "gameplay/characters/pico-playable/sounds/gun-prep",
          "gameplay/songs/2hot/sounds/kick-can-forward",
          "gameplay/songs/2hot/sounds/kick-can-up",
          "gameplay/songs/2hot/spraycan/spritemap1",
          "gameplay/stages/phillyBlazin/sounds/lightning-1",
          "gameplay/stages/phillyBlazin/sounds/lightning-2",
          "gameplay/stages/phillyBlazin/sounds/lightning-3",
          "gameplay/characters/pico-playable/sounds/bonk",
          "gameplay/characters/pico-playable/sounds/shot-1",
          "gameplay/characters/pico-playable/sounds/shot-2",
          "gameplay/characters/pico-playable/sounds/shot-3",
          "gameplay/characters/pico-playable/sounds/shot-4"
        ];

        for (sprite in spritesToCache)
        {
          trace('Queueing $sprite to preload.');
          // new Future<String>(function() {
          var path = Paths.image(sprite);
          funkin.FunkinMemory.cacheTexture(path);
          // Another dumb hack: FlxAnimate fetches from OpenFL's BitmapData cache directly and skips the FlxGraphic cache.
          // Since FlxGraphic tells OpenFL to not cache it, we have to do it manually.
          if (path.endsWith('spritemap1.png') #if FEATURE_COMPRESSED_TEXTURES || path.endsWith('spritemap1.astc') #end)
          {
            trace('Preloading FlxAnimate asset: ${path}');
            openfl.Assets.getBitmapData(path, true);
          }
          // return '${path} successfuly loaded.';
          // }, true);
        }

        for (sound in soundsToCache)
        {
          trace('Queueing $sound to preload.');
          new Future<String>(function()
          {
            var path = Paths.sound(sound);
            funkin.FunkinMemory.cacheSound(path);
            return '${path} successfuly loaded.';
          }, true);
        }
      }
    }

    if (asSubState)
    {
      FlxG.state.openSubState(cast playStateCtor());
    }
    else
    {
      // funkin.FunkinMemory.clearFreeplay();
      FlxG.signals.preStateSwitch.addOnce(function()
      {
        funkin.FunkinMemory.clearFreeplay();
        funkin.FunkinMemory.purgeCache(true);
      });
      FlxG.switchState(playStateCtor);
    }
    #end
  }

  #if NO_PRELOAD_ALL
  static function isSoundLoaded(path:String):Bool
  {
    return OpenFLAssets.cache.hasSound(path);
  }

  static function isLibraryLoaded(library:String):Bool
  {
    return Assets.getLibrary(library) != null;
  }
  #else
  static function preloadLevelAssets():Void
  {
    // TODO: This section is a hack! Redo this later when we have a proper asset caching system.
    // FunkinSprite.preparePurgeCache();
    // funkin.FunkinMemory.purgeSoundCache();

    // List all image assets in the level's library.

    // var assets = library.list(lime.utils.AssetType.IMAGE);
    // trace('Got ${assets.length} assets: ${assets}');

    // TODO: assets includes non-images! This is a bug with Polymod
    // for (asset in assets)
    // {
    //   // Exclude items of the wrong type.
    //   var path = '${PlayStatePlaylist.campaignId}:${asset}';
    //   // TODO DUMB HACK DUMB HACK why doesn't filtering by AssetType.IMAGE above work
    //   // I will fix this properly later I swear -eric
    //   if (!path.endsWith('.png')) continue;

    //   new Future<String>(function() {
    //     FunkinSprite.cacheTexture(path);
    //     // Another dumb hack: FlxAnimate fetches from OpenFL's BitmapData cache directly and skips the FlxGraphic cache.
    //     // Since FlxGraphic tells OpenFL to not cache it, we have to do it manually.
    //     if (path.endsWith('spritemap1.png'))
    //     {
    //       trace('Preloading FlxAnimate asset: ${path}');
    //       openfl.Assets.getBitmapData(path, true);
    //     }
    //     return 'Done precaching ${path}';
    //   }, true);

    //   trace('Queued ${path} for precaching');
    //   // FunkinSprite.cacheTexture(path);
    // }

    // FunkinSprite.cacheAllNoteStyleTextures(noteStyle) // This will replace the stuff above!
    // FunkinSprite.cacheAllCharacterTextures(player)
    // FunkinSprite.cacheAllCharacterTextures(girlfriend)
    // FunkinSprite.cacheAllCharacterTextures(opponent)
    // FunkinSprite.cacheAllStageTextures(stage)
    // FunkinSprite.cacheAllSongTextures(stage)

    // FunkinSprite.purgeCache();
  }
  #end

  override function destroy():Void
  {
    super.destroy();

    callbacks = null;
  }

  public static function transitionToState(state:NextState, stopMusic:Bool = false):Void
  {
    FlxG.switchState(() -> new LoadingState(state, stopMusic));
  }
}

@:nullSafety
class MultiCallback
{
  public var callback:Void->Void;
  public var logId:Null<String>;
  public var length(default, null) = 0;
  public var numRemaining(default, null) = 0;

  var unfired = new Map<String, Void->Void>();
  var fired = new Array<String>();

  public function new(callback:Void->Void, ?logId:String)
  {
    this.callback = callback;
    this.logId = logId;
  }

  public function add(id = 'untitled'):Void->Void
  {
    id = '$length:$id';
    length++;
    numRemaining++;
    var func:Void->Void = function()
    {
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

  public function getFired():Array<String> return fired.copy();

  public function getUnfired():Array<Void->Void> return unfired.array();

  /**
   * Perform an FlxG.switchState with a nice transition
   * @param state
   * @param transitionTex
   * @param time
   */
  public static function coolSwitchState(state:NextState, transitionTex:String = "shaderTransitionStuff/coolDots", time:Float = 2)
  {
    var screenShit:FunkinSprite = FunkinSprite.create('shaderTransitionStuff/coolDots');
    var screenWipeShit:ScreenWipeShader = new ScreenWipeShader();

    screenWipeShit.funnyShit.input = screenShit.pixels;
    FlxTween.tween(screenWipeShit, {daAlphaShit: 1}, time, {
      ease: FlxEase.quadInOut,
      onComplete: function(twn)
      {
        screenShit.destroy();
        FlxG.switchState(state);
      }
    });
    FlxG.camera.filters = [
      new ShaderFilter(screenWipeShit)
    ];
  }
}
