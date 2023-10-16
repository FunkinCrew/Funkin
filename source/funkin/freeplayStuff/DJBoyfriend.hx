package funkin.freeplayStuff;

import flixel.FlxSprite;
import flixel.util.FlxSignal;
import funkin.util.assets.FlxAnimationUtil;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import flixel.system.FlxSound;
import flixel.util.FlxTimer;
import funkin.audio.FlxStreamSound;

class DJBoyfriend extends FlxAtlasSprite
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

  var gotSpooked:Bool = false;

  static final SPOOK_PERIOD:Float = 120.0;
  static final TV_PERIOD:Float = 180.0;

  // Time since dad last SPOOKED you.
  var timeSinceSpook:Float = 0;

  public function new(x:Float, y:Float)
  {
    super(x, y, Paths.animateAtlas("freeplay/freeplay-boyfriend", "preload"));

    animOffsets = new Map<String, Array<Dynamic>>();

    anim.callback = function(name, number) {
      switch (name)
      {
        case "Boyfriend DJ watchin tv OG":
          if (number == 85) runTvLogic();
        default:
      }
    };

    setupAnimations();
    trace(listAnimations());

    FlxG.debugger.track(this);
    FlxG.console.registerObject("dj", this);

    anim.onComplete = onFinishAnim;

    FlxG.console.registerFunction("tv", function() {
      currentState = TV;
    });
  }

  /*
    [remote hand under,boyfriend top head,brim piece,arm cringe l,red lazer,dj arm in,bf fist pump arm,hand raised right,forearm left,fist shaking,bf smile eyes closed face,arm cringe r,bf clenched face,face shrug,boyfriend falling,blue tint 1,shirt sleeve,bf clenched fist,head BF relaxed,blue tint 2,hand down left,blue tint 3,blue tint 4,head less smooshed,blue tint 5,boyfriend freeplay,BF head slight turn,blue tint 6,arm shrug l,blue tint 7,shoulder raised w sleeve,blue tint 8,fist pump face,blue tint 9,foot rested light,hand turnaround,arm chill right,Boyfriend DJ,arm shrug r,head back bf,hat top piece,dad bod,face surprise snap,Boyfriend DJ fist pump,office chair,foot rested right,chest down,office chair upright,body chill,bf dj afk,head mouth open dad,BF Head defalt HAIR BLOWING,hand shrug l,face piece,foot wag,turn table,shoulder up left,turntable lights,boyfriend dj body shirt blowing,body chunk turned,hand down right,dj arm out,hand shrug r,body chest out,rave hand,palm,chill face default,head back semi bf,boyfriend bottom head,DJ arm,shoulder right dad,bf surprise,boyfriend dj body,hs1,Boyfriend DJ watchin tv OG,spinning disk,hs2,arm chill left,boyfriend dj intro,hs3,hs4,chill face extra,hs5,remote hand upright,hs6,pant over table,face surprise,bf arm peace,arm turnaround,bf eyes 1,arm slammed table,eye squit,leg BF,head mid piece,arm backing,arm swoopin in,shoe right lowering,forearm right,hand out,blue tint 10,body falling back,remote thumb press,shoulder,hair spike single,bf bent
    arm,crt,foot raised right,dad hand,chill face 1,chill face 2,clenched fist,head SMOOSHED,shoulder left dad,df1,body chunk upright,df2,df3,df4,hat front piece,df5,foot rested right 2,hand in,arm spun,shoe raised left,bf 1 finger hand,bf mouth 1,Boyfriend DJ confirm,forearm down ,hand raised left,remote thumb up]
   */
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

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    switch (currentState)
    {
      case Intro:
        // Play the intro animation then leave this state immediately.
        if (getCurrentAnimation() != 'boyfriend dj intro') playFlashAnimation('boyfriend dj intro', true);
        timeSinceSpook = 0;
      case Idle:
        // We are in this state the majority of the time.
        if (getCurrentAnimation() != 'Boyfriend DJ' || anim.finished)
        {
          if (timeSinceSpook > SPOOK_PERIOD && !gotSpooked)
          {
            currentState = Spook;
          }
          else if (timeSinceSpook > TV_PERIOD)
          {
            currentState = TV;
          }
          else
          {
            playFlashAnimation('Boyfriend DJ', false);
          }
        }
        timeSinceSpook += elapsed;
      case Confirm:
        if (getCurrentAnimation() != 'Boyfriend DJ confirm') playFlashAnimation('Boyfriend DJ confirm', false);
        timeSinceSpook = 0;
      case Spook:
        if (getCurrentAnimation() != 'bf dj afk')
        {
          onSpook.dispatch();
          playFlashAnimation('bf dj afk', false);
        }
        timeSinceSpook = 0;
      case TV:
        if (getCurrentAnimation() != 'Boyfriend DJ watchin tv OG') playFlashAnimation('Boyfriend DJ watchin tv OG', true);
        timeSinceSpook = 0;
      default:
        // I shit myself.
    }
  }

  function onFinishAnim():Void
  {
    var name = anim.curSymbol.name;
    switch (name)
    {
      case "boyfriend dj intro":
        // trace('Finished intro');
        currentState = Idle;
        onIntroDone.dispatch();
      case "Boyfriend DJ":
      // trace('Finished idle');
      case "bf dj afk":
        // trace('Finished spook');
        currentState = Idle;
      case "Boyfriend DJ confirm":

      case "Boyfriend DJ watchin tv OG":
        var frame:Int = FlxG.random.bool(33) ? 112 : 166;
        if (FlxG.random.bool(10))
        {
          frame = 60;
          // boyfriend switches channel code?
        }
        anim.play("Boyfriend DJ watchin tv OG", true, false, frame);
        // trace('Finished confirm');
    }
  }

  public function resetAFKTimer():Void
  {
    timeSinceSpook = 0;
  }

  function setupAnimations():Void
  {
    // frames = FlxAnimationUtil.combineFramesCollections(Paths.getSparrowAtlas('freeplay/bfFreeplay'), Paths.getSparrowAtlas('freeplay/bf-freeplay-afk'));

    // animation.addByPrefix('intro', "boyfriend dj intro", 24, false);
    addOffset('boyfriend dj intro', 8, 3);

    // animation.addByPrefix('idle', "Boyfriend DJ0", 24, false);
    addOffset('Boyfriend DJ', 0, 0);

    // animation.addByPrefix('confirm', "Boyfriend DJ confirm", 24, false);
    addOffset('Boyfriend DJ confirm', 0, 0);

    // animation.addByPrefix('spook', "bf dj afk0", 24, false);
    addOffset('bf dj afk', 0, 0);
  }

  var cartoonSnd:FlxStreamSound;

  public var playingCartoon:Bool = false;

  public function runTvLogic()
  {
    if (cartoonSnd == null)
    {
      // tv is OFF, but getting turned on
      FlxG.sound.play(Paths.sound('tv_on'));

      cartoonSnd = new FlxStreamSound();
      FlxG.sound.defaultSoundGroup.add(cartoonSnd);
    }
    else
    {
      // plays it smidge after the click
      new FlxTimer().start(0.1, function(_) {
        FlxG.sound.play(Paths.sound('channel_switch'));
      });
    }
    // cartoonSnd.loadEmbedded(Paths.sound("cartoons/peck"));
    // cartoonSnd.play();

    loadCartoon();
  }

  function loadCartoon()
  {
    cartoonSnd.loadEmbedded(Paths.sound(getRandomFlashToon()), false, false, function() {
      anim.play("Boyfriend DJ watchin tv OG", true, false, 60);
    });
    cartoonSnd.play(true, FlxG.random.float(0, cartoonSnd.length));
  }

  var cartoonList:Array<String> = openfl.utils.Assets.list().filter(function(path) return path.startsWith("assets/sounds/cartoons/"));

  function getRandomFlashToon():String
  {
    var randomFile = FlxG.random.getObject(cartoonList);

    randomFile = randomFile.replace("assets/sounds/", "");
    randomFile = randomFile.substring(0, randomFile.length - 4);

    return randomFile;
  }

  public function confirm():Void
  {
    currentState = Confirm;
  }

  public inline function addOffset(name:String, x:Float = 0, y:Float = 0)
  {
    animOffsets[name] = [x, y];
  }

  override public function getCurrentAnimation():String
  {
    if (this.anim == null || this.anim.curSymbol == null) return "";
    return this.anim.curSymbol.name;
  }

  public function playFlashAnimation(id:String, ?Force:Bool = false, ?Reverse:Bool = false, ?Frame:Int = 0):Void
  {
    anim.play(id, Force, Reverse, Frame);
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
  TV;
}
