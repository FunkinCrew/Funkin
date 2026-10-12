// Highlight keyframes in flash
// drag .jsfl script in
// will export the layer info of the first(?) element it finds?
// maybe someone can extend this to add more depth / functionality!
// see FramesJSFLParser.hx and CharSelectGF.hx for sample implementation

function splitArrayIntoChunks(array, chunkSize) {
    var result = [];
    for (var i = 0; i < array.length; i += chunkSize) {
        var chunk = array.slice(i, i + chunkSize);
        result.push(chunk);
    }
    return result;
}

var isJson = false;

function addField(name, variable, end)
{
	return (isJson) ? addFJson(name, variable, end) : addF(variable, end);
}
function addFJson(name, variable, end) {
	return "\"" + name + "\": " + variable + ((!end) ? "," : "");
}
function addF(variable, end) {
	return variable + ((end)? "" : " ");
}


fl.outputPanel.clear();

var timeline = fl.getDocumentDOM().getTimeline();
var daSelection = timeline.getSelectedFrames();
var splitArrays = splitArrayIntoChunks(daSelection, 3);
var uri = undefined;


if (fl.version.substring(4).split(",")[0] < 13)
{
	var macFormat = "Folder|TEXT[*.||";
	var winFormat = "Folder|*.||";
	var previewArea = {};
	uri = fl.browseForFileURL("save", "where to save files pick folder...", previewArea, macFormat, winFormat);
}
else
	uri = fl.browseForFileURL("save", "where to save files pick folder..", "Folder(*.)", "*.");


for (var i = 0; i < splitArrays.length; i+=1)
{
    var curLayerInfo = splitArrays[i];
    var curLayerInd = curLayerInfo[0];
    var curLayer = fl.getDocumentDOM().getTimeline().layers[curLayerInd];

    var layerURI = uri;
	var fileName = "";
	var uris = uri.split("/");

	fileName = uris[uris.length - 1];


    FLfile.createFolder(layerURI);


    var fileData = "{\n";
	if (!isJson)
		fileData = "";

    var selectedFrames = curLayer.frames;
    var sliceLength = curLayerInfo[2] - curLayerInfo[1];
    selectedFrames =selectedFrames.slice(curLayerInfo[1],curLayerInfo[2]);

	if (isJson)
		fileData += "\"frames\": [";

    for (var frameInd = curLayerInfo[1]; frameInd < curLayerInfo[2]; frameInd+=1)
    {
		if (isJson)
			fileData += "\n{"
        var curFrame = curLayer.frames[frameInd];
        if (curFrame.isEmpty)
        {
            continue;
        }

        for (var elementInd = 0; elementInd < curFrame.elements.length; elementInd+=1)
        {

            var curElement = curFrame.elements[elementInd];

			fileData += addField("x", curElement.left, false);
			fileData += addField("y", curElement.top, false);
			fileData += addField("alpha", (curElement.colorAlphaPercent == undefined) ? 100 : curElement.colorAlphaPercent, false);
			fileData += addField("scaleX", curElement.scaleX, false);
			fileData += addField("scaleY", curElement.scaleY, true);
			if (frameInd != curLayerInfo[2] - 1)
				fileData += "\n";
        }

		if (isJson)
			fileData += "},";
    }
	if (isJson)
		fileData += "]";

	if (isJson)
		fileData += "\n}";

    FLfile.write(layerURI + "/" + fileName + ".txt", fileData);
}
