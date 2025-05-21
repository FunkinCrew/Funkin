package funkin.ui.debug.charting.toolboxes;

#if FEATURE_CHART_EDITOR
import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import funkin.data.event.SongEventRegistry;
import funkin.data.event.SongEventSchema;
import funkin.play.event.SongEvent;
import funkin.play.event.SongEventHelper;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import haxe.ui.backend.ImageData;
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
class ChartEditorEventDataToolbox extends ChartEditorBaseToolbox
{
  var toolboxEventsModifyAllEvents:CheckBox;
  var toolboxEventsDataBox:VBox;
  var toolboxEventsSelectedEvents:DropDown;
  var selectedEventDropdownItemRenderer:haxe.ui.core.ItemRenderer;
  var toolboxEventsCustomKindLabel:Label;
  var toolboxEventsCustomKind:TextField;

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
  var populateSelectedEventsDropDown:Bool = true;

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

    selectedEventDropdownItemRenderer = toolboxEventsSelectedEvents.findComponent(haxe.ui.core.ItemRenderer);

    initialize();

    this.onDialogClosed = onClose;

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

    toolboxEventsCustomKind.onChange = function(event:UIEvent)
    {
      var customKind:Null<String> = event?.target?.text;
      if (customKind == null) return;

      var prevEventKindToPlace = chartEditorState.eventKindToPlace;
      chartEditorState.eventKindToPlace = customKind;
      if (!_initializing && chartEditorState.currentEventSelection.length > 0)
      {
        if (toolboxEventsModifyAllEvents.selected)
        {
          trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Event toolbox MODIFYING events to kind "${chartEditorState.eventKindToPlace}"');
          // Edit the event data of any existing events of the same type.
          for (event in chartEditorState.currentEventSelection)
          {
            if (event.eventKind == prevEventKindToPlace)
            {
              event.eventKind = chartEditorState.eventKindToPlace;
              event.value = Reflect.copy(chartEditorState.eventDataToPlace);
            }
          }
        }
        else
        {
          // Find the currently selected event and update it's values.
          var event = chartEditorState.currentEventSelection[toolboxEventsSelectedEvents.selectedIndex - 1];
          if (event != null)
          {
            event.eventKind = chartEditorState.eventKindToPlace;
            event.value = Reflect.copy(chartEditorState.eventDataToPlace);
          }
        }
        chartEditorState.saveDataDirty = true;
        chartEditorState.noteDisplayDirty = true;
        chartEditorState.notePreviewDirty = true;
        chartEditorState.noteTooltipsDirty = true;
      }
    }

    toolboxEventsSelectedEvents.onChange = function(event:UIEvent)
    {
      if (event.target.value == null) return;
      var selectedEvent = chartEditorState.currentEventSelection[toolboxEventsSelectedEvents.selectedIndex - 1];
      if (selectedEvent != null && chartEditorState.eventDataToPlace != selectedEvent.value)
      {
        chartEditorState.eventKindToPlace = selectedEvent.eventKind;
        chartEditorState.eventDataToPlace = selectedEvent.value;
        if (shouldTriggerOnEventKindChanged) // only refresh if there isn't one already taking place.
        {
          populateSelectedEventsDropDown = false;

          refresh();

          populateSelectedEventsDropDown = true;
        }
      }
    };
    refreshSelectedEvents(toolboxEventsSelectedEvents.selectedIndex);

    var startingEventValue = ChartEditorDropdowns.populateDropdownWithSongEvents(toolboxEventsEventKind, chartEditorState.eventKindToPlace);
    toolboxEventsEventKind.value = startingEventValue;

    shouldTriggerOnEventKindChanged = true;
  }

  function onEventKindChanged(event:UIEvent):Void
  {
    if (event.data == null)
    {
      return;
    }

    var prevEventKindToPlace = chartEditorState.eventKindToPlace;
    var eventKind:String = event.data.id;
    var sameEvent:Bool = (eventKind == chartEditorState.eventKindToPlace);

    trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Event toolbox changed kind to "$eventKind"');

    // Edit the event data to place.
    chartEditorState.eventKindToPlace = eventKind;

    var schema:SongEventSchema = SongEventRegistry.getEventSchema(eventKind);

    if (!sameEvent) chartEditorState.eventDataToPlace = {};
    if (schema == null)
    {
      chartEditorState.warning('Invalid Event Kind', 'Event toolbox tried to use unknown event kind "$eventKind", did you define a schema?');
      toolboxEventsCustomKindLabel.hidden = false;
      toolboxEventsCustomKind.hidden = false;
      buildEventDataFormFromSchema(toolboxEventsDataBox, buildSchemaFromEventData(), chartEditorState.eventKindToPlace);
    }
    else
    {
      toolboxEventsCustomKindLabel.hidden = true;
      toolboxEventsCustomKind.hidden = true;
      buildEventDataFormFromSchema(toolboxEventsDataBox, schema, chartEditorState.eventKindToPlace);
    }

    if (!_initializing && chartEditorState.currentEventSelection.length > 0)
    {
      if (toolboxEventsModifyAllEvents.selected)
      {
        chartEditorState.success(
          'Modified Events',
          'Switching ${chartEditorState.currentEventSelection.length} events to "${chartEditorState.eventKindToPlace}"'
        );
        // Edit the event data of any selected events of the same type.
        for (event in chartEditorState.currentEventSelection)
        {
          if (event.eventKind == prevEventKindToPlace)
          {
            event.eventKind = chartEditorState.eventKindToPlace;
            event.value = Reflect.copy(chartEditorState.eventDataToPlace);
          }
        }
      }
      else
      {
        // Find the currently selected event and update it's values.
        var event = chartEditorState.currentEventSelection[toolboxEventsSelectedEvents.selectedIndex - 1];
        if (event != null)
        {
          event.eventKind = chartEditorState.eventKindToPlace;
          event.value = Reflect.copy(chartEditorState.eventDataToPlace);
        }
      }
      chartEditorState.saveDataDirty = true;
      chartEditorState.noteDisplayDirty = true;
      chartEditorState.notePreviewDirty = true;
      chartEditorState.noteTooltipsDirty = true;
    }
  }

  function refreshSelectedEvents(startingChartEvent:Int = 0):Void
  {
    toolboxEventsSelectedEvents.pauseEvent(UIEvent.CHANGE, true);
    var startingSelectedEvent = ChartEditorDropdowns.populateDropdownWithChartEvents(toolboxEventsSelectedEvents, chartEditorState, startingChartEvent);
    toolboxEventsSelectedEvents.selectedIndex = Std.parseInt(startingSelectedEvent.id);
    toolboxEventsSelectedEvents.value = startingSelectedEvent;
    selectedEventDropdownItemRenderer.data = startingSelectedEvent;
    toolboxEventsSelectedEvents.resumeEvent(UIEvent.CHANGE, true, true);
  }

  override public function refresh():Void
  {
    super.refresh();

    shouldTriggerOnEventKindChanged = false;

    if (populateSelectedEventsDropDown) refreshSelectedEvents(toolboxEventsSelectedEvents.selectedIndex);

    var newDropdownElement = ChartEditorDropdowns.findDropdownElement(chartEditorState.eventKindToPlace, toolboxEventsEventKind);

    if (newDropdownElement == null)
    {
      trace(' WARNING '.bold().bg_yellow() + ' CHART EDITOR - Event kind "${chartEditorState.eventKindToPlace}" not found in dropdown lookup. Attempting to proceed...');
      newDropdownElement = ChartEditorDropdowns.findDropdownElement('unknown', toolboxEventsEventKind);
      toolboxEventsCustomKindLabel.hidden = false;
      toolboxEventsCustomKind.hidden = false;
      toolboxEventsCustomKind.value = chartEditorState.eventKindToPlace;
    }
    else
    {
      toolboxEventsCustomKindLabel.hidden = true;
      toolboxEventsCustomKind.hidden = true;
    }

    if (toolboxEventsEventKind.value != newDropdownElement || lastEventKind != toolboxEventsEventKind.value.id)
    {
      toolboxEventsEventKind.value = newDropdownElement;

      var schema:SongEventSchema = SongEventRegistry.getEventSchema(chartEditorState.eventKindToPlace);
      if (schema == null)
      {
        // Build the event schema using the selected unknown event's value instead.
        chartEditorState.warning(
          'Invalid Event Kind',
          'Event toolbox tried to use unknown event kind "${chartEditorState.eventKindToPlace}", did you define a schema?'
        );
        buildEventDataFormFromSchema(toolboxEventsDataBox, buildSchemaFromEventData(), chartEditorState.eventKindToPlace);
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
            numberStepper.value = value;
          case CheckBox:
            var checkBox:CheckBox = cast field;
            checkBox.selected = value;
          case DropDown:
            var dropDown:DropDown = cast field;
            dropDown.value = value;
          case TextField:
            var textField:TextField = cast field;
            textField.text = value;
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

    updateEasePreview();

    shouldTriggerOnEventKindChanged = true;
  }

  function buildSchemaFromEventData():SongEventSchema
  {
    var schema:SongEventSchema = new SongEventSchema([]);

    for (pair in chartEditorState.eventDataToPlace.keyValueIterator())
    {
      var fieldId:String = pair.key;
      var value:Null<Dynamic> = pair.value;

      switch (value)
      {
        case Std.isOfType(_, Int) => true:
          schema.push(
            {
              name: '$fieldId',
              title: '$fieldId',
              defaultValue: value,
              step: 1,
              type: SongEventFieldType.INTEGER,
            });
        case Std.isOfType(_, Float) => true:
          schema.push(
            {
              name: '$fieldId',
              title: '$fieldId',
              defaultValue: value,
              step: 0.1,
              type: SongEventFieldType.FLOAT,
            });
        case Std.isOfType(_, Bool) => true:
          schema.push(
            {
              name: '$fieldId',
              title: '$fieldId',
              type: SongEventFieldType.BOOL,
              defaultValue: value,
            });
        case Std.isOfType(_, String) => true:
          schema.push(
            {
              name: '$fieldId',
              title: '$fieldId',
              type: SongEventFieldType.STRING,
              defaultValue: '$value',
            });
        default:
          throw 'ChartEditorEventDataToolbox - Field "${fieldId}" is of unknown type "${Type.getClassName(Type.getClass(value))}".';
      }
    }

    if (schema.getFirstField() == null)
    {
      // Fine, here's some useless values for the psychic in you.
      schema = new SongEventSchema([
        {
          name: 'value1',
          title: 'value1',
          type: SongEventFieldType.STRING,
          defaultValue: '',
        },
        {
          name: 'value2',
          title: 'value2',
          type: SongEventFieldType.STRING,
          defaultValue: '',
        },
      ]);
    }

    return schema;
  }

  var lastEventKind:String = 'unknown';

  function buildEventDataFormFromSchema(target:Box, schema:SongEventSchema, eventKind:String):Void
  {
    trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Event Toolbox: Building form from schema ("${eventKind}")...');

    _initializing = true;

    lastEventKind = eventKind ?? 'unknown';

    // Clear the frame.
    target.removeAllComponents();

    recursiveChildAdd(target, schema);

    _initializing = false;
  }

  function recursiveChildAdd(parent:Component, schema:SongEventSchema)
  {
    // Ensure we have a cleared preview reference for rebuilt form
    easeGraphImage = null;
    easeDotImage = null;
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
          dropDown.width = 150.0;
          dropDown.dropdownSize = 10;
          dropDown.dropdownWidth = 157;
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
          input = new TextField();
          input.id = field.name;
          if (field.defaultValue != null) input.text = field.defaultValue;
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
        units.text = field.units;
        units.verticalAlign = 'center';
        inputBox.addComponent(units);
      }

      hbox.addComponent(field.type == FRAME ? input : inputBox);

      // Update the value of the event data without modifying
      input.pauseEvent(UIEvent.CHANGE, true);
      input.onChange = function(event:UIEvent)
      {
        if (field.type == FRAME) return;

        var value:Any = event.target.value;
        if (field.type == ENUM)
        {
          var drp:DropDown = cast event.target;
          value = drp.selectedItem?.value ?? field.defaultValue;
          updateEasePreview();
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

        if (!_initializing && chartEditorState.currentEventSelection.length > 0)
        {
          if (toolboxEventsModifyAllEvents.selected)
          {
            // Edit the event data of any existing events of the same type.
            trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Event Toolbox MODIFYING all selected events...');
            for (event in chartEditorState.currentEventSelection)
            {
              if (event.eventKind == chartEditorState.eventKindToPlace) event.value = chartEditorState.eventDataToPlace;
            }
          }
          else
          {
            // Find the currently selected event and update it's values.
            var event = chartEditorState.currentEventSelection[toolboxEventsSelectedEvents.selectedIndex - 1];
            if (event != null)
            {
              event.eventKind = chartEditorState.eventKindToPlace;
              event.value = Reflect.copy(chartEditorState.eventDataToPlace);
            }
          }
          chartEditorState.saveDataDirty = true;
          chartEditorState.noteDisplayDirty = true;
          chartEditorState.notePreviewDirty = true;
          chartEditorState.noteTooltipsDirty = true;
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

  function updateEasePreview():Void
  {
    if (easeGraphImage == null || easeDotImage == null) return;

    var easeStr:Null<String> = chartEditorState.eventDataToPlace.get('ease');
    var easeDirStr:Null<String> = chartEditorState.eventDataToPlace.get('easeDir');

    var easeType:String = SongEventHelper.resolveEaseTypeFromKey(easeStr ?? SongEvent.DEFAULT_EASE);
    var easeDir:String = easeDirStr ?? SongEventHelper.resolveEaseDirFromKey(easeStr);

    var easeKey:String = '$easeType$easeDir';

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
    easeGraphImage.resource = _easeGraphSprite?.frame;
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
    easeDotImage.resource = _easeDotSprites[0].frame;

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
          if (easeDotImage != null && !_initializing)
          {
            _dotIndex = 0;
            if (_easeDotSprites[0].frame != null) easeDotImage.resource = _easeDotSprites[0].frame;
            _dotTimer ??= new FlxTimer();
            _dotTimer.start(_dotInterval, frameCallback, 0);
          }
        }, 1);
      }
      else if (easeDotImage != null && !_initializing && _easeDotSprites[_dotIndex].frame != null) easeDotImage.resource = _easeDotSprites[_dotIndex].frame;
    };

    _dotTimer ??= new FlxTimer();
    _dotTimer.start(_dotInterval, frameCallback, 0);
  }

  function setEaseDirVisible(visible:Bool):Void
  {
    // Hardcoded behavior for a specific field lmao
    var easeDirField:Component = toolboxEventsDataBox.findComponent('containereaseDir');

    if (easeDirField != null)
    {
      trace('Toggling easeDir visibility: ${visible}');
      easeDirField.hidden = !visible;
    }
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
#end
