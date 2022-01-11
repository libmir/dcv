/**
Module implements common utilities for video I/O

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/
module dcv.io.video.common;

import std.stdio : writeln;
import std.exception : enforce;

import ffmpeg.libavcodec;
import ffmpeg.libavformat;
import ffmpeg.libavutil;
import ffmpeg.libavutil;
import ffmpeg.libavutil;
import ffmpeg.libswscale;
import ffmpeg.libavdevice;
import ffmpeg.libavfilter;

public import dcv.io.image;

/**
Exception related to streaming operations.
*/
class StreamException : Exception
{
    @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }
}

/**
Exception thrown on failed video stream opening.
*/
class StreamNotOpenException : StreamException
{
    @safe pure nothrow this(string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super("Stream is not opened.", file, line, next);
    }
}

/**
Video codec identifiers.
*/
enum CodecID
{
    NONE = 0, /// No codec.
    RAW = AVCodecID.AV_CODEC_ID_RAWVIDEO, /// Raw video.
    MPEG1VIDEO = AVCodecID.AV_CODEC_ID_MPEG1VIDEO, /// MPEG 1 codec.
    MPEG2VIDEO = AVCodecID.AV_CODEC_ID_MPEG2VIDEO, /// MPEG 2 codec.
    MPEG4 = AVCodecID.AV_CODEC_ID_MPEG4, /// MPEG 4 codec.
    H263 = AVCodecID.AV_CODEC_ID_H263, /// h263 codec.
    H264 = AVCodecID.AV_CODEC_ID_H264 /// h264 codec.
}

package:

string getCodecString(CodecID codec)
{
    switch (codec)
    {
    case CodecID.NONE:
        return "";
    case CodecID.RAW:
        return "rawvideo";
    case CodecID.MPEG1VIDEO:
        return "mpeg1video";
    case CodecID.MPEG2VIDEO:
        return "mpeg2video";
    case CodecID.MPEG4:
        return "mp4";
    case CodecID.H263:
        return "h263";
    case CodecID.H264:
        return "h264";
    default:
        return "";
    }
}

class AVStarter
{
    private static AVStarter _instance = null;
    static AVStarter instance()
    {
        if (AVStarter._instance is null)
            AVStarter._instance = new AVStarter;
        return AVStarter._instance;
    }

    this()
    {
        av_register_all();
        avformat_network_init();
        avcodec_register_all();
        avfilter_register_all();
        avdevice_register_all();
    }
}

immutable IF_MONO_TYPES = [AVPixelFormat.AV_PIX_FMT_GRAY8];

immutable IF_MONO_ALPHA_TYPES = [AVPixelFormat.AV_PIX_FMT_GRAY8A];

immutable IF_YUV_TYPES = [
    AVPixelFormat.AV_PIX_FMT_YUV410P, AVPixelFormat.AV_PIX_FMT_YUV411P,
    AVPixelFormat.AV_PIX_FMT_YUV420P, AVPixelFormat.AV_PIX_FMT_YUV422P,
    AVPixelFormat.AV_PIX_FMT_YUYV422, AVPixelFormat.AV_PIX_FMT_YUV440P, AVPixelFormat.AV_PIX_FMT_YUV444P
];

immutable IF_RGB_TYPES = [
    AVPixelFormat.AV_PIX_FMT_RGB0, AVPixelFormat.AV_PIX_FMT_RGB24, AVPixelFormat.AV_PIX_FMT_RGB4,
    AVPixelFormat.AV_PIX_FMT_RGB8
];

immutable IF_RGB_ALPHA_TYPES = [AVPixelFormat.AV_PIX_FMT_ARGB, AVPixelFormat.AV_PIX_FMT_RGBA];

immutable IF_BGR_TYPES = [
    AVPixelFormat.AV_PIX_FMT_BGR0, AVPixelFormat.AV_PIX_FMT_BGR24, AVPixelFormat.AV_PIX_FMT_BGR4,
    AVPixelFormat.AV_PIX_FMT_BGR8
];

immutable IF_BGR_ALPHA_TYPES = [AVPixelFormat.AV_PIX_FMT_ABGR, AVPixelFormat.AV_PIX_FMT_BGRA];

alias IF_MONO_PREFERED = AVPixelFormat.AV_PIX_FMT_GRAY8;
alias IF_MONO_ALPHA_PREFERED = AVPixelFormat.AV_PIX_FMT_GRAY8A;
alias IF_RGB_PREFERED = AVPixelFormat.AV_PIX_FMT_RGB24;
alias IF_RGB_ALPHA_PREFERED = AVPixelFormat.AV_PIX_FMT_RGBA;
alias IF_BGR_PREFERED = AVPixelFormat.AV_PIX_FMT_BGR24;
alias IF_BGR_ALPHA_PREFERED = AVPixelFormat.AV_PIX_FMT_BGRA;
alias IF_YUV_PREFERED = AVPixelFormat.AV_PIX_FMT_YUV444P;

AVPixelFormat convertDepricatedPixelFormat(AVPixelFormat pix)
{
    AVPixelFormat pixFormat = pix;
    switch (pix)
    {
    case AVPixelFormat.AV_PIX_FMT_YUVJ420P:
        pixFormat = AVPixelFormat.AV_PIX_FMT_YUV420P;
        break;
    case AVPixelFormat.AV_PIX_FMT_YUVJ422P:
        pixFormat = AVPixelFormat.AV_PIX_FMT_YUV422P;
        break;
    case AVPixelFormat.AV_PIX_FMT_YUVJ444P:
        pixFormat = AVPixelFormat.AV_PIX_FMT_YUV444P;
        break;
    case AVPixelFormat.AV_PIX_FMT_YUVJ440P:
        pixFormat = AVPixelFormat.AV_PIX_FMT_YUV440P;
        break;
    default:
        break;
    }
    return pixFormat;
}

ImageFormat AVPixelFormat_to_ImageFormat(AVPixelFormat format)
{
    import std.exception : enforce;
    import std.algorithm.searching : find;

    if (IF_YUV_TYPES.find(format))
    {
        return ImageFormat.IF_YUV;
    }
    else if (IF_RGB_TYPES.find(format))
    {
        return ImageFormat.IF_RGB;
    }
    else if (IF_BGR_TYPES.find(format))
    {
        return ImageFormat.IF_BGR;
    }
    else if (IF_RGB_ALPHA_TYPES.find(format))
    {
        return ImageFormat.IF_RGB_ALPHA;
    }
    else if (IF_BGR_ALPHA_TYPES.find(format))
    {
        return ImageFormat.IF_BGR_ALPHA;
    }
    else if (IF_MONO_TYPES.find(format))
    {
        return ImageFormat.IF_MONO;
    }
    else if (IF_MONO_ALPHA_TYPES.find(format))
    {
        return ImageFormat.IF_MONO_ALPHA;
    }
    else
    {
        enforce(0, "Format type is not supported");
    }
    return ImageFormat.IF_UNASSIGNED;
}

AVPixelFormat ImageFormat_to_AVPixelFormat(ImageFormat format)
{
    switch (format)
    {
    case ImageFormat.IF_MONO:
        return IF_MONO_PREFERED;
    case ImageFormat.IF_MONO_ALPHA:
        return IF_MONO_ALPHA_PREFERED;
    case ImageFormat.IF_BGR:
        return IF_BGR_PREFERED;
    case ImageFormat.IF_BGR_ALPHA:
        return IF_BGR_ALPHA_PREFERED;
    case ImageFormat.IF_RGB:
        return IF_RGB_PREFERED;
    case ImageFormat.IF_RGB_ALPHA:
        return IF_RGB_ALPHA_PREFERED;
    case ImageFormat.IF_YUV:
        return IF_YUV_PREFERED;
    default:
        assert(0);
    }
}

void adoptFormat(AVPixelFormat format, AVFrame* frame, ubyte[] data)
{

    import std.exception : enforce;
    import std.algorithm.searching : find;

    if (IF_YUV_TYPES.find(format))
    {
        adoptYUV(format, frame, data);
    }
    else if (IF_RGB_TYPES.find(format))
    {
        throw new Exception("Not implemented");
    }
    else if (IF_BGR_TYPES.find(format))
    {
        throw new Exception("Not implemented");
    }
    else if (IF_RGB_ALPHA_TYPES.find(format))
    {
        throw new Exception("Not implemented");
    }
    else if (IF_BGR_ALPHA_TYPES.find(format))
    {
        throw new Exception("Not implemented");
    }
    else if (IF_MONO_TYPES.find(format))
    {
        throw new Exception("Not implemented");
    }
    else if (IF_MONO_ALPHA_TYPES.find(format))
    {
        throw new Exception("Not implemented");
    }
    else
    {
        enforce(0, "Format type is not supported");
    }
}

void adoptYUV(AVPixelFormat format, AVFrame* frame, ubyte[] data)
{
    switch (format)
    {
    case AVPixelFormat.AV_PIX_FMT_YUV410P, AVPixelFormat.AV_PIX_FMT_YUV420P,
            AVPixelFormat.AV_PIX_FMT_YUV440P:
            adoptYUVGrouped(frame, data);
        break;
    case AVPixelFormat.AV_PIX_FMT_YUV411P:
        adoptYUV411P(frame, data);
        break;
    case AVPixelFormat.AV_PIX_FMT_YUV422P:
        adoptYUV422P(frame, data);
        break;
    case AVPixelFormat.AV_PIX_FMT_YUYV422:
        adoptYUYV422(frame, data);
        break;
    case AVPixelFormat.AV_PIX_FMT_YUV444P:
        adoptYUV444P(frame, data);
        break;
    default:
        assert(0);
    }
}

void adoptYUVGrouped(AVFrame* frame, ubyte[] data)
{
    auto ysize = frame.linesize[0];
    auto usize = frame.linesize[1];
    auto vsize = frame.linesize[2];

    auto udiv = ysize / usize;
    auto vdiv = ysize / vsize;

    int w = frame.width;
    int h = frame.height;

    if (data.length != w * h * 3)
        data.length = w * h * 3;

    auto ydata = frame.data[0];
    auto udata = frame.data[1];
    auto vdata = frame.data[2];

    foreach (r; 0 .. h)
    {
        foreach (c; 0 .. w)
        {
            auto pixpos = r * w * 3 + c * 3;
            auto ypos = r * w + c;
            auto uvpos = r / 2 * w / 2 + c / 2;
            data[pixpos + 0] = ydata[ypos];
            data[pixpos + 1] = udata[uvpos];
            data[pixpos + 2] = vdata[uvpos];
        }
    }
}

void adoptYUV411P(AVFrame* frame, ubyte[] data)
{

    int w = frame.width;
    int h = frame.height;
    int s = (w * h) / 4;

    auto ydata = frame.data[0];
    auto udata = frame.data[1];
    auto vdata = frame.data[2];

    foreach (i; 0 .. s)
    {
        auto y1 = ydata[i * 4];
        auto y2 = ydata[i * 4 + 1];
        auto y3 = ydata[i * 4 + 2];
        auto y4 = ydata[i * 4 + 3];
        auto u = udata[i];
        auto v = vdata[i];

        data[i * 12 + 0] = y1;
        data[i * 12 + 1] = u;
        data[i * 12 + 2] = v;

        data[i * 12 + 3] = y2;
        data[i * 12 + 4] = u;
        data[i * 12 + 5] = v;

        data[i * 12 + 3] = y3;
        data[i * 12 + 4] = u;
        data[i * 12 + 5] = v;

        data[i * 12 + 3] = y4;
        data[i * 12 + 4] = u;
        data[i * 12 + 5] = v;
    }
}

void adoptYUV422P(AVFrame* frame, ubyte[] data)
{

    int w = frame.width;
    int h = frame.height;
    int s = (w * h) / 2;

    auto ydata = frame.data[0];
    auto udata = frame.data[1];
    auto vdata = frame.data[2];

    foreach (i; 0 .. s)
    {
        auto y1 = ydata[i * 2];
        auto y2 = ydata[i * 2 + 1];
        auto u = udata[i];
        auto v = vdata[i];

        data[i * 6 + 0] = y1;
        data[i * 6 + 1] = u;
        data[i * 6 + 2] = v;

        data[i * 6 + 3] = y2;
        data[i * 6 + 4] = u;
        data[i * 6 + 5] = v;
    }
}

void adoptYUYV422(AVFrame* frame, ubyte[] data)
{

    int w = frame.width;
    int h = frame.height;
    int s = (w * h) / 2;

    auto yuyvdata = frame.data[0];

    size_t dataIter = 0;
    size_t yuyvIter = 0;

    foreach (i; 0 .. s)
    {
        auto y1 = yuyvdata[yuyvIter++];
        auto u = yuyvdata[yuyvIter++];
        auto y2 = yuyvdata[yuyvIter++];
        auto v = yuyvdata[yuyvIter++];

        data[dataIter++] = y1;
        data[dataIter++] = u;
        data[dataIter++] = v;

        data[dataIter++] = y2;
        data[dataIter++] = u;
        data[dataIter++] = v;
    }
}

void adoptYUV444P(AVFrame* frame, ubyte[] data)
{
    foreach (i; 0 .. frame.width * frame.height)
    {
        data[i * 3 + 0] = frame.data[0][i];
        data[i * 3 + 1] = frame.data[1][i];
        data[i * 3 + 2] = frame.data[2][i];
    }
}
