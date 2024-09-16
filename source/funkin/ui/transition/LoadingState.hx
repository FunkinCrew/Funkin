package funkin.ui.transition;

import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import funkin.graphics.FunkinSprite;
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

class LoadingState extends MusicBeatSubState
{
  inline static var MIN_TIME = 1.0;

  var asSubState:Bool = false;

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
    var bg:FunkinSprite = new FunkinSprite().makeSolidColor(FlxG.width, FlxG.height, 0xFFcaff4d);
    add(bg);

    funkay = FunkinSprite.create('funkay');
    funkay.setGraphicSize(0, FlxG.height);
    funkay.updateHitbox();
    add(funkay);
    funkay.scrollFactor.set();
    funkay.screenCenter();

    loadBar = new FunkinSprite(0, FlxG.height - 20).makeSolidColor(0, 10, 0xFFff16d2);
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
        var instPath:String = targetChart.getInstPath(playParams.targetInstrumental);
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

    #if FEATURE_DEBUG_FUNCTIONS
    if (FlxG.keys.justPressed.SPACE) trace('fired: ' + callbacks.getFired() + ' unfired:' + callbacks.getUnfired());
    #end
  }

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

  static function getSongPath():String
  {
    return Paths.inst(PlayState.instance.currentSong.id);
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
    Paths.setCurrentLevel(PlayStatePlaylist.campaignId);
    var playStateCtor:() -> PlayState = function() {
      return new PlayState(params);
    };

    if (onConstruct != null)
    {
      playStateCtor = function() {
        var result = new PlayState(params);
        onConstruct(result);
        return result;
      };
    }

    #if NO_PRELOAD_ALL
    // Switch to loading state while we load assets (default on HTML5 target).
    var loadStateCtor = function() {
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
    if (shouldStopMusic && FlxG.sound.music != null)
    {
      FlxG.sound.music.destroy();
      FlxG.sound.music = null;
    }

    // Load and cache the song's charts.
    // Don't do this if we already provided the music and charts.
    if (params?.targetSong != null && !params.overrideMusic)
    {
      params.targetSong.cacheCharts(true);
    }

    var shouldPreloadLevelAssets:Bool = !(params?.minimalMode ?? false);

    if (shouldPreloadLevelAssets) preloadLevelAssets();

    if (asSubState)
    {
      FlxG.state.openSubState(cast playStateCtor());
    }
    else
    {
      FlxG.switchState(playStateCtor);
    }
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
  #else
  static function preloadLevelAssets():Void
  {
    // TODO: This section is a hack! Redo this later when we have a proper asset caching system.
    FunkinSprite.preparePurgeCache();
    FunkinSprite.cacheTexture(Paths.image('healthBar'));
    FunkinSprite.cacheTexture(Paths.image('menuDesat'));
    // Lord have mercy on me and this caching -anysad
    FunkinSprite.cacheTexture(Paths.image('ui/popup/funkin/combo'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/funkin/num0'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/funkin/num1'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/funkin/num2'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/funkin/num3'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/funkin/num4'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/funkin/num5'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/funkin/num6'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/funkin/num7'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/funkin/num8'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/funkin/num9'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/pixel/combo'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/pixel/num0'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/pixel/num1'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/pixel/num2'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/pixel/num3'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/pixel/num4'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/pixel/num5'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/pixel/num6'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/pixel/num7'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/pixel/num8'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/pixel/num9'));

    FunkinSprite.cacheTexture(Paths.image('notes', 'shared'));
    FunkinSprite.cacheTexture(Paths.image('noteSplashes', 'shared'));
    FunkinSprite.cacheTexture(Paths.image('noteStrumline', 'shared'));
    FunkinSprite.cacheTexture(Paths.image('NOTE_hold_assets'));

    FunkinSprite.cacheTexture(Paths.image('ui/countdown/funkin/ready', 'shared'));
    FunkinSprite.cacheTexture(Paths.image('ui/countdown/funkin/set', 'shared'));
    FunkinSprite.cacheTexture(Paths.image('ui/countdown/funkin/go', 'shared'));
    FunkinSprite.cacheTexture(Paths.image('ui/countdown/pixel/ready', 'shared'));
    FunkinSprite.cacheTexture(Paths.image('ui/countdown/pixel/set', 'shared'));
    FunkinSprite.cacheTexture(Paths.image('ui/countdown/pixel/go', 'shared'));

    FunkinSprite.cacheTexture(Paths.image('ui/popup/funkin/sick'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/funkin/good'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/funkin/bad'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/funkin/shit'));

    FunkinSprite.cacheTexture(Paths.image('ui/popup/pixel/sick'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/pixel/good'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/pixel/bad'));
    FunkinSprite.cacheTexture(Paths.image('ui/popup/pixel/shit'));

    // List all image assets in the level's library.
    // This is crude and I want to remove it when we have a proper asset caching system.
    // TODO: Get rid of this junk!
    var library = PlayStatePlaylist.campaignId != null ? openfl.utils.Assets.getLibrary(PlayStatePlaylist.campaignId) : null;

    if (library == null) return; // We don't need to do anymore precaching.

    var assets = library.list(lime.utils.AssetType.IMAGE);
    trace('Got ${assets.length} assets: ${assets}');

    // TODO: assets includes non-images! This is a bug with Polymod
    for (asset in assets)
    {
      // Exclude items of the wrong type.
      var path = '${PlayStatePlaylist.campaignId}:${asset}';
      // TODO DUMB HACK DUMB HACK why doesn't filtering by AssetType.IMAGE above work
      // I will fix this properly later I swear -eric
      if (!path.endsWith('.png')) continue;

      new Future<String>(function() {
        FunkinSprite.cacheTexture(path);
        // Another dumb hack: FlxAnimate fetches from OpenFL's BitmapData cache directly and skips the FlxGraphic cache.
        // Since FlxGraphic tells OpenFL to not cache it, we have to do it manually.
        if (path.endsWith('spritemap1.png'))
        {
          trace('Preloading FlxAnimate asset: ${path}');
          openfl.Assets.getBitmapData(path, true);
        }
        return 'Done precaching ${path}';
      }, true);

      trace('Queued ${path} for precaching');
      // FunkinSprite.cacheTexture(path);
    }

    // FunkinSprite.cacheAllNoteStyleTextures(noteStyle) // This will replace the stuff above!
    // FunkinSprite.cacheAllCharacterTextures(player)
    // FunkinSprite.cacheAllCharacterTextures(girlfriend)
    // FunkinSprite.cacheAllCharacterTextures(opponent)
    // FunkinSprite.cacheAllStageTextures(stage)
    // FunkinSprite.cacheAllSongTextures(stage)

    FunkinSprite.purgeCache();
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
