package funkin.ui.debug.stageeditor.commands;

@:nullSafety
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class PasteObjectCommand implements StageEditorCommand
{
  public function execute(state:ChartEditorState):Void
  {
    var currentClipboard:SongClipboardItems = SongDataUtils.readItemsFromClipboard();

    if (currentClipboard.valid != true)
    {
      state.error('Failed to Paste', 'Could not parse clipboard contents.');
      return;
    }
  }
}
