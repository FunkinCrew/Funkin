package funkin.ui.freeplay;

import flixel.FlxSprite;
import flixel.util.FlxSignal;
import funkin.util.assets.FlxAnimationUtil;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.audio.FunkinSound;
import flixel.util.FlxTimer;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.data.freeplay.player.PlayerData.PlayerFreeplayDJData;
import funkin.audio.FunkinSound;
import funkin.audio.FlxStreamSound;

class FreeplayDJ extends FlxAtlasSprite
{
  // Represents the sprite's current status.
  // Without state machines I would have driven myself crazy years ago.
  // Made this PRIVATE so we can keep track of everything that can alter the state!
  //   Add a function to this class if you want to edit this value from outside.
  private var currentState:FreeplayDJState = Intro;

  // A callback activated when the intro animation finishes.
  public var onIntroDone:FlxSignal = new FlxSignal();

  // A callback activated when the idle easter egg plays.
  public var onIdleEasterEgg:FlxSignal = new FlxSignal();

  var seenIdleEasterEgg:Bool = false;

  static final IDLE_EGG_PERIOD:Float = 60.0;
  static final IDLE_CARTOON_PERIOD:Float = 120.0;

  // Time since last special idle animation you.
  var timeIdling:Float = 0;

  final characterId:String = Constants.DEFAULT_CHARACTER;
  final playableCharData:PlayerFreeplayDJData;

  public function new(x:Float, y:Float, characterId:String)
  {
    this.characterId = characterId;

    var playableChar = PlayerRegistry.instance.fetchEntry(characterId);
    playableCharData = playableChar.getFreeplayDJData();

    super(x, y, playableCharData.getAtlasPath());

    onAnimationFrame.add(function(name, number) {
      if (name == playableCharData.getAnimationPrefix('cartoon'))
      {
        if (number == playableCharData.getCartoonSoundClickFrame())
        {
          FunkinSound.playOnce(Paths.sound('remote_click'));
        }
        if (number == playableCharData.getCartoonSoundCartoonFrame())
        {
          runTvLogic();
        }
      }
    });

    FlxG.debugger.track(this);
    FlxG.console.registerObject("dj", this);

    onAnimationComplete.add(onFinishAnim);

    FlxG.console.registerFunction("freeplayCartoon", function() {
      currentState = Cartoon;
    });
  }

  override public function listAnimations():Array<String>
  {
    var anims:Array<String> = [];
    @:privateAccess
    for (animKey in anim.symbolDictionary)
    {
      anims.push(animKey.name);
    }
    return anims;
  }

  var lowPumpLoopPoint:Int = 4;

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    switch (currentState)
    {
      case Intro:
        // Play the intro animation then leave this state immediately.
        var animPrefix = playableCharData.getAnimationPrefix('intro');
        if (getCurrentAnimation() != animPrefix) playFlashAnimation(animPrefix, true);
        timeIdling = 0;
      case Idle:
        // We are in this state the majority of the time.
        var animPrefix = playableCharData.getAnimationPrefix('idle');
        if (getCurrentAnimation() != animPrefix)
        {
          playFlashAnimation(animPrefix, true, false, true);
        }

        if (getCurrentAnimation() == animPrefix && this.isLoopComplete())
        {
          if (timeIdling >= IDLE_EGG_PERIOD && !seenIdleEasterEgg)
          {
            currentState = IdleEasterEgg;
          }
          else if (timeIdling >= IDLE_CARTOON_PERIOD)
          {
            currentState = Cartoon;
          }
        }
        timeIdling += elapsed;
      case NewUnlock:
        var animPrefix = playableCharData.getAnimationPrefix('newUnlock');
        if (!hasAnimation(animPrefix))
        {
          currentState = Idle;
        }
        if (getCurrentAnimation() != animPrefix)
        {
          playFlashAnimation(animPrefix, true, false, true);
        }
      case Confirm:
        var animPrefix = playableCharData.getAnimationPrefix('confirm');
        if (getCurrentAnimation() != animPrefix) playFlashAnimation(animPrefix, false);
        timeIdling = 0;
      case FistPumpIntro:
        var animPrefixA = playableCharData.getAnimationPrefix('fistPump');
        var animPrefixB = playableCharData.getAnimationPrefix('loss');

        if (getCurrentAnimation() == animPrefixA)
        {
          var endFrame = playableCharData.getFistPumpIntroEndFrame();
          if (endFrame > -1 && anim.curFrame >= endFrame)
          {
            playFlashAnimation(animPrefixA, true, false, false, playableCharData.getFistPumpIntroStartFrame());
          }
        }
        else if (getCurrentAnimation() == animPrefixB)
        {
          trace("Loss Intro");
          var endFrame = playableCharData.getFistPumpIntroBadEndFrame();
          if (endFrame > -1 && anim.curFrame >= endFrame)
          {
            playFlashAnimation(animPrefixB, true, false, false, playableCharData.getFistPumpIntroBadStartFrame());
          }
        }
        else
        {
          FlxG.log.warn("Unrecognized animation in FistPumpIntro: " + getCurrentAnimation());
        }

      case FistPump:
        var animPrefixA = playableCharData.getAnimationPrefix('fistPump');
        var animPrefixB = playableCharData.getAnimationPrefix('loss');

        if (getCurrentAnimation() == animPrefixA)
        {
          var endFrame = playableCharData.getFistPumpLoopEndFrame();
          if (endFrame > -1 && anim.curFrame >= endFrame)
          {
            playFlashAnimation(animPrefixA, true, false, false, playableCharData.getFistPumpLoopStartFrame());
          }
        }
        else if (getCurrentAnimation() == animPrefixB)
        {
          trace("Loss GYATT");
          var endFrame = playableCharData.getFistPumpLoopBadEndFrame();
          if (endFrame > -1 && anim.curFrame >= endFrame)
          {
            playFlashAnimation(animPrefixB, true, false, false, playableCharData.getFistPumpLoopBadStartFrame());
          }
        }
        else
        {
          FlxG.log.warn("Unrecognized animation in FistPump: " + getCurrentAnimation());
        }

      case IdleEasterEgg:
        var animPrefix = playableCharData.getAnimationPrefix('idleEasterEgg');
        if (getCurrentAnimation() != animPrefix)
        {
          onIdleEasterEgg.dispatch();
          playFlashAnimation(animPrefix, false);
          seenIdleEasterEgg = true;
        }
        timeIdling = 0;
      case Cartoon:
        var animPrefix = playableCharData.getAnimationPrefix('cartoon');
        if (animPrefix == null)
        {
          currentState = IdleEasterEgg;
        }
        else
        {
          if (getCurrentAnimation() != animPrefix) playFlashAnimation(animPrefix, true);
          timeIdling = 0;
        }
      default:
        // I shit myself.
    }

    #if FEATURE_DEBUG_FUNCTIONS
    if (FlxG.keys.pressed.CONTROL)
    {
      if (FlxG.keys.justPressed.LEFT)
      {
        this.offsetX -= FlxG.keys.pressed.ALT ? 0.1 : (FlxG.keys.pressed.SHIFT ? 10.0 : 1.0);
      }

      if (FlxG.keys.justPressed.RIGHT)
      {
        this.offsetX += FlxG.keys.pressed.ALT ? 0.1 : (FlxG.keys.pressed.SHIFT ? 10.0 : 1.0);
      }

      if (FlxG.keys.justPressed.UP)
      {
        this.offsetY -= FlxG.keys.pressed.ALT ? 0.1 : (FlxG.keys.pressed.SHIFT ? 10.0 : 1.0);
      }

      if (FlxG.keys.justPressed.DOWN)
      {
        this.offsetY += FlxG.keys.pressed.ALT ? 0.1 : (FlxG.keys.pressed.SHIFT ? 10.0 : 1.0);
      }

      if (FlxG.keys.justPressed.C)
      {
        currentState = (currentState == Idle ? Cartoon : Idle);
      }
    }
    #end
  }

  function onFinishAnim(name:String):Void
  {
    // var name = anim.curSymbol.name;

    if (name == playableCharData.getAnimationPrefix('intro'))
    {
      if (PlayerRegistry.instance.hasNewCharacter())
      {
        currentState = NewUnlock;
      }
      else
      {
        currentState = Idle;
      }
      onIntroDone.dispatch();
    }
    else if (name == playableCharData.getAnimationPrefix('idle'))
    {
      // trace('Finished idle');
    }
    else if (name == playableCharData.getAnimationPrefix('confirm'))
    {
      // trace('Finished confirm');
    }
    else if (name == playableCharData.getAnimationPrefix('fistPump'))
    {
      // trace('Finished fist pump');
      currentState = Idle;
    }
    else if (name == playableCharData.getAnimationPrefix('idleEasterEgg'))
    {
      // trace('Finished spook');
      currentState = Idle;
    }
    else if (name == playableCharData.getAnimationPrefix('loss'))
    {
      // trace('Finished loss reaction');
      currentState = Idle;
    }
    else if (name == playableCharData.getAnimationPrefix('cartoon'))
    {
      // trace('Finished cartoon');

      var frame:Int = FlxG.random.bool(33) ? playableCharData.getCartoonLoopBlinkFrame() : playableCharData.getCartoonLoopFrame();

      // Character switches channels when the video ends, or at a 10% chance each time his idle loops.
      if (FlxG.random.bool(5))
      {
        frame = playableCharData.getCartoonChannelChangeFrame();
        // boyfriend switches channel code?
        // runTvLogic();
      }
      trace('Replay idle: ${frame}');
      playFlashAnimation(playableCharData.getAnimationPrefix('cartoon'), true, false, false, frame);
      // trace('Finished confirm');
    }
    else if (name == playableCharData.getAnimationPrefix('newUnlock'))
    {
      // Animation should loop.
    }
    else if (name == playableCharData.getAnimationPrefix('charSelect'))
    {
      onCharSelectComplete();
    }
    else
    {
      trace('Finished ${name}');
    }
  }

  public function resetAFKTimer():Void
  {
    timeIdling = 0;
    seenIdleEasterEgg = false;
  }

  /**
   * Dynamic function, it's actually a variable you can reassign!
   * `dj.onCharSelectComplete = function() {};`
   */
  public dynamic function onCharSelectComplete():Void
  {
    trace('onCharSelectComplete()');
  }

  var offsetX:Float = 0.0;
  var offsetY:Float = 0.0;

  var cartoonSnd:Null<FunkinSound> = null;

  public var playingCartoon:Bool = false;

  public function runTvLogic()
  {
    if (cartoonSnd == null)
    {
      // tv is OFF, but getting turned on
      FunkinSound.playOnce(Paths.sound('tv_on'), 1.0, function() {
        loadCartoon();
      });
    }
    else
    {
      // plays it smidge after the click
      FunkinSound.playOnce(Paths.sound('channel_switch'), 1.0, function() {
        cartoonSnd.destroy();
        loadCartoon();
      });
    }

    // loadCartoon();
  }

  function loadCartoon()
  {
    cartoonSnd = FunkinSound.load(Paths.sound(getRandomFlashToon()), 1.0, false, true, true, function() {
      playFlashAnimation(playableCharData.getAnimationPrefix('cartoon'), true, false, false, 60);
    });

    // Fade out music to 40% volume over 1 second.
    // This helps make the TV a bit more audible.
    FlxG.sound.music.fadeOut(1.0, 0.1);

    // Play the cartoon at a random time between the start and 5 seconds from the end.
    cartoonSnd.time = FlxG.random.float(0, Math.max(cartoonSnd.length - (5 * Constants.MS_PER_SEC), 0.0));
  }

  final cartoonList:Array<String> = openfl.utils.Assets.list().filter(function(path) return path.startsWith("assets/sounds/cartoons/"));

  function getRandomFlashToon():String
  {
    var randomFile = FlxG.random.getObject(cartoonList);

    // Strip folder prefix
    randomFile = randomFile.replace("assets/sounds/", "");
    // Strip file extension
    randomFile = randomFile.substring(0, randomFile.length - 4);

    return randomFile;
  }

  public function confirm():Void
  {
    // We really don't want to play anything but the new character animation here.
    if (PlayerRegistry.instance.hasNewCharacter())
    {
      currentState = NewUnlock;
      return;
    }

    currentState = Confirm;
  }

  public function toCharSelect():Void
  {
    if (hasAnimation(playableCharData.getAnimationPrefix('charSelect')))
    {
      currentState = CharSelect;
      var animPrefix = playableCharData.getAnimationPrefix('charSelect');
      playFlashAnimation(animPrefix, true, false, false, 0);
    }
    else
    {
      FlxG.log.warn("Freeplay character does not have 'charSelect' animation!");
      currentState = Confirm;
      // Call this immediately; otherwise, we get locked out of Character Select.
      onCharSelectComplete();
    }
  }

  public function fistPumpIntro():Void
  {
    // We really don't want to play anything but the new character animation here.
    if (PlayerRegistry.instance.hasNewCharacter())
    {
      currentState = NewUnlock;
      return;
    }

    currentState = FistPumpIntro;
    var animPrefix = playableCharData.getAnimationPrefix('fistPump');
    playFlashAnimation(animPrefix, true, false, false, playableCharData.getFistPumpIntroStartFrame());
  }

  public function fistPump():Void
  {
    // We really don't want to play anything but the new character animation here.
    if (PlayerRegistry.instance.hasNewCharacter())
    {
      currentState = NewUnlock;
      return;
    }

    currentState = FistPump;
    var animPrefix = playableCharData.getAnimationPrefix('fistPump');
    playFlashAnimation(animPrefix, true, false, false, playableCharData.getFistPumpLoopStartFrame());
  }

  public function fistPumpLossIntro():Void
  {
    // We really don't want to play anything but the new character animation here.
    if (PlayerRegistry.instance.hasNewCharacter())
    {
      currentState = NewUnlock;
      return;
    }

    currentState = FistPumpIntro;
    var animPrefix = playableCharData.getAnimationPrefix('loss');
    playFlashAnimation(animPrefix, true, false, false, playableCharData.getFistPumpIntroBadStartFrame());
  }

  public function fistPumpLoss():Void
  {
    // We really don't want to play anything but the new character animation here.
    if (PlayerRegistry.instance.hasNewCharacter())
    {
      currentState = NewUnlock;
      return;
    }

    currentState = FistPump;
    var animPrefix = playableCharData.getAnimationPrefix('loss');
    playFlashAnimation(animPrefix, true, false, false, playableCharData.getFistPumpLoopBadStartFrame());
  }

  override public function getCurrentAnimation():String
  {
    if (this.anim == null || this.anim.curSymbol == null) return "";
    return this.anim.curSymbol.name;
  }

  public function playFlashAnimation(id:String, Force:Bool = false, Reverse:Bool = false, Loop:Bool = false, Frame:Int = 0):Void
  {
    playAnimation(id, Force, Reverse, Loop, Frame);
    applyAnimOffset();
  }

  function applyAnimOffset()
  {
    var AnimName = getCurrentAnimation();
    var daOffset = playableCharData.getAnimationOffsetsByPrefix(AnimName);
    if (daOffset != null)
    {
      var xValue = daOffset[0];
      var yValue = daOffset[1];
      if (AnimName == "Boyfriend DJ watchin tv OG")
      {
        xValue += offsetX;
        yValue += offsetY;
      }

      trace('Successfully applied offset ($AnimName): ' + xValue + ', ' + yValue);
      offset.set(xValue, yValue);
    }
    else
    {
      trace('No offset found ($AnimName), defaulting to: 0, 0');
      offset.set(0, 0);
    }
  }

  public override function destroy():Void
  {
    super.destroy();

    if (cartoonSnd != null)
    {
      cartoonSnd.destroy();
      cartoonSnd = null;
    }
  }
}

enum FreeplayDJState
{
  /**
   * Character enters the frame and transitions to Idle.
   */
  Intro;

  /**
   * Character loops in idle.
   */
  Idle;

  /**
   * Plays an easter egg animation after a period in Idle, then reverts to Idle.
   */
  IdleEasterEgg;

  /**
   * Plays an elaborate easter egg animation. Does not revert until another animation is triggered.
   */
  Cartoon;

  /**
   * Player has selected a song.
   */
  Confirm;

  /**
   * Character preps to play the fist pump animation; plays after the Results screen.
   * The actual frame label that gets played may vary based on the player's success.
   */
  FistPumpIntro;

  /**
   * Character plays the fist pump animation.
   * The actual frame label that gets played may vary based on the player's success.
   */
  FistPump;

  /**
   * Plays an animation to indicate that the player has a new unlock in Character Select.
   * Overrides all idle animations as well as the fist pump. Only Confirm and CharSelect will override this.
   */
  NewUnlock;

  /**
   * Plays an animation to transition to the Character Select screen.
   */
  CharSelect;
}
