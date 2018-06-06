#import "FFmpegVideoPlayer.h"

#ifndef TIMEOUT
# define TIMEOUT 30 // 30 seconds timeout
#endif

@implementation FFmpegVideoPlayer

@synthesize interval;

- (UIImage *)currentImage
{
    if (!pFrame || !pFrame->data[0])
        return nil;
    
    return [self convertFrameToImage];
}

FFmpegVideoPlayer *_sharedInstance = nil;

// Singleton instance
+ (FFmpegVideoPlayer *) sharedInstance {
    if(!_sharedInstance) {
        _sharedInstance = [[FFmpegVideoPlayer alloc] init];
        
        //av_log_set_level(AV_LOG_TRACE);
        
        // Register all formats and codecs
        avcodec_register_all();
        av_register_all();
    }
    return _sharedInstance;
}

static NSDate *interruptTime;

// Interrupt callback to prevent stream IO from blocking
static int interrupt_cb(void *ctx) {
    NSDate *now = [NSDate date];
    if([interruptTime compare:[NSDate distantPast]] == NSOrderedSame) {
        interruptTime = now;
    } else if([now timeIntervalSinceDate:interruptTime] > TIMEOUT) {
        NSLog(@"FFmpegVideoPlayer timeout");
        interruptTime = [NSDate distantPast];
        return 1;
    }
    return 0;
}

- (BOOL)initWithVideo:(NSString *)moviePath usesTcp:(BOOL)usesTcp
{
    @synchronized(self) {
        
        interruptTime = [NSDate distantPast];
        
        avformat_network_init();
        
        pFormatCtx = avformat_alloc_context();
        pFormatCtx->interrupt_callback.callback = interrupt_cb;
        pFormatCtx->interrupt_callback.opaque = pFormatCtx;
        
        // Set the RTSP Options
        AVDictionary *opts = 0;
        if (usesTcp) {
            av_dict_set(&opts, "rtsp_transport", "tcp", 0);
        }
        
        if (avformat_open_input(&pFormatCtx, [moviePath UTF8String], NULL, &opts) != 0) {
            av_log(NULL, AV_LOG_ERROR, "Couldn't open file\n");
            return NO;
        }
        
        // Retrieve stream information
        if (avformat_find_stream_info(pFormatCtx,NULL) < 0) {
            av_log(NULL, AV_LOG_ERROR, "Couldn't find stream information\n");
            return NO;
        }
        
        // Find the first video stream
        videoStream = -1;
        
        for (int i = 0; i < pFormatCtx->nb_streams; i++) {
            if (pFormatCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
                NSLog(@"found video stream");
                videoStream=i;
            }
        }
        
        if (videoStream == -1) {
            return NO;
        }
        
        // Get a pointer to the codec context for the video stream
        AVCodec *pCodec = avcodec_find_decoder(pFormatCtx->streams[videoStream]->codecpar->codec_id);
        if (pCodec == NULL) {
            av_log(NULL, AV_LOG_ERROR, "Unsupported codec!\n");
            return NO;
        }
        pCodecCtx = avcodec_alloc_context3(pCodec);
        avcodec_parameters_to_context(pCodecCtx, pFormatCtx->streams[videoStream]->codecpar);
        
        // Open codec
        if (avcodec_open2(pCodecCtx, pCodec, NULL) < 0) {
            av_log(NULL, AV_LOG_ERROR, "Cannot open video decoder\n");
            return NO;
        }
        
        // Allocate video frame
        pFrame = av_frame_alloc();
        pFrameRGB = av_frame_alloc();
        out_buffer = (unsigned char *)av_malloc(av_image_get_buffer_size(AV_PIX_FMT_RGB24, pCodecCtx->width, pCodecCtx->height, 1));
        av_image_fill_arrays(pFrameRGB->data, pFrameRGB->linesize, out_buffer, AV_PIX_FMT_RGB24, pCodecCtx->width, pCodecCtx->height, 1);
        
        // Setup Scaler
        sws_freeContext(img_convert_ctx);
        img_convert_ctx = sws_getContext(pCodecCtx->width, pCodecCtx->height, pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height, AV_PIX_FMT_RGB24, SWS_FAST_BILINEAR, NULL, NULL, NULL);
        
        
        packetCount = 0;
        interval = 1.0/60;
        frameElapsed = 0.0;
        timeElapsed = 0.0;
        
        return YES;
    }
}

- (void)stop
{
    @synchronized(self) {
        
        // Free scaler
        sws_freeContext(img_convert_ctx);
        img_convert_ctx = nil;
        
        // Free the frame
        //av_freep(&out_buffer);
        av_frame_free(&pFrame);
        av_frame_free(&pFrameRGB);
        
        // Close the codec
        if (pCodecCtx) {
            avcodec_close(pCodecCtx);
        }
        
        // Close the video file
        if (pFormatCtx) {
            avformat_close_input(&pFormatCtx);
        }
    }
}

- (void)stepFrame
{
    @synchronized(self) {
        if (pFormatCtx && av_read_frame(pFormatCtx, &packet) >= 0) {
            
            NSDate *currentTime = [NSDate date];
            interruptTime = currentTime;
            
            if(packet.stream_index == videoStream) {
                if(avcodec_send_packet(pCodecCtx, &packet) == 0 && avcodec_receive_frame(pCodecCtx, pFrame) == 0) {
                    
                    double pts = pFrame->best_effort_timestamp * av_q2d(pFormatCtx->streams[videoStream]->time_base);
                    double frameInterval = lastPTS == 0.0 ? 0 : fabs(pts - lastPTS);
                    double timeInterval = lastTime == nil ? 0 : fabs([currentTime timeIntervalSinceDate:lastTime]);
                    lastPTS = pts;
                    lastTime = currentTime;
                    
                    if(frameInterval < 1000) { // ignore overflow
                        if(packetCount <= 30) {
                            packetCount++;
                            frameElapsed += frameInterval;
                            timeElapsed += timeInterval;
                        } else {
                            packetCount = 0;
                            interval *= frameElapsed / timeElapsed;
                            double frameRate = 30.0 / timeElapsed;
                            NSLog(@"interval:%f frame elapsed:%f time elapsed:%f frame rate:%f", interval, frameElapsed, timeElapsed, frameRate);
                            
                            frameElapsed = 0.0;
                            timeElapsed = 0.0;
                        }
                    }
                }
            }
        }
        
        av_packet_unref(&packet);
    }
}

- (UIImage *)convertFrameToImage
{
    @synchronized(self)
    {
        if(img_convert_ctx) {
            // Convert YUV frame to RGB frame
            sws_scale(img_convert_ctx, (const uint8_t *const *)pFrame->data, pFrame->linesize, 0, pFrame->height, pFrameRGB->data, pFrameRGB->linesize);
            
            // Convert RGB frame to UIImage
            CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
            CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pFrameRGB->data[0], pFrameRGB->linesize[0] * pCodecCtx->height, kCFAllocatorNull);
            CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGImageRef cgImage = CGImageCreate(pCodecCtx->width, pCodecCtx->height, 8, 24, pFrameRGB->linesize[0], colorSpace, bitmapInfo, provider, NULL, NO, kCGRenderingIntentDefault);
            UIImage *image = [UIImage imageWithCGImage:cgImage];
            
            CGImageRelease(cgImage);
            CGColorSpaceRelease(colorSpace);
            CGDataProviderRelease(provider);
            CFRelease(data);
            
            return image;
        } else {
            return nil;
        }
    }
}

@end
