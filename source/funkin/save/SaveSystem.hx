package funkin.save;

import funkin.save.migrator.RawSaveData_v1_0_0;
import funkin.save.migrator.SaveDataMigrator;
import flixel.util.FlxSave;

/**
 * A bit more of the backend and nitty gritty of FNF's save system
 */
class SaveSystem
{
  public function new():Void {}

  /**
   * Call this to make sure the save data is written to disk.
   */
  public function flush():Void
  {
    FlxG.save.flush();
  }

  public function clearSlot(slot:Int):Save
  {
    FlxG.save.bind(Constants.SAVE_NAME + slot, Constants.SAVE_PATH);

    if (FlxG.save.status == EMPTY) return new Save();

    // Archive the save data just in case.
    // Not reliable but better than nothing.
    var backupSlot:Int = Save.system.archiveBadSaveData(FlxG.save.data);

    FlxG.save.erase();
    return new Save();
  }

  public function fetchLegacySaveData():Option<RawSaveData_v1_0_0>
  {
    trace("[SAVE] Checking for legacy save data...");
    var legacySave:FlxSave = new FlxSave();
    legacySave.bind(Constants.SAVE_NAME_LEGACY, Constants.SAVE_PATH_LEGACY);

    if (legacySave.isEmpty())
    {
      trace("[SAVE] No legacy save data found.");
      return None;
    }
    else
    {
      trace("[SAVE] Legacy save data found.");
      return Some(cast legacySave.data);
    }
  }

  public function archiveBadSaveData(data:Dynamic):Int
  {
    // We want to save this somewhere so we can try to recover it for the user in the future!
    final RECOVERY_SLOT_START = 1000;
    return writeToAvailableSlot(RECOVERY_SLOT_START, data);
  }

  function writeToAvailableSlot(slot:Int, data:Dynamic):Int
  {
    trace('[SAVE] Finding slot to write data to (starting with ${slot})...');

    var targetSaveData:FlxSave = new FlxSave();
    targetSaveData.bind(Constants.SAVE_NAME + slot, Constants.SAVE_PATH);
    while (!targetSaveData.isEmpty())
    {
      // Keep trying to bind to slots until we find an empty slot.
      trace('[SAVE] Slot ${slot} is taken, continuing...');
      slot++;
      targetSaveData.bind(Constants.SAVE_NAME + slot, Constants.SAVE_PATH);
    }

    trace('[SAVE] Writing data to slot ${slot}...');
    targetSaveData.mergeData(data, true);

    trace('[SAVE] Data written to slot ${slot}!');
    return slot;
  }
}
