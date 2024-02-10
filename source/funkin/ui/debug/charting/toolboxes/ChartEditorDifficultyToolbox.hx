package funkin.ui.debug.charting.toolboxes;

import funkin.play.character.BaseCharacter.CharacterType;
import funkin.play.character.CharacterData;
import funkin.data.stage.StageData;
import funkin.data.stage.StageRegistry;
import funkin.ui.debug.charting.commands.ChangeStartingBPMCommand;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import funkin.data.song.SongData.SongMetadata;
import haxe.ui.components.DropDown;
import haxe.ui.components.HorizontalSlider;
import funkin.util.FileUtil;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import funkin.play.song.SongSerializer;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Slider;
import haxe.ui.components.TextField;
import funkin.play.stage.Stage;
import haxe.ui.containers.Box;
import haxe.ui.containers.TreeView;
import haxe.ui.containers.TreeViewNode;
import haxe.ui.containers.Frame;
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
  var difficultyToolboxAddVariation:Button;
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

    difficultyToolboxAddVariation.onClick = function(_:UIEvent) {
      chartEditorState.openAddVariationDialog(true);
    };

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
            // Remove the difficulty.
            chartEditorState.removeDifficulty(currentVariation, currentDifficulty);
            refresh();
          case DialogButton.NO: // Do nothing.
          default: // Do nothing.
        }
      }

      Dialogs.messageBox("Are you sure? This cannot be undone.", "Remove Difficulty", MessageBoxType.TYPE_YESNO, callback);
    };

    difficultyToolboxSaveMetadata.onClick = function(_:UIEvent) {
      var vari:String = chartEditorState.selectedVariation != Constants.DEFAULT_VARIATION ? '-${chartEditorState.selectedVariation}' : '';
      FileUtil.writeFileReference('${chartEditorState.currentSongId}$vari-metadata.json', chartEditorState.currentSongMetadata.serialize());
    };

    difficultyToolboxSaveChart.onClick = function(_:UIEvent) {
      var vari:String = chartEditorState.selectedVariation != Constants.DEFAULT_VARIATION ? '-${chartEditorState.selectedVariation}' : '';
      FileUtil.writeFileReference('${chartEditorState.currentSongId}$vari-chart.json', chartEditorState.currentSongChartData.serialize());
    };

    difficultyToolboxLoadMetadata.onClick = function(_:UIEvent) {
      // Replace metadata for current variation.
      SongSerializer.importSongMetadataAsync(function(songMetadata) {
        chartEditorState.currentSongMetadata = songMetadata;
      });
    };

    difficultyToolboxLoadChart.onClick = function(_:UIEvent) {
      // Replace chart data for current variation.
      SongSerializer.importSongChartDataAsync(function(songChartData) {
        chartEditorState.currentSongChartData = songChartData;
        chartEditorState.noteDisplayDirty = true;
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

      var difficultyList:Array<String> = variationMetadata.playData.difficulties;

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
   * @param targetNode The node to select. If null, the current variation/difficulty will be used.
   */
  public function refreshTreeSelection():Void
  {
    var targetNode = getCurrentTreeNode();
    if (targetNode != null) difficultyToolboxTree.selectedNode = targetNode;
  }

  /**
   * Get the node in the tree representing the current variation/difficulty.
   */
  function getCurrentTreeNode():TreeViewNode
  {
    return
      difficultyToolboxTree.findNodeByPath('stv_song/stv_variation_$chartEditorState.selectedVariation/stv_difficulty_${chartEditorState.selectedVariation}_$chartEditorState.selectedDifficulty',
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
          trace('Changing difficulty to "$variation:$difficulty"');
          chartEditorState.selectedVariation = variation;
          chartEditorState.selectedDifficulty = difficulty;
          chartEditorState.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
          refreshTreeSelection();
        }
      // case 'song':
      // case 'variation':
      default:
        // Reset the user's selection.
        trace('Selected wrong node type, resetting selection.');
        refreshTreeSelection();
        chartEditorState.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
    }
  }

  public override function refresh():Void
  {
    super.refresh();

    refreshTreeSelection();
  }

  public static function build(chartEditorState:ChartEditorState):ChartEditorDifficultyToolbox
  {
    return new ChartEditorDifficultyToolbox(chartEditorState);
  }
}
