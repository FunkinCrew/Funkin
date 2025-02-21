package funkin.ui.debug.charting.dialogs;

import funkin.data.song.SongRegistry;
import funkin.play.song.Song;
import funkin.ui.debug.charting.ChartEditorState;
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogParams;
import funkin.util.FileUtil;
import funkin.util.SortUtil;
import haxe.ui.components.Label;
import haxe.ui.components.Link;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;
import haxe.ui.events.MouseEvent;

/**
 * Builds and opens a dialog letting the user create a new chart, open a recent chart, or load from a template.
 * Opens when the chart editor first opens.
 */
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/dialogs/welcome.xml"))
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorWelcomeDialog extends ChartEditorBaseDialog
{
  /**
   * @param closable Whether the dialog can be closed by the user.
   * @param modal Whether the dialog is locked to the center of the screen (with a dark overlay behind it).
   */
  public function new(state2:ChartEditorState, params2:DialogParams)
  {
    super(state2, params2);

    this.splashBrowse.onClick = _ -> onClickButtonBrowse();
    this.splashCreateFromSongBasicOnly.onClick = _ -> onClickLinkCreateBasicOnly();
    this.splashCreateFromSongErectOnly.onClick = _ -> onClickLinkCreateErectOnly();
    this.splashCreateFromSongBasicErect.onClick = _ -> onClickLinkCreateBasicErect();
    this.splashImportChartLegacy.onClick = _ -> onClickLinkImportChartLegacy();

    // Add items to the Recent Charts list
    #if sys
    for (chartPath in chartEditorState.previousWorkingFilePaths)
    {
      if (chartPath == null) continue;
      this.addRecentFilePath(chartEditorState, chartPath);
    }
    #else
    this.addHTML5RecentFileMessage();
    #end

    // Add items to the Load From Template list
    this.buildTemplateSongList(chartEditorState);
  }

  /**
   * @param state The current state of the chart editor.
   * @return A newly created `ChartEditorWelcomeDialog`.
   */
  public static function build(chartEditorState:ChartEditorState, ?closable:Bool, ?modal:Bool):ChartEditorWelcomeDialog
  {
    var dialog = new ChartEditorWelcomeDialog(chartEditorState,
      {
        closable: closable ?? false,
        modal: modal ?? true
      });

    dialog.showDialog(modal ?? true);

    return dialog;
  }

  public override function onClose(event:DialogEvent):Void
  {
    super.onClose(event);
  }

  /**
   * Add a file path to the "Open Recent" scroll box on the left.
   * @param path
   */
  public function addRecentFilePath(state:ChartEditorState, chartPath:String):Void
  {
    var linkRecentChart:Link = new Link();

    var fileNamePattern:EReg = new EReg("([^/\\\\]+)$", "");
    var fileName:String = fileNamePattern.match(chartPath) ? fileNamePattern.matched(1) : chartPath;
    linkRecentChart.text = fileName;

    linkRecentChart.tooltip = chartPath;

    #if sys
    var lastModified:String = "Last Modified: " + sys.FileSystem.stat(chartPath).mtime.toString();
    linkRecentChart.tooltip += "\n" + lastModified;
    #end

    linkRecentChart.onClick = function(_event) {
      linkRecentChart.hide();

      this.hideDialog(DialogButton.CANCEL);

      // Load chart from file
      var result:Null<Array<String>> = ChartEditorImportExportHandler.loadFromFNFCPath(state, chartPath);
      if (result != null)
      {
        chartEditorState.success('Loaded Chart',
          result.length == 0 ? 'Loaded chart (${chartPath.toString()})' : 'Loaded chart (${chartPath.toString()})\n${result.join("\n")}');
      }
      else
      {
        chartEditorState.error('Failed to Load Chart', 'Failed to load chart (${chartPath.toString()})');
      }
    }

    if (!FileUtil.fileExists(chartPath))
    {
      trace('Previously loaded chart file (${chartPath}) does not exist, disabling link...');
      linkRecentChart.disabled = true;
    }

    splashRecentContainer.addComponent(linkRecentChart);
  }

  /**
   * Add a string message to the "Open Recent" scroll box on the left.
   * Only displays on platforms which don't support direct file system access.
   */
  public function addHTML5RecentFileMessage():Void
  {
    var webLoadLabel:Label = new Label();
    webLoadLabel.text = 'Click the button below to load a chart file (.fnfc) from your computer.';

    splashRecentContainer.addComponent(webLoadLabel);
  }

  /**
   * Add all the links to the "Create From Template" scroll box on the right.
   */
  public function buildTemplateSongList(state:ChartEditorState):Void
  {
    var songList:Array<String> = SongRegistry.instance.listEntryIds();
    songList.sort(SortUtil.alphabetically);

    for (targetSongId in songList)
    {
      var songData:Null<Song> = SongRegistry.instance.fetchEntry(targetSongId);
      if (songData == null) continue;

      var songName:Null<String> = songData.getDifficulty('normal')?.songName;
      if (songName == null) songName = songData.getDifficulty()?.songName;
      if (songName == null) // Still null?
      {
        trace('[WARN] Could not fetch song name for ${targetSongId}');
        continue;
      }

      this.addTemplateSong(songName, targetSongId, (_) -> {
        this.hideDialog(DialogButton.CANCEL);

        // Load song from template
        chartEditorState.loadSongAsTemplate(targetSongId);
      });
    }
  }

  /**
   * @param loadTemplateCb The callback to call when the user clicks the link. The callback should load the song ID from the template.
   */
  public function addTemplateSong(songName:String, songId:String, onClickCb:(MouseEvent) -> Void):Void
  {
    var linkTemplateSong:Link = new Link();
    linkTemplateSong.text = songName;
    linkTemplateSong.onClick = onClickCb;

    this.splashTemplateContainer.addComponent(linkTemplateSong);
  }

  /**
   * Called when the user clicks the "Browse Chart" button in the dialog.
   * Reassign this function to change the behavior.
   */
  public function onClickButtonBrowse():Void
  {
    // Hide the welcome dialog
    this.hideDialog(DialogButton.CANCEL);

    // Open the "Open Chart" dialog
    chartEditorState.openBrowseFNFC(false);
  }

  /**
   * Called when the user clicks the "Create From Template: Easy/Normal/Hard Only" link in the dialog.
   * Reassign this function to change the behavior.
   */
  public function onClickLinkCreateBasicOnly():Void
  {
    // Hide the welcome dialog
    this.hideDialog(DialogButton.CANCEL);

    //
    // Create Song Wizard
    //
    chartEditorState.openCreateSongWizardBasicOnly(false);
  }

  /**
   * Called when the user clicks the "Create From Template: Erect/Nightmare Only" link in the dialog.
   * Reassign this function to change the behavior.
   */
  public function onClickLinkCreateErectOnly():Void
  {
    // Hide the welcome dialog
    this.hideDialog(DialogButton.CANCEL);

    //
    // Create Song Wizard
    //
    chartEditorState.openCreateSongWizardErectOnly(false);
  }

  /**
   * Called when the user clicks the "Create From Template: Easy/Normal/Hard/Erect/Nightmare" link in the dialog.
   * Reassign this function to change the behavior.
   */
  public function onClickLinkCreateBasicErect():Void
  {
    // Hide the welcome dialog
    this.hideDialog(DialogButton.CANCEL);

    //
    // Create Song Wizard
    //
    chartEditorState.openCreateSongWizardBasicErect(false);
  }

  /**
   * Called when the user clicks the "Import Chart: FNF Legacy" link in the dialog.
   * Reassign this function to change the behavior.
   */
  public function onClickLinkImportChartLegacy():Void
  {
    // Hide the welcome dialog
    this.hideDialog(DialogButton.CANCEL);

    // Open the "Import Chart" dialog
    chartEditorState.openImportChartWizard('legacy', false);
  }
}
