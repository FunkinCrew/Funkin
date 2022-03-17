package funkin.play.character;

import openfl.Assets;
import haxe.Json;
import funkin.play.character.render.PackerCharacter;
import funkin.play.character.render.SparrowCharacter;
import funkin.util.assets.DataAssets;
import funkin.play.character.CharacterBase;
import funkin.play.character.ScriptedCharacter.ScriptedSparrowCharacter;
import funkin.play.character.ScriptedCharacter.ScriptedPackerCharacter;
import flixel.util.typeLimit.OneOfTwo;

using StringTools;

class CharacterDataParser
{
	/**
	 * The current version string for the stage data format.
	 * Handle breaking changes by incrementing this value
	 * and adding migration to the `migrateStageData()` function.
	 */
	public static final CHARACTER_DATA_VERSION:String = "1.0";

	static final characterCache:Map<String, CharacterBase> = new Map<String, CharacterBase>();

	static final DEFAULT_CHAR_ID:String = 'UNKNOWN';

	/**
	 * Parses and preloads the game's stage data and scripts when the game starts.
	 * 
	 * If you want to force stages to be reloaded, you can just call this function again.
	 */
	public static function loadCharacterCache():Void
	{
		// Clear any stages that are cached if there were any.
		clearCharacterCache();
		trace("[CHARDATA] Loading character cache...");

		//
		// SCRIPTED CHARACTERS
		//

		// Generic (Sparrow) characters
		var scriptedCharClassNames:Array<String> = ScriptedCharacter.listScriptClasses();
		trace('  Instantiating ${scriptedCharClassNames.length} scripted characters...');
		for (charCls in scriptedCharClassNames)
		{
			_storeChar(ScriptedCharacter.init(charCls, DEFAULT_CHAR_ID), charCls);
		}

		// Sparrow characters
		scriptedCharClassNames = ScriptedSparrowCharacter.listScriptClasses();
		if (scriptedCharClassNames.length > 0)
		{
			trace('  Instantiating ${scriptedCharClassNames.length} scripted characters (SPARROW)...');
			for (charCls in scriptedCharClassNames)
			{
				_storeChar(ScriptedSparrowCharacter.init(charCls, DEFAULT_CHAR_ID), charCls);
			}
		}

		//		// Packer characters
		//		scriptedCharClassNames = ScriptedPackerCharacter.listScriptClasses();
		//		if (scriptedCharClassNames.length > 0)
		//		{
		//			trace('  Instantiating ${scriptedCharClassNames.length} scripted characters (PACKER)...');
		//			for (charCls in scriptedCharClassNames)
		//			{
		//				_storeChar(ScriptedPackerCharacter.init(charCls, DEFAULT_CHAR_ID), charCls);
		//			}
		//		}

		// TODO: Add more character types.

		//
		// UNSCRIPTED STAGES
		//
		var charIdList:Array<String> = DataAssets.listDataFilesInPath('characters/');
		var unscriptedCharIds:Array<String> = charIdList.filter(function(charId:String):Bool
		{
			return !characterCache.exists(charId);
		});
		trace('  Instantiating ${unscriptedCharIds.length} non-scripted characters...');
		for (charId in unscriptedCharIds)
		{
			var char:CharacterBase = null;
			try
			{
				var charData:CharacterData = parseCharacterData(charId);
				if (charData != null)
				{
					switch (charData.renderType)
					{
						case CharacterRenderType.PACKER:
							char = new PackerCharacter(charId);
						case CharacterRenderType.SPARROW:
							// default
							char = new SparrowCharacter(charId);
						default:
							trace('    Failed to instantiate character: ${charId} (Bad render type ${charData.renderType})');
					}
				}
				if (char != null)
				{
					trace('    Loaded character data: ${char.characterName}');
					characterCache.set(charId, char);
				}
			}
			catch (e)
			{
				// Assume error was already logged.
				continue;
			}
		}

		trace('  Successfully loaded ${Lambda.count(characterCache)} stages.');
	}

	static function _storeChar(char:CharacterBase, charCls:String):Void
	{
		if (char != null)
		{
			trace('    Loaded scripted character: ${char.characterName}');
			// Disable the rendering logic for stage until it's loaded.
			// Note that kill() =/= destroy()
			char.kill();

			// Then store it.
			characterCache.set(char.characterId, char);
		}
		else
		{
			trace('    Failed to instantiate scripted character class: ${charCls}');
		}
	}

	public static function fetchCharacter(charId:String):Null<CharacterBase>
	{
		if (characterCache.exists(charId))
		{
			trace('[CHARDATA] Successfully fetch stage: ${charId}');
			var character:CharacterBase = characterCache.get(charId);
			character.revive();
			return character;
		}
		else
		{
			trace('[CHARDATA] Failed to fetch character, not found in cache: ${charId}');
			return null;
		}
	}

	static function clearCharacterCache():Void
	{
		if (characterCache != null)
		{
			for (char in characterCache)
			{
				char.destroy();
			}
			characterCache.clear();
		}
	}

	/**
	 * Load a character's JSON file, parse its data, and return it.
	 * 
	 * @param charId The character to load.
	 * @return The character data, or null if validation failed.
	 */
	public static function parseCharacterData(charId:String):Null<CharacterData>
	{
		var rawJson:String = loadCharacterFile(charId);

		var charData:CharacterData = migrateCharacterData(rawJson, charId);

		return validateCharacterData(charId, charData);
	}

	static function loadCharacterFile(charPath:String):String
	{
		var charFilePath:String = Paths.json('characters/${charPath}');
		var rawJson = Assets.getText(charFilePath).trim();

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
		}

		return rawJson;
	}

	static function migrateCharacterData(rawJson:String, charId:String)
	{
		// If you update the character data format in a breaking way,
		// handle migration here by checking the `version` value.

		try
		{
			var charData:CharacterData = cast Json.parse(rawJson);
			return charData;
		}
		catch (e)
		{
			trace('  Error parsing data for character: ${charId}');
			trace('    ${e}');
			return null;
		}
	}

	static final DEFAULT_NAME:String = "Untitled Character";
	static final DEFAULT_RENDERTYPE:CharacterRenderType = CharacterRenderType.SPARROW;
	static final DEFAULT_STARTINGANIM:String = "idle";
	static final DEFAULT_SCROLL:Array<Float> = [0, 0];
	static final DEFAULT_ISPIXEL:Bool = false;
	static final DEFAULT_DANCEEVERY:Int = 1;
	static final DEFAULT_FRAMERATE:Int = 24;
	static final DEFAULT_FLIPX:Bool = false;
	static final DEFAULT_SCALE:Float = 1;
	static final DEFAULT_FLIPY:Bool = false;
	static final DEFAULT_LOOP:Bool = false;
	static final DEFAULT_FRAMEINDICES:Array<Int> = [];

	/**
	 * Set unspecified parameters to their defaults.
	 * If the parameter is mandatory, print an error message.
	 * @param id 
	 * @param input 
	 * @return The validated character data
	 */
	static function validateCharacterData(id:String, input:CharacterData):Null<CharacterData>
	{
		if (input == null)
		{
			trace('[CHARDATA] ERROR: Could not parse character data for "${id}".');
			return null;
		}

		if (input.version == null)
		{
			trace('[CHARDATA] ERROR: Could not load character data for "$id": missing version');
			return null;
		}

		if (input.version == CHARACTER_DATA_VERSION)
		{
			trace('[CHARDATA] ERROR: Could not load character data for "$id": bad/outdated version (got ${input.version}, expected ${CHARACTER_DATA_VERSION})');
			return null;
		}

		if (input.name == null)
		{
			trace('[CHARDATA] WARN: Character data for "$id" missing name');
			input.name = DEFAULT_NAME;
		}

		if (input.renderType == null)
		{
			input.renderType = DEFAULT_RENDERTYPE;
		}

		if (input.assetPath == null)
		{
			trace('[CHARDATA] ERROR: Could not load character data for "$id": missing assetPath');
			return null;
		}

		if (input.startingAnimation == null)
		{
			input.startingAnimation = DEFAULT_STARTINGANIM;
		}

		if (input.scale == null)
		{
			input.scale = DEFAULT_SCALE;
		}

		if (input.isPixel == null)
		{
			input.isPixel = DEFAULT_ISPIXEL;
		}

		if (input.danceEvery == null)
		{
			input.danceEvery = DEFAULT_DANCEEVERY;
		}

		if (input.animations == null || input.animations.length == 0)
		{
			trace('[CHARDATA] ERROR: Could not load character data for "$id": missing animations');
			input.animations = [];
		}

		if (input.animations.length == 0 && input.startingAnimation != null)
		{
			return null;
		}

		for (inputAnimation in input.animations)
		{
			if (inputAnimation.name == null)
			{
				trace('[CHARDATA] ERROR: Could not load character data for "$id": missing animation name for prop "${input.name}"');
				return null;
			}

			if (inputAnimation.frameRate == null)
			{
				inputAnimation.frameRate = DEFAULT_FRAMERATE;
			}

			if (inputAnimation.frameIndices == null)
			{
				inputAnimation.frameIndices = DEFAULT_FRAMEINDICES;
			}

			if (inputAnimation.looped == null)
			{
				inputAnimation.looped = DEFAULT_LOOP;
			}

			if (inputAnimation.flipX == null)
			{
				inputAnimation.flipX = DEFAULT_FLIPX;
			}

			if (inputAnimation.flipY == null)
			{
				inputAnimation.flipY = DEFAULT_FLIPY;
			}
		}

		// All good!
		return input;
	}
}

enum abstract CharacterRenderType(String) from String to String
{
	var SPARROW = 'sparrow';
	var PACKER = 'packer';
	// TODO: Aesprite?
	// TODO: Animate?
	// TODO: Experimental...
}

typedef CharacterData =
{
	/**
	 * The sematic version of the chart data format.
	 */
	var version:String;

	/**
	 * The readable name of the character.
	 */
	var name:String;

	/**
	 * The type of rendering system to use for the character.
	 * @default sparrow
	 */
	var renderType:CharacterRenderType;

	/**
	 * Behavior varies by render type:
	 * - SPARROW: Path to retrieve both the spritesheet and the XML data from.
	 * - PACKER: Path to retrieve both the spritsheet and the TXT data from.
	 */
	var assetPath:String;

	/**
	 * Either the scale of the graphic as a float, or the [w, h] scale as an array of two floats.
	 * Pro tip: On pixel-art levels, save the sprites small and set this value to 6 or so to save memory.
	 * @default 1
	 */
	var scale:OneOfTwo<Float, Array<Float>>;

	/**
	 * Setting this to true disables anti-aliasing for the character.
	 * @default false
	 */
	var isPixel:Null<Bool>;

	/**
	 * The frequency at which the character will play its idle animation, in beats.
	 * Increasing this number will make the character dance less often.
	 * 
	 * @default 1
	 */
	var danceEvery:Null<Int>;

	/**
	 * The minimum duration that a character will play a note animation for, in beats.
	 * If this number is too low, you may see the character start playing the idle animation between notes.
	 * If this number is too high, you may see the the character play the sing animation for too long after the notes are gone.
	 * 
	 * Examples:
	 * - Daddy Dearest uses a value of `1.525`.
	 * @default 1.0
	 */
	var singTime:Null<Float>;

	/**
	 * An optional array of animations which the character can play.
	 */
	var animations:Array<AnimationData>;

	/**
	 * If animations are used, this is the name of the animation to play first.
	 * @default idle
	 */
	var startingAnimation:Null<String>;
};
