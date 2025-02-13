package funkin.play.event;

import polymod.hscript.HScriptedClass;

/**
 * A script that can be tied to a SongEvent.
 * Create a scripted class that extends SongEvent,
 * then call `super('SongEventType')` to use this.
 *
 * - Remember to override `handleEvent(data:SongEventData)` to perform your actions when the event is hit.
 * - Remember to override `getTitle()` to return an event name that will be displayed in the editor.
 * - Remember to override `getEventSchema()` to return a schema for the event data, used to build a form in the chart editor.
 */
@:hscriptClass
class ScriptedSongEvent extends SongEvent implements HScriptedClass {}
