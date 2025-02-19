package funkin.ui.debug.char.components.dialogs.freeplay;

import funkin.data.freeplay.style.FreeplayStyleRegistry;
import funkin.data.freeplay.player.PlayerRegistry;
import haxe.ui.components.OptionBox;
import haxe.ui.util.Color;
import funkin.ui.freeplay.FreeplayScore;
import funkin.util.FileUtil;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

@:access(funkin.ui.debug.char.pages.CharCreatorFreeplayPage)
@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/char-creator/dialogs/freeplay/style-dialog.xml"))
class FreeplayStyleDialog extends DefaultPageDialog
{
  var styleID:String;

  override public function new(daPage:CharCreatorFreeplayPage)
  {
    super(daPage);

    var entries = FreeplayStyleRegistry.instance.listEntryIds();
    var daPlayuh = PlayerRegistry.instance.fetchEntry(daPage.data.importedPlayerData);

    for (i in 0...entries.length)
    {
      var daBox = new OptionBox();
      daBox.text = entries[i];
      daBox.selected = (daPlayuh?.getFreeplayStyleID() != null ? daPlayuh.getFreeplayStyleID() == entries[i] : i == 0);
      if (daBox.selected) styleID = entries[i];
      daBox.onChange = _ -> {
        styleID = entries[i];
      }
      daBox.componentGroup = "freeplayStylePreset";
      freeplayStylePresets.addComponent(daBox);
    }

    optionMakeNew.onChange = optionUsePreset.onChange = function(_) {
      freeplayStyleNew.disabled = optionUsePreset.selected;
      freeplayStylePresets.disabled = optionMakeNew.selected;
    }

    optionUsePreset.selected = (daPlayuh != null);
    optionMakeNew.selected = (daPlayuh == null);

    buttonBGAsset.onClick = _ -> buttonCallbackForField(fieldBGAsset);
    buttonArrow.onClick = _ -> buttonCallbackForField(fieldArrow);
    buttonNumbers.onClick = _ -> buttonCallbackForField(fieldNumbers);
    buttonCapsule.onClick = _ -> buttonCallbackForField(fieldCapsule);

    var reloadNums = function(num:ScoreNum) {
      var numToString = [];
      @:privateAccess
      numToString = num.numToString;

      for (i in 0...10)
        num.animation.addByPrefix(numToString[i], '${numToString[i]} DIGITAL', 24, false);

      num.animation.play(numToString[num.digit], true);

      num.setGraphicSize(Std.int(num.width * 0.4));
      num.updateHitbox();
    }

    buttonApplyStyle.onClick = function(_) {
      if (optionUsePreset.selected)
      {
        var daStyle = FreeplayStyleRegistry.instance.fetchEntry(styleID);

        daPage.bgDad.loadGraphic(daStyle?.getBgAssetGraphic() != null ? daStyle.getBgAssetGraphic() : Paths.image('freeplay/freeplayBGdad'));

        daPage.arrowLeft.frames = daPage.arrowRight.frames = Paths.getSparrowAtlas(daStyle?.getSelectorAssetKey() ?? 'freeplay/freeplaySelector');
        daPage.arrowLeft.animation.addByPrefix('shine', 'arrow pointer loop', 24);
        daPage.arrowRight.animation.addByPrefix('shine', 'arrow pointer loop', 24);
        daPage.arrowLeft.animation.play('shine');
        daPage.arrowRight.animation.play('shine');

        daPage.randomCapsule.applyStyle(daStyle);

        daPage.scoreNumbers.forEach(function(num:ScoreNum) {
          num.frames = Paths.getSparrowAtlas(daStyle?.getNumbersAssetKey() ?? "digital_numbers");
          reloadNums(num);
        });

        daPage.useStyle = styleID;
      }
      else if (optionMakeNew.selected)
      {
        var dadBitmap = BitmapData.fromBytes(CharCreatorUtil.gimmeTheBytes(fieldBGAsset.text?.length > 0 ? fieldBGAsset.text : Paths.image('freeplay/freeplayBGdad')));
        var arrowBitmap = BitmapData.fromBytes(CharCreatorUtil.gimmeTheBytes(fieldArrow.text?.length > 0 ? fieldArrow.text : Paths.image('freeplay/freeplaySelector')));
        var numbersBitmap = BitmapData.fromBytes(CharCreatorUtil.gimmeTheBytes(fieldNumbers.text?.length > 0 ? fieldNumbers.text : Paths.image('digital_numbers')));
        var capsuleBitmap = BitmapData.fromBytes(CharCreatorUtil.gimmeTheBytes(fieldCapsule.text?.length > 0 ? fieldCapsule.text : Paths.image('freeplay/freeplayCapsule/capsule/freeplayCapsule')));

        var arrowXML = CharCreatorUtil.gimmeTheBytes(fieldArrow.text.replace(".png", ".xml"));
        var numbersXML = CharCreatorUtil.gimmeTheBytes(fieldNumbers.text.replace(".png", ".xml"));
        var capsuleXML = CharCreatorUtil.gimmeTheBytes(fieldCapsule.text.replace(".png", ".xml"));

        daPage.bgDad.loadGraphic(dadBitmap);

        daPage.arrowLeft.frames = daPage.arrowRight.frames = FlxAtlasFrames.fromSparrow(arrowBitmap,
          arrowXML?.toString() ?? Paths.file("images/freeplay/freeplaySelector.xml"));

        daPage.arrowLeft.animation.addByPrefix('shine', 'arrow pointer loop', 24);
        daPage.arrowRight.animation.addByPrefix('shine', 'arrow pointer loop', 24);
        daPage.arrowLeft.animation.play('shine');
        daPage.arrowRight.animation.play('shine');

        daPage.scoreNumbers.forEach(function(num:ScoreNum) {
          num.frames = FlxAtlasFrames.fromSparrow(numbersBitmap, numbersXML?.toString() ?? Paths.file("images/digital_numbers.xml"));
          reloadNums(num);
        });

        // overcomplicating capsule stuff
        daPage.randomCapsule.capsule.frames = FlxAtlasFrames.fromSparrow(capsuleBitmap,
          capsuleXML?.toString() ?? Paths.file("images/freeplay/freeplayCapsule/capsule/freeplayCapsule.xml"));
        daPage.randomCapsule.capsule.animation.addByPrefix('selected', 'mp3 capsule w backing0', 24);
        daPage.randomCapsule.capsule.animation.addByPrefix('unselected', 'mp3 capsule w backing NOT SELECTED', 24);

        var selectColor:Color = selectPicker.selectedItem != null ? cast(selectPicker.selectedItem) : Color.fromString("#00ccff");
        var deselectColor:Color = deselectPicker.selectedItem != null ? cast(deselectPicker.selectedItem) : Color.fromString("#00ccff");

        @:privateAccess
        {
          daPage.randomCapsule.songText.glowColor = FlxColor.fromRGB(selectColor.r, selectColor.g, selectColor.b);
          daPage.randomCapsule.songText.blurredText.color = daPage.randomCapsule.songText.glowColor;

          daPage.randomCapsule.songText.whiteText.textField.filters = [
            new openfl.filters.GlowFilter(daPage.randomCapsule.songText.glowColor, 1, 5, 5, 210, openfl.filters.BitmapFilterQuality.MEDIUM),
          ];
        }

        daPage.useStyle = null;

        daPage.customStyleData.bgAsset = 'freeplay/freeplayBGdad' + (fieldBGAsset.text?.length > 0 ? '_${daPage.data.characterID}' : "");
        daPage.customStyleData.selectorAsset = 'freeplay/freeplaySelector' + (fieldArrow.text?.length > 0 ? '_${daPage.data.characterID}' : "");
        daPage.customStyleData.numbersAsset = 'digital_numbers' + (fieldNumbers.text?.length > 0 ? '_${daPage.data.characterID}' : "");
        daPage.customStyleData.capsuleAsset = 'freeplay/freeplayCapsule/capsule/freeplayCapsule'
          + (fieldCapsule.text?.length > 0 ? '_${daPage.data.characterID}' : "");
        daPage.customStyleData.capsuleTextColors = [deselectColor.toHex(), selectColor.toHex()];
        daPage.customStyleData.startDelay = delayStepper.pos;

        daPage.styleFiles = [];
        if (daPage.customStyleData.bgAsset != 'freeplay/freeplayBGdad')
        {
          daPage.styleFiles.push(
            {
              name: '${daPage.customStyleData.bgAsset}.png',
              bytes: dadBitmap.image.encode(PNG)
            });
        }
        if (daPage.customStyleData.selectorAsset != 'freeplay/freeplaySelector')
        {
          daPage.styleFiles.push({name: '${daPage.customStyleData.selectorAsset}.png', bytes: numbersBitmap.image.encode(PNG)});
          daPage.styleFiles.push({name: '${daPage.customStyleData.selectorAsset}.xml', bytes: numbersXML});
        }
        if (daPage.customStyleData.selectorAsset != 'digital_numbers')
        {
          daPage.styleFiles.push({name: '${daPage.customStyleData.selectorAsset}.png', bytes: arrowBitmap.image.encode(PNG)});
          daPage.styleFiles.push({name: '${daPage.customStyleData.selectorAsset}.xml', bytes: arrowXML});
        }
        if (daPage.customStyleData.capsuleAsset != 'freeplay/freeplayCapsule/capsule/freeplayCapsule')
        {
          daPage.styleFiles.push({name: '${daPage.customStyleData.capsuleAsset}.png', bytes: capsuleBitmap.image.encode(PNG)});
          daPage.styleFiles.push({name: '${daPage.customStyleData.capsuleAsset}.xml', bytes: capsuleXML});
        }
      }
    }
  }

  function buttonCallbackForField(field:haxe.ui.components.TextField)
  {
    FileUtil.browseForBinaryFile("Load Image", [FileUtil.FILE_EXTENSION_INFO_PNG], function(_) {
      if (_?.fullPath != null) field.text = _.fullPath;
    });
  }
}
