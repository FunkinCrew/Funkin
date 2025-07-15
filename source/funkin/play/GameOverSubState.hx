package funkin.play;

import funkin.ui.freeplay.charselect.PlayableCharacter;
import flixel.FlxState;
import funkin.data.freeplay.player.PlayerRegistry;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.util.HapticUtil;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinSprite;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.character.BaseCharacter;
import funkin.ui.freeplay.FreeplayState;
import funkin.ui.MusicBeatSubState;
import funkin.ui.story.StoryMenuState;
import funkin.util.MathUtil;
import funkin.effects.RetroCameraFade;
import flixel.math.FlxPoint;
import funkin.util.TouchUtil;
import openfl.utils.Assets;
#if FEATURE_MOBILE_ADVERTISEMENTS
import funkin.mobile.util.AdMobUtil;
#end

/**
 * A substate which renders over the PlayState when the player dies.
 * Displays the player death animation, plays the music, and handles restarting the song.
 *
 * The newest implementation uses a substate, which prevents having to reload the song and stage each reset.
 */
@:nullSafety
class GameOverSubState extends MusicBeatSubState
{
  /**
   * The currently active GameOverSubState.
   * There should be only one GameOverSubState in existance at a time, we can use a singleton.
   */
  public static var instance:Null<GameOverSubState> = null;

  /**
   * Which alternate animation on the character to use.
   * You can set this via script.
   * For example, playing a different animation when BF dies in Week 4
   * or Pico dies in Weekend 1.
   */
  public static var animationSuffix:String = '';

  /**
   * Which alternate game over music to use.
   * You can set this via script.
   * For example, the bf-pixel script sets this to `-pixel`
   * and the pico-playable script sets this to `Pico`.
   */
  public static var musicSuffix:String = '';

  /**
   * Which alternate "blue ball" sound effect to use.
   */
  public static var blueBallSuffix:String = '';

  static var blueballed:Bool = false;

  /**
   * The boyfriend character.
   */
  var boyfriend:Null<BaseCharacter> = null;

  /**
   * The invisible object in the scene which the camera focuses on.
   */
  var cameraFollowPoint:FlxObject;

  /**
   * The music playing in the background of the state.
   */
  var gameOverMusic:Null<FunkinSound> = null;

  /**
   * Whether the player has confirmed and prepared to restart the level or to go back to the freeplay menu.
   * This means the animation and transition have already started.
   */
  var isEnding:Bool = false;

  /**
   * Whether the death music is on its first loop.
   */
  var isStarting:Bool = true;

  var isChartingMode:Bool = false;

  var mustNotExit:Bool = false;

  var transparent:Bool;

  static final CAMERA_ZOOM_DURATION:Float = 0.5;

  var targetCameraZoom:Float = 1.0;

  var canInput:Bool = false;

  var justDied:Bool = true;

  var isSpecialAnimation:Bool = false;

  var gameOverVibrationPreset:VibrationPreset =
    {
      period: 0,
      duration: Constants.DEFAULT_VIBRATION_DURATION,
      amplitude: Constants.MIN_VIBRATION_AMPLITUDE,
      sharpness: Constants.DEFAULT_VIBRATION_SHARPNESS
    };

  public function new(params:GameOverParams)
  {
    super();

    this.isChartingMode = params?.isChartingMode ?? false;
    transparent = params.transparent;

    cameraFollowPoint = new FlxObject(0, 0, 1, 1);
    if (parentPlayState != null)
    {
      cameraFollowPoint.x = parentPlayState.cameraFollowPoint.x;
      cameraFollowPoint.y = parentPlayState.cameraFollowPoint.y;
    }
  }

  /**
   * The PlayState that this GameOverSubState is displaying on top of.
   */
  public var parentPlayState:Null<PlayState>;

  /**
   * Reset the game over configuration to the default.
   */
  public static function reset():Void
  {
    animationSuffix = '';
    musicSuffix = '';
    blueBallSuffix = '';
    blueballed = false;
  }

  public override function create():Void
  {
    if (instance != null)
    {
      FlxG.log.warn('WARNING: GameOverSubState instance already exists. This should not happen.');
    }
    instance = this;

    super.create();

    parentPlayState = cast _parentState;

    //
    // Set up the visuals
    //

    // Add a black background to the screen.
    var bg:FunkinSprite = new FunkinSprite().makeSolidColor(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
    // We make this transparent so that we can see the stage underneath during debugging,
    // but it's normally opaque.
    bg.alpha = transparent ? 0.25 : 1.0;
    bg.scrollFactor.set();
    bg.screenCenter();
    add(bg);

    // Pluck Boyfriend from the PlayState and place him (in the same position) in the GameOverSubState.
    // We can then play the character's `firstDeath` animation.
    if ((parentPlayState?.isMinimalMode ?? true)) {}
    else
    {
      boyfriend = parentPlayState?.currentStage.getBoyfriend(true);
      if (boyfriend != null)
      {
        boyfriend.canPlayOtherAnims = true;
        boyfriend.isDead = true;
        add(boyfriend);
        boyfriend.resetCharacter();
      }
    }

    setCameraTarget();

    //
    // Set up the audio
    //

    // The conductor now represents the BPM of the game over music.
    Conductor.instance.update(0);

    #if mobile
    addBackButton(FlxG.width - 230, FlxG.height - 200, FlxColor.WHITE, goBack);
    #end

    // Allow input a second later to prevent accidental gameover skips.
    new FlxTimer().start(1, function(tmr:FlxTimer) {
      canInput = true;
    });
  }

  @:nullSafety(Off)
  function setCameraTarget():Void
  {
    if ((parentPlayState?.isMinimalMode ?? true) || boyfriend == null) return;

    // Assign a camera follow point to the boyfriend's position.
    cameraFollowPoint = new FlxObject(parentPlayState.cameraFollowPoint.x, parentPlayState.cameraFollowPoint.y, 1, 1);
    cameraFollowPoint.x = getMidPointOld(boyfriend).x;
    cameraFollowPoint.y = getMidPointOld(boyfriend).y;
    var offsets:Array<Float> = boyfriend.getDeathCameraOffsets();
    cameraFollowPoint.x += offsets[0];
    cameraFollowPoint.y += offsets[1];
    add(cameraFollowPoint);

    FlxG.camera.target = null;
    FlxG.camera.follow(cameraFollowPoint, LOCKON, Constants.DEFAULT_CAMERA_FOLLOW_RATE / 2);
    targetCameraZoom = (parentPlayState?.currentStage?.camZoom ?? 1.0) * boyfriend.getDeathCameraZoom();
  }

  /**
   * FlxSprite.getMidpoint(); calculations changed in this git commit
   * https://github.com/HaxeFlixel/flixel/commit/1553b5af0871462fcefedc091b7885437d6c36d2
   * https://github.com/HaxeFlixel/flixel/pull/3125
   *
   * So we use this to do the old math that gets the midpoint of our graphics
   * Luckily, we don't use getGraphicMidpoint() much in the code, so it's fine being in GameoverSubState here.
   * @return FlxPoint
   */
  function getMidPointOld(spr:FlxSprite, ?point:FlxPoint):FlxPoint
  {
    if (point == null) point = FlxPoint.get();
    return point.set(spr.x + spr.frameWidth * 0.5 * spr.scale.x, spr.y + spr.frameHeight * 0.5 * spr.scale.y);
  }

  /**
   * Forcibly reset the camera zoom level to that of the current stage.
   * This prevents camera zoom events from adversely affecting the game over state.
   */
  public function resetCameraZoom():Void
  {
    // Apply camera zoom level from stage data.
    FlxG.camera.zoom = parentPlayState?.currentStage?.camZoom ?? 1.0;
  }

  var hasStartedAnimation:Bool = false;

  override function update(elapsed:Float):Void
  {
    if (!hasStartedAnimation)
    {
      hasStartedAnimation = true;

      if (boyfriend == null || (parentPlayState?.isMinimalMode ?? true))
      {
        // Play the "blue balled" sound. May play a variant if one has been assigned.
        playBlueBalledSFX();
      }
      else
      {
        if (boyfriend.hasAnimation('fakeoutDeath') && FlxG.random.bool((1 / 4096) * 100))
        {
          boyfriend.playAnimation('fakeoutDeath', true, false);
        }
        else
        {
          boyfriend.playAnimation('firstDeath', true, false); // ignoreOther is set to FALSE since you WANT to be able to mash and confirm game over!
          // Play the "blue balled" sound. May play a variant if one has been assigned.
          playBlueBalledSFX();
        }
      }
    }

    // Smoothly lerp the camera
    FlxG.camera.zoom = MathUtil.smoothLerpPrecision(FlxG.camera.zoom, targetCameraZoom, elapsed, CAMERA_ZOOM_DURATION);

    //
    // Handle user inputs.
    //

    // Restart the level when pressing the assigned key.
    if ((controls.ACCEPT #if mobile || (TouchUtil.pressAction() && !TouchUtil.overlaps(backButton) && canInput) #end)
      && blueballed
      && !mustNotExit)
    {
      blueballed = false;
      confirmDeath();
    }

    if (controls.BACK && !mustNotExit && !isEnding) goBack();

    if (gameOverMusic != null && gameOverMusic.playing)
    {
      // Match the conductor to the music.
      // This enables the stepHit and beatHit events.
      Conductor.instance.update(gameOverMusic.time);
    }
    else if (boyfriend != null)
    {
      if ((parentPlayState?.isMinimalMode ?? true))
      {
        // Do nothing?
      }
      else
      {
        // Music hasn't started yet.

        if (boyfriend.getDeathQuote() != null)
        {
          if (boyfriend.getCurrentAnimation().startsWith('firstDeath') && boyfriend.isAnimationFinished() && !hasPlayedDeathQuote)
          {
            hasPlayedDeathQuote = true;
            playDeathQuote();
          }
        }
        else
        {
          // Start music at normal volume once the initial death animation finishes.
          if (boyfriend.getCurrentAnimation().startsWith('firstDeath') && boyfriend.isAnimationFinished())
          {
            startDeathMusic(1.0, false);
            boyfriend.playAnimation('deathLoop' + animationSuffix);
          }
        }
      }
    }

    // Handle vibrations on update.
    if (HapticUtil.hapticsAvailable) handleAnimationVibrations();

    // Start death music before firstDeath gets replaced
    super.update(elapsed);
  }

  var deathQuoteSound:Null<FunkinSound> = null;

  function playDeathQuote():Void
  {
    if (isEnding) return;
    if (boyfriend == null) return;
    if (parentPlayState == null) return;

    var deathQuote:Null<String> = boyfriend.getDeathQuote();
    if (deathQuote == null) return;

    if (deathQuoteSound != null)
    {
      deathQuoteSound.stop();
      deathQuoteSound = null;
    }

    // Start music at lower volume
    startDeathMusic(0.2, false);
    boyfriend.playAnimation('deathLoop' + animationSuffix);
    deathQuoteSound = FunkinSound.playOnce(deathQuote, function() {
      // Once the quote ends, fade in the game over music.
      if (!isEnding && gameOverMusic != null)
      {
        gameOverMusic.fadeIn(4, 0.2, 1);
      }
    });
  }

  /**
   * Do behavior which occurs when you confirm and move to restart the level.
   */
  function confirmDeath():Void
  {
    if (!isEnding)
    {
      isEnding = true;

      // Stop death quotes immediately.
      hasPlayedDeathQuote = true;
      if (deathQuoteSound != null)
      {
        deathQuoteSound.stop();
        deathQuoteSound = null;
      }

      startDeathMusic(1.0, true); // isEnding changes this function's behavior.

      if ((parentPlayState?.isMinimalMode ?? true) || boyfriend == null) {}
      else
      {
        boyfriend.playAnimation('deathConfirm' + animationSuffix, true);
      }

      // After the animation finishes...
      new FlxTimer().start(0.7, function(tmr:FlxTimer) {
        // ...fade out the graphics. Then after that happens...

        var resetPlaying = function(pixel:Bool = false) {
          // ...close the GameOverSubState.
          if (pixel) RetroCameraFade.fadeBlack(FlxG.camera, 10, 1);
          else
            FlxG.camera.fade(FlxColor.BLACK, 1, true, null, true);
          if (parentPlayState != null) parentPlayState.needsReset = true;

          if ((parentPlayState?.isMinimalMode ?? true) || boyfriend == null) {}
          else
          {
            // Readd Boyfriend to the stage.
            boyfriend.isDead = false;
            remove(boyfriend);
            parentPlayState?.currentStage.addCharacter(boyfriend, BF);
          }

          // Snap reset the camera which may have changed because of the player character data.
          resetCameraZoom();

          // Close the substate.
          close();
        };

        if (musicSuffix == '-pixel')
        {
          RetroCameraFade.fadeToBlack(FlxG.camera, 10, 2);
          new FlxTimer().start(2, _ -> {
            FlxG.camera.filters = [];
            #if FEATURE_MOBILE_ADVERTISEMENTS
            if (AdMobUtil.PLAYING_COUNTER >= AdMobUtil.MAX_BEFORE_AD)
            {
              AdMobUtil.loadInterstitial(function():Void {
                AdMobUtil.PLAYING_COUNTER = 0;
                resetPlaying(true);
              });
            }
            else
              resetPlaying(true);
            #else
            resetPlaying(true);
            #end
          });
        }
        else
        {
          FlxG.camera.fade(FlxColor.BLACK, 2, false, function() {
            #if FEATURE_MOBILE_ADVERTISEMENTS
            if (AdMobUtil.PLAYING_COUNTER >= AdMobUtil.MAX_BEFORE_AD)
            {
              AdMobUtil.loadInterstitial(function():Void {
                AdMobUtil.PLAYING_COUNTER = 0;
                resetPlaying();
              });
            }
            else
              resetPlaying();
            #else
            resetPlaying();
            #end
          });
        }
      });
    }
  }

  public override function dispatchEvent(event:ScriptEvent):Void
  {
    super.dispatchEvent(event);

    ScriptEventDispatcher.callEvent(boyfriend, event);
  }

  /**
   * Rather than hardcoding stuff, we look for the presence of a music file
   * with the given suffix, and strip it down until we find one that's valid.
   */
  function resolveMusicPath(suffix:String, starting:Bool = false, ending:Bool = false):Null<String>
  {
    var basePath:String = 'gameplay/gameover/gameOver';
    if (ending) basePath += 'End';
    else if (starting) basePath += 'Start';

    var musicPath:String = Paths.music(basePath + suffix);
    while (!Assets.exists(musicPath) && suffix.length > 0)
    {
      suffix = suffix.split('-').slice(0, -1).join('-');
      musicPath = Paths.music(basePath + suffix);
    }
    if (!Assets.exists(musicPath)) return null;
    trace('Resolved music path: ' + musicPath);
    return musicPath;
  }

  /**
   * Starts the death music at the appropriate volume.
   * @param startingVolume The initial volume for the music.
   * @param force Whether or not to force the music to restart.
   */
  public function startDeathMusic(startingVolume:Float = 1, force:Bool = false):Void
  {
    var musicPath:Null<String> = resolveMusicPath(musicSuffix, isStarting, isEnding);
    var onComplete:Void->Void = () -> {};

    if (isStarting)
    {
      if (musicPath == null)
      {
        // Looked for starting music and didn't find it. Use middle music instead.
        isStarting = false;
        musicPath = resolveMusicPath(musicSuffix, isStarting, isEnding);
      }
      else
      {
        onComplete = function() {
          isStarting = true;
          // We need to force to ensure that the non-starting music plays.
          startDeathMusic(0.0, true);
        };
      }
    }

    if (musicPath == null)
    {
      FlxG.log.warn('[GAMEOVER] Could not find game over music at path ($musicPath)!');
      return;
    }
    else if (gameOverMusic == null || !gameOverMusic.playing || force)
    {
      if (gameOverMusic != null) gameOverMusic.stop();

      gameOverMusic = FunkinSound.load(musicPath);
      if (gameOverMusic == null) return;

      gameOverMusic.volume = startingVolume;
      gameOverMusic.looped = !(isEnding || isStarting);
      gameOverMusic.onComplete = onComplete;
      gameOverMusic.play();
    }
    else
    {
      @:privateAccess
      trace('Music already playing! ${gameOverMusic?._label}');
    }
  }

  /**
   * Pressing BACK from the Game Over screen should return the player to the Story/Freeplay menu as appropriate.
   */
  public function goBack():Void
  {
    if (blueballed == false) return;
    isEnding = true;
    blueballed = false;
    if (parentPlayState != null) parentPlayState.deathCounter = 0;
    // PlayState.seenCutscene = false; // old thing...
    if (gameOverMusic != null) gameOverMusic.stop();

    // Stop death quotes immediately.
    hasPlayedDeathQuote = true;
    if (deathQuoteSound != null)
    {
      deathQuoteSound.stop();
      deathQuoteSound = null;
    }

    if (isChartingMode)
    {
      this.close();
      if (FlxG.sound.music != null) FlxG.sound.music.pause(); // Don't reset song position!
      if (parentPlayState != null) parentPlayState.close(); // This only works because PlayState is a substate!
      parentPlayState = null;
      return;
    }
    else
    {
      var targetState:funkin.ui.transition.stickers.StickerSubState->FlxState = (PlayStatePlaylist.isStoryMode) ? (sticker) ->
        new StoryMenuState(sticker) : (sticker) -> FreeplayState.build(sticker);

      if (PlayStatePlaylist.isStoryMode)
      {
        PlayStatePlaylist.reset();
      }

      var stickerPackId:Null<String> = parentPlayState?.currentChart.stickerPack;

      if (stickerPackId == null)
      {
        var playerCharacterId:Null<String> = PlayerRegistry.instance.getCharacterOwnerId(parentPlayState?.currentChart.characters.player);
        var playerCharacter:Null<PlayableCharacter> = PlayerRegistry.instance.fetchEntry(playerCharacterId ?? Constants.DEFAULT_CHARACTER);

        if (playerCharacter != null)
        {
          stickerPackId = playerCharacter.getStickerPackID();
        }
      }

      openSubState(new funkin.ui.transition.stickers.StickerSubState({targetState: targetState, stickerPack: stickerPackId}));
    }
  }

  /**
   * Play the sound effect that occurs when
   * boyfriend's testicles get utterly annihilated.
   */
  public static function playBlueBalledSFX():Void
  {
    blueballed = true;

    if (Assets.exists(Paths.sound('gameplay/gameover/fnf_loss_sfx' + blueBallSuffix)))
    {
      FunkinSound.playOnce(Paths.sound('gameplay/gameover/fnf_loss_sfx' + blueBallSuffix));
    }
    else
    {
      FlxG.log.error('Missing blue ball sound effect: ' + Paths.sound('gameplay/gameover/fnf_loss_sfx' + blueBallSuffix));
    }
  }

  var hasPlayedDeathQuote:Bool = false;

  /**
   * Used for death haptics.
   */
  var startedTimerHaptics:Bool = false;

  /**
   * Unique vibrations for each death animation.
   */
  function handleAnimationVibrations():Void
  {
    if ((parentPlayState?.isMinimalMode ?? true) || boyfriend == null) return;

    if (justDied)
    {
      if (isSpecialAnimation)
      {
        HapticUtil.vibrate(0, Constants.DEFAULT_VIBRATION_DURATION * 5);
        trace("It's a special game over animation.");
      }
      else
      {
        HapticUtil.vibrate(0, Constants.DEFAULT_VIBRATION_DURATION);
      }
      justDied = false;
    }

    if (boyfriend.animation == null) return;

    final curFrame:Int = (boyfriend.animation.curAnim != null) ? boyfriend.animation.curAnim.curFrame : -1;
    if (boyfriend.characterId.startsWith("bf"))
    {
      // BF's mic drops.
      if (boyfriend.getCurrentAnimation().startsWith('firstDeath') && curFrame == 27)
      {
        HapticUtil.vibrateByPreset(gameOverVibrationPreset);
      }

      // BF's balls pulsating.
      if (boyfriend.getCurrentAnimation().startsWith('deathLoop') && (curFrame == 0 || curFrame == 18))
      {
        HapticUtil.vibrateByPreset(gameOverVibrationPreset);
      }

      return;
    }

    // Pico dies because of Darnell beating him up.
    if (boyfriend.characterId == "pico-blazin")
    {
      if (!startedTimerHaptics)
      {
        startedTimerHaptics = true;

        new FlxTimer().start(0.5, function(tmr:FlxTimer) {
          // Pico falls on his knees.
          HapticUtil.vibrateByPreset(gameOverVibrationPreset);

          new FlxTimer().start(0.6, function(tmr:FlxTimer) {
            // Pico falls "asleep". :)
            HapticUtil.vibrateByPreset(gameOverVibrationPreset);
          });
        });

        return;
      }
    }
    else if (boyfriend.characterId.startsWith("pico") && boyfriend.characterId != "pico-holding-nene")
    {
      if (isSpecialAnimation)
      {
        if (startedTimerHaptics) return;

        startedTimerHaptics = true;

        // Death by Darnell's can.
        new FlxTimer().start(1.85, function(tmr:FlxTimer) {
          // Pico falls on his knees.
          HapticUtil.vibrateByPreset(gameOverVibrationPreset);
        });
      }
      else
      {
        // Pico falls on his back.
        if (boyfriend.getCurrentAnimation().startsWith('firstDeath') && curFrame == 20)
        {
          HapticUtil.vibrateByPreset(gameOverVibrationPreset);
        }

        // Blood firework woohoo!!!!
        if (boyfriend.getCurrentAnimation().startsWith('deathLoop') && curFrame % 2 == 0)
        {
          final randomAmplitude:Float = FlxG.random.float(Constants.MIN_VIBRATION_AMPLITUDE / 100, Constants.MIN_VIBRATION_AMPLITUDE);
          final randomDuration:Float = FlxG.random.float(Constants.DEFAULT_VIBRATION_DURATION / 10, Constants.DEFAULT_VIBRATION_DURATION);

          HapticUtil.vibrate(0, randomDuration, randomAmplitude);
        }
      }

      return;
    }
  }

  public override function destroy():Void
  {
    super.destroy();
    if (gameOverMusic != null)
    {
      gameOverMusic.stop();
      gameOverMusic = null;
    }
    blueballed = false;
    instance = null;
  }

  public override function toString():String
  {
    return 'GameOverSubState';
  }
}

/**
 * Parameters used to instantiate a GameOverSubState.
 */
typedef GameOverParams =
{
  var isChartingMode:Bool;
  var transparent:Bool;
}
