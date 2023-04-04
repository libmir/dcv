/**
Module implements utilities for video input.

Input video streaming is performed with InputStream utility by following example:
----
InputStream stream = new InputStream;

stream.open(pathToVideoFile, InputStreamType.FILE);

if (!stream.isOpen) {
    exit(-1);
}

Image frame;

while(stream.readFrame(frame)) {
    // do something with frame...
}
----

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/

module dcv.videoio.input;

import mir.exception;
import core.stdc.stdio : printf;
import dplug.core;

debug
{
    import std.stdio;
}

import ffmpeg.libavcodec;
import ffmpeg.libavformat;
import ffmpeg.libavutil;
import ffmpeg.libswscale;
import ffmpeg.libavdevice;
import ffmpeg.libavfilter;

public import dcv.videoio.common;
public import dcv.imageio.image;

/**
Input streaming type - file or webcam (live)
*/
enum InputStreamType
{
    INVALID, /// Invalid stream, as non-assigned.
    FILE, /// File video stream.
    LIVE /// Live video stream.
}

/**
Exception thrown when seeking a frame fails.
*/
class SeekFrameException : Exception
{
    mixin MirThrowableImpl;
    // "Internal error occurred while seeking a video frame."
}

/**
Exception thrown when seeking a time fails.
*/
class SeekTimeException : Exception
{
    mixin MirThrowableImpl;
    // super("Internal error occurred while seeking time: " ~ time.to!string, file, line, next);
}

/**
Video streaming utility.
*/
class InputStream
{
private:
    AVFormatContext* formatContext = null;
    AVStream* stream = null;
    InputStreamType type = InputStreamType.INVALID;
    AVDictionary* options = null;
public:
    @nogc nothrow:
    this()
    {
        AVStarter AV_STARTER_INSTANCE = AVStarter.instance();
    }

    ~this()
    {
        close();
    }

    @property const
    {
        private auto checkStream()
        {
            if (stream is null){
                try enforce!"Stream is not opened."(false);
                catch(Exception e) assert(false, e.msg);
            }
        }

        /// Check if stream is open.
        auto isOpen()
        {
            return formatContext !is null;
        }
        /// Check if this stream is the file stream.
        auto isFileStream()
        {
            return (type == InputStreamType.FILE);
        }
        /// Check if this stream is the live stream.
        auto isLiveStream()
        {
            return (type == InputStreamType.LIVE);
        }

        /// Get width of the video frame.
        auto width()
        {
            checkStream();
            return stream.codecpar.width;
        }
        /// Get height of the video frame.
        auto height()
        {
            checkStream();
            return stream.codecpar.height;
        }

        /// Get size of frame in bytes.
        auto frameSize()
        {
            return avpicture_get_size(pixelFormat, cast(int)width, cast(int)height);
        }

        /// Get number of frames in video.
        auto frameCount()
        {
            checkStream();
            long fc = stream.nb_frames;
            if (fc <= 0)
            {
                fc = stream.nb_index_entries;
            }
            return fc;
        }

        /// Get the index of the stream - most commonly is 0, where audio stream is 1.
        auto streamIndex()
        {
            checkStream();
            return stream.index;
        }
        /// Get frame rate of the stream.
        auto frameRate()
        {
            checkStream();
            double fps = stream.r_frame_rate.av_q2d;
            if (fps < float.epsilon)
            {
                fps = stream.avg_frame_rate.av_q2d;
            }
            if (fps < float.epsilon)
            {
                fps = 1. / stream.codec.time_base.av_q2d;
            }

            return fps;
        }

        auto duration()
        {
            import std.algorithm.comparison : max;

            checkStream();
            return stream.duration >= 0 ? stream.duration : 0;
        }
    }

    void dumpFormat() const
    {
        if (!isOpen){
            try enforce!"Stream is not opened."(false);
            catch(Exception e) assert(false, e.msg);
        }
        av_dump_format(cast(AVFormatContext*)formatContext, 0, "", 0);
    }

    /**
    Open the video stream.
    
    params:
    path = Path to the stream. 
    type = Stream type. 

    return:
    Stream opening status - true if succeeds, false otherwise.
    */
    bool open(in string path, InputStreamType type = InputStreamType.FILE)
    {
        try enforce!"Input stream type cannot be defined as invalid."(type != InputStreamType.INVALID);
        catch(Exception e){
            assert(false, e.msg);
        } 
        
        this.type = type;

        AVInputFormat* fmt = null;

        if (isLiveStream)
        {
            version (Windows)
            {
                fmt = av_find_input_format("dshow");
                if (fmt is null)
                {
                    fmt = av_find_input_format("vfwcap");
                }
            }
            else version (linux)
            {
                fmt = av_find_input_format("v4l2");
            }
            else version (OSX)
            {
                fmt = av_find_input_format("avfoundation");
            }
            else
            {
                static assert(0, "Not supported platform");
            }
            if (fmt is null)
            {
                try enforce!"Cannot find corresponding file live format for the platform"(false);
                catch(Exception e) assert(false, e.msg);
            }
        }

        return openInputStreamImpl(fmt, path);
    }

    /// Close the video stream.
    void close()
    {
        if (formatContext)
        {
            if (stream && stream.codec)
            {
                avcodec_close(stream.codec);
                stream = null;
            }
            avformat_close_input(&formatContext);
            formatContext = null;
        }
    }

    /// Seek the video timeline to given frame index.
    void seekFrame(size_t frame)
    {
        try enforce!"Only input file streams can be seeked."(isFileStream);
        catch(Exception e) assert(false, e.msg);

        if (stream is null){
            try enforce!"Stream is not opened."(false);
            catch(Exception e) assert(false, e.msg);
        }

        if (!(frame < frameCount))
        {
            try enforce!"Internal error occurred while seeking a video frame."(false);
            catch(Exception e) assert(false, e.msg);
        }

        double frameDuration = 1. / frameRate;
        double seekSeconds = frame * frameDuration;
        int seekTarget = cast(int)(seekSeconds * (stream.time_base.den)) / (stream.time_base.num);

        if (av_seek_frame(formatContext, cast(int)streamIndex, seekTarget, AVSEEK_FLAG_ANY) < 0)
        {
            try enforce!"Internal error occurred while seeking a video frame."(false);
            catch(Exception e) assert(false, e.msg);
        }
    }

    /// Seek the video timeline to given time.
    void seekTime(double time)
    {
        try enforce!"Only input file streams can be seeked."(isFileStream);
        catch(Exception e) assert(false, e.msg);

        if (stream is null){
            try enforce!"Stream is not opened."(false);
            catch(Exception e) assert(false, e.msg);
        }

        int seekTarget = cast(int)(time * (stream.time_base.den)) / (stream.time_base.num);

        if (av_seek_frame(formatContext, cast(int)streamIndex, seekTarget, AVSEEK_FLAG_ANY) < 0)
        {
            try enforce!"Internal error occurred while seeking time."(false);
            catch(Exception e){
                printf("At time: %f -> ", time);
                assert(false, e.msg);
            } 
        }
    }

    /**
    Read the next framw.

    params:
    image = Image where next video frame will be stored.
    Allocates a new image using mallocNew. This must be freed after use with destroyFree.
    */
    bool readFrame(ref Image image)
    {
        if(image !is null){
            try enforce!"Input instance of Image must be null!"(false);
            catch(Exception e) assert(false, e.msg);
        }

        if (isOpen)
        {
            return readFrameImpl(image);
        }
        else
        {
            try enforce!"Stream is not opened."(false);
            catch(Exception e) assert(false, e.msg);
        }

        return false;
    }

    void setVideoSizeRequest(int width, int height){
        import core.stdc.stdio : sprintf;
        char[64] _str;
        sprintf(_str.ptr, "%dx%d", width, height);
        av_dict_set(&options, "video_size", _str.ptr, 0);
    }

private:

    bool readFrameImpl(ref Image image)
    {
        bool stat = false;

        AVPacket packet;
        av_init_packet(&packet);

        // allocating an AVFrame
        AVFrame* frame = av_frame_alloc();
        if (!frame)
        {   
            try enforce!"Could not allocate frame."(false);
            catch(Exception e) assert(false, e.msg);
        
        }

        scope (exit)
        {
            av_frame_free(&frame);
            av_free_packet(&packet);
        }

        while (av_read_frame(formatContext, &packet) >= 0)
        {
            int ret = 0;
            int gotFrame = 0;
            if (packet.stream_index == streamIndex)
            {
                while (true)
                {
                    ret = avcodec_decode_video2(stream.codec, frame, &gotFrame, &packet);
                    if (ret < 0)
                    {
                        try enforce!"Error decoding video frame."(false);
                        catch(Exception e) assert(false, e.msg);
                    }
                    if (gotFrame)
                        break;
                }
                if (gotFrame)
                {
                    stat = true;

                    image = mallocNew!Image(width, height, AVPixelFormat_to_ImageFormat(pixelFormat), BitDepth.BD_8);

                    adoptFormat(pixelFormat, frame, image.data);
                    break;
                }
            }
        }
        return stat;
    }

    bool openInputStreamImpl(AVInputFormat* inputFormat, in string filepath)
    {
        int streamIndex = -1;

        scope(exit) av_dict_free(&options);
        // open file, and allocate format context
        if (avformat_open_input(&formatContext, CString(filepath), inputFormat, &options) < 0)
        {
            debug writeln("Could not open stream for file: " ~ filepath);
            return false;
        }

        // retrieve stream information 
        if (avformat_find_stream_info(formatContext, null) < 0)
        {
            debug writeln("Could not find stream information");
            return false;
        }

        if (openCodecContext(&streamIndex, formatContext, AVMediaType.AVMEDIA_TYPE_VIDEO) >= 0)
        {
            stream = formatContext.streams[streamIndex];
        }

        if (!stream)
        {
            debug writeln("Could not find video stream.");
            return false;
        }

        return true;
    }

    int openCodecContext(int* stream_idx, AVFormatContext* fmt_ctx, AVMediaType type)
    {
        int ret;

        AVStream* st;
        AVCodecContext* dec_ctx = null;
        AVCodec* dec = null;
        AVDictionary* opts = null;

        ret = av_find_best_stream(fmt_ctx, type, -1, -1, null, 0);
        if (ret < 0)
        {
            debug writeln("Could not find stream in FILE file.");
            return ret;
        }
        else
        {
            *stream_idx = ret;
            st = fmt_ctx.streams[*stream_idx];
            /* find decoder for the stream */
            dec_ctx = st.codec;
            dec = avcodec_find_decoder(dec_ctx.codec_id);

            if (!dec)
            {
                debug writeln("Failed to find codec: ", av_get_media_type_string(type));
                return -1;
            }

            if ((ret = avcodec_open2(dec_ctx, dec, &opts)) < 0)
            {
                debug writeln("Failed to open codec: ", av_get_media_type_string(type));
                return ret;
            }
            if ((ret = avcodec_parameters_to_context(dec_ctx, st.codecpar)) < 0)
            {
                debug writeln("Failed to get codec parameters: ", av_get_media_type_string(type));
                return ret;
            }
        }

        return 0;
    }

    @property AVPixelFormat pixelFormat() const
    {
        if (stream is null){
            try enforce!"Stream is not opened."(false);
            catch(Exception e) assert(false, e.msg);
        }
        return convertDepricatedPixelFormat(stream.codec.pix_fmt);
    }

}
