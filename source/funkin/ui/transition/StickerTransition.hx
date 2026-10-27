package funkin.ui.transition;

import flixel.FlxCamera;
import flixel.addons.transition.Transition as FlxTransition;
import flixel.addons.transition.TransitionData;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.ui.transition.stickers.StickerSprite;
import funkin.ui.transition.stickers.StickerPack;
import funkin.data.stickers.StickerRegistry;
import funkin.util.HapticUtil;
import funkin.assets.Paths.AssetPath;
import funkin.assets.Assets.AssetType;
import lime.app.Future;

using Lambda;
using StringTools;

/**
 * Parameters for performing a sticker transition.
 */
typedef StickerTransitionParams =
{
  /**
   * What sticker pack to use.
   */
  ?stickerPack:String,

  /**
   * The group to place the sticker sprites into.
   * This gets reused for the transition in, hold, and transition out.
   */
  stickerSpriteGroup:FlxTypedSpriteGroup<StickerSprite>,
}

/**
 * A custom FlxTransition which used to move into and out of a StickerLoadingState.
 * Plays animations and sounds for each sticker.
 */
@:nullSafety
class StickerTransition extends FlxTransition
{
  /**
   * Assets that used by sticker transitions are shared by IN/OUT transitions and therefore must survive the state purge that happens between states.
   */
  static var cachedPacks:Map<String, Future<Array<Future<Bool>>>> = [];

  public static function queryAssets(type:AssetType, ?stickerPackId:String):Array<AssetPath>
  {
    var packId:String = stickerPackId ?? Constants.DEFAULT_STICKER_PACK;
    var results:Array<AssetPath> = [];

    switch (type)
    {
      case IMAGE:
        results.appendUnique(StickerRegistry.instance.queryAssets(type, packId));
      case SOUND:
        for (i in 1...(8 + 1))
        {
          results.push(funkin.assets.Paths.sound('ui/loading/stickers/sounds/key-click-$i'));
        }
      default:
        // Nothing.
    }

    return results;
  }

  public static function cacheAssets(?stickerPackId:String):Future<Array<Future<Bool>>>
  {
    var packId:String = stickerPackId ?? Constants.DEFAULT_STICKER_PACK;

    var existing:Null<Future<Array<Future<Bool>>>> = cachedPacks.get(packId);
    if (existing != null && !existing.isComplete) return existing;

    var assets:Array<AssetPath> = [];
    assets.append(queryAssets(IMAGE, packId));
    assets.append(queryAssets(SOUND, packId));
    assets = assets.distinct(AssetPath.equals);

    var future:Future<Array<Future<Bool>>> = funkin.assets.Assets.cacheAll(assets, true);
    cachedPacks.set(packId, future);
    future.onError((error) ->
    {
      //retry if the first load failed
      if (cachedPacks.get(packId) == future) cachedPacks.remove(packId);
      trace('[STICKER TRANSITION] Failed to cache assets for pack "$packId": $error');
    });
    return future;
  }

  public static function ensureCached(?stickerPackId:String):Void
  {
    cacheAssets(stickerPackId);
  }

  var grpStickers:FlxTypedSpriteGroup<StickerSprite>;
  var stickerPackId:String;
  var stickerPack:StickerPack;
  var sounds:Array<String> = [];

  public function new(params:StickerTransitionParams):Void
  {
    super(new TransitionData(CUSTOM));

    this.stickerPackId = params.stickerPack ?? Constants.DEFAULT_STICKER_PACK;

    var targetStickerPack:Null<StickerPack> = StickerRegistry.instance.fetchEntry(this.stickerPackId);

    this.stickerPack = targetStickerPack ?? StickerRegistry.instance.fetchDefault();

    this.grpStickers = params.stickerSpriteGroup;

    // makes the stickers on the most recent camera, which is more often than not... a UI camera!!
    // this.grpStickers.cameras = FlxG.cameras.list;

    this.sounds = [for (i in 1...(8 + 1)) Paths.sound('ui/loading/stickers/sounds/key-click-$i')];

    // add(this.grpStickers);

    // Handle FlxAddon transition junk.
    remove(this._effect);
    @:nullSafety(Off)
    this._effect = null;
  }

  var transStatus:TransitionStatus = NULL;

  override public function start(newStatus:TransitionStatus):Void
  {
    transStatus = newStatus;

    setStatus(newStatus);

    switch (newStatus)
    {
      case IN:
        trace('Starting sticker transition!');
        regenStickers();
      case OUT:
        trace('Ending sticker transition!');
        degenStickers();
      default:
        // Nothing
    }
  }

  override public function setStatus(newStatus:TransitionStatus):Void
  {
    if (grpStickers?.group == null)
    {
      throw "StickerTransition is invalid! Was it destroyed?";
    }

    switch (newStatus)
    {
      case EMPTY:
        trace('Sticker transition status: EMPTY');
        this.grpStickers.clear();
      case IN:
        trace('Sticker transition status: IN');
      case FULL:
        trace('Sticker transition status: FULL');
        trace('Reviving group with ${grpStickers.members.length} stickers.');
      case OUT:
        trace('Sticker transition status: OUT');
      case NULL:
        trace('Sticker transition status: NULL');
    }
    transStatus = newStatus;
  }

  var customCamera:Null<FlxCamera> = null;

  function addNewCamera():FlxCamera
  {
    if (customCamera == null)
    {
      customCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height);
    }
    if (customCamera == null || customCamera.flashSprite == null)
    {
      throw "Failed to initialize camera!";
    }

    customCamera.bgColor = 0x0;
    customCamera.zIndex = 10;
    FlxG.cameras.add(customCamera, false);
    this.camera = customCamera;

    return customCamera;
  }

  override function get_finishCallback():Void->Void
  {
    return this.onTransitionFinish;
  }

  override function set_finishCallback(callback:Void->Void):Void->Void
  {
    trace('Setting StickerTransition.onTransitionFinish...');
    this.onTransitionFinish = callback;
    return this.onTransitionFinish;
  }

  /**
   * Called when the transition is finished.
   * Override by using `transition.onTransitionFinish = function()`
   */
  public dynamic function onTransitionFinish():Void
  {
    trace('Transition finished!');
  }

  /**
   * Remove the stickers from the screen, playing sound effects.
   */
  function degenStickers():Void
  {
    this.grpStickers.camera = addNewCamera();
    add(this.grpStickers);

    if (grpStickers.members == null || grpStickers.members.length == 0)
    {
      return;
    }

    for (ind => sticker in grpStickers.members)
    {
      new FlxTimer().start(sticker.timing, _ ->
      {
        var isLastSticker:Bool = grpStickers == null || ind == grpStickers.members.length - 1;

        // Remove each sticker in turn.
        sticker.visible = false;

        // Sometimes play a sound.
        // If we play a sound with EVERY sticker, the audio engine gets overwhelmed.
        var shouldPlaySound:Bool = isLastSticker || FlxG.random.bool(20); // 20%
        if (shouldPlaySound)
        {
          var nextSound:String = FlxG.random.getObject(sounds);
          FunkinSound.playOnce(nextSound);
        }

        // Do the small vibration each time sticker disappears.
        HapticUtil.vibrate(0, 0.01, Constants.MIN_VIBRATION_AMPLITUDE * 0.5);

        if (isLastSticker)
        {
          onLastStickerRemoved();
        }
      });
    }
  }

  function onLastStickerPlaced():Void
  {
    if (onTransitionFinish != null) onTransitionFinish();
  }

  function onLastStickerRemoved():Void
  {
    if (onTransitionFinish != null) onTransitionFinish();
  }

  /**
   * Place the stickers on the screen, playing sound effects.
   */
  function regenStickers():Void
  {
    this.grpStickers.camera = addNewCamera();
    add(this.grpStickers);

    if (grpStickers.members.length > 0)
    {
      grpStickers.clear();
    }

    // Initialize stickers at each point on the screen, then shuffle up the order they will get placed.
    // This ensures stickers consistently cover the screen.
    var xPos:Float = -100;
    var yPos:Float = -100;
    while (xPos <= FlxG.width)
    {
      var stickerPath:String = stickerPack.getRandomStickerPath(false);
      var sticky:StickerSprite = new StickerSprite(0, 0, stickerPath);
      sticky.visible = false;

      sticky.x = xPos;
      sticky.y = yPos;
      xPos += sticky.frameWidth * 0.5;

      if (xPos >= FlxG.width)
      {
        if (yPos <= FlxG.height)
        {
          xPos = -100;
          yPos += FlxG.random.float(70, 120);
        }
      }

      sticky.angle = FlxG.random.int(-60, 70);
      grpStickers.add(sticky);
    }

    FlxG.random.shuffle(grpStickers.members);

    // Creates a new sticker for the very center.
    var lastStickerPath:String = stickerPack.getRandomStickerPath(true);
    var lastSticker:StickerSprite = new StickerSprite(0, 0, lastStickerPath);
    lastSticker.visible = false;
    lastSticker.updateHitbox();
    lastSticker.angle = 0;
    lastSticker.screenCenter();
    grpStickers.add(lastSticker);

    // another damn for loop... apologies!!!
    for (ind => sticker in grpStickers.members)
    {
      sticker.timing = FlxMath.remapToRange(ind, 0, grpStickers.members.length, 0, 0.9);

      new FlxTimer().start(sticker.timing, _ ->
      {
        if (grpStickers == null) return;

        sticker.visible = true;
        var daSound:String = FlxG.random.getObject(sounds);
        FunkinSound.playOnce(daSound);

        // Do the small vibration each time sticker appears.
        HapticUtil.vibrate(0, 0.01, Constants.MIN_VIBRATION_AMPLITUDE * 0.5);

        var frameTimer:Int = FlxG.random.int(0, 2);

        // always make the last one POP
        if (ind == grpStickers.members.length - 1) frameTimer = 2;

        new FlxTimer().start((1 / 24) * frameTimer, _ ->
        {
          if (sticker == null) return;

          sticker.scale.x = sticker.scale.y = FlxG.random.float(0.97, 1.02);

          if (ind == grpStickers.members.length - 1)
          {
            onLastStickerPlaced();
          }
        });
      });
    }

    grpStickers.sort((ord, a, b) ->
    {
      return FlxSort.byValues(ord, a.timing, b.timing);
    });
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);
  }

  override public function destroy():Void
  {
    remove(grpStickers);

    super.destroy();
  }
}
