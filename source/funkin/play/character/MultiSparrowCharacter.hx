package funkin.play.character;

import flixel.graphics.frames.FlxFramesCollection;
import funkin.modding.events.ScriptEvent;
import funkin.util.assets.FlxAnimationUtil;

/**
 * For some characters which use Sparrow atlases, the spritesheets need to be split
 * into multiple files. This character renderer handles by showing the appropriate sprite.
 * 
 * Examples in base game include BF Holding GF (most of the sprites are in one file
 * but the death animation is in a separate file).
 * Only example I can think of in mods is Tricky (which has a separate file for each animation).
 * 
 * BaseCharacter has game logic, SparrowCharacter has only rendering logic.
 * KEEP THEM SEPARATE!
 *
 * TODO: Rewrite this to use a single frame collection.
 * @see https://github.com/HaxeFlixel/flixel/issues/2587#issuecomment-1179620637
 */
class MultiSparrowCharacter extends BaseCharacter
{
	/**
	 * The actual group which holds all spritesheets this character uses.
	 */
	private var members:Map<String, FlxFramesCollection> = new Map<String, FlxFramesCollection>();

	/**
	 * A map between animation names and what frame collection the animation should use.
	 */
	private var animAssetPath:Map<String, String> = new Map<String, String>();

	/**
	 * The current frame collection being used.
	 */
	private var activeMember:String;

	public function new(id:String)
	{
		super(id);
	}

	override function onCreate(event:ScriptEvent):Void
	{
		trace('Creating MULTI SPARROW CHARACTER: ' + this.characterId);

		buildSprites();
		super.onCreate(event);
	}

	function buildSprites()
	{
		buildSpritesheets();
		buildAnimations();

		if (_data.isPixel)
		{
			this.antialiasing = false;
		}
		else
		{
			this.antialiasing = true;
		}
	}

	function buildSpritesheets()
	{
		// Build the list of asset paths to use.
		// Ignore nulls and duplicates.
		var assetList = [_data.assetPath];
		for (anim in _data.animations)
		{
			if (anim.assetPath != null && !assetList.contains(anim.assetPath))
			{
				assetList.push(anim.assetPath);
			}
			animAssetPath.set(anim.name, anim.assetPath);
		}

		// Load the Sparrow atlas for each path and store them in the members map.
		for (asset in assetList)
		{
			var texture:FlxFramesCollection = Paths.getSparrowAtlas(asset, 'shared');
			// If we don't do this, the unused textures will be removed as soon as they're loaded.

			if (texture == null)
			{
				trace('Multi-Sparrow atlas could not load texture: ${asset}');
			}
			else
			{
				trace('Adding multi-sparrow atlas: ${asset}');
				texture.parent.destroyOnNoUse = false;
				members.set(asset, texture);
			}
		}

		// Use the default frame collection to start.
		loadFramesByAssetPath(_data.assetPath);
	}

	/**
	 * Replace this sprite's animation frames with the ones at this asset path.
	 */
	function loadFramesByAssetPath(assetPath:String):Void
	{
		if (_data.assetPath == null)
		{
			trace('[ERROR] Multi-Sparrow character has no default asset path!');
			return;
		}
		if (assetPath == null)
		{
			// trace('Asset path is null, falling back to default. This is normal!');
			loadFramesByAssetPath(_data.assetPath);
			return;
		}

		if (this.activeMember == assetPath)
		{
			// trace('Already using this asset path: ${assetPath}');
			return;
		}

		if (members.exists(assetPath))
		{
			// Switch to a new set of sprites.
			// trace('Loading frames from asset path: ${assetPath}');
			this.frames = members.get(assetPath);
			this.activeMember = assetPath;
			this.setScale(_data.scale);
		}
		else
		{
			trace('[WARN] MultiSparrow character ${characterId} could not find asset path: ${assetPath}');
		}
	}

	/**
	 * Replace this sprite's animation frames with the ones needed to play this animation.
	 */
	function loadFramesByAnimName(animName)
	{
		if (animAssetPath.exists(animName))
		{
			loadFramesByAssetPath(animAssetPath.get(animName));
		}
		else
		{
			trace('[WARN] MultiSparrow character ${characterId} could not find animation: ${animName}');
		}
	}

	function buildAnimations()
	{
		trace('[MULTISPARROWCHAR] Loading ${_data.animations.length} animations for ${characterId}');

		// We need to swap to the proper frame collection before adding the animations, I think?
		for (anim in _data.animations)
		{
			loadFramesByAnimName(anim.name);
			FlxAnimationUtil.addAtlasAnimation(this, anim);

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
		trace('[MULTISPARROWCHAR] Successfully loaded ${animNames.length} animations for ${characterId}');
	}

	public override function playAnimation(name:String, restart:Bool = false, ?ignoreOther:Bool = false):Void
	{
		// Make sure we ignore other animations if we're currently playing a forced one,
		// unless we're forcing a new animation.
		if (!this.canPlayOtherAnims && !ignoreOther)
			return;

		loadFramesByAnimName(name);
		super.playAnimation(name, restart, ignoreOther);
	}

	override function set_frames(value:FlxFramesCollection):FlxFramesCollection
	{
		// DISABLE THIS SO WE DON'T DESTROY OUR HARD WORK
		// WE WILL MAKE SURE TO LOAD THE PROPER SPRITESHEET BEFORE PLAYING AN ANIM
		// if (animation != null)
		// {
		// 	animation.destroyAnimations();
		// }

		if (value != null)
		{
			graphic = value.parent;
			this.frames = value;
			this.frame = value.getByIndex(0);
			this.numFrames = value.numFrames;
			resetHelpers();
			this.bakedRotationAngle = 0;
			this.animation.frameIndex = 0;
			graphicLoaded();
		}
		else
		{
			this.frames = null;
			this.frame = null;
			this.graphic = null;
		}

		return this.frames;
	}
}
