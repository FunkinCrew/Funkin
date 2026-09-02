package funkin.ui.transition;

import funkin.assets.FunkinAssetCache;
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
      var instPath:String = targetChart.getInstPath(playParams.targetInstrumental).toString();
      var voicesPaths:Array<String> = targetChart.buildVoiceList().map(function(voice) return voice.toString());

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
    var daChart:Null<SongDifficulty> = params.targetSong?.getDifficulty(
      params.targetDifficulty ?? Constants.DEFAULT_DIFFICULTY,
      params.targetVariation ?? Constants.DEFAULT_VARIATION
    );

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
    // All assets preloaded, switch directly to play state (default on other targets).
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
      FlxG.signals.preStateSwitch.addOnce(() ->
      {
        FunkinAssetCache.instance.preparePurgeCache();

        preloadLevelAssets();

        var spritesToCache:Array<funkin.assets.Paths.AssetPath> = [];
        var soundsToCache:Array<funkin.assets.Paths.AssetPath> = [];

        // Cache the note style.
        var songDifficulty = params.targetSong.getDifficulty(params.targetDifficulty, params.targetVariation);
        if (songDifficulty != null)
        {
          var noteStyle = NoteStyleRegistry.instance.fetchEntry(songDifficulty.noteStyle ?? '');
          if (noteStyle == null) noteStyle = NoteStyleRegistry.instance.fetchDefault();
          spritesToCache.append(noteStyle.queryAssets(IMAGE));
          soundsToCache.append(noteStyle.queryAssets(SOUND));
        }

        // TODO: This sucks lol.
        if (params.targetSong.songName == '2hot')
        {
          spritesToCache.append([
            funkin.assets.Paths.image('gameplay/songs/darnell/cutscene/cutscene-can'),
            funkin.assets.Paths.image('gameplay/songs/2hot/graphics/spraycan-explosion-ez'),
            funkin.assets.Paths.image('gameplay/songs/2hot/graphics/can-impact'),
            funkin.assets.Paths.image('gameplay/songs/2hot/spraycan/spritemap1')
          ]);

          soundsToCache.append([
            funkin.assets.Paths.sound('gameplay/songs/2hot/sounds/darnell-lighter'),
            funkin.assets.Paths.sound('gameplay/characters/pico-playable/sounds/gun-prep'),
            funkin.assets.Paths.sound('gameplay/songs/2hot/sounds/kick-can-forward'),
            funkin.assets.Paths.sound('gameplay/songs/2hot/sounds/kick-can-up'),
            funkin.assets.Paths.sound('gameplay/stages/phillyBlazin/sounds/lightning-1'),
            funkin.assets.Paths.sound('gameplay/stages/phillyBlazin/sounds/lightning-2'),
            funkin.assets.Paths.sound('gameplay/stages/phillyBlazin/sounds/lightning-3'),
            funkin.assets.Paths.sound('gameplay/characters/pico-playable/sounds/bonk'),
            funkin.assets.Paths.sound('gameplay/characters/pico-playable/sounds/shot-1'),
            funkin.assets.Paths.sound('gameplay/characters/pico-playable/sounds/shot-2'),
            funkin.assets.Paths.sound('gameplay/characters/pico-playable/sounds/shot-3'),
            funkin.assets.Paths.sound('gameplay/characters/pico-playable/sounds/shot-4')
          ]);
        }

        for (assetPath in spritesToCache)
        {
          trace('Queueing ${assetPath.toString()} to preload.');
          funkin.assets.Assets.cacheFlxGraphic(assetPath).onComplete((success:Bool) ->
          {
            // TODO: This should be where the the progress bar should be handled, i think
            trace('Succesfully cached ${assetPath.toString()}!');
          });
          // Another dumb hack: FlxAnimate fetches from OpenFL's BitmapData cache directly and skips the FlxGraphic cache.
          // Since FlxGraphic tells OpenFL to not cache it, we have to do it manually.
          if (assetPath.toString().endsWith('spritemap1.png') #if FEATURE_COMPRESSED_TEXTURES || assetPath.toString().endsWith('spritemap1.astc') #end)
          {
            trace('Preloading FlxAnimate asset: ${assetPath}');
            funkin.assets.Assets.getBitmapData(assetPath);
          }
        }

        for (assetPath in soundsToCache)
        {
          trace('Queueing ${assetPath.toString()} to preload.');
          funkin.assets.Assets.cacheSound(assetPath);
        }
      });

      FlxG.signals.postStateSwitch.addOnce(() ->
      {
        // TODO: In loading screens, you should be caching BETWEEN these.
        FunkinAssetCache.instance.purgeCache(#if ios funkin.util.DeviceUtil.iPhoneNumber > 12 #else true #end);
      });
    }

    if (asSubState)
    {
      FlxG.state.openSubState(cast playStateCtor());
    }
    else
    {
      FlxG.signals.preStateSwitch.addOnce(() ->
      {
        funkin.memory.FunkinMemory.clearFreeplay();
      });
      // TODO: FUCKING FIX THIS BULLSHIT I HATE YOU KILL EVERYONE IUNCLIDUGN YORUSLEF - TO MOON
      // TODO: pretty please fix this gem i love you heal everyone inclidugn yoruslef <3 - to moon
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
    // // TODO: For moon! replace this shit with the new restructured caching from Eric! Make that work with FunkinMemory! -Moon
    // if (Paths.currentLevel == null || Paths.currentLevel == "shared" || Paths.currentLevel == "") return;
    // var lib = openfl.Assets.getLibrary(Paths.currentLevel);

    // var ids = lib.list("IMAGE").concat(lib.list("SOUND"));
    // for (id in ids)
    // {
    //   if (id.endsWith('.ogg') || id.endsWith('.mp3') || id.endsWith('.wav'))
    //   {
    //     var path = Paths.sound(id, Paths.currentLevel);
    //     new Future<String>(function()
    //     {
    //       if (path != null)
    //       {
    //         funkin.assets.Assets.cacheSound(path);
    //       }
    //       return '${path} successfully loaded.';
    //     }, true);
    //   }

    //   if (id.endsWith('.png') || id.endsWith('.jpg') || id.endsWith('.jpeg'))
    //   {
    //     var path = Paths.image(id, Paths.currentLevel);
    //     new Future<String>(function()
    //     {
    //       if (path != null)
    //       {
    //         funkin.assets.Assets.cacheFlxGraphic(path);
    //       }
    //       return '${path} successfully loaded.';
    //     }, true);
    //   }
    // }
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
  public static function coolSwitchState(state:NextState,
    transitionTex:String = "shaderTransitionStuff/coolDots",
    time:Float = 2)
  {
    var screenShit:FunkinSprite = FunkinSprite.create('shaderTransitionStuff/coolDots');
    var screenWipeShit:ScreenWipeShader = new ScreenWipeShader();

    screenWipeShit.funnyShit.input = screenShit.pixels;
    FlxTween.tween(screenWipeShit, {
      daAlphaShit: 1
    }, time, {
      ease: FlxEase.quadInOut,
      onComplete: function(twn)
      {
        screenShit.destroy();
        FlxG.switchState(state);
      }
    });
    FlxG.camera.filters = [new ShaderFilter(screenWipeShit)];
  }
}
