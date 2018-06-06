#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "avformat.h"
#import "avcodec.h"
#import "avio.h"
#import "swscale.h"
#import "imgutils.h"

@interface FFmpegVideoPlayer : NSObject {
    AVFormatContext *pFormatCtx;
    AVCodecContext *pCodecCtx;
    struct SwsContext *img_convert_ctx;
    
    AVFrame *pFrame;
    AVFrame *pFrameRGB;
    unsigned char *out_buffer;
    
    AVPacket packet;
    int videoStream;
    
    double lastPTS;
    NSDate *lastTime;
    
    int packetCount;
    double interval;
    double frameElapsed;
    double timeElapsed;
}

@property (nonatomic, assign) double interval;

- (UIImage *)currentImage;

+ (FFmpegVideoPlayer *) sharedInstance;

-(BOOL)initWithVideo:(NSString *)moviePath usesTcp:(BOOL)usesTcp;

-(void)stop;

-(void)stepFrame;

@end
