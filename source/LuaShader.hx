/*import flixel.system.FlxAssets.FlxShader;

class LuaShader extends FlxShader
{
    // SHADER SHIT FOR LUA CODE

    public function new(frag,vert)
    {   
        glFragmentSource = '
        #pragma header
        varying float openfl_Alphav;
        varying vec4 openfl_ColorMultiplierv;
        varying vec4 openfl_ColorOffsetv;
        varying vec2 openfl_TextureCoordv;

        uniform bool openfl_HasColorTransform;
        uniform vec2 openfl_TextureSize;
        uniform sampler2D bitmap;

        uniform bool hasTransform;
        uniform bool hasColorTransform;

        uniform vec3      iResolution;           // viewport resolution (in pixels)
        uniform float     iTime;                 // shader playback time (in seconds)
        uniform float     iTimeDelta;            // render time (in seconds)
        uniform int       iFrame;                // shader playback frame
        uniform float     iChannelTime[4];       // channel playback time (in seconds)
        uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
        uniform vec4      iMouse;                // mouse pixel coords. xy: current, zw: click
        uniform samplerXX iChannel0..3;          // input channel. XX = 2D/Cube
        uniform vec4      iDate;                 // (year, month, day, time in seconds)
        uniform float     iSampleRate;           // sound sample rate (i.e., 44100)

        vec4 flixel_texture2D(sampler2D bitmap, vec2 coord)
                {
                        vec4 color = texture2D(bitmap, coord);
                        if (!hasTransform)
                        {
                                return color;
                        }

                        if (color.a == 0.0)
                        {
                                return vec4(0.0, 0.0, 0.0, 0.0);
                        }

                        if (!hasColorTransform)
                        {
                                return color * openfl_Alphav;
                        }

                        color = vec4(color.rgb / color.a, color.a);

                        mat4 colorMultiplier = mat4(0);
                        colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
                        colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
                        colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
                        colorMultiplier[3][3] = openfl_ColorMultiplierv.w;

                        color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);

                        if (color.a > 0.0)
                        {
                        return vec4(0.0, 0.0, 0.0, 0.0);
                }

        ' + frag;
        
        iResolution
        super();
    }
}*/