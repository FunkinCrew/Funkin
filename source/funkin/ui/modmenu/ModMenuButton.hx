package funkin.ui.modmenu;

import funkin.graphics.FunkinSprite;
import flixel.addons.display.FlxRuntimeShader;
import flixel.system.FlxAssets.FlxGraphicAsset;

class ModMenuButton extends FunkinSprite
{
  var invert(default, set):Bool = false;
  var selected(default, set):Bool = false;

  var swappedGraphics:Bool = false;
  public var graphicName:String;

  function set_invert(val:Bool):Bool
  {
    if (!val && invert)
    {
      if (selected) loadTexture('ui/mods/${graphicName}-highlighted');
      else loadTexture('ui/mods/${graphicName}');
    }
    else if (val && !invert) loadTexture('ui/mods/${graphicName}-inverted');

    invert = val;
    return val;
  }

  function set_selected(val:Bool):Bool
  {
    selected = val;

    if (swappedGraphics != selected && !invert)
    {
      if (selected) loadTexture('ui/mods/${graphicName}-highlighted');
      else loadTexture('ui/mods/${graphicName}');
      swappedGraphics = selected;
    }

    return val;
  }
}

