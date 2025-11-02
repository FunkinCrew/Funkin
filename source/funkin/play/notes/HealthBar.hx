package funkin.play.notes;

import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.ui.FlxBar;
import funkin.graphics.FunkinSprite;
import funkin.play.notes.notestyle.NoteStyle;

class HealthBar extends FlxSpriteGroup
{
  final noteStyle:NoteStyle;

  public var healthBar:FlxBar;
  public var healthBarBG:FunkinSprite;
  public var isBotPlayMode:Bool;

  final isDownscroll:Bool = #if mobile (Preferences.controlsScheme == FunkinHitboxControlSchemes.Arrows
    && !ControlsHandler.usingExternalInputDevice)
    || #end Preferences.downscroll;

  public var currentHealth = Constants.HEALTH_STARTING;

  var healthLerp:Float = Constants.HEALTH_STARTING;

  public function new(noteStyle, isBotPlayMode:Bool = false):Void
  {
    super(0, 0);
    this.noteStyle = noteStyle;
    this.isBotPlayMode = isBotPlayMode;
    healthBarBG = FunkinSprite.create(0, 0, noteStyle.getHealthBarAssetPath());
    healthBar = new FlxBar(0, 0, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), null, 0, 2);
    var scale = noteStyle.getHealthBarScale();
    healthBarBG.scale.set(scale, scale);
    healthBarBG.y = isDownscroll ? FlxG.height * 0.1 : FlxG.height * 0.9;
    healthBarBG.screenCenter(X);
    healthBarBG.scrollFactor.set(0, 0);
    healthBarBG.zIndex = 800;
    noteStyle.applyHealthBarOffsets(this);
    this.add(healthBarBG);
    healthBar.x = healthBarBG.x + 4;
    healthBar.y = healthBarBG.y + 4;
    healthBar.parent = this;
    healthBar.parentVariable = 'healthLerp';
    healthBar.scrollFactor.set();
    healthBar.createFilledBar(Constants.COLOR_HEALTH_BAR_RED, Constants.COLOR_HEALTH_BAR_GREEN);
    healthBar.zIndex = 801;
    this.add(healthBar);
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);
    if (isBotPlayMode)
    {
      healthLerp = Constants.HEALTH_MAX;
    }
    else
    {
      healthLerp = FlxMath.lerp(healthLerp, currentHealth, 0.15);
    }
  }
}
