#import <GameController/GameController.h>

bool Apple_KeyboardUtil_isKeyboardConnected()
{
    if ([GCKeyboard class])
    {
        return GCKeyboard.coalescedKeyboard != nil;
    }
    return false;
}
