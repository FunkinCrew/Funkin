package;

enum LoopState{
    NONE; // The song is not Looping
    REPEAT; // The song is either in a AB Loop or normal repeat mode
    ANODE; // The "A" Node
    ABREPEAT; //The song is on ab repeat.
}