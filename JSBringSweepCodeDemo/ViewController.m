//
//  ViewController.m
//  JSBringSweepCodeDemo
//
//  Created by jhon.sun on 15/11/11.
//  Copyright © 2015年 jhon.sun. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    
    for (AVCaptureDevice *allDevice in [AVCaptureDevice devices]) {
        NSLog(@"摄像头位置%ld", (long)allDevice.position);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self checkAVAuthorizationStatus];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - get
- (AVCaptureDevice *)device {
    if (!_device) {
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        NSError *error = nil;
        if ([_device lockForConfiguration:&error]) {
            //设置闪光灯
            _device.flashMode = AVCaptureFlashModeAuto;
            //设置手电筒，必须要两个一起设置，闪光灯才能正常工作
            _device.torchMode = AVCaptureTorchModeAuto;
            //设置聚焦方式
            _device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        } else {
            NSLog(@"设置失败，失败原因：%@", [error localizedDescription]);
        }
    }
    return _device;
}

- (AVCaptureDeviceInput *)deviceInput {
    if (!_deviceInput) {
        _deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    }
    return _deviceInput;
}

- (AVCaptureMetadataOutput *)metadataOutput {
    if (!_metadataOutput) {
        _metadataOutput = [[AVCaptureMetadataOutput alloc] init];
        [_metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        
    }
    return _metadataOutput;
}

- (AVCaptureSession *)session {
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
        if ([_session canAddInput:self.deviceInput]) {
            [_session addInput:self.deviceInput];
        }
    }
    return _session;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_previewLayer) {
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _previewLayer.frame = self.view.layer.bounds;
    }
    return _previewLayer;
}

#pragma mark - private
- (void)checkAVAuthorizationStatus {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(status == AVAuthorizationStatusAuthorized) {
        [self startSession];
    } else if(status == AVAuthorizationStatusDenied){
        NSLog(@"么有相机权限1");
        return ;
    } else if(status == AVAuthorizationStatusRestricted){
        // restricted
        NSLog(@"么有相机权限2");
        return;
    } else if(status == AVAuthorizationStatusNotDetermined){
        // not determined
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if(granted){
                [self startSession];
            } else {
                NSLog(@"么有相机权限3");
                return;
            }
        }];
    }
}

- (void)startSession {
    if ([self.session canAddOutput:self.metadataOutput]) {
        [self.session addOutput:self.metadataOutput];
        NSLog(@"%@", self.metadataOutput.availableMetadataObjectTypes);
        self.metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    }
    [self.session startRunning];
}

//获取扫描区域比例，原点在左上角，x与y颠倒
//AVCaptureMetadataOutput的rectOfInterest设置扫描区域
- (CGRect)getScanScropFromScanArea:(CGRect)scanAreaFrame inView:(CGRect)frame {
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat x = scanAreaFrame.origin.y / screenHeight;
    CGFloat y = scanAreaFrame.origin.x / screenWidth;
    CGFloat width = scanAreaFrame.size.height / screenHeight;
    CGFloat height = scanAreaFrame.size.width / screenWidth;
    return CGRectMake(x, y, width, height);
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count > 0) {
        [self.session stopRunning];
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects firstObject];
        NSLog(@"扫描的结果为：%@", metadataObject.stringValue);
    }
}

@end
