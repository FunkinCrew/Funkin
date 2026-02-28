package funkin.ui.debug.charting.util;

#if FEATURE_CHART_EDITOR
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.data.song.SongData.SongTimeChange;
import funkin.play.event.SongEvent;
import funkin.data.stage.StageRegistry;
import funkin.data.character.CharacterData;
import haxe.ui.components.DropDown;
import funkin.play.stage.Stage;
import funkin.play.notes.notekind.NoteKind;
import funkin.play.notes.notekind.NoteKindManager;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.data.event.SongEventRegistry;
import funkin.data.character.CharacterData.CharacterDataParser;

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
   * Populate a dropdown with a list of time changes.
   */
  public static function populateDropdownWithTimeChanges(dropDown:DropDown, timeChanges:Array<SongTimeChange>, startingTimeChange:Int = 0):DropDownEntry
  {
    dropDown.dataSource.clear();

    var returnValue:DropDownEntry = {
      id: "0",
      text: '${timeChanges[0].timeStamp} ms : BPM: ${timeChanges[0].bpm} in ${timeChanges[0].timeSignatureNum}/${timeChanges[0].timeSignatureDen}'
    };

    for (index in 0...timeChanges.length)
    {
      var value = {
        id: '$index',
        text: '${timeChanges[index].timeStamp} ms : BPM: ${timeChanges[index].bpm} in ${timeChanges[index].timeSignatureNum}/${timeChanges[index].timeSignatureDen}'
      };
      if (startingTimeChange == index) returnValue = value;

      dropDown.dataSource.add(value);
    }

    dropDown.dataSource.sort('id', ASCENDING);

    return returnValue;
  }

  /**
   * Populate a dropdown with a list of song events.
   */
  public static function populateDropdownWithSongEvents(dropDown:DropDown, startingEventId:String):DropDownEntry
  {
    dropDown.dataSource.clear();

    var returnValue:DropDownEntry = {id: "FocusCamera", text: "Focus Camera"};

    var songEvents:Array<SongEvent> = SongEventRegistry.listEvents();

    for (event in songEvents)
    {
      var value = {id: event.id, text: event.getTitle()};
      if (startingEventId == event.id) returnValue = value;
      dropDown.dataSource.add(value);
    }

    dropDown.dataSource.sort('text', ASCENDING);

    return returnValue;
  }

  /**
   * Given the ID of a dropdown element, find the corresponding entry in the dropdown's dataSource.
   */
  public static function findDropdownElement(id:String, dropDown:DropDown):Null<DropDownEntry>
  {
    // Attempt to find the entry.
    for (entryIndex in 0...dropDown.dataSource.size)
    {
      var entry = dropDown.dataSource.get(entryIndex);
      if (entry.id == id) return entry;
    }

    // Not found.
    return null;
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

      // check if the note style has all necessary assets (strums, notes, holdNotes)
      if (noteStyle._data?.assets?.noteStrumline == null
        || noteStyle._data?.assets?.note == null
        || noteStyle._data?.assets?.holdNote == null)
      {
        continue;
      }

      var value = {id: noteStyleId, text: noteStyle.getName()};
      if (startingStyleId == noteStyleId) returnValue = value;

      dropDown.dataSource.add(value);
    }

    dropDown.dataSource.sort('text', ASCENDING);

    return returnValue;
  }

  /**
   * Populate the provided dropdown with the list of available note kinds.
   * @param dropDown The dropdown to populate
   * @param startingKindId The note kind to pre-select.
   * @return The dropdown entry for the pre-selected note kind.
   */
  public static function populateDropdownWithNoteKinds(dropDown:DropDown, startingKindId:String):DropDownEntry
  {
    dropDown.dataSource.clear();

    dropDown.dataSource.add({id: '', text: 'Default'});
    dropDown.dataSource.add({id: '~CUSTOM~', text: 'Custom'});

    var customNoteKinds:Array<String> = NoteKindManager.listNoteKinds();

    for (noteKindId in customNoteKinds)
    {
      dropDown.dataSource.add(lookupNoteKind(noteKindId));
    }

    dropDown.dataSource.sort('id', ASCENDING);

    return lookupNoteKind(startingKindId);
  }

  /**
   * Generates the dropdown entry for the provided note kind ID.
   * @param noteKindId The note kind ID
   * @return The dropdown entry
   */
  public static function lookupNoteKind(noteKindId:Null<String>):DropDownEntry
  {
    if (noteKindId == null) return lookupNoteKind('');
    if (noteKindId == '') return {id: '', text: 'Default'};

    var noteKind:Null<NoteKind> = NoteKindManager.getNoteKind(noteKindId);
    var noteKindDesc:Null<String> = noteKind?.description ?? noteKindId;
    if (noteKind != null) return {id: noteKindId ?? 'unknown', text: noteKindDesc ?? 'unknown'};

    return {id: '~CUSTOM~', text: 'Custom'};
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

#end
