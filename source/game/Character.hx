package game;

import flixel.FlxG;
import flixel.addons.effects.FlxTrail;
import flixel.util.FlxColor;
import modding.CharacterCreationState.SpritesheetType;
import lime.utils.Assets;
import flixel.graphics.frames.FlxFramesCollection;
import haxe.Json;
#if sys
import sys.io.File;
import polymod.backends.PolymodAssets;
#end
import utilities.CoolUtil;
import states.PlayState;
import flixel.FlxSprite;
import modding.CharacterConfig;

using StringTools;

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = 'bf';

	public var holdTimer:Float = 0;
	var animationNotes:Array<Dynamic> = [];

	var dancesLeftAndRight:Bool = false;

	public var barColor:FlxColor = FlxColor.WHITE;
	public var positioningOffset:Array<Float> = [0, 0];
	public var cameraOffset:Array<Float> = [0, 0];

	public var otherCharacters:Array<Character>;

	var offsetsFlipWhenPlayer:Bool = true;
	var offsetsFlipWhenEnemy:Bool = false;

	public var coolTrail:FlxTrail;

	public var deathCharacter:String = "bf-dead";

	public var swapLeftAndRightSingPlayer:Bool = true;

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false, ?isDeathCharacter:Bool = false)
	{
		super(x, y);

		animOffsets = new Map<String, Array<Dynamic>>();
		curCharacter = character;
		this.isPlayer = isPlayer;

		antialiasing = true;

		dancesLeftAndRight = false;

		var ilikeyacutg:Bool = false;

		switch (curCharacter)
		{
			case 'gf':
				// GIRLFRIEND CODE
				frames = Paths.getSparrowAtlas('characters/GF_assets', 'shared');

				quickAnimAdd('cheer', "GF Cheer");
				quickAnimAdd('singLEFT', "GF left note");
				quickAnimAdd('singRIGHT', "GF Right Note");
				quickAnimAdd('singUP', "GF Up Note");
				quickAnimAdd('singDOWN', "GF Down Note");

				animation.addByIndices('sad', 'gf sad', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], "", 24, false);
				animation.addByIndices('danceLeft', 'GF Dancing Beat', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				animation.addByIndices('danceRight', 'GF Dancing Beat', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
				animation.addByIndices('hairBlow', "GF Dancing Beat Hair blowing", [0, 1, 2, 3], "", 24);
				animation.addByIndices('hairFall', "GF Dancing Beat Hair Landing", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], "", 24, false);

				animation.addByPrefix('scared', 'GF FEAR', 24, false);

				dancesLeftAndRight = true;
				playAnim('danceRight');
				barColor = FlxColor.fromRGB(186, 49, 104);
			case 'gf-old':
				frames = Paths.getSparrowAtlas('characters/GF_OLD_assets', 'shared');

				quickAnimAdd('cheer', "GF Cheer");
				quickAnimAdd('sad', "gf sad");

				animation.addByIndices('danceLeft', 'GF Dancing Beat', [29, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				animation.addByIndices('danceRight', 'GF Dancing Beat', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);

				dancesLeftAndRight = true;
				playAnim('danceRight');
				barColor = FlxColor.fromRGB(186, 49, 104);
			case 'gf-christmas':
				frames = Paths.getSparrowAtlas('characters/gfChristmas', 'shared');

				quickAnimAdd('cheer', "GF Cheer");
				quickAnimAdd('singLEFT', "GF left note");
				quickAnimAdd('singRIGHT', "GF Right Note");
				quickAnimAdd('singUP', "GF Up Note");
				quickAnimAdd('singDOWN', "GF Down Note");

				animation.addByIndices('sad', 'gf sad', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], "", 24, false);
				animation.addByIndices('danceLeft', 'GF Dancing Beat', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				animation.addByIndices('danceRight', 'GF Dancing Beat', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
				animation.addByIndices('hairBlow', "GF Dancing Beat Hair blowing", [0, 1, 2, 3], "", 24);
				animation.addByIndices('hairFall', "GF Dancing Beat Hair Landing", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], "", 24, false);

				animation.addByPrefix('scared', 'GF FEAR', 24, false);

				dancesLeftAndRight = true;
				playAnim('danceRight');
				barColor = FlxColor.fromRGB(186, 49, 104);
			case 'gf-car':
				frames = Paths.getSparrowAtlas('characters/gfCar', 'shared');

				animation.addByIndices('danceLeft', 'GF Dancing Beat Hair blowing CAR', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				animation.addByIndices('danceRight', 'GF Dancing Beat Hair blowing CAR', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24,
					false);

				playAnim('danceRight');
				dancesLeftAndRight = true;
				barColor = FlxColor.fromRGB(186, 49, 104);
			case 'gf-pixel':
				frames = Paths.getSparrowAtlas('characters/gfPixel', 'shared');
				animation.addByIndices('singUP', 'GF IDLE', [2], "", 24, false);
				animation.addByIndices('danceLeft', 'GF IDLE', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				animation.addByIndices('danceRight', 'GF IDLE', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);

				playAnim('danceRight');

				setGraphicSize(Std.int(width * 6));

				positioningOffset = [100, 100];

				antialiasing = false;
				dancesLeftAndRight = true;
				barColor = FlxColor.fromRGB(186, 49, 104);
			case 'dad':
				// DAD ANIMATION LOADING CODE
				frames = Paths.getSparrowAtlas('characters/DADDY_DEAREST', 'shared');
				animation.addByPrefix('idle', 'Dad idle dance', 24, false);
				animation.addByPrefix('singUP', 'Dad Sing note UP', 24, false);
				animation.addByPrefix('singRIGHT', 'Dad Sing Note RIGHT', 24, false);
				animation.addByPrefix('singDOWN', 'Dad Sing Note DOWN', 24, false);
				animation.addByPrefix('singLEFT', 'Dad Sing Note LEFT', 24, false);

				playAnim('idle');
				barColor = FlxColor.fromRGB(199, 111, 211);
			case 'spooky':
				frames = Paths.getSparrowAtlas('characters/spooky_kids_assets', 'shared');
				animation.addByPrefix('singUP', 'spooky UP NOTE', 24, false);
				animation.addByPrefix('singDOWN', 'spooky DOWN note', 24, false);
				animation.addByPrefix('singLEFT', 'note sing left', 24, false);
				animation.addByPrefix('singRIGHT', 'spooky sing right', 24, false);
				animation.addByIndices('danceLeft', 'spooky dance idle', [0, 2, 6], "", 12, false);
				animation.addByIndices('danceRight', 'spooky dance idle', [8, 10, 12, 14], "", 12, false);

				playAnim('danceRight');
				dancesLeftAndRight = true;
				barColor = FlxColor.fromRGB(226, 147, 30);
			case 'mom':
				frames = Paths.getSparrowAtlas('characters/Mom_Assets', 'shared');

				animation.addByPrefix('idle', "Mom Idle", 24, false);
				animation.addByPrefix('singUP', "Mom Up Pose", 24, false);
				animation.addByPrefix('singDOWN', "MOM DOWN POSE", 24, false);
				animation.addByPrefix('singLEFT', 'Mom Left Pose', 24, false);
				// ANIMATION IS CALLED MOM LEFT POSE BUT ITS FOR THE RIGHT
				// CUZ DAVE IS DUMB!
				animation.addByPrefix('singRIGHT', 'Mom Pose Left', 24, false);

				playAnim('idle');
				barColor = FlxColor.fromRGB(231, 109, 166);
			case 'mom-car':
				frames = Paths.getSparrowAtlas('characters/momCar', 'shared');

				animation.addByPrefix('idle', "Mom Idle", 24, false);
				animation.addByPrefix('singUP', "Mom Up Pose", 24, false);
				animation.addByPrefix('singDOWN', "MOM DOWN POSE", 24, false);
				animation.addByPrefix('singLEFT', 'Mom Left Pose', 24, false);
				// ANIMATION IS CALLED MOM LEFT POSE BUT ITS FOR THE RIGHT
				// CUZ DAVE IS DUMB!
				animation.addByPrefix('singRIGHT', 'Mom Pose Left', 24, false);

				playAnim('idle');
				barColor = FlxColor.fromRGB(231, 109, 166);
			case 'monster':
				frames = Paths.getSparrowAtlas('characters/Monster_Assets', 'shared');
				animation.addByPrefix('idle', 'monster idle', 24, false);
				animation.addByPrefix('singUP', 'monster up note', 24, false);
				animation.addByPrefix('singDOWN', 'monster down', 24, false);
				// fixed this garbage lol
				animation.addByPrefix('singLEFT', 'Monster Right note', 24, false);
				animation.addByPrefix('singRIGHT', 'Monster left note', 24, false);

				playAnim('idle');
				barColor = FlxColor.fromRGB(245, 255, 105);
			case 'monster-christmas':
				frames = Paths.getSparrowAtlas('characters/monsterChristmas', 'shared');
				animation.addByPrefix('idle', 'monster idle', 24, false);
				animation.addByPrefix('singUP', 'monster up note', 24, false);
				animation.addByPrefix('singDOWN', 'monster down', 24, false);
				// fixed this too lol
				animation.addByPrefix('singLEFT', 'Monster Right note', 24, false);
				animation.addByPrefix('singRIGHT', 'Monster left note', 24, false);

				playAnim('idle');
				barColor = FlxColor.fromRGB(245, 255, 105);
			case 'pico':
				frames = Paths.getSparrowAtlas('characters/Pico_FNF_assetss', 'shared');
				animation.addByPrefix('idle', "Pico Idle Dance", 24);
				animation.addByPrefix('singUP', 'pico Up note0', 24, false);
				animation.addByPrefix('singDOWN', 'Pico Down Note0', 24, false);

				if (isPlayer)
				{
					animation.addByPrefix('singLEFT', 'Pico NOTE LEFT0', 24, false);
					animation.addByPrefix('singRIGHT', 'Pico Note Right0', 24, false);
					animation.addByPrefix('singRIGHTmiss', 'Pico Note Right Miss', 24, false);
					animation.addByPrefix('singLEFTmiss', 'Pico NOTE LEFT miss', 24, false);
				}
				else
				{
					// Need to be flipped! REDO THIS LATER!
					animation.addByPrefix('singLEFT', 'Pico Note Right0', 24, false);
					animation.addByPrefix('singRIGHT', 'Pico NOTE LEFT0', 24, false);
					animation.addByPrefix('singRIGHTmiss', 'Pico NOTE LEFT miss', 24, false);
					animation.addByPrefix('singLEFTmiss', 'Pico Note Right Miss', 24, false);
				}

				animation.addByPrefix('singUPmiss', 'pico Up note miss', 24);
				animation.addByPrefix('singDOWNmiss', 'Pico Down Note MISS', 24);

				playAnim('idle');

				flipX = true;
				barColor = FlxColor.fromRGB(205, 229, 112);
			case 'bf-christmas':
				swapLeftAndRightSingPlayer = false;

				frames = Paths.getSparrowAtlas('characters/bfChristmas', 'shared');
				animation.addByPrefix('idle', 'BF idle dance', 24, false);
				animation.addByPrefix('singUP', 'BF NOTE UP0', 24, false);
				animation.addByPrefix('singLEFT', 'BF NOTE LEFT0', 24, false);
				animation.addByPrefix('singRIGHT', 'BF NOTE RIGHT0', 24, false);
				animation.addByPrefix('singDOWN', 'BF NOTE DOWN0', 24, false);
				animation.addByPrefix('singUPmiss', 'BF NOTE UP MISS', 24, false);
				animation.addByPrefix('singLEFTmiss', 'BF NOTE LEFT MISS', 24, false);
				animation.addByPrefix('singRIGHTmiss', 'BF NOTE RIGHT MISS', 24, false);
				animation.addByPrefix('singDOWNmiss', 'BF NOTE DOWN MISS', 24, false);
				animation.addByPrefix('hey', 'BF HEY', 24, false);
				animation.addByPrefix('scared', 'BF idle shaking', 24, false);

				playAnim('idle');

				flipX = true;
				barColor = FlxColor.fromRGB(81, 201, 219);
				offsetsFlipWhenEnemy = true;
				offsetsFlipWhenPlayer = false;
			case 'bf-car':
				swapLeftAndRightSingPlayer = false;

				frames = Paths.getSparrowAtlas('characters/bfCar', 'shared');
				animation.addByPrefix('idle', 'BF idle dance', 24, false);
				animation.addByPrefix('singUP', 'BF NOTE UP0', 24, false);
				animation.addByPrefix('singLEFT', 'BF NOTE LEFT0', 24, false);
				animation.addByPrefix('singRIGHT', 'BF NOTE RIGHT0', 24, false);
				animation.addByPrefix('singDOWN', 'BF NOTE DOWN0', 24, false);
				animation.addByPrefix('singUPmiss', 'BF NOTE UP MISS', 24, false);
				animation.addByPrefix('singLEFTmiss', 'BF NOTE LEFT MISS', 24, false);
				animation.addByPrefix('singRIGHTmiss', 'BF NOTE RIGHT MISS', 24, false);
				animation.addByPrefix('singDOWNmiss', 'BF NOTE DOWN MISS', 24, false);
				animation.addByPrefix('hey', 'BF HEY', 24, false);
				animation.addByPrefix('scared', 'BF idle shaking', 24, false);

				playAnim('idle');

				flipX = true;
				barColor = FlxColor.fromRGB(81, 201, 219);
				offsetsFlipWhenEnemy = true;
				offsetsFlipWhenPlayer = false;
			case 'bf-pixel':
				swapLeftAndRightSingPlayer = false;

				frames = Paths.getSparrowAtlas('characters/bfPixel', 'shared');
				animation.addByPrefix('idle', 'BF IDLE', 24, false);
				animation.addByPrefix('singUP', 'BF UP NOTE', 24, false);
				animation.addByPrefix('singLEFT', 'BF LEFT NOTE', 24, false);
				animation.addByPrefix('singRIGHT', 'BF RIGHT NOTE', 24, false);
				animation.addByPrefix('singDOWN', 'BF DOWN NOTE', 24, false);
				animation.addByPrefix('singUPmiss', 'BF UP MISS', 24, false);
				animation.addByPrefix('singLEFTmiss', 'BF LEFT MISS', 24, false);
				animation.addByPrefix('singRIGHTmiss', 'BF RIGHT MISS', 24, false);
				animation.addByPrefix('singDOWNmiss', 'BF DOWN MISS', 24, false);

				animation.addByPrefix('hey', 'BF Peace Sign', 24, false);

				setGraphicSize(Std.int(width * 6));

				playAnim('idle');

				//width -= 100;
				//height -= 100;

				cameraOffset = [-100, -200];

				antialiasing = false;

				flipX = true;

				barColor = FlxColor.fromRGB(123, 214, 246);
				offsetsFlipWhenEnemy = true;
				offsetsFlipWhenPlayer = false;

				deathCharacter = "bf-pixel-dead";
			case 'bf-pixel-dead':
				swapLeftAndRightSingPlayer = false;

				frames = Paths.getSparrowAtlas('characters/bfPixelsDEAD', 'shared');
				animation.addByPrefix('singUP', "BF Dies pixel", 24, false);
				animation.addByPrefix('firstDeath', "BF Dies pixel", 24, false);
				animation.addByPrefix('deathLoop', "Retry Loop", 24, true);
				animation.addByPrefix('deathConfirm', "RETRY CONFIRM", 24, false);

				playAnim('firstDeath');
				// pixel bullshit
				setGraphicSize(Std.int(width * 6));
				
				antialiasing = false;
				flipX = true;
				barColor = FlxColor.fromRGB(123, 214, 246);

			case 'senpai':
				frames = Paths.getSparrowAtlas('characters/senpai', 'shared');
				animation.addByPrefix('idle', 'Senpai Idle', 24, false);
				animation.addByPrefix('singUP', 'SENPAI UP NOTE', 24, false);
				animation.addByPrefix('singLEFT', 'SENPAI LEFT NOTE', 24, false);
				animation.addByPrefix('singRIGHT', 'SENPAI RIGHT NOTE', 24, false);
				animation.addByPrefix('singDOWN', 'SENPAI DOWN NOTE', 24, false);

				playAnim('idle');

				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				cameraOffset = [15, 0];
				positioningOffset = [0, 300];

				antialiasing = false;
				barColor = FlxColor.fromRGB(255, 170, 111);
			case 'senpai-angry':
				frames = Paths.getSparrowAtlas('characters/senpai', 'shared');
				animation.addByPrefix('idle', 'Angry Senpai Idle', 24, false);
				animation.addByPrefix('singUP', 'Angry Senpai UP NOTE', 24, false);
				animation.addByPrefix('singLEFT', 'Angry Senpai LEFT NOTE', 24, false);
				animation.addByPrefix('singRIGHT', 'Angry Senpai RIGHT NOTE', 24, false);
				animation.addByPrefix('singDOWN', 'Angry Senpai DOWN NOTE', 24, false);

				playAnim('idle');

				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				cameraOffset = [15, 0];
				positioningOffset = [0, 300];

				antialiasing = false;
				barColor = FlxColor.fromRGB(255, 170, 111);
			case 'spirit':
				frames = Paths.getPackerAtlas('characters/spirit', 'shared');
				animation.addByPrefix('idle', "idle spirit_", 24, false);
				animation.addByPrefix('singUP', "up_", 24, false);
				animation.addByPrefix('singRIGHT', "right_", 24, false);
				animation.addByPrefix('singLEFT', "left_", 24, false);
				animation.addByPrefix('singDOWN', "spirit down_", 24, false);

				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				playAnim('idle');

				positioningOffset = [-250, -100];

				antialiasing = false;
				barColor = FlxColor.fromRGB(255, 60, 110);

				coolTrail = new FlxTrail(this, null, 4, 24, 0.3, 0.069);
			case 'parents-christmas':
				frames = Paths.getSparrowAtlas('characters/mom_dad_christmas_assets', 'shared');
				animation.addByPrefix('idle', 'Parent Christmas Idle', 24, false);
				animation.addByPrefix('singUP', 'Parent Up Note Dad', 24, false);
				animation.addByPrefix('singDOWN', 'Parent Down Note Dad', 24, false);
				animation.addByPrefix('singLEFT', 'Parent Left Note Dad', 24, false);
				animation.addByPrefix('singRIGHT', 'Parent Right Note Dad', 24, false);

				animation.addByPrefix('singUP-alt', 'Parent Up Note Mom', 24, false);

				animation.addByPrefix('singDOWN-alt', 'Parent Down Note Mom', 24, false);
				animation.addByPrefix('singLEFT-alt', 'Parent Left Note Mom', 24, false);
				animation.addByPrefix('singRIGHT-alt', 'Parent Right Note Mom', 24, false);

				playAnim('idle');
				barColor = FlxColor.fromRGB(199, 111, 211);
			case '':
				trace("NO VALUE THINGY LOL DONT LOAD SHIT");
				deathCharacter = "";

			default:
				if (isPlayer)
					flipX = !flipX;

				ilikeyacutg = true;
				
				loadNamedConfiguration(curCharacter);
		}

		if (isPlayer && !ilikeyacutg)
			flipX = !flipX;

		// YOOOOOOOOOO POG MODDING STUFF
		if(character != "")
			loadOffsetFile(curCharacter);

		if(curCharacter != '' && otherCharacters == null)
		{
			updateHitbox();

			if(!debugMode)
			{
				dance();
	
				if(isPlayer)
				{
					// Doesn't flip for BF, since his are already in the right place???
					if(swapLeftAndRightSingPlayer && !isDeathCharacter)
					{
						// var animArray
						var oldRight = animation.getByName('singRIGHT').frames;
						animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
						animation.getByName('singLEFT').frames = oldRight;
		
						// IF THEY HAVE MISS ANIMATIONS??
						if (animation.getByName('singRIGHTmiss') != null)
						{
							var oldMiss = animation.getByName('singRIGHTmiss').frames;
							animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
							animation.getByName('singLEFTmiss').frames = oldMiss;
						}
					}
				}
			}
		}
		else
			visible = false;
	}

	function loadNamedConfiguration(characterName:String)
	{
		var rawJson:String;

		#if sys
		rawJson = PolymodAssets.getText(Paths.json("character data/" + characterName + "/config")).trim();
		#else
		rawJson = Assets.getText(Paths.json("character data/" + characterName + "/config")).trim();
		#end

		var config:CharacterConfig = cast Json.parse(rawJson);

		loadCharacterConfiguration(config);
	}

	public function loadCharacterConfiguration(config:CharacterConfig)
	{
		if(config.characters == null || config.characters.length <= 1)
		{
			if(!isPlayer)
				flipX = config.defaultFlipX;
			else
				flipX = !config.defaultFlipX;

			if(config.offsetsFlipWhenPlayer == null)
			{
				if(curCharacter.startsWith("bf"))
					offsetsFlipWhenPlayer = false;
				else
					offsetsFlipWhenPlayer = true;
			}
			else
				offsetsFlipWhenPlayer = config.offsetsFlipWhenPlayer;

			if(config.offsetsFlipWhenEnemy == null)
			{
				if(curCharacter.startsWith("bf"))
					offsetsFlipWhenEnemy = true;
				else
					offsetsFlipWhenEnemy = false;
			}
			else
				offsetsFlipWhenEnemy = config.offsetsFlipWhenEnemy;

			dancesLeftAndRight = config.dancesLeftAndRight;

			#if sys
			if(Assets.exists(Paths.image('characters/' + config.imagePath, 'shared')))
				frames = Paths.getSparrowAtlas('characters/' + config.imagePath, 'shared');
			else
				frames = Paths.getSparrowAtlasSYS("characters/" + config.imagePath, "shared");
			#else
			frames = Paths.getSparrowAtlas('characters/' + config.imagePath, 'shared');
			#end

			if(config.graphicsSize != null)
				setGraphicSize(Std.int(width * config.graphicsSize));

			for(selected_animation in config.animations)
			{
				if(selected_animation.indices != null)
				{
					animation.addByIndices(
						selected_animation.name,
						selected_animation.animation_name,
						selected_animation.indices, "",
						selected_animation.fps,
						selected_animation.looped
					);
				}
				else
				{
					animation.addByPrefix(
						selected_animation.name,
						selected_animation.animation_name,
						selected_animation.fps,
						selected_animation.looped
					);
				}
			}

			if(dancesLeftAndRight)
				playAnim("danceRight");
			else
				playAnim("idle");

			if(debugMode)
				flipX = config.defaultFlipX;

			updateHitbox();

			if(config.positionOffset != null)
				positioningOffset = config.positionOffset;

			if(config.trail == true)
				coolTrail = new FlxTrail(this, null, config.trailLength, config.trailDelay, config.trailStalpha, config.trailDiff);

			if(config.swapDirectionSingWhenPlayer != null)
				swapLeftAndRightSingPlayer = config.swapDirectionSingWhenPlayer;
			else if(curCharacter.startsWith("bf"))
				swapLeftAndRightSingPlayer = false;
		}
		else
		{
			otherCharacters = [];

			for(characterData in config.characters)
			{
				var character:Character;

				if(!isPlayer)
					character = new Character(x, y, characterData.name, isPlayer);
				else
					character = new Boyfriend(x, y, characterData.name, isPlayer);

				if(flipX)
					characterData.positionOffset[0] = 0 - characterData.positionOffset[0];

				character.positioningOffset[0] += characterData.positionOffset[0];
				character.positioningOffset[1] += characterData.positionOffset[1];
				
				otherCharacters.push(character);
			}
		}

		if(config.barColor == null)
			config.barColor = [255,0,0];

		barColor = FlxColor.fromRGB(config.barColor[0], config.barColor[1], config.barColor[2]);

		if(config.cameraOffset != null)
		{
			if(flipX)
				config.cameraOffset[0] = 0 - config.cameraOffset[0];

			cameraOffset = config.cameraOffset;
		}

		if(config.deathCharacterName != null)
			deathCharacter = config.deathCharacterName;
		else
			deathCharacter = "bf-dead";
	}

	public function loadOffsetFile(characterName:String)
	{
		animOffsets = new Map<String, Array<Dynamic>>();
		
		var offsets:Array<String>;

		#if sys
		offsets = CoolUtil.coolTextFilePolymod(Paths.txt("character data/" + characterName + "/" + "offsets"));
		#else
		offsets = CoolUtil.coolTextFile(Paths.txt("character data/" + characterName + "/" + "offsets"));
		#end

		for(x in 0...offsets.length)
		{
			var selectedOffset = offsets[x];
			var arrayOffset:Array<String>;
			arrayOffset = selectedOffset.split(" ");

			addOffset(arrayOffset[0], Std.parseInt(arrayOffset[1]), Std.parseInt(arrayOffset[2]));
		}
	}

	public function quickAnimAdd(animName:String, animPrefix:String)
	{
		animation.addByPrefix(animName, animPrefix, 24, false);
	}

	override function update(elapsed:Float)
	{
		if(!debugMode && curCharacter != '')
		{
			if (!isPlayer)
			{
				if (animation.curAnim.name.startsWith('sing'))
				{
					holdTimer += elapsed;
				}

				var dadVar:Float = 4;

				if (curCharacter == 'dad')
					dadVar = 6.1;
				
				if (holdTimer >= Conductor.stepCrochet * dadVar * 0.001)
				{
					dance();
					holdTimer = 0;
				}
			}

			switch (curCharacter)
			{
				case 'gf':
					if (animation.curAnim.name == 'hairFall' && animation.curAnim.finished)
						playAnim('danceRight');
			}
		}

		super.update(elapsed);
	}

	private var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(?altAnim:String = "")
	{
		if (!debugMode && curCharacter != '')
		{
			switch (curCharacter)
			{
				case 'gf' | 'gf-christmas' | 'gf-car' | 'gf-pixel' | 'gf-old' | 'gf-tankmen':
					if (!animation.curAnim.name.startsWith('hair'))
					{
						danced = !danced;

						if (danced)
							playAnim('danceRight' + altAnim);
						else
							playAnim('danceLeft' + altAnim);
					}

				default:
					if(!dancesLeftAndRight)
						playAnim('idle' + altAnim);
					else
					{
						danced = !danced;

						if (danced)
							playAnim('danceRight' + altAnim);
						else
							playAnim('danceLeft' + altAnim);
					}
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);

		if (animOffsets.exists(AnimName))
			offset.set(daOffset[0], daOffset[1]);
		else
			offset.set(0, 0);

		if (curCharacter.startsWith('gf'))
		{
			if (AnimName == 'singLEFT')
			{
				danced = true;
			}
			else if (AnimName == 'singRIGHT')
			{
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
			{
				danced = !danced;
			}
		}
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		if((isPlayer && offsetsFlipWhenPlayer) || (!isPlayer && offsetsFlipWhenEnemy))
			x = 0 - x;

		animOffsets.set(name, [x, y]);
	}
}