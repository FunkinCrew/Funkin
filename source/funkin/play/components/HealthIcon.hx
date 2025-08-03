package funkin.play.components;

import funkin.play.character.CharacterData;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.graphics.FunkinSprite;
import funkin.util.MathUtil;

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
 * @author EliteMasterEric
 */
@:nullSafety
class HealthIcon extends FunkinSprite
{
  /**
   * The character this icon is representing.
   * Setting this variable will automatically update the graphic.
   */
  public var characterId(default, set):String = Constants.DEFAULT_HEALTH_ICON;

  /**
   * Whether this health icon should automatically update its state based on the character's health.
   * Note that turning this off means you have to manually do the following:
   * - Boping the icon on the beat.
   * - Switching between winning/losing/idle animations.
   * - Repositioning the icon as health changes.
   */
  public var autoUpdate:Bool = true;

  /**
   * Since the `scale` of the sprite dynamically changes over time,
   * this value allows you to set a relative scale for the icon.
   * @default 1x scale = 150px width and height.
   */
  public var size:FlxPoint;

  /**
   * Apply the "bop" animation once every X steps.
   * Defaults to once per beat.
   */
  public var bopEvery:Int = Constants.STEPS_PER_BEAT;

  /**
   * The amount, in degrees, to rotate the icon by when boping.
   * ERIC NOTE: I experimented with this a bit but ended up turning it off,
   * but why not leave it in for the script kiddies?
   */
  public var bopAngle:Float = 0.0;

  /**
   * The player the health icon is attached to.
   */
  var playerId:Int = 0;

  /**
   * Whether the sprite is pixel art or not.
   */
  public var isPixel(default, set):Bool = false;

  /**
   * Whether this is a legacy icon or not.
   */
  var isLegacyStyle:Bool = false;

  /**
   * At this amount of health, play the Winning animation instead of the idle.
   */
  static final WINNING_THRESHOLD:Float = 0.8 * 2;

  /**
   * At this amount of health, play the Losing animation instead of the idle.
   */
  static final LOSING_THRESHOLD:Float = 0.2 * 2;

  /**
   * The maximum health of the player.
   */
  static final MAXIMUM_HEALTH:Float = 2;

  /**
   * The size of a non-pixel icon when using the legacy format.
   * Remember, modern icons can be any size.
   */
  public static final HEALTH_ICON_SIZE:Int = 150;

  /**
   * The size of a pixel icon when using the legacy format.
   * Remember, modern icons can be any size.
   */
  static final PIXEL_ICON_SIZE:Int = 32;

  /**
   * The amount, in percent, to scale the icon by when bopping.
   */
  static final BOP_SCALE:Float = 0.2;

  /**
   * shitty hardcoded value for a specific positioning!!!
   */
  static final POSITION_OFFSET:Int = 26;

  public function new(char:Null<String>, playerId:Int = 0)
  {
    super(0, 0);
    this.playerId = playerId;
    this.size = new FlxCallbackPoint(onSetSize);
    this.scrollFactor.set();
    size.set(1.0, 1.0);
    this.characterId = char;
  }

  function onSetSize(value:FlxPoint):Void
  {
    snapToTargetSize();
  }

  function set_characterId(value:Null<String>):String
  {
    if (value == characterId) return value;

    characterId = value ?? Constants.DEFAULT_HEALTH_ICON;
    return characterId;
  }

  function set_isPixel(value:Bool):Bool
  {
    if (value == isPixel) return value;

    isPixel = value;
    return isPixel;
  }

  /**
   * Easter egg; press 9 in the PlayState to use the old player icon.
   */
  public function toggleOldIcon():Void
  {
    if (characterId == 'bf-old')
    {
      isPixel = PlayState.instance.currentStage.getBoyfriend().isPixel;
      PlayState.instance.currentStage.getBoyfriend().initHealthIcon(false);
    }
    else
    {
      characterId = 'bf-old';
      isPixel = false;
      loadCharacter(characterId);
    }

    lerpIconSize(true);
  }

  /**
   * Use the provided CharacterHealthIconData to configure this health icon's appearance.
   * @param data The data to use to configure this health icon.
   */
  public function configure(data:Null<HealthIconData>):Void
  {
    if (data == null)
    {
      this.characterId = Constants.DEFAULT_HEALTH_ICON;
      this.isPixel = false;

      loadCharacter(characterId);

      this.size.set(1.0, 1.0);
      this.offset.x = 0.0;
      this.offset.y = 0.0;
      this.flipX = false;
    }
    else
    {
      this.characterId = data.id;
      this.isPixel = data.isPixel ?? false;

      loadCharacter(characterId);

      this.size.set(data.scale ?? 1.0, data.scale ?? 1.0);
      this.offset.x = (data.offsets != null) ? data.offsets[0] : 0.0;
      this.offset.y = (data.offsets != null) ? data.offsets[1] : 0.0;
      this.flipX = data.flipX ?? false; // Face the OTHER way by default, since that is more common.
    }
  }

  /**
   * Called by Flixel every frame. Includes logic to manage the currently playing animation.
   */
  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (bopEvery != 0)
    {
      lerpIconSize();

      // Lerp the health icon back to its normal angle.
      this.angle = MathUtil.smoothLerpPrecision(this.angle, 0, elapsed, 0.512);
    }

    this.updatePosition();
  }

  /**
   * Does the calculation to lerp the icon size. Usually called every frame, but can be forced to the target size.
   * Mainly forced when changing to old icon to not have a weird lerp related to changing from pixel icon to non-pixel old icon
   * @param force Force the icon immedialtely to be the target size. Defaults to false.
   */
  function lerpIconSize(force:Bool = false):Void
  {
    // Lerp the health icon back to its normal size,
    // while maintaining aspect ratio.
    if (this.width > this.height)
    {
      // Apply linear interpolation while accounting for frame rate.
      var targetSize:Int = Std.int(MathUtil.smoothLerpPrecision(this.width, HEALTH_ICON_SIZE * this.size.x, FlxG.elapsed, 0.512));

      if (force) targetSize = Std.int(HEALTH_ICON_SIZE * this.size.x);

      setGraphicSize(targetSize, 0);
    }
    else
    {
      var targetSize:Int = Std.int(MathUtil.smoothLerpPrecision(this.height, HEALTH_ICON_SIZE * this.size.y, FlxG.elapsed, 0.512));

      if (force) targetSize = Std.int(HEALTH_ICON_SIZE * this.size.y);

      setGraphicSize(0, targetSize);
    }

    this.updateHitbox();
  }

  /*
   * Immediately snap the health icon to its target size without lerping.
   */
  public function snapToTargetSize():Void
  {
    if (this.width > this.height)
    {
      setGraphicSize(Std.int(HEALTH_ICON_SIZE * this.size.x), 0);
    }
    else
    {
      setGraphicSize(0, Std.int(HEALTH_ICON_SIZE * this.size.y));
    }
    updateHitbox();
  }

  /**
   * Update the position (and status) of the health icon.
   */
  public function updatePosition():Void
  {
    // Make sure autoUpdate is false if the health icon is not being used in the PlayState.
    if (autoUpdate && PlayState.instance != null)
    {
      switch (playerId)
      {
        case 0: // Boyfriend
          // Update the animation based on the current state.
          updateHealthIcon(PlayState.instance.health);
          // Update the position to match the health bar.
          this.x = PlayState.instance.healthBar.x
            + (PlayState.instance.healthBar.width * (FlxMath.remapToRange(PlayState.instance.healthBar.value, 0, 2, 100, 0) * 0.01) - POSITION_OFFSET);
        case 1: // Dad
          // Update the animation based on the current state.
          updateHealthIcon(MAXIMUM_HEALTH - PlayState.instance.health);
          // Update the position to match the health bar.
          this.x = PlayState.instance.healthBar.x
            + (PlayState.instance.healthBar.width * (FlxMath.remapToRange(PlayState.instance.healthBar.value, 0, 2, 100, 0) * 0.01))
            - (this.width - POSITION_OFFSET);
      }

      // Keep the icon centered vertically on the health bar.
      this.y = PlayState.instance.healthBar.y - (this.height / 2); // - (PlayState.instance.healthBar.height / 2)
    }
  }

  /**
   * Called on every step.
   * @param curStep The current step number.
   */
  public function onStepHit(curStep:Int):Void
  {
    // Make the icons bop.
    if (bopEvery != 0 && curStep % bopEvery == 0 && isLegacyStyle)
    {
      // Make the icon increase in size (the update function causes them to lerp back down).
      if (this.width > this.height)
      {
        setGraphicSize(Std.int(this.width + (HEALTH_ICON_SIZE * this.size.x * BOP_SCALE)), 0);
      }
      else
      {
        setGraphicSize(0, Std.int(this.height + (HEALTH_ICON_SIZE * this.size.y * BOP_SCALE)));
      }
      // Make the icon twist (the update function causes them to lerp back to normal).
      this.angle += bopAngle * (playerId == 0 ? 1 : -1);

      this.updateHitbox();

      // Ensure the icon is positioned correctly after updating the hitbox.
      this.updatePosition();
    }
  }

  function updateHealthIcon(health:Float):Void
  {
    // We want to efficiently handle animation playback

    // Here, we use the current animation name to track the current state
    // of a simple state machine. Neat!

    switch (getCurrentAnimation())
    {
      case Idle:
        if (health < LOSING_THRESHOLD)
        {
          playAnimation(ToLosing, Losing);
        }
        else if (health > WINNING_THRESHOLD)
        {
          playAnimation(ToWinning, Winning);
        }
        else
        {
          playAnimation(Idle);
        }
      case Winning:
        if (health < WINNING_THRESHOLD)
        {
          playAnimation(FromWinning, Idle);
        }
        else
        {
          playAnimation(Winning, Idle);
        }
      case Losing:
        if (health > LOSING_THRESHOLD) playAnimation(FromLosing, Idle);
        else
        {
          playAnimation(Losing, Idle);
        }
      case ToLosing:
        if (isAnimationFinished())
        {
          playAnimation(Losing, Idle);
        }
      case ToWinning:
        if (isAnimationFinished())
        {
          playAnimation(Winning, Idle);
        }
      case FromLosing | FromWinning:
        if (isAnimationFinished())
        {
          playAnimation(Idle);
        }
      case '':
        playAnimation(Idle);
      default:
        playAnimation(Idle);
    }
  }

  /**
   * Load health icon animations from a Sparrow XML file (the kind used by characters)
   * Note that this is looking for SPECIFIC animation names, so you may need to modify the XML.
   * @param charId
   */
  function loadAnimationNew():Void
  {
    this.animation.addByPrefix(Idle, Idle, 24, true);
    this.animation.addByPrefix(Winning, Winning, 24, true);
    this.animation.addByPrefix(Losing, Losing, 24, true);
    this.animation.addByPrefix(ToWinning, ToWinning, 24, false);
    this.animation.addByPrefix(ToLosing, ToLosing, 24, false);
    this.animation.addByPrefix(FromWinning, FromWinning, 24, false);
    this.animation.addByPrefix(FromLosing, FromLosing, 24, false);
  }

  /**
   * Load health icon animations using the legacy format.
   * Simply assumes two icons, the idle and losing icons.
   * @param charId
   */
  function loadAnimationOld():Void
  {
    // Don't flip BF's icon here! That's done later.
    this.animation.add(Idle, [0], 0, false, false);
    this.animation.add(Losing, [1], 0, false, false);
    if (animation.numFrames >= 3)
    {
      this.animation.add(Winning, [2], 0, false, false);
    }
  }

  function iconExists(charId:String):Bool
  {
    return Assets.exists(Paths.image('icons/icon-$charId'));
  }

  function isNewSpritesheet(charId:String):Bool
  {
    return Assets.exists(Paths.file('images/icons/icon-$characterId.xml'));
  }

  function loadCharacter(charId:Null<String>):Void
  {
    if (charId == null || !iconExists(charId))
    {
      FlxG.log.warn('No icon for character: $charId : using default placeholder face instead!');
      characterId = Constants.DEFAULT_HEALTH_ICON;
      charId = characterId;
    }

    isLegacyStyle = !isNewSpritesheet(charId);

    trace(' Loading health icon for character: $charId (legacy: $isLegacyStyle)');

    if (!isLegacyStyle)
    {
      loadSparrow('icons/icon-$charId');

      loadAnimationNew();
    }
    else
    {
      loadGraphic(Paths.image('icons/icon-$charId'), true, isPixel ? PIXEL_ICON_SIZE : HEALTH_ICON_SIZE, isPixel ? PIXEL_ICON_SIZE : HEALTH_ICON_SIZE);

      loadAnimationOld();
    }

    this.antialiasing = !isPixel;
  }

  /**
   * @return Name of the current animation being played by this health icon.
   */
  public function getCurrentAnimation():String
  {
    if (this.animation == null || this.animation.curAnim == null) return "";
    return this.animation.curAnim.name;
  }

  /**
   * @param id The name of the animation to check for.
   * @return Whether this sprite posesses the given animation.
   *   Only true if the animation was successfully loaded from the XML.
   */
  public function hasAnimation(id:String):Bool
  {
    if (this.animation == null) return false;

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

/**
 * The current state of the health
 */
enum abstract HealthIconState(String) to String from String
{
  /**
   * Indicates the health icon is in the default animation.
   * Plays as long as health is between 20% and 80%.
   */
  public var Idle = 'idle';

  /**
   * Indicates the health icon is playing the Winning animation.
   * Plays as long as health is above 80%.
   */
  public var Winning = 'winning';

  /**
   * Indicates the health icon is playing the Losing animation.
   * Plays as long as health is below 20%.
   */
  public var Losing = 'losing';

  /**
   * Indicates that the health icon is transitioning between `idle` and `winning`.
   * The next animation will play once the current animation finishes.
   */
  public var ToWinning = 'toWinning';

  /**
   * Indicates that the health icon is transitioning between `idle` and `losing`.
   * The next animation will play once the current animation finishes.
   */
  public var ToLosing = 'toLosing';

  /**
   * Indicates that the health icon is transitioning between `winning` and `idle`.
   * The next animation will play once the current animation finishes.
   */
  public var FromWinning = 'fromWinning';

  /**
   * Indicates that the health icon is transitioning between `losing` and `idle`.
   * The next animation will play once the current animation finishes.
   */
  public var FromLosing = 'fromLosing';
}
