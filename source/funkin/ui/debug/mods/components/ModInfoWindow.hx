package funkin.ui.debug.mods.components;

import funkin.modding.PolymodHandler;
import funkin.util.WindowUtil;
import haxe.ui.components.Button;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.windows.Window;
import haxe.ui.containers.windows.WindowManager;
import polymod.Polymod.ModMetadata;

@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/mod-select/components/mod-info.xml"))
class ModInfoWindow extends Window
{
  public var linkedButton:ModButton = null;

  var modWindowIcon:Image;
  var modWindowName:Label;
  var modWindowDesc:Label;
  var modWindowDependencies:Label;

  var modWindowVisitHomepage:Button;
  var modWindowViewContributors:Button;
  var modWindowViewContents:Button;

  override public function new(data:ModMetadata)
  {
    super();

    var img = openfl.display.BitmapData.fromBytes(data.icon);
    if (img != null) modWindowIcon.resource = new flixel.FlxSprite().loadGraphic(img).frames.frames[0]; // such a hacky thing I hate it

    modWindowName.text = data.title;
    modWindowDesc.text = data.description;

    title = "Mod: " + data.title + " (" + data.modVersion + ")";

    // dependencies text
    var needed = "None";
    if (data.dependencies.keys().array().length > 0)
    {
      needed = "";

      for (mod => version in data.dependencies)
        needed += mod + ":" + version + "\n";
    }

    var optional = "None";
    if (data.optionalDependencies.keys().array().length > 0)
    {
      optional = "";

      for (mod => version in data.optionalDependencies)
        optional += mod + ":" + version + "\n";
    }

    modWindowDependencies.text = "Required:\n" + needed + "\nOptional:\n" + optional;
    modWindowLicense.text = "License: " + data.license;

    // some buttons n stuff
    #if CAN_OPEN_LINKS
    modWindowVisitHomepage.disabled = (data.homepage == "" || data.homepage == null);
    modWindowVisitHomepage.onClick = function(_) WindowUtil.openURL(data.homepage);
    #else
    modWindowVisitHomepage.disabled = true;
    #end

    modWindowViewContributors.disabled = (data.contributors.length == 0 || data.contributors == null);
    modWindowViewContributors.onClick = function(_) WindowManager.instance.addWindow(new ModContributorWindow(data));

    modWindowViewContents.onClick = function(_) WindowManager.instance.addWindow(new ModDefaultFileViewer(PolymodHandler.MOD_FOLDER + "/" + data.id));

    modWindowMoveUp.onClick = function(_) {
      if (linkedButton == null) return;

      var parent = linkedButton.parentComponent;
      var idx = parent.childComponents.indexOf(linkedButton);

      if (idx == 0) return;

      parent.removeComponent(linkedButton, false);
      parent.addComponentAt(linkedButton, idx - 1);
    }

    modWindowMoveDown.onClick = function(_) {
      if (linkedButton == null) return;

      var parent = linkedButton.parentComponent;
      var idx = parent.childComponents.indexOf(linkedButton);

      if (idx == parent.childComponents.length - 1) return;

      parent.removeComponent(linkedButton, false);
      parent.addComponentAt(linkedButton, idx + 1);
    }
  }
}
