package funkin.ui.debug.cameraeditor.handlers;

#if FEATURE_CAMERA_EDITOR
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogDropTarget;
import flixel.util.FlxTimer;

class CameraEditorFileDropHandler
{
  // ===============
  //  DROP HANDLERS
  // ===============

  /**
   * The current active file drop handlers.
   * This associates different HaxeUI components with different callback functions,
   * so you can have multiple things that can be file drop targets on screen at once.
   */
  static var dropHandlers:Array<DialogDropTarget> = [];

  /**
   * Add a callback for when a file is dropped on a component.
   *
   * On OS X you can’t drop on the application window, but rather only the app icon
   * (either in the dock while running or the icon on the hard drive) so this must be disabled
   * and UI updated appropriately.
   */
  public static function addDropHandler(dropTarget:DialogDropTarget):Void
  {
    #if desktop
    if (!FlxG.stage.window.onDropFile.has(onDropFile)) FlxG.stage.window.onDropFile.add(onDropFile);

    dropHandlers.push(dropTarget);
    #else
    trace('addDropHandler not implemented for this platform');
    #end
  }

  /**
   * Remove a callback for when a file is dropped on a component.
   */
  public static function removeDropHandler(dropTarget:DialogDropTarget):Void
  {
    #if desktop
    dropHandlers.remove(dropTarget);
    #end
  }

  static final EPSILON:Float = 0.01;

  static function onDropFile(path:String, state:String, x:Float, y:Float):Void
  {
    // a VERY short timer to wait for the mouse position to update
    new FlxTimer().start(EPSILON, function(_)
    {
      for (handler in dropHandlers)
      {
        if (handler.component.hitTest(FlxG.mouse.viewX, FlxG.mouse.viewY))
        {
          handler.handler(path);
          return;
        }
      }
    });
  }
}
#end
