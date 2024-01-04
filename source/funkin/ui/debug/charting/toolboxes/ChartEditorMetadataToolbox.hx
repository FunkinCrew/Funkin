package funkin.ui.debug.charting.toolboxes;

import funkin.play.character.BaseCharacter.CharacterType;
import funkin.play.character.CharacterData;
import funkin.play.stage.StageData;
import funkin.ui.debug.charting.commands.ChangeStartingBPMCommand;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.HorizontalSlider;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Slider;
import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.containers.Frame;
import haxe.ui.events.UIEvent;

/**
 * The toolbox which allows modifying information like Song Title, Scroll Speed, Characters/Stages, and starting BPM.
 */
// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/toolboxes/metadata.xml"))
class ChartEditorMetadataToolbox extends ChartEditorBaseToolbox
{
  var inputSongName:TextField;
  var inputSongArtist:TextField;
  var inputStage:DropDown;
  var inputNoteStyle:DropDown;
  var buttonCharacterPlayer:Button;
  var buttonCharacterGirlfriend:Button;
  var buttonCharacterOpponent:Button;
  var inputBPM:NumberStepper;
  var inputOffsetInst:NumberStepper;
  var inputOffsetVocal:NumberStepper;
  var labelScrollSpeed:Label;
  var inputScrollSpeed:Slider;
  var frameVariation:Frame;
  var frameDifficulty:Frame;

  public function new(chartEditorState2:ChartEditorState)
  {
    super(chartEditorState2);

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
      if (event.data?.id == null) return;
      chartEditorState.currentSongNoteStyle = event.data.id;
    };

    inputBPM.onChange = function(event:UIEvent) {
      if (event.value == null || event.value <= 0) return;

      // Use a command so we can undo/redo this action.
      var startingBPM = chartEditorState.currentSongMetadata.timeChanges[0].bpm;
      if (event.value != startingBPM)
      {
        chartEditorState.performCommand(new ChangeStartingBPMCommand(event.value));
      }
    };

    inputOffsetInst.onChange = function(event:UIEvent) {
      if (event.value == null) return;

      chartEditorState.currentInstrumentalOffset = event.value;
      Conductor.instrumentalOffset = event.value;
      // Update song length.
      chartEditorState.songLengthInMs = (chartEditorState.audioInstTrack?.length ?? 1000.0) + Conductor.instrumentalOffset;
    };

    inputOffsetVocal.onChange = function(event:UIEvent) {
      if (event.value == null) return;

      chartEditorState.currentSongMetadata.offsets.setVocalOffset(chartEditorState.currentSongMetadata.playData.characters.player, event.value);
    };
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

    buttonCharacterOpponent.onClick = function(_) {
      chartEditorState.openCharacterDropdown(CharacterType.DAD, false);
    };

    buttonCharacterGirlfriend.onClick = function(_) {
      chartEditorState.openCharacterDropdown(CharacterType.GF, false);
    };

    buttonCharacterPlayer.onClick = function(_) {
      chartEditorState.openCharacterDropdown(CharacterType.BF, false);
    };

    refresh();
  }

  public override function refresh():Void
  {
    super.refresh();

    inputSongName.value = chartEditorState.currentSongMetadata.songName;
    inputSongArtist.value = chartEditorState.currentSongMetadata.artist;
    inputStage.value = chartEditorState.currentSongMetadata.playData.stage;
    inputNoteStyle.value = chartEditorState.currentSongMetadata.playData.noteStyle;
    inputBPM.value = chartEditorState.currentSongMetadata.timeChanges[0].bpm;
    inputScrollSpeed.value = chartEditorState.currentSongChartScrollSpeed;
    labelScrollSpeed.text = 'Scroll Speed: ${chartEditorState.currentSongChartScrollSpeed}x';
    frameVariation.text = 'Variation: ${chartEditorState.selectedVariation.toTitleCase()}';
    frameDifficulty.text = 'Difficulty: ${chartEditorState.selectedDifficulty.toTitleCase()}';

    var stageId:String = chartEditorState.currentSongMetadata.playData.stage;
    var stageData:Null<StageData> = StageDataParser.parseStageData(stageId);
    if (inputStage != null)
    {
      inputStage.value = (stageData != null) ?
        {id: stageId, text: stageData.name} :
          {id: "mainStage", text: "Main Stage"};
    }

    var LIMIT = 6;

    var charDataOpponent:Null<CharacterData> = CharacterDataParser.fetchCharacterData(chartEditorState.currentSongMetadata.playData.characters.opponent);
    if (charDataOpponent != null)
    {
      buttonCharacterOpponent.icon = CharacterDataParser.getCharPixelIconAsset(chartEditorState.currentSongMetadata.playData.characters.opponent);
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
      buttonCharacterGirlfriend.icon = CharacterDataParser.getCharPixelIconAsset(chartEditorState.currentSongMetadata.playData.characters.girlfriend);
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
      buttonCharacterPlayer.icon = CharacterDataParser.getCharPixelIconAsset(chartEditorState.currentSongMetadata.playData.characters.player);
      buttonCharacterPlayer.text = charDataPlayer.name.length > LIMIT ? '${charDataPlayer.name.substr(0, LIMIT)}.' : '${charDataPlayer.name}';
    }
    else
    {
      buttonCharacterPlayer.icon = null;
      buttonCharacterPlayer.text = "None";
    }
  }

  public static function build(chartEditorState:ChartEditorState):ChartEditorMetadataToolbox
  {
    return new ChartEditorMetadataToolbox(chartEditorState);
  }
}
