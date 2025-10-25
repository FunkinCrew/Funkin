package funkin.ui.debug.charting.toolboxes;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongRegistry;
import haxe.ui.components.Button;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import funkin.data.song.SongData.SongMetadata;
import funkin.util.VersionUtil;
import funkin.util.FileUtil;
import openfl.net.FileReference;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import haxe.ui.containers.TreeView;
import haxe.ui.containers.TreeViewNode;
import haxe.ui.core.ItemRenderer;
import haxe.ui.events.UIEvent;

/**
 * The toolbox which allows viewing the list of difficulties, switching to a specific one,
 * and adding/removing variations and difficulties.
 */
// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/toolboxes/difficulty.xml"))
class ChartEditorDifficultyToolbox extends ChartEditorBaseToolbox
{
  var difficultyToolboxTree:TreeView;
  var difficultyToolboxAddDifficulty:Button;
  var difficultyToolboxRemoveDifficulty:Button;
  var difficultyToolboxSaveMetadata:Button;
  var difficultyToolboxSaveChart:Button;
  var difficultyToolboxLoadMetadata:Button;
  var difficultyToolboxLoadChart:Button;

  public function new(chartEditorState2:ChartEditorState)
  {
    super(chartEditorState2);

    initialize();

    this.onDialogClosed = onClose;
  }

  function onClose(event:UIEvent)
  {
    chartEditorState.menubarItemToggleToolboxDifficulty.selected = false;
  }

  function initialize():Void
  {
    // Starting position.
    // TODO: Save and load this.
    this.x = 150;
    this.y = 250;

    difficultyToolboxAddDifficulty.onClick = function(_:UIEvent) {
      chartEditorState.openAddDifficultyDialog(true);
    };

    difficultyToolboxRemoveDifficulty.onClick = function(_:UIEvent) {
      var currentVariation:String = chartEditorState.selectedVariation;
      var currentDifficulty:String = chartEditorState.selectedDifficulty;

      trace('Removing difficulty "$currentVariation:$currentDifficulty"');

      var callback = (button) -> {
        switch (button)
        {
          case DialogButton.YES:
            // Remove the difficulty from the chartdata and metadata.
            chartEditorState.removeDifficulty(currentVariation, currentDifficulty, true, true);
            refresh();
          case DialogButton.NO:
            // Remove the difficulty from the chartdata.
            chartEditorState.removeDifficulty(currentVariation, currentDifficulty, false, true);
            refresh();
          case DialogButton.CANCEL: // Do nothing.

          default: // Do nothing.
        }
      }

      Dialogs.messageBox("Are you sure? This is destructive and cannot be undone.\n\nYES will remove it from the chartdata and metadata.\n\nNO will remove it from only the chartdata.",
        "Remove Difficulty", MessageBoxType.TYPE_QUESTION, callback);
    };

    difficultyToolboxSaveMetadata.onClick = function(_:UIEvent) {
      var vari:String = chartEditorState.selectedVariation != Constants.DEFAULT_VARIATION ? '-${chartEditorState.selectedVariation}' : '';
      FileUtil.writeFileReference('${chartEditorState.currentSongId}$vari-metadata.json', chartEditorState.currentSongMetadata.serialize(),
        function(notification:String) {
          switch (notification)
          {
            case "success":
              chartEditorState.success("Saved Metadata", 'Successfully wrote file (${chartEditorState.currentSongId}$vari-metadata.json).');
            case "info":
              chartEditorState.info("Canceled Save Metadata", '(${chartEditorState.currentSongId}$vari-metadata.json)');
            case "error":
              chartEditorState.error("Failure", 'Failed to write file (${chartEditorState.currentSongId}$vari-metadata.json).');
          }
        });
    };

    difficultyToolboxSaveChart.onClick = function(_:UIEvent) {
      var vari:String = chartEditorState.selectedVariation != Constants.DEFAULT_VARIATION ? '-${chartEditorState.selectedVariation}' : '';
      FileUtil.writeFileReference('${chartEditorState.currentSongId}$vari-chart.json', chartEditorState.currentSongChartData.serialize(),
        function(notification:String) {
          switch (notification)
          {
            case "success":
              chartEditorState.success("Saved Chart Data", 'Successfully wrote file (${chartEditorState.currentSongId}$vari-chart.json).');
            case "info":
              chartEditorState.info("Canceled Save Chart Data", '(${chartEditorState.currentSongId}$vari-chart.json)');
            case "error":
              chartEditorState.error("Failure", 'Failed to write file (${chartEditorState.currentSongId}$vari-chart.json).');
          }
        });
    };

    difficultyToolboxLoadMetadata.onClick = function(_:UIEvent) {
      // Replace metadata for current variation.
      FileUtil.browseFileReference(function(fileReference:FileReference) {
        var data = fileReference.data.toString();

        if (data == null) return;

        var songMetadataVersion:Null<thx.semver.Version> = VersionUtil.getVersionFromJSON(data);

        var songMetadata:Null<SongMetadata> = null;
        if (VersionUtil.validateVersion(songMetadataVersion,
          SongRegistry.SONG_METADATA_VERSION_RULE)) songMetadata = SongRegistry.instance.parseEntryMetadataRawWithMigration(data, fileReference.name,
            songMetadataVersion);

        if (songMetadata != null)
        {
          chartEditorState.currentSongMetadata = songMetadata;
          chartEditorState.healthIconsDirty = true;
          chartEditorState.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
          chartEditorState.success('Replaced Metadata', 'Replaced metadata with file (${fileReference.name})');
        }
        else
        {
          chartEditorState.error('Failure', 'Failed to load metadata file (${fileReference.name})');
        }
      });
    };

    difficultyToolboxLoadChart.onClick = function(_:UIEvent) {
      // Replace chart data for current variation.
      FileUtil.browseFileReference(function(fileReference:FileReference) {
        var data = fileReference.data.toString();

        if (data == null) return;

        var songChartDataVersion:Null<thx.semver.Version> = VersionUtil.getVersionFromJSON(data);

        var songChartData:Null<SongChartData> = null;
        if (VersionUtil.validateVersion(songChartDataVersion,
          SongRegistry.SONG_CHART_DATA_VERSION_RULE)) songChartData = SongRegistry.instance.parseEntryChartDataRawWithMigration(data, fileReference.name,
            songChartDataVersion);

        if (songChartData != null)
        {
          chartEditorState.currentSongChartData = songChartData;
          chartEditorState.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
          updateTree();
          refresh();
          chartEditorState.success('Loaded Chart Data', 'Loaded chart data file (${fileReference.name})');
          if (chartEditorState.currentNoteSelection != []) chartEditorState.currentNoteSelection = [];
          if (chartEditorState.currentEventSelection != []) chartEditorState.currentEventSelection = [];
          chartEditorState.noteDisplayDirty = true;
          chartEditorState.notePreviewDirty = true;
          chartEditorState.noteTooltipsDirty = true;
          chartEditorState.notePreviewViewportBoundsDirty = true;
        }
        else
        {
          chartEditorState.error('Failure', 'Failed to load chart data file (${fileReference.name})');
        }
      });
    };

    refresh();
  }

  /**
   * Clear the tree view and rebuild it with the current song metadata (variation and difficulty list).
   */
  public function updateTree():Void
  {
    // Clear the tree view so we can rebuild it.
    difficultyToolboxTree.clearNodes();

    // , icon: 'haxeui-core/styles/default/haxeui_tiny.png'
    var treeSong:TreeViewNode = difficultyToolboxTree.addNode({id: 'stv_song', text: 'S: ${chartEditorState.currentSongName}'});
    treeSong.expanded = true;

    for (curVariation in chartEditorState.availableVariations)
    {
      var variationMetadata:Null<SongMetadata> = chartEditorState.songMetadata.get(curVariation);
      if (variationMetadata == null) continue;

      var treeVariation:TreeViewNode = treeSong.addNode(
        {
          id: 'stv_variation_$curVariation',
          text: 'V: ${curVariation.toTitleCase()}'
        });
      treeVariation.expanded = true;

      var difficultyList:Array<String> = [];
      var variationChartdata:Null<SongChartData> = chartEditorState.songChartData.get(curVariation);

      if (variationChartdata != null)
      {
        var keys:Array<String> = [for (x in variationChartdata.notes.keys()) x];
        keys.sort(funkin.util.SortUtil.defaultsThenAlphabetically.bind(Constants.DEFAULT_DIFFICULTY_LIST_FULL));

        for (key in keys)
        {
          difficultyList.pushUnique(key);
        }
      }

      for (difficulty in difficultyList)
      {
        var _treeDifficulty:TreeViewNode = treeVariation.addNode(
          {
            id: 'stv_difficulty_${curVariation}_$difficulty',
            text: 'D: ${difficulty.toTitleCase()}'
          });
      }
    }

    difficultyToolboxTree.onChange = onTreeChange;
    refreshTreeSelection();
  }

  /**
   * Set the selected item in the tree to the current variation/difficulty.
   *
   * @param node The node to select. If null, the current variation/difficulty will be used.
   */
  public function refreshTreeSelection(node:TreeViewNode = null):Void
  {
    var targetNode = getCurrentTreeNode(node);
    if (this.visible && difficultyToolboxTree.selectedNode != targetNode)
    {
      if (difficultyToolboxTree.selectedNode != null)
      {
        var renderer = difficultyToolboxTree.selectedNode.findComponent(ItemRenderer, true);
        if (renderer != null)
        {
          renderer.removeClass(":node-selected", true, true);
        }
      }
      difficultyToolboxTree.selectedNode = targetNode;
      if (targetNode != null) targetNode.selected = true;
    }
  }

  /**
   * Get the node in the tree representing the current variation/difficulty.
   */
  function getCurrentTreeNode(node:TreeViewNode):TreeViewNode
  {
    if (node != null)
    {
      return switch (node.data.id.split('_')[1])
      {
        case 'song':
          difficultyToolboxTree.findNodeByPath('${node.data.id}');

        case 'variation':
          difficultyToolboxTree.findNodeByPath('stv_song/${node.data.id}');

        case 'difficulty':
          difficultyToolboxTree.findNodeByPath('stv_song/stv_variation_${chartEditorState.selectedVariation}/${node.data.id}');
        default:
          difficultyToolboxTree.findNodeByPath('stv_song/stv_variation_${chartEditorState.selectedVariation}/stv_difficulty_${chartEditorState.selectedVariation}_${chartEditorState.selectedDifficulty}',
            'id');
      }
    }
    else
      return
        difficultyToolboxTree.findNodeByPath('stv_song/stv_variation_${chartEditorState.selectedVariation}/stv_difficulty_${chartEditorState.selectedVariation}_${chartEditorState.selectedDifficulty}',
        'id');
  }

  /**
   * Called when an item in the tree is selected. Updates the current variation/difficulty.
   */
  function onTreeChange(event:UIEvent):Void
  {
    // Get the newly selected node.
    var treeView:TreeView = cast event.target;
    var targetNode:TreeViewNode = difficultyToolboxTree.selectedNode;

    if (targetNode == null)
    {
      trace('No target node!');
      // Reset the user's selection.
      refreshTreeSelection();
      return;
    }

    switch (targetNode.data.id.split('_')[1])
    {
      case 'difficulty':
        var variation:String = targetNode.data.id.split('_')[2];
        var difficulty:String = targetNode.data.id.split('_')[3];

        if (variation != null && difficulty != null)
        {
          if ((chartEditorState.songMetadata.size() == 1 || variation == Constants.DEFAULT_VARIATION)
            && chartEditorState.availableDifficulties.length == 1
            && difficulty == chartEditorState.availableDifficulties[0]) difficultyToolboxRemoveDifficulty.disabled = true;
          else
            difficultyToolboxRemoveDifficulty.disabled = false;
          trace('Changing difficulty to "$variation:$difficulty"');
          chartEditorState.selectedVariation = variation;
          chartEditorState.selectedDifficulty = difficulty;
          cast(chartEditorState.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT),
            ChartEditorMetadataToolbox)?.refreshTreeSelection(targetNode);
        }
      // case 'song':
      case 'variation':
        var variation:String = targetNode.data.id.split('_')[2];
        if (variation != null)
        {
          difficultyToolboxRemoveDifficulty.disabled = true;
          chartEditorState.selectedVariation = variation;
          // Use the first available difficulty as a fallback if the currently selected one cannot be found.
          if (chartEditorState.availableDifficulties.indexOf(chartEditorState.selectedDifficulty) < 0)
            chartEditorState.selectedDifficulty = chartEditorState.availableDifficulties[0];
          trace('Changing difficulty to "$variation:${chartEditorState.selectedDifficulty}"');
          cast(chartEditorState.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT),
            ChartEditorMetadataToolbox)?.refreshTreeSelection(targetNode);
        }
      default:
        difficultyToolboxRemoveDifficulty.disabled = true;
        // Reset the user's selection.
        trace('Selected wrong node type, resetting selection.');
        cast(chartEditorState.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT), ChartEditorMetadataToolbox)?.refreshTreeSelection(targetNode);
    }
  }

  public override function refresh():Void
  {
    super.refresh();

    if (chartEditorState.songMetadata.size() == 1
      && chartEditorState.availableDifficulties.length == 1
      && chartEditorState.selectedDifficulty == chartEditorState.availableDifficulties[0]) difficultyToolboxRemoveDifficulty.disabled = true;
    else
      difficultyToolboxRemoveDifficulty.disabled = false;

    refreshTreeSelection();
  }

  public static function build(chartEditorState:ChartEditorState):ChartEditorDifficultyToolbox
  {
    return new ChartEditorDifficultyToolbox(chartEditorState);
  }
}
#end
