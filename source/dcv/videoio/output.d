/**
Module implements utilities for video output.

Video output streaming is performed using OutputStream utility by following example:

----

Image []frames; // initialized elsewhere 

OutputStream outputStream = new OutputStream;  // define the output video outputStream.

OutputDefinition props;

props.width = width;
props.height = height;
props.imageFormat = ImageFormat.IF_RGB;
props.bitRate = 90_000;
props.codecId = CodecID.H263;

outputStream.open(filePath, props);

if (!outputStream.isOpen) {
    exit(-1);
}

foreach(frame; frames) {
    outputStream.writeFrame(frame);
}

outputStream.close();
----

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/

module dcv.videoio.output;

debug
{
    import std.stdio;
}

import mir.exception;
import std.string;
import dplug.core;
import core.stdc.stdlib : malloc, free;

import ffmpeg.libavcodec;
import ffmpeg.libavformat;
import ffmpeg.libavutil;
import ffmpeg.libswscale;
import ffmpeg.libavdevice;
import ffmpeg.libavfilter;

public import dcv.videoio.common;
public import dcv.imageio.image;

/**
Output stream definition properties.
*/
struct OutputDefinition
{
    size_t width = 0; /// Width of the output video frame.
    size_t height = 0; /// Height of the output video frame.
    size_t bitRate = 400000; /// Bit rate of the output video stream.
    size_t frameRate = 30; /// Frame rate of the output video stream.
    ImageFormat imageFormat = ImageFormat.IF_RGB; /// Image format for video frame.
    CodecID codecId = CodecID.NONE; /// Video codec for output video stream.

    // book-keeping parameters for video writing.
    size_t frames = 0;
    size_t pts = 0;

}

/**
Video stream utility used to output video content to file system.
*/
class OutputStream
{
private:
    AVFormatContext* formatContext;
    AVStream* stream;
    AVFrame* frame;
    SwsContext* swsContext;
    OutputDefinition properties;

public:
    @nogc nothrow:
    /// Default initialization.
    this()
    {
        AVStarter AV_STARTER_INSTANCE = AVStarter.instance();
    }
    /// Destructor of the stream - closes the stream.
    ~this()
    {
        close();
    }

    /// Check if stream is open.
    @property isOpen() const
    {
        return formatContext !is null;
    }

    /**
    Open the video stream.

    Params:
        filepath    = Path to the stream.
        props       = Properties of the video.
    */
    bool open(in string filepath, in OutputDefinition props = OutputDefinition())
    {
        this.properties = props;
        auto cstr = CString(filepath);
        const(char)* path = cstr.storage;
        string formatString;

        // Determinate output format
        AVOutputFormat* outputFormat = null;
        if (cast(int)props.codecId)
        {
            formatString = getCodecString(props.codecId);
            outputFormat = av_guess_format(CString(formatString), null, null);
        }
        else
        {
            outputFormat = av_guess_format(null, path, null);
        }

        if (outputFormat is null)
        {
            debug writeln("Could not find suitable output format");
            return false;
        }

        // Allocate format context
        formatContext = avformat_alloc_context();
        if (formatContext is null)
        {
            debug writeln("Cannot allocate context");
            return false;
        }

        // Open the file
        formatContext.oformat = outputFormat;
        formatContext.filename[0 .. filepath.length] = filepath[];

        // Find right encoder
        auto codecCheck = AVCodecIDToCodecID(outputFormat.video_codec);
        if (codecCheck == CodecID.NONE)
        {
            debug writeln("Codec is unsupported for given video format.");
            return false;
        }

        if (properties.codecId == CodecID.NONE)
        {
            properties.codecId = codecCheck;
        }

        AVCodec* codec = avcodec_find_encoder(outputFormat.video_codec);
        if (!codec)
        {
            codec = avcodec_find_encoder_by_name(CString(formatString));
            if (!codec)
            {
                debug writeln("Cannot find encoder.");
                return false;
            }
        }

        // Add a video stream
        stream = avformat_new_stream(formatContext, null);
        if (stream is null)
        {
            debug writeln("Could not allocate stream");
            return false;
        }

        AVCodecContext* c = avcodec_alloc_context3(codec);
        stream.codec = c;

        c.codec_id = outputFormat.video_codec;
        c.codec_type = AVMediaType.AVMEDIA_TYPE_VIDEO;
        c.bit_rate = cast(int)properties.bitRate;
        c.width = cast(int)properties.width;
        c.height = cast(int)properties.height;
        c.time_base = AVRational(1, cast(int)properties.frameRate);
        c.gop_size = 12;
        c.pix_fmt = codec.pix_fmts[0];
        c.frame_number = 0;
        stream.time_base = c.time_base;

        assert(c.pix_fmt != AVPixelFormat.AV_PIX_FMT_NONE, "Codec pixel format not defined");

        if (c.codec_id == AVCodecID.AV_CODEC_ID_MPEG1VIDEO)
        {
            c.mb_decision = 2;
        }
        else if (c.codec_id == AVCodecID.AV_CODEC_ID_MPEG2VIDEO)
        {
            c.max_b_frames = 2;
        }

        if (formatContext.oformat.flags & AVFMT_GLOBALHEADER)
            c.flags |= CODEC_FLAG_GLOBAL_HEADER;

        if (properties.codecId == CodecID.H264)
            av_opt_set(c.priv_data, "preset", "slow", 0);

        if (avcodec_open2(c, codec, null) < 0)
        {
            debug writeln("could not open codec");
            return false;
        }

        swsContext = sws_getContext(cast(int)width, cast(int)height,
                ImageFormat_to_AVPixelFormat(properties.imageFormat), cast(int)width,
                cast(int)height, c.pix_fmt, SWS_BICUBIC, null, null, null);

        // Allocate output frame
        frame = allocPicture(c.pix_fmt, c.width, c.height);
        if (!frame)
        {
            debug writeln("Could not allocate frame\n");
            return false;
        }

        // open file
        if (avio_open(&formatContext.pb, path, AVIO_FLAG_WRITE) < 0)
        {
            debug writeln("Cannot open file at given path");
            return false;
        }

        // Write stream header, if any
        avformat_write_header(formatContext, null);

        return true;
    }

    /// Close the output stream.
    void close()
    {
        if (formatContext)
        {
            av_write_trailer(formatContext);
            avio_close(formatContext.pb);
            formatContext = null;
        }
        if (stream)
        {
            avcodec_close(stream.codec);
            av_freep(stream);
            stream = null;
        }
        if (frame)
        {
            av_frame_free(&frame);
            frame = null;
        }
        if (swsContext)
        {
            sws_freeContext(swsContext);
            swsContext = null;
        }
    }

    /// Write given image as new frame of the image.
    bool writeFrame(Image image)
    {
        import ffmpeg.libavutil.mathematics;

        try enforce!"Image format does not match the output configuration."(image.format == properties.imageFormat);
        catch(Exception e) assert(false, e.msg);

        try enforce!"Image height does not match the output configuration."(image.height == properties.height);
        catch(Exception e) assert(false, e.msg);

        try enforce!"Image width does not match the output configuration."(image.width == properties.width);
        catch(Exception e) assert(false, e.msg);

        AVPacket packet;
        av_init_packet(&packet);
        packet.data = null;
        packet.size = 0;

        scope (exit)
        {
            av_packet_unref(&packet);
            av_free_packet(&packet);
        }

        ubyte*[] data;
        int[] linesize;

        extractDataFromImage(image, data, linesize);

        scope(exit){
            if(data.length > 1){
                foreach (dt; data){
                    free(cast(void*)dt);
                }
            }
            freeSlice(data);
            freeSlice(linesize);
        }

        sws_scale(swsContext, data.ptr, linesize.ptr, 0, cast(int)height, frame.data.ptr, frame.linesize.ptr);

        int gotPacket = 0;

        if (formatContext.oformat.flags & AVFMT_RAWPICTURE)
        {

            packet.flags |= AV_PKT_FLAG_KEY;
            packet.stream_index = stream.index;
            packet.data = cast(ubyte*)frame;
            packet.size = frame.sizeof;

            gotPacket = 1;

        }
        else
        {
            while (true)
            {
                int outSize = avcodec_encode_video2(stream.codec, &packet, frame, &gotPacket);
                frame.pts++;
                if (gotPacket)
                {
                    break;
                }
            }
        }
        if (!gotPacket)
            return false;

        if (packet.pts != AV_NOPTS_VALUE)
            packet.pts = av_rescale_q(packet.pts, stream.codec.time_base, stream.time_base);

        if (packet.dts != AV_NOPTS_VALUE)
            packet.dts = av_rescale_q(packet.dts, stream.codec.time_base, stream.time_base);

        if (stream.codec.coded_frame.key_frame)
            packet.flags |= AV_PKT_FLAG_KEY;

        auto ret = av_interleaved_write_frame(formatContext, &packet);

        if (ret != 0)
        {
            debug writeln("Error writing frame");
            return false;
        }
        else
        {
            return true;
        }
    }

    @property @nogc nothrow const
    {
        /// Width of the frame image.
        auto width()
        {
            return properties.width;
        }
        /// Height of the frame image.
        auto height()
        {
            return properties.height;
        }
        /// Current frame count of the output stream.
        auto frameCount()
        {
            return properties.frames;
        }
        /// Frame rate of the stream.
        auto frameRate()
        {
            return properties.frameRate;
        }
        /// Codec of the stream.
        auto codec()
        {
            return properties.codecId;
        }
    }

private:

    AVFrame* allocPicture(AVPixelFormat pix_fmt, int width, int height)
    {
        AVFrame* picture;
        ubyte[] picture_buf;
        int size;

        picture = av_frame_alloc();
        if (!picture)
        {
            debug writeln("Cannot allocate memory for the frame");
            return null;
        }

        size = avpicture_get_size(pix_fmt, width, height);
        picture_buf = mallocSlice!ubyte(size);
        avpicture_fill(cast(AVPicture*)picture, picture_buf.ptr, pix_fmt, width, height);

        picture.format = pix_fmt;
        picture.width = width;
        picture.height = height;
        picture.pts = 0;

        freeSlice(picture_buf);
        return picture;
    }

    @property AVPixelFormat pixelFormat() const
    {
        return convertDepricatedPixelFormat(stream.codec.pix_fmt);
    }
}

private:

@nogc nothrow:

CodecID AVCodecIDToCodecID(AVCodecID avcodecId)
{
    CodecID c;

    switch (avcodecId)
    {
    case AVCodecID.AV_CODEC_ID_RAWVIDEO, AVCodecID.AV_CODEC_ID_MPEG1VIDEO, AVCodecID.AV_CODEC_ID_MPEG2VIDEO,
            AVCodecID.AV_CODEC_ID_MPEG4, AVCodecID.AV_CODEC_ID_H263, AVCodecID.AV_CODEC_ID_H264:
            c = cast(CodecID)(cast(int)avcodecId);
        break;
    default:
        c = CodecID.NONE;
    }
    return c;
}

void extractDataFromImage(Image image, ref ubyte*[] data, ref int[] linesize)
{
    try enforce!"Image bit depth not supported so far."(image.depth == BitDepth.BD_8);
        catch(Exception e) assert(false, e.msg);

    auto pixelCount = image.width * image.height;
    auto imdata = image.data;
    auto w = cast(int)image.width;
    auto h = cast(int)image.height;

    switch (image.format)
    {
    case ImageFormat.IF_MONO:
        data = mallocSlice!(ubyte*)(1);
        data[0] = image.data.ptr;
        linesize = mallocSlice!(int)(1);
        linesize[0] = w;
        break;
    /+case ImageFormat.IF_MONO_ALPHA:
        data = [image.data.ptr];
        linesize = [w * 2];
        break;+/
    case ImageFormat.IF_RGB, ImageFormat.IF_BGR:
        data = mallocSlice!(ubyte*)(1);
        data[0] = image.data.ptr;
        linesize = mallocSlice!(int)(1);
        linesize[0] = w * 3;
        break;
    /+case ImageFormat.IF_RGB_ALPHA, ImageFormat.IF_BGR_ALPHA:
        data = [image.data.ptr];
        linesize = [w * 4];
        break;+/
    case ImageFormat.IF_YUV:
        data = mallocSlice!(ubyte*)(3);
        data[0] = cast(ubyte*)malloc(w * h * ubyte.sizeof);
        data[1] = cast(ubyte*)malloc(w * h * ubyte.sizeof);
        data[2] = cast(ubyte*)malloc(w * h * ubyte.sizeof);
        
        foreach (i; 0 .. pixelCount)
        {
            data[0][i] = imdata[i * 3 + 0];
            data[0][i] = imdata[i * 3 + 1];
            data[0][i] = imdata[i * 3 + 2];
        }
        linesize = mallocSlice!(int)(3);
        linesize[] = w;
        break;
    default:
        assert(0);
    }
}
