package funkin.ui.transition.stickers;

import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.util.HapticUtil;
import funkin.data.stickers.StickerRegistry;
import funkin.graphics.FunkinSprite;
import funkin.ui.freeplay.FreeplayState;
import funkin.ui.MusicBeatSubState;
import funkin.ui.transition.stickers.StickerPack;
import funkin.FunkinMemory;
import funkin.util.DeviceUtil;

using Lambda;
using StringTools;

typedef StickerSubStateParams =
{
  /*
   * The state to transition into.
   */
  ?targetState:StickerSubState->FlxState,

  /**
   * The sticker pack to retrieve and use.
   * @default `Constants.DEFAULT_STICKER_PACK`
   */
  ?stickerPack:String,

  /**
   * An existing set of stickers to transition out with.
   */
  ?oldStickers:Array<StickerSprite>,
}

@:nullSafety
class StickerSubState extends MusicBeatSubState
{
  public var grpStickers:FlxTypedGroup<StickerSprite>;

  /**
   * The state to switch to after the stickers are done.
   * This is a FUNCTION so we can pass it directly to `FlxG.switchState()`,
   * and we can add constructor parameters in the caller.
   */
  var targetState:StickerSubState->FlxState;

  var stickerPackId:String;
  var stickerPack:StickerPack;

  // what "folders" to potentially load from (as of writing only "keys" exist)
  var soundSelections:Array<String> = [];
  // what "folder" was randomly selected
  var soundSelection:String = "";
  var sounds:Array<String> = [];

  public function new(params:StickerSubStateParams):Void
  {
    super();

    // Define the target state, with a default fallback.
    this.targetState = params?.targetState ?? (sticker) -> FreeplayState.build(null, sticker);

    this.stickerPackId = params.stickerPack ?? Constants.DEFAULT_STICKER_PACK;

    var targetStickerPack = StickerRegistry.instance.fetchEntry(this.stickerPackId);

    this.stickerPack = targetStickerPack ?? StickerRegistry.instance.fetchDefault();

    // TODO: Make this tied to the sticker pack more closely.
    var assetsInList = Assets.list();
    var soundFilterFunc = function(a:String) {
      return a.startsWith('assets/shared/sounds/stickersounds/');
    };
    soundSelections = assetsInList.filter(soundFilterFunc);
    soundSelections = soundSelections.map(function(a:String) {
      return a.replace('assets/shared/sounds/stickersounds/', '').split('/')[0];
    });

    grpStickers = new FlxTypedGroup<StickerSprite>();
    add(grpStickers);

    // cracked cleanup... yuchh...
    for (i in soundSelections)
    {
      while (soundSelections.contains(i))
      {
        soundSelections.remove(i);
      }
      soundSelections.push(i);
    }

    soundSelection = FlxG.random.getObject(soundSelections);

    var filterFunc = function(a:String) {
      return a.startsWith('assets/shared/sounds/stickersounds/' + soundSelection + '/');
    };
    var assetsInList3 = Assets.list();
    sounds = assetsInList3.filter(filterFunc);
    for (i in 0...sounds.length)
    {
      sounds[i] = sounds[i].replace('assets/shared/sounds/', '');
      sounds[i] = sounds[i].substring(0, sounds[i].lastIndexOf('.'));
    }

    // makes the stickers on the most recent camera, which is more often than not... a UI camera!!
    // grpStickers.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    grpStickers.cameras = FlxG.cameras.list;

    if (params.oldStickers != null)
    {
      for (sticker in params.oldStickers)
      {
        grpStickers.add(sticker);
      }

      degenStickers();
    }
    else
    {
      regenStickers();
    }
  }

  public function degenStickers():Void
  {
    grpStickers.cameras = FlxG.cameras.list;

    /*
      if (dipshit != null)
      {
        FlxG.removeChild(dipshit);
        dipshit = null;
      }
     */

    if (grpStickers.members == null || grpStickers.members.length == 0)
    {
      switchingState = false;
      close();
      return;
    }

    for (ind => sticker in grpStickers.members)
    {
      new FlxTimer().start(sticker.timing, _ -> {
        sticker.visible = false;
        var daSound:String = FlxG.random.getObject(sounds);
        FunkinSound.playOnce(Paths.sound(daSound));

        // Do the small vibration each time sticker disappears.
        HapticUtil.vibrate(0, 0.01, Constants.MIN_VIBRATION_AMPLITUDE * 0.5);

        if (grpStickers == null || ind == grpStickers.members.length - 1)
        {
          switchingState = false;
          FunkinMemory.clearStickers();
          close();
        }
      });
    }
  }

  function regenStickers():Void
  {
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

      new FlxTimer().start(sticker.timing, _ -> {
        if (grpStickers == null) return;

        sticker.visible = true;
        var daSound:String = FlxG.random.getObject(sounds);
        FunkinSound.playOnce(Paths.sound(daSound));

        // Do the small vibration each time sticker appears.
        HapticUtil.vibrate(0, 0.01, Constants.MIN_VIBRATION_AMPLITUDE * 0.5);

        var frameTimer:Int = FlxG.random.int(0, 2);

        // always make the last one POP
        if (ind == grpStickers.members.length - 1) frameTimer = 2;

        new FlxTimer().start((1 / 24) * frameTimer, _ -> {
          if (sticker == null) return;

          sticker.scale.x = sticker.scale.y = FlxG.random.float(0.97, 1.02);

          if (ind == grpStickers.members.length - 1)
          {
            switchingState = true;

            FlxTransitionableState.skipNextTransIn = true;
            FlxTransitionableState.skipNextTransOut = true;

            // I think this grabs the screen and puts it under the stickers?
            // Leaving this commented out rather than stripping it out because it's cool...
            /*
              dipshit = new Sprite();
              var scrn:BitmapData = new BitmapData(FlxG.width, FlxG.height, true, 0x00000000);
              var mat:Matrix = new Matrix();
              scrn.draw(grpStickers.cameras[0].canvas, mat);

              var bitmap:Bitmap = new Bitmap(scrn);

              dipshit.addChild(bitmap);
              // FlxG.addChildBelowMouse(dipshit);
             */
            FlxG.signals.preStateSwitch.addOnce(function() {
              #if ios
              trace(DeviceUtil.iPhoneNumber);
              if (DeviceUtil.iPhoneNumber > 12) funkin.FunkinMemory.purgeCache(true);
              else
                funkin.FunkinMemory.purgeCache();
              #else
              funkin.FunkinMemory.purgeCache(true);
              #end
            });
            FlxG.switchState(() -> {
              // TODO: Rework this asset caching stuff
              // NOTE: This has to come AFTER the state switch,
              // otherwise the game tries to render destroyed sprites!
              // FunkinSprite.preparePurgeCache();
              return targetState(this);
            });
          }
        });
      });
    }

    grpStickers.sort((ord, a, b) -> {
      return FlxSort.byValues(ord, a.timing, b.timing);
    });
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);
  }

  var switchingState:Bool = false;

  override public function close():Void
  {
    if (switchingState) return;
    super.close();
  }

  override public function destroy():Void
  {
    if (switchingState) return;
    super.destroy();
  }
}
