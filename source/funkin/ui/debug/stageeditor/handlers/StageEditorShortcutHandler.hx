package funkin.ui.debug.stageeditor.handlers;

import funkin.util.PlatformUtil;

/**
 * Handles modifying the shortcut text of menu items based on the current platform.
 * On MacOS, `Ctrl`, `Alt`, and `Shift` are replaced with `⌘` (or `^`), `⌥`, and `⇧`, respectively.
 */
@:nullSafety
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class StageEditorShortcutHandler
{
  public static function applyPlatformShortcutText(state:StageEditorState):Void
  {

  }

  /**
   * Display `Ctrl` on Windows and `⌘` (Command) on macOS.
   * @param input
   */
  static inline function ctrlOrCmd(input:String)
  {
    return (PlatformUtil.isMacOS()) ? '⌘+${input}' : 'Ctrl+${input}';
  }

  /**
   * Display `Ctrl` on Windows and `^` (Control) on macOS.
   * @param input
   */
  static inline function ctrl(input:String)
  {
    return (PlatformUtil.isMacOS()) ? '^+${input}' : 'Ctrl+${input}';
  }

  static inline function alt(input:String)
  {
    return (PlatformUtil.isMacOS()) ? '⌥+${input}' : 'Alt+${input}';
  }

  static inline function shift(input:String)
  {
    return (PlatformUtil.isMacOS()) ? '⇧+${input}' : 'Shift+${input}';
  }
}
