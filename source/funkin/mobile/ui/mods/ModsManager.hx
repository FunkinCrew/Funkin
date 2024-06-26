package funkin.mobile.ui.mods;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import funkin.mobile.util.TouchUtil;
import funkin.util.FileUtil;
import funkin.ui.MusicBeatSubState;
import funkin.modding.PolymodHandler;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.geom.Matrix;

// #if android
// import android.FileDialog;
// import android.widget.Toast;
// #end

/**
 * A Placeholder substate for simplefied mods management on Android targets
 */
class ModsManager extends MusicBeatSubState
{
  var background:FlxSprite;
  var importSpr:FlxSprite;
  var deleteSpr:FlxSprite;
  var importTxt:FlxText;
  var deleteTxt:FlxText;
  var alphaSine:Float = 0.0;
  var curButton:Null<FlxSprite>;
  var isImport:Bool = false;

  public function new()
  {
    super();

    // FileDialog.init();

    // var matrix:Matrix = new Matrix();
    // matrix.createGradientBox(FlxG.width, FlxG.height, 0, 0, 0);

    // var shape:Shape = new Shape();
    // shape.graphics.beginGradientFill(RADIAL, [0xFF373434, 0xFF373434], [0, 1], [20, 255], matrix, PAD, RGB, 0);
    // shape.graphics.drawRect(0, 0, FlxG.width, FlxG.height);
    // shape.graphics.endFill();

    // var graphicData:BitmapData = new BitmapData(FlxG.width, FlxG.height, true, 0);
    // graphicData.draw(shape, true);

    // background = new FlxSprite(0, 0, FlxGraphic.fromBitmapData(graphicData, false, null, false));
    // background.scrollFactor.set();
    // add(background);

    // importSpr = FlxSpriteUtil.drawRoundRect(new FlxSprite().makeGraphic(250, 125, FlxColor.TRANSPARENT), 0, 0, 250, 125, 30, 30, FlxColor.WHITE);
    // importSpr.scrollFactor.set();
    // add(importSpr);

    // deleteSpr = FlxSpriteUtil.drawRoundRect(new FlxSprite().makeGraphic(250, 125, FlxColor.TRANSPARENT), 0, 0, 250, 125, 30, 30, FlxColor.WHITE);
    // deleteSpr.scrollFactor.set();
    // add(deleteSpr);

    // importTxt = new FlxText(0, 0, importSpr.width, "Import", 24);
    // importTxt.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    // importTxt.scrollFactor.set();
    // add(importTxt);

    // deleteTxt = new FlxText(0, 0, deleteSpr.width, "Delete", 24);
    // deleteTxt.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    // deleteTxt.scrollFactor.set();
    // add(deleteTxt);

    // importSpr.screenCenter();
    // importSpr.x -= 150;
    // deleteSpr.screenCenter();
    // deleteSpr.x += 150;

    // importTxt.setPosition(importSpr.x + ((importSpr.width - importTxt.width) / 2), importSpr.y + ((importSpr.height - importTxt.height) / 2));
    // deleteTxt.setPosition(deleteSpr.x + ((deleteSpr.width - deleteTxt.width) / 2), deleteSpr.y + ((deleteSpr.height - deleteTxt.height) / 2));

    // // THE COLORS AND ALPHA KEEP MESSING UP WHILE CONSTRUCTING THE SPRITE INSTANCE IDFK WHY
    // importSpr.color = 0xFF00FF0D;
    // deleteSpr.color = 0xFFFF0000;
    // deleteSpr.alpha = importSpr.alpha = 0.75;
    // background.alpha = 0.7;
  }

  override public function update(elapsed:Float)
  {
    super.update(elapsed);

    // if (controls.BACK || FlxG.android.justReleased.BACK)
    // {
    //   FlxG.mouse.visible = false;
    //   FlxG.state.persistentUpdate = true;
    //   close();
    // }

    // alphaSine += 255 * elapsed;

    // if (curButton != null)
    // {
    //   curButton.alpha = 1 - Math.sin((Math.PI * alphaSine) / 163);

    //   if (TouchUtil.justPressed)
    //   {
    //     if (TouchUtil.overlaps(curButton))
    //     {
    //       if (isImport)
    //       {
    //         trace('[NOTICE] launched SAF!');
    //         FileDialog.launch(FileDialogType.OPEN_DOCUMENT, "application/x-zip-compressed");
    //         FileDialog.onOpen.add(function(content:FileContent) {
    //           trace(content.toString());
    //           @:privateAccess
    //           var aaa:String = PolymodHandler.MOD_FOLDER + '/' + content.name;
    //           trace(aaa);
    //           FileUtil.writeBytesToPath(aaa, content.bytes, Force);
    //         }, true);
    //       }
    //       else {}
    //     }

    //     if (!(TouchUtil.overlaps(importSpr) || TouchUtil.overlaps(deleteSpr)))
    //     {
    //       curButton.alpha = 0.75;
    //       curButton = null;
    //     }
    //   }
    // }

    // for (spr in [importSpr, deleteSpr])
    // {
    //   if (curButton != null) return;
    //   if (curButton == null && TouchUtil.overlaps(spr) && TouchUtil.justPressed)
    //   {
    //     if (spr == importSpr) isImport = true;
    //     curButton = spr;
    //     return;
    //   }
    // }
  }
}
