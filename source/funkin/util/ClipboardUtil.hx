package funkin.util;

/**
 * Utility functions for working with the system clipboard.
 * On platforms that don't support interacting with the clipboard,
 * an internal clipboard is used (neat!).
 */
@:nullSafety
class ClipboardUtil
{
  /**
   * Add an event listener callback which executes next time the system clipboard is updated.
   *
   * @param	callback The callback to execute when the clipboard is updated.
   * @param	once If true, the callback will only execute once and then be deleted.
   * @param priority Set the priority at which the callback will be executed. Higher values execute first.
   */
  public static function addListener(callback:Void->Void, once:Bool = false, priority:Int = 0):Void
  {
    lime.system.Clipboard.onUpdate.add(callback, once, priority);
  }

  /**
   * Remove an event listener callback from the system clipboard.
   *
   * @param	callback The callback to remove.
   */
  public static function removeListener(callback:Void->Void):Void
  {
    lime.system.Clipboard.onUpdate.remove(callback);
  }

  /**
   * Get the current contents of the system clipboard.
   *
   * @return The current contents of the system clipboard.
   */
  public static function getClipboard():String
  {
    return lime.system.Clipboard.text;
  }

  /**
   * Set the contents of the system clipboard.
   *
   * @param	text The text to set the system clipboard to.
   */
  public static function setClipboard(text:String):String
  {
    return lime.system.Clipboard.text = text;
  }
}
