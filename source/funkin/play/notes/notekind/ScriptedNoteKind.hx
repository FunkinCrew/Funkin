package funkin.play.notes.notekind;

/**
 * A script that can be tied to a NoteKind.
 * Create a scripted class that extends NoteKind,
 * then call `super('noteKind')` in the constructor to use this.
 */
@:hscriptClass
class ScriptedNoteKind extends NoteKind implements polymod.hscript.HScriptedClass {}
