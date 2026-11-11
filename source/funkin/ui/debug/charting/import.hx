package funkin.ui.debug.charting;

#if !macro
// Apply handlers so they can be called as though they were functions in ChartEditorState
using funkin.ui.debug.charting.handlers.audio.ChartEditorAudioHandler;
using funkin.ui.debug.charting.handlers.audio.ChartEditorPlaybackHandler;
using funkin.ui.debug.charting.handlers.chart.ChartEditorCommentHandler;
using funkin.ui.debug.charting.handlers.chart.ChartEditorCursorHandler;
using funkin.ui.debug.charting.handlers.chart.ChartEditorDifficultyHandler;
using funkin.ui.debug.charting.handlers.chart.ChartEditorEventChainHandler;
using funkin.ui.debug.charting.handlers.chart.ChartEditorGridInteractionHandler;
using funkin.ui.debug.charting.handlers.chart.ChartEditorImportExportHandler;
using funkin.ui.debug.charting.handlers.chart.ChartEditorNoteDisplayHandler;
using funkin.ui.debug.charting.handlers.chart.ChartEditorSubBeatHandler;
using funkin.ui.debug.charting.handlers.editor.ChartEditorAutoSaveHandler;
using funkin.ui.debug.charting.handlers.editor.ChartEditorGamepadHandler;
using funkin.ui.debug.charting.handlers.editor.ChartEditorKeybindHandler;
using funkin.ui.debug.charting.handlers.editor.ChartEditorPlaytestHandler;
using funkin.ui.debug.charting.handlers.editor.ChartEditorPreferencesHandler;
using funkin.ui.debug.charting.handlers.editor.ChartEditorShortcutHandler;
using funkin.ui.debug.charting.handlers.editor.ChartEditorThemeHandler;
using funkin.ui.debug.charting.handlers.ui.ChartEditorContextMenuHandler;
using funkin.ui.debug.charting.handlers.ui.ChartEditorDialogHandler;
using funkin.ui.debug.charting.handlers.ui.ChartEditorLayoutHandler;
using funkin.ui.debug.charting.handlers.ui.ChartEditorNotificationHandler;
using funkin.ui.debug.charting.handlers.ui.ChartEditorToolboxHandler;
using funkin.ui.debug.charting.handlers.ui.ChartEditorUIHandler;
import funkin.ui.debug.charting.util.ChartEditorNoteUtil;
import funkin.ui.debug.charting.util.ChartEditorTimeScale;
#end
