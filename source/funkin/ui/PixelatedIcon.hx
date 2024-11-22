package funkin.ui;

import funkin.graphics.FlxFilteredSprite;

/**
 * The icon that gets used for Freeplay capsules and char select
 * NOT to be confused with the HealthIcon class, which is for the in-game icons
 */
class PixelatedIcon extends FlxFilteredSprite
{
  public function new(x:Float, y:Float)
  {
    super(x, y);
    this.makeGraphic(32, 32, 0x00000000);
    this.antialiasing = false;
    this.active = false;
  }

  public function setCharacter(char:String):Void
  {
    var charPath:String = "freeplay/icons/";

    switch (char)
    {
      // MAT MIXES CASES
      case "mat" | "mat-playable" | "mat-christmas" | "mat-car" | "mat-dark" | "mat-playable-dark":
        charPath += "matpixel";
      case "prism" | "prism-christmas" | "prism-car" | "prism-dark":
        charPath += "facepixel";

      // BASE GAME CASES
      case "bf-christmas" | "bf-car" | "bf-pixel" | "bf-holding-gf" | "bf-dark" | "bf-opponent" | "bf-opponent-dark":
        charPath += "bfpixel";
      case "monster-christmas":
        charPath += "monsterpixel";
      case "mom" | "mom-car":
        charPath += "mommypixel";
      case "pico-blazin" | "pico-playable" | "pico-speaker" | "pico-christmas" | "pico-dark":
        charPath += "picopixel";
      case "gf-christmas" | "gf-car" | "gf-pixel" | "gf-tankmen" | "gf-dark":
        charPath += "gfpixel";
      case "darnell-blazin":
        charPath += "darnellpixel";
      case "senpai-angry":
        charPath += "senpaipixel";
      case "spooky-dark":
        charPath += "spookypixel";
      case "tankman-atlas":
        charPath += "tankmanpixel";
      default:
        charPath += '${char}pixel';
    }

    if (!openfl.utils.Assets.exists(Paths.image(charPath)))
    {
      trace('[WARN] Character ${char} has no freeplay icon.\nLoading placeholder instead.');
      charPath = "freeplay/icons/facepixel";
      return;
    }
    else
    {
      this.visible = true;
    }

    var isAnimated = openfl.utils.Assets.exists(Paths.file('images/$charPath.xml'));

    if (isAnimated)
    {
      this.frames = Paths.getSparrowAtlas(charPath);
    }
    else
    {
      this.loadGraphic(Paths.image(charPath));
    }

    this.scale.x = this.scale.y = 2;

    switch (char)
    {
      case 'parents-christmas':
        this.origin.x = 140;
      default:
        this.origin.x = 100;
    }

    if (isAnimated)
    {
      this.active = true;
      this.animation.addByPrefix('idle', 'idle0', 10, true);
      this.animation.addByPrefix('confirm', 'confirm0', 10, false);
      this.animation.addByPrefix('confirm-hold', 'confirm-hold0', 10, true);

      this.animation.finishCallback = function(name:String):Void {
        trace('Finish pixel animation: ${name}');
        if (name == 'confirm') this.animation.play('confirm-hold');
      };

      this.animation.play('idle');
    }
  }
}
