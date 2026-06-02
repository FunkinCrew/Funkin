package funkin.ui.charSelect;

import flixel.FlxObject;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.data.freeplay.player.PlayerData.PlayerCharSelectData;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.BlueFade;
import funkin.modding.events.ScriptEvent;
import funkin.save.Save;
import funkin.ui.UIStateMachine;
import funkin.ui.charSelect.characters.CharSelectCharacter;
import funkin.ui.charSelect.characters.CharSelectCharacterGroup;
import funkin.ui.charSelect.characters.Nametag;
import funkin.ui.charSelect.icons.IconGroup;
import funkin.ui.freeplay.FreeplayState;
import funkin.ui.freeplay.charselect.PlayableCharacter;
import funkin.util.HapticUtil;
import openfl.display.BlendMode;
import openfl.filters.ShaderFilter;
#if FEATURE_NEWGROUNDS
import funkin.api.newgrounds.Medals;
#end
#if FEATURE_TOUCH_CONTROLS
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import funkin.util.SwipeUtil;
import funkin.util.TouchUtil;
#end

/**
 * Parameters used to initialize the CharacterSelectState.
 */
typedef CharacterSelectStateParams =
{
  ?character:String
}

/**
 * The state of the Character Select screen. Allows the player to select a playable character.
 */
@:nullSafety
class CharacterSelectState extends MusicBeatSubState
{
  /**
   * A singleton instance of the Character Select screen.
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
   * The UI state machine for the Character Select screen.
   */
  public var uiStateMachine(default, null):UIStateMachine = new UIStateMachine();

  /**
   * A `FunkinGroup` that holds all of the icons.
   */
  public var icons:IconGroup = new IconGroup();

  /**
   * Alias for `this.icons`.
   * Only here for backwards compatibility with mods.
   */
  @:deprecated('Use `this.icons` instead.')
  public var grpIcons(get, never):IconGroup;

  function get_grpIcons():IconGroup
  {
    return icons;
  }

  /**
   * The currently selected icon.
   */
  public var currentSelection(default, set):Int;

  function set_currentSelection(value:Int):Int
  {
    if (value == currentSelection) return value;

    var oldSelection:Int = currentSelection;

    currentSelection = value;

    cursors.resetDeny();
    selectSound.play(true);

    var currentCharacter:String = availableChars.get(currentSelection) ?? Constants.DEFAULT_CHARACTER;
    if (availableChars.exists(currentSelection) && PlayerRegistry.instance.isCharacterSeen(currentCharacter))
    {
      if (currentCharacter != null)
      {
        currentCharacterId = currentCharacter;
      }
    }
    else
    {
      currentCharacterId = 'locked';
    }

    icons.selectIcon(currentSelection);

    if (oldSelection != currentSelection)
    {
      icons.deselectIcon(oldSelection);
    }

    return value;
  }

  /**
   * A `FunkinGroup` that holds of all of the character sprites.
   */
  public var characters:CharSelectCharacterGroup = new CharSelectCharacterGroup();

  /**
   * Alias for `characters.player`.
   * Only here for backwards compatibility with mods.
   */
  @:deprecated('Use `characters.player` instead.')
  public var playerChill(get, never):CharSelectCharacter;

  function get_playerChill():CharSelectCharacter
  {
    return characters.player;
  }

  /**
   * Alias for `characters.player`.
   * Only here for backwards compatibility with mods.
   */
  @:deprecated('Use `characters.player` instead.')
  public var playerChillOut(get, never):CharSelectCharacter;

  function get_playerChillOut():CharSelectCharacter
  {
    return characters.player;
  }

  /**
   * Alias for `characters.gf`.
   * Only here for backwards compatibility with mods.
   */
  @:deprecated('Use `characters.gf` instead.')
  public var gfChill(get, never):CharSelectCharacter;

  function get_gfChill():CharSelectCharacter
  {
    return characters.gf;
  }

  /**
   * The nametag that appears at the top right, changes between characters.
   */
  public var nametag:Nametag;

  /**
   * The current character ID.
   * Not to be confused with `currentSelection`, which is the currently selected ICON.
   */
  public var currentCharacterId(default, set):String = Constants.DEFAULT_CHARACTER;

  function set_currentCharacterId(value:String):String
  {
    if (currentCharacterId == value) return value;

    var oldId:String = currentCharacterId;

    currentCharacterId = value;

    nametag.loadCharacter(value);

    characters.setCharacters(oldId, value);
    characters.dispatchEvent(new ScriptEvent(CREATE));

    return value;
  }

  /**
   * The last character that was selected.
   */
  public var rememberedCharacterId:String;

  /**
   * Alias for `currentCharacterId`.
   * Only here for backwards compatibility with mods.
   */
  @:deprecated('Use `currentCharacterId` instead.')
  public var curChar(get, never):String;

  function get_curChar():String
  {
    return currentCharacterId;
  }

  /**
   * Toggling this on will make the camera follow whatever slot is selected.
   * For example, going to the leftmost slot will make the camera pan slightly to the left.
   */
  public var autoFollow:Bool = false;

  /**
   * A timer that runs when a character is selected.
   */
  var selectTimer:FlxTimer = new FlxTimer();

  /**
   * A list of locks that need to be unlocked for the unlock animation.
   */
  var locksToUnlock:Array<Int> = [];

  /**
   * The total number of slots in the Character Select screen.
   */
  var totalSlots:Int;

  /**
   * A list of available characters.
   * The key is the slot number, and the value is the character ID.
   */
  var availableChars:Map<Int, String> = new Map<Int, String>();

  /**
   * A `FunkinGroup` that controls the cursor in the Character Select screen.
   */
  var cursors:CharSelectCursors;

  /**
   * The bar at the top of the screen.
   */
  var topBar:FunkinSprite;

  /**
   * The "CHOOSE YOUR DIPSHIT" text.
   */
  var chooseDipshit:FunkinSprite;

  /**
   * A gradient sprite that appears when you enter Character Select.
   */
  var transitionGradient:FunkinSprite;

  /**
   * An empty `FlxObject` that the camera follows.
   */
  var cameraFollowPoint:FlxObject;

  /**
   * The select sound, plays when you go to a character.
   */
  var selectSound:FunkinSound;

  /**
   * The unlock sound, plays during the unlock animation.
   */
  var unlockSound:FunkinSound;

  /**
   * The locked sound, plays when you try to select a locked character.
   */
  var lockedSound:FunkinSound;

  /**
   * The intro sound, plays when you enter Character Select for the first time after unlocking a character.
   */
  var introSound:FunkinSound;

  /**
   * A shader that fades the screen to a blue tint, used when entering and exiting Character Select.
   */
  var fadeShader:BlueFade;

  /**
   * A separate class that handles directional inputs.
   */
  var inputHandler:CharSelectInputHandler = new CharSelectInputHandler();

  #if FEATURE_TOUCH_CONTROLS
  /**
   * The hitbox for the character that the user is selecting.
   */
  var characterHitbox:FlxObject;
  #end

  /**
   * Whether or not the player went back to Freeplay instead of selecting a character.
   */
  var wentBackToFreeplay:Bool = false;

  public function new(?params:CharacterSelectStateParams)
  {
    super();

    rememberedCharacterId = params?.character ?? '';

    @:bypassAccessor
    currentCharacterId = rememberedCharacterId;

    cursors = new CharSelectCursors();

    chooseDipshit = new FunkinSprite(CUTOUT_SIZE, 0);
    transitionGradient = new FunkinSprite(0, 0);
    topBar = new FunkinSprite(0, 0);

    nametag = new Nametag(rememberedCharacterId);

    selectSound = new FunkinSound();
    unlockSound = new FunkinSound();
    lockedSound = new FunkinSound();
    introSound = new FunkinSound();

    fadeShader = new BlueFade();

    #if FEATURE_TOUCH_CONTROLS
    characterHitbox = new FlxObject(FlxG.width * 0.65, FlxG.height * 0.2, 300, 500);
    #end
    cameraFollowPoint = new FlxObject(0, 0, 1, 1);

    totalSlots = SLOTS_PER_PAGE;

    @:bypassAccessor
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
      var playerData:Null<PlayerCharSelectData> = player.getCharSelectData();
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
    }

    // Add additional slots to fill up the last page.
    if (totalSlots % SLOTS_PER_PAGE != 0)
    {
      totalSlots += (SLOTS_PER_PAGE - totalSlots % SLOTS_PER_PAGE);
    }

    characters.createCharacters(currentCharacterId, availableChars);
    icons.loadCharacters(totalSlots, availableChars, locksToUnlock);

    if (rememberedCharacterId != Constants.DEFAULT_CHARACTER)
    {
      for (position => characterId in availableChars)
      {
        if (characterId == rememberedCharacterId)
        {
          @:bypassAccessor
          currentSelection = position;
          break;
        }
      }
    }

    icons.selectIcon(currentSelection);
    cursors.snapToIndex(currentSelection);
  }

  override public function create():Void
  {
    super.create();

    uiStateMachine.transition(Disabled);

    loadAvailableCharacters();

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

    var stage:FunkinSprite = new FunkinSprite(CUTOUT_SIZE - 2, 1).loadTextureAtlas('ui/character-select/interface/char-select-stage', {
      applyStageMatrix: true
    });
    stage.anim.addBySymbol('wholeTimeline', stage.getDefaultSymbol(), stage.library.frameRate);
    stage.animation.play('wholeTimeline');
    add(stage);

    var curtains:FunkinSprite = new FunkinSprite(CUTOUT_SIZE + -212, -99);
    curtains.loadGraphic(Paths.image('ui/character-select/interface/curtains'));
    curtains.scrollFactor.set(1.4, 1.4);
    add(curtains);

    topBar.loadTextureAtlas('ui/character-select/interface/bar-thing', {
      applyStageMatrix: true
    });
    topBar.anim.addBySymbol('wholeTimeline', topBar.getDefaultSymbol(), topBar.library.frameRate);
    topBar.animation.play('wholeTimeline');
    topBar.blend = BlendMode.MULTIPLY;
    topBar.scale.x = 2.5;
    topBar.scrollFactor.set(0, 0);
    add(topBar);

    topBar.y += 80;
    FlxTween.tween(topBar, {
      y: topBar.y - 80
    }, 1.3, {
      ease: FlxEase.expoOut
    });

    var charLight:FunkinSprite = new FunkinSprite(CUTOUT_SIZE + 800, 250);
    charLight.loadGraphic(Paths.image('ui/character-select/interface/char-light'));
    add(charLight);

    var charLightGF:FunkinSprite = new FunkinSprite(CUTOUT_SIZE + 180, 240);
    charLightGF.loadGraphic(Paths.image('ui/character-select/interface/char-light'));
    add(charLightGF);

    // Adding the character group here for layering.
    add(characters);

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

    chooseDipshit.loadTextureAtlas('ui/character-select/interface/dipshit-text', {
      applyStageMatrix: true
    });
    chooseDipshit.anim.addBySymbol('wholeTimeline', chooseDipshit.getDefaultSymbol(), chooseDipshit.library.frameRate);
    chooseDipshit.animation.play('wholeTimeline');
    chooseDipshit.scrollFactor.set();
    add(chooseDipshit);

    chooseDipshit.y += 200;
    FlxTween.tween(chooseDipshit, {
      y: chooseDipshit.y - 200
    }, 1, {
      ease: FlxEase.expoOut
    });

    nametag.targetPosition.x += CUTOUT_SIZE;
    nametag.targetPosition.y += 200;
    add(nametag);
    FlxTween.tween(nametag.targetPosition, {
      y: nametag.targetPosition.y - 200
    }, 1, {
      ease: FlxEase.expoOut
    });

    add(cursors);
    add(icons);

    #if FEATURE_TOUCH_CONTROLS
    characterHitbox.active = false;
    characterHitbox.scrollFactor.set();
    add(characterHitbox);
    #end

    selectSound.loadEmbedded(Paths.sound('ui/character-select/sounds/select'));
    selectSound.volume = 0.7;
    FlxG.sound.list.add(selectSound);

    unlockSound.loadEmbedded(Paths.sound('ui/character-select/sounds/unlock'));
    unlockSound.volume = 0.7;
    FlxG.sound.list.add(unlockSound);

    lockedSound.loadEmbedded(Paths.sound('ui/character-select/sounds/locked'));
    lockedSound.volume = 0.7;
    FlxG.sound.list.add(lockedSound);

    // Pre-caching the menu music for later.
    FlxG.sound.cache(Paths.sound('ui/character-select/stay-funky/stay-funky'));

    icons.doIntroTween();

    cameraFollowPoint.screenCenter();
    add(cameraFollowPoint);

    FlxG.camera.follow(cameraFollowPoint, LOCKON);

    var fadeShaderFilter:ShaderFilter = new ShaderFilter(fadeShader);
    FlxG.camera.filters = [fadeShaderFilter];

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
    transitionGradient.scale.set(FlxG.width, 1);
    transitionGradient.flipY = true;
    transitionGradient.updateHitbox();
    add(transitionGradient);
    FlxTween.tween(transitionGradient, {
      y: -FlxG.height
    }, 1, {
      ease: FlxEase.expoOut
    });

    cameraFollowPoint.screenCenter();
    cameraFollowPoint.y -= 150;
    FlxG.camera.filtersEnabled = true;
    fadeShader.fade(0.0, 1.0, 0.8, {
      ease: FlxEase.quadOut,
      onComplete: (twn) ->
      {
        FlxG.camera.filtersEnabled = false;
      }
    });
    FlxTween.tween(cameraFollowPoint, {
      y: cameraFollowPoint.y + 150
    }, 1.5, {
      ease: FlxEase.expoOut,
      onComplete: (_) ->
      {
        autoFollow = true;
        FlxG.camera.follow(cameraFollowPoint, LOCKON, 0.01);
      }
    });

    var blackScreen:FunkinSprite = new FunkinSprite(-(FlxG.width * 0.5), -(FlxG.height * 0.5)).makeSolidColor(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
    add(blackScreen);

    introSound.loadEmbedded(Paths.sound('ui/character-select/sounds/lights'));
    introSound.volume = 0;

    FlxG.sound.list.add(introSound);

    openSubState(new IntroSubState());

    subStateClosed.addOnce((_) ->
    {
      remove(blackScreen);

      // If this is the player's first time entering Character Select, play the intro sound
      if (!Save.instance.oldChar.value)
      {
        Save.instance.oldChar.value = true;

        camera.flash();

        introSound.volume = 1;
        introSound.play(true);
      }

      checkForUnlocks();
    });
  }

  function checkForUnlocks():Void
  {
    if (locksToUnlock.length > 0)
    {
      uiStateMachine.transition(UnlockAnimation);

      // We loop the idle animation since there's no music playing during the unlock sequence
      // Without looping, the characters would bop once and awkwardly remain static for 2 seconds
      if (characters.player.animation.curAnim != null)
      {
        characters.player.animation.curAnim.looped = true;
      }

      if (characters.gf.animation.curAnim != null)
      {
        characters.gf.animation.curAnim.looped = true;
      }

      FlxTimer.wait(2, () ->
      {
        if (characters.player.animation.curAnim != null)
        {
          characters.player.animation.curAnim.looped = false;
        }

        if (characters.gf.animation.curAnim != null)
        {
          characters.gf.animation.curAnim.looped = false;
        }

        playUnlockAnimation();
      });
    }
    else
    {
      #if FEATURE_NEWGROUNDS
      // Make the character unlock medal retroactive.
      if (availableChars.size() > 1) Medals.award(CharSelect);
      #end

      playMenuMusic();
    }
  }

  function playUnlockAnimation():Void
  {
    currentSelection = locksToUnlock[0];
    locksToUnlock.shift();

    var characterId:String = availableChars.get(currentSelection) ?? Constants.DEFAULT_CHARACTER;

    var newPlayer:Null<CharSelectCharacter> = characters.getCharacter(characterId, false);
    var newGf:Null<CharSelectCharacter> = characters.getCharacter(characterId, true);

    FlxTimer.wait(0.5, () ->
    {
      var lock:Null<FunkinSprite> = icons.getIconByIndex(currentSelection);
      if (lock == null)
      {
        throw 'I don\'t know how you triggered this, but the lock is null.';
      }

      lock.animation.play('unlock');
      lock.animation.onFrameChange.add((animName:String, frame:Int, index:Int) ->
      {
        if (frame == 2)
        {
          unlockSound.volume = 0.7;
          unlockSound.play(true);
        }

        if (frame == 38)
        {
          characters.player.playAnimation(UNLOCK);

          var finishSequence:String->Int->Int->Void = (animName:String, frame:Int, index:Int) ->
          {
            if (frame == 34)
            {
              camera.flash(0xFFFFFFFF, 0.1);

              // The locked character (characters.player) calls `kill()` on its own when the unlock animation finishes
              // so we don't need to kill it here.
              characters.gf.kill();

              newGf?.revive();
              newPlayer?.revive();
              newPlayer?.playAnimation(UNLOCK);

              nametag.loadCharacter(characterId);

              icons.replaceLock(characterId, currentSelection);
              icons.updateIconPositions();
              icons.playIconBop(characterId);

              #if FEATURE_NEWGROUNDS
              // Grant the medal when the player unlocks a character.
              Medals.award(CharSelect);
              #end

              Save.instance.addCharacterSeen(characterId);

              @:bypassAccessor
              currentCharacterId = characterId;

              if (locksToUnlock.isEmpty())
              {
                @:privateAccess
                characters.staticSound.stop();

                playMenuMusic();
              }
              else
              {
                if (newPlayer == null)
                {
                  playUnlockAnimation();
                }
                else
                {
                  if (newPlayer.animation.curAnim.looped)
                  {
                    newPlayer.animation.onLoop.addOnce((_) -> playUnlockAnimation());
                  }
                  else
                  {
                    newPlayer.animation.onFinish.addOnce((_) -> playUnlockAnimation());
                  }
                }
              }
            }
          };

          characters.player.animation.onFrameChange.add(finishSequence);
          characters.player.animation.onFinish.addOnce((_) -> characters.player.animation.onFrameChange.remove(finishSequence));
        }
      });
    });
  }

  function playMenuMusic():Void
  {
    FunkinSound.playMusic('ui/character-select/stay-funky/stay-funky', {
      startingVolume: 1,
      overrideExisting: true,
      restartTrack: true,
      onLoad: () ->
      {
        uiStateMachine.transition(Idle);

        characters.dispatchEvent(new ScriptEvent(CREATE));
      }
    });
  }

  override public function destroy():Void
  {
    instance = null;

    super.destroy();
  }

  override public function dispatchEvent(event:ScriptEvent, finish:Bool = true):Void
  {
    // super.dispatchEvent(event) dispatches event to module scripts.
    super.dispatchEvent(event, finish);

    // Dispatch events to characters
    characters.dispatchEvent(event);
    if (finish) event.finish();
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    Conductor.instance.update();

    #if FEATURE_TOUCH_CONTROLS
    var mobileAccept:Bool = false;
    #end

    if (uiStateMachine.canInteract())
    {
      if (!uiStateMachine.is(CharacterSelected))
      {
        #if FEATURE_TOUCH_CONTROLS
        if (TouchUtil.pressed || TouchUtil.justReleased)
        {
          @:privateAccess
          for (i => hitbox in icons.hitboxes.members)
          {
            if (hitbox == null || !TouchUtil.overlaps(hitbox)) continue;

            var currentPage:Int = Math.floor(currentSelection / SLOTS_PER_PAGE);
            var targetIndex:Int = i + currentPage * SLOTS_PER_PAGE;
            var iconPage:Int = Math.floor(targetIndex / SLOTS_PER_PAGE);
            if (iconPage != currentPage) continue;

            if (targetIndex != currentSelection)
            {
              currentSelection = targetIndex;
            }
            else if (TouchUtil.justPressed && !mobileAccept)
            {
              mobileAccept = true;
            }

            break;
          }
        }

        if (TouchUtil.overlaps(characterHitbox) && TouchUtil.justPressed && !mobileAccept)
        {
          mobileAccept = true;
        }

        // I don't fucking know what null-safety is complaining about here, I'm not gonna bother with it
        // - Abnormal
        @:nullSafety(Off)
        {
          // On mobile, use swiping to scroll the page.
          var scrollAmount:Int = 0;
          if (SwipeUtil.justSwipedUp) scrollAmount = -1;
          if (SwipeUtil.justSwipedDown) scrollAmount = 1;
          if (scrollAmount != 0)
          {
            var targetIndex:Int = currentSelection + Std.int(scrollAmount * SLOTS_PER_PAGE);
            currentSelection = Std.int(FlxMath.bound(targetIndex, 0, totalSlots - 1));
          }
        }
        #end

        inputHandler.handleDirectionInput(elapsed);

        if (controls.ACCEPT_P #if FEATURE_TOUCH_CONTROLS || mobileAccept #end)
        {
          selectCharacter();
        }

        if (controls.BACK_P)
        {
          goBack();
        }
      }
      else
      {
        if (controls.BACK_P #if FEATURE_TOUCH_CONTROLS || TouchUtil.justPressed #end)
        {
          deselectCharacter();
        }
      }
    }

    if (autoFollow)
    {
      cameraFollowPoint.screenCenter();
      cameraFollowPoint.x += (((currentSelection % SLOTS_PER_PAGE) % SLOTS_PER_ROW) - 1) * 10;
      cameraFollowPoint.y += (Math.floor((currentSelection % SLOTS_PER_PAGE) / SLOTS_PER_ROW) - 1) * 10;
    }
  }

  function selectCharacter():Void
  {
    if (currentCharacterId == 'locked')
    {
      characters.player.playAnimation(LOCKED, true);
      icons.playIconAnimation(currentSelection, 'clicked', true);
      cursors.deny();

      lockedSound.play(true);

      HapticUtil.vibrate(0, 0.2);
      return;
    }

    uiStateMachine.transition(CharacterSelected);

    inputHandler.reset();
    cursors.confirm();

    FunkinSound.playOnce(Paths.sound('ui/character-select/sounds/confirm'));

    var event:CharacterSelectScriptEvent = CharacterSelectScriptEvent.get(CHARACTER_CONFIRMED, currentCharacterId);
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

    characters.player.playAnimation(SELECT);
    characters.gf.playAnimation(SELECT);
    icons.playIconAnimation(currentSelection, 'confirm', true);

    selectTimer.start(1.5, (_) ->
    {
      goToFreeplay();
    });
  }

  function deselectCharacter():Void
  {
    uiStateMachine.transition(Idle);

    selectTimer.cancel();
    cursors.unconfirm();

    dispatchEvent(new CharacterSelectScriptEvent(CHARACTER_DESELECTED, currentCharacterId));

    #if FEATURE_TOUCH_CONTROLS
    if (backButton != null)
    {
      backButton.enabled = true;
    }
    #end

    FlxTween.cancelTweensOf(FlxG.sound.music);
    FlxTween.tween(FlxG.sound.music, {
      pitch: 1.0,
      volume: 1.0
    }, 1, {
      ease: FlxEase.quartInOut
    });

    characters.player.playAnimation(DESELECT);
    characters.gf.playAnimation(DESELECT);
    icons.playIconAnimation(currentSelection, 'confirm-reversed', true);

    FlxTween.tween(FlxG.sound.music, {
      pitch: 1.0
    }, 1, {
      ease: FlxEase.quartInOut,
      onComplete: (_) ->
      {
        if (characters.player.getCurrentAnimation().startsWith(DESELECT))
        {
          characters.player.playAnimation(IDLE, true);
          characters.gf.playAnimation(IDLE, true);
        }
      }
    });
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

  function goToFreeplay():Void
  {
    uiStateMachine.transition(Exiting);

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
    FlxTween.tween(topBar, {
      y: topBar.y + 80
    }, 0.8, {
      ease: FlxEase.backIn
    });
    FlxTween.tween(nametag.targetPosition, {
      y: nametag.targetPosition.y + 80
    }, 0.8, {
      ease: FlxEase.backIn
    });
    FlxTween.tween(chooseDipshit, {
      y: chooseDipshit.y + 200
    }, 0.8, {
      ease: FlxEase.backIn
    });

    icons.doExitTween();

    FlxG.camera.follow(cameraFollowPoint, LOCKON);
    FlxTween.cancelTweensOf(transitionGradient);
    FlxTween.cancelTweensOf(fadeShader);
    FlxTween.cancelTweensOf(cameraFollowPoint);

    FlxTween.tween(transitionGradient, {
      y: -150
    }, 0.8, {
      ease: FlxEase.backIn
    });
    FlxG.camera.filtersEnabled = true;
    fadeShader.fade(1.0, 0, 0.8, {
      ease: FlxEase.quadIn
    });
    FlxTween.tween(cameraFollowPoint, {
      y: cameraFollowPoint.y - 150
    }, 0.8, {
      ease: FlxEase.backIn,
      onComplete: (_) ->
      {
        FlxG.switchState(() -> FreeplayState.build({
          {
            character: wentBackToFreeplay ? rememberedCharacterId : currentCharacterId,
            fromCharSelect: true
          }
        }));
      }
    });
  }
}
