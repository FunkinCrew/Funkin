package funkin;

import funkin.play.PlayStatePlaylist;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import funkin.play.PlayState;
import haxe.io.Path;
import lime.app.Future;
import lime.app.Promise;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.Assets as LimeAssets;
import openfl.utils.Assets;

class LoadingState extends MusicBeatState
{
  inline static var MIN_TIME = 1.0;

  var target:FlxState;
  var stopMusic = false;
  var callbacks:MultiCallback;
  var danceLeft = false;

  var loadBar:FlxSprite;
  var funkay:FlxSprite;

  function new(target:FlxState, stopMusic:Bool)
  {
    super();
    this.target = target;
    this.stopMusic = stopMusic;
  }

  override function create():Void
  {
    var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFcaff4d);
    add(bg);

    funkay = new FlxSprite();
    funkay.loadGraphic(Paths.image('funkay'));
    funkay.setGraphicSize(0, FlxG.height);
    funkay.updateHitbox();
    add(funkay);
    funkay.scrollFactor.set();
    funkay.screenCenter();

    loadBar = new FlxSprite(0, FlxG.height - 20).makeGraphic(FlxG.width, 10, 0xFFff16d2);
    loadBar.screenCenter(X);
    add(loadBar);

    initSongsManifest().onComplete(function(lib) {
      callbacks = new MultiCallback(onLoad);
      var introComplete = callbacks.add('introComplete');
      // checkLoadSong(getSongPath());
      // if (PlayState.currentSong.needsVoices)
      // {
      //  var files = PlayState.currentSong.voiceList;
      //
      //  if (files == null) files = ['']; // loads with no file name assumption, to load 'Voices.ogg' or whatev normally
      //
      //  for (sndFile in files)
      //  {
      //    checkLoadSong(getVocalPath(sndFile));
      //  }
      // }

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

  inline static public function loadAndSwitchState(nextState:FlxState, shouldStopMusic = false):Void
  {
    FlxG.switchState(getNextState(nextState, shouldStopMusic));
  }

  static function getNextState(nextState:FlxState, shouldStopMusic = false):FlxState
  {
    Paths.setCurrentLevel(PlayStatePlaylist.campaignId);

    #if NO_PRELOAD_ALL
    // var loaded = isSoundLoaded(getSongPath())
    //  && (!PlayState.currentSong.needsVoices || isSoundLoaded(getVocalPath()))
    //  && isLibraryLoaded('shared');
    //
    if (true) return new LoadingState(nextState, shouldStopMusic);
    #end
    if (shouldStopMusic && FlxG.sound.music != null) FlxG.sound.music.stop();

    return nextState;
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
}
