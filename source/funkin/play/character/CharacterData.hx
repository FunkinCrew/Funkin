package funkin.play.character;

import flixel.util.typeLimit.OneOfTwo;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.character.BaseCharacter;
import funkin.play.character.MultiSparrowCharacter;
import funkin.play.character.PackerCharacter;
import funkin.play.character.SparrowCharacter;
import funkin.play.character.ScriptedCharacter.ScriptedBaseCharacter;
import funkin.play.character.ScriptedCharacter.ScriptedMultiSparrowCharacter;
import funkin.play.character.ScriptedCharacter.ScriptedPackerCharacter;
import funkin.play.character.ScriptedCharacter.ScriptedSparrowCharacter;
import funkin.util.assets.DataAssets;
import funkin.util.VersionUtil;
import haxe.Json;
import openfl.utils.Assets;

using StringTools;

class CharacterDataParser
{
	/**
	 * The current version string for the stage data format.
	 * Handle breaking changes by incrementing this value
	 * and adding migration to the `migrateStageData()` function.
	 */
	public static final CHARACTER_DATA_VERSION:String = "1.0.0";

	/**
	 * The current version rule check for the stage data format.
	 */
	public static final CHARACTER_DATA_VERSION_RULE:String = "1.0.x";

	static final characterCache:Map<String, CharacterData> = new Map<String, CharacterData>();
	static final characterScriptedClass:Map<String, String> = new Map<String, String>();

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
		// UNSCRIPTED CHARACTERS
		//
		var charIdList:Array<String> = DataAssets.listDataFilesInPath('characters/');
		var unscriptedCharIds:Array<String> = charIdList.filter(function(charId:String):Bool
		{
			return !characterCache.exists(charId);
		});
		trace('  Fetching data for ${unscriptedCharIds.length} characters...');
		for (charId in unscriptedCharIds)
		{
			try
			{
				var charData:CharacterData = parseCharacterData(charId);
				if (charData != null)
				{
					trace('    Loaded character data: ${charId}');
					characterCache.set(charId, charData);
				}
			}
			catch (e)
			{
				// Assume error was already logged.
				continue;
			}
		}

		//
		// SCRIPTED CHARACTERS
		//

		// Fuck I wish scripted classes supported static functions.

		var scriptedCharClassNames1:Array<String> = ScriptedSparrowCharacter.listScriptClasses();
		if (scriptedCharClassNames1.length > 0)
		{
			trace('  Instantiating ${scriptedCharClassNames1.length} (Sparrow) scripted characters...');
			for (charCls in scriptedCharClassNames1)
			{
				var character = ScriptedSparrowCharacter.init(charCls, DEFAULT_CHAR_ID);
				characterScriptedClass.set(character.characterId, charCls);
			}
		}

		var scriptedCharClassNames2:Array<String> = ScriptedPackerCharacter.listScriptClasses();
		if (scriptedCharClassNames2.length > 0)
		{
			trace('  Instantiating ${scriptedCharClassNames2.length} (Packer) scripted characters...');
			for (charCls in scriptedCharClassNames2)
			{
				var character = ScriptedPackerCharacter.init(charCls, DEFAULT_CHAR_ID);
				characterScriptedClass.set(character.characterId, charCls);
			}
		}

		var scriptedCharClassNames3:Array<String> = ScriptedMultiSparrowCharacter.listScriptClasses();
		trace('  Instantiating ${scriptedCharClassNames3.length} (Multi-Sparrow) scripted characters...');
		for (charCls in scriptedCharClassNames3)
		{
			var character = ScriptedBaseCharacter.init(charCls, DEFAULT_CHAR_ID);
			if (character == null)
			{
				trace('    Failed to instantiate scripted character: ${charCls}');
				continue;
			}
			characterScriptedClass.set(character.characterId, charCls);
		}

		// NOTE: Only instantiate the ones not populated above.
		// ScriptedBaseCharacter.listScriptClasses() will pick up scripts extending the other classes.
		var scriptedCharClassNames:Array<String> = ScriptedBaseCharacter.listScriptClasses();
		scriptedCharClassNames.filter(function(charCls:String):Bool
		{
			return !scriptedCharClassNames1.contains(charCls)
				&& !scriptedCharClassNames2.contains(charCls)
				&& !scriptedCharClassNames3.contains(charCls);
		});

		trace('  Instantiating ${scriptedCharClassNames.length} (Base) scripted characters...');
		for (charCls in scriptedCharClassNames)
		{
			var character = ScriptedBaseCharacter.init(charCls, DEFAULT_CHAR_ID);
			if (character == null)
			{
				trace('    Failed to instantiate scripted character: ${charCls}');
				continue;
			}
			else
			{
				trace('    Successfully instantiated scripted character: ${charCls}');
				characterScriptedClass.set(character.characterId, charCls);
			}
		}

		trace('  Successfully loaded ${Lambda.count(characterCache)} stages.');
	}

	public static function fetchCharacter(charId:String):Null<BaseCharacter>
	{
		if (charId == null || charId == '')
		{
			// Gracefully handle songs that don't use this character.
			return null;
		}

		if (characterCache.exists(charId))
		{
			var charData:CharacterData = characterCache.get(charId);
			var charScriptClass:String = characterScriptedClass.get(charId);

			var char:BaseCharacter;

			if (charScriptClass != null)
			{
				switch (charData.renderType)
				{
					case CharacterRenderType.MULTISPARROW:
						char = ScriptedMultiSparrowCharacter.init(charScriptClass, charId);
					case CharacterRenderType.SPARROW:
						char = ScriptedSparrowCharacter.init(charScriptClass, charId);
					case CharacterRenderType.PACKER:
						char = ScriptedPackerCharacter.init(charScriptClass, charId);
					default:
						// We're going to assume that the script class does the rendering.
						char = ScriptedBaseCharacter.init(charScriptClass, charId);
				}
			}
			else
			{
				switch (charData.renderType)
				{
					case CharacterRenderType.MULTISPARROW:
						char = new MultiSparrowCharacter(charId);
					case CharacterRenderType.SPARROW:
						char = new SparrowCharacter(charId);
					case CharacterRenderType.PACKER:
						char = new PackerCharacter(charId);
					default:
						trace('[WARN] Creating character with undefined renderType ${charData.renderType}');
						char = new BaseCharacter(charId);
				}
			}

			trace('[CHARDATA] Successfully instantiated character: ${charId}');

			// Call onCreate only in the fetchCharacter() function, not at application initialization.
			ScriptEventDispatcher.callEvent(char, new ScriptEvent(ScriptEvent.CREATE));

			return char;
		}
		else
		{
			trace('[CHARDATA] Failed to build character, not found in cache: ${charId}');
			return null;
		}
	}

	public static function fetchCharacterData(charId:String):Null<CharacterData>
	{
		if (characterCache.exists(charId))
		{
			return characterCache.get(charId);
		}
		else
		{
			return null;
		}
	}

	static function clearCharacterCache():Void
	{
		if (characterCache != null)
		{
			characterCache.clear();
		}
		if (characterScriptedClass != null)
		{
			characterScriptedClass.clear();
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
		var rawJson = StringTools.trim(Assets.getText(charFilePath));

		while (!StringTools.endsWith(rawJson, "}"))
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

	/**
	 * The default time the character should sing for, in beats.
	 * Values that are too low will cause the character to stop singing between notes.
	 * Originally, this value was set to 1, but it was changed to 2 because that became
	 * too low after some other code changes.
	 */
	static final DEFAULT_SINGTIME:Float = 2.0;

	static final DEFAULT_DANCEEVERY:Int = 1;
	static final DEFAULT_FLIPX:Bool = false;
	static final DEFAULT_FLIPY:Bool = false;
	static final DEFAULT_FRAMERATE:Int = 24;
	static final DEFAULT_ISPIXEL:Bool = false;
	static final DEFAULT_LOOP:Bool = false;
	static final DEFAULT_NAME:String = "Untitled Character";
	static final DEFAULT_OFFSETS:Array<Int> = [0, 0];
	static final DEFAULT_RENDERTYPE:CharacterRenderType = CharacterRenderType.SPARROW;
	static final DEFAULT_SCALE:Float = 1;
	static final DEFAULT_SCROLL:Array<Float> = [0, 0];
	static final DEFAULT_CAMERAOFFSET:Array<Float> = [0, 0];
	static final DEFAULT_STARTINGANIM:String = "idle";

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
			// trace('[CHARDATA] ERROR: Could not parse character data for "${id}".');
			return null;
		}

		if (input.version == null)
		{
			trace('[CHARDATA] WARN: No semantic version specified for character data file "$id", assuming ${CHARACTER_DATA_VERSION}');
			input.version = CHARACTER_DATA_VERSION;
		}

		if (!VersionUtil.validateVersion(input.version, CHARACTER_DATA_VERSION_RULE))
		{
			trace('[CHARDATA] ERROR: Could not load character data for "$id": bad version (got ${input.version}, expected ${CHARACTER_DATA_VERSION_RULE})');
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

		if (input.cameraOffset == null)
		{
			input.cameraOffset = DEFAULT_CAMERAOFFSET;
		}

		if (input.isPixel == null)
		{
			input.isPixel = DEFAULT_ISPIXEL;
		}

		if (input.danceEvery == null)
		{
			input.danceEvery = DEFAULT_DANCEEVERY;
		}

		if (input.singTime == null)
		{
			input.singTime = DEFAULT_SINGTIME;
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

			if (inputAnimation.offsets == null)
			{
				inputAnimation.offsets = DEFAULT_OFFSETS;
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
	var MULTISPARROW = 'multisparrow';
	// TODO: FlxSpine?
	//   https://api.haxeflixel.com/flixel/addons/editors/spine/FlxSpine.html
	// TODO: Aseprite?
	//   https://lib.haxe.org/p/openfl-aseprite/
	// TODO: Animate?
	//   https://lib.haxe.org/p/flxanimate
	// TODO: REDACTED
}

typedef CharacterData =
{
	/**
	 * The sematic version number of the character data JSON format.
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
	 * The scale of the graphic as a float.
	 * Pro tip: On pixel-art levels, save the sprites small and set this value to 6 or so to save memory.
	 * @default 1
	 */
	var scale:Null<Float>;

	/**
	 * The amount to offset the camera by while focusing on this character.
	 * Default value focuses on the character directly.
	 * @default [0, 0]
	 */
	var cameraOffset:Array<Float>;

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
