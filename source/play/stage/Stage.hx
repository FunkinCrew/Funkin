package play.stage;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSort;
import modding.IHook;
import play.character.Character.CharacterType;
import play.stage.StageData.StageDataParser;
import util.SortUtil;

/**
 * A Stage is a group of objects rendered in the PlayState.
 * 
 * A Stage is comprised of one or more props, each of which is a FlxSprite.
 */
class Stage extends FlxSpriteGroup implements IHook
{
	public final stageId:String;
	public final stageName:String;

	final _data:StageData;

	public var camZoom:Float = 1.0;

	var namedProps:Map<String, FlxObject> = new Map<String, FlxObject>();
	var characters:Map<String, Character> = new Map<String, Character>();

	/**
	 * The Stage elements get initialized at the beginning of the game.
	 * They're used to cache the data needed to build the stage,
	 * then accessed and fleshed out when the stage needs to be built.
	 * 
	 * @param stageId 
	 */
	public function new(stageId:String)
	{
		super();

		this.stageId = stageId;
		_data = StageDataParser.parseStageData(this.stageId);
		this.stageName = _data.name;
	}

	/**
	 * The default stage construction routine. Called when the stage is going to be played in.
	 * Instantiates each prop and adds it to the stage, while setting its parameters.
	 */
	public function buildStage()
	{
		trace('Building stage for display: ${this.stageId}');

		this.camZoom = _data.cameraZoom;

		for (dataProp in _data.props)
		{
			trace('  Placing prop: ${dataProp.name} (${dataProp.assetPath})');
			var imagePath = Paths.image(dataProp.assetPath);
			var propSprite = new FlxSprite().loadGraphic(imagePath);

			if (Std.isOfType(dataProp.scale, Array))
			{
				propSprite.scale.set(dataProp.scale[0], dataProp.scale[1]);
			}
			else
			{
				propSprite.scale.set(dataProp.scale);
			}
			propSprite.updateHitbox();

			propSprite.x = dataProp.position[0];
			propSprite.y = dataProp.position[1];

			propSprite.scrollFactor.x = dataProp.scroll[0];
			propSprite.scrollFactor.y = dataProp.scroll[1];

			propSprite.zIndex = dataProp.zIndex;

			for (propAnim in dataProp.animations)
			{
				propSprite.animation.addByPrefix(propAnim.name, propAnim.prefix, propAnim.frameRate, propAnim.loop);
			}

			if (dataProp.startingAnimation != null)
			{
				propSprite.animation.play(dataProp.startingAnimation);
			}

			if (dataProp.name != null)
			{
				namedProps.set(dataProp.name, propSprite);
			}

			trace('    Prop placed.');
			this.add(propSprite);
		}

		this.refresh();
	}

	/**
	 * Refreshes the stage, by redoing the render order of all props.
	 * It does this based on the `zIndex` of each prop.
	 */
	public function refresh()
	{
		sort(SortUtil.byZIndex, FlxSort.ASCENDING);
	}

	public function addCharacter(character:Character, charType:CharacterType)
	{
		// Apply position and z-index.
		switch (charType)
		{
			case BF:
				this.characters.set("bf", character);
				character.zIndex = _data.characters.bf.zIndex;
				character.x = _data.characters.bf.position[0];
				character.y = _data.characters.bf.position[1];
			case GF:
				this.characters.set("gf", character);
				character.zIndex = _data.characters.gf.zIndex;
				character.x = _data.characters.gf.position[0];
				character.y = _data.characters.gf.position[1];
			case DAD:
				this.characters.set("dad", character);
				character.zIndex = _data.characters.dad.zIndex;
				character.x = _data.characters.dad.position[0];
				character.y = _data.characters.dad.position[1];
			default:
				this.characters.set(character.curCharacter, character);
		}

		// Add the character to the scene.
		this.add(character);
	}

	public function getCharacter(id:String):Character
	{
		return this.characters.get(id);
	}

	public function getBoyfriend():Character
	{
		return this.characters.get("bf");
	}

	public function getGirlfriend():Character
	{
		return this.characters.get("gf");
	}

	public function getDad():Character
	{
		return this.characters.get("dad");
	}

	public function cleanup()
	{
		this.clear();
		namedProps.clear();
		characters.clear();
	}
}
