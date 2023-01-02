package funkin.play;

import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import funkin.play.character.CharacterData.CharacterDataParser;
import openfl.utils.Assets;

/**
 * This is a rework of the health icon with the following changes:
 * - The health icon now owns its own state logic. It queries health and updates the sprite itself,
 *   rather than relying on PlayState to command it.
 * - The health icon now supports animations.
 * 	 - The health icon will now search for a SparrowV2 (XML) spritesheet, and use that for rendering if it can.
 * 	 - If it can't find a spritesheet, it will the old format; a two-frame 300x150 image.
 *   - If the spritesheet is found, the health icon will attempt to load and use the following animations as appropriate:
 * 		 - `idle`, `winning`, `losing`, `toWinning`, `fromWinning`, `toLosing`, `fromLosing`
 * - The health icon is now easier to control via scripts.
 * 	 - Set `autoUpdate` to false to prevent the health icon from changing its own animations.
 *   - Once `autoUpdate` is false, you can manually call `playAnimation()` to play a specific animation.
 *     - i.e. `PlayState.instance.iconP1.playAnimation("losing")`
 *   - Scripts can also utilize all functionality that a normal FlxSprite would have access to, such as adding supplimental animations.
 *     - i.e. `PlayState.instance.iconP1.animation.addByPrefix("jumpscare", "jumpscare", 24, false);`
 * @author MasterEric
 */
class HealthIcon extends FlxSprite
{
	/**
	 * The character this icon is representing.
	 * Setting this variable will automatically update the graphic.
	 */
	public var characterId(default, set):String;

	/**
	 * Whether this health icon should automatically update its state based on the character's health.
	 * Note that turning this off means you have to manually do the following:
	 * - Bumping the icon on the beat.
	 * - Switching between winning/losing/idle animations.
	 * - Repositioning the icon as health changes.
	 */
	public var autoUpdate:Bool = true;

	/**
	 * Since the `scale` of the sprite dynamically changes over time,
	 * this value allows you to set a relative scale for the icon.
	 * @default 1x scale = 150px width and height.
	 */
	public var size:FlxPoint = new FlxPoint(1, 1);

	/**
	 * Apply the "bump" animation once every X steps.
	 */
	public var bumpEvery:Int = 4;

	/**
	 * The player the health icon is attached to.
	 */
	var playerId:Int = 0;

	/**
	 * Whether the sprite is pixel art or not.
	 * Calculated when loading an icon.
	 */
	var isPixel:Bool = false;

	/**
	 * Whether this is a legacy icon or not.
	 */
	var isLegacyStyle:Bool = false;

	/**
	 * At this amount of health, play the Winning animation instead of the idle.
	 */
	static final WINNING_THRESHOLD = 0.8 * 2;

	/**
	 * At this amount of health, play the Losing animation instead of the idle.
	 */
	static final LOSING_THRESHOLD = 0.2 * 2;

	/**
	 * The maximum health of the player.
	 */
	static final MAXIMUM_HEALTH = 2;

	/**
	 * The size of a non-pixel icon when using the legacy format.
	 * Remember, modern icons can be any size.
	 */
	public static final HEALTH_ICON_SIZE = 150;

	/**
	 * The size of a pixel icon when using the legacy format.
	 * Remember, modern icons can be any size.
	 */
	static final PIXEL_ICON_SIZE = 32;

	/**
	 * shitty hardcoded value for a specific positioning!!!
	 */
	static final POSITION_OFFSET = 26;

	public function new(char:String = 'bf', playerId:Int = 0)
	{
		super(0, 0);
		this.playerId = playerId;
		this.scrollFactor.set();

		this.characterId = char;

		this.antialiasing = !isPixel;

		initTargetSize();
	}

	function set_characterId(value:String):String
	{
		if (value == characterId)
			return value;

		characterId = value;
		loadCharacter(characterId);
		return value;
	}

	/**
	 * Easter egg; press 9 in the PlayState to use the old player icon.
	 */
	public function toggleOldIcon():Void
	{
		if (characterId == 'bf-old')
		{
			characterId = PlayState.currentSong.player1;
		}
		else
		{
			characterId = 'bf-old';
		}
	}

	/**
	 * Called by Flixel every frame. Includes logic to manage the currently playing animation.
	 */
	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// Auto-update the state of the icon based on the player's health.
		// Make sure this is false if the health icon is not being used in the PlayState.
		if (autoUpdate && PlayState.instance != null)
		{
			switch (playerId)
			{
				case 0: // Boyfriend
					// Update the animation based on the current state.
					updateHealthIcon(PlayState.instance.health);
					// Update the position to match the health bar.
					this.x = PlayState.instance.healthBar.x
						+ (PlayState.instance.healthBar.width * (FlxMath.remapToRange(PlayState.instance.healthBar.value, 0, 2, 100, 0) * 0.01)
							- POSITION_OFFSET);
				case 1: // Dad
					// Update the animation based on the current state.
					updateHealthIcon(MAXIMUM_HEALTH - PlayState.instance.health);
					// Update the position to match the health bar.
					this.x = PlayState.instance.healthBar.x
						+ (PlayState.instance.healthBar.width * (FlxMath.remapToRange(PlayState.instance.healthBar.value, 0, 2, 100, 0) * 0.01))
						- (this.width - POSITION_OFFSET);
			}
		}

		if (bumpEvery != 0)
		{
			// Lerp the health icon back to its normal size,
			// while maintaining aspect ratio.
			if (this.width > this.height)
			{
				// Apply linear interpolation while accounting for frame rate.
				var targetSize = Std.int(CoolUtil.coolLerp(this.width, HEALTH_ICON_SIZE * this.size.x, 0.15));

				setGraphicSize(targetSize, 0);
			}
			else
			{
				var targetSize = Std.int(CoolUtil.coolLerp(this.height, HEALTH_ICON_SIZE * this.size.y, 0.15));

				setGraphicSize(0, targetSize);
			}
			this.updateHitbox();
		}
	}

	public function onStepHit(curStep:Int)
	{
		if (bumpEvery != 0 && curStep % bumpEvery == 0 && isLegacyStyle)
		{
			// Make the health icons bump (the update function causes them to lerp back down).
			if (this.width > this.height)
			{
				setGraphicSize(Std.int(this.width + (HEALTH_ICON_SIZE * this.size.x * 0.2)), 0);
			}
			else
			{
				setGraphicSize(0, Std.int(this.height + (HEALTH_ICON_SIZE * this.size.y * 0.2)));
			}
			this.updateHitbox();
		}
	}

	inline function initTargetSize()
	{
		setGraphicSize(HEALTH_ICON_SIZE);
		updateHitbox();
	}

	function updateHealthIcon(health:Float)
	{
		// We want to efficiently handle animation playback

		// Here, we use the current animation name to track the current state
		// of a simple state machine. Neat!

		switch (getCurrentAnimation())
		{
			case IDLE:
				if (health < LOSING_THRESHOLD)
					playAnimation(TO_LOSING, LOSING);
				else if (health > WINNING_THRESHOLD)
					playAnimation(TO_WINNING, WINNING);
				else
					playAnimation(IDLE);
			case WINNING:
				if (health < WINNING_THRESHOLD)
					playAnimation(FROM_WINNING, IDLE);
				else
					playAnimation(WINNING, IDLE);
			case LOSING:
				if (health > LOSING_THRESHOLD)
					playAnimation(FROM_LOSING, IDLE);
				else
					playAnimation(LOSING, IDLE);
			case TO_LOSING:
				if (isAnimationFinished())
					playAnimation(LOSING, IDLE);
			case TO_WINNING:
				if (isAnimationFinished())
					playAnimation(WINNING, IDLE);
			case FROM_LOSING | FROM_WINNING:
				if (isAnimationFinished())
					playAnimation(IDLE);
			case "":
				playAnimation(IDLE);
			default:
				playAnimation(IDLE);
		}
	}

	/**
	 * Load
	 * @param charId 
	 */
	function loadAnimationNew(charId:String):Void
	{
		this.animation.addByPrefix(IDLE, IDLE, 24, true);
		this.animation.addByPrefix(WINNING, WINNING, 24, true);
		this.animation.addByPrefix(LOSING, LOSING, 24, true);
		this.animation.addByPrefix(TO_WINNING, TO_WINNING, 24, true);
		this.animation.addByPrefix(TO_LOSING, TO_LOSING, 24, true);
		this.animation.addByPrefix(FROM_WINNING, FROM_WINNING, 24, true);
		this.animation.addByPrefix(FROM_LOSING, FROM_LOSING, 24, true);
	}

	/**
	 * Load health icon animations using the legacy format.
	 * Simply assumes two icons, one on 
	 * @param charId 
	 */
	function loadAnimationOld(charId:String):Void
	{
		this.animation.add(IDLE, [0], 0, false, this.playerId == 0);
		this.animation.add(LOSING, [1], 0, false, this.playerId == 0);
	}

	function correctCharacterId(charId:String):String
	{
		if (!Assets.exists(Paths.image('icons/icon-$charId')))
		{
			FlxG.log.warn('No icon for character: $charId : using default placeholder face instead!');
			return "face";
		}

		return charId;
	}

	function isNewSpritesheet(charId:String):Bool
	{
		return Assets.exists(Paths.file('images/icons/icon-$characterId.xml'));
	}

	function fetchIsPixel(charId:String):Bool
	{
		var charData = CharacterDataParser.fetchCharacterData(charId);
		if (charData == null)
		{
			FlxG.log.warn('No character data found for character: $charId');
			return false;
		}
		return charData.isPixel;
	}

	function loadCharacter(charId:String):Void
	{
		if (correctCharacterId(charId) != charId)
		{
			characterId = correctCharacterId(charId);
			return;
		}

		isPixel = fetchIsPixel(charId);

		isLegacyStyle = !isNewSpritesheet(charId);

		if (!isLegacyStyle)
		{
			frames = Paths.getSparrowAtlas('icons/icon-$charId');

			loadAnimationNew(charId);
		}
		else
		{
			loadGraphic(Paths.image('icons/icon-$charId'), true, isPixel ? PIXEL_ICON_SIZE : HEALTH_ICON_SIZE, isPixel ? PIXEL_ICON_SIZE : HEALTH_ICON_SIZE);

			loadAnimationOld(charId);
		}
	}

	/**
	 * @return Name of the current animation being played by this health icon.
	 */
	public function getCurrentAnimation():String
	{
		if (this.animation == null || this.animation.curAnim == null)
			return "";
		return this.animation.curAnim.name;
	}

	/**
	 * @return Whether this sprite posesses the given animation.
	 *   Only true if the animation was successfully loaded from the XML.
	 */
	public function hasAnimation(id:String):Bool
	{
		if (this.animation == null)
			return false;

		return this.animation.getByName(id) != null;
	}

	/**
	 * @return Whether the current animation is in the finished state.
	 */
	public function isAnimationFinished():Bool
	{
		return this.animation.finished;
	}

	/**
	 * Plays the animation with the given name.
	 * @param name The name of the animation to play.
	 * @param fallback The fallback animation to play if the given animation is not found.
	 * @param restart Whether to forcibly restart the animation if it is already playing.
	 */
	public function playAnimation(name:String, fallback:String = null, restart = false):Void
	{
		// Attempt to play the animation
		if (hasAnimation(name))
		{
			this.animation.play(name, restart, false, 0);
			return;
		}

		// Play the fallback animation if the requested animation was not found
		if (fallback != null && hasAnimation(fallback))
		{
			this.animation.play(fallback, restart, false, 0);
			return;
		}

		// If we don't have an animation, we're done.
	}
}

enum abstract HealthIconState(String) to String from String
{
	/**
	 * Indicates the health icon is in the default animation.
	 * Plays as long as health is between 20% and 80%.
	 */
	var IDLE = "idle";

	/**
	 * Indicates the health icon is playing the Winning animation.
	 * Plays as long as health is above 80%.
	 */
	var WINNING = "winning";

	/**
	 * Indicates the health icon is playing the Losing animation.
	 * Plays as long as health is below 20%.
	 */
	var LOSING = "losing";

	/**
	 * Indicates that the health icon is transitioning between `idle` and `winning`.
	 * The next animation will play once the current animation finishes.
	 */
	var TO_WINNING = "toWinning";

	/**
	 * Indicates that the health icon is transitioning between `idle` and `losing`.
	 * The next animation will play once the current animation finishes.
	 */
	var TO_LOSING = "toLosing";

	/**
	 * Indicates that the health icon is transitioning between `winning` and `idle`.
	 * The next animation will play once the current animation finishes.
	 */
	var FROM_WINNING = "fromWinning";

	/**
	 * Indicates that the health icon is transitioning between `losing` and `idle`.
	 * The next animation will play once the current animation finishes.
	 */
	var FROM_LOSING = "fromLosing";
}
