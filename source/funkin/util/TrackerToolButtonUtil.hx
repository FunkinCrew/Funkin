package funkin.util;

import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import flixel.system.debug.interaction.Interaction;
import flixel.system.debug.interaction.tools.Tool;

/**
 * the name is a bit of a mouthful, but this adds a button to the
 * FlxDebugger Interaction window, which when pressed will open a
 * tracking window corresponding to whatever currently selected objects are
 */
@:nullSafety
class TrackerToolButtonUtil extends Tool
{
  override function init(brain:Interaction):Tool
  {
    super.init(brain);

    _name = "Add Tracker";
    setButton(GraphicCursorCross);

    button.upHandler = function() {
      brain.selectedItems.forEach(function(item) {
        FlxG.debugger.track(item);
      });
    };

    button.toggleMode = false;

    return this;
  }
}
