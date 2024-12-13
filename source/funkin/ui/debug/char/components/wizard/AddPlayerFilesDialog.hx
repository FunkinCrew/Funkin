package funkin.ui.debug.char.components.wizard;

import haxe.io.Path;
import haxe.ui.containers.HBox;
import haxe.ui.containers.dialogs.Dialogs.FileDialogExtensionInfo;
import haxe.ui.components.Button;
import haxe.ui.components.TextField;
import funkin.ui.debug.char.handlers.CharCreatorStartupWizard;
import funkin.util.FileUtil;
import flxanimate.data.AnimationData.AnimAtlas;
import flxanimate.data.SpriteMapData.AnimateAtlas;
import funkin.data.character.CharacterData.CharacterRenderType;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxSprite;
import openfl.display.BitmapData;
import openfl.net.FileFilter;
import funkin.ui.debug.char.components.wizard.AddCharFilesDialog.UploadAssetsBox;

using StringTools;

// copy of AddCharFilesDialog lol
@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/char-creator/wizard/add-assets.xml"))
class AddPlayerFilesDialog extends DefaultWizardDialog
{
  override public function new()
  {
    super(UPLOAD_PLAYER_ASSETS);

    addAssetsBox.addComponent(new UploadAssetsBox("Put the path to the Character Select .zip Data Here", FileUtil.FILE_EXTENSION_INFO_ZIP));
    addAssetsBox.addComponent(new UploadAssetsBox("Put the path to the Freeplay DJ .zip Data Here", FileUtil.FILE_EXTENSION_INFO_ZIP));
  }

  override public function showDialog(modal:Bool = true):Void
  {
    super.showDialog(modal);

    addAssetsBox.disabled = (!params.generatePlayerData || params.importedPlayerData != null);
  }

  override public function isNextStepAvailable():Bool
  {
    params.freeplayFile = null;
    params.charSelectFile = null;

    // we skippin if we aint even doin these
    if (addAssetsBox.disabled) return true;

    var uploadBoxes:Array<UploadAssetsBox> = [];
    for (unsafeBox in addAssetsBox.childComponents)
    {
      if (!Std.isOfType(unsafeBox, UploadAssetsBox))
      {
        continue;
      }
      var box:UploadAssetsBox = cast unsafeBox;
      if (box.daField.text == null || box.daField.text.length == 0)
      {
        CharCreatorUtil.error("Add Files", "Please fill out all the required Fields.");
        return false;
      }
      uploadBoxes.push(box);
    }

    // check if the files even exist
    for (thingy in uploadBoxes)
    {
      if (!FileUtil.doesFileExist(thingy.daField.text) && !openfl.Assets.exists(thingy.daField.text))
      {
        CharCreatorUtil.error("Add Files", "Path: " + thingy.daField.text + " doesn't exist. Is the spelling correct?");
        return false;
      }
    }

    // we do a little trollin
    return typeCheck(uploadBoxes);
  }

  public function typeCheck(uploadBoxes:Array<UploadAssetsBox>):Bool
  {
    var allFiles = [];

    for (i in 0...uploadBoxes.length)
    {
      var zipPath = uploadBoxes[i].daField.text;

      // checking if we even have the correct file types in the correct places
      if (Path.extension(zipPath) != "zip")
      {
        CharCreatorUtil.error("Add Files", "The provided Path doesn't end with the supported format, (.zip).");
        return false;
      }

      var zipBytes = CharCreatorUtil.gimmeTheBytes(zipPath);
      if (zipBytes == null)
      {
        CharCreatorUtil.error("Add Files", "Error retrieving Bytes from the given Path.");
        return false;
      }

      var zipFiles = FileUtil.readZIPFromBytes(zipBytes);
      if (zipFiles.length == 0)
      {
        CharCreatorUtil.error("Add Files", "The provided .zip file has no content.");
        return false;
      }

      var hasAnimData:Bool = false;
      var hasSpritemapData:Bool = false;
      var hasImageData:Bool = false;

      for (entry in zipFiles)
      {
        if (entry.fileName.indexOf("/") != -1) entry.fileName = Path.withoutDirectory(entry.fileName);

        if (entry.fileName.endsWith("Animation.json"))
        {
          var fileData = entry.data.toString();
          var animData:AnimAtlas = haxe.Json.parse(CharCreatorUtil.normalizeJSONText(fileData));
          if (animData == null)
          {
            CharCreatorUtil.error("Add Files", "Error parsing the Animation.json File.");
            return false;
          }

          hasAnimData = true;
        }

        if (entry.fileName.startsWith("spritemap") && entry.fileName.endsWith(".json"))
        {
          var fileData = entry.data.toString();
          var spritemapData:AnimateAtlas = haxe.Json.parse(CharCreatorUtil.normalizeJSONText(fileData));
          if (spritemapData == null)
          {
            CharCreatorUtil.error("Add Files", "Error parsing the Spritemap.json File.");
            return false;
          }

          hasSpritemapData = true;
        }

        if (entry.fileName.startsWith("spritemap") && entry.fileName.endsWith(".png"))
        {
          if (BitmapData.fromBytes(entry.data) == null)
          {
            CharCreatorUtil.error("Add Files", "Error parsing the Spritemap.png File.");
            return false;
          }
          hasImageData = true;
        }
      }

      if (hasAnimData && hasSpritemapData && hasImageData) allFiles.push({name: zipPath, bytes: zipBytes});

      if (!(hasAnimData && hasSpritemapData && hasImageData))
      {
        CharCreatorUtil.error("Add Files", "Insufficient amount of Files in the .zip File.");
        return false;
      }
    }

    params.charSelectFile = allFiles[0];
    params.freeplayFile = allFiles[1];

    return true;
  }
}
