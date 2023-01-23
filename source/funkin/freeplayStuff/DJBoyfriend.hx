package funkin.freeplayStuff;

import flixel.FlxSprite;
import flixel.util.FlxSignal;
import funkin.util.assets.FlxAnimationUtil;

class DJBoyfriend extends FlxSprite
{
  // Represents the sprite's current status.
  // Without state machines I would have driven myself crazy years ago.
  public var currentState:DJBoyfriendState = Intro;

  // A callback activated when the intro animation finishes.
  public var onIntroDone:FlxSignal = new FlxSignal();

  // A callback activated when Boyfriend gets spooked.
  public var onSpook:FlxSignal = new FlxSignal();

  // playAnim stolen from Character.hx, cuz im lazy lol!
  // TODO: Switch this class to use SwagSprite instead.
  public var animOffsets:Map<String, Array<Dynamic>>;

  static final SPOOK_PERIOD:Float = 180.0;

  // Time since dad last SPOOKED you.
  var timeSinceSpook:Float = 0;

  public function new(x:Float, y:Float)
  {
    super(x, y);

    animOffsets = new Map<String, Array<Dynamic>>();

    setupAnimations();

    animation.finishCallback = onFinishAnim;
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.LEFT)
    {
      animOffsets["confirm"] = [animOffsets["confirm"][0] + 1, animOffsets["confirm"][1]];
      applyAnimOffset();
    }
    else if (FlxG.keys.justPressed.RIGHT)
    {
      animOffsets["confirm"] = [animOffsets["confirm"][0] - 1, animOffsets["confirm"][1]];
      applyAnimOffset();
    }
    else if (FlxG.keys.justPressed.UP)
    {
      animOffsets["confirm"] = [animOffsets["confirm"][0], animOffsets["confirm"][1] + 1];
      applyAnimOffset();
    }
    else if (FlxG.keys.justPressed.DOWN)
    {
      animOffsets["confirm"] = [animOffsets["confirm"][0], animOffsets["confirm"][1] - 1];
      applyAnimOffset();
    }

    switch (currentState)
    {
      case Intro:
        // Play the intro animation then leave this state immediately.
        if (getCurrentAnimation() != 'intro')
          playAnimation('intro', true);
        timeSinceSpook = 0;
      case Idle:
        // We are in this state the majority of the time.
        if (getCurrentAnimation() != 'idle' || animation.finished)
        {
          if (timeSinceSpook > SPOOK_PERIOD)
          {
            currentState = Spook;
          }
          else
          {
            playAnimation('idle', false);
          }
        }
        timeSinceSpook += elapsed;
      case Confirm:
        if (getCurrentAnimation() != 'confirm')
          playAnimation('confirm', false);
        timeSinceSpook = 0;
      case Spook:
        if (getCurrentAnimation() != 'spook')
        {
          onSpook.dispatch();
          playAnimation('spook', false);
        }
        timeSinceSpook = 0;
      default:
        // I shit myself.
    }
  }

  function onFinishAnim(name:String):Void
  {
    switch (name)
    {
      case "intro":
        // trace('Finished intro');
        currentState = Idle;
        onIntroDone.dispatch();
      case "idle":
      // trace('Finished idle');
      case "spook":
        // trace('Finished spook');
        currentState = Idle;
      case "confirm":
        // trace('Finished confirm');
    }
  }

  public function resetAFKTimer():Void
  {
    timeSinceSpook = 0;
  }

  function setupAnimations():Void
  {
    frames = FlxAnimationUtil.combineFramesCollections(Paths.getSparrowAtlas('freeplay/bfFreeplay'), Paths.getSparrowAtlas('freeplay/bf-freeplay-afk'));

    animation.addByPrefix('intro', "boyfriend dj intro", 24, false);
    addOffset('intro', 0, 0);

    animation.addByPrefix('idle', "Boyfriend DJ0", 24, false);
    addOffset('idle', -4, -426);

    animation.addByPrefix('confirm', "Boyfriend DJ confirm", 24, false);
    addOffset('confirm', 40, -451);

    animation.addByPrefix('spook', "bf dj afk0", 24, false);
    addOffset('spook', -3, -272);
  }

  public function confirm():Void
  {
    currentState = Confirm;
  }

  public inline function addOffset(name:String, x:Float = 0, y:Float = 0)
  {
    animOffsets[name] = [x, y];
  }

  public function getCurrentAnimation():String
  {
    if (this.animation == null || this.animation.curAnim == null)
      return "";
    return this.animation.curAnim.name;
  }

  public function playAnimation(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
  {
    animation.play(AnimName, Force, Reversed, Frame);
    applyAnimOffset();
  }

  function applyAnimOffset()
  {
    var AnimName = getCurrentAnimation();
    var daOffset = animOffsets.get(AnimName);
    if (animOffsets.exists(AnimName))
    {
      offset.set(daOffset[0], daOffset[1]);
    }
    else
      offset.set(0, 0);
  }
}

enum DJBoyfriendState
{
  Intro;
  Idle;
  Confirm;
  Spook;
}
