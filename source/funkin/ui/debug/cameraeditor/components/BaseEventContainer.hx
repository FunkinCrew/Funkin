package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.ui.debug.cameraeditor.commands.EditEventPropertiesCommand;
import funkin.ui.haxeui.components.editors.camera.EaseGraphPreview;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import funkin.ui.haxeui.components.editors.timeline.TimelineUtil;
import haxe.ui.constants.Priority;
import haxe.ui.events.FocusEvent;
import haxe.ui.events.UIEvent;

/**
 * Shared base for properties-panel containers in the Camera Editor.
 */
abstract class BaseEventContainer extends VBox implements EditorContainer
{
  public var cameraEditorState:CameraEditorState;

  /**
   * Every event being edited. All of them share the same event kind.
   */
  var editedEvents(get, never):Array<SongEventData>;

  function get_editedEvents():Array<SongEventData>
  {
    return cameraEditorState.selectedSongEvents;
  }

  /**
   * The event the panel reads its values from.
   */
  var primaryEvent(get, never):Null<SongEventData>;

  function get_primaryEvent():Null<SongEventData>
  {
    return editedEvents.length > 0 ? editedEvents[0] : null;
  }

  /**
   * A copy of each edited event's value as of the last recorded edit.
   */
  var lastSnapshot:Array<Dynamic> = [];

  public function new(state:CameraEditorState)
  {
    super();
    cameraEditorState = state;
    lastSnapshot = takeSnapshot();
  }

  function takeSnapshot():Array<Dynamic>
  {
    return [for (event in editedEvents) Reflect.copy(event.valueAsStruct())];
  }

  /**
   * Records what has changed since the last snapshot into the undo history.
   */
  function commitEdit():Bool
  {
    var current:Array<Dynamic> = takeSnapshot();
    if (current.length != lastSnapshot.length) return false;
    if (!snapshotsDiffer(lastSnapshot, current)) return false;
    EditEventPropertiesCommand.push(cameraEditorState, editedEvents, lastSnapshot, current);
    lastSnapshot = current;
    return true;
  }

  static function snapshotsDiffer(a:Array<Dynamic>, b:Array<Dynamic>):Bool
  {
    for (i in 0...a.length)
    {
      for (field in Reflect.fields(a[i]).concat(Reflect.fields(b[i])))
      {
        if (Reflect.field(a[i], field) != Reflect.field(b[i], field)) return true;
      }
    }
    return false;
  }

  /**
   * Points the panel at the current selection again, without rebuilding it.
   */
  public function reload():Void
  {
    lastSnapshot = takeSnapshot();
    var previousPlaceholders:Array<Component> = placeholdersShown;
    placeholdersShown = [];
    mixedFields = [];
    loadCurrentEventData();
    for (component in previousPlaceholders)
    {
      if (!mixedFields.contains(component)) clearPlaceholder(component);
    }
    applyMixedPlaceholders();
  }

  /**
   * Fields currently showing the placeholder.
   */
  var placeholdersShown:Array<Component> = [];

  function clearPlaceholder(component:Component):Void
  {
    if (Std.isOfType(component, NumberStepper))
    {
      var stepper:NumberStepper = cast component;
      var inner:Null<TextField> = stepper.findComponent('value', TextField);
      if (inner == null) return;
      var text:String = haxe.ui.util.StringUtil.padDecimal(stepper.value, stepper.precision);
      quietly(inner, () -> inner.text = text);
    }
    else if (Std.isOfType(component, DropDown))
    {
      showSelectedText(cast component);
    }
    else
    {
      for (dropdown in component.findComponents(null, DropDown)) showSelectedText(dropdown);
    }
  }

  function showSelectedText(dropdown:DropDown):Void
  {
    var item:Dynamic = dropdown.selectedItem;
    if (item == null || item.text == null) return;
    var text:String = item.text;
    quietly(dropdown, () -> dropdown.text = text);
  }

  /**
   * What fields show when the selected events have different values for them.
   */
  public static inline var MIXED_TEXT:String = '---';

  /**
   * Fields whose value differs between the selected events, filled in by `markShared`.
   */
  var mixedFields:Array<Component> = [];

  /**
   * The real label of each checkbox, since a mixed one gets the placeholder added to it.
   */
  var checkboxLabels:Map<Component, String> = new Map();

  /**
   * What each text field was last filled with, so loading it does not count as an edit.
   */
  var loadedTexts:Map<Component, String> = new Map();

  /**
   * Changes a field without its change event going through.
   */
  function quietly(component:Component, apply:Void->Void):Void
  {
    component.pauseEvent(UIEvent.CHANGE, true);
    apply();
    component.syncComponentValidation(false);
    component.resumeEvent(UIEvent.CHANGE, true, true);
  }

  /**
   * Shows the placeholder in every field the selected events have different values for.
   */
  function applyMixedPlaceholders():Void
  {
    for (component in mixedFields)
    {
      placeholdersShown.push(component);
      if (Std.isOfType(component, NumberStepper))
      {
        var stepper:NumberStepper = cast component;
        quietly(stepper, () -> {});
        var inner:Null<TextField> = stepper.findComponent('value', TextField);
        if (inner != null) quietly(inner, () -> inner.text = MIXED_TEXT);
      }
      else if (Std.isOfType(component, DropDown))
      {
        var dropdown:DropDown = cast component;
        quietly(dropdown, () -> dropdown.selectedIndex = -1);
        quietly(dropdown, () -> dropdown.text = MIXED_TEXT);
      }
      else if (Std.isOfType(component, CheckBox))
      {
        var checkbox:CheckBox = cast component;
        if (!checkboxLabels.exists(checkbox)) checkboxLabels.set(checkbox, checkbox.text);
        quietly(checkbox, () ->
        {
          checkbox.selected = false;
          checkbox.text = '${checkboxLabels.get(checkbox)} $MIXED_TEXT';
        });
        loadedBools.set(checkbox, false);
      }
      else if (Std.isOfType(component, TextField))
      {
        var field:TextField = cast component;
        quietly(field, () -> field.text = '');
        field.placeholder = MIXED_TEXT;
        loadedTexts.set(field, '');
      }
      else
      {
        // Groups like the ease picker
        for (dropdown in component.findComponents(null, DropDown))
        {
          quietly(dropdown, () -> dropdown.text = MIXED_TEXT);
        }
      }
    }
  }

  /**
   * Writes a value to the field on every edited event.
   */
  function setOnAll(fieldName:String, value:Dynamic):Void
  {
    for (event in editedEvents) event.set(fieldName, value);
  }

  /**
   * Copies a field from the primary event onto the other edited events.
   */
  function copyFromPrimary(fieldName:String):Void
  {
    final primary:Null<SongEventData> = primaryEvent;
    if (primary == null) return;
    final value:Dynamic = primary.getDynamic(fieldName);
    for (event in editedEvents)
    {
      if (event != primary) TimelineUtil.setEventField(event, fieldName, value);
    }
  }

  /**
   * Whether every edited event has the same value for the field.
   */
  function allMatch(fieldName:String, defaultValue:Dynamic):Bool
  {
    final primary:Null<SongEventData> = primaryEvent;
    if (primary == null) return true;
    final value:Dynamic = primary.getDynamic(fieldName) ?? defaultValue;
    for (event in editedEvents)
    {
      final other:Dynamic = event.getDynamic(fieldName) ?? defaultValue;
      if (other != value) return false;
    }
    return true;
  }

  /**
   * Fields only stay editable when they are the same.
   */
  function markShared(component:Component, shared:Bool):Void
  {
    component.tooltip = shared ? null : 'The selected events have different values, changing this sets all of them';
    if (!shared)
    {
      if (!mixedFields.contains(component)) mixedFields.push(component);
      return;
    }

    mixedFields.remove(component);
    restoreMixedLabel(component);
    if (Std.isOfType(component, TextField))
    {
      var field:TextField = cast component;
      field.placeholder = null;
    }
  }

  function restoreMixedLabel(component:Component):Void
  {
    if (!checkboxLabels.exists(component)) return;
    component.text = checkboxLabels.get(component);
    checkboxLabels.remove(component);
  }

  /**
   * Populate UI controls from the currently-selected event.
   * Called once after construction by the dispatcher.
   */
  public abstract function loadCurrentEventData():Void;

  /**
   * Override to return the ease preview owned by this container, so the
   * base's `destroy()` can call `cleanup()`. Containers without an ease
   * preview return `null` (the default).
   */
  function getEasePreview():Null<EaseGraphPreview>
  {
    return null;
  }

  /**
   * Replays the camera timeline so the viewport reflects the edited values.
   * Call from any onChange handler that mutates a field affecting the
   * camera state at the current playhead.
   */
  function updateCameraPreview():Void
  {
    // Loading a selection also comes through here, the replay only matters when something changed.
    if (commitEdit()) cameraEditorState.requestCameraReplay();
  }

  /**
   * Refresh the timeline block visuals. Call from onChange handlers that
   * mutate a field affecting block layout (currently only `duration`).
   */
  function updateBlockVisuals():Void
  {
    cameraEditorState.timeline.viewport.refreshBlockVisuals(true);
  }

  override public function destroy():Void
  {
    super.destroy();
    FlxG.stage.removeEventListener(openfl.events.KeyboardEvent.KEY_DOWN, onFormulaKey);
    listeningForEnter = false;
    formulaFields = [];
    final preview:Null<EaseGraphPreview> = getEasePreview();
    if (preview != null) preview.cleanup();
  }

  /**
   * Whether mutating the named field requires refreshing the timeline block
   * visuals. Override per-kind if a non-`duration` field also affects layout.
   */
  function fieldAffectsBlockVisuals(fieldName:String):Bool
  {
    return fieldName == 'duration';
  }

  /**
   * Pull the current event's Float value for `fieldName` into `stepper`,
   * falling back to `defaultValue` if the field is unset.
   * Call from `loadCurrentEventData()`.
   */
  function loadFloatField(stepper:NumberStepper, fieldName:String, defaultValue:Float):Void
  {
    final selected:Null<SongEventData> = primaryEvent;
    if (selected == null) return;
    markShared(stepper, allMatch(fieldName, defaultValue));
    loadNumber(stepper, selected.getFloat(fieldName) ?? defaultValue);
  }

  /**
   * What each number field was last filled with, either by loading or by the user.
   */
  var loadedNumbers:Map<Component, Float> = new Map();

  var loadingNumber:Bool = false;

  /**
   * Fills a number field without the change counting as an edit.
   */
  function loadNumber(field:Component, value:Float):Void
  {
    loadingNumber = true;
    field.value = value;
    loadingNumber = false;
    loadedNumbers.set(field, field.value);
  }

  /**
   * Whether a number field change came from the user, and not from loading it.
   */
  function isUserNumberChange(field:Component, value:Float):Bool
  {
    if (loadingNumber) return false;
    if (loadedNumbers.exists(field) && loadedNumbers.get(field) == value && !(mixedFields.contains(field) && hasFocusWithin(field))) return false;
    loadedNumbers.set(field, value);
    return true;
  }

  /**
   * What each checkbox was last set to, by loading or by the user.
   */
  var loadedBools:Map<Component, Bool> = new Map();

  /**
   * Whether a checkbox change came from the user, and not from a late change event of loading it.
   */
  function isUserBoolChange(field:Component, value:Bool):Bool
  {
    if (loadedBools.exists(field) && loadedBools.get(field) == value) return false;
    loadedBools.set(field, value);
    return true;
  }

  /**
   * Change events this soon after loading a field come from the loading itself, HaxeUI can send them a frame late.
   */
  static inline var LOAD_SETTLE_MS:Float = 150;

  var easeLoadTicks:Float = -1;

  /**
   * What each dropdown was last set to, by loading or by the user.
   */
  var loadedChoices:Map<Component, Dynamic> = new Map();

  var choiceLoadTicks:Float = -1;

  /**
   * Remembers what a dropdown was loaded with. Call right after selecting the loaded value.
   */
  function rememberChoice(field:Component, value:Dynamic):Void
  {
    loadedChoices.set(field, value);
    choiceLoadTicks = FlxG.game.ticks;
  }

  /**
   * Whether a dropdown change came from the user.
   */
  function isUserChoiceChange(field:Component, value:Dynamic):Bool
  {
    if (loadedChoices.exists(field) && loadedChoices.get(field) == value && FlxG.game.ticks - choiceLoadTicks < LOAD_SETTLE_MS) return false;
    loadedChoices.set(field, value);
    return true;
  }
  var loadedEase:Dynamic = null;
  var loadedEaseDir:Dynamic = null;

  /**
   * Remembers the primary event's ease, call after pointing the ease picker at it.
   */
  function rememberEase():Void
  {
    easeLoadTicks = FlxG.game.ticks;
    loadedEase = primaryEvent?.getDynamic('ease');
    loadedEaseDir = primaryEvent?.getDynamic('easeDir');
  }

  /**
   * The ease picker only edits the primary event, this passes the parts that changed on to the rest.
   */
  function onEasePreviewChange():Void
  {
    var primary:Null<SongEventData> = primaryEvent;
    if (primary == null) return;

    if (FlxG.game.ticks - easeLoadTicks < LOAD_SETTLE_MS)
    {
      TimelineUtil.setEventField(primary, 'ease', loadedEase);
      TimelineUtil.setEventField(primary, 'easeDir', loadedEaseDir);
      return;
    }

    var ease:Dynamic = primary.getDynamic('ease');
    var easeDir:Dynamic = primary.getDynamic('easeDir');
    if (ease != loadedEase) copyFromPrimary('ease');
    if (easeDir != loadedEaseDir) copyFromPrimary('easeDir');
    loadedEase = ease;
    loadedEaseDir = easeDir;

    updateCameraPreview();
    updateBlockVisuals();
  }

  /**
   * Whether the focused HaxeUI component is this one or inside it.
   */
  static function hasFocusWithin(field:Component):Bool
  {
    var focused:Null<Component> = cast haxe.ui.focus.FocusManager.instance.focus;
    while (focused != null)
    {
      if (focused == field) return true;
      focused = focused.parentComponent;
    }
    return false;
  }

  /**
   * Wire `stepper.CHANGE` to write its value into the selected event's
   * `fieldName`, then refresh the camera preview (and block visuals when
   * `fieldAffectsBlockVisuals(fieldName)`). Call once from the constructor.
   */
  function bindFloatField(stepper:NumberStepper, fieldName:String):Void
  {
    bindFormula(stepper, fieldName);
    stepper.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void
    {
      if (primaryEvent == null || stepper.disabled) return;
      if (!isUserNumberChange(stepper, stepper.value)) return;
      setOnAll(fieldName, stepper.value);
      updateCameraPreview();
      if (fieldAffectsBlockVisuals(fieldName)) updateBlockVisuals();
    });
  }

  var formulaStart:Map<Component, String> = new Map();

  /**
   * Math for a number field.
   */
  function bindFormula(stepper:NumberStepper, fieldName:String, isInt:Bool = false):Void
  {
    var inner:Null<TextField> = stepper.findComponent('value', TextField);
    if (inner == null) return;
    inner.restrictChars = '0-9\\-\\.\\,\\+\\*/\\x5E\\(\\) ';
    inner.registerEvent(UIEvent.CHANGE, function(event:UIEvent):Void
    {
      // Don't let the stepper read half-typed math as a number.
      if (NumberFormula.isFormula(inner.text)) event.cancel();
      else formulaStart.set(stepper, inner.text);
      showFormula(inner);
    }, Priority.HIGHEST);
    stepper.registerEvent(FocusEvent.FOCUS_IN, function(_:FocusEvent):Void
    {
      formulaStart.set(stepper, inner.text);
    });
    stepper.registerEvent(FocusEvent.FOCUS_OUT, function(_:FocusEvent):Void
    {
      applyFormula(stepper, inner, fieldName, isInt);
    });
    // The stepper holds the focus and not its text field, so the text field never sends SUBMIT.
    if (!listeningForEnter)
    {
      FlxG.stage.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, onFormulaKey);
      listeningForEnter = true;
    }
    formulaFields.push(() -> if (hasFocusWithin(stepper)) applyFormula(stepper, inner, fieldName, isInt));
  }

  /**
   * Applies the math in whichever number field has the focus, one per bound field.
   */
  var formulaFields:Array<Void->Void> = [];

  var listeningForEnter:Bool = false;

  function onFormulaKey(event:openfl.events.KeyboardEvent):Void
  {
    if (event.keyCode != openfl.ui.Keyboard.ENTER && event.keyCode != openfl.ui.Keyboard.NUMPAD_ENTER) return;
    for (apply in formulaFields) apply();
  }

  function applyFormula(stepper:NumberStepper, inner:TextField, fieldName:String, isInt:Bool):Void
  {
    if (primaryEvent == null || stepper.disabled) return;
    var text:String = inner.text;
    var start:String = formulaStart.get(stepper) ?? '';
    if (text == start || !NumberFormula.isFormula(text)) return;

    var tail:Null<String> = NumberFormula.relativePart(text, start);
    var whole:Float = tail == null ? NumberFormula.evaluate(text) : Math.NaN;
    for (event in editedEvents)
    {
      var value:Float = tail == null ? whole : NumberFormula.evaluateOn(numberOf(event, fieldName), tail);
      if (Math.isNaN(value)) continue;
      if (stepper.min != null) value = Math.max(value, stepper.min);
      if (stepper.max != null) value = Math.min(value, stepper.max);
      if (isInt) event.set(fieldName, Math.round(value));
      else event.set(fieldName, value);
    }

    updateCameraPreview();
    if (fieldAffectsBlockVisuals(fieldName)) updateBlockVisuals();
    reload();
    formulaStart.set(stepper, inner.text);
    showFormula(inner);
  }

  /**
   * The box goes dark blue while math is typed in it.
   */
  static inline var FORMULA_COLOR:Int = 0x1C2B4A;

  function showFormula(inner:TextField):Void
  {
    if (inner.text != MIXED_TEXT && NumberFormula.isFormula(inner.text)) inner.backgroundColor = FORMULA_COLOR;
    else
      inner.backgroundColor = null;
  }

  /**
   * An event's number for the field, falling back to the field's default if not set.
   */
  function numberOf(event:SongEventData, fieldName:String):Float
  {
    var value:Null<Float> = event.getFloat(fieldName);
    if (value != null) return value;
    var fallback:Dynamic = event.getSchema()?.getByName(fieldName)?.defaultValue;
    return fallback != null ? (fallback : Float) : 0;
  }

  /**
   * Pull the current event's String value for `fieldName` into `field`,
   * falling back to `defaultValue` if the field is unset.
   * Call from `loadCurrentEventData()`.
   */
  function loadStringField(field:TextField, fieldName:String, defaultValue:String):Void
  {
    final selected:Null<SongEventData> = primaryEvent;
    if (selected == null) return;
    markShared(field, allMatch(fieldName, defaultValue));
    final value:String = selected.getString(fieldName) ?? defaultValue;
    quietly(field, () -> field.text = value);
    loadedTexts.set(field, value);
  }

  /**
   * Wire `field.CHANGE` to write its text into the selected event's
   * `fieldName`, then refresh the camera preview (and block visuals when
   * `fieldAffectsBlockVisuals(fieldName)`). Call once from the constructor.
   */
  function bindStringField(field:TextField, fieldName:String):Void
  {
    field.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void
    {
      if (primaryEvent == null || field.disabled) return;
      if (loadedTexts.get(field) == field.text) return;
      loadedTexts.set(field, field.text);
      setOnAll(fieldName, field.text);
      updateCameraPreview();
      if (fieldAffectsBlockVisuals(fieldName)) updateBlockVisuals();
    });
  }

  /**
   * Pull the current event's Bool value for `fieldName` into `field`,
   * falling back to `defaultValue` if the field is unset.
   * Call from `loadCurrentEventData()`.
   */
  function loadBoolField(field:CheckBox, fieldName:String, defaultValue:Bool):Void
  {
    final selected:Null<SongEventData> = primaryEvent;
    if (selected == null) return;
    markShared(field, allMatch(fieldName, defaultValue));
    final value:Bool = selected.getBool(fieldName) ?? defaultValue;
    quietly(field, () -> field.selected = value);
    loadedBools.set(field, value);
  }

  /**
   * Wire `field.CHANGE` to write its selected state into the selected event's
   * `fieldName`, then refresh the camera preview (and block visuals when
   * `fieldAffectsBlockVisuals(fieldName)`). Call once from the constructor.
   */
  function bindBoolField(field:CheckBox, fieldName:String):Void
  {
    field.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void
    {
      if (primaryEvent == null || field.disabled) return;
      if (!isUserBoolChange(field, field.selected)) return;
      restoreMixedLabel(field);
      setOnAll(fieldName, field.selected);
      updateCameraPreview();
      if (fieldAffectsBlockVisuals(fieldName)) updateBlockVisuals();
    });
  }
}
#end
