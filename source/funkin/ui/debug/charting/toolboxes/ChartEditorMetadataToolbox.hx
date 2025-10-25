package funkin.ui.debug.charting.toolboxes;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.data.character.CharacterData;
import funkin.data.song.importer.ChartManifestData;
import funkin.data.stage.StageRegistry;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.ui.debug.charting.commands.AddNewTimeChangeCommand;
import funkin.ui.debug.charting.commands.ModifyTimeChangeCommand;
import funkin.ui.debug.charting.commands.RemoveTimeChangeCommand;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import haxe.ui.components.Button;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Slider;
import haxe.ui.components.TextField;
import funkin.play.stage.Stage;
import haxe.ui.containers.Frame;
import haxe.ui.containers.TreeView;
import haxe.ui.containers.TreeViewNode;
import haxe.ui.core.ItemRenderer;
import haxe.ui.events.UIEvent;

/**
 * The toolbox which allows modifying information like Song Title, Scroll Speed, Characters/Stages, and starting BPM.
 */
// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/toolboxes/metadata.xml"))
class ChartEditorMetadataToolbox extends ChartEditorBaseToolbox
{
  var inputSongId:TextField;
  var inputSongName:TextField;
  var inputSongArtist:TextField;
  var inputSongCharter:TextField;
  var inputStage:DropDown;
  var inputNoteStyle:DropDown;
  var buttonCharacterPlayer:Button;
  var buttonCharacterGirlfriend:Button;
  var buttonCharacterOpponent:Button;
  var buttonAddVariation:Button;
  var buttonAddDifficulty:Button;
  var buttonRemove:Button;
  var inputBPM:NumberStepper;
  var labelTimeStamp:Label;
  var inputTimeStamp:NumberStepper;
  var labelScrollSpeed:Label;
  var inputScrollSpeed:Slider;
  var frameVariation:Frame;
  var frameDifficulty:Frame;
  var tcDropdownItemRenderer:ItemRenderer;
  var metadataToolboxTree:TreeView;

  public function new(chartEditorState2:ChartEditorState)
  {
    super(chartEditorState2);

    tcDropdownItemRenderer = inputTimeChange.findComponent(ItemRenderer);

    initialize();

    this.onDialogClosed = onClose;
  }

  function onClose(event:UIEvent)
  {
    chartEditorState.menubarItemToggleToolboxMetadata.selected = false;
  }

  function initialize():Void
  {
    // Starting position.
    // TODO: Save and load this.
    this.x = 150;
    this.y = 250;

    inputSongId.onChange = function(event:UIEvent) {
      var valid:Bool = event.target.text != null && event.target.text != '' && !ChartManifestData.invalidIdRegex.match(event.target.text);

      if (valid)
      {
        inputSongId.removeClass('invalid-value');
        chartEditorState.songManifestData.songId = event.target.text;
      }
      else
      {
        chartEditorState._songManifestData = null;
      }
    };

    inputSongName.onChange = function(event:UIEvent) {
      var valid:Bool = event.target.text != null && event.target.text != '';

      if (valid)
      {
        inputSongName.removeClass('invalid-value');
        chartEditorState.currentSongMetadata.songName = event.target.text;
      }
      else
      {
        chartEditorState.currentSongMetadata.songName = '';
      }
    };

    inputSongArtist.onChange = function(event:UIEvent) {
      var valid:Bool = event.target.text != null && event.target.text != '';

      if (valid)
      {
        inputSongArtist.removeClass('invalid-value');
        chartEditorState.currentSongMetadata.artist = event.target.text;
      }
      else
      {
        chartEditorState.currentSongMetadata.artist = '';
      }
    };

    inputSongCharter.onChange = function(event:UIEvent) {
      var valid:Bool = event.target.text != null && event.target.text != '';

      if (valid)
      {
        inputSongCharter.removeClass('invalid-value');
        chartEditorState.currentSongMetadata.charter = event.target.text;
      }
      else
      {
        chartEditorState.currentSongMetadata.charter = null;
      }
    };

    inputStage.onChange = function(event:UIEvent) {
      var valid:Bool = event.data != null && event.data.id != null;

      if (valid)
      {
        chartEditorState.currentSongMetadata.playData.stage = event.data.id;
      }
    };
    var startingValueStage = ChartEditorDropdowns.populateDropdownWithStages(inputStage, chartEditorState.currentSongMetadata.playData.stage);
    inputStage.value = startingValueStage;

    inputNoteStyle.onChange = function(event:UIEvent) {
      var valid:Bool = event.data != null && event.data.id != null;

      if (valid)
      {
        chartEditorState.currentSongNoteStyle = event.data.id;
      }
    };
    var startingValueNoteStyle = ChartEditorDropdowns.populateDropdownWithNoteStyles(inputNoteStyle, chartEditorState.currentSongMetadata.playData.noteStyle);
    inputNoteStyle.value = startingValueNoteStyle;

    inputTimeChange.onChange = function(event:UIEvent) {
      var currentTimeChange = refreshTimeChangeInputs();
      var previousTimeChange = chartEditorState.currentSongMetadata.timeChanges[inputTimeChange.selectedIndex - 1];
      // Set the step of the timestamp to the step.
      inputTimeStamp.step = ((Constants.SECS_PER_MIN / (previousTimeChange?.bpm ?? currentTimeChange?.bpm ?? 100)) * Constants.MS_PER_SEC) * (4 / (previousTimeChange?.timeSignatureDen ?? currentTimeChange?.timeSignatureDen ?? 4)) / Constants.STEPS_PER_BEAT;
      // Set the min max values of the input timestamp to previous and next time change timestamps to in the array,
      // to prevent the conductor from breaking due to time change timestamps not being in ascending order.
      inputTimeStamp.min = (previousTimeChange?.timeStamp ?? 0);
      inputTimeStamp.max = (chartEditorState.currentSongMetadata.timeChanges[inputTimeChange.selectedIndex + 1]?.timeStamp ?? chartEditorState.songLengthInMs);
      inputTimeStamp.max -= 1;

      // Prevent the inital time change timestamp from being modified (it should always be 0) or removed.
      if (inputTimeChange.selectedIndex == 0)
      {
        labelTimeStamp.hidden = true;
        inputTimeStamp.hidden = true;
        removeTimeChange.disabled = true;
      }
      else
      {
        inputTimeStamp.min += 1; // This here so it can't accidentally change the first/0 timechange timestamp to 1.
        labelTimeStamp.hidden = false;
        inputTimeStamp.hidden = false;
        removeTimeChange.disabled = false;
      }
    };
    var startingTimeChange = ChartEditorDropdowns.populateDropdownWithTimeChanges(inputTimeChange, chartEditorState.currentSongMetadata.timeChanges, 0);
    inputTimeChange.selectedIndex = Std.parseInt(startingTimeChange.id);
    inputTimeChange.value = startingTimeChange;

    inputBPM.onChange = function(event:UIEvent) {
      if (event.value == null || event.value <= 0) return;

      // Use a command so we can undo/redo this action.
      var currentTimeChange = chartEditorState.currentSongMetadata.timeChanges[inputTimeChange.selectedIndex];
      var currentBPM = currentTimeChange.bpm;
      if (event.value != currentBPM)
      {
        chartEditorState.performCommand(new ModifyTimeChangeCommand(inputTimeChange.selectedIndex, currentTimeChange.timeStamp, event.value,
          currentTimeChange.timeSignatureNum, currentTimeChange.timeSignatureDen));
        inputTimeChange.value.text = '${currentTimeChange.timeStamp} ms : BPM: ${event.value} in ${currentTimeChange.timeSignatureNum}/${currentTimeChange.timeSignatureDen}';
        tcDropdownItemRenderer.data = inputTimeChange.value;
      }
    };

    inputTimeStamp.onChange = function(event:UIEvent) {
      if (event.value == null || event.value <= 0) return;

      // Use a command so we can undo/redo this action.
      var currentTimeChange = chartEditorState.currentSongMetadata.timeChanges[inputTimeChange.selectedIndex];
      var currentTimeStamp = currentTimeChange.timeStamp;
      if (inputTimeChange.selectedIndex != 0 && event.value != currentTimeStamp)
      {
        chartEditorState.performCommand(new ModifyTimeChangeCommand(inputTimeChange.selectedIndex, event.value, currentTimeChange.bpm,
          currentTimeChange.timeSignatureNum, currentTimeChange.timeSignatureDen));
        inputTimeChange.value.text = '${event.value} ms : BPM: ${currentTimeChange.bpm} in ${currentTimeChange.timeSignatureNum}/${currentTimeChange.timeSignatureDen}';
        tcDropdownItemRenderer.data = inputTimeChange.value;
      }
    };

    inputTSNum.onChange = function(event:UIEvent) {
      var numerator:Null<Int> = Std.parseInt(event?.data?.text);
      if (numerator == null) return;
      var currentTimeChange = chartEditorState.currentSongMetadata.timeChanges[inputTimeChange.selectedIndex];
      var prevNumerator:Int = currentTimeChange.timeSignatureNum;
      if (numerator == prevNumerator) return;

      chartEditorState.performCommand(new ModifyTimeChangeCommand(inputTimeChange.selectedIndex, currentTimeChange.timeStamp, currentTimeChange.bpm,
        numerator, currentTimeChange.timeSignatureDen));
      inputTimeChange.value.text = '${currentTimeChange.timeStamp} ms : BPM: ${currentTimeChange.bpm} in ${numerator}/${currentTimeChange.timeSignatureDen}';
      tcDropdownItemRenderer.data = inputTimeChange.value;
    }

    inputTSDen.onChange = function(event:UIEvent) {
      var denominator:Null<Int> = Std.parseInt(event?.data?.text);
      if (denominator == null) return;
      var currentTimeChange = chartEditorState.currentSongMetadata.timeChanges[inputTimeChange.selectedIndex];
      var prevDenominator:Int = currentTimeChange.timeSignatureDen;
      if (denominator == prevDenominator) return;

      chartEditorState.performCommand(new ModifyTimeChangeCommand(inputTimeChange.selectedIndex, currentTimeChange.timeStamp, currentTimeChange.bpm,
        currentTimeChange.timeSignatureNum, denominator));
      inputTimeChange.value.text = '${currentTimeChange.timeStamp} ms : BPM: ${currentTimeChange.bpm} in ${currentTimeChange.timeSignatureNum}/${denominator}';
      tcDropdownItemRenderer.data = inputTimeChange.value;
    }

    createTimeChange.onClick = function(_:UIEvent) {
      var currentTimeChangeIndex = chartEditorState.currentSongMetadata.timeChanges.indexOf(Conductor.instance.currentTimeChange);
      chartEditorState.performCommand(new AddNewTimeChangeCommand(currentTimeChangeIndex,
        chartEditorState.scrollPositionInMs + chartEditorState.playheadPositionInMs));
    }

    removeTimeChange.onClick = function(_:UIEvent) {
      chartEditorState.performCommand(new RemoveTimeChangeCommand(inputTimeChange.selectedIndex));
    }

    inputScrollSpeed.onChange = function(event:UIEvent) {
      var valid:Bool = event.target.value != null && event.target.value > 0;

      if (valid)
      {
        inputScrollSpeed.removeClass('invalid-value');
        chartEditorState.currentSongChartScrollSpeed = event.target.value;
      }
      else
      {
        chartEditorState.currentSongChartScrollSpeed = 1.0;
      }
      labelScrollSpeed.text = 'Scroll Speed: ${chartEditorState.currentSongChartScrollSpeed}x';
    };

    inputDifficultyRating.onChange = function(event:UIEvent) {
      chartEditorState.currentSongChartDifficultyRating = event.target.value;
    };

    buttonCharacterOpponent.onClick = function(_) {
      chartEditorState.openCharacterDropdown(CharacterType.DAD, false);
    };

    buttonCharacterGirlfriend.onClick = function(_) {
      chartEditorState.openCharacterDropdown(CharacterType.GF, false);
    };

    buttonCharacterPlayer.onClick = function(_) {
      chartEditorState.openCharacterDropdown(CharacterType.BF, false);
    };

    buttonAddVariation.onClick = function(_:UIEvent) {
      chartEditorState.openAddVariationDialog(true);
    };

    buttonAddDifficulty.onClick = function(_:UIEvent) {
      chartEditorState.openAddDifficultyDialog(true, true);
    };

    buttonRemove.onClick = function(_:UIEvent) {
      var currentVariation:String = chartEditorState.selectedVariation;
      var currentDifficulty:String = chartEditorState.selectedDifficulty;

      var callback;
      switch (metadataToolboxTree.selectedNode.data.id.split('_')[1])
      {
        case 'variation':
          callback = (button) -> {
            switch (button)
            {
              case DialogButton.YES:
                // Remove the variation.
                chartEditorState.removeVariation(currentVariation);
                refresh();
              case DialogButton.NO: // Do nothing.

              default: // Huh?
            }
          }

          Dialogs.messageBox("Are you sure? This is destructive and cannot be undone.", "Remove Variation", MessageBoxType.TYPE_YESNO, callback);

        case 'difficulty':
          callback = (button) -> {
            switch (button)
            {
              case DialogButton.YES:
                // Remove the difficulty from the chartdata and metadata.
                chartEditorState.removeDifficulty(currentVariation, currentDifficulty, true, true);
                refresh();
              case DialogButton.NO:
                // Remove the difficulty from the metadata.
                chartEditorState.removeDifficulty(currentVariation, currentDifficulty, true, false);
                refresh();
              case DialogButton.CANCEL: // Do nothing.

              default: // Do nothing.
            }
          }

          Dialogs.messageBox("Are you sure? This is destructive and cannot be undone.\n\nYES will remove it from both the chartdata and metadata.\n\nNO will remove it from the metadata.",
            "Remove Difficulty", MessageBoxType.TYPE_QUESTION, callback);
        default:
          trace("WHAT");
      }
    };

    refresh();
  }

  // Separate function because it needs to be refreshed in some of the time change commands, updating the entire toolbox would be wasteful.
  public function refreshTimeChanges(startingTimeChangeIndex:Int = 0):Void
  {
    // Reset time change dropdown and the associated inputs
    var startingTimeChange = ChartEditorDropdowns.populateDropdownWithTimeChanges(inputTimeChange, chartEditorState.currentSongMetadata.timeChanges,
      startingTimeChangeIndex);
    inputTimeChange.selectedIndex = Std.parseInt(startingTimeChange.id);
    inputTimeChange.value = startingTimeChange;
    chartEditorState.updateSongTime();
  }

  public function refreshTimeChangeInputs(updateDropdownText:Bool = false):Null<funkin.data.song.SongData.SongTimeChange>
  {
    var currentTimeChange = chartEditorState.currentSongMetadata.timeChanges[inputTimeChange.selectedIndex];
    if (currentTimeChange == null)
    {
      trace("No time change in timeChanges at inputTimeChange's selectedIndex!");
      return null;
    }
    inputBPM.value = currentTimeChange.bpm;
    inputTSNum.value = currentTimeChange.timeSignatureNum;
    inputTSDen.value = currentTimeChange.timeSignatureDen;
    inputTimeStamp.value = currentTimeChange.timeStamp;
    if (updateDropdownText)
    {
      inputTimeChange.value.text = '${currentTimeChange.timeStamp} ms : BPM: ${currentTimeChange.bpm} in ${currentTimeChange.timeSignatureNum}/${currentTimeChange.timeSignatureDen}';
      tcDropdownItemRenderer.data = inputTimeChange.value;
    }
    return currentTimeChange;
  }

  /**
   * Clear the tree view and rebuild it with the current song metadata (variation and difficulty list).
   */
  public function updateTree():Void
  {
    // Clear the tree view so we can rebuild it.
    metadataToolboxTree.clearNodes();

    // , icon: 'haxeui-core/styles/default/haxeui_tiny.png'
    var treeSong:TreeViewNode = metadataToolboxTree.addNode({id: 'stv_song', text: 'S: ${chartEditorState.currentSongName}'});
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

    metadataToolboxTree.onChange = onTreeChange;
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
    if (this.visible && metadataToolboxTree.selectedNode != targetNode)
    {
      // Bit annoying I have to do this to remove the hightlight on the previous selection when updated by code.
      if (metadataToolboxTree.selectedNode != null)
      {
        var renderer = metadataToolboxTree.selectedNode.findComponent(ItemRenderer, true);
        if (renderer != null)
        {
          renderer.removeClass(":node-selected", true, true);
        }
      }
      metadataToolboxTree.selectedNode = targetNode;
      if (targetNode != null) targetNode.selected = true; // Add the hightlight to the new selected node.
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
          metadataToolboxTree.findNodeByPath('${node.data.id}');

        case 'variation':
          metadataToolboxTree.findNodeByPath('stv_song/${node.data.id}');

        case 'difficulty':
          metadataToolboxTree.findNodeByPath('stv_song/stv_variation_${chartEditorState.selectedVariation}/${node.data.id}');
        default:
          metadataToolboxTree.findNodeByPath('stv_song/stv_variation_${chartEditorState.selectedVariation}/stv_difficulty_${chartEditorState.selectedVariation}_${chartEditorState.selectedDifficulty}',
            'id');
      }
    }
    else
    return
      metadataToolboxTree.findNodeByPath('stv_song/stv_variation_${chartEditorState.selectedVariation}/stv_difficulty_${chartEditorState.selectedVariation}_${chartEditorState.selectedDifficulty}',
      'id');
  }

  /**
   * Called when an item in the tree is selected. Updates the current variation/difficulty.
   */
  function onTreeChange(event:UIEvent):Void
  {
    // Get the newly selected node.
    var treeView:TreeView = cast event.target;
    var targetNode:TreeViewNode = metadataToolboxTree.selectedNode;

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
            && chartEditorState.availableDifficulties.length == 1) buttonRemove.disabled = true;
          else
            buttonRemove.disabled = false;
          trace('Changing difficulty to "$variation:$difficulty"');
          chartEditorState.selectedVariation = variation;
          chartEditorState.selectedDifficulty = difficulty;
          cast(chartEditorState.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT),
            ChartEditorDifficultyToolbox)?.refreshTreeSelection(targetNode);
        }
      // case 'song':
      case 'variation':
        var variation:String = targetNode.data.id.split('_')[2];
        if (variation != null)
        {
          if (chartEditorState.songMetadata.size() == 1 || variation == Constants.DEFAULT_VARIATION) buttonRemove.disabled = true;
          else
            buttonRemove.disabled = false;
          chartEditorState.selectedVariation = variation;
          // Use the first available difficulty as a fallback if the currently selected one cannot be found.
          if (chartEditorState.availableDifficulties.indexOf(chartEditorState.selectedDifficulty) < 0)
            chartEditorState.selectedDifficulty = chartEditorState.availableDifficulties[0];
          trace('Changing difficulty to "$variation:${chartEditorState.selectedDifficulty}"');
          cast(chartEditorState.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT),
            ChartEditorDifficultyToolbox)?.refreshTreeSelection(targetNode);
        }
      default:
        buttonRemove.disabled = true;
        // Reset the user's selection.
        trace('Selected wrong node type, resetting selection.');
        cast(chartEditorState.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT),
          ChartEditorDifficultyToolbox)?.refreshTreeSelection(targetNode);
    }
  }

  public override function refresh():Void
  {
    super.refresh();

    inputSongId.value = chartEditorState.songManifestData.songId;
    inputSongName.value = chartEditorState.currentSongMetadata.songName;
    inputSongArtist.value = chartEditorState.currentSongMetadata.artist;
    inputSongCharter.value = chartEditorState.currentSongMetadata.charter;
    inputStage.value = chartEditorState.currentSongMetadata.playData.stage;
    inputNoteStyle.value = chartEditorState.currentSongMetadata.playData.noteStyle;
    inputDifficultyRating.value = chartEditorState.currentSongChartDifficultyRating;
    inputScrollSpeed.value = chartEditorState.currentSongChartScrollSpeed;
    labelScrollSpeed.text = 'Scroll Speed: ${chartEditorState.currentSongChartScrollSpeed}x';
    frameVariation.text = 'Variation: ${chartEditorState.selectedVariation.toTitleCase()}';
    frameDifficulty.text = 'Difficulty: ${chartEditorState.selectedDifficulty.toTitleCase()}';

    refreshTimeChanges();

    var stageId:String = chartEditorState.currentSongMetadata.playData.stage;
    var stage:Null<Stage> = StageRegistry.instance.fetchEntry(stageId);
    if (inputStage != null)
    {
      inputStage.value = (stage != null) ?
        {id: stage.id, text: stage.stageName} :
          {id: "mainStage", text: "Main Stage"};
    }

    var noteStyleId:String = chartEditorState.currentSongNoteStyle;
    var noteStyle:Null<NoteStyle> = NoteStyleRegistry.instance.fetchEntry(noteStyleId);
    if (inputNoteStyle != null)
    {
      inputNoteStyle.value = (noteStyle != null) ?
        {id: noteStyle.id, text: noteStyle.getName()} :
          {id: "Funkin", text: "Funkin'"};
    }

    var LIMIT = 6;

    var charDataOpponent:Null<CharacterData> = CharacterDataParser.fetchCharacterData(chartEditorState.currentSongMetadata.playData.characters.opponent);
    if (charDataOpponent != null)
    {
      buttonCharacterOpponent.icon = haxe.ui.util.Variant.fromImageData(CharacterDataParser.getCharPixelIconAsset(chartEditorState.currentSongMetadata.playData.characters.opponent));
      buttonCharacterOpponent.text = charDataOpponent.name.length > LIMIT ? '${charDataOpponent.name.substr(0, LIMIT)}.' : '${charDataOpponent.name}';
    }
    else
    {
      buttonCharacterOpponent.icon = null;
      buttonCharacterOpponent.text = "None";
    }

    var charDataGirlfriend:Null<CharacterData> = CharacterDataParser.fetchCharacterData(chartEditorState.currentSongMetadata.playData.characters.girlfriend);
    if (charDataGirlfriend != null)
    {
      buttonCharacterGirlfriend.icon = haxe.ui.util.Variant.fromImageData(CharacterDataParser.getCharPixelIconAsset(chartEditorState.currentSongMetadata.playData.characters.girlfriend));
      buttonCharacterGirlfriend.text = charDataGirlfriend.name.length > LIMIT ? '${charDataGirlfriend.name.substr(0, LIMIT)}.' : '${charDataGirlfriend.name}';
    }
    else
    {
      buttonCharacterGirlfriend.icon = null;
      buttonCharacterGirlfriend.text = "None";
    }

    var charDataPlayer:Null<CharacterData> = CharacterDataParser.fetchCharacterData(chartEditorState.currentSongMetadata.playData.characters.player);
    if (charDataPlayer != null)
    {
      buttonCharacterPlayer.icon = haxe.ui.util.Variant.fromImageData(CharacterDataParser.getCharPixelIconAsset(chartEditorState.currentSongMetadata.playData.characters.player));
      buttonCharacterPlayer.text = charDataPlayer.name.length > LIMIT ? '${charDataPlayer.name.substr(0, LIMIT)}.' : '${charDataPlayer.name}';
    }
    else
    {
      buttonCharacterPlayer.icon = null;
      buttonCharacterPlayer.text = "None";
    }
    if (chartEditorState.songMetadata.size() == 1 && chartEditorState.availableDifficulties.length == 1) buttonRemove.disabled = true;
    else
      buttonRemove.disabled = false;

    refreshTreeSelection();
  }

  public static function build(chartEditorState:ChartEditorState):ChartEditorMetadataToolbox
  {
    return new ChartEditorMetadataToolbox(chartEditorState);
  }
}
#end
