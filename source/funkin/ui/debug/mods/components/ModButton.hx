package funkin.ui.debug.mods.components;

import haxe.ui.containers.HBox;
import polymod.Polymod.ModMetadata;

@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/mod-select/components/mod-button.xml"))
class ModButton extends HBox
{
  public var linkedMod:ModMetadata;

  override public function new(mod:ModMetadata)
  {
    super();

    this.id = mod.id;
    linkedMod = mod;

    modButtonLabel.text = mod.id + " (" + mod.modVersion + ")";
    // if (changeTextColor != null) modButtonLabel.styleString = 'color: $changeTextColor;';

    var img = openfl.display.BitmapData.fromBytes(mod.icon);
    if (img != null) modButtonIcon.resource = new flixel.FlxSprite().loadGraphic(img).frames.frames[0]; // hacky way but it works
  }
}
