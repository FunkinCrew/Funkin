import flixel.system.FlxAssets;

class ShaderShader extends FlxShader
{
    @:glFragmentSource('
    #pragma header
    uniform float fade;
    
    varying vec4 color;
    varying vec2 textureCoord;
    varying vec2 textureSize;
    uniform sampler2D sampler0;
    
    float luma(vec3 color) {
        return dot(color, vec3(0.299, 0.587, 0.114));
    }
    
    vec3 rgb(float r, float g, float b) {
        return vec3(r/255.0,g/255.0,b/255.0);
    }
    
    void main()
    {
        vec2 uv = textureCoord;
        
        vec3 col = texture2D( sampler0, uv ).rgb;
        float bright=floor(luma(col+0.4)*4.0)/4.0;
        
        vec3 newcol;
        if (bright<0.3) newcol = 	  rgb(54.0,87.0,53.0);
        else if (bright<0.6) newcol = rgb(128.0,128.0,0.0);
        else newcol = 				  rgb(157.0,187.0,97.0);
        gl_FragColor = vec4( newcol*(fade)+col*(1.0-fade), 1.0 ) * color;
    }
    ')

    public function new()
    {
        super();
    }
}