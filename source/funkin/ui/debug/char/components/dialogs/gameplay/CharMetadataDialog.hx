package funkin.ui.debug.char.components.dialogs.gameplay;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/char-creator/dialogs/gameplay/metadata-dialog.xml"))
class CharMetadataDialog extends DefaultPageDialog
{
  override public function new(daPage:CharCreatorGameplayPage, char:CharCreatorCharacter)
  {
    super(daPage);

    charOffsetsX.pos = char.globalOffsets[0];
    charOffsetsY.pos = char.globalOffsets[1];
    charCamOffsetsX.pos = char.characterCameraOffsets[0];
    charCamOffsetsY.pos = char.characterCameraOffsets[1];
    charScale.pos = char.characterScale;
    charHoldTimer.pos = char.holdTimer;
    charFlipX.selected = char.characterFlipX;
    charIsPixel.selected = char.isPixel;
    charHasDeathData.selected = (char.deathData != null);
    charDeathBox.disabled = !charHasDeathData.selected;
    charName.text = char.characterName;

    charDeathCamOffsetX.pos = char.deathData?.cameraOffsets[0] ?? 0;
    charDeathCamOffsetY.pos = char.deathData?.cameraOffsets[1] ?? 0;
    charDeathCamZoom.pos = char.deathData?.cameraZoom ?? 1;
    charDeathTransDelay.pos = char.deathData?.preTransitionDelay ?? 0;

    // callbaccd
    charName.onChange = function(_) char.characterName = charName.text;

    charOffsetsX.onChange = charOffsetsY.onChange = function(_) {
      char.globalOffsets = [charOffsetsX.pos, charOffsetsY.pos];
      daPage.updateCharPerStageData(char.characterType);
    }

    charCamOffsetsX.onChange = charCamOffsetsY.onChange = function(_) char.characterCameraOffsets = [charCamOffsetsX.pos, charCamOffsetsY.pos];

    charScale.onChange = function(_) {
      char.characterScale = charScale.pos;
      daPage.updateCharPerStageData(char.characterType);
    }

    charHoldTimer.onChange = function(_) char.holdTimer = charHoldTimer.pos;

    charFlipX.onChange = function(_) {
      char.characterFlipX = charFlipX.selected;
      daPage.updateCharPerStageData(char.characterType);
    }

    charIsPixel.onChange = function(_) {
      char.isPixel = charIsPixel.selected;

      char.antialiasing = !char.isPixel;
      char.pixelPerfectRender = char.isPixel;
      char.pixelPerfectPosition = char.isPixel;
    }

    // death
    charHasDeathData.onChange = function(_) {
      char.deathData = charHasDeathData.selected ?
        {
          cameraOffsets: [charDeathCamOffsetX.pos, charDeathCamOffsetY.pos],
          cameraZoom: charDeathCamZoom.pos,
          preTransitionDelay: charDeathTransDelay.pos
        } : null;

      charDeathBox.disabled = !charHasDeathData.selected;
    }

    charDeathCamOffsetX.onChange = charDeathCamOffsetY.onChange = function(_) {
      if (char.deathData != null) char.deathData.cameraOffsets = [charDeathCamOffsetX.pos, charDeathCamOffsetY.pos];
    }

    charDeathCamZoom.onChange = function(_) {
      if (char.deathData != null) char.deathData.cameraZoom = charDeathCamZoom.pos;
    }

    charDeathTransDelay.onChange = function(_) {
      if (char.deathData != null) char.deathData.preTransitionDelay = charDeathTransDelay.pos;
    }
  }
}
