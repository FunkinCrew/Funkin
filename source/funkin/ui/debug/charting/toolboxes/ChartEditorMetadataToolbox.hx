package funkin.ui.debug.charting.toolboxes;

import funkin.play.character.BaseCharacter.CharacterType;
import funkin.play.character.CharacterData;
import funkin.data.stage.StageRegistry;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.ui.debug.charting.commands.ChangeStartingBPMCommand;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import haxe.ui.components.Button;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Slider;
import haxe.ui.components.TextField;
import funkin.play.stage.Stage;
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
  var inputSongCharter:TextField;
  var inputStage:DropDown;
  var inputNoteStyle:DropDown;
  var buttonCharacterPlayer:Button;
  var buttonCharacterGirlfriend:Button;
  var buttonCharacterOpponent:Button;
  var inputBPM:NumberStepper;
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

    inputBPM.onChange = function(event:UIEvent) {
      if (event.value == null || event.value <= 0) return;

      // Use a command so we can undo/redo this action.
      if (event.value != Conductor.instance.bpm)
      {
        chartEditorState.performCommand(new ChangeStartingBPMCommand(event.value));
      }
    };

    inputTimeSignature.onChange = function(event:UIEvent) {
      var timeSignatureStr:String = event.data.text;
      var timeSignature = timeSignatureStr.split('/');
      if (timeSignature.length != 2) return;

      var timeSignatureNum:Int = Std.parseInt(timeSignature[0]);
      var timeSignatureDen:Int = Std.parseInt(timeSignature[1]);

      var previousTimeSignatureNum:Int = chartEditorState.currentSongMetadata.timeChanges[0].timeSignatureNum;
      var previousTimeSignatureDen:Int = chartEditorState.currentSongMetadata.timeChanges[0].timeSignatureDen;
      if (timeSignatureNum == previousTimeSignatureNum && timeSignatureDen == previousTimeSignatureDen) return;

      chartEditorState.currentSongMetadata.timeChanges[0].timeSignatureNum = timeSignatureNum;
      chartEditorState.currentSongMetadata.timeChanges[0].timeSignatureDen = timeSignatureDen;

      trace('Time signature changed to ${timeSignatureNum}/${timeSignatureDen}');

      chartEditorState.updateTimeSignature();
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

    refresh();
  }

  public override function refresh():Void
  {
    super.refresh();

    inputSongName.value = chartEditorState.currentSongMetadata.songName;
    inputSongArtist.value = chartEditorState.currentSongMetadata.artist;
    inputSongCharter.value = chartEditorState.currentSongMetadata.charter;
    inputStage.value = chartEditorState.currentSongMetadata.playData.stage;
    inputNoteStyle.value = chartEditorState.currentSongNoteStyle;
    inputBPM.value = chartEditorState.currentSongMetadata.timeChanges[0].bpm;
    inputDifficultyRating.value = chartEditorState.currentSongChartDifficultyRating;
    inputScrollSpeed.value = chartEditorState.currentSongChartScrollSpeed;
    labelScrollSpeed.text = 'Scroll Speed: ${chartEditorState.currentSongChartScrollSpeed}x';
    frameVariation.text = 'Variation: ${chartEditorState.selectedVariation.toTitleCase()}';
    frameDifficulty.text = 'Difficulty: ${chartEditorState.selectedDifficulty.toTitleCase()}';

    if (chartEditorState.currentSongMetadata.timeChanges[0].bpm != Conductor.instance.bpm)
    {
      chartEditorState.performCommand(new ChangeStartingBPMCommand(chartEditorState.currentSongMetadata.timeChanges[0].bpm));
    }

    var currentTimeSignature = '${chartEditorState.currentSongMetadata.timeChanges[0].timeSignatureNum}/${chartEditorState.currentSongMetadata.timeChanges[0].timeSignatureDen}';
    trace('Setting time signature to ${currentTimeSignature}');
    inputTimeSignature.value = {id: currentTimeSignature, text: currentTimeSignature};

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
  }

  public static function build(chartEditorState:ChartEditorState):ChartEditorMetadataToolbox
  {
    return new ChartEditorMetadataToolbox(chartEditorState);
  }
}
