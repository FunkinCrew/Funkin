package funkin.ui.charSelect;

import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.system.debug.watch.Tracker.TrackerProfile;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.data.freeplay.player.PlayerData.PlayerCharSelectData;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.BlueFade;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.save.Save;
import funkin.ui.PixelatedIcon;
import funkin.ui.charSelect.characters.CharSelectAtlasHandler;
import funkin.ui.charSelect.characters.CharSelectGF;
import funkin.ui.charSelect.characters.CharSelectPlayer;
import funkin.ui.charSelect.characters.Nametag;
import funkin.ui.charSelect.icons.IconGroup;
import funkin.ui.charSelect.icons.Lock;
import funkin.ui.freeplay.FreeplayState;
import funkin.ui.freeplay.charselect.PlayableCharacter;
import funkin.util.HapticUtil;
import funkin.util.MathUtil;
import funkin.vis.dsp.SpectralAnalyzer;
import openfl.display.BlendMode;
import openfl.filters.ShaderFilter;
#if FEATURE_NEWGROUNDS
import funkin.api.newgrounds.Medals;
#end
#if FEATURE_TOUCH_CONTROLS
import funkin.util.TouchUtil;
#end

/**
 * Parameters used to initialize the CharacterSelectState.
 */
typedef CharacterSelectStateParams =
{
  ?character:String
};

@:nullSafety
class CharacterSelectState extends MusicBeatSubState
{
  /**
   * A singleton instance of the Character Select screen.
   * There should only ever be one instance of this at a time.
   */
  public static var instance:Null<CharacterSelectState> = null;

  /**
   * The default index for the cursor.
   */
  public static final DEFAULT_CURSOR_INDEX:Int = 4;

  /**
   * The amount of slots per page.
   */
  public static final SLOTS_PER_PAGE:Int = 9;

  /**
   * The amount of slots per row.
   */
  public static var SLOTS_PER_ROW(get, never):Int;

  static function get_SLOTS_PER_ROW():Int
  {
    return Math.floor(Math.sqrt(SLOTS_PER_PAGE));
  }

  /**
   * An additional X offset for sprites on mobile devices.
   */
  public static var CUTOUT_SIZE(get, never):Float;

  static function get_CUTOUT_SIZE():Float
  {
    return FullScreenScaleMode.gameCutoutSize.x / 2;
  }

  /**
   * The speed to lerp the icons at when scrolling pages.
   */
  public static final SLOT_LERP_VALUE:Float = 0.1;

  /**
   * A `FunkinGroup` that holds all of the icons.
   */
  public var iconGroup:IconGroup = new IconGroup();

  /**
   * Alias for `this.iconGroup`.
   * Only here for backwards compatibility with mods.
   */
  @:deprecated("Use `this.iconGroup` instead.")
  public var grpIcons(get, never):IconGroup;

  function get_grpIcons():IconGroup
  {
    return iconGroup;
  }

  /**
   * The currently selected icon.
   */
  public var currentSelection:Int;

  var grpHitboxes:FlxTypedGroup<FlxObject>;

  public var nonLocks:Array<Int> = [];
  public var totalSlots:Int;

  var cursors:CharSelectCursors;
  var cursorFactor:Float = 110;
  var cursorOffsetX:Float = -16;
  var cursorOffsetY:Float = -48;
  var cursorLocIntended:FlxPoint = new FlxPoint(0, 0);
  var playerChill:CharSelectPlayer;
  var playerChillOut:CharSelectPlayer;
  var gfChill:CharSelectGF;
  var barthing:FunkinSprite;
  var dipshitBacking:FunkinSprite;
  var chooseDipshit:FunkinSprite;
  var dipshitBlur:FunkinSprite;
  var transitionGradient:FunkinSprite;
  var curChar(default, set):String = Constants.DEFAULT_CHARACTER;
  var rememberedChar:String;
  var nametag:Nametag;
  var camFollow:FlxObject = new FlxObject(0, 0, 1, 1);

  public var autoFollow:Bool = false;
  public var availableChars:Map<Int, String> = new Map<Int, String>();
  public var pressedSelect:Bool = false;

  var selectTimer:FlxTimer = new FlxTimer();
  var allowInput:Bool = false;
  var selectSound:FunkinSound = new FunkinSound();
  var unlockSound:FunkinSound = new FunkinSound();
  var lockedSound:FunkinSound = new FunkinSound();
  var introSound:FunkinSound = new FunkinSound();
  var staticSound:FunkinSound = new FunkinSound();
  var charHitbox:FlxObject = new FlxObject();
  var fadeShader:BlueFade = new BlueFade();

  public function new(?params:CharacterSelectStateParams)
  {
    super();

    rememberedChar = params?.character ?? '';

    cursors = new CharSelectCursors();
    grpHitboxes = new FlxTypedGroup<FlxObject>();

    gfChill = new CharSelectGF(CUTOUT_SIZE, 0);
    playerChillOut = new CharSelectPlayer(CUTOUT_SIZE, 0);
    playerChill = new CharSelectPlayer(CUTOUT_SIZE, 0);

    dipshitBlur = new FunkinSprite(CUTOUT_SIZE + 419, -65);
    dipshitBacking = new FunkinSprite(CUTOUT_SIZE + 423, -17);
    chooseDipshit = new FunkinSprite(CUTOUT_SIZE + 426, -13);

    nametag = new Nametag(rememberedChar);

    charHitbox = new FlxObject(FlxG.width * 0.65, FlxG.height * 0.2, 300, 500);

    transitionGradient = new FunkinSprite(0, 0);
    barthing = new FunkinSprite(0, 0);

    selectSound = new FunkinSound();
    unlockSound = new FunkinSound();
    lockedSound = new FunkinSound();
    staticSound = new FunkinSound();

    totalSlots = SLOTS_PER_PAGE;
    currentSelection = DEFAULT_CURSOR_INDEX;

    instance = this;
  }

  function loadAvailableCharacters():Void
  {
    var playerIds:Array<String> = PlayerRegistry.instance.listEntryIds();

    for (playerId in playerIds)
    {
      var player:Null<PlayableCharacter> = PlayerRegistry.instance.fetchEntry(playerId);
      if (player == null) continue;
      var playerData:Null<PlayerCharSelectData> = PlayerRegistry.instance.fetchEntry(playerId)?.getCharSelectData();
      if (playerData == null) continue;

      #if !UNLOCK_EVERYTHING
      // Without this, locked characters still take up space on the grid,
      // which sometimes pushes locked
      if (!player.isUnlocked()) continue;
      #end

      var targetPosition:Int = playerData.position ?? 0;
      while (availableChars.exists(targetPosition))
      {
        targetPosition += 1;
      }

      trace('Placing player ${playerId} at position ${targetPosition}');
      availableChars.set(targetPosition, playerId);

      totalSlots = Std.int(Math.max(targetPosition + 1, totalSlots));

      switch (playerData.getAssetType())
      {
        case 'animateatlas':
          CharSelectAtlasHandler.loadAtlas(playerData.getAnimateAtlasAssetPath(playerId));
        default:
          throw 'Unsupported asset type ${playerData.getAssetType()} for player ${playerId}';
      }

      var gfPath:Null<String> = playerData.gf?.assetPath;
      if (gfPath != null)
      {
        CharSelectAtlasHandler.loadAtlas(gfPath);
      }
    }

    // Mr. Static also needs some caching...
    CharSelectAtlasHandler.loadAtlas('ui/character-select/characters/locked', {
      filterQuality: LOW,
      cacheOnLoad: true
    });
  }

  override public function create():Void
  {
    super.create();

    loadAvailableCharacters();

    // Add additional slots to fill up the last page.
    if (totalSlots % SLOTS_PER_PAGE != 0)
    {
      totalSlots += (SLOTS_PER_PAGE - totalSlots % SLOTS_PER_PAGE);
    }

    var bg:FunkinSprite = new FunkinSprite(CUTOUT_SIZE + -153, -140);
    bg.loadGraphic(Paths.image('ui/character-select/interface/char-select-bg'));
    bg.scrollFactor.set(0.1, 0.1);
    add(bg);

    var crowd:FunkinSprite = new FunkinSprite(CUTOUT_SIZE, 0).loadTextureAtlas('ui/character-select/interface/crowd', {
      applyStageMatrix: true
    });
    crowd.anim.addBySymbol('wholeTimeline', crowd.getDefaultSymbol(), crowd.library.frameRate);
    crowd.animation.play('wholeTimeline');
    crowd.scrollFactor.set(0.3, 0.3);
    add(crowd);

    var stageSpr:FunkinSprite = new FunkinSprite(CUTOUT_SIZE - 2, 1).loadTextureAtlas('ui/character-select/interface/char-select-stage', {
      applyStageMatrix: true
    });
    stageSpr.anim.addBySymbol('wholeTimeline', stageSpr.getDefaultSymbol(), stageSpr.library.frameRate);
    stageSpr.animation.play('wholeTimeline');
    add(stageSpr);

    var curtains:FunkinSprite = new FunkinSprite(CUTOUT_SIZE + -212, -99);
    curtains.loadGraphic(Paths.image('ui/character-select/interface/curtains'));
    curtains.scrollFactor.set(1.4, 1.4);
    add(curtains);

    barthing.loadTextureAtlas('ui/character-select/interface/bar-thing', {
      applyStageMatrix: true
    });
    barthing.anim.addBySymbol('wholeTimeline', barthing.getDefaultSymbol(), barthing.library.frameRate);
    barthing.animation.play('wholeTimeline');
    barthing.blend = BlendMode.MULTIPLY;
    barthing.scale.x = 2.5;
    barthing.scrollFactor.set(0, 0);
    add(barthing);

    barthing.y += 80;
    FlxTween.tween(barthing, {
      y: barthing.y - 80
    }, 1.3, {
      ease: FlxEase.expoOut
    });

    var charLight:FunkinSprite = new FunkinSprite(CUTOUT_SIZE + 800, 250);
    charLight.loadGraphic(Paths.image('ui/character-select/interface/char-light'));
    add(charLight);

    var charLightGF:FunkinSprite = new FunkinSprite(CUTOUT_SIZE + 180, 240);
    charLightGF.loadGraphic(Paths.image('ui/character-select/interface/char-light'));
    add(charLightGF);

    function setupPlayerChill(character:String)
    {
      gfChill.switchGF(character);
      add(gfChill);

      playerChillOut.switchChar(character, false);
      playerChillOut.visible = false;
      add(playerChillOut);

      playerChill.switchChar(character, false);
      add(playerChill);
    }

    // I think I can do the character preselect thing here? This better work
    // Edit: [UH-OH!] yes! It does!
    if (rememberedChar != null && rememberedChar != Constants.DEFAULT_CHARACTER)
    {
      setupPlayerChill(rememberedChar);
      for (pos => charId in availableChars)
      {
        if (charId == rememberedChar)
        {
          setCursorPosition(pos, true);
          break;
        }
      }
      @:bypassAccessor curChar = rememberedChar;
    }
    else
    {
      setupPlayerChill(Constants.DEFAULT_CHARACTER);
      setCursorPosition(DEFAULT_CURSOR_INDEX, true);
    }

    var speakers:FunkinSprite = new FunkinSprite(CUTOUT_SIZE - 10, 0).loadTextureAtlas('ui/character-select/interface/speakers', {
      applyStageMatrix: true
    });
    speakers.anim.addBySymbol('wholeTimeline', speakers.getDefaultSymbol(), speakers.library.frameRate);
    speakers.animation.play('wholeTimeline');
    speakers.scrollFactor.set(1.8, 1.8);
    speakers.scale.set(1.05, 1.05);
    add(speakers);

    var fgBlur:FunkinSprite = new FunkinSprite(CUTOUT_SIZE + -125, 170);
    fgBlur.loadGraphic(Paths.image('ui/character-select/interface/foreground-blur'));
    fgBlur.blend = BlendMode.MULTIPLY;
    add(fgBlur);

    dipshitBlur.frames = Paths.getSparrowAtlas('ui/character-select/interface/dipshit-blur');
    dipshitBlur.animation.addByPrefix('idle', 'CHOOSE vertical offset instance 1', 24, true);
    dipshitBlur.blend = BlendMode.ADD;
    dipshitBlur.animation.play('idle');
    add(dipshitBlur);

    dipshitBacking.frames = Paths.getSparrowAtlas('ui/character-select/interface/dipshit-backing');
    dipshitBacking.animation.addByPrefix('idle', 'CHOOSE horizontal offset instance 1', 24, true);
    dipshitBacking.blend = BlendMode.ADD;
    dipshitBacking.animation.play('idle');
    add(dipshitBacking);

    dipshitBacking.y += 210;
    FlxTween.tween(dipshitBacking, {
      y: dipshitBacking.y - 210
    }, 1.1, {
      ease: FlxEase.expoOut
    });

    chooseDipshit.loadGraphic(Paths.image('ui/character-select/interface/choose-your-dipshit'));
    add(chooseDipshit);

    chooseDipshit.y += 200;
    FlxTween.tween(chooseDipshit, {
      y: chooseDipshit.y - 200
    }, 1, {
      ease: FlxEase.expoOut
    });

    dipshitBlur.y += 220;
    FlxTween.tween(dipshitBlur, {
      y: dipshitBlur.y - 220
    }, 1.2, {
      ease: FlxEase.expoOut
    });

    chooseDipshit.scrollFactor.set();
    dipshitBacking.scrollFactor.set();
    dipshitBlur.scrollFactor.set();

    nametag.midpoint.x += CUTOUT_SIZE;
    add(nametag);

    final initialMidpointY:Float = nametag.midpoint.y;
    nametag.midpoint.y += 200;
    FlxTween.tween(nametag.midpoint, {
      y: initialMidpointY
    }, 1, {
      ease: FlxEase.expoOut
    });

    nametag.scrollFactor.set();

    add(cursors);
    add(iconGroup);

    FlxG.debugger.addTrackerProfile(new TrackerProfile(FunkinSprite, [
      'x',
      'y',
      'alpha',
      'scale',
      'blend'
    ]));
    FlxG.debugger.addTrackerProfile(new TrackerProfile(FlxSound, ['pitch', 'volume']));

    charHitbox.active = false;
    charHitbox.scrollFactor.set();

    selectSound.loadEmbedded(Paths.sound('ui/character-select/sounds/select'));
    selectSound.volume = 0.7;

    FlxG.sound.defaultSoundGroup.add(selectSound);
    FlxG.sound.list.add(selectSound);

    unlockSound.loadEmbedded(Paths.sound('ui/character-select/sounds/unlock'));
    unlockSound.volume = 0;
    unlockSound.play(true);

    FlxG.sound.defaultSoundGroup.add(unlockSound);
    FlxG.sound.list.add(unlockSound);

    lockedSound.loadEmbedded(Paths.sound('ui/character-select/sounds/locked'));
    lockedSound.volume = 1.;

    FlxG.sound.defaultSoundGroup.add(lockedSound);
    FlxG.sound.list.add(lockedSound);

    staticSound.loadEmbedded(Paths.sound('ui/character-select/sounds/static'));
    staticSound.looped = true;
    staticSound.volume = 0.6;

    FlxG.sound.defaultSoundGroup.add(staticSound);
    FlxG.sound.list.add(staticSound);

    // playing it here to preload it. not doing this makes a super awkward pause at the end of the intro
    // TODO: probably make an intro thing for funkinSound itself that preloads the next audio?
    FunkinSound.playMusic('ui/character-select/stay-funky/stay-funky', {
      startingVolume: 0,
      overrideExisting: true,
      restartTrack: true,
    });

    iconGroup.loadCharacters();

    iconGroup.doIntroTween();

    add(camFollow);
    camFollow.screenCenter();

    FlxG.camera.follow(camFollow, LOCKON);

    var fadeShaderFilter:ShaderFilter = new ShaderFilter(fadeShader);
    FlxG.camera.filters = [fadeShaderFilter];

    Conductor.stepHit.add(spamOnStep);

    #if FEATURE_TOUCH_CONTROLS
    addBackButton(FlxG.width, FlxG.height - 200, FlxColor.WHITE, goBack, 0.3, true);

    if (backButton != null)
    {
      backButton.enabled = false;
      backButton.cameras = [FlxG.camera];
    }

    FlxTween.tween(backButton, {
      x: FlxG.width - 230
    }, 0.5, {
      ease: FlxEase.expoOut,
      onComplete: (_) ->
      {
        if (backButton != null) backButton.enabled = true;
      }
    });
    #end

    transitionGradient.loadGraphic(Paths.image('ui/freeplay/interface/transition-gradient'));
    transitionGradient.scale.set(1280, 1);
    transitionGradient.flipY = true;
    transitionGradient.updateHitbox();
    FlxTween.tween(transitionGradient, {
      y: -720
    }, 1, {
      ease: FlxEase.expoOut
    });
    add(transitionGradient);

    camFollow.screenCenter();
    camFollow.y -= 150;
    FlxG.camera.filtersEnabled = true;
    fadeShader.fade(0.0, 1.0, 0.8, {
      ease: FlxEase.quadOut,
      onComplete: (twn) ->
      {
        FlxG.camera.filtersEnabled = false;
      }
    });
    FlxTween.tween(camFollow, {
      y: camFollow.y + 150
    }, 1.5, {
      ease: FlxEase.expoOut,
      onComplete: function(_)
      {
        autoFollow = true;
        FlxG.camera.follow(camFollow, LOCKON, 0.01);
      }
    });

    var blackScreen = new FunkinSprite().makeSolidColor(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
    blackScreen.x = -(FlxG.width * 0.5);
    blackScreen.y = -(FlxG.height * 0.5);
    add(blackScreen);

    introSound = new FunkinSound();
    introSound.loadEmbedded(Paths.sound('ui/character-select/sounds/lights'));
    introSound.volume = 0;

    FlxG.sound.defaultSoundGroup.add(introSound);
    FlxG.sound.list.add(introSound);

    openSubState(new IntroSubState());

    subStateClosed.addOnce((_) ->
    {
      remove(blackScreen);
      if (!Save.instance.oldChar.value)
      {
        camera.flash();

        introSound.volume = 1;
        introSound.play(true);
      }
      checkNewChar();

      Save.instance.oldChar.value = true;
    });
  }

  override public function destroy():Void
  {
    CharSelectAtlasHandler.clearAtlasCache();
    instance = null;

    super.destroy();
  }

  function checkNewChar():Void
  {
    if (nonLocks.length > 0) selectTimer.start(2, (_) ->
    {
      unLock();
    });
    else
    {
      #if FEATURE_NEWGROUNDS
      // Make the character unlock medal retroactive.
      if (availableChars.size() > 1) Medals.award(CharSelect);
      #end

      FunkinSound.playMusic('ui/character-select/stay-funky/stay-funky', {
        startingVolume: 1,
        overrideExisting: true,
        restartTrack: true,
        onLoad: function()
        {
          allowInput = true;

          @:privateAccess
          gfChill.analyzer = new SpectralAnalyzer(FlxG.sound.music._channel.__audioSource, 7, 0.1);
          #if sys
          // On native it uses FFT stuff that isn't as optimized as the direct browser stuff we use on HTML5
          // So we want to manually change it!
          @:privateAccess
          gfChill.analyzer.fftN = 512;
          #end
        }
      });
    }
  }

  function unLock():Void
  {
    pressedSelect = true;

    currentSelection = nonLocks[0];

    selectSound.play(true);

    nonLocks.shift();

    selectTimer.start(0.5, (_) ->
    {
      var lock:Lock = cast iconGroup.children[currentSelection];

      lock.animation.play('unlock');
      lock.animation.onFrameChange.add((animName:String, frame:Int, index:Int) ->
      {
        if (frame == 40)
        {
          playerChillOut.animation.play('death');
        }
      });

      unlockSound.volume = 0.7;
      unlockSound.play(true);

      lock.animation.onFinish.addOnce((_) ->
      {
        var char:String = availableChars.get(currentSelection) ?? Constants.DEFAULT_CHARACTER;
        camera.flash(0xFFFFFFFF, 0.1);
        playerChill.animation.play('unlock');
        playerChill.visible = true;

        var id = iconGroup.children.indexOf(lock);

        nametag.switchChar(char);
        gfChill.switchGF(char);
        gfChill.visible = true;

        var icon = new PixelatedIcon(0, 0);
        icon.setCharacter(char);
        icon.setGraphicSize(128, 128);
        icon.updateHitbox();
        iconGroup.insert(icon, id);
        iconGroup.remove(lock);
        icon.ID = 0;

        iconGroup.updateIconPositions();
        playerChillOut.animation.onFinish.addOnce((_) -> if (_ == 'death')
        {
          playerChillOut.visible = false;
          playerChillOut.switchChar(char);
        });

        #if FEATURE_NEWGROUNDS
        // Grant the medal when the player unlocks a character.
        Medals.award(CharSelect);
        #end

        Save.instance.addCharacterSeen(char);
        if (nonLocks.length == 0)
        {
          pressedSelect = false;
          @:bypassAccessor curChar = char;

          staticSound.stop();

          FunkinSound.playMusic('ui/character-select/stay-funky/stay-funky', {
            startingVolume: 1,
            overrideExisting: true,
            restartTrack: true,
            onLoad: function()
            {
              allowInput = true;

              @:privateAccess
              gfChill.analyzer = new SpectralAnalyzer(FlxG.sound.music._channel.__audioSource, 7, 0.1);
              #if sys
              // On native it uses FFT stuff that isn't as optimized as the direct browser stuff we use on HTML5
              // So we want to manually change it!
              @:privateAccess
              gfChill.analyzer.fftN = 512;
              #end
            }
          });
        }
        else
          playerChill.animation.onFinish.addOnce((_) -> unLock());
      });

      playerChill.visible = false;
      playerChill.switchChar(availableChars[currentSelection] ?? Constants.DEFAULT_CHARACTER);

      playerChillOut.visible = true;
    });
  }

  function goToFreeplay():Void
  {
    allowInput = false;
    autoFollow = false;

    #if FEATURE_TOUCH_CONTROLS
    if (backButton != null)
    {
      FlxTween.tween(backButton, {
        alpha: 0
      }, 0.2);
    }
    #end

    FlxTween.tween(cursors, {
      alpha: 0
    }, 0.8, {
      ease: FlxEase.expoOut
    });

    FlxTween.tween(barthing, {
      y: barthing.y + 80
    }, 0.8, {
      ease: FlxEase.backIn
    });
    FlxTween.tween(nametag.midpoint, {
      y: nametag.midpoint.y + 80
    }, 0.8, {
      ease: FlxEase.backIn
    });
    FlxTween.tween(dipshitBacking, {
      y: dipshitBacking.y + 210
    }, 0.8, {
      ease: FlxEase.backIn
    });
    FlxTween.tween(chooseDipshit, {
      y: chooseDipshit.y + 200
    }, 0.8, {
      ease: FlxEase.backIn
    });
    FlxTween.tween(dipshitBlur, {
      y: dipshitBlur.y + 220
    }, 0.8, {
      ease: FlxEase.backIn
    });

    iconGroup.doExitTween();

    FlxG.camera.follow(camFollow, LOCKON);
    // going to freeplay so fast makes the fade effects and the camera to bug, that's why we cancel the tweens
    FlxTween.cancelTweensOf(transitionGradient);
    FlxTween.cancelTweensOf(fadeShader);
    FlxTween.cancelTweensOf(camFollow);

    FlxTween.tween(transitionGradient, {
      y: -150
    }, 0.8, {
      ease: FlxEase.backIn
    });
    FlxG.camera.filtersEnabled = true;
    fadeShader.fade(1.0, 0, 0.8, {
      ease: FlxEase.quadIn
    });
    FlxTween.tween(camFollow, {
      y: camFollow.y - 150
    }, 0.8, {
      ease: FlxEase.backIn,
      onComplete: (_) ->
      {
        FlxG.switchState(() -> FreeplayState.build({
          {
            character: wentBackToFreeplay ? rememberedChar : curChar,
            fromCharSelect: true
          }
        }));
      }
    });
  }

  var holdTmrUp:Float = 0;
  var holdTmrDown:Float = 0;
  var holdTmrLeft:Float = 0;
  var holdTmrRight:Float = 0;
  var spamDirections:FlxDirectionFlags = NONE;
  var initSpam:Float = 0.5;
  var mobileDeny:Bool = false;
  var mobileAccept:Bool = false;
  var wentBackToFreeplay:Bool = false;

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    Conductor.instance.update();

    mobileAccept = false;

    if (allowInput && !pressedSelect)
    {
      #if FEATURE_TOUCH_CONTROLS
      if (TouchUtil.pressed || TouchUtil.justReleased)
      {
        for (i => hitbox in grpHitboxes.members)
        {
          if (hitbox == null || !TouchUtil.overlaps(hitbox)) continue;

          final currentPage:Int = Math.floor(currentSelection / SLOTS_PER_PAGE);
          if (i + currentPage * SLOTS_PER_PAGE != currentSelection)
          {
            currentSelection = i + currentPage * SLOTS_PER_PAGE;
            cursors.resetDeny();
            selectSound.play(true);
          }
          else if (TouchUtil.justPressed)
          {
            mobileAccept = true;
          }

          trace('Index: ' + i);
          break;
        }
      }

      if (TouchUtil.pressAction(charHitbox, null, false))
      {
        mobileAccept = true;
      }

      // On mobile, use swiping to scroll the page.
      var scrollAmount:Int = 0;

      if (SwipeUtil.justSwipedUp) scrollAmount = -1;
      if (SwipeUtil.justSwipedDown) scrollAmount = 1;
      if (scrollAmount != 0)
      {
        currentSelection += Std.int(scrollAmount * SLOTS_PER_PAGE);
        cursorDenied.visible = false;
        selectSound.play(true);
      }
      #end

      if (controls.UI_UP_P)
      {
        var column:Int = currentSelection % SLOTS_PER_ROW;
        currentSelection = FlxMath.wrap(currentSelection - SLOTS_PER_ROW, column, totalSlots + column - 1);

        cursors.resetDeny();
        holdTmrUp = 0;
        selectSound.play(true);
      }
      if (controls.UI_DOWN_P)
      {
        var column:Int = currentSelection % SLOTS_PER_ROW;
        currentSelection = FlxMath.wrap(currentSelection + SLOTS_PER_ROW, column, totalSlots + column - 1);

        cursors.resetDeny();
        holdTmrDown = 0;
        selectSound.play(true);
      }
      if (controls.UI_LEFT_P)
      {
        var row:Int = Math.floor(currentSelection / SLOTS_PER_ROW);
        currentSelection = FlxMath.wrap(currentSelection - 1, row * SLOTS_PER_ROW, (row + 1) * SLOTS_PER_ROW - 1);

        cursors.resetDeny();
        holdTmrLeft = 0;
        selectSound.play(true);
      }
      if (controls.UI_RIGHT_P)
      {
        var row:Int = Math.floor(currentSelection / SLOTS_PER_ROW);
        currentSelection = FlxMath.wrap(currentSelection + 1, row * SLOTS_PER_ROW, (row + 1) * SLOTS_PER_ROW - 1);

        cursors.resetDeny();
        holdTmrRight = 0;
        selectSound.play(true);
      }

      if (controls.UI_UP) holdTmrUp += elapsed;
      if (controls.UI_UP_R || !controls.UI_UP)
      {
        holdTmrUp = 0;
        spamDirections = spamDirections.without(UP);
      }

      if (controls.UI_DOWN) holdTmrDown += elapsed;
      if (controls.UI_DOWN_R || !controls.UI_DOWN)
      {
        holdTmrDown = 0;
        spamDirections = spamDirections.without(DOWN);
      }

      if (controls.UI_LEFT) holdTmrLeft += elapsed;
      if (controls.UI_LEFT_R || !controls.UI_LEFT)
      {
        holdTmrLeft = 0;
        spamDirections = spamDirections.without(LEFT);
      }

      if (controls.UI_RIGHT) holdTmrRight += elapsed;
      if (controls.UI_RIGHT_R || !controls.UI_RIGHT)
      {
        holdTmrRight = 0;
        spamDirections = spamDirections.without(RIGHT);
      }

      if (holdTmrUp >= initSpam) spamDirections = spamDirections.with(UP);
      if (holdTmrDown >= initSpam) spamDirections = spamDirections.with(DOWN);
      if (holdTmrLeft >= initSpam) spamDirections = spamDirections.with(LEFT);
      if (holdTmrRight >= initSpam) spamDirections = spamDirections.with(RIGHT);

      if (controls.BACK_P) goBack();
    }

    var currentCharacter:String = availableChars[currentSelection] ?? Constants.DEFAULT_CHARACTER;
    if (availableChars.exists(currentSelection) && PlayerRegistry.instance.isCharacterSeen(currentCharacter))
    {
      var charId:String = availableChars.get(currentSelection) ?? Constants.DEFAULT_CHARACTER;
      if (charId != null) curChar = charId;

      if (allowInput && pressedSelect && (controls.BACK_P #if FEATURE_TOUCH_CONTROLS || (mobileDeny && TouchUtil.justReleased) #end))
      {
        mobileDeny = false;
        cursors.unconfirm();

        var event:CharacterSelectScriptEvent = CharacterSelectScriptEvent.get(CHARACTER_DESELECTED, curChar);
        dispatchEvent(event);

        #if FEATURE_TOUCH_CONTROLS
        if (backButton != null)
        {
          backButton.enabled = true;
        }
        #end

        FlxTween.globalManager.cancelTweensOf(FlxG.sound.music);
        FlxTween.tween(FlxG.sound.music, {
          pitch: 1.0,
          volume: 1.0
        }, 1, {
          ease: FlxEase.quartInOut
        });
        playerChill.animation.play('deselect');
        gfChill.animation.play('deselect');
        pressedSelect = false;
        FlxTween.tween(FlxG.sound.music, {
          pitch: 1.0
        }, 1, {
          ease: FlxEase.quartInOut,
          onComplete: (_) ->
          {
            if (playerChill.getCurrentAnimation() == 'deselect-loop' || playerChill.getCurrentAnimation() == 'deselect')
            {
              playerChill.animation.play('idle', true);
              gfChill.animation.play('idle', true);
            }
          }
        });
        selectTimer.cancel();
      }

      if (allowInput && !pressedSelect && (controls.ACCEPT_P || mobileAccept))
      {
        mobileDeny = false;
        spamDirections = NONE;

        cursors.confirm();

        FunkinSound.playOnce(Paths.sound('ui/character-select/sounds/confirm'));

        var event:CharacterSelectScriptEvent = CharacterSelectScriptEvent.get(CHARACTER_CONFIRMED, curChar);
        dispatchEvent(event);

        #if FEATURE_TOUCH_CONTROLS
        if (backButton != null)
        {
          backButton.enabled = false;
        }
        #end

        FlxTween.tween(FlxG.sound.music, {
          pitch: 0.1
        }, 1, {
          ease: FlxEase.quadInOut
        });
        FlxTween.tween(FlxG.sound.music, {
          volume: 0.0
        }, 1.5, {
          ease: FlxEase.quadInOut
        });

        playerChill.animation.play('select');
        gfChill.animation.play('confirm', true);
        gfChill.animation.curAnim.looped = true;

        pressedSelect = true;
        selectTimer.start(1.5, (_) ->
        {
          goToFreeplay();
        });
      }
      #if FEATURE_TOUCH_CONTROLS
      else if (pressedSelect && TouchUtil.justReleased) mobileDeny = true;
      #end

      mobileAccept = false;
    }
    else
    {
      curChar = 'locked';

      gfChill.visible = false;

      if (allowInput && (controls.ACCEPT_P || mobileAccept))
      {
        playerChill.animation.play('cannotSelect', true);
        lockedSound.play(true);
        HapticUtil.vibrate(0, 0.2);

        cursors.deny();
      }
    }

    var pageRow:Int = ((currentSelection % SLOTS_PER_PAGE) % SLOTS_PER_ROW) - 1;
    var pageColumn:Int = Math.floor((currentSelection % SLOTS_PER_PAGE) / SLOTS_PER_ROW) - 1;

    if (autoFollow)
    {
      camFollow.screenCenter();
      camFollow.x += pageRow * 10;
      camFollow.y += pageColumn * 10;
    }

    cursorLocIntended.x = (cursorFactor * pageRow) + (FlxG.width / 2) - cursors.main.width / 2;
    cursorLocIntended.y = (cursorFactor * pageColumn) + (FlxG.height / 2) - cursors.main.height / 2;

    cursorLocIntended.x += cursorOffsetX;
    cursorLocIntended.y += cursorOffsetY;

    cursors.lerpToLocation(cursorLocIntended);
  }

  function goBack():Void
  {
    #if FEATURE_TOUCH_CONTROLS
    if (backButton != null)
    {
      backButton.enabled = false;
      backButton.alpha = 1;
      backButton.animation.play('confirm');
    }
    #end

    wentBackToFreeplay = true;
    FunkinSound.playOnce(Paths.sound('ui/main-menu/cancel-menu'));
    FlxTween.tween(FlxG.sound.music, {
      volume: 0.0
    }, 0.7, {
      ease: FlxEase.quadInOut
    });
    goToFreeplay();
  }

  override public function dispatchEvent(event:ScriptEvent, finish:Bool = true):Void
  {
    // super.dispatchEvent(event) dispatches event to module scripts.
    super.dispatchEvent(event, false);

    // Dispatch events (like onBeatHit) to props
    ScriptEventDispatcher.callEvent(playerChill, event);
    ScriptEventDispatcher.callEvent(gfChill, event);
    if (finish) event.finish();
  }

  function spamOnStep():Void
  {
    if (spamDirections.hasAny(ANY))
    {
      if (selectSound.pitch > 5) selectSound.pitch = 5;
      selectSound.play(true);

      cursors.resetDeny();

      if (spamDirections.has(UP) || spamDirections.has(DOWN))
      {
        var column:Int = currentSelection % SLOTS_PER_ROW;
        currentSelection = FlxMath.wrap(currentSelection + SLOTS_PER_ROW * (spamDirections.has(UP) ? -1 : 1), column, totalSlots + column - 1);

        if (spamDirections.has(UP)) holdTmrUp = 0;
        else if (spamDirections.has(DOWN)) holdTmrDown = 0;
      }
      if (spamDirections.has(LEFT) || spamDirections.has(RIGHT))
      {
        var row:Int = Math.floor(currentSelection / SLOTS_PER_ROW);
        currentSelection = FlxMath.wrap(currentSelection + (spamDirections.has(LEFT) ? -1 : 1), row * SLOTS_PER_ROW, (row + 1) * SLOTS_PER_ROW - 1);

        if (spamDirections.has(LEFT)) holdTmrLeft = 0;
        else if (spamDirections.has(RIGHT)) holdTmrRight = 0;
      }
    }
  }

  function setCursorPosition(index:Int, instant:Bool = false):Void
  {
    currentSelection = index;

    if (instant)
    {
      var pageRow:Int = ((currentSelection % SLOTS_PER_PAGE) % SLOTS_PER_ROW) - 1;
      var pageColumn:Int = Math.floor((currentSelection % SLOTS_PER_PAGE) / SLOTS_PER_ROW) - 1;

      cursorLocIntended.x = (cursorFactor * pageRow) + (FlxG.width / 2) - cursors.main.width / 2;
      cursorLocIntended.y = (cursorFactor * pageColumn) + (FlxG.height / 2) - cursors.main.height / 2;

      cursorLocIntended.x += cursorOffsetX;
      cursorLocIntended.y += cursorOffsetY;

      cursors.snapToLocation(cursorLocIntended);
    }
  }

  function set_curChar(value:String):String
  {
    if (curChar == value) return value;

    curChar = value;

    if (value == 'locked') staticSound.play();
    else
      staticSound.stop();

    nametag.switchChar(value);

    gfChill.visible = false;
    playerChill.visible = false;
    playerChillOut.visible = true;
    playerChillOut.animation.play('slideout');

    playerChillOut.animation.onFrameChange.removeAll();
    playerChillOut.animation.onFrameChange.add(function(animName:String, frameNumber:Int, index:Int)
    {
      if (!playerChill.visible)
      {
        playerChill.visible = true;
        playerChill.switchChar(value);
        gfChill.switchGF(value);
        gfChill.visible = true;
      }
    });

    playerChillOut.animation.onFinish.addOnce(function(animName:String)
    {
      playerChillOut.switchChar(value);
      playerChillOut.visible = false;
      playerChillOut.animation.onFrameChange.removeAll();
    });

    return value;
  }
}
