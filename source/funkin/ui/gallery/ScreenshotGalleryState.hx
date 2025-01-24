package funkin.ui.gallery;

import funkin.input.Cursor;
import funkin.graphics.FunkinCamera;
import funkin.util.plugins.ScreenshotPlugin;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import openfl.display.BitmapData;

class ScreenshotGalleryState extends MusicBeatState
{
  inline static final ROWS:Int = 3;
  inline static final BORDER_SIZE:Int = 5;

  var allScreenshots:Array<FlxSprite> = [];
  var screenshotNames:Array<String> = [];
  var camFollow:FlxObject;
  var shotOutline:FlxSprite;

  var camSUB:FlxCamera;
  var camHUD:FlxCamera;

  override public function create()
  {
    super.create();

    FlxG.cameras.reset(new FunkinCamera('gallery'));

    camSUB = new FlxCamera();
    camSUB.bgColor.alpha = 0;
    camHUD = new FlxCamera();
    camHUD.bgColor.alpha = 0;

    FlxG.cameras.add(camSUB, false);
    FlxG.cameras.add(camHUD, false);

    camFollow = new FlxObject(0, 0, 1, 1);
    camFollow.screenCenter(X);
    add(camFollow);

    FlxG.camera.follow(camFollow, null, 0.06);

    Cursor.show();

    persistentUpdate = false;
    persistentDraw = true;

    var menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
    menuBG.color = 0xFF874CAF;
    menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    add(menuBG);

    shotOutline = new FlxSprite().makeGraphic(1, 1);
    shotOutline.visible = false;
    add(shotOutline);

    reloadScreenshots();
  }

  var minCamY:Float = FlxG.height / 2;
  var maxCamY:Float = FlxG.height / 2;

  override public function update(elapsed:Float)
  {
    super.update(elapsed);

    if (FlxG.mouse.wheel != 0) camFollow.y -= FlxG.mouse.wheel * 25;

    if (camFollow.y > maxCamY) camFollow.y = maxCamY;
    else if (camFollow.y < minCamY) camFollow.y = minCamY;

    shotOutline.visible = false;
    for (shot in allScreenshots)
    {
      if (FlxG.mouse.overlaps(shot))
      {
        shotOutline.visible = true;
        shotOutline.x = shot.x - BORDER_SIZE;
        shotOutline.y = shot.y - BORDER_SIZE;

        if (FlxG.mouse.justPressed)
        {
          var sub = new EditScreenshotSubState(shot, screenshotNames[allScreenshots.indexOf(shot)]);
          sub.cameras = [camSUB];
          openSubState(sub);
        }
      }
    }

    #if FEATURE_SCREENSHOTS
    if (controls.WINDOW_SCREENSHOT) reloadScreenshots();
    #end

    if (controls.BACK)
    {
      FlxG.switchState(() -> new funkin.ui.debug.DebugMenuSubState());
    }
  }

  override public function onFocus()
  {
    super.onFocus();
    reloadScreenshots();
  }

  function reloadScreenshots() // this should also activate when a screenshot is taken/deleted!
  {
    minCamY = FlxG.height / 2;
    maxCamY = FlxG.height / 2;

    while (allScreenshots.length > 0)
    {
      var daSS:FlxSprite = allScreenshots.pop();

      daSS.kill();
      remove(daSS, true);
      daSS.destroy();
    }

    #if sys
    var allFiles:Array<String> = sys.FileSystem.readDirectory(ScreenshotPlugin.SCREENSHOT_FOLDER);
    allFiles.reverse();

    var shotWidth:Float = FlxG.width / (ROWS + 1);
    var shotHeight:Float = FlxG.height / (ROWS + 1);
    var shotSpacing:Float = (FlxG.width - ROWS * shotWidth) / (ROWS + 1);

    for (i in 0...allFiles.length)
    {
      var path:String = allFiles[i];
      if (haxe.io.Path.extension(path) != "png") continue;

      var shot:FlxSprite = new FlxSprite().loadGraphic(BitmapData.fromFile(ScreenshotPlugin.SCREENSHOT_FOLDER + "/" + path));
      shot.setGraphicSize(Std.int(shotWidth), Std.int(shotHeight));
      shot.updateHitbox();

      // positioning da screenshots
      var column:Int = Math.floor(i / ROWS);
      var row:Int = i % ROWS;

      shot.x = row * (shotWidth + shotSpacing) + shotSpacing;
      shot.y = column * (shotHeight + shotSpacing / 2) + shotSpacing / 2;

      add(shot);
      allScreenshots.push(shot);
      screenshotNames.push(haxe.io.Path.withoutExtension(path));

      // update the maxcamy
      if (shot.y + shot.height > FlxG.height)
      {
        maxCamY = shot.y + shot.height + shotSpacing / 2 - FlxG.height / 2;
      }
    }

    shotOutline.setGraphicSize(allScreenshots.length > 0 ? Std.int(shotWidth + BORDER_SIZE * 2) : 1,
      allScreenshots.length > 0 ? Std.int(shotHeight + BORDER_SIZE * 2) : 1);

    shotOutline.updateHitbox();
    #end
  }
}
