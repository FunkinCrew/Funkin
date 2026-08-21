package funkin.options;

import funkin.data.options.OptionSchema;
import funkin.touch.ui.FunkinHitbox.FunkinHitboxControlSchemes;
import funkin.save.Save;

/**
 * Represents the user preference on the current mode for phone haptics.
 *
 * Use `funkin.options.Subtitles.value` to get/set the value.
 */
class MobileControlsScheme extends funkin.options.Option<String>
{
  public function new(id:String)
  {
    super('mobileControlsScheme');
  }

  /**
   * The current preference for this option.
   */
  public static var value(get, set):String;

  static function get_value():String
  {
    return Save?.instance?.options?.controlsScheme ?? "Arrows";
  }

  static function set_value(value:String):String
  {
    var save:Save = Save.instance;
    save.options.controlsScheme = value;
    Save.system.flush();
    return value;
  }

  /**
   * Retrieves the options schema for this option.
   * This determines the data type and parameters for the input field in the options menu.
   * @return The schema.
   */
  override public function getOptionSchema():OptionSchema
  {
    return new OptionSchema(List, {
      values: [
        {
          text: 'Arrows',
          value: FunkinHitboxControlSchemes.Arrows
        },
        {
          text: 'Four Lanes',
          value: FunkinHitboxControlSchemes.FourLanes
        },
        {
          text: '2 Thumb Triangle',
          value: FunkinHitboxControlSchemes.DoubleThumbTriangle
        },
        {
          text: '2 Thumb Square',
          value: FunkinHitboxControlSchemes.DoubleThumbSquare
        },
        {
          text: '2 Thumb DPad',
          value: FunkinHitboxControlSchemes.DoubleThumbDPad
        }
      ],
    });
  }

  /**
   * Retrieves the asset path to the icon this option should use in the options menu.
   * @return The asset path. Override this function to return a custom result.
   */
  override public function getIconAssetPath():String
  {
    return Paths.image('ui/options/interface/icons/strumline-background');
  }

  /**
   * Retrieves the category ID for this option.
   * @return The category to display this option in.
   */
  override public function getTabId():String
  {
    return "gameplay";
  }

  /**
   * Retrieves the human readable title of this option,
   * as displayed on the list item in the options menu.
   * @return The title. Override this function to return a custom result.
   */
  override public function getTitle():String
  {
    return "Controls Schemes";
  }

  /**
   * Retrieves the human readable description of this option,
   * as displayed under the preview when it is selected.
   *
   * @return The description to display under the preview.
   */
  override public function getDescription():String
  {
    return "Placeholder";
  }

  /**
   * Whether or not this option should be shown.
   * Useful for hiding options like mobile-only options on desktop.
   * @return Whether or not this option should be shown.
   */
  override public function isVisible():Bool
  {
    return false;
  }

  // Functions used by the Options menu.

  override public function getValue():String
  {
    return MobileControlsScheme.value;
  }

  override public function setValue(input:String):Void
  {
    MobileControlsScheme.value = input;
  }
}
