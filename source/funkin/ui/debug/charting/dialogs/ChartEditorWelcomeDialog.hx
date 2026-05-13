package funkin.ui.debug.charting.dialogs;

#if FEATURE_CHART_EDITOR
import funkin.ui.debug.charting.ChartEditorState;
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogParams;
import funkin.util.FileUtil;
import haxe.ui.components.Label;
import haxe.ui.components.Link;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;

/**
 * Builds and opens a dialog letting the user create a new chart, open a recent chart, or load from a template.
 * Opens when the chart editor first opens.
 */
@:build(haxe.ui.ComponentBuilder.build('assets/exclude/data/ui/chart-editor/dialogs/welcome.xml')) @:access(funkin.ui.debug.charting.ChartEditorState)
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
    this.splashImportChartLegacy.onClick = _ -> onClickLinkImport('legacy');
    this.splashImportChartOsuMania.onClick = _ -> onClickLinkImport('osumania');
    this.splashImportChartStepMania.onClick = _ -> onClickLinkImport('stepmania');

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
    this.splashTemplateList.populate((songId) ->
    {
      try
      {
        chartEditorState.loadSongFromTemplate(songId);
        this.hideDialog(DialogButton.CANCEL);
      }
      catch (e)
      {
        chartEditorState.error('Failed to Load Chart', 'Failed to load chart (${songId}):\n$e');
      }
    });
  }

  /**
   * @param state The current state of the chart editor.
   * @return A newly created `ChartEditorWelcomeDialog`.
   */
  public static function build(chartEditorState:ChartEditorState, ?closable:Bool, ?modal:Bool):ChartEditorWelcomeDialog
  {
    var dialog = new ChartEditorWelcomeDialog(chartEditorState, {
      closable: closable ?? false,
      modal: modal ?? true
    });

    dialog.showDialog(modal ?? true);

    return dialog;
  }

  override public function onClose(event:DialogEvent):Void
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

    var fileNamePattern:EReg = new EReg('([^/\\\\]+)$', '');
    var fileName:String = fileNamePattern.match(chartPath) ? fileNamePattern.matched(1) : chartPath;
    linkRecentChart.text = fileName;

    linkRecentChart.tooltip = chartPath;

    #if sys
    if (!FileUtil.fileExists(chartPath))
    {
      trace('Previously loaded chart file (${chartPath}) does not exist, disabling link...');
      linkRecentChart.disabled = true;
    }
    else
    {
      var lastModified:String = 'Last Modified: ' + sys.FileSystem.stat(chartPath).mtime.toString();
      linkRecentChart.tooltip += '\n' + lastModified;
    }
    #end

    linkRecentChart.onClick = function(_event)
    {
      linkRecentChart.hide();

      // Load chart from file
      try
      {
        ChartEditorImportExportHandler.loadSongFromFNFCPath(state, chartPath);
        // Success, close dialog.
        this.hideDialog(DialogButton.CANCEL);
      }
      catch (e)
      {
        chartEditorState.error('Failed to Load Chart', 'Failed to load chart (${chartPath.toString()}):\n$e');
      }
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
   * Called when the user clicks on any "Import Chart" link in the dialog.
   * Reassign this function to change the behavior.
   */
  public function onClickLinkImport(format:String):Void
  {
    // Hide the welcome dialog
    this.hideDialog(DialogButton.CANCEL);

    // Open the "Import Chart" dialog for specified format
    chartEditorState.openImportChartWizard(format, false);
  }
}
#end
