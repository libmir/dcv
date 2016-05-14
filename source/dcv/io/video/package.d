module dcv.io.video;


public import dcv.io.video.input, 
    dcv.io.video.output;

unittest {

    /*
     Only a temp solution for a test. More complete and correct form of testing should be provided in future.
     */
    import std.stdio;
    import std.file;
    import std.math : abs;

    import dcv.imgproc.color : yuv2rgb;

    
    immutable ubyte[][] frameColorMap = [
        [255, 255, 255],
        [255, 0, 0],
        [0, 255, 0],
        [0, 0, 255],
        [0, 0, 0],
        [255, 255, 255],
        [85, 170, 255],
        [255, 170, 85],
        [255, 255, 255]
    ];

    // output the dummy image of certain format

    immutable width = 352;
    immutable height = 288;
    immutable filePath = "test.mkv";

    scope(exit) {
        try {
            remove(filePath);
        } finally {}
    }

    Image frameImage = new Image(width, height, ImageFormat.IF_RGB);  // define the frame image
    auto frameSlice = frameImage.sliced;  // slice the image for editing

    OutputStream outputStream = new OutputStream;  // define the output video outputStream.

    OutputDefinition props;

    props.width = width;
    props.height = height;
    props.imageFormat = ImageFormat.IF_RGB;
    props.bitRate = 1_400_000;
    /*
     * Use the h263 because the mpeg repeats the first frame.
     * This looks like a known bug:
     * https://trac.ffmpeg.org/ticket/2324
     */
    props.codecId = CodecID.H263; // 

    outputStream.open(filePath, props);

    if (!outputStream.isOpen) {
        writeln("Cannot open H263 stream");
        return;
    }

    foreach(pixel; frameSlice.pack!1.byElement) {
        pixel[0] = cast(ubyte)0;
        pixel[1] = cast(ubyte)0;
        pixel[2] = cast(ubyte)0;
    }

    foreach(frameColor; frameColorMap) {
        foreach(pixel; frameSlice.pack!1.byElement) {
            pixel[0] = frameColor[0];
            pixel[1] = frameColor[1];
            pixel[2] = frameColor[2];
        }
        outputStream.writeFrame(frameImage);
    }

    outputStream.close();

    // define an input stream, read the video we've just written, and find if its of the same content
    InputStream inputStream = new InputStream;

    inputStream.open(filePath, InputStreamType.FILE);

    if (!inputStream.isOpen) {
        writeln("Cannot open input stream");
        return;
    }

    size_t i = 0;
    while(inputStream.readFrame(frameImage)) {
        frameSlice = yuv2rgb!ubyte(frameImage.sliced); 

        // compare 
        auto frameColor = frameColorMap[i++];
        
        foreach(c; 0..3) {
            auto error = abs(cast(int)frameSlice[height / 2, width / 2, c] - cast(int)frameColor[c]);
            assert(error < 2); // encoding error
        }
    }

    // seek some frames
    auto seekFramesIds = [0, 3, 5, 2]; // last should throw SeekFrameException
    foreach(index; seekFramesIds) {
        try {
            inputStream.seekFrame(index);
        } catch {
            assert(0); // should not throw!
        }

        assert(inputStream.readFrame(frameImage));
        frameSlice = yuv2rgb!ubyte(frameImage.sliced); 

        foreach(c; 0..3) {
            auto error = abs(cast(int)frameSlice[height / 2, width / 2, c] - cast(int)frameColorMap[index][c]);
            assert(error < 2); // encoding error
        }
    }

    try {
        inputStream.seekFrame(ulong.max); // should throw
    } catch (SeekFrameException e) {
        // should be caught here
    } catch {
        assert(0);
    }

    try {
        inputStream.seekTime(0.0); 
    } catch {
        assert(0); // should not throw!
    }

    try {
        inputStream.seekTime(ulong.max); // should throw
    } catch (SeekTimeException e) {
        // should be caught here
    } catch {
        assert(0);
    }

    inputStream.close();
}
