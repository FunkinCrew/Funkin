import flixel.system.FlxAssets.FlxShader;

class ModchartShader extends FlxShader
{
    public var vertexHeader = "attribute float openfl_Alpha;
		attribute vec4 openfl_ColorMultiplier;
		attribute vec4 openfl_ColorOffset;
		attribute vec4 openfl_Position;
		attribute vec2 openfl_TextureCoord;
		varying float openfl_Alphav;
		varying vec4 openfl_ColorMultiplierv;
		varying vec4 openfl_ColorOffsetv;
		varying vec2 openfl_TextureCoordv;
		uniform mat4 openfl_Matrix;
		uniform bool openfl_HasColorTransform;
		uniform vec2 openfl_TextureSize;";
    public var vertexBody = "openfl_Alphav = openfl_Alpha;
		openfl_TextureCoordv = openfl_TextureCoord;
		if (openfl_HasColorTransform) {
			openfl_ColorMultiplierv = openfl_ColorMultiplier;
			openfl_ColorOffsetv = openfl_ColorOffset / 255.0;
		}
		gl_Position = openfl_Matrix * openfl_Position;";
	public var vertexSource = "#pragma header
		void main(void) {
			#pragma body
		}";
	public var fragmentHeader = "varying float openfl_Alphav;
		varying vec4 openfl_ColorMultiplierv;
		varying vec4 openfl_ColorOffsetv;
		varying vec2 openfl_TextureCoordv;
		uniform bool openfl_HasColorTransform;
		uniform sampler2D openfl_Texture;
		uniform vec2 openfl_TextureSize;";
	public var fragmentBody = "vec4 color = texture2D (openfl_Texture, openfl_TextureCoordv);
		if (color.a == 0.0) {
			gl_FragColor = vec4 (0.0, 0.0, 0.0, 0.0);
		} else if (openfl_HasColorTransform) {
			color = vec4 (color.rgb / color.a, color.a);
			mat4 colorMultiplier = mat4 (0);
			colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
			colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
			colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
			colorMultiplier[3][3] = 1.0; // openfl_ColorMultiplierv.w;
			color = clamp (openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);
			if (color.a > 0.0) {
				gl_FragColor = vec4 (color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
			} else {
				gl_FragColor = vec4 (0.0, 0.0, 0.0, 0.0);
			}
		} else {
			gl_FragColor = color * openfl_Alphav;
		}";

    public function new(frag:String,?vert:String = "")
    {
        if (vert != "")
            glVertexSource = vert;
        glFragmentSource = frag;

        if (glVertexSource != null)
        {
            glVertexSource = StringTools.replace(glVertexSource, "#pragma header", vertexHeader);
			glVertexSource = StringTools.replace(glVertexSource, "#pragma body", vertexBody);
        }

        if (glVertexSource != null)
        {
			glFragmentSource = StringTools.replace(glFragmentSource, "#pragma header", fragmentHeader);
			glFragmentSource = StringTools.replace(glFragmentSource, "#pragma body", fragmentBody);
        }
        super();
    }
}