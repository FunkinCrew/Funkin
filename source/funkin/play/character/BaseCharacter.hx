package funkin.play.character;

import flixel.math.FlxPoint;
import funkin.Note.NoteDir;
import funkin.modding.events.ScriptEvent;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.play.stage.Bopper;

using StringTools;

/**
 * A Character is a stage prop which bops to the music as well as controlled by the strumlines.
 * 
 * Remember: The character's origin is at its FEET. (horizontal center, vertical bottom)
 */
class BaseCharacter extends Bopper
{
	// Metadata about a character.
	public var characterId(default, null):String;
	public var characterName(default, null):String;

	/**
	 * Whether the player is an active character (Boyfriend) or not.
	 */
	public var characterType:CharacterType = OTHER;

	/**
	 * Tracks how long, in seconds, the character has been playing the current `sing` animation.
	 * This is used to ensure that characters play the `sing` animations for at least one beat,
	 *   preventing them from reverting to the `idle` animation between notes.
	 */
	public var holdTimer:Float = 0;

	public var isDead:Bool = false;
	public var debugMode:Bool = false;

	/**
	 * This character plays a given animation when hitting these specific combo numbers.
	 */
	public var comboNoteCounts(default, null):Array<Int>;

	/**
	 * This character plays a given animation when dropping combos larger than these numbers.
	 */
	public var dropNoteCounts(default, null):Array<Int>;

	final _data:CharacterData;
	final singTimeCrochet:Float;

	/**
	 * The offset between the corner of the sprite and the origin of the sprite (at the character's feet).
	 * cornerPosition = stageData - characterOrigin
	 */
	public var characterOrigin(get, null):FlxPoint;

	function get_characterOrigin():FlxPoint
	{
		var xPos = (width / 2); // Horizontal center
		var yPos = (height); // Vertical bottom
		return new FlxPoint(xPos, yPos);
	}

	/**
	 * The absolute position of the top-left of the character.
	 * @return 
	 */
	public var cornerPosition(get, null):FlxPoint;

	function get_cornerPosition():FlxPoint
	{
		return new FlxPoint(x, y);
	}

	/**
	 * The absolute position of the character's feet, at the bottom-center of the sprite.
	 */
	public var feetPosition(get, null):FlxPoint;

	function get_feetPosition():FlxPoint
	{
		return new FlxPoint(x + characterOrigin.x, y + characterOrigin.y);
	}

	/**
	 * Returns the point the camera should focus on.
	 * Should be approximately centered on the character, and should not move based on the current animation.
	 * 
	 * Set the position of this rather than reassigning it, so that anything referencing it will not be affected.
	 */
	public var cameraFocusPoint(default, null):FlxPoint = new FlxPoint(0, 0);

	override function set_animOffsets(value:Array<Float>)
	{
		if (animOffsets == null)
			value = [0, 0];
		if (animOffsets == value)
			return value;

		var xDiff = animOffsets[0] - value[0];
		var yDiff = animOffsets[1] - value[1];

		// Call the super function so that camera focus point is not affected.
		super.set_x(this.x + xDiff);
		super.set_y(this.y + yDiff);

		return animOffsets = value;
	}

	/**
	 * If the x position changes, other than via changing the animation offset,
	 *  then we need to update the camera focus point.
	 */
	override function set_x(value:Float):Float
	{
		if (value == this.x)
			return value;

		var xDiff = value - this.x;
		this.cameraFocusPoint.x += xDiff;

		return super.set_x(value);
	}

	/**
	 * If the y position changes, other than via changing the animation offset,
	 *  then we need to update the camera focus point.
	 */
	override function set_y(value:Float):Float
	{
		if (value == this.y)
			return value;

		var yDiff = value - this.y;
		this.cameraFocusPoint.y += yDiff;

		return super.set_y(value);
	}

	public function new(id:String)
	{
		super();
		this.characterId = id;

		_data = CharacterDataParser.fetchCharacterData(this.characterId);
		if (_data == null)
		{
			throw 'Could not find character data for characterId: $characterId';
		}
		else
		{
			this.characterName = _data.name;
			this.singTimeCrochet = _data.singTime;
			this.globalOffsets = _data.offsets;
			this.flipX = _data.flipX;
		}

		shouldBop = false;
	}

	/**
	 * Gets the value of flipX from the character data.
	 * `!getFlipX()` is the direction Boyfriend should face.
	 */
	public function getDataFlipX():Bool
	{
		return _data.flipX;
	}

	function findCountAnimations(prefix:String):Array<Int>
	{
		var animNames:Array<String> = this.animation.getNameList();

		var result:Array<Int> = [];

		for (anim in animNames)
		{
			if (anim.startsWith(prefix))
			{
				var comboNum:Null<Int> = Std.parseInt(anim.substring(prefix.length));
				if (comboNum != null)
				{
					result.push(comboNum);
				}
			}
		}

		// Sort numerically.
		result.sort((a, b) -> a - b);
		return result;
	}

	/**
	 * Reset the character so it can be used at the start of the level.
	 * Call this when restarting the level.
	 */
	public function resetCharacter(resetCamera:Bool = true):Void
	{
		// Reset the animation offsets. This will modify x and y to be the absolute position of the character.
		this.animOffsets = [0, 0];

		// Now we can set the x and y to be their original values without having to account for animOffsets.
		this.resetPosition();

		// Make sure we are playing the idle animation (to reapply animOffsets)...
		this.dance(true); // Force to avoid the old animation playing with the wrong offset at the start of the song.
		// ...then update the hitbox so that this.width and this.height are correct.
		this.updateHitbox();

		// Reset the camera focus point while we're at it.
		if (resetCamera)
			this.resetCameraFocusPoint();
	}

	/**
	 * Set the sprite scale to the appropriate value.
	 * @param scale 
	 */
	function setScale(scale:Null<Float>):Void
	{
		if (scale == null)
			scale = 1.0;

		var feetPos:FlxPoint = feetPosition;
		this.scale.x = scale;
		this.scale.y = scale;
		this.updateHitbox();
		// Reposition with newly scaled sprite.
		this.x = feetPos.x - characterOrigin.x + globalOffsets[0];
		this.y = feetPos.y - characterOrigin.y + globalOffsets[1];
	}

	/**
	 * The per-character camera offset.
	 */
	var characterCameraOffsets(get, null):Array<Float>;

	function get_characterCameraOffsets():Array<Float>
	{
		return _data.cameraOffsets;
	}

	override function onCreate(event:ScriptEvent):Void
	{
		// Make sure we are playing the idle animation...
		this.dance();
		// ...then update the hitbox so that this.width and this.height are correct.
		this.updateHitbox();
		// Without the above code, width and height (and therefore character position)
		// will be based on the first animation in the sheet rather than the default animation.

		this.resetCameraFocusPoint();

		// Child class should have created animations by now,
		// so we can query which ones are available.
		this.comboNoteCounts = findCountAnimations('combo'); // example: combo50
		this.dropNoteCounts = findCountAnimations('drop'); // example: drop50
		// trace('${this.animation.getNameList()}');
		// trace('Combo note counts: ' + this.comboNoteCounts);
		// trace('Drop note counts: ' + this.dropNoteCounts);

		super.onCreate(event);
	}

	function resetCameraFocusPoint():Void
	{
		// Calculate the camera focus point
		var charCenterX = this.x + this.width / 2;
		var charCenterY = this.y + this.height / 2;
		this.cameraFocusPoint = new FlxPoint(charCenterX + _data.cameraOffsets[0], charCenterY + _data.cameraOffsets[1]);
	}

	public function initHealthIcon(isOpponent:Bool):Void
	{
		if (!isOpponent)
		{
			PlayState.instance.iconP1.characterId = _data.healthIcon.id;
			PlayState.instance.iconP1.size.set(_data.healthIcon.scale, _data.healthIcon.scale);
			PlayState.instance.iconP1.offset.x = _data.healthIcon.offsets[0];
			PlayState.instance.iconP1.offset.y = _data.healthIcon.offsets[1];
			PlayState.instance.iconP1.flipX = !_data.healthIcon.flipX;
		}
		else
		{
			PlayState.instance.iconP2.characterId = _data.healthIcon.id;
			PlayState.instance.iconP2.size.set(_data.healthIcon.scale, _data.healthIcon.scale);
			PlayState.instance.iconP2.offset.x = _data.healthIcon.offsets[0];
			PlayState.instance.iconP2.offset.y = _data.healthIcon.offsets[1];
			PlayState.instance.iconP1.flipX = _data.healthIcon.flipX;
		}
	}

	public override function onUpdate(event:UpdateScriptEvent):Void
	{
		super.onUpdate(event);

		// Reset hold timer for each note pressed.
		if (justPressedNote())
		{
			holdTimer = 0;
		}

		if (isDead)
		{
			playDeathAnimation();
			return;
		}

		if (hasAnimation('idle-hold') && getCurrentAnimation() == "idle" && isAnimationFinished())
			playAnimation('idle-hold');
		if (hasAnimation('singLEFT-hold') && getCurrentAnimation() == "singLEFT" && isAnimationFinished())
			playAnimation('singLEFT-hold');
		if (hasAnimation('singDOWN-hold') && getCurrentAnimation() == "singDOWN" && isAnimationFinished())
			playAnimation('singDOWN-hold');
		if (hasAnimation('singUP-hold') && getCurrentAnimation() == "singUP" && isAnimationFinished())
			playAnimation('singUP-hold');
		if (hasAnimation('singRIGHT-hold') && getCurrentAnimation() == "singRIGHT" && isAnimationFinished())
			playAnimation('singRIGHT-hold');

		// Handle character note hold time.
		if (getCurrentAnimation().startsWith("sing"))
		{
			// TODO: Rework this code (and all character animations ugh)
			// such that the hold time is handled by padding frames,
			// and reverting to the idle animation is done when `isAnimationFinished()`.
			// This lets you add frames to the end of the sing animation to ease back into the idle!

			holdTimer += event.elapsed;
			var singTimeMs:Float = singTimeCrochet * (Conductor.crochet * 0.001); // x beats, to ms.
			// Without this check here, the player character would only play the `sing` animation
			// for one beat, as opposed to holding it as long as the player is holding the button.
			var shouldStopSinging:Bool = (this.characterType == BF) ? !isHoldingNote() : true;

			FlxG.watch.addQuick('singTimeMs-${characterId}', singTimeMs);
			if (holdTimer > singTimeMs && shouldStopSinging) //  && !getCurrentAnimation().endsWith("miss")
			{
				// trace('holdTimer reached ${holdTimer}sec (> ${singTimeMs}), stopping sing animation');
				holdTimer = 0;
				dance(true);
			}
		}
		else
		{
			holdTimer = 0;
			// super.onBeatHit handles the regular `dance()` calls.
		}
		FlxG.watch.addQuick('holdTimer-${characterId}', holdTimer);
	}

	/**
	 * Since no `onBeatHit` or `dance` calls happen in GameOverSubstate,
	 * this regularly gets called instead.
	 */
	public function playDeathAnimation(force:Bool = false):Void
	{
		if (force || (getCurrentAnimation().startsWith("firstDeath") && isAnimationFinished()))
		{
			playAnimation("deathLoop" + GameOverSubstate.animationSuffix);
		}
	}

	override function dance(force:Bool = false)
	{
		// Prevent default dancing behavior.
		if (debugMode)
			return;

		if (isDead)
			return;

		if (!force)
		{
			if (getCurrentAnimation().startsWith("sing"))
			{
				return;
			}
			if (["hey", "cheer"].contains(getCurrentAnimation()) && !isAnimationFinished())
			{
				return;
			}
		}

		// Prevent dancing while another animation is playing.
		if (!force && getCurrentAnimation().startsWith("sing"))
		{
			return;
		}

		// Otherwise, fallback to the super dance() method, which handles playing the idle animation.
		super.dance();
	}

	/**
	 * Returns true if the player just pressed a note.
	 * Used when determing whether a the player character should revert to the `idle` animation.
	 * On non-player characters, this should be ignored.
	 */
	function justPressedNote(player:Int = 1):Bool
	{
		// Returns true if at least one of LEFT, DOWN, UP, or RIGHT is being held.
		switch (player)
		{
			case 1:
				return [
					PlayerSettings.player1.controls.NOTE_LEFT_P,
					PlayerSettings.player1.controls.NOTE_DOWN_P,
					PlayerSettings.player1.controls.NOTE_UP_P,
					PlayerSettings.player1.controls.NOTE_RIGHT_P,
				].contains(true);
			case 2:
				return [
					PlayerSettings.player2.controls.NOTE_LEFT_P,
					PlayerSettings.player2.controls.NOTE_DOWN_P,
					PlayerSettings.player2.controls.NOTE_UP_P,
					PlayerSettings.player2.controls.NOTE_RIGHT_P,
				].contains(true);
		}
		return false;
	}

	/**
	 * Returns true if the player is holding a note.
	 * Used when determing whether a the player character should revert to the `idle` animation.
	 * On non-player characters, this should be ignored.
	 */
	function isHoldingNote(player:Int = 1):Bool
	{
		// Returns true if at least one of LEFT, DOWN, UP, or RIGHT is being held.
		switch (player)
		{
			case 1:
				return [
					PlayerSettings.player1.controls.NOTE_LEFT,
					PlayerSettings.player1.controls.NOTE_DOWN,
					PlayerSettings.player1.controls.NOTE_UP,
					PlayerSettings.player1.controls.NOTE_RIGHT,
				].contains(true);
			case 2:
				return [
					PlayerSettings.player2.controls.NOTE_LEFT,
					PlayerSettings.player2.controls.NOTE_DOWN,
					PlayerSettings.player2.controls.NOTE_UP,
					PlayerSettings.player2.controls.NOTE_RIGHT,
				].contains(true);
		}
		return false;
	}

	/**
	 * Every time a note is hit, check if the note is from the same strumline.
	 * If it is, then play the sing animation.
	 */
	public override function onNoteHit(event:NoteScriptEvent)
	{
		super.onNoteHit(event);

		holdTimer = 0;

		if (event.note.mustPress && characterType == BF)
		{
			// If the note is from the same strumline, play the sing animation.
			this.playSingAnimation(event.note.data.dir, false);
		}
		else if (!event.note.mustPress && characterType == DAD)
		{
			// If the note is from the same strumline, play the sing animation.
			this.playSingAnimation(event.note.data.dir, false);
		}
		else if (characterType == GF)
		{
			if (event.note.mustPress && this.comboNoteCounts.contains(event.comboCount))
			{
				trace('Playing GF combo animation: combo${event.comboCount}');
				this.playAnimation('combo${event.comboCount}', true, true);
			}
		}
	}

	/**
	 * Every time a note is missed, check if the note is from the same strumline.
	 * If it is, then play the sing animation.
	 */
	public override function onNoteMiss(event:NoteScriptEvent)
	{
		super.onNoteMiss(event);

		if (event.note.mustPress && characterType == BF)
		{
			// If the note is from the same strumline, play the sing animation.
			this.playSingAnimation(event.note.data.dir, true);
		}
		else if (!event.note.mustPress && characterType == DAD)
		{
			// If the note is from the same strumline, play the sing animation.
			this.playSingAnimation(event.note.data.dir, true);
		}
		else if (event.note.mustPress && characterType == GF)
		{
			var dropAnim = '';

			// Choose the combo drop anim to play.
			// If there are several (for example, drop10 and drop50) the highest one will be used.
			// If the combo count is too low, no animation will be played.
			for (count in dropNoteCounts)
			{
				if (event.comboCount >= count)
				{
					dropAnim = 'drop${count}';
				}
			}

			if (dropAnim != '')
			{
				trace('Playing GF combo drop animation: ${dropAnim}');
				this.playAnimation(dropAnim, true, true);
			}
		}
	}

	/**
	 * Every time a wrong key is pressed, play the miss animation if we are Boyfriend.
	 */
	public override function onNoteGhostMiss(event:GhostMissNoteScriptEvent)
	{
		super.onNoteGhostMiss(event);

		if (event.eventCanceled || !event.playAnim)
		{
			// Skipping...
			return;
		}

		if (characterType == BF)
		{
			// If the note is from the same strumline, play the sing animation.
			// trace('Playing ghost miss animation...');
			this.playSingAnimation(event.dir, true);
		}
	}

	public override function onDestroy(event:ScriptEvent):Void
	{
		this.characterType = OTHER;
	}

	/**
	 * Play the appropriate singing animation, for the given note direction.
	 * @param dir The direction of the note.
	 * @param miss If true, play the miss animation instead of the sing animation.
	 * @param suffix A suffix to append to the animation name, like `alt`.
	 */
	public function playSingAnimation(dir:NoteDir, miss:Bool = false, suffix:String = ""):Void
	{
		var anim:String = 'sing${dir.nameUpper}${miss ? 'miss' : ''}${suffix != "" ? '-${suffix}' : ''}';

		// restart even if already playing, because the character might sing the same note twice.
		playAnimation(anim, true);
	}
}

enum CharacterType
{
	/**
	 * The BF character has the following behaviors.
	 * - At idle, dances with `danceLeft` and `danceRight` if available, or `idle` if not.
	 * - When the player hits a note, plays the appropriate `singDIR` animation until BF is done singing.
	 * - If there is a `singDIR-end` animation, the `singDIR` animation will play once before looping the `singDIR-end` animation until BF is done singing.
	 * - If the player misses or hits a ghost note, plays the appropriate `singDIR-miss` animation until BF is done singing.
	 */
	BF;

	/**
	 * The DAD character has the following behaviors.
	 * - At idle, dances with `danceLeft` and `danceRight` if available, or `idle` if not.
	 * - When the CPU hits a note, plays the appropriate `singDIR` animation until DAD is done singing.
	 * - If there is a `singDIR-end` animation, the `singDIR` animation will play once before looping the `singDIR-end` animation until DAD is done singing.
	 * - When the CPU misses a note (NOTE: This only happens via script, not by default), plays the appropriate `singDIR-miss` animation until DAD is done singing.
	 */
	DAD;

	/**
	 * The GF character has the following behaviors.
	 * - At idle, dances with `danceLeft` and `danceRight` if available, or `idle` if not.
	 * - If available, `combo###` animations will play when certain combo counts are reached.
	 *   - For example, `combo50` will play when the player hits 50 notes in a row.
	 *   - Multiple combo animations can be provided for different thresholds.
	 * - If available, `drop###` animations will play when combos are dropped above certain thresholds.
	 *   - For example, `drop10` will play when the player drops a combo larger than 10.
	 *   - Multiple drop animations can be provided for different thresholds (i.e. dropping larger combos).
	 *   - No drop animation will play if one isn't applicable (i.e. if the combo count is too low).
	 */
	GF;

	/**
	 * The OTHER character will only perform the `danceLeft`/`danceRight` or `idle` animation by default, depending on what's available.
	 * Additional behaviors can be performed via scripts.
	 */
	OTHER;
}
