package funkin.ui.debug.char.util;

import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.BitmapData;
import funkin.ui.debug.char.animate.CharSelectAtlasSprite;
import funkin.data.character.CharacterData;

@:access(funkin.ui.debug.char.CharCreatorCharacter)
class CharacterUtil
{
  public static function fromCharacter(char:CharCreatorCharacter, other:CharCreatorCharacter):Void
  {
    char.generatedParams = other.generatedParams;
    char.animations = [];
    char.atlasCharacter = null;
    char.loadGraphic(null); // should remove all the frames and animations i think

    switch (other.renderType)
    {
      case CharacterRenderType.Sparrow | CharacterRenderType.MultiSparrow:
        if (char.generatedParams.files.length < 2) return; // img and data

        var combinedFrames = null;
        for (i in 0...Math.floor(char.generatedParams.files.length / 2))
        {
          var img = BitmapData.fromBytes(char.generatedParams.files[i * 2].bytes);
          var data = char.generatedParams.files[i * 2 + 1].bytes.toString();
          var sparrow = FlxAtlasFrames.fromSparrow(img, data);
          if (combinedFrames == null) combinedFrames = sparrow;
          else
            combinedFrames.addAtlas(sparrow);
        }
        char.frames = combinedFrames;

      case CharacterRenderType.Packer:
        if (char.generatedParams.files.length != 2) return; // img and data

        var img = BitmapData.fromBytes(char.generatedParams.files[0].bytes);
        var data = char.generatedParams.files[1].bytes.toString();
        char.frames = FlxAtlasFrames.fromSpriteSheetPacker(img, data);

      case CharacterRenderType.AnimateAtlas: // todo
        if (char.generatedParams.files.length != 1) return; // zip file with all the data
        char.atlasCharacter = new CharSelectAtlasSprite(0, 0, char.generatedParams.files[0].bytes);

        char.atlasCharacter.alpha = 0.0001;
        char.atlasCharacter.draw();
        char.atlasCharacter.alpha = 1.0;

        char.atlasCharacter.x = char.x;
        char.atlasCharacter.y = char.y;
        char.atlasCharacter.alpha *= char.alpha;
        char.atlasCharacter.flipX = char.flipX;
        char.atlasCharacter.flipY = char.flipY;
        char.atlasCharacter.scrollFactor.copyFrom(char.scrollFactor);
        char.atlasCharacter.cameras = char._cameras; // _cameras instead of cameras because get_cameras() will not return null

      default: // nothing, what the fuck are you even doing
    }

    char.characterCameraOffsets = other.characterCameraOffsets.copy();
    char.globalOffsets = other.globalOffsets.copy();
    char.characterFlipX = other.characterFlipX;
    char.characterScale = other.characterScale;
    char.deathData = other.deathData;
    char.healthIcon = other.healthIcon;
    char.characterName = other.characterName;

    for (anim in other.animations)
    {
      char.addAnimation(anim.name, anim.prefix, anim.offsets, anim.frameIndices, anim.frameRate, anim.looped, anim.flipX, anim.flipY);
    }
  }

  public static function fromCharacterData(char:CharCreatorCharacter, data:CharacterData):Void
  {
    // char.generatedParams = other.generatedParams;
    char.animations = [];
    char.atlasCharacter = null;
    char.loadGraphic(null); // should remove all the frames and animations i think

    switch (data.renderType)
    {
      case CharacterRenderType.Sparrow | CharacterRenderType.MultiSparrow:
        var combinedFrames = null;
        for (i => assetPath in data.assetPaths)
        {
          if (combinedFrames == null) combinedFrames = Paths.getSparrowAtlas(assetPath);
          else
            combinedFrames.addAtlas(Paths.getSparrowAtlas(assetPath));
        }
        char.frames = combinedFrames;

      case CharacterRenderType.Packer:
        char.frames = Paths.getPackerAtlas(data.assetPaths[0]);

      case CharacterRenderType.AnimateAtlas:
        var animLibrary:String = Paths.getLibrary(data.assetPaths[0]);
        var animPath:String = Paths.stripLibrary(data.assetPaths[0]);
        var assetPath:String = Paths.animateAtlas(animPath, animLibrary);

        char.atlasCharacter = new CharSelectAtlasSprite(0, 0, assetPath);
        char.atlasCharacter.alpha = 0.0001;
        char.atlasCharacter.draw();
        char.atlasCharacter.alpha = 1.0;

        char.atlasCharacter.x = char.x;
        char.atlasCharacter.y = char.y;
        char.atlasCharacter.alpha *= char.alpha;
        char.atlasCharacter.flipX = char.flipX;
        char.atlasCharacter.flipY = char.flipY;
        char.atlasCharacter.scrollFactor.copyFrom(char.scrollFactor);
        char.atlasCharacter.cameras = char._cameras; // _cameras instead of cameras because get_cameras() will not return null

      default: // nuthin
    }

    char.characterCameraOffsets = data.cameraOffsets ?? [0, 0];
    char.globalOffsets = data.offsets ?? [0, 0];
    char.characterFlipX = data.flipX ?? false;
    char.characterScale = data.scale ?? 1;
    char.deathData = data.death;
    char.holdTimer = data.singTime;
    char.healthIcon = data.healthIcon;
    char.characterName = data.name;

    for (anim in data.animations)
    {
      char.addAnimation(anim.name, anim.prefix, anim.offsets, anim.frameIndices ?? [], anim.frameRate ?? 24, anim.looped ?? false, anim.flipX ?? false,
        anim.flipY ?? false);
    }
  }
}
