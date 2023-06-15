package funkin.play;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.system.FlxSound;
import funkin.ui.story.StoryMenuState;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.PlayState;
import funkin.play.character.BaseCharacter;
import funkin.ui.PreferencesMenu;

/**
 * A substate which renders over the PlayState when the player dies.
 * Displays the player death animation, plays the music, and handles restarting the song.
 * 
 * The newest implementation uses a substate, which prevents having to reload the song and stage each reset.
 */
class GameOverSubstate extends MusicBeatSubstate
{
  /**
   * Which alternate animation on the character to use.
   * You can set this via script.
   * For example, playing a different animation when BF dies in Week 4
   * or Pico dies in Weekend 1.
   */
  public static var animationSuffix:String = "";

  /**
   * Which alternate game over music to use.
   * You can set this via script.
   * For example, the bf-pixel script sets this to `-pixel`
   * and the pico-playable script sets this to `Pico`.
   */
  public static var musicSuffix:String = "";

  /**
   * Which alternate "blue ball" sound effect to use.
   */
  public static var blueBallSuffix:String = "";

  /**
   * The boyfriend character.
   */
  var boyfriend:BaseCharacter;

  /**
   * The invisible object in the scene which the camera focuses on.
   */
  var cameraFollowPoint:FlxObject;

  /**
   * The music playing in the background of the state.
   */
  var gameOverMusic:FlxSound = new FlxSound();

  /**
   * Whether the player has confirmed and prepared to restart the level.
   * This means the animation and transition have already started.
   */
  var isEnding:Bool = false;

  public function new()
  {
    super();
  }

  /**
   * Reset the game over configuration to the default.
   */
  public static function reset()
  {
    animationSuffix = "";
    musicSuffix = "";
  }

  override public function create()
  {
    super.create();

    //
    // Set up the visuals
    //

    // Add a black background to the screen.
    // We make this transparent so that we can see the stage underneath during debugging.
    var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
    bg.alpha = 0.25;
    bg.scrollFactor.set();
    add(bg);

    // Pluck Boyfriend from the PlayState and place him (in the same position) in the GameOverSubstate.
    // We can then play the character's `firstDeath` animation.
    boyfriend = PlayState.instance.currentStage.getBoyfriend(true);
    boyfriend.isDead = true;
    add(boyfriend);
    boyfriend.resetCharacter();

    // Assign a camera follow point to the boyfriend's position.
    cameraFollowPoint = new FlxObject(PlayState.instance.cameraFollowPoint.x, PlayState.instance.cameraFollowPoint.y, 1, 1);
    cameraFollowPoint.x = boyfriend.getGraphicMidpoint().x;
    cameraFollowPoint.y = boyfriend.getGraphicMidpoint().y;
    add(cameraFollowPoint);

    FlxG.camera.target = null;
    FlxG.camera.follow(cameraFollowPoint, LOCKON, 0.01);

    //
    // Set up the audio
    //

    // Prepare the game over music.
    FlxG.sound.list.add(gameOverMusic);
    gameOverMusic.stop();

    // The conductor now represents the BPM of the game over music.
    Conductor.songPosition = 0;
  }

  var hasStartedAnimation:Bool = false;

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (!hasStartedAnimation)
    {
      hasStartedAnimation = true;

      if (boyfriend.hasAnimation('fakeoutDeath') && FlxG.random.bool((1 / 4096) * 100))
      {
        boyfriend.playAnimation('fakeoutDeath', true, true);
      }
      else
      {
        boyfriend.playAnimation('firstDeath', true, true);
        // Play the "blue balled" sound. May play a variant if one has been assigned.
        playBlueBalledSFX();
      }
    }

    //
    // Handle user inputs.
    //

    // MOBILE ONLY: Restart the level when tapping Boyfriend.
    if (FlxG.onMobile)
    {
      var touch = FlxG.touches.getFirst();
      if (touch != null)
      {
        if (touch.overlaps(boyfriend))
        {
          confirmDeath();
        }
      }
    }

    // KEYBOARD ONLY: Restart the level when pressing the assigned key.
    if (controls.ACCEPT)
    {
      confirmDeath();
    }

    // KEYBOARD ONLY: Return to the menu when pressing the assigned key.
    if (controls.BACK)
    {
      PlayState.deathCounter = 0;
      PlayState.seenCutscene = false;
      gameOverMusic.stop();

      if (PlayState.isStoryMode) FlxG.switchState(new StoryMenuState());
      else
        FlxG.switchState(new FreeplayState());
    }

    if (gameOverMusic.playing)
    {
      // Match the conductor to the music.
      // This enables the stepHit and beatHit events.
      Conductor.songPosition = gameOverMusic.time;
    }
    else
    {
      // Music hasn't started yet.
      switch (PlayState.storyWeek)
      {
        // TODO: Make the behavior for playing Jeff's voicelines generic or un-hardcoded.
        // This will simplify the class and make it easier for mods to add death quotes.
        case 7:
          if (boyfriend.getCurrentAnimation().startsWith('firstDeath') && boyfriend.isAnimationFinished() && !playingJeffQuote)
          {
            playingJeffQuote = true;
            playJeffQuote();
            // Start music at lower volume
            startDeathMusic(0.2, false);
          }
        default:
          // Start music at normal volume once the initial death animation finishes.
          if (boyfriend.getCurrentAnimation().startsWith('firstDeath') && boyfriend.isAnimationFinished())
          {
            startDeathMusic(1.0, false);
          }
      }
    }

    // Dispatch the onUpdate event.
    dispatchEvent(new UpdateScriptEvent(elapsed));
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

      boyfriend.playAnimation('deathConfirm' + animationSuffix, true);

      // After the animation finishes...
      new FlxTimer().start(0.7, function(tmr:FlxTimer) {
        // ...fade out the graphics. Then after that happens...
        FlxG.camera.fade(FlxColor.BLACK, 2, false, function() {
          // ...close the GameOverSubstate.
          FlxG.camera.fade(FlxColor.BLACK, 1, true, null, true);
          PlayState.needsReset = true;

          // Readd Boyfriend to the stage.
          boyfriend.isDead = false;
          remove(boyfriend);
          PlayState.instance.currentStage.addCharacter(boyfriend, BF);

          // Close the substate.
          close();
        });
      });
    }
  }

  override function dispatchEvent(event:ScriptEvent)
  {
    super.dispatchEvent(event);

    ScriptEventDispatcher.callEvent(boyfriend, event);
  }

  /**
   * Starts the death music at the appropriate volume.
   * @param startingVolume 
   */
  function startDeathMusic(?startingVolume:Float = 1, ?force:Bool = false):Void
  {
    var musicPath = Paths.music('gameOver' + musicSuffix);
    if (isEnding)
    {
      musicPath = Paths.music('gameOverEnd' + musicSuffix);
    }
    if (!gameOverMusic.playing || force)
    {
      gameOverMusic.loadEmbedded(musicPath);
      gameOverMusic.volume = startingVolume;
      gameOverMusic.play();
    }
  }

  /**
   * Play the sound effect that occurs when
   * boyfriend's testicles get utterly annihilated.
   */
  public static function playBlueBalledSFX()
  {
    FlxG.sound.play(Paths.sound('fnf_loss_sfx' + blueBallSuffix));
  }

  var playingJeffQuote:Bool = false;

  /**
   * Week 7-specific hardcoded behavior, to play a custom death quote.
   * TODO: Make this a module somehow.
   */
  function playJeffQuote()
  {
    var randomCensor:Array<Int> = [];

    if (PreferencesMenu.getPref('censor-naughty')) randomCensor = [1, 3, 8, 13, 17, 21];

    FlxG.sound.play(Paths.sound('jeffGameover/jeffGameover-' + FlxG.random.int(1, 25, randomCensor)), 1, false, null, true, function() {
      // Once the quote ends, fade in the game over music.
      if (!isEnding && gameOverMusic != null)
      {
        gameOverMusic.fadeIn(4, 0.2, 1);
      }
    });
  }
}
