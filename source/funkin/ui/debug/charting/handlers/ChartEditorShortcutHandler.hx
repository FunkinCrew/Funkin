package funkin.ui.debug.charting.handlers;

import funkin.util.PlatformUtil;

/**
 * Handles modifying the shortcut text of menu items based on the current platform.
 * On MacOS, `Ctrl`, `Alt`, and `Shift` are replaced with `⌘` (or `^`), `⌥`, and `⇧`, respectively.
 */
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorShortcutHandler
{
  public static function applyPlatformShortcutText(state:ChartEditorState):Void
  {
    state.menubarItemNewChart.shortcutText = ctrlOrCmd('N');
    state.menubarItemOpenChart.shortcutText = ctrlOrCmd('O');
    state.menubarItemSaveChartAs.shortcutText = ctrlOrCmd(shift('S'));
    state.menubarItemExit.shortcutText = ctrlOrCmd('Q');

    state.menubarItemUndo.shortcutText = ctrlOrCmd('Z');
    state.menubarItemRedo.shortcutText = ctrlOrCmd('Y');
    state.menubarItemCut.shortcutText = ctrlOrCmd('X');
    state.menubarItemCopy.shortcutText = ctrlOrCmd('C');
    state.menubarItemPaste.shortcutText = ctrlOrCmd('V');

    state.menubarItemSelectAllNotes.shortcutText = ctrlOrCmd('A');
    state.menubarItemSelectAllEvents.shortcutText = ctrlOrCmd(alt('A'));
    state.menubarItemSelectInverse.shortcutText = ctrlOrCmd('I');
    state.menubarItemSelectNone.shortcutText = ctrlOrCmd('D');
    state.menubarItemSelectBeforeCursor.shortcutText = shift('Home');
    state.menubarItemSelectAfterCursor.shortcutText = shift('End');

    state.menubarItemDifficultyDown.shortcutText = ctrlOrCmd('←');
    state.menubarItemDifficultyUp.shortcutText = ctrlOrCmd('→');

    state.menubarItemPlaytestFull.shortcutText = 'Enter';
    state.menubarItemPlaytestMinimal.shortcutText = shift('Enter');
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
