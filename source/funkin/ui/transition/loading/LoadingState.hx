package funkin.ui.transition.loading;

import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;
import funkin.assets.FunkinAssetCache;
import lime.app.Future;
import openfl.media.Sound;
import funkin.ui.transition.Transition.TransitionTarget;
import funkin.ui.transition.Transition.TransitionParams;
import lime.app.Promises;
//
// ~PATHS~
//
import funkin.assets.Assets as Assets;
import funkin.assets.Assets.AssetType;
import funkin.assets.Paths.AnimateAtlasAssetPathBuilder;
import funkin.assets.Paths.AssetPath;
import funkin.assets.Paths.MusicAssetPathBuilder;
import funkin.assets.ValidatedPaths as Paths;
import funkin.ui.transition.Transition.TransitionParams;
import funkin.ui.transition.Transition.TransitionTarget;
import funkin.util.MemoryUtil;
import lime.app.Future;
import lime.app.Promises;
import openfl.media.Sound;

/**
 * Handles the main logic of loading requested assets asynchronously.
 * Only displays a black screen though. Add different appearances in child classes to keep code clean!
 */
@:nullSafety
@:allow(funkin.ui.transition.Transition)
class LoadingState extends MusicBeatSubState
{
  static final LIME:FlxColor = FlxColor.fromString('#32CD32') ?? FlxColor.GREEN; // Because apparently fromString is nullable -_-
  static final BLACK:FlxColor = FlxColor.BLACK;

  var target:TransitionTarget;
  var params:TransitionParams;
  var loadingStagesDone:Int = 0;
  public var currentProgress(default, null):Float = 0.0; // [0.0, 1.0]
  var completionStarted:Bool = false;
  var transitionCancelled:Bool = false;
  var previousPersistentUpdate:Bool = true;
  var previousPersistentDraw:Bool = true;
  var cancelParentUpdate:Bool = true;
  var pendingPostStatePurge:Null<Void->Void> = null;

  public static function queryAssets(type:AssetType):Array<AssetPath>
  {
    switch (type)
    {
      default:
        return [];
    }
  }

  public function new(?color:FlxColor, target:TransitionTarget, params:TransitionParams)
  {
    // #if FEATURE_DEBUG_FUNCTIONS
    // super(color ?? LIME);
    // #else
    super(color ?? BLACK);
    // #end

    this.target = target;
    this.params = params;
  }

  override public function create():Void
  {
    previousPersistentUpdate = FlxG.state.persistentUpdate;
    previousPersistentDraw = FlxG.state.persistentDraw;

    super.create();

    startAssetLoading();

    // Prevent UI elements from the state below from being updated/drawn.
    if (cancelParentUpdate)
    {
      _parentState.persistentUpdate = false;
      if (this.bgColor == FlxColor.TRANSPARENT)
      {
        _parentState.persistentDraw = true;
      }
      else
      {
        _parentState.persistentDraw = false;
      }
    }
  }

  function isSubState():Bool
  {
    switch (target)
    {
      case TransitionTarget.SubState(_):
        return true;
      default:
        return false;
    }
  }

  /**
   * Cancel this loading transition. Any asynchronous completion callback is ignored afterwards, and the state below is restored to its previous update and draw behavior.
   */
  public function cancelTransition():Void
  {
    if (transitionCancelled) return;

    transitionCancelled = true;

    if (pendingPostStatePurge != null)
    {
      FlxG.signals.postStateSwitch.remove(pendingPostStatePurge);
      pendingPostStatePurge = null;
    }

    FunkinAssetCache.instance.cancelPurgeCycle();

    FlxG.state.persistentUpdate = previousPersistentUpdate;
    FlxG.state.persistentDraw = previousPersistentDraw;

    close();
  }

  function startAssetLoading():Void
  {
    trace('[LOADING] Starting asset loading...');

    if (params?.shouldPurgeCache ?? true)
    {
      FunkinAssetCache.instance.preparePurgeCache();
    }

    loadPriorityAssets();
  }

  function loadPriorityAssets():Void
  {
    if (transitionCancelled) return;
    trace('[LOADING] Loading priority assets...');

    var onFinishedLoading:Void->Void = () ->
    {
      if (transitionCancelled) return;
      loadingStagesDone += 1;
      if (params.onPriorityAssetsLoaded != null)
      {
        params.onPriorityAssetsLoaded(this.onProgress, this.loadGraphics);
      }
      else
      {
        loadGraphics();
      }
    };

    if (params.priorityAssetQuery == null)
    {
      // Nothing to load!
      onFinishedLoading();
      return;
    }

    var assetsToLoad:Array<AssetPath> = [];

    @:privateAccess
    for (typeToLoad in Assets.ASSET_TYPES.filterNull())
    {
      assetsToLoad.append(params.priorityAssetQuery(typeToLoad));
    }

    if (assetsToLoad.length == 0)
    {
      // Nothing to load!
      onFinishedLoading();
      return;
    }

    // Final Future sounds badass ngl
    var finalFuture:Future<Array<Future<Bool>>> = Assets.cacheAll(assetsToLoad);

    finalFuture.onProgress(this.onProgress);
    finalFuture.onError(this.onError);
    finalFuture.onComplete((loadedAssets:Array<Future<Bool>>) ->
    {
      if (transitionCancelled) return;
      var success:Int = 0;
      var error:Int = 0;
      for (loadedAsset in loadedAssets)
      {
        if (!loadedAsset.isComplete)
        {
          trace('HUH? Asset loading is not complete...');
        }
        else if (loadedAsset.isError)
        {
          trace('[LOADING] Error loading asset: ${loadedAsset.error}');
          error++;
        }
        else
        {
          success++;
        }
      }

      trace('[LOADING] Finished loading $success/${success + error} priority assets.');

      onFinishedLoading();
    });
  }

  function loadGraphics():Void
  {
    if (transitionCancelled) return;
    trace('[LOADING] Loading graphics...');

    // Get the list of assets needed for this state,
    // plus the assets that should always stay loaded across states.
    var graphicsToLoad:Array<AssetPath> = params.assetQuery == null ? [] : params.assetQuery(IMAGE);
    if (graphicsToLoad.length == 0)
    {
      // Nothing to load!
      loadingStagesDone += 1;
      loadSounds();
      return;
    }

    // trace('[LOADING] Created promise to cache ${graphicsToLoad.length} total graphics.')
    var future:Future<Array<Future<Bool>>> = Assets.cacheAllFlxGraphics(graphicsToLoad);

    future.onProgress(this.onProgress);
    future.onError(this.onError);
    future.onComplete((loadedGraphics:Array<Future<Bool>>) ->
    {
      if (transitionCancelled) return;
      // trace('[LOADING] Finished loading graphics, counting results...')
      var success:Int = 0;
      var error:Int = 0;
      for (loadedGraphic in loadedGraphics)
      {
        if (loadedGraphic.isError)
        {
          trace('[LOADING] Error loading graphic: ${loadedGraphic.error}');
          error++;
        }
        else if (!loadedGraphic.isComplete)
        {
          trace('HUH? Asset loading is not complete...');
        }
        else
        {
          success++;
        }
      }

      trace('[LOADING] Finished loading ${success}/${success + error} graphics.');

      loadingStagesDone += 1;
      loadSounds();
    });
  }

  function loadSounds():Void
  {
    if (transitionCancelled) return;
    trace('[LOADING] Loading sounds...');

    // Get the list of assets needed for this state,
    // plus the assets that should always stay loaded across states.
    trace('[LOADING] Getting sound list...');
    var soundsToLoad:Array<AssetPath> = params.assetQuery == null ? [] : params.assetQuery(SOUND);
    trace('[LOADING] Got list of ${soundsToLoad.length} total sounds.');
    if (soundsToLoad.length == 0)
    {
      // Nothing to load!
      loadingStagesDone += 1;
      loadText();
      return;
    }

    var future:Future<Array<Future<Bool>>> = Assets.cacheAllSounds(soundsToLoad);

    future.onProgress(this.onProgress);
    future.onError(this.onError);
    future.onComplete((loadedSounds:Array<Future<Bool>>) ->
    {
      if (transitionCancelled) return;
      var success:Int = 0;
      var error:Int = 0;
      for (loadedSound in loadedSounds)
      {
        if (loadedSound.isError)
        {
          trace('[LOADING] Error loading sound: ${loadedSound.error}');
          error++;
        }
        else if (!loadedSound.isComplete)
        {
          trace('HUH? Asset loading is not complete...');
        }
        else
        {
          success++;
        }
      }

      trace('[LOADING] Finished loading ${success}/${success + error} sounds.');

      loadingStagesDone += 1;
      loadText();
    });
  }

  function loadText():Void
  {
    if (transitionCancelled) return;
    trace('[LOADING] Loading text...');

    // Get the list of assets needed for this state,
    // plus the assets that should always stay loaded across states.
    var textToLoad:Array<AssetPath> = Arrays.flatten(params.assetQuery == null ? [] : [
      params.assetQuery(TEXT),
      params.assetQuery(JSON),
      params.assetQuery(SHADER),
      params.assetQuery(SCRIPT),
      params.assetQuery(SCRIPTED_CLASS),
      params.assetQuery(XML),
    ]);
    if (textToLoad.length == 0)
    {
      // Nothing to load!
      loadingStagesDone += 1;
      loadBytes();
      return;
    }

    var future:Future<Array<Future<Bool>>> = Assets.cacheAllText(textToLoad);
    future.onProgress(this.onProgress);
    future.onError(this.onError);
    future.onComplete((loadedText:Array<Future<Bool>>) ->
    {
      if (transitionCancelled) return;
      var success:Int = 0;
      var error:Int = 0;
      for (textFuture in loadedText)
      {
        if (textFuture.isError)
        {
          trace('[LOADING] Error loading text: ${textFuture.error}');
          error++;
        }
        else if (!textFuture.isComplete)
        {
          trace('HUH? Asset loading is not complete...');
        }
        else
        {
          success++;
        }
      }

      trace('[LOADING] Finished loading ${success}/${success + error} text.');

      loadingStagesDone += 1;
      loadBytes();
    });
  }

  function loadBytes():Void
  {
    if (transitionCancelled) return;
    trace('[LOADING] Loading other files...');

    // Get the list of assets needed for this state,
    // plus the assets that should always stay loaded across states.
    var bytesToLoad:Array<AssetPath> = Arrays.flatten(params.assetQuery == null ? [] : [
      params.assetQuery(VIDEO),
      params.assetQuery(CHART),
      params.assetQuery(STAGE),
      params.assetQuery(FONT),
      params.assetQuery(UNKNOWN),
    ]);

    if (bytesToLoad.length == 0)
    {
      trace('[LOADING] No other files to load.');
      // Nothing to load!
      loadingStagesDone += 1;
      if (params.onAssetsLoaded != null)
      {
        trace('[LOADING] Queuing additional loading...');
        params.onAssetsLoaded(this.onProgress, this.onFullyComplete);
      }
      else
      {
        trace('[LOADING] Queuing cleanup...');
        this.onFullyComplete();
      }
      return;
    }

    var future:Future<Array<Future<Bool>>> = Assets.cacheAllBytes(bytesToLoad);

    future.onProgress(this.onProgress);
    future.onError(this.onError);
    future.onComplete((loadedBytes:Array<Future<Bool>>) ->
    {
      if (transitionCancelled) return;
      var success:Int = 0;
      var error:Int = 0;
      for (bytesFuture in loadedBytes)
      {
        if (bytesFuture.isError)
        {
          trace('[LOADING] Error loading files: ${bytesFuture.error}');
          error++;
        }
        else if (!bytesFuture.isComplete)
        {
          trace('HUH? Asset loading is not complete...');
        }
        else
        {
          success++;
        }
      }

      trace('[LOADING] Finished loading ${success}/${success + error} bytes.');

      loadingStagesDone += 1;
      if (params.onAssetsLoaded != null)
      {
        params.onAssetsLoaded(this.onProgress, this.onFullyComplete);
      }
      else
      {
        this.onFullyComplete();
      }
    });
  }

  function onProgress(loaded:Int, total:Int):Void
  {
    if (transitionCancelled) return;
    var numberOfStages:Int = 5; // Priority, Graphics, Sound, Text, Binary

    // If you've completed 4/5 stages, and you're 25% done this stage, then we're 85% done.
    this.currentProgress = (loadingStagesDone / numberOfStages) + ((loaded / total) / numberOfStages);
    this.currentProgress = this.currentProgress.clamp(0.0, 1.0);

    trace('[LOADING] Loaded ${loaded}/${total} [Stage $loadingStagesDone/$numberOfStages] (${currentProgress * 100}%)');
  }

  function onError(error:Any):Void
  {
    if (transitionCancelled) return;
    trace('[LOADING] Error loading assets: ${error}');
  }

  /**
   * Purge only after a real state switch has completed.
   * SubState transitions do not get this treatment cuz the parent state remains alive and is expected to keep using its assets.
   */
  function schedulePostStatePurge():Void
  {
    if (!(params?.shouldPurgeCache ?? true)) return;
    if (pendingPostStatePurge != null) return;

    final purgeCallback:Void->Void = () ->
    {
      pendingPostStatePurge = null;

      if (transitionCancelled)
      {
        trace('[LOADING] Skipping deferred cache purge because the transition was cancelled.');
        return;
      }

      trace('[LOADING] State switch complete; purging cache now.');
      final FORCE_GC:Bool = true;
      FunkinAssetCache.instance.purgeCache(FORCE_GC);
      trace('[LOADING] Deferred cache purge complete.');
    };

    pendingPostStatePurge = purgeCallback;
    FlxG.signals.postStateSwitch.addOnce(purgeCallback);
  }

  function onFullyComplete():Void
  {
    if (transitionCancelled) return;
    if (completionStarted)
    {
      trace('[LOADING] Ignoring duplicate completion callback.');
      return;
    }
    completionStarted = true;

    trace('[LOADING] Loading process complete, preparing state transition.');

    if (params.shouldStopMusic && FlxG.sound.music != null)
    {
      FlxG.sound.music.destroy();
      @:nullSafety(Off) {
        FlxG.sound.music = null;
      }
    }

    switch (target)
    {
      case State(nextState):
        #if cpp
        MemoryUtil.collect(true);
        #end
        schedulePostStatePurge();
        FlxG.switchState(nextState);

      case SubState(targetSubState):
        if (params?.shouldPurgeCache ?? true)
        {
          trace('[LOADING] Skipping global cache purge for SubState transition; parent state remains alive.');
        }
        this.switchSubState(targetSubState.createInstance());

      default:
        throw 'No target state provided to LoadingState!';
    }
  }
}
