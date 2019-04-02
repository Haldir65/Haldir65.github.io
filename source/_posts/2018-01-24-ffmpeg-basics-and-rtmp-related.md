---
title: ffmpeg知识手册
date: 2018-01-24 13:44:33
tags:
---

ffmpeg安装手记
![](https://www.haldir66.ga/static/imgs/water foot cold dark river.jpg)
<!--more-->


## 安装
[how-to-install-ffmpeg-on-windows](http://adaptivesamples.com/how-to-install-ffmpeg-on-windows/)
[下载](https://ffmpeg.zeranoe.com/builds/)

检查下是否安装完成:
> ffmpeg -codecs

## Basic commands
> ffmpeg -i video.mp4 ## 从视频中提取出信息
 ffmpeg -i video.mp4 video.avi ## 格式转换
ffmpeg -i input.mp4 -vn -ab 320 output.mp3 ##提取视频中的音频，转成mp3
ffmpeg -i input.mp4  -t 50 output.avi  ## 提取视频前50s
ffmpeg -i input.mp4 -aspect 16:9 output.mp4 ## 更改长宽比



参考[20-ffmpeg-commands-beginners](https://www.ostechnix.com/20-ffmpeg-commands-beginners/)

需要知道的是，***视频转码是很费性能的***，消耗的时间也比较长。




### 视频基础信息
视频包括：
内容元素
Image
Audio
Metadata(元信息)

编码解码器(Codec)
video: H.263, H.264,H.265
Audio: AAC, HE-AAC

容器文件格式(Container)
MP3 , Mp4 ,FLV, AVI

视频关键字
帧率（Frame rate）
码率 （Bit rate） -- 这个是指文件大小
分辨率 (Bit rate)
图片群组 (Group of Picture， GOP) I帧率 ： 关键帧(完整，直接解码) B/P帧 ：参考帧 P帧依赖于前帧，B帧依赖于前后帧

帧数据 编码压缩之后组成多个GOP，最后封装成视频。

视频直播结构

摄像头 编码 -> 视频流 -> 传输给server -> server负责推流 -> 交给播放器
录制包括Native, webRTC(提供js的api获取视频数据)
直播协议这边，分为HLS和rtmp. html5的video标签使用HLS协议(.m3u8)，
pc端使用flash,native端使用系统播放器使用rtmp协议

### HLS
HLS(HTTP Live Streaming)协议播放视频流在webview中使用比较简单,android和ios的webview都支持
```html
<video control autoplay>
    <source src="http://10.66.99.77:8080/hls/mystream.m38u" type="application/vnd.apple.mpegurl"/>
    <p class="warning">Your browser does not support HTML5 video. </p>
</video>
```

HLS协议的.m3u8文件理论上就是讲推送的视频流切分成多个.ts文件外加一些配置。注意这个.m3u8文件只是一个文本文件，很小的。
所以video标签在请求完上面的m3u8文件之后，就会根据配置信息去拉取真正的.ts文件。ts文件时长太长或者太短都不好，一般推荐是5s。

### RTMP(Real Time Messaging Protocol)
是Macromedia开发的直播协议，现在属于Adobe。rtmp和HLS一样可以用于视频直播，但是RTMP因为是基于flash的，所以无法在ios生态中播放，但是实时性要比HLS好，就是低延时。所以一般使用这种协议来上传视频流，也就是视频流推送到服务器。RTMP是基于tcp长连接的，延时在2s左右，而HLS是基于http的，延时在10-30s左右。
推流端的话，Android一般是用MediaCodec将视频数据编码成rtmp包的格式，RTMP流本质上是FLV格式的音视频
nginx上要配合一个nginx-rtmp-module来做


## 移动端音视频方案选择
一般来说，音视频，摄像头这一块相关的api。Google在这方面的控制力都非常弱，导致各大厂商之间的实现存在各种差异。[吐槽MediaCodec的文章很多](http://ragnraok.github.io/android_video_record.html)
现实中，在Android平台上音视频编码器的选择包括：
用NediaCodec或者FFMpeg+x264/openh264。
MediaRecorder能录，但是不能一帧帧地去处理。
[有人比较了mediaRecoder、ffmpeg和mediaCodec的差别](https://stackoverflow.com/questions/42737378/android-choosing-between-mediarecorder-mediacodec-and-ffmpeg)
简单来讲,MediaCodec有硬件加成，速度快，更加接近底层(但是强烈依赖OEM的实现，不同机型表现不同，bug有不少)
ffmpeg慢一点，但是几乎什么都能干，不同机型上表现一致。但是so文件很大。


## MediaCodec 这个类的使用（ MediaCodec, MediaMuxer, and MediaExtractor）
MediaMuxer是用来把video track和audio track合并起来的
[MediaCodec的api page](https://developer.android.com/reference/android/media/MediaCodec)
MediaCodec可以处理的数据有以下三种类型：压缩数据、原始音频数据、原始视频数据。这三种类型的数据均可以利用ByteBuffers进行处理，但是对于原始视频数据应提供一个Surface以提高编解码器的性能。Surface直接使用native视频数据缓存，而没有映射或复制它们到ByteBuffers，因此，这种方式会更加高效。
MediaCodec采用异步方式处理数据，并且使用了一组输入输出缓存（ByteBuffer）。通过请求一个空的输入缓存（ByteBuffer），向其中填充满数据并将它传递给编解码器处理。编解码器处理完这些数据并将处理结果输出至一个空的输出缓存（ByteBuffer）中。使用完输出缓存的数据之后，将其释放回编解码器：
在使用一个Surface的时候，可以使用ImageReader获取视频某一帧的raw date，也可以使用Image这个class的getInputImage()方法

```
Use MediaCodecList to create a MediaCodec for a specific MediaFormat. When decoding a file or a stream, you can get the desired format from MediaExtractor.getTrackFormat. Inject any specific features that you want to add using MediaFormat.setFeatureEnabled, then call MediaCodecList.findDecoderForFormat to get the name of a codec that can handle that specific media format. Finally, create the codec using createByCodecName(String).
```
就是说MediaCode的创建需要走factory method那一套，首先根据dataSource，使用MediaExtractor去提取音视频track，然后使用MediaCodecList.findDecoderForFormat找到一个可以用的codec的名称。最后，使用createByCodecName去创建出一个MediaCodec.

创建完MediaCodec之后就要去初始化它了，可以使用setCallback去进行异步解码。
这个callback长这样。
```java
 public static abstract class Callback {
        /**
         * Called when an input buffer becomes available.
         *
         * @param codec The MediaCodec object.
         * @param index The index of the available input buffer.
         */
        public abstract void onInputBufferAvailable(@NonNull MediaCodec codec, int index);

        /**
         * Called when an output buffer becomes available.
         *
         * @param codec The MediaCodec object.
         * @param index The index of the available output buffer.
         * @param info Info regarding the available output buffer {@link MediaCodec.BufferInfo}.
         */
        public abstract void onOutputBufferAvailable(
                @NonNull MediaCodec codec, int index, @NonNull BufferInfo info);

        /**
         * Called when the MediaCodec encountered an error
         *
         * @param codec The MediaCodec object.
         * @param e The {@link MediaCodec.CodecException} object describing the error.
         */
        public abstract void onError(@NonNull MediaCodec codec, @NonNull CodecException e);

        /**
         * Called when the output format has changed
         *
         * @param codec The MediaCodec object.
         * @param format The new output format.
         */
        public abstract void onOutputFormatChanged(
                @NonNull MediaCodec codec, @NonNull MediaFormat format);
    }
```
接下来使用方法设置这个codec去使用特定格式的数据格式，并且在这个时候提供一个surface，视频播放就是这里设置的
```java
public void configure (MediaFormat format,
                Surface surface,
                MediaCrypto crypto,
                int flags)
```

调用MediaCodec处理数据的方式:
每一个Codec都包含一组input和output buffers，外部可以使用bufferId（int）来对其进行操控。在同步模式下，可以使用dequeueInputBuffer(long)和dequeueOutputBuffer()分别从code获取一块输入或者输出buffer。
在异步模式下，在MediaCodec.Callback.OnInputBufferAvailable/和MediaCodec.Callback.onOutputBufferAvailable中可以获得buffer。

buffer拿到手之后，自己往里面塞数据(ByteBuffer和jdk里的buffer是一样的，一个需要注意的方法是order(ByteOrder.BIG_ENDIAN)，就是字节数组的字节序问题，一般都是用natural order，这个order方法用的很多)

虽然java是大端的，但是Android在native层都是Little endian的，这话在Bits.java中写了.
```java
 // -- Processor and memory-system properties --

    // Android-changed: Android is always little-endian.
    // private static final ByteOrder byteOrder;
    private static final ByteOrder byteOrder = ByteOrder.LITTLE_ENDIAN;
```
上面说到往buffer塞满数据后，就能调用MediaCodec.queueInputBuffer方法把数据丢给codec，codec相应的会在onOutputBufferAvailable回调或者在dequeueOutputBuffer方法中返回一份只读的buffer。用完之后这部分之后，调用releaseOutputBuffer将这份buffer还给codec。（用完了就要还，不然codec会阻塞住）

MediaCodec一般是这么用的，文档上也建议使用异步的方法
```java
 MediaCodec codec = MediaCodec.createByCodecName(name);
 MediaFormat mOutputFormat; // member variable
 codec.setCallback(new MediaCodec.Callback() {
   @Override
   void onInputBufferAvailable(MediaCodec mc, int inputBufferId) {
     ByteBuffer inputBuffer = codec.getInputBuffer(inputBufferId);
     // fill inputBuffer with valid data
     …
     codec.queueInputBuffer(inputBufferId, …);
   }

   @Override
   void onOutputBufferAvailable(MediaCodec mc, int outputBufferId, …) {
     ByteBuffer outputBuffer = codec.getOutputBuffer(outputBufferId);
     MediaFormat bufferFormat = codec.getOutputFormat(outputBufferId); // option A
     // bufferFormat is equivalent to mOutputFormat
     // outputBuffer is ready to be processed or rendered.
     …
     codec.releaseOutputBuffer(outputBufferId, …);
   }

   @Override
   void onOutputFormatChanged(MediaCodec mc, MediaFormat format) {
     // Subsequent data will conform to new format.
     // Can ignore if using getOutputFormat(outputBufferId)
     mOutputFormat = format; // option B
   }

   @Override
   void onError(…) {
     …
   }
 });
 codec.configure(format, …);
 mOutputFormat = codec.getOutputFormat(); // option B
 codec.start();
 // wait for processing to complete
 codec.stop();
 codec.release();
```

但同时也给出了一份同步的版本
```java
 MediaCodec codec = MediaCodec.createByCodecName(name);
 codec.configure(format, …);
 MediaFormat outputFormat = codec.getOutputFormat(); // option B
 codec.start();
 for (;;) {
   int inputBufferId = codec.dequeueInputBuffer(timeoutUs);
   if (inputBufferId >= 0) {
     ByteBuffer inputBuffer = codec.getInputBuffer(…);
     // fill inputBuffer with valid data
     …
     codec.queueInputBuffer(inputBufferId, …);
   }
   int outputBufferId = codec.dequeueOutputBuffer(…);
   if (outputBufferId >= 0) {
     ByteBuffer outputBuffer = codec.getOutputBuffer(outputBufferId);
     MediaFormat bufferFormat = codec.getOutputFormat(outputBufferId); // option A
     // bufferFormat is identical to outputFormat
     // outputBuffer is ready to be processed or rendered.
     …
     codec.releaseOutputBuffer(outputBufferId, …);
   } else if (outputBufferId == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
     // Subsequent data will conform to new format.
     // Can ignore if using getOutputFormat(outputBufferId)
     outputFormat = codec.getOutputFormat(); // option B
   }
 }
 codec.stop();
 codec.release();
```
如果使用output Surface的话（就是播放器嘛）
此时可以选择是否将Buffer渲染到surface上，你有三个选择：
- Do not render the buffer: Call releaseOutputBuffer(bufferId, false).
- Render the buffer with the default timestamp: Call releaseOutputBuffer(bufferId, true).
- Render the buffer with a specific timestamp: Call releaseOutputBuffer(bufferId, timestamp).

Adaptive Playback 这里也提到了视频流中关键帧的概念
>It is important that the input data after start() or flush() starts at a suitable stream boundary: the first frame must a key frame. A key frame can be decoded completely on its own (for most codecs this means an I-frame), and no frames that are to be displayed after a key frame refer to frames before the key frame.

找到了一个解释如何使用MediaExtractor从mp4文件中提取分离音频和视频的代码
```java
private void exactorMedia() {
    FileOutputStream videoOutputStream = null;
    FileOutputStream audioOutputStream = null;
    try {
        //分离的视频文件
        File videoFile = new File(SDCARD_PATH, "output_video.mp4");
        //分离的音频文件
        File audioFile = new File(SDCARD_PATH, "output_audio");
        videoOutputStream = new FileOutputStream(videoFile);
        audioOutputStream = new FileOutputStream(audioFile);
        //源文件
        mediaExtractor.setDataSource(SDCARD_PATH + "/input.mp4");
        //信道总数
        int trackCount = mediaExtractor.getTrackCount();
        int audioTrackIndex = -1;
        int videoTrackIndex = -1;
        for (int i = 0; i < trackCount; i++) {
            MediaFormat trackFormat = mediaExtractor.getTrackFormat(i);
            String mineType = trackFormat.getString(MediaFormat.KEY_MIME);
            //视频信道
            if (mineType.startsWith("video/")) {
                videoTrackIndex = i;
            }
            //音频信道
            if (mineType.startsWith("audio/")) {
                audioTrackIndex = i;
            }
        }

        ByteBuffer byteBuffer = ByteBuffer.allocate(500 * 1024);
        //切换到视频信道
        mediaExtractor.selectTrack(videoTrackIndex);
        while (true) {
            int readSampleCount = mediaExtractor.readSampleData(byteBuffer, 0);
            if (readSampleCount < 0) {
                break;
            }
            //保存视频信道信息
            byte[] buffer = new byte[readSampleCount];
            byteBuffer.get(buffer);
            videoOutputStream.write(buffer);
            byteBuffer.clear();
            mediaExtractor.advance();
        }
        //切换到音频信道
        mediaExtractor.selectTrack(audioTrackIndex);
        while (true) {
            int readSampleCount = mediaExtractor.readSampleData(byteBuffer, 0);
            if (readSampleCount < 0) {
                break;
            }
            //保存音频信息
            byte[] buffer = new byte[readSampleCount];
            byteBuffer.get(buffer);
            audioOutputStream.write(buffer);
            byteBuffer.clear();
            mediaExtractor.advance();
        }

    } catch (IOException e) {
        e.printStackTrace();
    } finally {
        mediaExtractor.release();
        try {
            videoOutputStream.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}

```
[Android 视频分离和合成(MediaMuxer和MediaExtractor)](https://blog.csdn.net/zhi184816/article/details/52514138)
[关于MediaCodec这个类的使用](https://github.com/PhilLab/Android-MediaCodec-Examples)


这里贴一个NV21和Yuv420之间的转换
```java
public class Yuv420Util {
    /**
     * Nv21:
     * YYYYYYYY
     * YYYYYYYY
     * YYYYYYYY
     * YYYYYYYY
     * VUVU
     * VUVU
     * VUVU
     * VUVU
     * <p>
     * I420:
     * YYYYYYYY
     * YYYYYYYY
     * YYYYYYYY
     * YYYYYYYY
     * UUUU
     * UUUU
     * VVVV
     * VVVV
     *
     * @param data
     * @param dstData
     * @param w
     * @param h
     */
    public static void Nv21ToI420(byte[] data, byte[] dstData, int w, int h) {

        int size = w * h;
        // Y
        System.arraycopy(data, 0, dstData, 0, size);//Y都是一样的
        for (int i = 0; i < size / 4; i++) {
            dstData[size + i] = data[size + i * 2 + 1]; //U
            dstData[size + size / 4 + i] = data[size + i * 2]; //V
        }
    }

// Nv21 to Yuv Semi Planar
    public static void Nv21ToYuv420SP(byte[] data, byte[] dstData, int w, int h) {
        int size = w * h;
        // Y都是一样的
        System.arraycopy(data, 0, dstData, 0, size);

        for (int i = 0; i < size / 4; i++) {
            dstData[size + i * 2] = data[size + i * 2 + 1]; //U
            dstData[size + i * 2 + 1] = data[size + i * 2]; //V
        }
    }

}
```
[c语言的实现YUVtoRBGA和YUVtoARBG](https://github.com/cats-oss/android-gpuimage/blob/master/library/src/main/cpp/yuv-decoder.c) 

## Exoplayer
查看exoplayer的源码，dataSource在拉到数据之后，最终交给MediaCodecRender，后者调用processOutputBuffer，核心代码是这句:
```java
codec.releaseOutputBuffer(bufferIndex, releaseTimeNs);//codec是MediaCodec实例


// If you are done with a buffer, use this call to update its surface timestamp and return it to the codec to render it on the output surface. 说的很清楚了，就是把这块buffer还给codec从而在surface上渲染
public final void releaseOutputBuffer(int index, long renderTimestampNs) {
    //...
}
```

## ijkplayer的原理
ijkplayer可以选择mediaPlayer，exoplayer或者是IjkMediaPlayer。exoplayer是基于MediaCodec的，而IjkMediaPlayer是**一个基于FFPlay的轻量级Android/iOS视频播放器，实现了跨平台的功能，API易于集成；编译配置可裁剪，方便控制安装包大小。**

整体的代码结构是：
tool - 初始化的一些脚本
config - 编译ffmpeg的一些配置文件
extra 用于存放编译ijkplayer所需要的依赖源文件，比如ffmpeg，openssl等
ijkmedia 核心代码
 ---  ijkplayer 播放器数据下载及解码相关
 --- ijksdl 音视频数据渲染相关（理由有一个gles2文件夹，里头装了opengl渲染yuv格式的代码）
ios ios平台上的上层接口封装
andriod 一些jni函数 




Android相关的代码在android/ijkplayer/ijkplayer-java/src/main/java/tv/danmaku/ijk/media/player/IjkMediaPlayer.java这里，比方说这个start方法，java层start最终调用到

```java
private native void _start() throws IllegalStateException;
```
映射到jni这边是ijkplayer/ijkmedia/ijkplayer/android/ijkplayer_jni.c这个文件
```C
static int ijkmp_start_l(IjkMediaPlayer *mp)
{
    assert(mp);

    MP_RET_IF_FAILED(ikjmp_chkst_start_l(mp->mp_state));

    ffp_remove_msg(mp->ffplayer, FFP_REQ_START);
    ffp_remove_msg(mp->ffplayer, FFP_REQ_PAUSE);
    ffp_notify_msg1(mp->ffplayer, FFP_REQ_START);

    return 0;
}

int ijkmp_start(IjkMediaPlayer *mp)
{
    assert(mp);
    MPTRACE("ijkmp_start()\n");
    pthread_mutex_lock(&mp->mutex);
    int retval = ijkmp_start_l(mp);
    pthread_mutex_unlock(&mp->mutex);
    MPTRACE("ijkmp_start()=%d\n", retval);
    return retval;
}
```



c语言这边，首先是创建player
```c
IjkMediaPlayer *ijkmp_android_create(int(*msg_loop)(void*))
{
    IjkMediaPlayer *mp = ijkmp_create(msg_loop);
    if (!mp)
        goto fail;

    mp->ffplayer->vout = SDL_VoutAndroid_CreateForAndroidSurface();
    if (!mp->ffplayer->vout)
        goto fail;

    mp->ffplayer->pipeline = ffpipeline_create_from_android(mp->ffplayer);
    if (!mp->ffplayer->pipeline)
        goto fail;

    ffpipeline_set_vout(mp->ffplayer->pipeline, mp->ffplayer->vout);

    return mp;

fail:
    ijkmp_dec_ref_p(&mp);
    return NULL;
}
```
主要干了三件事，创建了IjkMediaPlayer对象，为这个对象的FFPlayer指定vout(图像渲染对象)和pipeline(音视频解码相关)

IMediaPlayer.prepareAsync方法 -> IjkMediaPlayer_prepareAsync ->
... -> 最终调用到ijkplayer.c中的
```c
int ffp_prepare_async_l(FFPlayer *ffp, const char *file_name)
```

随后调用这个方法
```c
static VideoState *stream_open(FFPlayer *ffp, const char *filename, AVInputFormat *iformat){
        /* start video display */
    if (frame_queue_init(&is->pictq, &is->videoq, ffp->pictq_size, 1) < 0)
        goto fail;
    if (frame_queue_init(&is->subpq, &is->subtitleq, SUBPICTURE_QUEUE_SIZE, 0) < 0)
        goto fail;
    if (frame_queue_init(&is->sampq, &is->audioq, SAMPLE_QUEUE_SIZE, 1) < 0)
        goto fail;

    //创建视频渲染线程
    is->video_refresh_tid = SDL_CreateThreadEx(&is->_video_refresh_tid, video_refresh_thread, ffp, "ff_vout");

    //创建读取数据线程 ff_read
     is->read_tid = SDL_CreateThreadEx(&is->_read_tid, read_thread, ffp, "ff_read");
}
```
注意视频解码和音频是两条并行的线，播放器做好了同步控制。（subtitle也算一条线）

ff_ffplay.c
```c
/* this thread gets the stream from the disk or the network */
static int read_thread(void *arg){
       do {
           //..
            err = avformat_find_stream_info(ic, opts); //这个avformat_find_stream_info是ffmpeg的api
        } while(0);
        ffp_notify_msg1(ffp, FFP_MSG_FIND_STREAM_INFO);


     for (i = 0; i < ic->nb_streams; i++) {
         //...选择想要的track
        // choose first h264
        if (type == AVMEDIA_TYPE_VIDEO) {
            if (codec_id == AV_CODEC_ID_H264) {
              //..
            }
        }
    }

    //然后是打开流
    /* open the streams */
    if (st_index[AVMEDIA_TYPE_AUDIO] >= 0) {
        stream_component_open(ffp, st_index[AVMEDIA_TYPE_AUDIO]);
    } else {
        ffp->av_sync_type = AV_SYNC_VIDEO_MASTER;
        is->av_sync_type  = ffp->av_sync_type;
    }

    //打开媒体数据，得到的是音视频分离的解码前数据
    ret = av_read_frame(ic, pkt);

    for (;;) {
        //注意这里写了一个循环，所以下面的过程是持续的
        if (is->abort_request)
            break;
        }
        //每次读取一部分数据就调用ffmpeg api往后挪一点
        ret = avformat_seek_file(is->ic, -1, seek_min, seek_target, seek_max, is->seek_flags);
         if (is->audio_stream >= 0) { //把音频放进队列
            packet_queue_flush(&is->audioq);
            packet_queue_put(&is->audioq, &flush_pkt);
            // TODO: clear invaild audio data
            // SDL_AoutFlushAudio(ffp->aout);
        }
        if (is->subtitle_stream >= 0) { //把字幕放进队列
            packet_queue_flush(&is->subtitleq);
            packet_queue_put(&is->subtitleq, &flush_pkt);
        }
        if (is->video_stream >= 0) { //把视频数据放进队列
            if (ffp->node_vdec) {
                ffpipenode_flush(ffp->node_vdec);
            }
            packet_queue_flush(&is->videoq);
            packet_queue_put(&is->videoq, &flush_pkt);
        }
    }
```

stream_component_open中根据数据的类型，分别创建音频解码器，视频解码器或是字幕解码器
```c
static int stream_component_open(FFPlayer *ffp, int stream_index){
    ...
  switch (avctx->codec_type) {
        case AVMEDIA_TYPE_AUDIO   : is->last_audio_stream    = stream_index; forced_codec_name = ffp->audio_codec_name; break;
        case AVMEDIA_TYPE_SUBTITLE: is->last_subtitle_stream = stream_index; forced_codec_name = ffp->subtitle_codec_name; break;
        case AVMEDIA_TYPE_VIDEO   : is->last_video_stream    = stream_index; forced_codec_name = ffp->video_codec_name; break;
        default: break;
    }
    ...
}

static IJKFF_Pipenode *func_open_video_decoder(IJKFF_Pipeline *pipeline, FFPlayer *ffp)
{
    IJKFF_Pipeline_Opaque *opaque = pipeline->opaque;
    IJKFF_Pipenode        *node = NULL;

    if (ffp->mediacodec_all_videos || ffp->mediacodec_avc || ffp->mediacodec_hevc || ffp->mediacodec_mpeg2)
        node = ffpipenode_create_video_decoder_from_android_mediacodec(ffp, pipeline, opaque->weak_vout); //如果设置了option则选用mediaCode
    if (!node) {
        //否则使用ffmpeg
        node = ffpipenode_create_video_decoder_from_ffplay(ffp);
    }

    return node;
}
```

### 视频输出
不管视频解码还是音频解码，其基本流程都是从解码前的数据缓冲区中取出一帧数据进行解码，完成后放入相应的解码后的数据缓冲区

### 音频输出
ijkplayer中Android平台使用OpenGL ES或AudioTrack输出音频，iOS平台使用AudioQueue输出音频。

### 视频的音视频同步
通常音视频同步的解决方案就是选择一个参考时钟，播放时读取音视频帧上的时间戳，同时参考当前时钟参考时钟上的时间来安排播放
ijkplayer在默认情况下也是使用音频作为参考时钟源，处理同步的过程主要在视频渲染video_refresh_thread的线程中：


[ijkplayer现在看来似乎只是ffmpeg的一层wrapper](https://github.com/Bilibili/ijkplayer)


MediaCodec应该就是硬解，ffmpeg是软解(后面好像支持了硬解)


## 参考
- [Ijkplayer解析](https://www.jianshu.com/p/daf0a61cc1e0)
[ffmpeg c语言写一个video player](https://github.com/mpenkov/ffmpeg-tutorial)
[ffmpeg的node js 包装](https://github.com/fluent-ffmpeg/node-fluent-ffmpeg)
[nginx搭建rtmp推流服务](https://www.jianshu.com/p/fc64102d6162)
[ijkplayer如何使用FFmpeg 4.0内核？](https://zhuanlan.zhihu.com/p/51010662)
[微信Android视频编码爬过的那些坑](https://github.com/WeMobileDev/article/blob/master/微信Android视频编码爬过的那些坑.md) 使用Neon指令
[B站有一个AndroidVideoCache通过本地ServerSocket的形式实现了边看边缓存](https://www.jianshu.com/p/4745de02dcdc) 具体实现是读的时候读所在的线程每隔一秒wait(1000)(这一秒中其实读取远程server数据的线程一直在跑)然后去读，很好的框架。


tbd
opencv
play video using ffmplayer


