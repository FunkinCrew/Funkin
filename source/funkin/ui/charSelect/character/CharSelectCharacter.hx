package funkin.ui.charSelect.character;

import funkin.util.assets.FlxAnimationUtil;
import flixel.graphics.frames.FlxFramesCollection;
import funkin.data.freeplay.player.PlayerData;
import funkin.graphics.FunkinSprite;
import funkin.modding.IScriptedClass.IBPMSyncedScriptedClass;
import funkin.modding.events.ScriptEvent;

/**
 * The class for characters that show in the Character Select Menu.
 * Unlike in-game characters and Freeplay DJs, both the rendering and behavior is done here,
 * since the characters aren't that complex in hindsight.
 */
@:nullSafety
class CharSelectCharacter extends FunkinSprite implements IBPMSyncedScriptedClass
{
  /**
   * The player to attach this character to.
   */
  public var playerId:String = "unknown";

  /**
   * Whether this character is a specator character such as Gf or Nene.
   */
  public var isGf:Bool = false;

  final _data:PlayerCharSelectCharacterData;

  var animationOffsets:Map<String, Array<Float>> = [];
  var danceEvery:Int = 2;

  public function new(x:Float, y:Float, playerId:String = "unknown", isGf:Bool = false, data:PlayerCharSelectCharacterData)
  {
    super(x, y);

    this.playerId = playerId;
    this.isGf = isGf;

    _data = data;

    loadCharacterFrames();
    loadCharacterAnimations();

    this.animation.onFinish.add(onAnimationFinished);

    playAnimation("idle", true);
  }

  public function playAnimation(animName:String, force:Bool = false, reversed:Bool = false, index:Int = 0)
  {
    this.animation.play(animName, force, reversed, index);

    // Apply the offsets if possible.
    if (animationOffsets.get(animName) != null && animationOffsets.get(animName)?.length == 2)
    {
      var animOffsets:Array<Float> = animationOffsets.get(animName) ?? [0, 0];
      this.offset.set(animOffsets[0], animOffsets[1]);
    }
    else
    {
      this.offset.set();
    }
  }

  function onAnimationFinished(name:String)
  {
    // Play the hold animation if it exists.
    if (hasAnimation(name + Constants.ANIMATION_HOLD_SUFFIX) && !name.endsWith(Constants.ANIMATION_HOLD_SUFFIX))
    {
      playAnimation(name + Constants.ANIMATION_HOLD_SUFFIX, true);
      return;
    }

    switch (name)
    {
      case "slideIn", "slideIn-hold", "locked", "unlock":
        playAnimation("idle", true);

      case "slideOut", "slideOut-hold", "slideOut-unlock":
        this.kill();
    }
  }

  public function onStepHit(event:SongTimeScriptEvent):Void {}

  public function onBeatHit(event:SongTimeScriptEvent):Void
  {
    // Play the idle animation every 2nd beat.
    if (getCurrentAnimation() == "idle" && (event.beat % danceEvery == 0) && isAnimationFinished())
    {
      playAnimation("idle", true);
    }
  }

  public function onScriptEvent(event:ScriptEvent):Void {}

  public function onCreate(event:ScriptEvent):Void {}

  public function onDestroy(event:ScriptEvent):Void {}

  public function onUpdate(event:UpdateScriptEvent):Void {}

  function loadCharacterFrames()
  {
    if (_data.assetPath == null)
    {
      throw "Couldn't generate the character since no asset path was provided.";
      return;
    }

    var allAssetPaths:Array<String> = [_data.assetPath];

    // Using animations, fetch all the asset paths to be used for this.
    for (anim in (_data.animations ?? []))
    {
      if (anim.assetPath != null && !allAssetPaths.contains(anim.assetPath))
      {
        allAssetPaths.push(anim.assetPath);
      }
    }

    switch (_data?.renderType ?? "animateatlas")
    {
      case "animateatlas":
        var assetLibrary:String = Paths.getLibrary(allAssetPaths[0]);
        var assetPath:String = Paths.stripLibrary(allAssetPaths[0]);

        this.loadTextureAtlas(assetPath, assetLibrary, {swfMode: true, applyStageMatrix: true});

      case "sparrow":
        this.loadSparrow(allAssetPaths[0]);

      case "packer":
        this.loadPacker(allAssetPaths[0]);

      case "multisparrow":
        // For the multisparrow render type, we create a new frame collection instance and add all the frames from the asset path array.
        // This makes the base asset path's frame collection not receive any unnecessary frames from the other frame collections.
        @:nullSafety(Off)
        var framesCollection:FlxFramesCollection = new FlxFramesCollection(null, ATLAS, null);

        for (assetPath in allAssetPaths)
        {
          var assetFrames:FlxFramesCollection = Paths.getSparrowAtlas(assetPath);
          for (frame in assetFrames.frames)
            framesCollection.pushFrame(frame.copyTo());
        }
    }
  }

  function loadCharacterAnimations()
  {
    if (_data.animations == null || (_data.animations?.length ?? 0) == 0) return;

    if (this.isAnimate)
    {
      FlxAnimationUtil.addTextureAtlasAnimations(this, _data.animations);
    }
    else
    {
      FlxAnimationUtil.addAtlasAnimations(this, _data.animations);
    }

    for (anim in _data.animations)
    {
      animationOffsets.set(anim.name, anim.offsets ?? [0, 0]);
    }
  }
}
