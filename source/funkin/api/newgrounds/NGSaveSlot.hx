package funkin.api.newgrounds;

import io.newgrounds.utils.SaveSlotList;
import io.newgrounds.objects.SaveSlot;
import io.newgrounds.Call.CallError;
import io.newgrounds.objects.events.Outcome;
import funkin.save.Save;

@:nullSafety
@:access(funkin.save.Save)
class NGSaveSlot
{
  public static var instance(get, never):NGSaveSlot;
  static var _instance:Null<NGSaveSlot> = null;

  static function get_instance():NGSaveSlot
  {
    if (_instance == null)
    {
      return loadInstance();
    }
    return _instance;
  }

  public static function loadInstance():NGSaveSlot
  {
    trace("[NEWGROUNDS] Loading save slot...");

    var loadedSave:NGSaveSlot = loadSlot(Save.BASE_SAVE_SLOT);
    if (_instance == null) _instance = loadedSave;

    return loadedSave;
  }

  static function loadSlot(slot:Int):NGSaveSlot
  {
    trace('[NEWGROUNDS] Loading save slot from ID $slot');

    var saveSlot:Null<SaveSlot> = NewgroundsClient.instance.saveSlots?.getById(slot);

    if (saveSlot != null && !saveSlot.isEmpty())
    {
      // Precache Slots
      saveSlot.load(function(outcome:SaveSlotOutcome):Void {
        switch (outcome)
        {
          case SUCCESS(value):
            trace('[NEWGROUNDS] Loaded save slot with the ID of ${saveSlot.id}!');
            #if FEATURE_DEBUG_FUNCTIONS
            trace('Save Slot Data:');
            trace(value);
            #end
          case FAIL(error):
            trace('[NEWGROUNDS] Failed to load save slot with the ID of ${saveSlot.id}!');
            trace(error);
        }
      });
    }

    var saveSlotObj:NGSaveSlot = new NGSaveSlot(saveSlot);
    return saveSlotObj;
  }

  public var ngSaveSlot:Null<SaveSlot> = null;

  public function new(?ngSaveSlot:Null<SaveSlot>)
  {
    this.ngSaveSlot = ngSaveSlot;

    #if FLX_DEBUG
    FlxG.console.registerClass(NGSaveSlot);
    FlxG.console.registerClass(Save);
    #end
  }

  /**
   * Saves `data` to the newgrounds save slot.
   * @param data The raw save data.
   */
  public function save(data:RawSaveData):Void
  {
    var encodedData:String = haxe.Serializer.run(data);

    ngSaveSlot?.save(encodedData, function(outcome:Outcome<CallError>) {
      switch (outcome)
      {
        case SUCCESS:
          trace('[NEWGROUNDS] Successfully saved save data to save slot!');
        case FAIL(error):
          trace('[NEWGROUNDS] Failed to save data to save slot!');
          trace(error);
      }
    });
  }

  public function load():Dynamic
  {
    var encodedData:Null<String> = ngSaveSlot?.contents;

    if (encodedData == null) return null;

    return haxe.Unserializer.run(encodedData);
  }
}
