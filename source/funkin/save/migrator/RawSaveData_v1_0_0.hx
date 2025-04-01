package funkin.save.migrator;

import thx.semver.Version;

typedef RawSaveData_v1_0_0 =
{
  var seenVideo:Bool;
  var mute:Bool;
  var volume:Float;

  var sessionId:String;

  var songCompletion:Map<String, Float>;

  var songScores:Map<String, Int>;

  var ?controls:
    {
      ?p1:SavePlayerControlsData_v1_0_0,
      ?p2:SavePlayerControlsData_v1_0_0
    };
  var enabledMods:Array<String>;
  var weeksUnlocked:Array<Bool>;
  var windowSettings:Array<Bool>;
}

typedef SavePlayerControlsData_v1_0_0 =
{
  var keys:SaveControlsData_v1_0_0;
  var pad:SaveControlsData_v1_0_0;
};

typedef SaveControlsData_v1_0_0 =
{
  var ?ACCEPT:Array<Int>;
  var ?BACK:Array<Int>;
  var ?CUTSCENE_ADVANCE:Array<Int>;
  var ?NOTE_DOWN:Array<Int>;
  var ?NOTE_LEFT:Array<Int>;
  var ?NOTE_RIGHT:Array<Int>;
  var ?NOTE_UP:Array<Int>;
  var ?PAUSE:Array<Int>;
  var ?RESET:Array<Int>;
  var ?UI_DOWN:Array<Int>;
  var ?UI_LEFT:Array<Int>;
  var ?UI_RIGHT:Array<Int>;
  var ?UI_UP:Array<Int>;
  var ?VOLUME_DOWN:Array<Int>;
  var ?VOLUME_MUTE:Array<Int>;
  var ?VOLUME_UP:Array<Int>;
};
