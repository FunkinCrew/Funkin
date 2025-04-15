package funkin.mobile.ui.options.objects;

import flixel.group.FlxSpriteGroup;
import funkin.ui.TextMenuList.TextMenuItem;
import funkin.ui.options.items.CheckboxPreferenceItem;
import funkin.ui.AtlasText.AtlasFont;
import flixel.FlxG;
import funkin.graphics.FunkinCamera;

@:nullSafety
class HitboxOptionButton extends FlxSpriteGroup
{
  var checkbox:CheckboxPreferenceItem;

  public var text:TextMenuItem;

  public function new(?xPos:Float = 0, ?yPos:Float = 0, defaultValue:Bool, onClick:Bool->Void):Void
  {
    super(xPos, yPos);

    checkbox = new CheckboxPreferenceItem(0, 0, defaultValue);

    text = new TextMenuItem(checkbox.x + checkbox.width, checkbox.y + 30, "Downscroll", AtlasFont.BOLD, function() {
      var value = !checkbox.currentValue;
      onClick(value);
      checkbox.currentValue = value;
    });

    add(text);
    add(checkbox);

    setSize(500, 500);

    var camControls = new FunkinCamera('camControls2');
    FlxG.cameras.add(camControls, false);
    camControls.bgColor = 0x0;

    cameras = [camControls];
    // updateHitbox();
  }
}
