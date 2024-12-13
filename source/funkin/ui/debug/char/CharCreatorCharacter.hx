package funkin.ui.debug.char;

import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.BitmapData;
import funkin.data.animation.AnimationData;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.data.character.CharacterData;
import funkin.data.character.CharacterData.CharacterRenderType;
import funkin.data.character.CharacterRegistry;
import funkin.ui.debug.char.animate.CharSelectAtlasSprite;
import funkin.play.stage.Bopper;
import flixel.math.FlxPoint;
import flixel.math.FlxPoint.FlxCallbackPoint; // honestly these are kind of awesome
import flixel.FlxSprite;
import haxe.io.Bytes;
import haxe.io.Path;

// literally just basecharacter but less functionality
// like the removal of note event functions
// also easy way to store in files used for generation!
// also ALSO these have ALL the character types integrated, LOL
class CharCreatorCharacter extends Bopper
{
  public var generatedParams:WizardGenerateParams;
  public var characterId(get, never):String;
  public var renderType(get, never):CharacterRenderType;
  public var files(get, never):Array<WizardFile>;

  public var characterName:String = "Unknown";
  public var characterType:CharacterType = BF;

  public var holdTimer:Float = 0;
  public var characterCameraOffsets:Array<Float> = [0.0, 0.0];
  public var animations:Array<AnimationData> = [];
  public var deathData:DeathData = null;

  public var characterFlipX:Bool = false;
  public var characterScale:Float = 1.0; // character scale to be used in the data, ghosts need one

  public var healthIcon:HealthIconData = null;
  public var healthIconFiles:Array<WizardFile> = [];

  public var characterOrigin(get, never):FlxPoint;
  public var feetPosition(get, never):FlxPoint;
  public var totalScale(default, set):Float; // total character scale, included with the stage scale

  public var atlasCharacter:CharSelectAtlasSprite = null;
  public var currentAtlasAnimation:Null<String> = null;

  public var ignoreLoop:Bool = false;

  override public function new(wizardParams:WizardGenerateParams)
  {
    super(CharacterRegistry.DEFAULT_DANCEEVERY);
    ignoreExclusionPref = ["sing"];
    shouldBop = false;

    generatedParams = wizardParams;

    switch (generatedParams?.renderType)
    {
      case CharacterRenderType.Sparrow | CharacterRenderType.MultiSparrow:
        if (generatedParams.files.length < 2) return; // img and data

        var combinedFrames = null;
        for (i in 0...Math.floor(generatedParams.files.length / 2))
        {
          var img = BitmapData.fromBytes(generatedParams.files[i * 2].bytes);
          var data = generatedParams.files[i * 2 + 1].bytes.toString();
          var sparrow = FlxAtlasFrames.fromSparrow(img, data);
          if (combinedFrames == null) combinedFrames = sparrow;
          else
            combinedFrames.addAtlas(sparrow);
        }
        this.frames = combinedFrames;

      case CharacterRenderType.Packer:
        if (generatedParams.files.length != 2) return; // img and data

        var img = BitmapData.fromBytes(generatedParams.files[0].bytes);
        var data = generatedParams.files[1].bytes.toString();
        this.frames = FlxAtlasFrames.fromSpriteSheetPacker(img, data);

      case CharacterRenderType.AnimateAtlas:
        if (generatedParams.files.length != 1) return; // zip file with all the data
        atlasCharacter = new CharSelectAtlasSprite(0, 0, generatedParams.files[0].bytes);

        atlasCharacter.alpha = 0.0001;
        atlasCharacter.draw();
        atlasCharacter.alpha = 1.0;

        atlasCharacter.x = this.x;
        atlasCharacter.y = this.y;
        atlasCharacter.alpha *= alpha;
        atlasCharacter.flipX = flipX;
        atlasCharacter.flipY = flipY;
        atlasCharacter.scrollFactor.copyFrom(scrollFactor);
        atlasCharacter.cameras = _cameras; // _cameras instead of cameras because get_cameras() will not return null

      default: // nothing, what the fuck are you even doing
    }
  }

  override public function update(elapsed:Float)
  {
    super.update(elapsed);

    if (atlasCharacter != null) // easier than transform LOL
    {
      if (ignoreLoop) atlasCharacter.looping = false;

      atlasCharacter.x = this.x;
      atlasCharacter.y = this.y;
      atlasCharacter.alpha = this.alpha;
      atlasCharacter.flipX = this.flipX;
      atlasCharacter.flipY = this.flipY;
      atlasCharacter.moves = this.moves;
      atlasCharacter.color = this.color;
      atlasCharacter.blend = this.blend;
      atlasCharacter.immovable = this.immovable;
      atlasCharacter.visible = this.visible;
      atlasCharacter.active = this.active;
      atlasCharacter.solid = this.solid; // cwc reference
      atlasCharacter.alive = this.alive;
      atlasCharacter.exists = this.exists;
      atlasCharacter.camera = this.camera;
      atlasCharacter.cameras = this.cameras;
      atlasCharacter.offset.set(animOffsets[0], animOffsets[1]);
      atlasCharacter.origin.copyFrom(this.origin);
      atlasCharacter.scale.copyFrom(this.scale);
      atlasCharacter.scrollFactor.copyFrom(this.scrollFactor);
      atlasCharacter.antialiasing = this.antialiasing;
      atlasCharacter.pixelPerfectRender = this.pixelPerfectRender;
      atlasCharacter.pixelPerfectPosition = this.pixelPerfectPosition;
      atlasCharacter.update(elapsed);
    }
  }

  override public function draw():Void
  {
    if (atlasCharacter != null) atlasCharacter.draw();
    else
      super.draw();
  }

  public function addAnimation(name:String, prefix:String, offsets:Array<Float>, indices:Array<Int>, frameRate:Int = 24, looped:Bool = false,
      flipX:Bool = false, flipY:Bool = false)
  {
    if (renderType != CharacterRenderType.AnimateAtlas)
    {
      if (indices.length > 0) animation.addByIndices(name, prefix, indices, "", frameRate, looped, flipX, flipY);
      else
        animation.addByPrefix(name, prefix, frameRate, looped, flipX, flipY);

      if (!animation.getNameList().contains(name)) return false;
    }
    else
    {
      if (!atlasCharacter.hasAnimation(prefix)) return false;
    }

    if (getAnimationData(name) != null) removeAnimation(name);

    animations.push(
      {
        name: name,
        prefix: prefix,
        frameIndices: indices,
        frameRate: frameRate,
        flipX: flipX,
        flipY: flipY,
        looped: looped,
        offsets: offsets
      });

    super.setAnimationOffsets(name, offsets[0], offsets[1]);

    return true;
  }

  public function removeAnimation(name:String):Bool
  {
    if (getAnimationData(name) == null) return false;

    for (animation in animations)
    {
      if (animation.name == name)
      {
        animations.remove(animation);
        return true;
      }
    }

    return false;
  }

  override public function setAnimationOffsets(name:String, xOffset:Float, yOffset:Float)
  {
    super.setAnimationOffsets(name, xOffset, yOffset);

    for (anim in animations)
    {
      if (anim.name == name)
      {
        anim.offsets = [xOffset, yOffset];
        break;
      }
    }
  }

  public override function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reverse:Bool = false):Void
  {
    if (!active) active = true;

    if ((!canPlayOtherAnims && !ignoreOther)) return;

    var correctName = correctAnimationName(name);
    if (correctName == null)
    {
      trace('Could not find Character animation: ' + name);
      return;
    }

    var animData = getAnimationData(correctName);
    var loop:Bool = ignoreLoop ? false : animData.looped;

    if (atlasCharacter == null)
    {
      super.playAnimation(name, restart, ignoreOther, reverse);
      animation.curAnim.looped = loop;
      return;
    }

    currentAtlasAnimation = correctName;
    var prefix:String = animData.prefix;
    if (prefix == null) prefix = correctName;

    atlasCharacter.playAnimation(prefix, restart, ignoreOther, loop);
    applyAnimationOffsets(correctName);
  }

  public override function hasAnimation(name:String):Bool
  {
    return atlasCharacter == null ? super.hasAnimation(name) : getAnimationData(name) != null;
  }

  public override function isAnimationFinished():Bool
  {
    return atlasCharacter == null ? super.isAnimationFinished() : atlasCharacter.isAnimationFinished();
  }

  override function onAnimationFinished(prefix:String):Void
  {
    super.onAnimationFinished(prefix);
    if (atlasCharacter == null) return;

    if (getAnimationData() != null && getAnimationData().looped)
    {
      playAnimation(currentAtlasAnimation, true, false);
    }
    else
    {
      atlasCharacter.cleanupAnimation(prefix);
    }
  }

  public override function getCurrentAnimation():Null<String>
  {
    return atlasCharacter == null ? super.getCurrentAnimation() : currentAtlasAnimation;
  }

  public function getAnimationData(name:String = null)
  {
    if (name == null) name = getCurrentAnimation();

    for (anim in animations)
    {
      if (anim.name == name) return anim;
    }

    return null;
  }

  /**
   * Returns the `CharacterData` in bytes
   * @return String
   */
  public function toJSON():String
  {
    var writer = new json2object.JsonWriter<CharacterData>(true);
    return writer.write(toCharacterData(), "  ");
  }

  /**
   * Returns the information as `CharacterData`
   * @return CharacterData
   */
  public function toCharacterData():CharacterData
  {
    return {
      version: CharacterRegistry.CHARACTER_DATA_VERSION,
      name: characterName,
      assetPaths: generatedParams.files.filter((file) -> return file.name.endsWith(".png") || file.name.endsWith(".zip")).map((file) -> {
        var path = Path.withoutExtension(Path.normalize(file.name));
        if (!CharCreatorUtil.isPathProvided(path, "images/characters"))
        {
          return 'characters/${Path.withoutDirectory(path)}';
        }
        return path.substr(path.lastIndexOf("images") + 7);
      }),
      flipX: characterFlipX,
      renderType: generatedParams.renderType,
      healthIcon: healthIcon,
      animations: animations,
      offsets: globalOffsets,
      isPixel: isPixel,
      cameraOffsets: characterCameraOffsets,
      singTime: holdTimer,
      death: deathData
    };
  }

  // getters and setters
  // git gut

  function get_characterId()
  {
    return generatedParams.characterID;
  }

  function get_renderType()
  {
    return generatedParams.renderType;
  }

  function get_files()
  {
    return generatedParams.files;
  }

  function get_characterOrigin():FlxPoint
  {
    var xPos = (width / 2); // Horizontal center
    var yPos = (height); // Vertical bottom
    return new FlxPoint(xPos, yPos);
  }

  function get_feetPosition():FlxPoint
  {
    return new FlxPoint(x + characterOrigin.x, y + characterOrigin.y);
  }

  function set_totalScale(value:Float)
  {
    if (totalScale == value) return totalScale;
    totalScale = value;

    var feetPos:FlxPoint = feetPosition;
    this.scale.x = totalScale;
    this.scale.y = totalScale;
    this.updateHitbox();
    // Reposition with newly scaled sprite.
    this.x = feetPos.x - characterOrigin.x + globalOffsets[0];
    this.y = feetPos.y - characterOrigin.y + globalOffsets[1];

    return totalScale;
  }

  override function set_isPixel(value:Bool)
  {
    pixelPerfectPosition = value;
    pixelPerfectRender = value;
    antialiasing = !value;
    return super.set_isPixel(value);
  }

  override function get_height():Float
  {
    if (atlasCharacter == null) return super.get_height();
    return atlasCharacter.height;
  }

  override function get_width():Float
  {
    if (atlasCharacter == null) return super.get_width();
    return atlasCharacter.width;
  }
}
