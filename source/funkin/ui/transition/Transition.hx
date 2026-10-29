package funkin.ui.transition;

import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.FlxTransitionableSubState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.typeLimit.NextState;
import funkin.assets.Assets.AssetType;
import funkin.assets.Paths.AssetPath;
import funkin.data.song.SongRegistry;
import funkin.play.PlayState;
import funkin.ui.transition.loading.FunkayLoadingState;
import funkin.ui.transition.loading.LoadingState;
import funkin.ui.transition.loading.StickerLoadingState;
import funkin.ui.transition.StickerTransition;
import funkin.ui.transition.loading.ThrobberLoadingState;
import funkin.util.FlxStateUtil;
import funkin.util.tasks.TaskHandler;
import funkin.assets.Assets;
import funkin.assets.ValidatedPaths as Paths;

/**
 * Provides information about how to transition between states, including the asset query function to use during loading.
 */
typedef TransitionParams =
{
  > BaseTransitionParams,
  /**
   * An asset query function.
   * Given an asset type, this should return the assets which must be loaded for the target state to operate.
   */
  ?assetQuery:(AssetType) -> Array<AssetPath>,
  /**
   * Given an asset type, this should return the assets which must be loaded BEFORE any other asset queries can return the correct data.
   * Ideally, this should return the minimum required assets to allow other assets to be loaded in the standard loading step.
   *
   * Example: PlayState needs to load the chart data first, then parse it, then use that parsed chart data to check the song events.
   */
  ?priorityAssetQuery:(AssetType) -> Array<AssetPath>,
};

/**
 * Provides information about how to transition between states, excluding the asset query function.
 */
typedef BaseTransitionParams =
{
  /**
   * What we want the transition to look like.
   * @see `TransitionType`
   * @default `BlackScreen(FadeType.None)`
   */
  ?transition:TransitionType,
  /**
   * Should the music be stopped during the transition?
   * @default `false`
   */
  ?shouldStopMusic:Bool,
  /**
   * Should the asset cache be purged during the transition,
   * unloading assets that won't be used in the target state?
   * @default `true`
   */
  ?shouldPurgeCache:Bool,
  /**
   * A loading function executed after standard assets are loaded.
   * Make sure to do things asynchronously if possible to prevent lag,
   * and call `onProgress` and `onComplete` to update the progress bar!
   */
  ?onAssetsLoaded:(onProgress:(loaded:Int, total:Int) -> Void,
    onComplete:() -> Void) -> Void,
  /**
   * A loading function executed after priority assets are loaded.
   * Make sure to do things asynchronously if possible to prevent lag,
   * and call `onProgress` and `onComplete` to update the progress bar!
   */
  ?onPriorityAssetsLoaded:(onProgress:(loaded:Int, total:Int) -> Void,
    onComplete:() -> Void) -> Void,
  /**
   * A function to call after the state is constructed but before we switch to it.
   */
  ?onConstruct:(targetState:FlxState) -> Void,
};

/**
 * A utility class for handling switching states with clean loading screens.
 */
class Transition
{
  /**
   * Prevent multiple state-transition requests from the same frame.
   * We dont want F4 soft lock, right?
   */
  static var pendingReplacement:Bool = false;

  public static function isTransitionActive():Bool
  {
    var topState:Null<FlxState> = FlxStateUtil.getTopmostSubState(FlxG.state, false);
    if (topState == null) return false;

    if (Std.isOfType(topState, flixel.addons.transition.Transition)) return true;

    if (Std.isOfType(topState, LoadingState)) return true;

    return false;
  }

  static function cancelActiveTransition():Void
  {
    if (!FlxStateUtil.cancelTransitionAtTop(FlxG.state)) return;

    FlxTransitionableState.skipNextTransIn = false;
    FlxTransitionableState.skipNextTransOut = false;
  }

  /**
   * An asset query function that returns no assets.
   */
  public static final NO_ASSETS:(AssetType) -> Array<AssetPath> = (_) -> [];

  /**
   * Query assets needed for transitions.
   * This includes stuff like gradients and loading screen graphics.
   *
   * @param type The asset type to query
   * @return A list of asset paths of that type required for transitions.
   */
  public static function queryAssets(type:AssetType):Array<AssetPath>
  {
    var results:Array<AssetPath> = [];

    // We keep all the assets for all loading screens cached,
    // because we don't want to have a loading screen for a loading screen.
    results.append(LoadingState.queryAssets(type));
    results.append(FunkayLoadingState.queryAssets(type));
    results.append(ThrobberLoadingState.queryAssets(type));

    // Scripted loading screens must keep their assets cached before a transition starts.
    for (scriptedClass in LoadingState.listScriptClasses())
    {
      if (!LoadingState.scriptStaticHas(scriptedClass, 'queryAssets')) continue;

      var scriptedAssets:Array<AssetPath> = LoadingState.scriptStaticCall(scriptedClass, 'queryAssets', [type]);
      if (scriptedAssets != null) results.appendUnique(scriptedAssets);
    }

    switch (type)
    {
      default:
        // Nothing
    }

    return results;
  }

  /**
   * Open the target state as a new state, with a defined transition between.
   * Ensures all the assets require for that state are loaded before continuing.
   * @param targetState The state to transition to.
   * @param params Parameters for the transition.
   */
  public static function switchState(targetState:NextState, params:TransitionParams):Void
  {
    if (isTransitionActive())
    {
      if (pendingReplacement)
      {
        trace('[TRANSITION] Ignoring duplicate state transition request while a replacement is pending.');
        return;
      }

      pendingReplacement = true;
      trace('[TRANSITION] Replacing the active transition with a new state transition.');
      cancelActiveTransition();

      new FlxTimer().start(0, (_) ->
      {
        pendingReplacement = false;
        switchState(targetState, params);
      });
      return;
    }

    params = validateParams(params);

    var builder = () ->
    {
      return targetState.createInstance();
    };

    if (params.onConstruct != null)
    {
      builder = () ->
      {
        var result:FlxState = targetState.createInstance();
        params.onConstruct(result);
        return result;
      };
    }

    var transitionType:TransitionType = params?.transition ?? TransitionType.BlackScreen(FadeType.None, FadeType.None);

    switch (transitionType)
    {
      case None:
        var onTransOutDone:Void->Void = () ->
        {
          FlxStateUtil.openSubStateAtTop(new LoadingState(FlxColor.TRANSPARENT, State(builder), params));
        };

        // Make sure to reset the fade to None,
        // to prevent invalid fades from being reused from previous transitions.
        prepareFadeOut(None);
        prepareFadeIn(None, onTransOutDone);

      case TransitionType.LoadingScreen(fadeIn, fadeOut):
        var onTransOutDone:Void->Void = () ->
        {
          FlxStateUtil.openSubStateAtTop(new FunkayLoadingState(State(builder), params));
        };

        prepareFadeOut(fadeOut);
        prepareFadeIn(fadeIn, onTransOutDone);

      case TransitionType.BlackScreen(fadeIn, fadeOut):
        var onTransOutDone:Void->Void = () ->
        {
          FlxStateUtil.openSubStateAtTop(new LoadingState(State(builder), params));
        };

        prepareFadeOut(fadeOut);
        prepareFadeIn(fadeIn, onTransOutDone);

      case TransitionType.BlackWithThrobber(fadeIn, fadeOut):
        var onTransOutDone:Void->Void = () ->
        {
          FlxStateUtil.openSubStateAtTop(new ThrobberLoadingState(State(builder), params, {
            transparent: false,
            delay: 0.0,
          }));
        };

        prepareFadeOut(fadeOut);
        prepareFadeIn(fadeIn, onTransOutDone);

      case TransitionType.Throbber:
        var onTransOutDone:Void->Void = () ->
        {
          FlxStateUtil.openSubStateAtTop(new ThrobberLoadingState(State(builder), params, {
            transparent: true,
            delay: 1.0,
          }));
        };

        // Make sure to reset the fade to None,
        // to prevent invalid fades from being reused from previous transitions.
        prepareFadeOut(None);
        prepareFadeIn(None, onTransOutDone);

      case TransitionType.Sticker(stickerPack):
        // params.shouldPurgeCache = false;
        var stickerLoadingState:StickerLoadingState = new StickerLoadingState(State(builder), params, {
          stickerPack: stickerPack
        });

        prepareStickerOut(stickerLoadingState);
        prepareStickerIn(stickerLoadingState);

      case TransitionType.Custom(name, fadeIn, fadeOut):
        var onTransOutDone:Void->Void = () ->
        {
          var loadingState:LoadingState = createCustomLoadingState(name, State(builder), params);
          FlxStateUtil.openSubStateAtTop(loadingState);
        };

        prepareFadeOut(fadeOut);
        prepareFadeIn(fadeIn, onTransOutDone);
    }
  }

  /**
   * Open the target substate on top of the current state (or substate), with a defined transition between.
   * Ensures all the assets require for that substate are loaded before continuing.
   * @param targetSubState The substate to transition to.
   * @param params Parameters for the transition.
   */
  public static function openSubState(targetSubState:NextSubState, params:TransitionParams):Void
  {
    if (isTransitionActive())
    {
      trace('[TRANSITION] Replacing the active transition with a new substate transition.');
      cancelActiveTransition();

      // Im fingering the devil
      new FlxTimer().start(0, (_) -> openSubState(targetSubState, params));
      return;
    }

    params = validateParams(params);

    var builder = () ->
    {
      return targetSubState.createInstance();
    };

    if (params.onConstruct != null)
    {
      builder = () ->
      {
        var result:FlxSubState = targetSubState.createInstance();
        params.onConstruct(result);
        return result;
      };
    }

    var transitionType:TransitionType = params?.transition ?? TransitionType.BlackScreen(FadeType.None, FadeType.None);

    switch (transitionType)
    {
      case None:
        var onTransOutDone:Void->Void = () ->
        {
          FlxStateUtil.openSubStateAtTop(new LoadingState(FlxColor.TRANSPARENT, SubState(builder), params));
        };

        // Make sure to reset the fade to None,
        // to prevent invalid fades from being reused from previous transitions.
        prepareFadeOut(None);
        prepareFadeIn(None, onTransOutDone);

      case TransitionType.LoadingScreen(fadeIn, fadeOut):
        var onTransOutDone:Void->Void = () ->
        {
          FlxStateUtil.openSubStateAtTop(new FunkayLoadingState(SubState(builder), params));
        };

        prepareFadeOut(fadeOut);
        prepareFadeIn(fadeIn, onTransOutDone);

      case TransitionType.BlackScreen(fadeIn, fadeOut):
        var onTransOutDone:Void->Void = () ->
        {
          FlxStateUtil.openSubStateAtTop(new LoadingState(SubState(builder), params));
        };

        prepareFadeOut(fadeOut);
        prepareFadeIn(fadeIn, onTransOutDone);

      case TransitionType.BlackWithThrobber(fadeIn, fadeOut):
        var onTransOutDone:Void->Void = () ->
        {
          FlxStateUtil.openSubStateAtTop(new ThrobberLoadingState(SubState(builder), params, {
            transparent: false,
            delay: 0.0
          }));
        };

        prepareFadeOut(fadeOut);
        prepareFadeIn(fadeIn, onTransOutDone);

      case TransitionType.Throbber:
        var onTransOutDone:Void->Void = () ->
        {
          FlxStateUtil.openSubStateAtTop(new ThrobberLoadingState(SubState(builder), params, {
            transparent: true,
            delay: 1.0
          }));
        };

        // Make sure to reset the fade to None,
        // to prevent invalid fades from being reused from previous transitions.
        prepareFadeOut(None);
        prepareFadeIn(None, onTransOutDone);

      case TransitionType.Sticker(stickerPack):
        // params.shouldPurgeCache = false;
        var stickerLoadingState:StickerLoadingState = new StickerLoadingState(SubState(builder), params, {
          stickerPack: stickerPack
        });
        prepareStickerOut(stickerLoadingState);
        prepareStickerIn(stickerLoadingState);

      case TransitionType.Custom(name, fadeIn, fadeOut):
        var onTransOutDone:Void->Void = () ->
        {
          var loadingState:LoadingState = createCustomLoadingState(name, SubState(builder), params);
          FlxStateUtil.openSubStateAtTop(loadingState);
        };

        prepareFadeOut(fadeOut);
        prepareFadeIn(fadeIn, onTransOutDone);
    }
  }

  /**
   * Open and transition to a PlayState, with a defined transition between.
   * Ensures all the assets require for that PlayState are loaded before continuing.
   * @param playStateParams Parameters for the PlayState.
   * @param transitionParams Parameters for the transition.
   * @param asSubState Whether the PlayState should be opened as a substate or switched to as a state.
   */
  public static function openPlayState(playStateParams:PlayStateParams,
    transitionParams:BaseTransitionParams,
    asSubState:Bool = false):Void
  {
    // Get the list of assets we need in order to parse the charts.
    var priorityAssetQuery:(AssetType) -> Array<AssetPath> = (type:AssetType) ->
    {
      var results:Array<AssetPath> = [];

      if (type == JSON)
      {
        // results.appendUnique(SongRegistry.instance.queryAssets(JSON, playStateParams.targetSong.id, {
        //   variation: playStateParams.targetVariation
        // }));
      }

      return results;
    };

    var assetQuery:(AssetType) -> Array<AssetPath> = PlayState.queryAssets.bind(_, playStateParams);

    // Parse the charts in an async queue, so the rest of the asset query will be valid.
    transitionParams.onPriorityAssetsLoaded = (onProgress:(loaded:Int, total:Int) -> Void,
      onComplete:() -> Void) ->
    {
      trace('[LOADING] Queuing task handler...');
      var future = TaskHandler.performSimpleTask(() ->
      {
        trace('[LOADING] Caching charts...');
        final targetDifficulty = playStateParams.targetSong.getDifficulty(
          playStateParams.targetDifficulty, playStateParams.targetVariation
        );
        if (targetDifficulty?.notes == null)
        {
          var forceReload:Bool = true;
          playStateParams.targetSong.cacheCharts(forceReload);
        }
        else
        {
          trace('[LOADING] Using chart data already loaded into target Song.');
        }
        return true;
      });
      future.onComplete((_) -> onComplete());
    };

    // Perform additional tasks in an async queue.
    transitionParams.onAssetsLoaded = (onProgress:(loaded:Int, total:Int) -> Void,
      onComplete:() -> Void) ->
    {
      trace('[LOADING] Queuing task handler...');
      var future = TaskHandler.performSimpleTask(() ->
      {
        // Left this function as a template in case we need to do work post-loading.
        return true;
      });
      future.onComplete((_) -> onComplete());
    };

    if (asSubState)
    {
      var targetSubState:NextSubState = () ->
      {
        var result = new PlayState(playStateParams);
        if (transitionParams.onConstruct != null) transitionParams.onConstruct(result);
        return result;
      };
      Transition.openSubState(targetSubState, buildTransitionParams(assetQuery, priorityAssetQuery, transitionParams));
    }
    else
    {
      var targetState:NextState = () ->
      {
        var result = new PlayState(playStateParams);
        if (transitionParams.onConstruct != null) transitionParams.onConstruct(result);
        return result;
      };
      Transition.switchState(targetState, buildTransitionParams(assetQuery, priorityAssetQuery, transitionParams));
    }
  }

  static function createCustomLoadingState(className:String, target:TransitionTarget, params:TransitionParams):LoadingState
  {
    var loadingState:Null<LoadingState> = LoadingState.scriptInit(className, target, params);
    if (loadingState != null) return loadingState;

    trace('[TRANSITION] Failed to create scripted loading state "${className}". Falling back to the default loading screen.');
    return new LoadingState(FlxColor.BLACK, target, params);
  }

  static function prepareFadeIn(fadeType:FadeType, onTransOutDone:() -> Void):Void
  {
    // Fade out of the loading state corresponds to fade in on the next state.
    switch (fadeType)
    {
      case FadeType.Fade(dir, duration):
        FlxTransitionableState.skipNextTransOut = false;

        FlxTransitionableState.defaultTransOut = buildTransitionData(fadeType, duration);

        var currentState:FlxState = FlxG.state;
        if (Std.isOfType(currentState, FlxTransitionableState))
        {
          var currentTransState:FlxTransitionableState = cast currentState;
          currentTransState.transOut = FlxTransitionableState.defaultTransOut;
          currentTransState.transitionOut(onTransOutDone);
        }
        else if (Std.isOfType(currentState, FlxTransitionableSubState))
        {
          var currentTransState:FlxTransitionableSubState = cast currentState;
          currentTransState.transOut = FlxTransitionableState.defaultTransOut;
          currentTransState.transitionOut(onTransOutDone);
        }
        else
        {
          // Call immediately.
          onTransOutDone();
        }
      case FadeType.DiamondTile | FadeType.CircleTile | FadeType.SquareTile:
        FlxTransitionableState.skipNextTransOut = false;

        FlxTransitionableState.defaultTransOut = buildTransitionData(fadeType);

        var currentState:FlxState = FlxG.state;
        if (Std.isOfType(currentState, FlxTransitionableState))
        {
          var currentTransState:FlxTransitionableState = cast currentState;
          currentTransState.transOut = FlxTransitionableState.defaultTransOut;
          currentTransState.transitionOut(onTransOutDone);
        }
        else if (Std.isOfType(currentState, FlxTransitionableSubState))
        {
          var currentTransState:FlxTransitionableSubState = cast currentState;
          currentTransState.transOut = FlxTransitionableState.defaultTransOut;
          currentTransState.transitionOut(onTransOutDone);
        }
        else
        {
          // Call immediately.
          onTransOutDone();
        }
      case FadeType.None:
        // Nothing
        FlxTransitionableState.skipNextTransOut = true;

        FlxTransitionableState.defaultTransOut = null;

        var currentState:FlxState = FlxG.state;
        if (Std.isOfType(currentState, FlxTransitionableState))
        {
          var currentTransState:FlxTransitionableState = cast currentState;
          currentTransState.transOut = null;
          currentTransState.transitionOut(onTransOutDone);
        }
        else if (Std.isOfType(currentState, FlxTransitionableSubState))
        {
          var currentTransState:FlxTransitionableSubState = cast currentState;
          currentTransState.transOut = null;
          currentTransState.transitionOut(onTransOutDone);
        }
        else
        {
          // Call immediately.
          onTransOutDone();
        }
    }
  }

  static function prepareFadeOut(fadeType:FadeType):Void
  {
    // Fade out of the loading state corresponds to fade in on the next state.
    switch (fadeType)
    {
      case FadeType.Fade(dir, duration):
        FlxTransitionableState.skipNextTransIn = false;

        FlxTransitionableState.defaultTransIn = buildTransitionData(fadeType, duration);
      case FadeType.DiamondTile | FadeType.CircleTile | FadeType.SquareTile:
        FlxTransitionableState.skipNextTransIn = false;

        FlxTransitionableState.defaultTransIn = buildTransitionData(fadeType);
      case FadeType.None:
        // Nothing
        FlxTransitionableState.skipNextTransIn = true;

        FlxTransitionableState.defaultTransIn = null;
    }
  }

  static function prepareStickerIn(state:StickerLoadingState):Void
  {
    var currentState:FlxState = FlxG.state;
    var stickerPackId:String = state.stickerPackId;

    // cache assets before touching the transition system.
    StickerTransition.cacheAssets(stickerPackId).onComplete((_) ->
    {
      var transData:TransitionData = new TransitionData(CUSTOM);
      transData.transitionState = state.buildTransition();

      FlxTransitionableState.skipNextTransOut = false;
      FlxTransitionableState.defaultTransOut = transData;

      if (Std.isOfType(currentState, FlxTransitionableState))
      {
        var currentTransState:FlxTransitionableState = cast currentState;
        currentTransState.transOut = transData;
        currentTransState.transitionOut(() ->
        {
          trace('Transition into sticker state is done.');
          FlxStateUtil.openSubStateAtTop(state, currentState);
        });
      }
      else if (Std.isOfType(currentState, FlxTransitionableSubState))
      {
        var currentTransState:FlxTransitionableSubState = cast currentState;
        currentTransState.transOut = transData;
        currentTransState.transitionOut(() ->
        {
          trace('Transition into sticker state is done.');
          FlxStateUtil.openSubStateAtTop(state, currentState);
        });
      }
      else
      {
        // Call immediately.
        trace('[WARNING] Cannot play transition on non-transition state: ${Type.typeof(currentState)}');
        FlxStateUtil.openSubStateAtTop(state, currentState);
      }
    });
  }

  static function prepareStickerOut(state:StickerLoadingState):Void
  {
    var transData:TransitionData = new TransitionData(CUSTOM);
    transData.transitionState = state.buildTransition();

    FlxTransitionableState.skipNextTransIn = false;
    FlxTransitionableState.defaultTransIn = transData;
  }

  static function buildTransitionData(fadeType:FadeType, duration:Float = 0.5):Null<TransitionData>
  {
    // Color of the transition graphic.
    var color:FlxColor = FlxColor.BLACK;
    // Direction of the wipe.
    var direction:Null<FlxPoint> = new FlxPoint(0, -1);
    // The area of the screen to display the transition
    var region:Null<FlxRect> = new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4);
    // Which camera to use for the transition
    var cameraMode:TransitionCameraMode = TransitionCameraMode.TOP;

    switch (fadeType)
    {
      case FadeType.Fade(dir):
        direction = dir.toPoint();

        var tileData:Null<TransitionTileData> = null;

        return new TransitionData(FADE, color, duration, direction, tileData, region, cameraMode);

      case FadeType.DiamondTile:
        // Diamond Transition
        var diamond:FlxGraphic = FlxGraphic.fromClass(flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond);
        diamond.persist = true;
        diamond.destroyOnNoUse = false;
        var tileData:TransitionTileData = {
          asset: diamond,
          width: 32,
          height: 32
        };

        // NOTE: tileData is ignored if TransitionData.type is FADE instead of TILES.
        return new TransitionData(TILES, color, duration, direction, tileData, region, cameraMode);

      case FadeType.CircleTile:
        // Circle Transition
        var circle:FlxGraphic = FlxGraphic.fromClass(flixel.addons.transition.FlxTransitionSprite.GraphicTransTileCircle);
        circle.persist = true;
        circle.destroyOnNoUse = false;
        var tileData:TransitionTileData = {
          asset: circle,
          width: 32,
          height: 32
        };

        // NOTE: tileData is ignored if TransitionData.type is FADE instead of TILES.
        return new TransitionData(TILES, color, duration, direction, tileData, region, cameraMode);

      case FadeType.SquareTile:
        // Square Transition
        var square:FlxGraphic = FlxGraphic.fromClass(flixel.addons.transition.FlxTransitionSprite.GraphicTransTileSquare);
        square.persist = true;
        square.destroyOnNoUse = false;
        var tileData:TransitionTileData = {
          asset: square,
          width: 32,
          height: 32
        };

        // NOTE: tileData is ignored if TransitionData.type is FADE instead of TILES.
        return new TransitionData(TILES, color, duration, direction, tileData, region, cameraMode);

      case FadeType.None:
        return null;
      default:
        return null;
    }
  }

  static function buildTransitionParams(assetQuery:Null<(AssetType) -> Array<AssetPath>>,
    ?priorityAssetQuery:(AssetType) -> Array<AssetPath>,
    base:BaseTransitionParams):TransitionParams
  {
    return validateParams({
      assetQuery: assetQuery ?? NO_ASSETS,
      priorityAssetQuery: priorityAssetQuery,

      transition: base.transition,
      shouldStopMusic: base.shouldStopMusic,
      shouldPurgeCache: base.shouldPurgeCache,
      onAssetsLoaded: base.onAssetsLoaded,
      onPriorityAssetsLoaded: base.onPriorityAssetsLoaded,
      onConstruct: base.onConstruct,
    });
  }

  static function validateParams(params:TransitionParams):TransitionParams
  {
    // TODO: Use reflection to automatically fetch the assetQuery function
    if (params.assetQuery == null) params.assetQuery = NO_ASSETS;
    // params.priorityAssetQuery can be null

    // Fall back Null<any optional parameters are excluded>.
    if (params.transition == null) params.transition = TransitionType.BlackScreen(FadeType.None, FadeType.None);
    if (params.shouldStopMusic == null) params.shouldStopMusic = false;
    if (params.shouldPurgeCache == null) params.shouldPurgeCache = true;
    // params.onAssetsLoaded can be null
    // params.onPriorityAssetsLoaded can be null
    // params.onConstruct can be null

    return params;
  }
}

/**
 * Provides data on what the transition looks like.
 * Does it use a loading screen? How does it fade into and out of that loading screen?
 */
enum TransitionType
{
  /**
   * Move to the lime green loading screen.
   * @param fadeIn Define how to transition to the loading screen.
   * @param fadeOut Define how to transition from the loading screen.
   */
  LoadingScreen(fadeIn:FadeType, fadeOut:FadeType);

  /**
   * Move to a black screen with no loading indicators.
   * The default transition.
   * @param fadeIn Define how to transition to the black screen.
   * @param fadeOut Define how to transition from the black screen.
   */
  BlackScreen(fadeIn:FadeType, fadeOut:FadeType);

  /**
   * Display no loading screen, transition, or loading indicators at all.
   * Only suitable for very short loading screens.
   */
  None;

  /**
   * Move to a black screen with a throbber in the bottom right.
   * @param fadeIn Define how to transition to the black screen.
   * @param fadeOut Define how to transition from the black screen.
   */
  BlackWithThrobber(fadeIn:FadeType, fadeOut:FadeType);

  /**
   * Display no transition, but display a throbber in the bottom right.
   * Since the background is transparent and the throbber only appears after a delay,
   * this essentially acts like None, but with a guard to show a throbber only if loading takes longer than expected.
   * Suitable for when you need a loading screen but don't want to switch to another screen.
   */
  Throbber;

  /**
   * Use the transition which covers the screen in stickers, then removes them.
   * fadeIn and fadeOut are both custom here.
   */
  Sticker(stickerPack:String);

  /**
   * Use a scripted LoadingState class to display the loading screen.
   * The class must extend LoadingState and provide a constructor accepting
   * (target:TransitionTarget, params:TransitionParams).
   * @param name The fully-qualified name of the scripted LoadingState class.
   * @param fadeIn Define how to transition to the loading screen.
   * @param fadeOut Define how to transition from the loading screen.
   */
  Custom(name:String, fadeIn:FadeType, fadeOut:FadeType);
}

/**
 * Represents either the state or substate we are transitioning to.
 */
enum TransitionTarget
{
  State(nextState:NextState);
  SubState(subState:NextSubState);
}

/**
 * Provides data on how to transition to and from the loading screen.
 * Fading? Tiling? No transition?
 */
enum FadeType
{
  /**
   * No fade, hard cut to whatever view we want to display during loading.
   */
  None;

  /**
   * A fade transition in a certain direction.
   * @param dir The direction to fade towards.
   * @param duration The duration of the fade. Default to 1 second.
   */
  Fade(dir:FadeDirection, ?duration:Float);

  /**
   * A diamond-shaped tiled transition.
   * WARNING: These lag the game to hell and I'm not sure how to make it better.
   */
  DiamondTile;

  /**
   * A circle-shaped tiled transition.
   * WARNING: These lag the game to hell and I'm not sure how to make it better.
   */
  CircleTile;

  /**
   * A square-shaped tiled transition.
   * WARNING: These lag the game to hell and I'm not sure how to make it better.
   */
  SquareTile;
}

/**
 * When fading, represents the direction to fade towards.
 * You can fade orthogonally or diagonally.
 */
enum abstract FadeDirection(String)
{
  /**
   * Fade towards the north
   */
  public var North = 'North';

  /**
   * Fade towards the north-east
   */
  public var NorthEast = 'NorthEast';

  /**
   * Fade towards the north-west
   */
  public var NorthWest = 'NorthWest';

  /**
   * Fade towards the south
   */
  public var South = 'South';

  /**
   * Fade towards the south-east
   */
  public var SouthEast = 'SouthEast';

  /**
   * Fade towards the south-west
   */
  public var SouthWest = 'SouthWest';

  /**
   * Fade towards the east
   */
  public var East = 'East';

  /**
   * Fade towards the west
   */
  public var West = 'West';

  /**
   * Represents the direction of the fade as a vector.
   * @return The direction to fade in as an FlxPoint.
   */
  public function toPoint():FlxPoint
  {
    switch (abstract)
    {
      case FadeDirection.North:
        return new FlxPoint(0, 1);
      case FadeDirection.NorthEast:
        return new FlxPoint(1, 1);
      case FadeDirection.NorthWest:
        return new FlxPoint(-1, 1);
      case FadeDirection.South:
        return new FlxPoint(0, -1);
      case FadeDirection.SouthEast:
        return new FlxPoint(1, -1);
      case FadeDirection.SouthWest:
        return new FlxPoint(-1, -1);
      case FadeDirection.East:
        return new FlxPoint(1, 0);
      case FadeDirection.West:
        return new FlxPoint(-1, 0);
    }
  }
}
