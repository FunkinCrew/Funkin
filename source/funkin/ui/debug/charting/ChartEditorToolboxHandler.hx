package funkin.ui.debug.charting;

import haxe.ui.data.ArrayDataSource;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.play.event.SongEvent;
import funkin.play.song.SongData.SongTimeChange;
import funkin.play.song.SongSerializer;
import funkin.ui.haxeui.components.CharacterPlayer;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Slider;
import haxe.ui.components.TextField;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.Box;
import haxe.ui.containers.Frame;
import haxe.ui.containers.Grid;
import haxe.ui.containers.Group;
import haxe.ui.core.Component;
import haxe.ui.events.UIEvent;

/**
 * Available tools for the chart editor state.
 */
enum ChartEditorToolMode
{
  Select;
  Place;
}

class ChartEditorToolboxHandler
{
  public static function setToolboxState(state:ChartEditorState, id:String, shown:Bool):Void
  {
    if (shown) showToolbox(state, id);
    else
      hideToolbox(state, id);
  }

  public static function showToolbox(state:ChartEditorState, id:String)
  {
    var toolbox:Dialog = state.activeToolboxes.get(id);

    if (toolbox == null) toolbox = initToolbox(state, id);

    if (toolbox != null)
    {
      toolbox.showDialog(false);
    }
    else
    {
      trace('ChartEditorToolboxHandler.showToolbox() - Could not retrieve toolbox: $id');
    }
  }

  public static function hideToolbox(state:ChartEditorState, id:String):Void
  {
    var toolbox:Dialog = state.activeToolboxes.get(id);

    if (toolbox == null) toolbox = initToolbox(state, id);

    if (toolbox != null)
    {
      toolbox.hideDialog(DialogButton.CANCEL);
    }
    else
    {
      trace('ChartEditorToolboxHandler.hideToolbox() - Could not retrieve toolbox: $id');
    }
  }

  public static function minimizeToolbox(state:ChartEditorState, id:String):Void {}

  public static function maximizeToolbox(state:ChartEditorState, id:String):Void {}

  public static function initToolbox(state:ChartEditorState, id:String):Dialog
  {
    var toolbox:Dialog = null;
    switch (id)
    {
      case ChartEditorState.CHART_EDITOR_TOOLBOX_TOOLS_LAYOUT:
        toolbox = buildToolboxToolsLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_NOTEDATA_LAYOUT:
        toolbox = buildToolboxNoteDataLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_EVENTDATA_LAYOUT:
        toolbox = buildToolboxEventDataLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT:
        toolbox = buildToolboxDifficultyLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT:
        toolbox = buildToolboxMetadataLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_CHARACTERS_LAYOUT:
        toolbox = buildToolboxCharactersLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT:
        toolbox = buildToolboxPlayerPreviewLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT:
        toolbox = buildToolboxOpponentPreviewLayout(state);
      default:
        // This happens if you try to load an unknown layout.
        trace('ChartEditorToolboxHandler.initToolbox() - Unknown toolbox ID: $id');
        toolbox = null;
    }

    // This happens if the layout you try to load has a syntax error.
    if (toolbox == null) return null;

    // Make sure we can reuse the toolbox later.
    toolbox.destroyOnClose = false;
    state.activeToolboxes.set(id, toolbox);

    return toolbox;
  }

  public static function getToolbox(state:ChartEditorState, id:String):Dialog
  {
    var toolbox:Dialog = state.activeToolboxes.get(id);

    // Initialize the toolbox without showing it.
    if (toolbox == null) toolbox = initToolbox(state, id);

    return toolbox;
  }

  static function buildToolboxToolsLayout(state:ChartEditorState):Dialog
  {
    var toolbox:Dialog = cast state.buildComponent(ChartEditorState.CHART_EDITOR_TOOLBOX_TOOLS_LAYOUT);

    if (toolbox == null) return null;

    // Starting position.
    toolbox.x = 50;
    toolbox.y = 50;

    toolbox.onDialogClosed = (event:DialogEvent) -> {
      state.setUICheckboxSelected('menubarItemToggleToolboxTools', false);
    }

    var toolsGroup:Group = toolbox.findComponent("toolboxToolsGroup", Group);

    if (toolsGroup == null) return null;

    toolsGroup.onChange = (event:UIEvent) -> {
      switch (event.target.id)
      {
        case 'toolboxToolsGroupSelect':
          state.currentToolMode = ChartEditorToolMode.Select;
        case 'toolboxToolsGroupPlace':
          state.currentToolMode = ChartEditorToolMode.Place;
        default:
          trace('ChartEditorToolboxHandler.buildToolboxToolsLayout() - Unknown toolbox tool selected: $event.target.id');
      }
    }

    return toolbox;
  }

  static function buildToolboxNoteDataLayout(state:ChartEditorState):Dialog
  {
    var toolbox:Dialog = cast state.buildComponent(ChartEditorState.CHART_EDITOR_TOOLBOX_NOTEDATA_LAYOUT);

    if (toolbox == null) return null;

    // Starting position.
    toolbox.x = 75;
    toolbox.y = 100;

    toolbox.onDialogClosed = (event:DialogEvent) -> {
      state.setUICheckboxSelected('menubarItemToggleToolboxNotes', false);
    }

    var toolboxNotesNoteKind:DropDown = toolbox.findComponent("toolboxNotesNoteKind", DropDown);
    var toolboxNotesCustomKindLabel:Label = toolbox.findComponent("toolboxNotesCustomKindLabel", Label);
    var toolboxNotesCustomKind:TextField = toolbox.findComponent("toolboxNotesCustomKind", TextField);

    toolboxNotesNoteKind.onChange = (event:UIEvent) -> {
      var isCustom = (event.data.id == '~CUSTOM~');

      if (isCustom)
      {
        toolboxNotesCustomKindLabel.hidden = false;
        toolboxNotesCustomKind.hidden = false;

        state.selectedNoteKind = toolboxNotesCustomKind.text;
      }
      else
      {
        toolboxNotesCustomKindLabel.hidden = true;
        toolboxNotesCustomKind.hidden = true;

        state.selectedNoteKind = event.data.id;
      }
    }

    toolboxNotesCustomKind.onChange = (event:UIEvent) -> {
      state.selectedNoteKind = toolboxNotesCustomKind.text;
    }

    return toolbox;
  }

  static function buildToolboxEventDataLayout(state:ChartEditorState):Dialog
  {
    var toolbox:Dialog = cast state.buildComponent(ChartEditorState.CHART_EDITOR_TOOLBOX_EVENTDATA_LAYOUT);

    if (toolbox == null) return null;

    // Starting position.
    toolbox.x = 100;
    toolbox.y = 150;

    toolbox.onDialogClosed = (event:DialogEvent) -> {
      state.setUICheckboxSelected('menubarItemToggleToolboxEvents', false);
    }

    var toolboxEventsEventKind:DropDown = toolbox.findComponent("toolboxEventsEventKind", DropDown);
    var toolboxEventsDataGrid:Grid = toolbox.findComponent("toolboxEventsDataGrid", Grid);

    toolboxEventsEventKind.dataSource = new ArrayDataSource();

    var songEvents:Array<SongEvent> = SongEventParser.listEvents();

    for (event in songEvents)
    {
      toolboxEventsEventKind.dataSource.add({text: event.getTitle(), value: event.id});
    }

    toolboxEventsEventKind.onChange = (event:UIEvent) -> {
      var eventType:String = event.data.value;

      trace('ChartEditorToolboxHandler.buildToolboxEventDataLayout() - Event type changed: $eventType');

      var schema:SongEventSchema = SongEventParser.getEventSchema(eventType);

      if (schema == null)
      {
        trace('ChartEditorToolboxHandler.buildToolboxEventDataLayout() - Unknown event kind: $eventType');
        return;
      }

      buildEventDataFormFromSchema(state, toolboxEventsDataGrid, schema);
    }

    return toolbox;
  }

  static function buildEventDataFormFromSchema(state:ChartEditorState, target:Box, schema:SongEventSchema):Void
  {
    trace(schema);
    // Clear the frame.
    target.removeAllComponents();

    state.selectedEventData = {};

    for (field in schema)
    {
      // Add a label.
      var label:Label = new Label();
      label.text = field.title;
      target.addComponent(label);

      var input:Component;
      switch (field.type)
      {
        case INTEGER:
          var numberStepper:NumberStepper = new NumberStepper();
          numberStepper.id = field.name;
          numberStepper.step = field.step == null ? 1.0 : field.step;
          numberStepper.min = field.min;
          numberStepper.max = field.max;
          numberStepper.value = field.defaultValue;
          input = numberStepper;
        case FLOAT:
          var numberStepper:NumberStepper = new NumberStepper();
          numberStepper.id = field.name;
          numberStepper.step = field.step == null ? 0.1 : field.step;
          numberStepper.min = field.min;
          numberStepper.max = field.max;
          numberStepper.value = field.defaultValue;
          input = numberStepper;
        case BOOL:
          var checkBox = new CheckBox();
          checkBox.id = field.name;
          checkBox.selected = field.defaultValue == true;
          input = checkBox;
        case ENUM:
          var dropDown:DropDown = new DropDown();
          dropDown.id = field.name;
          dropDown.dataSource = new ArrayDataSource();

          // Add entries to the dropdown.
          for (optionName in field.keys.keys())
          {
            var optionValue = field.keys.get(optionName);
            trace('$optionName : $optionValue');
            dropDown.dataSource.add({value: optionValue, text: optionName});
          }

          dropDown.value = field.defaultValue;

          input = dropDown;
        case STRING:
          input = new TextField();
          input.id = field.name;
          input.text = field.defaultValue;
        default:
          // Unknown type. Display a label so we know what it is.
          input = new Label();
          input.id = field.name;
          input.text = field.type;
      }

      target.addComponent(input);

      input.onChange = (event:UIEvent) -> {
        trace('ChartEditorToolboxHandler.buildEventDataFormFromSchema() - ${event.target.id} = ${event.target.value}');

        if (event.target.value == null) state.selectedEventData.remove(event.target.id);
        else
          state.selectedEventData.set(event.target.id, event.target.value);
      }
    }
  }

  static function buildToolboxDifficultyLayout(state:ChartEditorState):Dialog
  {
    var toolbox:Dialog = cast state.buildComponent(ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);

    if (toolbox == null) return null;

    // Starting position.
    toolbox.x = 125;
    toolbox.y = 200;

    toolbox.onDialogClosed = (event:DialogEvent) -> {
      state.setUICheckboxSelected('menubarItemToggleToolboxDifficulty', false);
    }

    var difficultyToolboxSaveMetadata:Button = toolbox.findComponent("difficultyToolboxSaveMetadata", Button);
    var difficultyToolboxSaveChart:Button = toolbox.findComponent("difficultyToolboxSaveChart", Button);
    var difficultyToolboxSaveAll:Button = toolbox.findComponent("difficultyToolboxSaveAll", Button);
    var difficultyToolboxLoadMetadata:Button = toolbox.findComponent("difficultyToolboxLoadMetadata", Button);
    var difficultyToolboxLoadChart:Button = toolbox.findComponent("difficultyToolboxLoadChart", Button);

    difficultyToolboxSaveMetadata.onClick = (event:UIEvent) -> {
      SongSerializer.exportSongMetadata(state.currentSongMetadata);
    };

    difficultyToolboxSaveChart.onClick = (event:UIEvent) -> {
      SongSerializer.exportSongChartData(state.currentSongChartData);
    };

    difficultyToolboxSaveAll.onClick = (event:UIEvent) -> {
      state.exportAllSongData();
    };

    difficultyToolboxLoadMetadata.onClick = (event:UIEvent) -> {
      // Replace metadata for current variation.
      SongSerializer.importSongMetadataAsync(function(songMetadata) {
        state.currentSongMetadata = songMetadata;
      });
    };

    difficultyToolboxLoadChart.onClick = (event:UIEvent) -> {
      // Replace chart data for current variation.
      SongSerializer.importSongChartDataAsync(function(songChartData) {
        state.currentSongChartData = songChartData;
        state.noteDisplayDirty = true;
      });
    };

    state.difficultySelectDirty = true;

    return toolbox;
  }

  static function buildToolboxMetadataLayout(state:ChartEditorState):Dialog
  {
    var toolbox:Dialog = cast state.buildComponent(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);

    if (toolbox == null) return null;

    // Starting position.
    toolbox.x = 150;
    toolbox.y = 250;

    toolbox.onDialogClosed = (event:DialogEvent) -> {
      state.setUICheckboxSelected('menubarItemToggleToolboxMetadata', false);
    }

    var inputSongName:TextField = toolbox.findComponent('inputSongName', TextField);
    inputSongName.onChange = (event:UIEvent) -> {
      var valid = event.target.text != null && event.target.text != "";

      if (valid)
      {
        inputSongName.removeClass('invalid-value');
        state.currentSongMetadata.songName = event.target.text;
      }
      else
      {
        state.currentSongMetadata.songName = null;
      }
    };

    var inputSongArtist:TextField = toolbox.findComponent('inputSongArtist', TextField);
    inputSongArtist.onChange = (event:UIEvent) -> {
      var valid = event.target.text != null && event.target.text != "";

      if (valid)
      {
        inputSongArtist.removeClass('invalid-value');
        state.currentSongMetadata.artist = event.target.text;
      }
      else
      {
        state.currentSongMetadata.artist = null;
      }
    };

    var inputStage:DropDown = toolbox.findComponent('inputStage', DropDown);
    inputStage.onChange = (event:UIEvent) -> {
      var valid = event.data != null && event.data.id != null;

      if (valid)
      {
        state.currentSongMetadata.playData.stage = event.data.id;
      }
    };

    var inputNoteSkin:DropDown = toolbox.findComponent('inputNoteSkin', DropDown);
    inputNoteSkin.onChange = (event:UIEvent) -> {
      if (event.data.id == null) return;
      state.currentSongMetadata.playData.noteSkin = event.data.id;
    };

    var inputBPM:NumberStepper = toolbox.findComponent('inputBPM', NumberStepper);
    inputBPM.onChange = (event:UIEvent) -> {
      if (event.value == null || event.value <= 0) return;

      var timeChanges = state.currentSongMetadata.timeChanges;
      if (timeChanges == null || timeChanges.length == 0)
      {
        timeChanges = [new SongTimeChange(-1, 0, event.value, 4, 4, [4, 4, 4, 4])];
      }
      else
      {
        timeChanges[0].bpm = event.value;
      }

      Conductor.forceBPM(event.value);

      state.currentSongMetadata.timeChanges = timeChanges;
    };

    var inputScrollSpeed:Slider = toolbox.findComponent('inputScrollSpeed', Slider);
    inputScrollSpeed.onChange = (event:UIEvent) -> {
      var valid = event.target.value != null && event.target.value > 0;

      if (valid)
      {
        inputScrollSpeed.removeClass('invalid-value');
        state.currentSongChartData.scrollSpeed = event.target.value;
      }
      else
      {
        state.currentSongChartData.scrollSpeed = null;
      }
    };

    return toolbox;
  }

  static function buildToolboxCharactersLayout(state:ChartEditorState):Dialog
  {
    var toolbox:Dialog = cast state.buildComponent(ChartEditorState.CHART_EDITOR_TOOLBOX_CHARACTERS_LAYOUT);

    if (toolbox == null) return null;

    // Starting position.
    toolbox.x = 175;
    toolbox.y = 300;

    toolbox.onDialogClosed = (event:DialogEvent) -> {
      state.setUICheckboxSelected('menubarItemToggleToolboxCharacters', false);
    }

    return toolbox;
  }

  static function buildToolboxPlayerPreviewLayout(state:ChartEditorState):Dialog
  {
    var toolbox:Dialog = cast state.buildComponent(ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT);

    if (toolbox == null) return null;

    // Starting position.
    toolbox.x = 200;
    toolbox.y = 350;

    toolbox.onDialogClosed = (event:DialogEvent) -> {
      state.setUICheckboxSelected('menubarItemToggleToolboxPlayerPreview', false);
    }

    var charPlayer:CharacterPlayer = toolbox.findComponent('charPlayer');
    // TODO: We need to implement character swapping in ChartEditorState.
    charPlayer.loadCharacter('bf');
    // charPlayer.setScale(0.5);
    charPlayer.setCharacterType(CharacterType.BF);
    charPlayer.flip = true;

    return toolbox;
  }

  static function buildToolboxOpponentPreviewLayout(state:ChartEditorState):Dialog
  {
    var toolbox:Dialog = cast state.buildComponent(ChartEditorState.CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT);

    if (toolbox == null) return null;

    // Starting position.
    toolbox.x = 200;
    toolbox.y = 350;

    toolbox.onDialogClosed = (event:DialogEvent) -> {
      state.setUICheckboxSelected('menubarItemToggleToolboxOpponentPreview', false);
    }

    var charPlayer:CharacterPlayer = toolbox.findComponent('charPlayer');
    // TODO: We need to implement character swapping in ChartEditorState.
    charPlayer.loadCharacter('dad');
    // charPlayer.setScale(0.5);
    charPlayer.setCharacterType(CharacterType.DAD);
    charPlayer.flip = false;

    return toolbox;
  }
}
