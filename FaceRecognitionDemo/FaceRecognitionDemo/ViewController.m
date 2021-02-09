//
//  ViewController.m
//  FaceRecognitionDemo
//
//  Created by A on 2021/2/8.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#import "CoreImageFaceController.h"

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureMetadataOutputObjectsDelegate>

//硬件设备
@property (nonatomic, strong) AVCaptureDevice *device;
//输入流
@property (nonatomic, strong) AVCaptureDeviceInput *input;
//协调输入输出流的数据
@property (nonatomic, strong) AVCaptureSession *session;
//预览层
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

//输出流

@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;  //用于捕捉静态图片
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;    //原始视频帧，用于获取实时图像以及视频录制
@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;      //用于二维码识别以及人脸识别

//切换前后摄像头
@property (nonatomic, strong) UIButton *cameraButton;

// 人脸框
@property (nonatomic,strong) NSMutableArray *faceViewArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view.layer addSublayer:self.previewLayer];
    [self.view addSubview:self.cameraButton];
    [self setupMenuButton];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.session startRunning];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
//AVCaptureVideoDataOutput获取实时图像，这个代理方法的回调频率很快，几乎与手机屏幕的刷新频率一样快
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    //设置图像方向，否则largeImage取出来是反的
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait|AVCaptureVideoOrientationLandscapeRight|AVCaptureVideoOrientationLandscapeLeft];
    
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    //先清空人脸数组
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.faceViewArr enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj removeFromSuperview];
                 obj = nil;
            }];
        });
    
    if (metadataObjects.count>0) {
        
        for (AVMetadataMachineReadableCodeObject *metadataObject in metadataObjects) {
            AVMetadataObject *faceData = [self.previewLayer transformedMetadataObjectForMetadataObject:metadataObject];
            //描绘人脸区域
            dispatch_async(dispatch_get_main_queue(), ^{
                UIView* faceView = [[UIView alloc] initWithFrame:faceData.bounds];
                faceView.layer.borderWidth = 2;
                faceView.layer.borderColor = [[UIColor greenColor] CGColor];
                [self.view addSubview:faceView];
                [self.faceViewArr addObject:faceView];
            });
        }
    }
}

#pragma mark - 切换前后摄像头
- (void)switchCamera{
    NSUInteger cameraCount = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
    if (cameraCount > 1) {
        AVCaptureDevice *newCamera = nil;
        AVCaptureDeviceInput *newInput = nil;
        AVCaptureDevicePosition position = [[self.input device] position];
        if (position == AVCaptureDevicePositionFront){
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
        }else {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
        }
        newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
        if (newInput != nil) {
            [self.session beginConfiguration];
            [self.session removeInput:self.input];
            if ([self.session canAddInput:newInput]) {
                [self.session addInput:newInput];
                self.input = newInput;
            }else {
                [self.session addInput:self.input];
            }
            [self.session commitConfiguration];
        }
    }
}
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position ) return device;
    return nil;
}

- (void)setupMenuButton{
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"CoreImage识别方式" forState:UIControlStateNormal];
    btn.frame = CGRectMake((self.view.frame.size.width - 150.0f)/2, self.view.frame.size.height - 100, 150.0f, 64.0f);
    [btn addTarget:self action:@selector(CoreImageBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}
#pragma mark 另一种识别方式 coreimage识别
- (void)CoreImageBtnClick{
    CoreImageFaceController *coreVc = [CoreImageFaceController new];
    [self presentViewController:coreVc animated:YES completion:nil];
}
#pragma mark - getter
- (AVCaptureDevice *)device{
    if (_device == nil) {
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([_device lockForConfiguration:nil]) {
            //自动闪光灯
            if ([_device isFlashModeSupported:AVCaptureFlashModeAuto]) {
                [_device setFlashMode:AVCaptureFlashModeAuto];
            }
            //自动白平衡
            if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
                [_device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
            }
            //自动对焦
            if ([_device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                [_device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            }
            //自动曝光
            if ([_device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                [_device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
            [_device unlockForConfiguration];
        }
    }
    return _device;
}

- (AVCaptureDeviceInput *)input{
    if (_input == nil) {
        _input = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:nil];
    }
    return _input;
}
- (AVCaptureVideoDataOutput *)videoDataOutput{
    if (_videoDataOutput == nil) {
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
        //设置像素格式，否则CMSampleBufferRef转换NSImage的时候CGContextRef初始化会出问题
        [_videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    }
    return _videoDataOutput;
}

- (AVCaptureMetadataOutput *)metadataOutput{
    if (_metadataOutput == nil) {
        _metadataOutput = [[AVCaptureMetadataOutput alloc]init];
        [_metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        //设置扫描区域
        _metadataOutput.rectOfInterest = self.view.bounds;
    }
    return _metadataOutput;
}

- (AVCaptureSession *)session{
    if (_session == nil) {
        _session = [[AVCaptureSession alloc] init];
        if ([_session canAddInput:self.input]) {
            [_session addInput:self.input];
        }
        if ([_session canAddOutput:self.stillImageOutput]) {
            [_session addOutput:self.stillImageOutput];
        }
        if ([_session canAddOutput:self.videoDataOutput]) {
            [_session addOutput:self.videoDataOutput];
        }
        if ([_session canAddOutput:self.metadataOutput]) {
            [_session addOutput:self.metadataOutput];

            /*//设置扫码格式
            self.metadataOutput.metadataObjectTypes = @[
                                                        AVMetadataObjectTypeQRCode,
                                                        AVMetadataObjectTypeEAN13Code,
                                                        AVMetadataObjectTypeEAN8Code,
                                                        AVMetadataObjectTypeCode128Code
                                                        ];
             */
            
            // 设置人脸识别模式
            self.metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];

        }
    }
    return _session;
}

- (AVCaptureVideoPreviewLayer *)previewLayer{
    if (_previewLayer == nil) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        _previewLayer.frame = self.view.layer.bounds;
    }
    return _previewLayer;
}

- (UIButton *)cameraButton{
    if (_cameraButton == nil) {
        _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cameraButton.frame = CGRectMake((self.view.frame.size.width - 100.0f)/2, 20.0f, 100.0f, 64.0f);
        //[_cameraButton setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
        [_cameraButton setTitle:@"切换摄像头" forState:UIControlStateNormal];
        [_cameraButton addTarget:self action:@selector(switchCamera) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraButton;
}
- (NSMutableArray *)faceViewArr{
    if (!_faceViewArr) {
        _faceViewArr = [NSMutableArray array];
    }
    return _faceViewArr;
}
@end
