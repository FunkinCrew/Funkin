package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import haxe.ui.containers.dialogs.Dialog;

/**
 * The dialog that displays general information about the Camera Editor.
 */
@:build(haxe.ui.macros.ComponentMacros.build('assets/exclude/data/ui/camera-editor/dialogs/about.xml'))
class AboutDialog extends Dialog
{
}
#end
