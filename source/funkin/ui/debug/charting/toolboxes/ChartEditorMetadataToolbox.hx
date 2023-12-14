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

  public function new(state2:ChartEditorState)
  {
    super(state2);

    initialize();

    this.onDialogClosed = onClose;
  }

  function onClose(event:UIEvent)
  {
    state.menubarItemToggleToolboxMetadata.selected = false;
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
        state.currentSongMetadata.songName = event.target.text;
      }
      else
      {
        state.currentSongMetadata.songName = '';
      }
    };

    inputSongArtist.onChange = function(event:UIEvent) {
      var valid:Bool = event.target.text != null && event.target.text != '';

      if (valid)
      {
        inputSongArtist.removeClass('invalid-value');
        state.currentSongMetadata.artist = event.target.text;
      }
      else
      {
        state.currentSongMetadata.artist = '';
      }
    };

    inputStage.onChange = function(event:UIEvent) {
      var valid:Bool = event.data != null && event.data.id != null;

      if (valid)
      {
        state.currentSongMetadata.playData.stage = event.data.id;
      }
    };
    var startingValueStage = ChartEditorDropdowns.populateDropdownWithStages(inputStage, state.currentSongMetadata.playData.stage);
    inputStage.value = startingValueStage;

    inputNoteStyle.onChange = function(event:UIEvent) {
      if (event.data?.id == null) return;
      state.currentSongNoteStyle = event.data.id;
    };

    inputBPM.onChange = function(event:UIEvent) {
      if (event.value == null || event.value <= 0) return;

      // Use a command so we can undo/redo this action.
      var startingBPM = state.currentSongMetadata.timeChanges[0].bpm;
      if (event.value != startingBPM)
      {
        state.performCommand(new ChangeStartingBPMCommand(event.value));
      }
    };

    inputOffsetInst.onChange = function(event:UIEvent) {
      if (event.value == null) return;

      state.currentInstrumentalOffset = event.value;
      Conductor.instance.instrumentalOffset = event.value;
      // Update song length.
      state.songLengthInMs = (state.audioInstTrack?.length ?? 1000.0) + Conductor.instance.instrumentalOffset;
    };

    inputOffsetVocal.onChange = function(event:UIEvent) {
      if (event.value == null) return;

      state.currentSongMetadata.offsets.setVocalOffset(state.currentSongMetadata.playData.characters.player, event.value);
    };
    inputScrollSpeed.onChange = function(event:UIEvent) {
      var valid:Bool = event.target.value != null && event.target.value > 0;

      if (valid)
      {
        inputScrollSpeed.removeClass('invalid-value');
        state.currentSongChartScrollSpeed = event.target.value;
      }
      else
      {
        state.currentSongChartScrollSpeed = 1.0;
      }
      labelScrollSpeed.text = 'Scroll Speed: ${state.currentSongChartScrollSpeed}x';
    };

    buttonCharacterOpponent.onClick = function(_) {
      state.openCharacterDropdown(CharacterType.DAD, false);
    };

    buttonCharacterGirlfriend.onClick = function(_) {
      state.openCharacterDropdown(CharacterType.GF, false);
    };

    buttonCharacterPlayer.onClick = function(_) {
      state.openCharacterDropdown(CharacterType.BF, false);
    };

    refresh();
  }

  public override function refresh():Void
  {
    inputSongName.value = state.currentSongMetadata.songName;
    inputSongArtist.value = state.currentSongMetadata.artist;
    inputStage.value = state.currentSongMetadata.playData.stage;
    inputNoteStyle.value = state.currentSongMetadata.playData.noteStyle;
    inputBPM.value = state.currentSongMetadata.timeChanges[0].bpm;
    inputScrollSpeed.value = state.currentSongChartScrollSpeed;
    labelScrollSpeed.text = 'Scroll Speed: ${state.currentSongChartScrollSpeed}x';
    frameVariation.text = 'Variation: ${state.selectedVariation.toTitleCase()}';
    frameDifficulty.text = 'Difficulty: ${state.selectedDifficulty.toTitleCase()}';

    var stageId:String = state.currentSongMetadata.playData.stage;
    var stageData:Null<StageData> = StageDataParser.parseStageData(stageId);
    if (inputStage != null)
    {
      inputStage.value = (stageData != null) ?
        {id: stageId, text: stageData.name} :
          {id: "mainStage", text: "Main Stage"};
    }

    var LIMIT = 6;

    var charDataOpponent:CharacterData = CharacterDataParser.fetchCharacterData(state.currentSongMetadata.playData.characters.opponent);
    buttonCharacterOpponent.icon = CharacterDataParser.getCharPixelIconAsset(state.currentSongMetadata.playData.characters.opponent);
    buttonCharacterOpponent.text = charDataOpponent.name.length > LIMIT ? '${charDataOpponent.name.substr(0, LIMIT)}.' : '${charDataOpponent.name}';

    var charDataGirlfriend:CharacterData = CharacterDataParser.fetchCharacterData(state.currentSongMetadata.playData.characters.girlfriend);
    buttonCharacterGirlfriend.icon = CharacterDataParser.getCharPixelIconAsset(state.currentSongMetadata.playData.characters.girlfriend);
    buttonCharacterGirlfriend.text = charDataGirlfriend.name.length > LIMIT ? '${charDataGirlfriend.name.substr(0, LIMIT)}.' : '${charDataGirlfriend.name}';

    var charDataPlayer:CharacterData = CharacterDataParser.fetchCharacterData(state.currentSongMetadata.playData.characters.player);
    buttonCharacterPlayer.icon = CharacterDataParser.getCharPixelIconAsset(state.currentSongMetadata.playData.characters.player);
    buttonCharacterPlayer.text = charDataPlayer.name.length > LIMIT ? '${charDataPlayer.name.substr(0, LIMIT)}.' : '${charDataPlayer.name}';
  }

  public static function build(state:ChartEditorState):ChartEditorMetadataToolbox
  {
    return new ChartEditorMetadataToolbox(state);
  }
}
