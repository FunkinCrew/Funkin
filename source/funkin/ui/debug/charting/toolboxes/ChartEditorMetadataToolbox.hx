package funkin.ui.debug.charting.toolboxes;

#if FEATURE_CHART_EDITOR
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.data.character.CharacterData;
import funkin.data.character.CharacterRegistry;
import funkin.data.freeplay.album.AlbumRegistry;
import funkin.data.song.importer.ChartManifestData;
import funkin.data.stage.StageRegistry;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.ui.debug.charting.commands.timing.AddNewTimeChangeCommand;
import funkin.ui.debug.charting.commands.timing.ModifyTimeChangeCommand;
import funkin.ui.debug.charting.commands.timing.RemoveTimeChangeCommand;
import funkin.play.stage.Stage;
import funkin.ui.debug.charting.commands.song.SetAudioOffsetCommand;
import funkin.ui.debug.charting.commands.song.SetFreeplayPreviewCommand;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import funkin.ui.freeplay.Album;
import haxe.ui.components.Button;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Slider;
import haxe.ui.components.TextField;
import haxe.ui.containers.Frame;
import haxe.ui.events.UIEvent;

/**
 * The toolbox which allows modifying information like Song Title, Scroll Speed, and Characters/Stages.
 */
// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build('assets/exclude/ui/editors/chart-editor/toolboxes/metadata.xml'))
class ChartEditorMetadataToolbox extends ChartEditorBaseToolbox
{
  var inputSongId:TextField;
  var inputSongName:TextField;
  var inputSongArtist:TextField;
  var inputSongCharter:TextField;
  var inputStage:DropDown;
  var inputNoteStyle:DropDown;
  var inputAlbum:DropDown;
  var inputStickerPack:DropDown;
  var buttonCharacterPlayer:Button;
  var buttonCharacterGirlfriend:Button;
  var buttonCharacterOpponent:Button;
  var inputAudioOffset:NumberStepper;
  var inputPreviewStart:NumberStepper;
  var inputPreviewLength:NumberStepper;
  var buttonPreviewToSelection:Button;

  /**
   * Set while the audio steppers are being filled in, so that doesn't count as an edit.
   */
  var refreshingAudio:Bool = false;
  var frameVariation:Frame;

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

    inputSongId.onChange = function(event:UIEvent)
    {
      var valid:Bool = event.target.text != null && event.target.text != '' && !ChartManifestData.INVALID_ID_REGEX.match(event.target.text);

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

    inputSongName.onChange = function(event:UIEvent)
    {
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

    inputSongArtist.onChange = function(event:UIEvent)
    {
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

    inputSongCharter.onChange = function(event:UIEvent)
    {
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

    inputStage.onChange = function(event:UIEvent)
    {
      var valid:Bool = event.data != null && event.data.id != null;

      if (valid)
      {
        chartEditorState.currentSongMetadata.playData.stage = event.data.id;
      }
    };
    var startingValueStage = ChartEditorDropdowns.populateDropdownWithStages(inputStage, chartEditorState.currentSongMetadata.playData.stage);
    inputStage.value = startingValueStage;

    inputNoteStyle.onChange = function(event:UIEvent)
    {
      var valid:Bool = event.data != null && event.data.id != null;

      if (valid)
      {
        chartEditorState.currentSongNoteStyle = event.data.id;
      }
    };
    var startingValueNoteStyle = ChartEditorDropdowns.populateDropdownWithNoteStyles(inputNoteStyle, chartEditorState.currentSongMetadata.playData.noteStyle);
    inputNoteStyle.value = startingValueNoteStyle;

    inputAlbum.onChange = (event:UIEvent) ->
    {
      var valid:Bool = event.data != null && event.data.id != null;

      if (valid)
      {
        chartEditorState.currentSongAlbum = event.data.id;
      }
    }
    var startingValueAlbum = ChartEditorDropdowns.populateDropdownWithAlbums(inputAlbum, chartEditorState.currentSongMetadata.playData?.album);
    inputAlbum.value = startingValueAlbum;

    inputStickerPack.onChange = (event:UIEvent) ->
    {
      var valid:Bool = event.data != null && event.data.id != null;

      if (valid)
      {
        chartEditorState.currentSongStickerPack = event.data.id;
      }
    }
    var startingValueStickerPack = ChartEditorDropdowns.populateDropdownWithStickerPacks(
      inputStickerPack,
      chartEditorState.currentSongMetadata.playData?.stickerPack
    );
    inputStickerPack.value = startingValueStickerPack;

    inputAudioOffset.onChange = function(event:UIEvent)
    {
      if (refreshingAudio || event.value == null) return;
      var offsetMs:Float = secondsToMs(event.value);
      if (offsetMs == chartEditorState.currentInstrumentalOffset) return;
      chartEditorState.performCommand(new SetAudioOffsetCommand(INSTRUMENTAL, offsetMs));
    };

    inputPreviewStart.onChange = function(event:UIEvent)
    {
      if (refreshingAudio || event.value == null) return;
      var startMs:Float = secondsToMs(event.value);
      if (startMs == chartEditorState.currentSongFreeplayPreviewStart) return;
      var lengthMs:Float = chartEditorState.currentSongFreeplayPreviewEnd - chartEditorState.currentSongFreeplayPreviewStart;
      chartEditorState.performCommand(new SetFreeplayPreviewCommand(startMs, startMs + lengthMs));
    };

    buttonPreviewToSelection.onClick = function(_)
    {
      var start:Null<Float> = chartEditorState.rangeSelectionStartMs;
      var end:Null<Float> = chartEditorState.rangeSelectionEndMs;
      if (start == null || end == null || end <= start)
      {
        chartEditorState.warning('No Selection', 'Press Tab at the start and again at the end of the stretch to use.');
        return;
      }
      // The selection is in chart time, and the preview plays the audio file, which the instrumental offset shifts.
      var offset:Float = chartEditorState.currentInstrumentalOffset;
      var startMs:Float = Math.max(0, Math.round(start - offset));
      var endMs:Float = Math.max(startMs + 1, Math.round(end - offset));
      chartEditorState.performCommand(new SetFreeplayPreviewCommand(startMs, endMs));

      // Consume selection
      chartEditorState.rangeSelectionStartMs = null;
      chartEditorState.rangeSelectionEndMs = null;
    };

    inputPreviewLength.onChange = function(event:UIEvent)
    {
      if (refreshingAudio || event.value == null || event.value <= 0) return;
      var endMs:Float = chartEditorState.currentSongFreeplayPreviewStart + secondsToMs(event.value);
      if (endMs == chartEditorState.currentSongFreeplayPreviewEnd) return;
      chartEditorState.performCommand(new SetFreeplayPreviewCommand(null, endMs));
    };

    buttonCharacterOpponent.onClick = function(_)
    {
      chartEditorState.openCharacterDropdown(CharacterType.DAD, false);
    };

    buttonCharacterGirlfriend.onClick = function(_)
    {
      chartEditorState.openCharacterDropdown(CharacterType.GF, false);
    };

    buttonCharacterPlayer.onClick = function(_)
    {
      chartEditorState.openCharacterDropdown(CharacterType.BF, false);
    };

    refresh();
  }

  static function secondsToMs(seconds:Float):Float
  {
    return Math.round(seconds * Constants.MS_PER_SEC);
  }

  static function msToSeconds(ms:Float):Float
  {
    return Math.round(ms) / Constants.MS_PER_SEC;
  }

  /**
   * Set the value of a stepper if it has changed.
   */
  static function setStepper(stepper:NumberStepper, value:Float):Void
  {
    if (stepper.value != value) stepper.value = value;
  }

  override public function refresh():Void
  {
    super.refresh();

    inputSongId.value = chartEditorState.songManifestData.songId;
    inputSongName.value = chartEditorState.currentSongMetadata.songName;
    inputSongArtist.value = chartEditorState.currentSongMetadata.artist;
    inputSongCharter.value = chartEditorState.currentSongMetadata.charter;
    inputStage.value = chartEditorState.currentSongMetadata.playData.stage;
    inputNoteStyle.value = chartEditorState.currentSongMetadata.playData.noteStyle;
    inputAlbum.value = chartEditorState.currentSongMetadata.playData.album;

    refreshingAudio = true;
    setStepper(inputAudioOffset, msToSeconds(chartEditorState.currentInstrumentalOffset));
    setStepper(inputPreviewStart, msToSeconds(chartEditorState.currentSongFreeplayPreviewStart));
    setStepper(inputPreviewLength, msToSeconds(chartEditorState.currentSongFreeplayPreviewEnd - chartEditorState.currentSongFreeplayPreviewStart));
    refreshingAudio = false;
    frameVariation.text = 'Variation: ${chartEditorState.selectedVariation.toTitleCase()}';

    var stageId:String = chartEditorState.currentSongMetadata.playData.stage;
    var stage:Null<Stage> = StageRegistry.instance.fetchEntry(stageId);
    if (inputStage != null)
    {
      inputStage.value = (stage != null) ? {
        id: stage.id,
        text: stage.stageName
      } : {
        id: 'mainStage',
        text: 'Main Stage'
        };
    }

    var noteStyleId:String = chartEditorState.currentSongNoteStyle;
    var noteStyle:Null<NoteStyle> = NoteStyleRegistry.instance.fetchEntry(noteStyleId);
    if (inputNoteStyle != null)
    {
      inputNoteStyle.value = (noteStyle != null) ? {
        id: noteStyle.id,
        text: noteStyle.getName()
      } : {
        id: 'Funkin',
        text: "Funkin'"
        };
    }

    var albumId:String = chartEditorState.currentSongAlbum;
    var album:Null<Album> = AlbumRegistry.instance.fetchEntry(albumId);
    if (inputAlbum != null)
    {
      inputAlbum.value = (album != null) ? {
        id: album.id,
        text: album.getAlbumName()
      } : {
        id: 'volume1',
        text: 'Volume 1'
        };
    }

    var LIMIT = 6;

    var charDataOpponent:Null<CharacterData> = CharacterRegistry.instance.fetchCharacterData(
      chartEditorState.currentSongMetadata.playData.characters.opponent
    );
    if (charDataOpponent != null)
    {
      var opponentIcon = CharacterRegistry.getCharPixelIconAsset(chartEditorState.currentSongMetadata.playData.characters.opponent);
      buttonCharacterOpponent.icon = opponentIcon != null ? haxe.ui.util.Variant.fromImageData(opponentIcon) : null;
      buttonCharacterOpponent.text = charDataOpponent.name.length > LIMIT ? '${charDataOpponent.name.substr(0, LIMIT)}.' : '${charDataOpponent.name}';
    }
    else
    {
      buttonCharacterOpponent.icon = null;
      buttonCharacterOpponent.text = 'None';
    }

    var charDataGirlfriend:Null<CharacterData> = CharacterRegistry.instance.fetchCharacterData(
      chartEditorState.currentSongMetadata.playData.characters.girlfriend
    );
    if (charDataGirlfriend != null)
    {
      var girlfriendIcon = CharacterRegistry.getCharPixelIconAsset(chartEditorState.currentSongMetadata.playData.characters.girlfriend);
      buttonCharacterGirlfriend.icon = girlfriendIcon != null ? haxe.ui.util.Variant.fromImageData(girlfriendIcon) : null;
      buttonCharacterGirlfriend.text = charDataGirlfriend.name.length > LIMIT ? '${charDataGirlfriend.name.substr(0, LIMIT)}.' : '${charDataGirlfriend.name}';
    }
    else
    {
      buttonCharacterGirlfriend.icon = null;
      buttonCharacterGirlfriend.text = 'None';
    }

    var charDataPlayer:Null<CharacterData> = CharacterRegistry.instance.fetchCharacterData(chartEditorState.currentSongMetadata.playData.characters.player);
    if (charDataPlayer != null)
    {
      var playerIcon = CharacterRegistry.getCharPixelIconAsset(chartEditorState.currentSongMetadata.playData.characters.player);
      buttonCharacterPlayer.icon = playerIcon != null ? haxe.ui.util.Variant.fromImageData(playerIcon) : null;
      buttonCharacterPlayer.text = charDataPlayer.name.length > LIMIT ? '${charDataPlayer.name.substr(0, LIMIT)}.' : '${charDataPlayer.name}';
    }
    else
    {
      buttonCharacterPlayer.icon = null;
      buttonCharacterPlayer.text = 'None';
    }
  }

  public static function build(chartEditorState:ChartEditorState):ChartEditorMetadataToolbox
  {
    return new ChartEditorMetadataToolbox(chartEditorState);
  }
}
#end
