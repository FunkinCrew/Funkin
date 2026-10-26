package funkin.ui.modmenu;

import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.graphics.framebuffer.DropShadowLayer;
import funkin.graphics.shaders.PureColor;
import funkin.ui.FullScreenScaleMode;
import funkin.ui.MusicBeatState;
import funkin.ui.modmenu.ModMenuCharacter.CharacterAnimation;

/**
 * Pretty weird one but basically this is everything visually visible on the camera in Mod Menu. Like, BF,
 * GF, the electric chair etc.
 *
 * This is NOT a display group on purpose. Everything is added straight to the state so the index ordering and dropshadow
 * layering are all nice and jiffy.
 * Oh and this class isn't responsible for managing mod lists and whatnot, it just gets the enabled mods, puts them up, does
 * all the animation shtuff, nothing more.
 */
class ModMenuScene
{
  // Timing fields, in seconds.
  static inline final SHOCK_DURATION:Float = 81 / 24;
  static inline final BLACKOUT_DURATION:Float = 2 / 24;
  static inline final SMOKE_CLOUD_FADE_DURATION:Float = 62 / 24;
  static inline final CRISPY_SFX_DELAY:Float = 0.7;
  static inline final GF_RESUME_DELAY:Float = 0.3;

  /**
   * How long after the sequence finishes before `updateAftermath()` reports it's done.
   */
  static inline final AFTERMATH_DURATION:Float = 2.5;

  /**
   * The blinking timer is reset when it reaches this number.
   */
  static inline final BLINK_TIMER_RESET:Float = 100;

  static inline final BLACKOUT_COLOR:FlxColor = 0xFF232327;

  /**
   * BF in the mod menu.
   */
  public var bf(default, null):ModMenuCharacter;

  /**
   * GF in the mod menu.
   */
  public var gf(default, null):ModMenuCharacter;

  /**
   * The car battery.
   */
  public var carBattery(default, null):FunkinSprite;

  /**
   * Whether the shock part of the electrocution sequence is still running.
   */
  public var isShocking(get, never):Bool;

  function get_isShocking():Bool
  {
    return shockTimer.active;
  }

  /**
   * Whether or not the electrocution sequence has finished.
   */
  public var isFinished:Bool = false;

  // Otherrrrrr
  final modmenuInstance:ModMenuState;
  final camera:FunkinCamera;
  final dropShadow:DropShadowLayer;
  final getEnabledModIds:Void->Array<String>;
  var gfWire:FunkinSprite;
  var bgWires:FunkinSprite;
  var fgWiresBottom:FunkinSprite;
  var fgWiresTop:FunkinSprite;
  var crispySmokeBF:FunkinSprite;
  var crispySmokeGF:FunkinSprite;
  var smokeCloud:FunkinSprite;
  var sparks:ModMenuSparks;
  final whiteColor:PureColor = new PureColor(FlxColor.WHITE);
  final shockTimer:FlxTimer = new FlxTimer();
  var blinkTimer:Float = 0;
  var bfBlink:Float = 0;
  var gfBlink:Float = 0;
  var crispyTimer:Float = 0;
  var playedCrispySFX:Bool = false;

  /**
   * @param modmenuInstance The state the sprites are added to.
   * @param camera The camera every sprite in the scene is drawn on.
   * @param dropShadow The drop shadow layer that renders the characters camera.
   * @param getEnabledModIds Returns the IDs of the mods currently enabled in the menu.
   */
  public function new(instance:ModMenuState,
    camera:FunkinCamera,
    dropShadow:DropShadowLayer,
    getEnabledModIds:Void->Array<String>)
  {
    this.modmenuInstance = instance;
    this.camera = camera;
    this.dropShadow = dropShadow;
    this.getEnabledModIds = getEnabledModIds;
  }

  /**
   * Caches the smoke graphics, since they're not drawn immediately.
   * TODO: Remove and replace with `queryAssets()` once async loading is done.
   */
  public static function cacheAssets():Void
  {
    var assetPaths:Array<String> = [
      'ui/mods/smoke',
      'ui/mods/smoke-cloud/spritemap1'
    ];

    for (assetPath in assetPaths)
    {
      funkin.assets.Assets.cacheFlxGraphic(funkin.assets.Paths.image(assetPath));
    }
  }

  /**
   * Creates every sprite and adds it to the instance.
   * @param rightBoxX The X position of the right mod list box.
   */
  public function build(rightBoxX:Float):Void
  {
    carBattery = new FunkinSprite(rightBoxX + 475.6, FlxG.height * 0.11).loadSparrow('ui/mods/carbattery');
    carBattery.animation.addByPrefix('idle', 'idle', 24);
    carBattery.animation.play('idle');
    carBattery.animation.pause();
    carBattery.scale.set(0.75, 0.75);
    carBattery.updateHitbox();
    carBattery.zIndex = 20;
    carBattery.camera = camera;
    modmenuInstance.add(carBattery);

    gfWire = new FunkinSprite(carBattery.x - 117, carBattery.y - 18).loadSparrow('ui/mods/gfwire');
    gfWire.animation.addByPrefix('idle', 'idle0', 24, false);
    gfWire.animation.addByPrefix('idle-emptychair', 'idle empty chair0', 24, false);
    gfWire.animation.addByPrefix('shock', 'shock', 24, false);
    gfWire.animation.play('idle');
    gfWire.scale.set(0.7, 0.7);
    gfWire.updateHitbox();
    gfWire.zIndex = carBattery.zIndex + 1;
    gfWire.camera = camera;
    modmenuInstance.add(gfWire);

    bf = new ModMenuCharacter(carBattery.x - 119, carBattery.y + 50, 'bf');
    bf.camera = camera;
    bf.animation.onFinish.add((name:String) ->
    {
      bfBlink = nextBlinkTime(5);
    });
    bfBlink = nextBlinkTime(6);

    bf.zIndex = 30;
    modmenuInstance.add(bf);

    gf = new ModMenuCharacter(bf.x - 166, bf.y, 'gf', true);
    gf.camera = camera;
    gf.animation.onFinish.add((name:String) ->
    {
      gfBlink = nextBlinkTime(9);
    });
    gfBlink = 6 + nextBlinkTime(4);

    gf.zIndex = 25;
    modmenuInstance.add(gf);

    bgWires = new FunkinSprite(carBattery.x + 75, carBattery.y + 170).loadTexture('ui/mods/bgwires');
    bgWires.scale.set(0.7, 0.7);
    bgWires.updateHitbox();
    bgWires.zIndex = 10;
    bgWires.camera = camera;
    modmenuInstance.add(bgWires);

    fgWiresBottom = new FunkinSprite(bf.x - 144, bf.y + 446.5).loadTextureAtlas('ui/mods/foreground-wires-bottom');
    fgWiresBottom.anim.addByFrameLabel('idle', 'idle', 24);
    fgWiresBottom.anim.addByFrameLabel('idle-pinhead', 'idle pinhead', 24);
    fgWiresBottom.anim.addByFrameLabel('shock', 'shock', 24);
    fgWiresBottom.anim.addByFrameLabel('end', 'end', 24, false);
    fgWiresBottom.animation.play('idle');
    fgWiresBottom.scale.set(0.7, 0.7);
    fgWiresBottom.updateHitbox();
    fgWiresBottom.zIndex = 35;
    fgWiresBottom.camera = camera;
    modmenuInstance.add(fgWiresBottom);

    fgWiresTop = new FunkinSprite(bf.x + 257.5, bf.y - 90).loadTextureAtlas('ui/mods/foreground-wires-top');
    fgWiresTop.anim.addByFrameLabel('idle', 'idle', 24);
    fgWiresTop.anim.addByFrameLabel('shock', 'shock', 24);
    fgWiresTop.anim.addByFrameLabel('end', 'end', 24, false);
    fgWiresTop.animation.play('idle');
    fgWiresTop.scale.set(0.7, 0.7);
    fgWiresTop.updateHitbox();
    fgWiresTop.zIndex = 35;
    fgWiresTop.camera = camera;
    modmenuInstance.add(fgWiresTop);

    crispySmokeBF = new FunkinSprite(bf.x + 70, bf.y - 180).loadSparrow('ui/mods/smoke');
    crispySmokeBF.animation.addByPrefix('idle', 'retry_smoke', 24);
    // BF's smoke is supposed to be offset from GF's!
    crispySmokeBF.animation.play('idle', false, 13);
    crispySmokeBF.scale.set(0.5, 0.5);
    crispySmokeBF.updateHitbox();
    crispySmokeBF.camera = camera;

    crispySmokeGF = new FunkinSprite(gf.x + 70, gf.y - 180).loadSparrow('ui/mods/smoke');
    crispySmokeGF.animation.addByPrefix('idle', 'retry_smoke', 24);
    crispySmokeGF.animation.play('idle');
    crispySmokeGF.scale.set(0.5, 0.5);
    crispySmokeGF.updateHitbox();
    crispySmokeGF.camera = camera;

    crispySmokeBF.visible = false;
    crispySmokeGF.visible = false;

    crispySmokeBF.zIndex = bf.zIndex + 10;
    crispySmokeGF.zIndex = gf.zIndex + 10;

    // SIX SEVEEEEEENNNN!!!
    // (Yes, this is really the value from the FLA)
    crispySmokeBF.alpha = 0.67;
    crispySmokeGF.alpha = 0.67;

    modmenuInstance.add(crispySmokeBF);
    modmenuInstance.add(crispySmokeGF);

    smokeCloud = new FunkinSprite(carBattery.x - 415, -450).loadTextureAtlas('ui/mods/smoke-cloud', {
      useRenderTexture: true
    });
    smokeCloud.anim.addBySymbol('wholeTimeline', smokeCloud.getDefaultSymbol(), smokeCloud.library.frameRate, false);
    smokeCloud.visible = false;
    smokeCloud.scale.set(0.75, 0.75);
    smokeCloud.updateHitbox();
    smokeCloud.zIndex = 100;
    smokeCloud.camera = camera;
    modmenuInstance.add(smokeCloud);

    sparks = new ModMenuSparks();
    sparks.x = FullScreenScaleMode.gameCutoutSize.x / 2.5;
    sparks.zIndex = smokeCloud.zIndex + 1;
    sparks.camera = camera;
    modmenuInstance.add(sparks);
  }

  /**
   * Keeps the parts of the scene that shouldn't get drop shadow.
   * @param uiShadow The DropShadowLayer we use.
   */
  public function blacklistFromShadow(uiShadow:DropShadowLayer):Void
  {
    uiShadow.blacklistSprite(bgWires);
    uiShadow.blacklistSprite(crispySmokeBF);
    uiShadow.blacklistSprite(crispySmokeGF);
    uiShadow.blacklistSprite(sparks);
  }

  /**
   * Swaps BF and GF for the characters of the currently enabled mods.
   */
  public function changeCharacters():Void
  {
    var modIds:Array<String> = getEnabledModIds();

    bf.prepareToSwitch('mod-bf', modIds);

    gf.previousModId = bf.previousModId;
    gf.prepareToSwitch('mod-gf', modIds);

    // If one character can't be found, but the other one *was* found then we hide the one that can't be found.
    // An empty chair takes its place.
    if (modIds.length > 1)
    {
      if (bf.isPinhead && !gf.isPinhead)
      {
        bf.currentCharacterId = 'empty-chair';
      }
      else if (!bf.isPinhead && gf.isPinhead)
      {
        gf.currentCharacterId = 'empty-chair';
      }
    }

    var pendingCharacters:Int = 2;
    var onCharacterLoaded = () ->
    {
      pendingCharacters--;
      if (pendingCharacters > 0) return;

      gfWire.visible = !gf.hasCustomWires;
      fgWiresTop.visible = !bf.hasCustomWires;

      if (gf.currentCharacterId == 'empty-chair')
      {
        gfWire.zIndex = gf.zIndex + 1;
        gfWire.animation.play('idle-emptychair');
      }
      else
      {
        gfWire.zIndex = carBattery.zIndex + 1;
        gfWire.animation.play('idle');
      }

      fgWiresTop.animation.play('idle');

      if (bf.useSmallWire)
      {
        fgWiresBottom.animation.play('idle-pinhead');
      }
      else
      {
        fgWiresBottom.animation.play('idle');
      }

      modmenuInstance.refresh();
    };

    bf.switchCharacter(onCharacterLoaded);
    gf.switchCharacter(onCharacterLoaded);
  }

  /**
   * Refresh your eyes by manually closing and opening your lids! FUCK
   * @param elapsed Elapsed.
   */
  public function updateBlink(elapsed:Float):Void
  {
    blinkTimer += elapsed;

    if (blinkTimer >= BLINK_TIMER_RESET)
    {
      blinkTimer = 0;
      bfBlink = 0;
      gfBlink = 0;
    }

    if (blinkTimer >= bfBlink && bf.animation.finished)
    {
      bfBlink = nextBlinkTime(6);
      bf.playAnimation(IDLE);
    }

    if (blinkTimer >= gfBlink && gf.animation.finished)
    {
      gfBlink = nextBlinkTime(8);
      gf.playAnimation(IDLE);
    }
  }

  /**
   * The next time for a character should blink.
   * @param maxExtra
   */
  function nextBlinkTime(maxExtra:Float):Float
  {
    return blinkTimer + Math.random() + (Math.random() * maxExtra);
  }

  /**
   * Play the electrocution sequence
   *
   * @param onBlackout Called while the screen is black. Hide any UI that shouldn't be visible during the flash.
   * @param onRestore Called as the screen flashes back. Unhides the UI.
   */
  public function playElectrocutionSequence(onBlackout:Void->Void, onRestore:Void->Void):Void
  {
    bf.playAnimation(ELECTROCUTED, true);
    gf.playAnimation(ELECTROCUTED, true);

    carBattery.animation.resume();
    fgWiresBottom.animation.play('shock');

    gfWire.visible = true;
    gfWire.animation.play('shock');

    fgWiresTop.visible = true;
    fgWiresTop.animation.play('shock');

    sparks.startElectrocution();

    whiteColor.colorSet = true;

    dropShadow.blacklistSprite(gfWire);
    dropShadow.blacklistSprite(carBattery);
    dropShadow.blacklistSprite(fgWiresBottom);
    dropShadow.blacklistSprite(fgWiresTop);

    var blackFlash:FunkinSprite = new FunkinSprite(0, 0).makeSolidColor(FlxG.width, FlxG.height, BLACKOUT_COLOR);
    blackFlash.zIndex = 0;
    blackFlash.camera = camera;
    blackFlash.visible = false;
    modmenuInstance.add(blackFlash);
    modmenuInstance.refresh();

    shockTimer.start(SHOCK_DURATION, (_) ->
    {
      bf.shader = whiteColor;
      gf.shader = whiteColor;

      blackFlash.visible = true;

      carBattery.visible = false;
      gfWire.visible = false;
      fgWiresBottom.visible = false;
      fgWiresTop.visible = false;
      bgWires.visible = false;

      onBlackout();

      dropShadow.visible = false;
      dropShadow.whitelistSprite(gfWire);
      dropShadow.whitelistSprite(carBattery);
      dropShadow.whitelistSprite(fgWiresTop);
      dropShadow.whitelistSprite(fgWiresBottom);

      FlxTimer.wait(BLACKOUT_DURATION, () ->
      {
        FlxG.camera.flash(0xFFFFFFFF, 1 / 24, () ->
        {
          blackFlash.destroy();
          modmenuInstance.remove(blackFlash);
        });

        changeCharacters();
        onRestore();

        carBattery.visible = true;
        carBattery.animation.reset();

        smokeCloud.visible = true;
        smokeCloud.animation.play('wholeTimeline');

        FunkinSound.playOnce(Paths.sound('ui/mods/sounds/smoke-cloud').toString());

        sparks.endElectrocution();

        fgWiresBottom.visible = true;
        bgWires.visible = true;
        dropShadow.visible = true;

        FlxTween.tween(smokeCloud, {
          alpha: 0
        }, SMOKE_CLOUD_FADE_DURATION, {
          ease: FlxEase.linear,
          framerate: 24
        });

        bf.applyShader();
        gf.applyShader();

        showCrispyResult();

        crispyTimer = 0;
      });
    });
  }

  /**
   * Plays the crispy / idle anims after the swap, and the smoke if fried.
   */
  function showCrispyResult():Void
  {
    isFinished = true;

    var showSmokeBF:Bool = false;
    var showSmokeGF:Bool = false;

    if (bf.hasAnimation(CRISPY) && bf.previousModId == bf.currentModId)
    {
      showSmokeBF = true;
      bf.playAnimation(CRISPY, true);
    }
    else
    {
      bf.playAnimation(IDLE, true);
    }

    if (gf.hasAnimation(CRISPY) && gf.previousModId == gf.currentModId)
    {
      showSmokeGF = true;
      gf.playAnimation(CRISPY, true);
    }
    else
    {
      gf.playAnimation(IDLE, true);
      gf.animation.pause();
    }

    crispySmokeBF.x += bf.smokeOffsets[0];
    crispySmokeBF.y += bf.smokeOffsets[1];
    crispySmokeBF.scale.set(bf.smokeScale[0], bf.smokeScale[1]);
    crispySmokeBF.updateHitbox();

    crispySmokeGF.x += gf.smokeOffsets[0];
    crispySmokeGF.y += gf.smokeOffsets[1];
    crispySmokeGF.scale.set(gf.smokeScale[0], gf.smokeScale[1]);
    crispySmokeGF.updateHitbox();

    // Do not show the smoke on an empty chair... for obvious reasons.
    crispySmokeBF.visible = showSmokeBF && bf.currentCharacterId != 'empty-chair';
    crispySmokeGF.visible = showSmokeGF && gf.currentCharacterId != 'empty-chair';

    if (showSmokeBF)
    {
      fgWiresBottom.animation.play('end');
    }
  }

  /**
   * Skips the rest of the shock and jumps to the blackout.
   */
  public function skipShock():Void
  {
    @:privateAccess
    shockTimer.onLoopFinished();
    shockTimer.active = false;
  }

  /**
   * Drives the crispy sound and GF's resume after the swap. Call every frame once the shock is over.
   * @param elapsed Elapsed.
   * @return `true` once the aftermath has played out and the menu should apply the mod list.
   */
  public function updateAftermath(elapsed:Float):Bool
  {
    if (!isFinished) return false;

    crispyTimer += elapsed;

    if (bf.getCurrentAnimation() == CRISPY && gf.getCurrentAnimation() == CRISPY)
    {
      if (crispyTimer >= CRISPY_SFX_DELAY && !playedCrispySFX)
      {
        playedCrispySFX = true;
        FunkinSound.playOnce(Paths.sound('ui/mods/sounds/crispy').toString());
      }
    }

    if (crispyTimer >= GF_RESUME_DELAY && gf.animation.paused) gf.animation.resume();

    return crispyTimer >= AFTERMATH_DURATION;
  }
}
