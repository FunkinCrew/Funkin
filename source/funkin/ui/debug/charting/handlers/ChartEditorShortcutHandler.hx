package funkin.ui.debug.charting.handlers;

import funkin.util.PlatformUtil;

@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorShortcutHandler
{
  public static function applyPlatformShortcutText(state:ChartEditorState):Void
  {
    state.setComponentShortcutText('menubarItemNewChart', ctrlOrCmd('N'));
    state.setComponentShortcutText('menubarItemOpenChart', ctrlOrCmd('O'));
    state.setComponentShortcutText('menubarItemSaveChartAs', ctrlOrCmd(shift('S')));
    state.setComponentShortcutText('menubarItemExit', ctrlOrCmd('Q'));

    state.setComponentShortcutText('menubarItemUndo', ctrlOrCmd('Z'));
    state.setComponentShortcutText('menubarItemRedo', ctrlOrCmd('Y'));
    state.setComponentShortcutText('menubarItemCut', ctrlOrCmd('X'));
    state.setComponentShortcutText('menubarItemCopy', ctrlOrCmd('C'));
    state.setComponentShortcutText('menubarItemPaste', ctrlOrCmd('V'));

    state.setComponentShortcutText('menubarItemSelectAll', ctrlOrCmd('A'));
    state.setComponentShortcutText('menubarItemSelectInverse', ctrlOrCmd('I'));
    state.setComponentShortcutText('menubarItemSelectNone', ctrlOrCmd('D'));
    state.setComponentShortcutText('menubarItemSelectBeforeCursor', shift('Home'));
    state.setComponentShortcutText('menubarItemSelectAfterCursor', shift('End'));

    state.setComponentShortcutText('menubarItemDifficultyDown', ctrlOrCmd('←'));
    state.setComponentShortcutText('menubarItemDifficultyUp', ctrlOrCmd('→'));

    state.setComponentShortcutText('menubarItemPlaytestFull', 'Enter');
    state.setComponentShortcutText('menubarItemPlaytestMinimal', shift('Enter'));
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
