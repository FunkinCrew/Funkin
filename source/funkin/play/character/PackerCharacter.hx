package funkin.play.character;

import funkin.modding.events.ScriptEvent;
import flixel.graphics.frames.FlxFramesCollection;
import funkin.util.assets.FlxAnimationUtil;
import funkin.play.character.BaseCharacter.CharacterType;

/**
 * A PackerCharacter is a Character which is rendered by
 * displaying an animation derived from a Packer spritesheet file.
 */
class PackerCharacter extends BaseCharacter
{
	public function new(id:String)
	{
		super(id);
	}

	override function onCreate(event:ScriptEvent):Void
	{
		trace('Creating PACKER CHARACTER: ' + this.characterId);

		loadSpritesheet();
		loadAnimations();

		playAnimation(_data.startingAnimation);
	}

	function loadSpritesheet()
	{
		trace('[PACKERCHAR] Loading spritesheet ${_data.assetPath} for ${characterId}');

		var tex:FlxFramesCollection = Paths.getPackerAtlas(_data.assetPath, 'shared');
		if (tex == null)
		{
			trace('Could not load Packer sprite: ${_data.assetPath}');
			return;
		}

		this.frames = tex;

		if (_data.isPixel)
		{
			this.antialiasing = false;
		}
		else
		{
			this.antialiasing = true;
		}

		if (_data.scale != null)
		{
			this.setGraphicSize(Std.int(this.width * this.scale.x));
			this.updateHitbox();
		}
	}

	function loadAnimations()
	{
		trace('[PACKERCHAR] Loading ${_data.animations.length} animations for ${characterId}');

		FlxAnimationUtil.addAtlasAnimations(this, _data.animations);

		for (anim in _data.animations)
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
		trace('[PACKERCHAR] Successfully loaded ${animNames.length} animations for ${characterId}');
	}
}
