package funkin.ui.debug.stage;

import flixel.group.FlxGroup;

class StagetoolBar extends FlxGroup
{
  var icons:Array<StageBuilderState.TOOLS> = [SELECT, MOVE, GRAB, BOYFRIEND];
  var iconSprs:Array<String> = ['cursorSelect', 'cursorGrab', 'cursorMove', 'toolbarBF'];

  public function new()
  {
    super();
  }
}
