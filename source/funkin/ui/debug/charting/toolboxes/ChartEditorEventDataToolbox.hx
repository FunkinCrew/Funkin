package funkin.ui.debug.charting.toolboxes;

#if FEATURE_CHART_EDITOR
import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import funkin.data.animation.AnimationData;
import funkin.data.character.CharacterRegistry;
import funkin.data.event.SongEventRegistry;
import funkin.data.event.SongEventSchema;
import funkin.data.event.SongEventSchema.SongEventSchemaField;
import funkin.util.Constants;
import funkin.data.stage.StageData.StageDataProp;
import funkin.data.stage.StageRegistry;
import funkin.play.event.CustomSongEvent;
import funkin.play.event.PlayAnimationSongEvent;
import funkin.ui.haxeui.components.CustomEventParamsList;
import funkin.play.event.SongEvent;
import funkin.play.event.SongEventHelper;
import funkin.play.stage.Stage;
import funkin.ui.debug.charting.commands.events.EditEventsCommand;
import funkin.ui.debug.charting.commands.selection.SetItemSelectionCommand;
import funkin.ui.debug.charting.handlers.ui.ChartEditorContextMenuHandler;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import funkin.data.song.SongData.SongEventData;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.MenuSeparator;
import haxe.Timer;
import haxe.ui.backend.ImageData;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.containers.Frame;
import haxe.ui.containers.Grid;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.data.ArrayDataSource;
import haxe.ui.events.UIEvent;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * The toolbox which allows modifying information like Song Title, Scroll Speed, Characters/Stages, and starting BPM.
 */
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build('assets/exclude/ui/editors/chart-editor/toolboxes/event-data.xml'))
class ChartEditorEventDataToolbox extends ChartEditorBaseToolbox implements ChartEditorListKeyTarget
{
  var toolboxEventsEventKind:DropDown;
  var toolboxEventsDataBox:VBox;
  var toolboxEventsChainBox:VBox;
  var toolboxEventsChainTitle:Label;
  var toolboxEventsChainList:VBox;
  var toolboxEventsChainScroll:haxe.ui.containers.ScrollView;
  var toolboxEventsDataScroll:haxe.ui.containers.ScrollView;

  /**
   * The tallest the chain list and the event data get before they scroll.
   */
  static final MAX_CHAIN_LIST_HEIGHT:Float = 96;

  static final MAX_EVENT_DATA_HEIGHT:Float = 380;

  /**
   * The shortest they get, so a short list or form doesn't leave the panel cramped.
   */
  static final MIN_CHAIN_LIST_HEIGHT:Float = 64;

  static final MIN_EVENT_DATA_HEIGHT:Float = 240;

  var toolboxEventsChainBeat:NumberStepper;

  /**
   * Where the picked event sits in the chain.
   */
  var chainActiveIndex:Int = 0;

  /**
   * The events the Beat stepper moves.
   */
  var movingGroup:Array<SongEventData> = [];

  /**
   * Set while the Beat stepper's move runs.
   */
  var movingByBeat:Bool = false;

  static function sameEvents(a:Array<SongEventData>, b:Array<SongEventData>):Bool
  {
    if (a.length != b.length) return false;
    for (event in a) if (!b.contains(event)) return false;
    return true;
  }

  /**
   * Set while the beat stepper is being filled in, so that doesn't move the events.
   */
  var refreshingBeat:Bool = false;

  /**
   * The events at the selected time, when the selection is one event chain or a single event.
   */
  var chainEvents:Array<SongEventData> = [];

  /**
   * The event in the chain the form edits.
   */
  var chainActive:Null<SongEventData> = null;

  /**
   * Events in the chain that are hovered over, which get highlighted in the list and the chart.
   */
  var chainPicked:Array<SongEventData> = [];

  static final CHAIN_ROW_STYLE:String = 'padding: 4px; padding-left: 8px; background-opacity: 0;';
  static final CHAIN_ACTIVE_STYLE:String = 'background-color: #3C8DF0; background-opacity: 0.45;';
  static final CHAIN_HOVER_STYLE:String = 'background-color: #888888; background-opacity: 0.2;';
  static final CHAIN_DIM_STYLE:String = 'color: #888888;';

  var easeGraphImage:Image;
  var easeDotImage:Image;
  var _easeGraphSprite:Null<flixel.FlxSprite> = null;
  var _easeDotSprites:Array<flixel.FlxSprite> = [];
  var _dotTimer:Null<FlxTimer> = null;
  var _pauseTimer:Null<FlxTimer> = null;
  var _dotIndex:Int = 0;

  static var _dotInterval:Float = 1.0 / 30.0;
  static var _loopPause:Float = 0.15;

  var _initializing:Bool = true;

  /**
   * If `true`, changing the value of the Event Kind dropdown will trigger the `onEventKindChanged` callback,
   * modifying the event kind of all selected events.
   * Set to `false` to safety modify the dropdown directly, without modifying placed events.
   */
  var shouldTriggerOnEventKindChanged(default, set):Bool = true;

  function set_shouldTriggerOnEventKindChanged(value:Bool):Bool
  {
    shouldTriggerOnEventKindChanged = value;

    if (!shouldTriggerOnEventKindChanged)
    {
      toolboxEventsEventKind.pauseEvent(UIEvent.CHANGE, true);
    }
    else
    {
      toolboxEventsEventKind.resumeEvent(UIEvent.CHANGE, true, true);
    }

    return shouldTriggerOnEventKindChanged;
  }

  public function new(chartEditorState2:ChartEditorState)
  {
    super(chartEditorState2);

    initialize();

    this.onDialogClosed = onClose;
    this.registerEvent(UIEvent.RESIZE, _ -> fitScrollHeights());

    this._initializing = false;
  }

  function onClose(event:UIEvent)
  {
    chartEditorState.menubarItemToggleToolboxEventData.selected = false;
  }

  function initialize():Void
  {
    toolboxEventsEventKind.onChange = onEventKindChanged;
    shouldTriggerOnEventKindChanged = false;

    var startingEventValue = ChartEditorDropdowns.populateDropdownWithSongEvents(toolboxEventsEventKind, chartEditorState.eventKindToPlace);
    toolboxEventsEventKind.value = startingEventValue;

    toolboxEventsChainList.registerEvent(haxe.ui.events.MouseEvent.MOUSE_MOVE, function(event:haxe.ui.events.MouseEvent)
    {
      updateChainHover(event.screenX, event.screenY);
    });
    toolboxEventsChainList.registerEvent(haxe.ui.events.MouseEvent.MOUSE_OUT, function(_)
    {
      updateChainHover(null, null);
    });

    toolboxEventsChainBeat.onChange = function(event:UIEvent)
    {
      if (refreshingBeat || event.value == null || movingGroup.length == 0) return;
      var targetMs:Float = Conductor.instance.getBeatTimeInMs(event.value);
      // Moving puts every moved event on the same time.
      var allThere:Bool = true;
      for (moving in movingGroup) if (Math.abs(targetMs - moving.time) >= 0.5) allThere = false;
      if (allThere) return;
      movingByBeat = true;
      chartEditorState.performCommand(new funkin.ui.debug.charting.commands.events.MoveEventsCommand(movingGroup, targetMs, true));
      movingByBeat = false;
      // The command swaps the events for moved copies and selects them.
      movingGroup = chartEditorState.currentEventSelection.copy();
      refresh();
    };

    shouldTriggerOnEventKindChanged = true;
  }

  function onEventKindChanged(event:UIEvent):Void
  {
    if (event.data == null)
    {
      return;
    }

    var eventKind:String = event.data.id;
    var sameEvent:Bool = (eventKind == chartEditorState.eventKindToPlace);

    trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Event toolbox changed kind to "$eventKind"');

    // Edit the event data to place.
    chartEditorState.eventKindToPlace = eventKind;

    var schema:SongEventSchema = SongEventRegistry.getEventSchema(eventKind);

    if (schema == null)
    {
      chartEditorState.warning('Invalid Event Kind', 'Event toolbox tried to use unknown event kind "$eventKind", did you define a schema?');
      return;
    }

    if (!sameEvent) chartEditorState.eventDataToPlace = {};
    buildEventDataFormFromSchema(toolboxEventsDataBox, schema, chartEditorState.eventKindToPlace);

    if (!_initializing && chartEditorState.currentEventSelection.length > 0)
    {
      // Edit the event data of any selected events.
      chartEditorState.success(
        'Modified Events',
        'Switching ${chartEditorState.currentEventSelection.length} events to "${chartEditorState.eventKindToPlace}"'
      );
      var targets:Array<SongEventData> = editTargets();
      var before = EditEventsCommand.snapshot(targets);
      for (event in targets)
      {
        event.eventKind = chartEditorState.eventKindToPlace;
        event.value = Reflect.copy(chartEditorState.eventDataToPlace);
      }
      EditEventsCommand.push(chartEditorState, targets, before, 'eventKind');
      refreshChainList();
      chartEditorState.saveDataDirty = true;
      chartEditorState.noteDisplayDirty = true;
      chartEditorState.notePreviewDirty = true;
    }
  }

  override public function refresh():Void
  {
    super.refresh();

    refreshChain();
    refreshOptionLists();

    shouldTriggerOnEventKindChanged = false;

    var newDropdownElement = ChartEditorDropdowns.findDropdownElement(chartEditorState.eventKindToPlace, toolboxEventsEventKind);

    if (newDropdownElement == null)
    {
      trace(' WARNING '.bold().bg_yellow() + ' CHART EDITOR - Event kind "${chartEditorState.eventKindToPlace}" not found in dropdown lookup. Attempting to proceed...');
      newDropdownElement = toolboxEventsEventKind.dataSource.get(0);
    }
    else if (toolboxEventsEventKind.value != newDropdownElement || lastEventKind != toolboxEventsEventKind.value.id)
    {
      toolboxEventsEventKind.value = newDropdownElement;

      var schema:SongEventSchema = SongEventRegistry.getEventSchema(chartEditorState.eventKindToPlace);
      if (schema == null)
      {
        chartEditorState.warning(
          'Invalid Event Kind',
          'Event toolbox tried to use unknown event kind "${chartEditorState.eventKindToPlace}", did you define a schema?'
        );
      }
      else
      {
        buildEventDataFormFromSchema(toolboxEventsDataBox, schema, chartEditorState.eventKindToPlace);
      }
    }
    else
    {
      trace('ChartEditorEventDataToolbox - Event kind not changed: ${toolboxEventsEventKind.value} == ${newDropdownElement} == ${lastEventKind}');
    }

    var currentSchema:Null<SongEventSchema> = SongEventRegistry.getEventSchema(chartEditorState.eventKindToPlace);
    if (currentSchema != null) resetMissingFields(currentSchema);

    for (pair in chartEditorState.eventDataToPlace.keyValueIterator())
    {
      var fieldId:String = pair.key;
      var value:Null<Dynamic> = pair.value;

      var field:Component = toolboxEventsDataBox.findComponent(fieldId);

      if (field != null)
      {
        field.pauseEvent(UIEvent.CHANGE, true);

        switch (Type.getClass(field))
        {
          case NumberStepper:
            var numberStepper:NumberStepper = cast field;
            numberStepper.value = beatFields.exists(fieldId) ? stepsToBeats(value) : value;
          case CheckBox:
            var checkBox:CheckBox = cast field;
            checkBox.selected = value;
          case DropDown:
            var dropDown:DropDown = cast field;
            if (isOptionField(fieldId)) selectOption(dropDown, value);
            else
              dropDown.value = value;
          case TextField:
            var textField:TextField = cast field;
            textField.text = value;
          case CustomEventParamsList:
            var list:CustomEventParamsList = cast field;
            list.setParams(CustomSongEvent.readParams(value));
          default:
            trace(' WARNING '.bg_yellow().bold() + ' CHART EDITOR '.bold().bg_bright_yellow() + 'Field "${fieldId}" is of unknown or unsupported type.');
        }
        field.resumeEvent(UIEvent.CHANGE, true, true);
      }
      else
      {
        trace(' WARNING '.bg_yellow().bold() + ' CHART EDITOR '.bold().bg_bright_yellow() + 'Field "${fieldId}" was not found in the form.');
      }
    }

    var list:Null<CustomEventParamsList> = customEventParams;
    if (list != null && !chartEditorState.eventDataToPlace.exists(CustomSongEvent.PARAMS_FIELD)) list.setParams([]);

    refreshAnimationOptions();

    shouldTriggerOnEventKindChanged = true;
    updateEasePreview();
    refreshMixedFields();
    fitScrollHeights();
  }

  var lastEventKind:String = 'unknown';

  /**
   * Fields stored in steps that the form shows in beats.
   */
  var beatFields:Map<String, Bool> = [];

  /**
   * How much the beat steppers move by, a quarter beat being one step.
   */
  static final BEAT_FIELD_STEP:Float = 0.25;

  static function stepsToBeats(steps:Float):Float
  {
    return steps / Constants.STEPS_PER_BEAT;
  }

  static function beatsToSteps(beats:Float):Float
  {
    return beats * Constants.STEPS_PER_BEAT;
  }

  /**
   * Put the default values of any missing fields into the form, so the user can see them and change them.
   */
  function resetMissingFields(schema:SongEventSchema):Void
  {
    for (field in schema)
    {
      if (field == null) continue;
      if (field.type == FRAME)
      {
        if (field.children != null) resetMissingFields(new SongEventSchema(field.children));
        continue;
      }
      if (chartEditorState.eventDataToPlace.exists(field.name)) continue;

      var component:Null<Component> = toolboxEventsDataBox.findComponent(field.name);
      if (component == null) continue;
      var value:Null<Dynamic> = field.defaultValue;
      component.pauseEvent(UIEvent.CHANGE, true);
      switch (Type.getClass(component))
      {
        case NumberStepper:
          if (value != null) cast(component, NumberStepper).value = beatFields.exists(field.name) ? stepsToBeats(value) : value;
        case CheckBox:
          cast(component, CheckBox).selected = (value == true);
        case DropDown:
          var dropDown:DropDown = cast component;
          if (isOptionField(field.name)) selectOption(dropDown, value);
          else if (value != null) dropDown.value = value;
        case TextField:
          cast(component, TextField).text = (value != null) ? Std.string(value) : '';
        default:
      }
      component.resumeEvent(UIEvent.CHANGE, true, true);
    }
  }

  /**
   * The events the form edits: the picked event when looking at a chain.
   */
  function editTargets():Array<SongEventData>
  {
    var active:Null<SongEventData> = chainActive;
    if (chainEvents.length > 0 && active != null)
    {
      var picked:Array<SongEventData> = chainPicked.filter(event -> chainEvents.contains(event));
      return picked.length > 1 ? picked : [active];
    }
    return chartEditorState.currentEventSelection;
  }

  function editTargetsField(name:String, value:Null<Dynamic>):Void
  {
    var all:Array<SongEventData> = editTargets();
    var targets:Array<SongEventData> = all.length == 1 ? all : all.filter(event -> eventHasField(event, name));
    var before = EditEventsCommand.snapshot(targets);
    for (songEvent in targets)
    {
      var data:haxe.DynamicAccess<Dynamic>;
      if (all.length == 1)
      {
        songEvent.eventKind = chartEditorState.eventKindToPlace;
        data = Reflect.copy(chartEditorState.eventDataToPlace);
      }
      else
      {
        data = Reflect.copy(songEvent.valueAsStruct()) ?? {};
        if (value == null) data.remove(name);
        else
          data.set(name, value);
      }

      if (name == CustomSongEvent.PARAMS_FIELD && value != null) data.set(name, CustomSongEvent.copyParams(value));
      songEvent.value = data;
    }
    EditEventsCommand.push(chartEditorState, targets, before, name);
  }

  function eventHasField(event:SongEventData, name:String):Bool
  {
    var field:Null<SongEventSchemaField> = SongEventRegistry.getEventSchema(chartEditorState.eventKindToPlace)?.getByName(name);
    if (field == null) return event.eventKind == chartEditorState.eventKindToPlace;
    var other:Null<SongEventSchemaField> = event.getSchema()?.getByName(name);
    return other != null && other.type == field.type;
  }

  /**
   * What fields show when the events being edited have different values for them.
   */
  static inline var MIXED_TEXT:String = '---';

  var hiddenUnsharedFields:Array<Component> = [];

  function refreshMixedFields():Void
  {
    var schema:Null<SongEventSchema> = SongEventRegistry.getEventSchema(chartEditorState.eventKindToPlace);
    if (schema == null) return;
    var targets:Array<SongEventData> = editTargets();
    var multiple:Bool = targets.length > 1;

    var newTitle:String = multiple ? 'Events (${targets.length}x Events)' : 'Events';
    if (this.title != newTitle) this.title = newTitle;

    var mixedKinds:Bool = multiple && targets.exists(event -> event.eventKind != chartEditorState.eventKindToPlace);
    if (mixedKinds) quietly(toolboxEventsEventKind, () -> toolboxEventsEventKind.text = MIXED_TEXT);
    if (!mixedKinds && toolboxEventsEventKind.text == MIXED_TEXT)
    {
      var kindText:Null<String> = toolboxEventsEventKind.selectedItem?.text;
      if (kindText != null) quietly(toolboxEventsEventKind, () -> toolboxEventsEventKind.text = kindText);
    }
    var kindTooltip:Null<String> = mixedKinds ? 'The selected events are different kinds, changing this sets all of them' : null;
    if (toolboxEventsEventKind.tooltip != kindTooltip) toolboxEventsEventKind.tooltip = kindTooltip;

    for (component in hiddenUnsharedFields)
    {
      component.hidden = false;
    }
    hiddenUnsharedFields = [];

    @:privateAccess
    for (field in schema.listAllFields(cast schema))
    {
      if (field == null || field.type == FRAME) continue;
      var container:Null<Component> = toolboxEventsDataBox.findComponent('container${field.name}');
      var input:Null<Component> = toolboxEventsDataBox.findComponent(field.name);
      if (container == null || input == null) continue;

      var shared:Bool = !multiple || targets.foreach(event -> eventHasField(event, field.name));
      if (!shared)
      {
        if (!container.hidden)
        {
          container.hidden = true;
          hiddenUnsharedFields.push(container);
        }
        continue;
      }

      var mixed:Bool = false;
      if (multiple)
      {
        // The value is a plain struct, so read it with Reflect rather than DynamicAccess.get.
        var first:String = haxe.Json.stringify(Reflect.field(targets[0].valueAsStruct(), field.name) ?? field.defaultValue);
        mixed = targets.exists(event -> haxe.Json.stringify(Reflect.field(event.valueAsStruct(), field.name) ?? field.defaultValue) != first);
      }
      var newTooltip:Null<String> = mixed ? 'The selected events have different values, changing this sets all of them' : null;
      if (container.tooltip != newTooltip) container.tooltip = newTooltip;
      if (mixed) showMixed(input);
      else
        clearMixed(input);
    }
  }

  function showMixed(input:Component):Void
  {
    if (Std.isOfType(input, NumberStepper))
    {
      // Let the stepper finish showing its new value first, or it would replace the placeholder afterwards.
      quietly(input, () -> {
      });
      var inner:Null<TextField> = input.findComponent('value', TextField);
      if (inner != null) quietly(inner, () -> inner.text = MIXED_TEXT);
    }
    else if (Std.isOfType(input, DropDown))
    {
      var dropDown:DropDown = cast input;
      quietly(dropDown, () -> {
      });
      quietly(dropDown, () -> dropDown.selectedIndex = -1);
      quietly(dropDown, () -> dropDown.text = MIXED_TEXT);
    }
    else if (Std.isOfType(input, CheckBox))
    {
      var checkBox:CheckBox = cast input;
      quietly(checkBox, () ->
      {
        checkBox.selected = false;
        checkBox.text = MIXED_TEXT;
      });
    }
    else if (Std.isOfType(input, TextField))
    {
      var textField:TextField = cast input;
      quietly(textField, () -> textField.text = '');
      textField.placeholder = MIXED_TEXT;
    }
  }

  function clearMixed(input:Component):Void
  {
    if (Std.isOfType(input, NumberStepper))
    {
      var stepper:NumberStepper = cast input;
      var inner:Null<TextField> = stepper.findComponent('value', TextField);
      if (inner != null && inner.text == MIXED_TEXT)
      {
        var text:String = haxe.ui.util.StringUtil.padDecimal(stepper.value, stepper.precision);
        quietly(inner, () -> inner.text = text);
      }
    }
    else if (Std.isOfType(input, DropDown))
    {
      var dropDown:DropDown = cast input;
      var text:Null<String> = dropDown.selectedItem?.text;
      if (dropDown.text == MIXED_TEXT && text != null) quietly(dropDown, () -> dropDown.text = text);
    }
    else if (Std.isOfType(input, CheckBox))
    {
      var checkBox:CheckBox = cast input;
      if (checkBox.text == MIXED_TEXT) quietly(checkBox, () -> checkBox.text = '');
    }
    else if (Std.isOfType(input, TextField))
    {
      cast(input, TextField).placeholder = null;
    }
  }

  /**
   * Change a field without its change event going through.
   */
  function quietly(component:Component, apply:Void->Void):Void
  {
    component.pauseEvent(UIEvent.CHANGE, true);
    apply();
    // Apply any change waiting on HaxeUI's next validation now, so it can't overwrite this later.
    component.syncComponentValidation(false);
    component.resumeEvent(UIEvent.CHANGE, true, true);
  }

  /**
   * Work out the chain from the selection, and point the form at the picked event.
   */
  function refreshChain():Void
  {
    var selection:Array<SongEventData> = chartEditorState.currentEventSelection;
    if (chartEditorState.currentNoteSelection.length > 0 || !chartEditorState.isOneEventChain(selection))
    {
      chainEvents = [];
      chainActive = null;
      chainPicked = [];
      toolboxEventsChainBox.hidden = true;
      // Several events at different times: show the first one, and edits go to all of them.
      if (chartEditorState.currentNoteSelection.length == 0 && selection.length > 1)
      {
        chartEditorState.eventKindToPlace = selection[0].eventKind;
        chartEditorState.eventDataToPlace = Reflect.copy(selection[0].valueAsStruct()) ?? {};
      }
      return;
    }

    if (movingByBeat) movingGroup = selection.copy();
    else if (!sameEvents(movingGroup, selection)) movingGroup = chartEditorState.withEventChains(selection);

    chainEvents = chartEditorState.eventChainOf(selection[0]);
    if (chainActive == null || !chainEvents.contains(chainActive))
    {
      chainActive = chainEvents[Std.int(Math.min(chainActiveIndex, chainEvents.length - 1))];
    }
    chainActiveIndex = chainEvents.indexOf(chainActive);
    chainPicked = chainPicked.filter(event -> chainEvents.contains(event));
    if (!chainPicked.contains(chainActive)) chainPicked = [chainActive];
    loadActiveIntoForm();
    toolboxEventsChainBox.hidden = false;
    toolboxEventsChainTitle.text = chainEvents.length > 1 ? 'EVENT CHAIN (${chainEvents.length} EVENTS)' : 'EVENT';

    refreshingBeat = true;
    var beat:Float = Math.round(Conductor.instance.getTimeInSteps(chainEvents[0].time) / Constants.STEPS_PER_BEAT * 1000) / 1000;
    ChartEditorBaseToolbox.setStepperValue(toolboxEventsChainBeat, beat);
    refreshingBeat = false;

    refreshChainList();
  }

  /**
   * Set the event kind and data the form shows to the picked event.
   */
  function loadActiveIntoForm():Void
  {
    var active:Null<SongEventData> = chainActive;
    if (active == null) return;
    chartEditorState.eventKindToPlace = active.eventKind;
    chartEditorState.eventDataToPlace = active.valueAsStruct();
  }

  function refreshChainList():Void
  {
    toolboxEventsChainList.removeAllComponents();
    chainRows = [];
    hoveredChainRow = null;

    for (i in 0...chainEvents.length)
    {
      var event:SongEventData = chainEvents[i];
      var row:HBox = makeChainRow();

      var name:Label = new Label();
      name.text = '${i + 1}. ${eventTitle(event.eventKind)}';
      name.verticalAlign = 'center';
      row.addComponent(name);

      var info:Label = new Label();
      info.text = eventSummary(event);
      info.styleString = CHAIN_DIM_STYLE;
      info.percentWidth = 100;
      info.wordWrap = false;
      info.verticalAlign = 'center';
      info.textAlign = 'right';
      row.addComponent(info);

      row.onClick = _ ->
      {
        chartEditorState.listKeyTarget = this;
        if (chartEditorState.pressingControl()) toggleChainPick(event);
        else if (FlxG.keys.pressed.SHIFT) pickChainRange(event);
        else
          pickChainEvent(event);
      };
      row.onRightClick = _ ->
      {
        chartEditorState.listKeyTarget = this;
        if (!chainPicked.contains(event)) pickChainEvent(event);
        openChainMenu(event);
      };
      toolboxEventsChainList.addComponent(row);
    }

    var add:HBox = makeChainRow();
    var addLabel:Label = new Label();
    addLabel.text = '+ Add event at this beat';
    addLabel.styleString = CHAIN_DIM_STYLE;
    add.addComponent(addLabel);
    add.onClick = _ ->
    {
      addToChain();
    };
    toolboxEventsChainList.addComponent(add);

    styleChainRows();
    fitScrollHeights();
  }

  /**
   * Size the chain list and event data to what they hold, up to a limit, past which they scroll.
   */
  function fitScrollHeights():Void
  {
    if (fitScrollHeightsPending) return;
    fitScrollHeightsPending = true;
    haxe.ui.Toolkit.callLater(function()
    {
      fitScrollHeightsPending = false;
      toolboxEventsChainScroll.height = Math.max(MIN_CHAIN_LIST_HEIGHT, Math.min(MAX_CHAIN_LIST_HEIGHT, toolboxEventsChainList.height + 4));
      if (this.autoHeight)
      {
        toolboxEventsDataScroll.height = Math.max(MIN_EVENT_DATA_HEIGHT, Math.min(MAX_EVENT_DATA_HEIGHT, toolboxEventsDataBox.height + 4));
        return;
      }
      // Layout the toolbox to get the correct height of the scroll view, then size it to fill the rest of the toolbox.
      toolboxEventsRoot.validateNow();
      var chrome:Float = this.height - dialogContent.height + (dialogContent.paddingTop ?? 0) + (dialogContent.paddingBottom ?? 0);
      var others:Float = toolboxEventsRoot.height - toolboxEventsDataScroll.height;
      var target:Float = Math.max(MIN_CHAIN_LIST_HEIGHT, this.height - chrome - others);
      if (Math.abs(toolboxEventsDataScroll.height - target) > 0.5) toolboxEventsDataScroll.height = target;
    });
  }

  var fitScrollHeightsPending:Bool = false;
  var chainRows:Array<
    {row:HBox, event:Null<SongEventData>}> = [];
  var hoveredChainRow:Null<HBox> = null;

  function makeChainRow():HBox
  {
    var row:HBox = new HBox();
    row.percentWidth = 100;
    row.styleString = CHAIN_ROW_STYLE;
    chainRows.push({
      row: row,
      event: null
    });
    return row;
  }

  /**
   * Give each row its highlight: blue for the picked event, grey under the mouse.
   */
  function styleChainRows():Void
  {
    for (i in 0...chainRows.length)
    {
      var entry = chainRows[i];
      var event:Null<SongEventData> = i < chainEvents.length ? chainEvents[i] : null;
      var style:String = CHAIN_ROW_STYLE;
      if (event != null && (sameEvent(event, chainActive) || chainPicked.contains(event))) style += CHAIN_ACTIVE_STYLE;
      else if (entry.row == hoveredChainRow) style += CHAIN_HOVER_STYLE;
      if (entry.row.styleString != style) entry.row.styleString = style;
    }
  }

  /**
   * Highlight the row under the mouse.
   */
  function updateChainHover(screenX:Null<Float>, screenY:Null<Float>):Void
  {
    var target:Null<HBox> = null;
    if (screenX != null)
    {
      for (entry in chainRows)
      {
        if (entry.row.hitTest(screenX, screenY))
        {
          target = entry.row;
          break;
        }
      }
    }
    if (target == hoveredChainRow) return;
    hoveredChainRow = target;
    styleChainRows();
  }

  function pickChainEvent(event:SongEventData):Void
  {
    if (sameEvent(chainActive, event) && chainPicked.length <= 1) return;
    chainActive = event;
    chainActiveIndex = chainEvents.indexOf(event);
    chainPicked = [event];
    loadActiveIntoForm();
    refresh();
  }

  /**
   * Ctrl click: add an event to the picked ones, or take it out.
   */
  function toggleChainPick(event:SongEventData):Void
  {
    if (chainPicked.contains(event))
    {
      if (chainPicked.length <= 1) return;
      chainPicked.remove(event);
      if (sameEvent(chainActive, event)) chainActive = chainPicked[0];
    }
    else
    {
      chainPicked.push(event);
      chainActive = event;
    }
    chainActiveIndex = chainEvents.indexOf(chainActive);
    loadActiveIntoForm();
    refresh();
  }

  function pickChainRange(event:SongEventData):Void
  {
    var from:Int = chainEvents.indexOf(chainActive);
    var to:Int = chainEvents.indexOf(event);
    if (from == -1 || to == -1) return pickChainEvent(event);
    var low:Int = Std.int(Math.min(from, to));
    var high:Int = Std.int(Math.max(from, to));
    chainPicked = [for (i in low...(high + 1)) chainEvents[i]];
    refresh();
  }

  function openChainMenu(event:SongEventData):Void
  {
    var menu:Menu = new Menu();
    menu.left = FlxG.mouse.viewX;
    menu.top = FlxG.mouse.viewY;

    var duplicate:MenuItem = new MenuItem();
    duplicate.text = 'Duplicate';
    duplicate.onClick = _ ->
    {
      addCopyToChain(event);
    };
    menu.addComponent(duplicate);

    menu.addComponent(new MenuSeparator());

    var remove:MenuItem = new MenuItem();
    remove.text = 'Remove';
    remove.onClick = _ ->
    {
      deleteSelection();
    };
    menu.addComponent(remove);

    ChartEditorContextMenuHandler.openCustomContextMenu(chartEditorState, menu);
  }

  /**
   * A short summary of an event's values, for its row.
   */
  static function eventSummary(event:SongEventData):String
  {
    var value:Dynamic = event.value;
    if (value == null || Type.typeof(value) != TObject) return value == null ? '' : '$value';
    var parts:Array<String> = [];
    for (field in Reflect.fields(value)) parts.push('$field: ${Reflect.field(value, field)}');
    var text:String = parts.join(', ');
    return text.length > SUMMARY_LENGTH ? text.substr(0, SUMMARY_LENGTH - 3) + '...' : text;
  }

  static final SUMMARY_LENGTH:Int = 22;

  /**
   * A copy of an event's value, so editing the copy doesn't change the original.
   */
  static function copyValue(value:Dynamic):Dynamic
  {
    return (value != null && Type.typeof(value) == TObject) ? Reflect.copy(value) : value;
  }

  /**
   * The event copied with Ctrl+C.
   */
  static var copiedChainEvent:Null<SongEventData> = null;

  public function containsMouse():Bool
  {
    return hitTest(FlxG.mouse.viewX, FlxG.mouse.viewY);
  }

  public function isListShown():Bool
  {
    return haxe.ui.core.Screen.instance.rootComponents.contains(this) && !hidden && chainEvents.length > 0;
  }

  public function copySelection():Void
  {
    var active:Null<SongEventData> = chainActive;
    if (active == null) return;
    copiedChainEvent = new SongEventData(active.time, active.eventKind, copyValue(active.value));
    chartEditorState.success('Copied Event', eventTitle(active.eventKind));
  }

  public function pasteSelection():Void
  {
    var copied:Null<SongEventData> = copiedChainEvent;
    if (copied != null) addCopyToChain(copied);
  }

  public function deleteSelection():Void
  {
    var picked:Array<SongEventData> = editTargets();
    if (picked.length > 1) removeManyFromChain(picked);
    else
    {
      var active:Null<SongEventData> = chainActive;
      if (active != null) removeFromChain(active);
    }
  }

  function removeManyFromChain(events:Array<SongEventData>):Void
  {
    var remaining:Array<SongEventData> = [for (other in chainEvents) if (other != null && !events.contains(other)) other];
    chartEditorState.performCommand(new funkin.ui.debug.charting.commands.events.RemoveEventsCommand(events));
    chartEditorState.currentEventSelection = remaining;
    chainActive = remaining.length > 0 ? remaining[0] : null;
    chainPicked = chainActive != null ? [chainActive] : [];
    if (chainActive != null) loadActiveIntoForm();
    refresh();
  }

  public function renameSelection():Void
  {
  }

  /**
   * Add a copy of an event to the chain, at the chain's time.
   */
  function addCopyToChain(source:SongEventData):Void
  {
    if (chainEvents.length == 0) return;
    var added:SongEventData = new SongEventData(chainEvents[0].time, source.eventKind, copyValue(source.value));
    chartEditorState.performCommand(new funkin.ui.debug.charting.commands.events.AddEventsCommand([added], true));
    chainActive = added;
    chainActiveIndex = chainEvents.length;
    loadActiveIntoForm();
    refresh();
  }

  /**
   * The name the event kind dropdown shows for an event kind.
   */
  function eventTitle(eventKind:String):String
  {
    var entry = ChartEditorDropdowns.findDropdownElement(eventKind, toolboxEventsEventKind);
    return entry?.text ?? eventKind;
  }

  /**
   * Add a new event at the chain's time, using the event kind picked in the form.
   */
  function addToChain():Void
  {
    if (chainEvents.length == 0) return;
    var added:SongEventData = new SongEventData(chainEvents[0].time, chartEditorState.eventKindToPlace, {
    });
    chartEditorState.performCommand(new funkin.ui.debug.charting.commands.events.AddEventsCommand([added], true));
    chainActive = added;
    chainActiveIndex = chainEvents.length;
    loadActiveIntoForm();
    refresh();
  }

  static function sameEvent(a:Null<SongEventData>, b:Null<SongEventData>):Bool
  {
    return (a : Dynamic) == (b : Dynamic);
  }

  function removeFromChain(event:SongEventData):Void
  {
    var remaining:Array<SongEventData> = [for (other in chainEvents) if (other != null && !sameEvent(other, event)) other];
    var wasActive:Bool = sameEvent(chainActive, event);
    chartEditorState.performCommand(new funkin.ui.debug.charting.commands.events.RemoveEventsCommand([event]));
    // Keep the rest of the chain selected so the panel stays on it.
    chartEditorState.currentEventSelection = remaining;
    if (wasActive || chainActive == null) chainActive = remaining.length > 0 ? remaining[0] : null;
    if (chainActive != null) loadActiveIntoForm();
    refresh();
  }

  function buildEventDataFormFromSchema(target:Box, schema:SongEventSchema, eventKind:String):Void
  {
    trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Event Toolbox: Building form from schema ("${eventKind}")...');

    _initializing = true;

    lastEventKind = eventKind ?? 'unknown';
    beatFields.clear();
    optionListsKey = '';

    // Clear the frame.
    target.removeAllComponents();
    customEventParams = null;

    recursiveChildAdd(target, schema);
    if (eventKind == CustomSongEvent.KIND) addCustomEventParams(target);

    _initializing = false;
    fitScrollHeights();
  }

  var customEventParams:Null<CustomEventParamsList> = null;

  function addCustomEventParams(target:Box):Void
  {
    var list:CustomEventParamsList = new CustomEventParamsList();
    list.id = CustomSongEvent.PARAMS_FIELD;
    list.setParams(CustomSongEvent.readParams(chartEditorState.eventDataToPlace.get(CustomSongEvent.PARAMS_FIELD)));
    list.onParamsChanged = function(params)
    {
      chartEditorState.eventDataToPlace.set(CustomSongEvent.PARAMS_FIELD, params);
      if (_initializing || chartEditorState.currentEventSelection.length == 0) return;
      editTargetsField(CustomSongEvent.PARAMS_FIELD, params);
    };
    target.addComponent(list);
    customEventParams = list;
  }

  static final SING_POSE:EReg = ~/^sing(LEFT|DOWN|UP|RIGHT)/;

  function isOptionField(name:String):Bool
  {
    return lastEventKind == 'PlayAnimation' && (name == 'target' || name == 'anim');
  }

  function stringFieldOptions(name:String):Null<Array<EventFieldOption>>
  {
    if (!isOptionField(name)) return null;
    if (name == 'target') return playAnimationTargets();
    var target:String = chartEditorState.eventDataToPlace.get('target') ?? PlayAnimationSongEvent.DEFAULT_TARGET;
    return playAnimationNames(target);
  }

  function playAnimationTargets():Array<EventFieldOption>
  {
    var characters = chartEditorState.currentSongMetadata.playData.characters;
    var targets:Array<EventFieldOption> = [
      {
        text: 'Player (${characters.player ?? 'none'})',
        value: 'boyfriend'
      },
      {
        text: 'Opponent (${characters.opponent ?? 'none'})',
        value: 'dad'
      },
      {
        text: 'Girlfriend (${characters.girlfriend ?? 'none'})',
        value: 'girlfriend'
      }
    ];
    for (prop in stageProps())
    {
      if (prop.name == null || prop.name == '') continue;
      targets.push({
        text: 'Prop (${prop.name})',
        value: prop.name
      });
    }
    return targets;
  }

  function playAnimationNames(target:String):Array<EventFieldOption>
  {
    var characters = chartEditorState.currentSongMetadata.playData.characters;
    var charId:Null<String> = switch (target)
    {
      case 'boyfriend' | 'bf' | 'player':
        characters.player;
      case 'dad' | 'opponent':
        characters.opponent;
      case 'girlfriend' | 'gf':
        characters.girlfriend;
      default:
        null;
    }
    var animations:Array<AnimationData> = [];
    if (charId != null) animations = CharacterRegistry.instance.fetchCharacterData(charId)?.animations ?? [];
    else
    {
      for (prop in stageProps()) if (prop.name == target) animations = prop.animations ?? [];
    }

    var names:Array<EventFieldOption> = [];
    var seen:Map<String, Bool> = [];
    for (animation in animations)
    {
      var animName:Null<String> = animation.name;
      if (animName == null || animName == '' || seen.exists(animName) || SING_POSE.match(animName)) continue;
      seen.set(animName, true);
      names.push({
        text: animName,
        value: animName
      });
    }
    names.sort((a, b) -> a.text < b.text ? -1 : (a.text > b.text ? 1 : 0));
    return names;
  }

  @:privateAccess
  function stageProps():Array<StageDataProp>
  {
    var stage:Null<Stage> = StageRegistry.instance.fetchEntry(chartEditorState.currentSongMetadata.playData.stage);
    return stage?._data?.props ?? [];
  }

  var optionListsKey:String = '';

  /**
   * Rebuild the target and animation lists.
   */
  public function refreshOptionLists():Void
  {
    if (!isOptionField('target')) return;
    var playData = chartEditorState.currentSongMetadata.playData;
    var key:String = '${chartEditorState.currentSongId}|${chartEditorState.selectedVariation}|${playData.stage}|${playData.characters.player}|${playData.characters.opponent}|${playData.characters.girlfriend}';
    if (key == optionListsKey) return;
    optionListsKey = key;

    var dropDown:Null<DropDown> = toolboxEventsDataBox.findComponent('target', DropDown);
    if (dropDown != null)
    {
      dropDown.pauseEvent(UIEvent.CHANGE, true);
      dropDown.dataSource.clear();
      for (option in playAnimationTargets()) dropDown.dataSource.add(option);
      selectOption(dropDown, chartEditorState.eventDataToPlace.get('target') ?? PlayAnimationSongEvent.DEFAULT_TARGET);
      dropDown.resumeEvent(UIEvent.CHANGE, true, true);
    }
    refreshAnimationOptions();
  }

  function refreshAnimationOptions():Void
  {
    if (!isOptionField('anim')) return;
    var dropDown:Null<DropDown> = toolboxEventsDataBox.findComponent('anim', DropDown);
    if (dropDown == null) return;
    var options:Null<Array<EventFieldOption>> = stringFieldOptions('anim');
    if (options == null) return;
    dropDown.pauseEvent(UIEvent.CHANGE, true);
    dropDown.dataSource.clear();
    for (option in options) dropDown.dataSource.add(option);
    selectOption(dropDown, chartEditorState.eventDataToPlace.get('anim') ?? PlayAnimationSongEvent.DEFAULT_ANIM);
    dropDown.resumeEvent(UIEvent.CHANGE, true, true);
  }

  /**
   * Select the option with this value.
   */
  static function selectOption(dropDown:DropDown, value:Null<Dynamic>):Void
  {
    if (value == null) return;
    var text:String = Std.string(value);
    for (i in 0...dropDown.dataSource.size)
    {
      if (dropDown.dataSource.get(i).value == text)
      {
        if (dropDown.selectedIndex == i) dropDown.selectedIndex = -1;
        dropDown.selectedIndex = i;
        return;
      }
    }
    dropDown.dataSource.add({
      text: text,
      value: text
    });
    dropDown.selectedIndex = -1;
    dropDown.selectedIndex = dropDown.dataSource.size - 1;
  }

  function recursiveChildAdd(parent:Component, schema:SongEventSchema)
  {
    // Ensure we have a cleared preview reference for rebuilt form
    easeGraphImage = null;
    easeDotImage = null;
    _lastEaseKey = null;
    var _needEasePreview:Bool = false;

    for (field in schema)
    {
      if (field == null) continue;

      var hbox:HBox = new HBox();
      hbox.id = 'container${field.name}';
      hbox.percentWidth = 100;
      parent.addComponent(hbox);

      // Add a label for the data field.
      var label:Label = new Label();
      label.text = field.title;
      label.verticalAlign = 'center';
      label.percentWidth = 50;
      hbox.addComponent(label);

      // Add an input field for the data field.
      var input:Component;
      switch (field.type)
      {
        case INTEGER | FLOAT if (field.units == 'steps'):
          beatFields.set(field.name, true);
          var numberStepper:NumberStepper = new NumberStepper();
          numberStepper.id = field.name;
          numberStepper.step = BEAT_FIELD_STEP;
          numberStepper.precision = 2;
          if (field.min != null) numberStepper.min = stepsToBeats(field.min);
          if (field.max != null) numberStepper.max = stepsToBeats(field.max);
          if (field.defaultValue != null) numberStepper.value = stepsToBeats(field.defaultValue);
          input = numberStepper;
        case INTEGER:
          var numberStepper:NumberStepper = new NumberStepper();
          numberStepper.id = field.name;
          numberStepper.step = field.step ?? 1.0;
          if (field.min != null) numberStepper.min = field.min;
          if (field.max != null) numberStepper.max = field.max;
          if (field.defaultValue != null) numberStepper.value = field.defaultValue;
          input = numberStepper;
        case FLOAT:
          var numberStepper:NumberStepper = new NumberStepper();
          numberStepper.id = field.name;
          numberStepper.step = field.step ?? 0.1;
          if (field.min != null) numberStepper.min = field.min;
          if (field.max != null) numberStepper.max = field.max;
          if (field.defaultValue != null) numberStepper.value = field.defaultValue;
          input = numberStepper;
        case BOOL:
          var checkBox:CheckBox = new CheckBox();
          checkBox.id = field.name;
          if (field.defaultValue != null) checkBox.selected = field.defaultValue;
          input = checkBox;
        case ENUM:
          var dropDown:DropDown = new DropDown();
          dropDown.id = field.name;
          var isEase:Bool = field.name == 'ease' || field.name == 'easeDir';
          if (isEase) dropDown.width = 100.0;
          else
            dropDown.percentWidth = 100;
          dropDown.dropdownSize = 10;
          dropDown.dropdownWidth = isEase ? 107 : 157;
          dropDown.searchable = true;
          dropDown.dataSource = new ArrayDataSource();

          if (field.keys == null) throw 'Field "${field.name}" is of Enum type but has no keys.';

          // Add entries to the dropdown.

          for (optionName in field.keys.keys())
          {
            var optionValue:Null<Dynamic> = field.keys.get(optionName);
            dropDown.dataSource.add({
              value: optionValue,
              text: optionName
            });
          }

          dropDown.value = field.defaultValue;

          // TODO: Add an option to customize sort.
          dropDown.dataSource.sort('text', ASCENDING);

          input = dropDown;
        case STRING:
          var options:Null<Array<EventFieldOption>> = stringFieldOptions(field.name);
          if (options != null)
          {
            var dropDown:DropDown = new DropDown();
            dropDown.id = field.name;
            dropDown.percentWidth = 100;
            dropDown.dropdownSize = 10;
            dropDown.dropdownWidth = 157;
            dropDown.searchable = true;
            dropDown.dataSource = new ArrayDataSource();
            for (option in options) dropDown.dataSource.add(option);
            selectOption(dropDown, chartEditorState.eventDataToPlace.get(field.name) ?? field.defaultValue);
            input = dropDown;
          }
          else
          {
            input = new TextField();
            input.id = field.name;
            if (field.defaultValue != null) input.text = field.defaultValue;
          }
        case FRAME:
          hbox.removeComponent(label, true);

          input = new Frame();
          input.id = field.name;
          input.text = field.title;
          input.percentWidth = 100;
          if (field.collapsible != null)
          {
            var targetFrame:Frame = cast(input, Frame);
            if (targetFrame != null) targetFrame.collapsible = field.collapsible;
          }

          var frameVBox:VBox = new VBox();
          frameVBox.percentWidth = 100;
          input.addComponent(frameVBox);

          if (field.children != null) recursiveChildAdd(frameVBox, new SongEventSchema(field.children));

        default:
          // Unknown type. Display a label that proclaims the type so we can debug it.
          input = new Label();
          input.id = field.name;
          input.text = field.type;
      }

      // Putting in a box so we can add a unit label easily if there is one.
      var inputBox:HBox = new HBox();
      inputBox.percentWidth = 50;
      if (field.type != FRAME) inputBox.addComponent(input);

      if (field.type == ENUM && (field.name == 'ease' || field.name == 'easeDir'))
      {
        _needEasePreview = true;
      }

      // Add a unit label if applicable.
      if (field.units != null && field.units != '')
      {
        var units:Label = new Label();
        units.text = beatFields.exists(field.name) ? 'beats' : field.units;
        if (field.type == INTEGER || field.type == FLOAT) input.width = 70;
        units.verticalAlign = 'center';
        inputBox.addComponent(units);
      }

      hbox.addComponent(field.type == FRAME ? input : inputBox);

      // Ensure chartEditorState.eventDataToPlace reflects default UI values so preview is correct on first open
      if (field.defaultValue != null)
      {
        // Only set if not already present (don't overwrite existing selection data)
        if (chartEditorState.eventDataToPlace.get(field.name) == null)
        {
          chartEditorState.eventDataToPlace.set(field.name, field.defaultValue);
        }
      }

      // Update the value of the event data without modifying
      input.pauseEvent(UIEvent.CHANGE, true);
      input.onChange = function(event:UIEvent)
      {
        if (field.type == FRAME) return;

        var value:Any = event.target.value;
        if (beatFields.exists(field.name) && event.target.value != null)
        {
          var steps:Float = beatsToSteps(event.target.value);
          value = (field.type == INTEGER) ? Math.round(steps) : steps;
        }
        else if (Std.isOfType(event.target, DropDown))
        {
          var drp:DropDown = cast event.target;
          value = drp.selectedItem?.value ?? field.defaultValue;
        }
        else if (field.type == BOOL)
        {
          var chk:CheckBox = cast event.target;
          value = cast(chk.selected, Null<Bool>); // Need to cast to nullable bool or the compiler will get mad.
        }

        // Edit the event data to place.
        if (value == null)
        {
          chartEditorState.eventDataToPlace.remove(event.target.id);
        }
        else
        {
          chartEditorState.eventDataToPlace.set(event.target.id, value);
        }
        if (field.name == 'target') refreshAnimationOptions();

        // Edit the event data of any existing events.
        if (!_initializing && chartEditorState.currentEventSelection.length > 0)
        {
          editTargetsField(event.target.id, value);
        }
        updateEasePreview();
      }

      input.resumeEvent(UIEvent.CHANGE, true, true);
    }

    if (_needEasePreview)
    {
      if (easeGraphImage == null)
      {
        easeGraphImage = new Image();
        easeGraphImage.id = 'easeGraph';
        easeGraphImage.width = 100;
        easeGraphImage.height = 100;
        easeGraphImage.hidden = true;
        easeGraphImage.verticalAlign = 'bottom';
      }
      if (easeDotImage == null)
      {
        easeDotImage = new Image();
        easeDotImage.id = 'easeDot';
        easeDotImage.width = 16;
        easeDotImage.height = 100;
        easeDotImage.hidden = true;
        easeDotImage.verticalAlign = 'bottom';
      }

      var easeHBox = new HBox();
      easeHBox.percentWidth = 100;
      easeHBox.height = 100;
      easeHBox.verticalAlign = 'bottom';

      easeHBox.addComponent(easeGraphImage);
      easeHBox.addComponent(easeDotImage);

      currentEaseHBox = easeHBox;
      currentEaseHBox.hidden = true;
      parent.addComponent(easeHBox);

      updateEasePreview();
    }
  }

  var currentEaseHBox:HBox = null;
  var _lastEaseKey:Null<String> = null;

  function stopEasePreviewTimers():Void
  {
    _dotTimer?.cancel();
    _pauseTimer?.cancel();
    _dotTimer = null;
    _pauseTimer = null;
  }

  function canUpdateEaseDot():Bool
  {
    @:privateAccess
    return easeDotImage != null && !_initializing && !easeDotImage._isDisposed && !this._isDisposed;
  }

  override function onDestroy():Void
  {
    stopEasePreviewTimers();

    super.onDestroy();
  }

  function updateEasePreview():Void
  {
    if (easeGraphImage == null || easeDotImage == null) return;

    var easeStr:Null<String> = chartEditorState.eventDataToPlace.get('ease');
    var easeDirStr:Null<String> = chartEditorState.eventDataToPlace.get('easeDir');

    var easeType:String = SongEventHelper.resolveEaseTypeFromKey(easeStr ?? SongEvent.DEFAULT_EASE);
    var easeDir:String = easeDirStr ?? SongEventHelper.resolveEaseDirFromKey(easeStr);

    setDurationVisible(easeType != 'CLASSIC' && easeType != 'INSTANT');

    var easeKey:String = '$easeType$easeDir';
    if (easeKey == _lastEaseKey) return;
    _lastEaseKey = easeKey;

    // Hide preview when easing indicates a non-visual/legacy type such as "CLASSIC"
    if (easeType != null && (easeType == 'CLASSIC' || easeType == 'INSTANT'))
    {
      _dotTimer?.cancel();
      _pauseTimer?.cancel();
      _dotTimer = null;
      _pauseTimer = null;
      _easeDotSprites = [];
      _dotIndex = 0;

      easeGraphImage.resource = null;
      easeDotImage.resource = null;
      easeGraphImage.hidden = true;
      easeDotImage.hidden = true;
      if (currentEaseHBox != null) currentEaseHBox.hidden = true;

      setEaseDirVisible(false);

      return;
    }

    setEaseDirVisible(true);

    // Reset any previous timers/sprites
    _dotTimer?.cancel();
    _pauseTimer?.cancel();
    _dotTimer = null;
    _pauseTimer = null;
    _easeDotSprites = [];
    _dotIndex = 0;

    final _graphBd:BitmapData = SongEventHelper.getEaseBitmap(easeKey);
    _easeGraphSprite = SongEventHelper.createSpriteFromKey(easeKey, 100, 100);
    easeGraphImage.resource = SongEventHelper.liveFrame(_easeGraphSprite);
    if (_graphBd == null || easeGraphImage.resource == null)
    {
      easeDotImage.resource = null;
      easeGraphImage.hidden = true;
      easeDotImage.hidden = true;
      if (currentEaseHBox != null) currentEaseHBox.hidden = true;
      return;
    }

    // show preview and start dot animation
    easeGraphImage.hidden = false;
    easeDotImage.hidden = false;
    if (currentEaseHBox != null) currentEaseHBox.hidden = false;

    var dotSprites:Array<flixel.FlxSprite> = SongEventHelper.getOrCreateEaseDotSprites(easeKey, 30, 3, 16);
    if (dotSprites == null || dotSprites.length == 0)
    {
      // if no dot sprites, still show graph but keep dot empty
      easeDotImage.resource = null;
      return;
    }
    _easeDotSprites = dotSprites;
    easeDotImage.resource = SongEventHelper.liveFrame(_easeDotSprites[0]);

    var frameCallback:Dynamic = null;
    frameCallback = (tmr:FlxTimer) ->
    {
      _dotIndex++;
      if (_dotIndex >= _easeDotSprites.length)
      {
        _dotTimer?.cancel();
        _pauseTimer ??= new FlxTimer();
        _pauseTimer.start(_loopPause, function(p:FlxTimer):Void
        {
          if (canUpdateEaseDot())
          {
            _dotIndex = 0;
            if (SongEventHelper.liveFrame(_easeDotSprites[0]) != null) easeDotImage.resource = SongEventHelper.liveFrame(_easeDotSprites[0]);
            _dotTimer ??= new FlxTimer();
            _dotTimer.start(_dotInterval, frameCallback, 0);
          }
        }, 1);
      }
      else if (
        canUpdateEaseDot()
        && SongEventHelper.liveFrame(_easeDotSprites[_dotIndex]) != null
      ) easeDotImage.resource = SongEventHelper.liveFrame(_easeDotSprites[_dotIndex]);
    };

    _dotTimer ??= new FlxTimer();
    _dotTimer.start(_dotInterval, frameCallback, 0);
  }

  function setEaseDirVisible(visible:Bool):Void
  {
    // Hardcoded behavior for a specific field lmao
    var easeDirField:Component = toolboxEventsDataBox.findComponent('containereaseDir');

    if (easeDirField != null && easeDirField.hidden == visible) easeDirField.hidden = !visible;
  }

  function setDurationVisible(visible:Bool):Void
  {
    var durationField:Component = toolboxEventsDataBox.findComponent('containerduration');

    if (durationField != null && durationField.hidden == visible) durationField.hidden = !visible;
  }

  /**
   * Constructs a new Event toolbox for the given Chart Editor.
   * @param chartEditorState The Chart Editor state to build the toolbox for.
   * @return The newly constructed toolbox.
   */
  public static function build(chartEditorState:ChartEditorState):ChartEditorEventDataToolbox
  {
    return new ChartEditorEventDataToolbox(chartEditorState);
  }
}

typedef EventFieldOption =
{
  text:String,
  value:String
}
#end
