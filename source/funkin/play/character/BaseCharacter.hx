package funkin.play.character;

import flixel.math.FlxPoint;
import funkin.modding.events.ScriptEvent;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.play.character.CharacterData.CharacterRenderType;
import funkin.play.stage.Bopper;
import funkin.play.notes.NoteDirection;

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
  public var characterType(default, set):CharacterType = OTHER;

  function set_characterType(value:CharacterType):CharacterType
  {
    return this.characterType = value;
  }

  /**
   * Tracks how long, in seconds, the character has been playing the current `sing` animation.
   * This is used to ensure that characters play the `sing` animations for at least one beat,
   *   preventing them from reverting to the `idle` animation between notes.
   */
  public var holdTimer:Float = 0;

  /**
   * Set to true when the character dead. Part of the handling for death animations.
   */
  public var isDead:Bool = false;

  /**
   * Set to true when the character being used in a special way.
   * This includes the Chart Editor and the Animation Editor.
   *
   * Used by scripts to ensure that they don't try to run code to interact with the stage when the stage doesn't actually exist.
   */
  public var debug:Bool = false;

  /**
   * This character plays a given animation when hitting these specific combo numbers.
   */
  public var comboNoteCounts(default, null):Array<Int>;

  /**
   * This character plays a given animation when dropping combos larger than these numbers.
   */
  public var dropNoteCounts(default, null):Array<Int>;

  @:allow(funkin.ui.debug.anim.DebugBoundingState)
  final _data:CharacterData;
  final singTimeSteps:Float;

  /**
   * The offset between the corner of the sprite and the origin of the sprite (at the character's feet).
   * cornerPosition = stageData - characterOrigin
   */
  public var characterOrigin(get, never):FlxPoint;

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
  public var cornerPosition(get, set):FlxPoint;

  function get_cornerPosition():FlxPoint
  {
    return new FlxPoint(x, y);
  }

  function set_cornerPosition(value:FlxPoint):FlxPoint
  {
    var xDiff:Float = value.x - this.x;
    var yDiff:Float = value.y - this.y;

    this.cameraFocusPoint.x += xDiff;
    this.cameraFocusPoint.y += yDiff;

    super.set_x(value.x);
    super.set_y(value.y);

    return value;
  }

  /**
   * The absolute position of the character's feet, at the bottom-center of the sprite.
   */
  public var feetPosition(get, never):FlxPoint;

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

  /**
   * If the x position changes, other than via changing the animation offset,
   *  then we need to update the camera focus point.
   */
  override function set_x(value:Float):Float
  {
    if (value == this.x) return value;

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
    if (value == this.y) return value;

    var yDiff = value - this.y;
    this.cameraFocusPoint.y += yDiff;

    return super.set_y(value);
  }

  public function new(id:String, renderType:CharacterRenderType)
  {
    super(CharacterDataParser.DEFAULT_DANCEEVERY);

    this.characterId = id;

    ignoreExclusionPref = ["sing"];

    _data = CharacterDataParser.fetchCharacterData(this.characterId);
    if (_data == null)
    {
      throw 'Could not find character data for characterId: $characterId';
    }
    else if (_data.renderType != renderType)
    {
      throw 'Render type mismatch for character ($characterId): expected ${renderType}, got ${_data.renderType}';
    }
    else
    {
      this.characterName = _data.name;
      this.name = _data.name;
      this.danceEvery = _data.danceEvery;
      this.singTimeSteps = _data.singTime;
      this.globalOffsets = _data.offsets;
      this.flipX = _data.flipX;
    }

    shouldBop = false;
  }

  public function getDeathCameraOffsets():Array<Float>
  {
    return _data.death?.cameraOffsets ?? [0.0, 0.0];
  }

  public function getBaseScale():Float
  {
    return _data.scale;
  }

  public function getDeathCameraZoom():Float
  {
    return _data.death?.cameraZoom ?? 1.0;
  }

  public function getDeathPreTransitionDelay():Float
  {
    return _data.death?.preTransitionDelay ?? 0.0;
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
    // Set the x and y to be their original values.
    this.resetPosition();

    this.dance(true); // Force to avoid the old animation playing with the wrong offset at the start of the song.
    // Make sure we are playing the idle animation
    // ...then update the hitbox so that this.width and this.height are correct.
    this.updateHitbox();

    // Reset the camera focus point while we're at it.
    if (resetCamera) this.resetCameraFocusPoint();
  }

  /**
   * Set the character's sprite scale to the appropriate value.
   * @param scale The desired scale.
   */
  public function setScale(scale:Null<Float>):Void
  {
    if (scale == null) scale = 1.0;

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
  var characterCameraOffsets(get, never):Array<Float>;

  function get_characterCameraOffsets():Array<Float>
  {
    return _data.cameraOffsets;
  }

  override function onCreate(event:ScriptEvent):Void
  {
    super.onCreate(event);

    // Make sure we are playing the idle animation...
    this.dance(true);
    // ...then update the hitbox so that this.width and this.height are correct.
    this.updateHitbox();
    // Without the above code, width and height (and therefore character position)
    // will be based on the first animation in the sheet rather than the default animation.

    this.resetCameraFocusPoint();

    // Child class should have created animations by now,
    // so we can query which ones are available.
    this.comboNoteCounts = findCountAnimations('combo'); // example: combo50
    this.dropNoteCounts = findCountAnimations('drop'); // example: drop50
    if (comboNoteCounts.length > 0) trace('Combo note counts: ' + this.comboNoteCounts);
    if (dropNoteCounts.length > 0) trace('Drop note counts: ' + this.dropNoteCounts);

    super.onCreate(event);
  }

  override function onAnimationFinished(animationName:String):Void
  {
    super.onAnimationFinished(animationName);

    // trace('${characterId} has finished animation: ${animationName}');
    if ((animationName.endsWith(Constants.ANIMATION_END_SUFFIX) && !animationName.startsWith('idle') && !animationName.startsWith('dance'))
      || animationName.startsWith('combo')
      || animationName.startsWith('drop'))
    {
      // Force the character to play the idle after the animation ends.
      this.dance(true);
    }
  }

  function resetCameraFocusPoint():Void
  {
    // Calculate the camera focus point
    var charCenterX = this.x + this.width / 2;
    var charCenterY = this.y + this.height / 2;
    this.cameraFocusPoint = new FlxPoint(charCenterX + _data.cameraOffsets[0], charCenterY + _data.cameraOffsets[1]);
  }

  public function getHealthIconId():String
  {
    return _data?.healthIcon?.id ?? Constants.DEFAULT_HEALTH_ICON;
  }

  public function initHealthIcon(isOpponent:Bool):Void
  {
    if (!isOpponent)
    {
      if (PlayState.instance.iconP1 == null)
      {
        trace('[WARN] Player 1 health icon not found!');
        return;
      }
      PlayState.instance.iconP1.configure(_data?.healthIcon);
      PlayState.instance.iconP1.flipX = !PlayState.instance.iconP1.flipX; // BF is looking the other way.
    }
    else
    {
      if (PlayState.instance.iconP2 == null)
      {
        trace('[WARN] Player 2 health icon not found!');
        return;
      }
      PlayState.instance.iconP2.configure(_data?.healthIcon);
    }
  }

  public override function onUpdate(event:UpdateScriptEvent):Void
  {
    super.onUpdate(event);

    // Reset hold timer for each note pressed.
    if (justPressedNote() && this.characterType == BF)
    {
      holdTimer = 0;
    }

    if (isDead)
    {
      // playDeathAnimation();
      return;
    }

    // If there is an animation, and another animation with the same name + "-hold" exists,
    // the second animation will play (and be looped if configured to do so) after the first animation finishes.
    // This is good for characters that need to hold a pose while maintaining an animation, like the parents (this keeps their eyes flickering)
    // and Darnell (this keeps the flame on his lighter flickering).
    // Works for idle, singLEFT/RIGHT/UP/DOWN, alt singing animations, and anything else really.

    if (isAnimationFinished()
      && !getCurrentAnimation().endsWith(Constants.ANIMATION_HOLD_SUFFIX)
      && hasAnimation(getCurrentAnimation() + Constants.ANIMATION_HOLD_SUFFIX))
    {
      playAnimation(getCurrentAnimation() + Constants.ANIMATION_HOLD_SUFFIX);
    }
    else
    {
      if (isAnimationFinished())
      {
        // trace('Not playing hold (${getCurrentAnimation()}) (${isAnimationFinished()}, ${getCurrentAnimation().endsWith(Constants.ANIMATION_HOLD_SUFFIX)}, ${hasAnimation(getCurrentAnimation() + Constants.ANIMATION_HOLD_SUFFIX)})');
      }
    }

    // Handle character note hold time.
    if (isSinging())
    {
      // TODO: Rework this code (and all character animations ugh)
      // such that the hold time is handled by padding frames,
      // and reverting to the idle animation is done when `isAnimationFinished()`.
      // This lets you add frames to the end of the sing animation to ease back into the idle!

      holdTimer += event.elapsed;
      var singTimeSec:Float = singTimeSteps * (Conductor.instance.stepLengthMs / Constants.MS_PER_SEC); // x beats, to ms.

      if (getCurrentAnimation().endsWith('miss')) singTimeSec *= 2; // makes it feel more awkward when you miss???

      // Without this check here, the player character would only play the `sing` animation
      // for one beat, as opposed to holding it as long as the player is holding the button.
      var shouldStopSinging:Bool = (this.characterType == BF) ? !isHoldingNote() : true;

      FlxG.watch.addQuick('singTimeSec-${characterId}', singTimeSec);
      if (holdTimer > singTimeSec && shouldStopSinging)
      {
        // trace('holdTimer reached ${holdTimer}sec (> ${singTimeSec}), stopping sing animation');
        holdTimer = 0;

        var currentAnimation:String = getCurrentAnimation();
        // Strip "-hold" from the end.
        if (currentAnimation.endsWith(Constants.ANIMATION_HOLD_SUFFIX)) currentAnimation = currentAnimation.substring(0,
          currentAnimation.length - Constants.ANIMATION_HOLD_SUFFIX.length);

        var endAnimation:String = currentAnimation + Constants.ANIMATION_END_SUFFIX;
        if (hasAnimation(endAnimation))
        {
          // Play the '-end' animation, if one exists.
          trace('${characterId}: playing ${endAnimation}');
          playAnimation(endAnimation);
        }
        else
        {
          // Play the idle animation.
          dance(true);
        }
      }
    }
    else
    {
      holdTimer = 0;
      // super.onBeatHit handles the regular `dance()` calls.
    }
    FlxG.watch.addQuick('holdTimer-${characterId}', holdTimer);
  }

  public function isSinging():Bool
  {
    var currentAnimation:String = getCurrentAnimation();
    return currentAnimation.startsWith('sing') && !currentAnimation.endsWith(Constants.ANIMATION_END_SUFFIX);
  }

  override function dance(force:Bool = false):Void
  {
    // Prevent default dancing behavior.
    if (isDead) return;

    if (!force)
    {
      // Prevent dancing while a singing animation is playing.
      if (isSinging()) return;

      // Prevent dancing while a non-idle special animation is playing.
      var currentAnimation:String = getCurrentAnimation();
      if (!currentAnimation.startsWith('dance') && !currentAnimation.startsWith('idle') && !isAnimationFinished()) return;
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
        return PlayerSettings.player1.controls.NOTE_LEFT_P
          || PlayerSettings.player1.controls.NOTE_DOWN_P
          || PlayerSettings.player1.controls.NOTE_UP_P
          || PlayerSettings.player1.controls.NOTE_RIGHT_P;
      case 2:
        return PlayerSettings.player2.controls.NOTE_LEFT_P
          || PlayerSettings.player2.controls.NOTE_DOWN_P
          || PlayerSettings.player2.controls.NOTE_UP_P
          || PlayerSettings.player2.controls.NOTE_RIGHT_P;
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
        return PlayerSettings.player1.controls.NOTE_LEFT
          || PlayerSettings.player1.controls.NOTE_DOWN
          || PlayerSettings.player1.controls.NOTE_UP
          || PlayerSettings.player1.controls.NOTE_RIGHT;
      case 2:
        return PlayerSettings.player2.controls.NOTE_LEFT
          || PlayerSettings.player2.controls.NOTE_DOWN
          || PlayerSettings.player2.controls.NOTE_UP
          || PlayerSettings.player2.controls.NOTE_RIGHT;
    }
    return false;
  }

  /**
   * Every time a note is hit, check if the note is from the same strumline.
   * If it is, then play the sing animation.
   */
  public override function onNoteHit(event:HitNoteScriptEvent)
  {
    super.onNoteHit(event);

    // If another script cancelled the event, don't do anything.
    if (event.eventCanceled) return;

    if (event.note.noteData.getMustHitNote() && characterType == BF)
    {
      // If the note is from the same strumline, play the sing animation.
      this.playSingAnimation(event.note.noteData.getDirection(), false);
      holdTimer = 0;
    }
    else if (!event.note.noteData.getMustHitNote() && characterType == DAD)
    {
      // If the note is from the same strumline, play the sing animation.
      this.playSingAnimation(event.note.noteData.getDirection(), false);
      holdTimer = 0;
    }
    else if (characterType == GF && event.note.noteData.getMustHitNote())
    {
      switch (event.judgement)
      {
        case 'sick' | 'good':
          playComboAnimation(event.comboCount);
        default:
          playComboDropAnimation(event.comboCount);
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

    // If another script cancelled the event, don't do anything.
    if (event.eventCanceled) return;

    if (event.note.noteData.getMustHitNote() && characterType == BF)
    {
      // If the note is from the same strumline, play the miss animation.
      this.playSingAnimation(event.note.noteData.getDirection(), true);
    }
    else if (!event.note.noteData.getMustHitNote() && characterType == DAD)
    {
      // If the note is from the same strumline, play the miss animation.
      this.playSingAnimation(event.note.noteData.getDirection(), true);
    }
    else if (event.note.noteData.getMustHitNote() && characterType == GF)
    {
      playComboDropAnimation(event.comboCount);
    }
  }

  public override function onNoteHoldDrop(event:HoldNoteScriptEvent)
  {
    super.onNoteHoldDrop(event);

    // If another script cancelled the event, don't do anything.
    if (event.eventCanceled) return;

    if (event.holdNote.noteData.getMustHitNote() && characterType == BF)
    {
      // If the note is from the same strumline, play the miss animation.
      this.playSingAnimation(event.holdNote.noteData.getDirection(), true);
    }
    else if (!event.holdNote.noteData.getMustHitNote() && characterType == DAD)
    {
      // If the note is from the same strumline, play the miss animation.
      this.playSingAnimation(event.holdNote.noteData.getDirection(), true);
    }
    else if (event.holdNote.noteData.getMustHitNote() && event.isComboBreak && characterType == GF)
    {
      playComboDropAnimation(event.comboCount);
    }
  }

  function playComboAnimation(comboCount:Int):Void
  {
    var comboAnim = 'combo${comboCount}';
    if (hasAnimation(comboAnim))
    {
      trace('Playing GF combo animation: ${comboAnim}');
      this.playAnimation(comboAnim, true, true);
    }
  }

  function playComboDropAnimation(comboCount:Int):Void
  {
    var dropAnim:Null<String> = null;

    // Choose the combo drop anim to play.
    // If there are several (for example, drop10 and drop50) the highest one will be used.
    // If the combo count is too low, no animation will be played.
    for (count in dropNoteCounts)
    {
      if (comboCount >= count)
      {
        dropAnim = 'drop${count}';
      }
    }

    if (dropAnim != null)
    {
      trace('Playing GF combo drop animation: ${dropAnim}');
      this.playAnimation(dropAnim, true, true);
    }
  }

  /**
   * Every time a wrong key is pressed, play the miss animation if we are Boyfriend.
   */
  public override function onNoteGhostMiss(event:GhostMissNoteScriptEvent):Void
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
  public function playSingAnimation(dir:NoteDirection, miss:Bool = false, ?suffix:String = ''):Void
  {
    var anim:String = 'sing${dir.nameUpper}${miss ? 'miss' : ''}${suffix != '' ? '-${suffix}' : ''}';

    // restart even if already playing, because the character might sing the same note twice.
    // trace('Playing ${anim}...');
    playAnimation(anim, true);
  }

  public override function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reversed:Bool = false):Void
  {
    super.playAnimation(name, restart, ignoreOther, reversed);
  }

  public function getDeathQuote():Null<String>
  {
    return null;
  }
}

/**
 * The type of a given character sprite. Defines its default behaviors.
 */
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
   * - When the CPU misses a note (NOTE: This only happens via script, not by default),
   *     plays the appropriate `singDIR-miss` animation until DAD is done singing.
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
