package funkin.ui.debug.charting.util;

import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.data.stage.StageData;
import funkin.data.stage.StageRegistry;
import funkin.play.character.CharacterData;
import haxe.ui.components.DropDown;
import funkin.play.stage.Stage;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.play.character.CharacterData.CharacterDataParser;

/**
 * Functions for populating dropdowns based on game data.
 * These get used by both dialogs and toolboxes so they're in their own class to prevent "reaching over."
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorDropdowns
{
  /**
   * Populate a dropdown with a list of characters.
   */
  public static function populateDropdownWithCharacters(dropDown:DropDown, charType:CharacterType, startingCharId:String):DropDownEntry
  {
    dropDown.dataSource.clear();

    // TODO: Filter based on charType.
    var charIds:Array<String> = CharacterDataParser.listCharacterIds();

    var returnValue:DropDownEntry = switch (charType)
    {
      case BF: {id: "bf", text: "Boyfriend"};
      case DAD: {id: "dad", text: "Daddy Dearest"};
      default: {
          dropDown.dataSource.add({id: "none", text: ""});
          {id: "none", text: "None"};
        }
    }

    for (charId in charIds)
    {
      var character:Null<CharacterData> = CharacterDataParser.fetchCharacterData(charId);
      if (character == null) continue;

      var value = {id: charId, text: character.name};
      if (startingCharId == charId) returnValue = value;

      dropDown.dataSource.add(value);
    }

    dropDown.dataSource.sort('text', ASCENDING);

    return returnValue;
  }

  /**
   * Populate a dropdown with a list of stages.
   */
  public static function populateDropdownWithStages(dropDown:DropDown, startingStageId:String):DropDownEntry
  {
    dropDown.dataSource.clear();

    var stageIds:Array<String> = StageRegistry.instance.listEntryIds();

    var returnValue:DropDownEntry = {id: "mainStage", text: "Main Stage"};

    for (stageId in stageIds)
    {
      var stage:Null<Stage> = StageRegistry.instance.fetchEntry(stageId);
      if (stage == null) continue;

      var value = {id: stage.id, text: stage.stageName};
      if (startingStageId == stageId) returnValue = value;

      dropDown.dataSource.add(value);
    }

    dropDown.dataSource.sort('text', ASCENDING);

    return returnValue;
  }

  /**
   * Populate a dropdown with a list of note styles.
   */
  public static function populateDropdownWithNoteStyles(dropDown:DropDown, startingStyleId:String):DropDownEntry
  {
    dropDown.dataSource.clear();

    var noteStyleIds:Array<String> = NoteStyleRegistry.instance.listEntryIds();

    var returnValue:DropDownEntry = {id: "funkin", text: "Funkin'"};

    for (noteStyleId in noteStyleIds)
    {
      var noteStyle:Null<NoteStyle> = NoteStyleRegistry.instance.fetchEntry(noteStyleId);
      if (noteStyle == null) continue;

      var value = {id: noteStyleId, text: noteStyle.getName()};
      if (startingStyleId == noteStyleId) returnValue = value;

      dropDown.dataSource.add(value);
    }

    dropDown.dataSource.sort('text', ASCENDING);

    return returnValue;
  }

  static final NOTE_KINDS:Map<String, String> = [
    // Base
    "" => "Default",
    "~CUSTOM~" => "Custom",
    // Weeks 1-7
    "mom" => "Mom Sings (Week 5)",
    "ugh" => "Ugh (Week 7)",
    "hehPrettyGood" => "Heh, Pretty Good (Week 7)",
    // Weekend 1
    "weekend-1-lightcan" => "Light Can (2hot)",
    "weekend-1-kickcan" => "Kick Can (2hot)",
    "weekend-1-kneecan" => "Knee Can (2hot)",
    "weekend-1-cockgun" => "Cock Gun (2hot)",
    "weekend-1-firegun" => "Fire Gun (2hot)",
    "weekend-1-punchlow" => "Punch Low (Blazin)",
    "weekend-1-punchhigh" => "Punch High (Blazin)",
    "weekend-1-punchlowblocked" => "Punch Low Blocked (Blazin)",
    "weekend-1-punchhighblocked" => "Punch High Blocked (Blazin)",
    "weekend-1-dodgelow" => "Dodge Low (Blazin)",
    "weekend-1-blockhigh" => "Block High (Blazin)",
    "weekend-1-fakeout" => "Fakeout (Blazin)",
  ];

  public static function populateDropdownWithNoteKinds(dropDown:DropDown, startingKindId:String):DropDownEntry
  {
    dropDown.dataSource.clear();

    var returnValue:DropDownEntry = lookupNoteKind('~CUSTOM');

    for (noteKindId in NOTE_KINDS.keys())
    {
      var noteKind:String = NOTE_KINDS.get(noteKindId) ?? 'Default';

      var value:DropDownEntry = {id: noteKindId, text: noteKind};
      if (startingKindId == noteKindId) returnValue = value;

      dropDown.dataSource.add(value);
    }

    return returnValue;
  }

  public static function lookupNoteKind(noteKindId:Null<String>):DropDownEntry
  {
    if (noteKindId == null) return lookupNoteKind('');
    if (!NOTE_KINDS.exists(noteKindId)) return {id: '~CUSTOM~', text: 'Custom'};
    return {id: noteKindId ?? '', text: NOTE_KINDS.get(noteKindId) ?? 'Default'};
  }

  /**
   * Populate a dropdown with a list of song variations.
   */
  public static function populateDropdownWithVariations(dropDown:DropDown, state:ChartEditorState, includeNone:Bool = true):DropDownEntry
  {
    dropDown.dataSource.clear();

    var variationIds:Array<String> = state.availableVariations;

    if (includeNone)
    {
      dropDown.dataSource.add({id: "none", text: ""});
    }

    var returnValue:DropDownEntry = includeNone ? ({id: "none", text: ""}) : ({id: "default", text: "Default"});

    for (variationId in variationIds)
    {
      dropDown.dataSource.add({id: variationId, text: variationId.toTitleCase()});
    }

    dropDown.dataSource.sort('text', ASCENDING);

    return returnValue;
  }
}

/**
 * An entry in a dropdown.
 */
typedef DropDownEntry =
{
  id:String,
  text:String
};
