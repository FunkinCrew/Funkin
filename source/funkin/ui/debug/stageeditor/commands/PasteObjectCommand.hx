package funkin.ui.debug.stageeditor.commands;

@:nullSafety @:access(funkin.ui.debug.stageeditor.StageEditorState)
class PasteObjectCommand implements StageEditorCommand
{
  public function execute(state:StageEditorState):Void
  {
    var currentClipboard:ObjectClipboardItem = StageEditorAssetHandler.readItemsFromClipboard();

    if (currentClipboard.valid != true)
    {
      state.error('Failed to Paste', 'Could not parse clipboard contents.');
      return;
    }

    state.error('TODO!', 'Not finished yet, sorry!');
  }

  public function undo(state:StageEditorState):Void
  {
    state.error('TODO!', 'Not finished yet, sorry!');
  }

  public function shouldAddToHistory(state:StageEditorState):Bool
  {
    return true;
  }

  public function toString():String
  {
    var objectID = 'Unknown';
    return 'Paste $objectID to Clipboard';
  }
}
