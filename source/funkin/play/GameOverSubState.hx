package funkin.play;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.input.touch.FlxTouch;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinSprite;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.character.BaseCharacter;
import funkin.ui.freeplay.FreeplayState;
import funkin.ui.MusicBeatSubState;
import funkin.ui.story.StoryMenuState;
import funkin.util.MathUtil;
import openfl.utils.Assets;
import funkin.effects.RetroCameraFade;
import flixel.math.FlxPoint;

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

  public function new(params:GameOverParams)
  {
    super();

    this.isChartingMode = params?.isChartingMode ?? false;
    transparent = params.transparent;

    cameraFollowPoint = new FlxObject(PlayState.instance.cameraFollowPoint.x, PlayState.instance.cameraFollowPoint.y, 1, 1);
  }

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
      // TODO: Do something in this case? IDK.
      FlxG.log.warn('WARNING: GameOverSubState instance already exists. This should not happen.');
    }
    instance = this;

    super.create();

    //
    // Set up the visuals
    //

    var playState = PlayState.instance;

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
    if (PlayState.instance.isMinimalMode) {}
    else
    {
      boyfriend = PlayState.instance.currentStage.getBoyfriend(true);
      boyfriend.canPlayOtherAnims = true;
      boyfriend.isDead = true;
      add(boyfriend);
      boyfriend.resetCharacter();
    }

    setCameraTarget();

    //
    // Set up the audio
    //

    // The conductor now represents the BPM of the game over music.
    Conductor.instance.update(0);
  }

  @:nullSafety(Off)
  function setCameraTarget():Void
  {
    if (PlayState.instance.isMinimalMode || boyfriend == null) return;

    // Assign a camera follow point to the boyfriend's position.
    cameraFollowPoint = new FlxObject(PlayState.instance.cameraFollowPoint.x, PlayState.instance.cameraFollowPoint.y, 1, 1);
    cameraFollowPoint.x = getMidPointOld(boyfriend).x;
    cameraFollowPoint.y = getMidPointOld(boyfriend).y;
    var offsets:Array<Float> = boyfriend.getDeathCameraOffsets();
    cameraFollowPoint.x += offsets[0];
    cameraFollowPoint.y += offsets[1];
    add(cameraFollowPoint);

    FlxG.camera.target = null;
    FlxG.camera.follow(cameraFollowPoint, LOCKON, Constants.DEFAULT_CAMERA_FOLLOW_RATE / 2);
    targetCameraZoom = (PlayState?.instance?.currentStage?.camZoom ?? 1.0) * boyfriend.getDeathCameraZoom();
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
    FlxG.camera.zoom = PlayState?.instance?.currentStage?.camZoom ?? 1.0;
  }

  var hasStartedAnimation:Bool = false;

  override function update(elapsed:Float):Void
  {
    if (!hasStartedAnimation)
    {
      hasStartedAnimation = true;

      if (boyfriend == null || PlayState.instance.isMinimalMode)
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
    FlxG.camera.zoom = MathUtil.smoothLerp(FlxG.camera.zoom, targetCameraZoom, elapsed, CAMERA_ZOOM_DURATION);

    //
    // Handle user inputs.
    //

    // MOBILE ONLY: Restart the level when tapping Boyfriend.
    if (FlxG.onMobile)
    {
      var touch:FlxTouch = FlxG.touches.getFirst();
      if (touch != null)
      {
        if (boyfriend == null || touch.overlaps(boyfriend))
        {
          confirmDeath();
        }
      }
    }

    // KEYBOARD ONLY: Restart the level when pressing the assigned key.
    if (controls.ACCEPT && blueballed && !mustNotExit)
    {
      blueballed = false;
      confirmDeath();
    }

    // KEYBOARD ONLY: Return to the menu when pressing the assigned key.
    if (controls.BACK && !mustNotExit && !isEnding)
    {
      isEnding = true;
      blueballed = false;
      PlayState.instance.deathCounter = 0;
      // PlayState.seenCutscene = false; // old thing...
      if (gameOverMusic != null) gameOverMusic.stop();

      if (isChartingMode)
      {
        this.close();
        if (FlxG.sound.music != null) FlxG.sound.music.pause(); // Don't reset song position!
        PlayState.instance.close(); // This only works because PlayState is a substate!
        return;
      }
      else if (PlayStatePlaylist.isStoryMode)
      {
        openSubState(new funkin.ui.transition.StickerSubState(null, (sticker) -> new StoryMenuState(sticker)));
      }
      else
      {
        openSubState(new funkin.ui.transition.StickerSubState(null, (sticker) -> FreeplayState.build(sticker)));
      }
    }

    if (gameOverMusic != null && gameOverMusic.playing)
    {
      // Match the conductor to the music.
      // This enables the stepHit and beatHit events.
      Conductor.instance.update(gameOverMusic.time);
    }
    else if (boyfriend != null)
    {
      if (PlayState.instance.isMinimalMode)
      {
        // startDeathMusic(1.0, false);
      }
      else
      {
        // Music hasn't started yet.
        switch (PlayStatePlaylist.campaignId)
        {
          // TODO: Make the behavior for playing Jeff's voicelines generic or un-hardcoded.
          // This will simplify the class and make it easier for mods to add death quotes.
          case 'week7':
            if (boyfriend.getCurrentAnimation().startsWith('firstDeath') && boyfriend.isAnimationFinished() && !playingJeffQuote)
            {
              playingJeffQuote = true;
              playJeffQuote();
              // Start music at lower volume
              startDeathMusic(0.2, false);
              boyfriend.playAnimation('deathLoop' + animationSuffix);
            }
          default:
            // Start music at normal volume once the initial death animation finishes.
            if (boyfriend.getCurrentAnimation().startsWith('firstDeath') && boyfriend.isAnimationFinished())
            {
              startDeathMusic(1.0, false);
              boyfriend.playAnimation('deathLoop' + animationSuffix);
            }
        }
      }
    }

    // Start death music before firstDeath gets replaced
    super.update(elapsed);
  }

  /**
   * Do behavior which occurs when you confirm and move to restart the level.
   */
  function confirmDeath():Void
  {
    if (!isEnding)
    {
      isEnding = true;
      startDeathMusic(1.0, true); // isEnding changes this function's behavior.

      if (PlayState.instance.isMinimalMode || boyfriend == null) {}
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
          PlayState.instance.needsReset = true;

          if (PlayState.instance.isMinimalMode || boyfriend == null) {}
          else
          {
            // Readd Boyfriend to the stage.
            boyfriend.isDead = false;
            remove(boyfriend);
            PlayState.instance.currentStage.addCharacter(boyfriend, BF);
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
            resetPlaying(true);
          });
        }
        else
        {
          FlxG.camera.fade(FlxColor.BLACK, 2, false, function() {
            resetPlaying();
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
    var onComplete:() -> Void = () -> {};

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
          startDeathMusic(1.0, true);
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

  var playingJeffQuote:Bool = false;

  /**
   * Week 7-specific hardcoded behavior, to play a custom death quote.
   * TODO: Make this a module somehow.
   */
  function playJeffQuote():Void
  {
    var randomCensor:Array<Int> = [];

    if (!Preferences.naughtyness) randomCensor = [1, 3, 8, 13, 17, 21];

    FunkinSound.playOnce(Paths.sound('jeffGameover/jeffGameover-' + FlxG.random.int(1, 25, randomCensor)), function() {
      // Once the quote ends, fade in the game over music.
      if (!isEnding && gameOverMusic != null)
      {
        gameOverMusic.fadeIn(4, 0.2, 1);
      }
    });
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
