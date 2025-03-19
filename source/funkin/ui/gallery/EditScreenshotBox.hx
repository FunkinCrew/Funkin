package funkin.ui.gallery;

import haxe.ui.components.popups.ColorPickerPopup;
import haxe.ui.containers.Box;
import haxe.ui.containers.Grid;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.containers.ScrollView;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.DropDown.DropDownBuilder;
import haxe.ui.components.DropDown.DropDownEvents;
import haxe.ui.components.DropDown.DropDownHandler;
import haxe.ui.components.HorizontalSlider;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.OptionBox;
import haxe.ui.components.SectionHeader;
import haxe.ui.components.VerticalRule;
import haxe.ui.events.UIEvent;
import funkin.util.SortUtil;
import flixel.FlxSprite;
import openfl.text.Font;

@:xml("
  <box>
    <style>
      body, .label, .link {
        font-size: 18px;
        font-family: 'Inconsolata';
        font-bold: true;
      }
      .button, .menu, .menuitem, .menuLabel, .menuitem-checkbox {
        font-size: 12px;
        font-family: 'Inconsolata';
        font-bold: true;
      }
      .menuHeader {
        font-size: 16px;
        font-family: 'Inconsolata';
        font-bold: true;
      }
      .textfield {
        font-size: 10px;
        font-bold: true;
      }
      .compact {
        margin: 0px;
        padding: 0px;
      }
      .compactButton {
        margin: 0px;
        padding-top: 4px;
        padding-right: 0px;
        padding-bottom: 4px;
        padding-left: 0px;
      }
      .disable-validation.invalid-value {
        border: $normal-border-size solid $normal-border-color;
        background-color: $tertiary-background-color;
      }
      .offset-ticks-label {
        color: #FFFFFF;
        font-size: 12px;
        font-weight: bold;
      }
      .absolute {
        clip: false;
      }
    </style>
  </box>
")
@:access(funkin.ui.gallery.EditScreenshotSubState)
class EditScreenshotBox extends Box
{
  var daState:EditScreenshotSubState = null;

  var hboxLEFT:HBox = new HBox();
  var hboxCENTER:HBox = new HBox();
  var hboxRIGHT:HBox = new HBox();

  public var allFonts:Array<String> = [];

  public var selectScale:HorizontalSlider = new HorizontalSlider();
  public var selectAngle:HorizontalSlider = new HorizontalSlider();
  public var selectFlipX:CheckBox = new CheckBox();
  public var selectFlipY:CheckBox = new CheckBox();

  public var drawSize:HorizontalSlider = new HorizontalSlider();
  public var drawColor:ColorPickerPopup = new ColorPickerPopup();

  public var stickerDropdown:DropDown = new DropDown();

  public var textSize:NumberStepper = new NumberStepper();
  public var textFont:DropDown = new DropDown();
  public var textBold:CheckBox = new CheckBox();
  public var textItalic:CheckBox = new CheckBox();
  public var textUnderline:CheckBox = new CheckBox();
  public var textColor:ColorPickerPopup = new ColorPickerPopup();

  override public function new(state:EditScreenshotSubState)
  {
    super();

    daState = state;
    padding = 8;
    styleString = "background-color: $solid-background-color;";
    cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    width = FlxG.width;
    height = 48;
    y = FlxG.height - height;
    screenCenter(X);

    for (font in Font.enumerateFonts(true).concat(Font.enumerateFonts(false)))
    {
      if (font?.fontName == null) continue;
      if (!allFonts.contains(font.fontName)) allFonts.push(font.fontName);
    }
    allFonts.sort(SortUtil.alphabetically);

    generateBottomUI();
    useSelectUI();
  }

  function generateBottomUI()
  {
    hboxLEFT.verticalAlign = hboxCENTER.verticalAlign = hboxRIGHT.verticalAlign = "center";
    hboxLEFT.horizontalAlign = "left";
    hboxCENTER.horizontalAlign = "center";
    hboxRIGHT.horizontalAlign = "right";

    addComponent(hboxLEFT);
    addComponent(hboxCENTER);
    addComponent(hboxRIGHT);

    for (mode in EditScreenshotSubState.ALL_MODES)
    {
      var modeOption:OptionBox = new OptionBox();
      modeOption.text = mode.toUpperKebabCase();
      modeOption.componentGroup = "screenshotEditMode";
      modeOption.selected = (mode == daState.curMode);

      modeOption.pauseEvent(UIEvent.CHANGE);
      modeOption.onChange = function(_) {
        daState.curMode = mode;

        switch (daState.curMode)
        {
          case SELECT:
            useSelectUI();
          case DRAW:
            useDrawUI();
          case STICKERS:
            useStickerUI();
          case TEXT:
            useTextUI();
          default:
            hboxRIGHT.removeAllComponents(false);
        }
      }
      hboxLEFT.addComponent(modeOption);
      modeOption.resumeEvent(UIEvent.CHANGE, true);
    }
  }

  function useSelectUI()
  {
    hboxRIGHT.removeAllComponents(false);

    // labels
    var scaleLabel:Label = new Label();
    var angleLabel:Label = new Label();
    var flipLabel:Label = new Label();

    // rules
    var scaleRule:VerticalRule = new VerticalRule();
    var angleRule:VerticalRule = new VerticalRule();

    // values
    scaleLabel.text = "Scale:";

    selectScale.max = 10;
    selectScale.step = selectScale.min = 0.05;
    selectScale.majorTicks = 1;
    selectScale.minorTicks = 0.25;
    selectScale.pos = 1;

    angleLabel.text = "Angle:";

    selectAngle.max = 360;
    selectAngle.min = selectAngle.pos = 0;
    selectAngle.minorTicks = selectAngle.step = 15;
    selectAngle.majorTicks = 90;

    flipLabel.text = "Flip:";

    selectFlipX.text = "Horizontally";
    selectFlipY.text = "Vertically";

    angleRule.percentHeight = scaleRule.percentHeight = 80;
    scaleLabel.verticalAlign = angleLabel.verticalAlign = flipLabel.verticalAlign = selectFlipX.verticalAlign = selectFlipY.verticalAlign = "center";

    // order
    hboxRIGHT.addComponent(scaleLabel);
    hboxRIGHT.addComponent(selectScale);
    hboxRIGHT.addComponent(scaleRule);
    hboxRIGHT.addComponent(angleLabel);
    hboxRIGHT.addComponent(selectAngle);
    hboxRIGHT.addComponent(angleRule);
    hboxRIGHT.addComponent(flipLabel);
    hboxRIGHT.addComponent(selectFlipX);
    hboxRIGHT.addComponent(selectFlipY);
  }

  function useDrawUI()
  {
    hboxRIGHT.removeAllComponents(false);

    // labels
    var sizeLabel:Label = new Label();
    var colorLabel:Label = new Label();

    // rules
    var sizeRule:VerticalRule = new VerticalRule();

    // values
    sizeLabel.text = "Size:";

    drawSize.max = 100;
    drawSize.min = drawSize.step = 1;
    drawSize.majorTicks = 25;
    drawSize.minorTicks = 5;
    drawSize.pos = daState.drawSprite.radius;

    sizeRule.percentHeight = 80;

    colorLabel.text = "Color:";

    drawColor.selectedItem = haxe.ui.util.Color.fromString(daState.drawSprite.color.toHexString());

    // order
    hboxRIGHT.addComponent(sizeLabel);
    hboxRIGHT.addComponent(drawSize);
    hboxRIGHT.addComponent(sizeRule);
    hboxRIGHT.addComponent(colorLabel);
    hboxRIGHT.addComponent(drawColor);
  }

  function useStickerUI()
  {
    hboxRIGHT.removeAllComponents(false);

    stickerDropdown.type = "stickers";
    stickerDropdown.width = 150;
    stickerDropdown.text = EditScreenshotSubState.selectedSticker;
    DropDownBuilder.HANDLER_MAP.set("stickers", Type.getClassName(StickerDropdown));

    hboxRIGHT.addComponent(stickerDropdown);
  }

  function useTextUI()
  {
    hboxRIGHT.removeAllComponents(false);

    // labels
    var sizeLabel:Label = new Label();
    var fontLabel:Label = new Label();
    var colorLabel:Label = new Label();

    // rules
    var sizeRule:VerticalRule = new VerticalRule();
    var fontRule:VerticalRule = new VerticalRule();
    var colorRule:VerticalRule = new VerticalRule();
    var boldRule:VerticalRule = new VerticalRule();
    var italicRule:VerticalRule = new VerticalRule();

    // values
    sizeLabel.text = "Size:";

    textSize.pos = 16;
    textSize.min = 1;
    textSize.step = 1;

    fontLabel.text = "Font:";

    textFont.width = 150;
    textFont.dataSource.clear();

    for (font in allFonts)
      textFont.dataSource.add({text: font});

    textFont.selectedIndex = allFonts.indexOf(flixel.system.FlxAssets.FONT_DEFAULT);
    textFont.searchable = true;
    textFont.searchPrompt = "Find a Font";

    colorLabel.text = "Color:";
    textColor.selectedItem = haxe.ui.util.Color.fromString("white");

    textBold.text = "Bold";
    textItalic.text = "Italic";
    textUnderline.text = "Underline";

    sizeRule.percentHeight = fontRule.percentHeight = colorRule.percentHeight = boldRule.percentHeight = italicRule.percentHeight = 80;

    // order
    hboxRIGHT.addComponent(sizeLabel);
    hboxRIGHT.addComponent(textSize);
    hboxRIGHT.addComponent(sizeRule);
    hboxRIGHT.addComponent(fontLabel);
    hboxRIGHT.addComponent(textFont);
    hboxRIGHT.addComponent(fontRule);
    hboxRIGHT.addComponent(colorLabel);
    hboxRIGHT.addComponent(textColor);
    hboxRIGHT.addComponent(colorRule);
    hboxRIGHT.addComponent(textBold);
    hboxRIGHT.addComponent(boldRule);
    hboxRIGHT.addComponent(textItalic);
    hboxRIGHT.addComponent(italicRule);
    hboxRIGHT.addComponent(textUnderline);
  }
}

// nabbed from haxe ui examples!

@:access(haxe.ui.core.Component)
class StickerDropdown extends DropDownHandler
{
  var stickerBox:VBox;

  override function get_component()
  {
    if (stickerBox == null)
    {
      stickerBox = new VBox();
      stickerBox.width = 350;
      stickerBox.height = 350;

      var newScroll:ScrollView = new ScrollView();
      newScroll.percentWidth = newScroll.percentHeight = newScroll.percentContentWidth = 100;
      stickerBox.addComponent(newScroll);

      var scrollBox:VBox = new VBox();
      scrollBox.percentWidth = 100;
      newScroll.addComponent(scrollBox);

      // aight we making stickahs now
      for (char => stickers in EditScreenshotSubState.stickerStuff)
      {
        var sect:SectionHeader = new SectionHeader();
        sect.text = char;
        scrollBox.addComponent(sect);

        var buttonBox:Grid = new Grid();
        buttonBox.percentWidth = 100;
        buttonBox.columns = 3;
        scrollBox.addComponent(buttonBox);

        for (stickah in stickers)
        {
          var stickerButton:Button = new Button();
          stickerButton.toggle = true;
          stickerButton.text = stickah;
          stickerButton.componentGroup = "sticker";
          stickerButton.iconPosition = "top";
          stickerButton.icon = EditScreenshotSubState.stickerSprites[stickah].frame;
          stickerButton.width = 96;
          stickerButton.height = 96;
          stickerButton.selected = (EditScreenshotSubState.selectedSticker == stickah);

          stickerButton.onChange = function(_) {
            if (stickerButton.selected) _dropdown.text = stickah;
          }

          buttonBox.addComponent(stickerButton);
        }
      }
    }

    return stickerBox;
  }
}
