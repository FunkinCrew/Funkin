package funkin.api.newgrounds;

#if FEATURE_NEWGROUNDS
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
    var loadedSave:NGSaveSlot = loadSlot(Constants.BASE_SAVE_SLOT);
    if (_instance == null) _instance = loadedSave;

    return loadedSave;
  }

  static function loadSlot(slot:Int):NGSaveSlot
  {
    trace(' NEWGROUNDS '.bold().bg_orange() + ' Getting save slot from ID $slot');

    var saveSlot:Null<SaveSlot> = NewgroundsClient.instance.saveSlots?.getById(slot);

    var saveSlotObj:NGSaveSlot = new NGSaveSlot(saveSlot);
    return saveSlotObj;
  }

  public var ngSaveSlot:Null<SaveSlot> = null;

  public function new(?ngSaveSlot:Null<SaveSlot>)
  {
    this.ngSaveSlot = ngSaveSlot;
  }

  /**
   * Saves `data` to the newgrounds save slot.
   * @param data The raw save data.
   */
  public function save(data:RawSaveData):Void
  {
    var encodedData:String = haxe.Serializer.run(data);

    try
    {
      ngSaveSlot?.save(encodedData, function(outcome:Outcome<CallError>) {
        switch (outcome)
        {
          case SUCCESS:
            trace(' NEWGROUNDS '.bold().bg_orange() + ' Successfully saved save data to save slot!');
          case FAIL(error):
            trace(' NEWGROUNDS '.bold().bg_orange() + ' Failed to save data to save slot!');
            trace(error);
        }
      });
    }
    catch (error:String)
    {
      trace(' NEWGROUNDS '.bold().bg_orange() + ' Failed to save data to save slot!');
      trace(error);
    }
  }

  public function load(?onComplete:Null<Dynamic->Void>, ?onError:Null<CallError->Void>):Void
  {
    try
    {
      ngSaveSlot?.load(function(outcome:SaveSlotOutcome):Void {
        switch (outcome)
        {
          case SUCCESS(value):
            trace(' NEWGROUNDS '.bold().bg_orange() + ' Loaded save slot with the ID of ${ngSaveSlot?.id}!');
            #if FEATURE_DEBUG_FUNCTIONS
            trace('Save Slot Data:');
            trace(value);
            #end

            if (onComplete != null && value != null)
            {
              var decodedData:Dynamic = haxe.Unserializer.run(value);
              onComplete(decodedData);
            }
          case FAIL(error):
            trace(' NEWGROUNDS '.bold().bg_orange() + ' Failed to load save slot with the ID of ${ngSaveSlot?.id}!');
            trace(error);

            if (onError != null)
            {
              onError(error);
            }
        }
      });
    }
    catch (error:String)
    {
      trace(' NEWGROUNDS '.bold().bg_orange() + ' Failed to load save slot with the ID of ${ngSaveSlot?.id}!');
      trace(error);

      if (onError != null)
      {
        onError(RESPONSE({message: error, code: 500}));
      }
    }
  }

  public function clear():Void
  {
    try
    {
      ngSaveSlot?.clear(function(outcome:Outcome<CallError>) {
        switch (outcome)
        {
          case SUCCESS:
            trace(' NEWGROUNDS '.bold().bg_orange() + ' Successfully cleared save slot!');
          case FAIL(error):
            trace(' NEWGROUNDS '.bold().bg_orange() + ' Failed to clear save slot!');
            trace(error);
        }
      });
    }
    catch (error:String)
    {
      trace(' NEWGROUNDS '.bold().bg_orange() + ' Failed to clear save slot!');
      trace(error);
    }
  }

  public function checkSlot():Void
  {
    trace(' NEWGROUNDS '.bold().bg_orange() + ' Checking save slot with the ID of ${ngSaveSlot?.id}...');

    trace(' Is null? ${ngSaveSlot == null}');
    trace(' Is empty? ${ngSaveSlot?.isEmpty() ?? false}');
  }
}
#end
