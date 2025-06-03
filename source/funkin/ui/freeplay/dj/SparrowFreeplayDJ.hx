package funkin.ui.freeplay.dj;

import flixel.util.FlxSignal;
import funkin.audio.FunkinSound;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.data.freeplay.player.PlayerData.PlayerFreeplayDJData;
import funkin.modding.events.ScriptEvent;
import funkin.util.assets.FlxAnimationUtil;
import funkin.graphics.FunkinSprite;
import flixel.graphics.frames.FlxFramesCollection;

class SparrowFreeplayDJ extends BaseFreeplayDJ
{
  // BaseFreeplayDJ extends FlxAtlasSprite but we can't make it also extend FunkinSprite UGH
  // I basically copied the code from FlxSpriteGroup to make the FunkinSprite a "child" of this class
  var mainSprite:FunkinSprite;

  public function new(x:Float, y:Float, characterId:String)
  {
    super(x, y, characterId);

    // TODO: Move this shit to BF's logic
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

    FlxG.console.registerFunction("freeplayCartoon", function() {
      currentState = Cartoon;
    });

    FlxG.debugger.track(this);
    FlxG.console.registerObject("dj", this);

    onAnimationComplete.add(onFinishAnim);
    onAnimationLoop.add(onFinishAnim);
  }

  override function onCreate(event:ScriptEvent):Void
  {
    // Display a custom scope for debugging purposes.
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('SPARROWDJacter.create(${this.characterId})');
    #end

    var sparrowSprite:FunkinSprite = loadSparrowSprite();
    setSprite(sparrowSprite);

    loadAnimations();

    super.onCreate(event);
  }

  function setSprite(sprite:FunkinSprite):Void
  {
    trace('[SPARROWDJ] Applying sprite properties to ${characterId}');

    this.mainSprite = sprite;

    mainSprite.updateHitbox();

    sprite.x = this.x;
    sprite.y = this.y;
    sprite.alpha *= alpha;
    sprite.flipX = flipX;
    sprite.flipY = flipY;
    sprite.scrollFactor.copyFrom(scrollFactor);
    sprite.cameras = _cameras;
  }

  function loadSparrowSprite():FunkinSprite
  {
    trace('[SPRARROWDJ] Loading sprite sparrow for ${characterId}.');

    var sprite:FlxAtlasSprite = FunkinSprite.createSparrow(0, 0, _data.assetPath);

    return sprite;
  }

  function loadAnimations()
  {
    trace('[SPARROWCHAR] Loading ${playableCharData.animations.length} animations for ${characterId}');

    FlxAnimationUtil.addAtlasAnimations(this, playableCharData.animations);

    for (anim in playableCharData.animations)
    {
      if (anim.offsets == null)
      {
        setAnimationOffsets(anim.name, 0, 0);
      }
      else
      {
        setAnimationOffsets(anim.name, anim.offsets[0], anim.offsets[1]);
      }
    }

    var animNames = this.animation.getNameList();
    trace('[SPARROWCHAR] Successfully loaded ${animNames.length} animations for ${characterId}');
  }

  override public function listAnimations():Array<String>
  {
    return mainSprite.animation.getNameList();
  }

  public function playFlashAnimation(id:String, Force:Bool = false, Reverse:Bool = false, Loop:Bool = false, Frame:Int = 0):Void
  {
    mainSprite.animation.play(id, Force, Reverse, Frame);
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

      trace('Successfully applied offset ($AnimName): ' + xValue + ', ' + yValue);
      mainSprite.offset.set(xValue, yValue);
    }
    else
    {
      trace('No offset found ($AnimName), defaulting to: 0, 0');
      mainSprite.offset.set(0, 0);
    }
  }
}
