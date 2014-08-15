//
//  HSViewController.m
//  HearShot
//
//  Created by Yurii.B on 7/17/14.
//  Copyright (c) 2014 YuriiBogdan. All rights reserved.
//

#import "HSViewController.h"

- (void)convertVideoToAudio {
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    
    converteAudioPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[@"audio" stringByAppendingPathExtension:@"m4a"]];
    NSURL*      dstURL = [NSURL fileURLWithPath:converteAudioPath];
    [[NSFileManager defaultManager] removeItemAtURL:dstURL error:nil];
    
    AVMutableComposition*   newAudioAsset = [AVMutableComposition composition];
    
    AVMutableCompositionTrack*  dstCompositionTrack;
    dstCompositionTrack = [newAudioAsset addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    
    AVAsset*    srcAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:outputFilePath] options:nil];
    AVAssetTrack*   srcTrack = [[srcAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    
    CMTimeRange timeRange = srcTrack.timeRange;
    
    NSError*    error;
    
    if(NO == [dstCompositionTrack insertTimeRange:timeRange ofTrack:srcTrack atTime:kCMTimeZero error:&error]) {
        NSLog(@"track insert failed: %@\n", error);
        [self onCompletionVideoToAudioConversion:@"NO"];
        return;
    }
    
    AVAssetExportSession*   exportSesh = [[AVAssetExportSession alloc] initWithAsset:newAudioAsset presetName:AVAssetExportPresetPassthrough];
    
    exportSesh.outputFileType = AVFileTypeAppleM4A;
    exportSesh.outputURL = dstURL;
    
    [exportSesh exportAsynchronouslyWithCompletionHandler:^{
        AVAssetExportSessionStatus  status = exportSesh.status;
        NSLog(@"exportAsynchronouslyWithCompletionHandler: %i\n", status);
        
        
        
        if(AVAssetExportSessionStatusFailed == status) {
            NSLog(@"FAILURE: %@\n", exportSesh.error);
            [self performSelector:@selector(onCompletionVideoToAudioConversion:) onThread:[NSThread mainThread] withObject:@"NO" waitUntilDone:NO];
        } else if(AVAssetExportSessionStatusCompleted == status) {
            NSLog(@"SUCCESS!\n");
            
            [self performSelector:@selector(onCompletionVideoToAudioConversion:) onThread:[NSThread mainThread] withObject:@"YES" waitUntilDone:NO];
        }
    }];
}

- (void)onCompletionVideoToAudioConversion:(NSString*)isFinished {
    UIBackgroundTaskIdentifier backgroundRecordingID = [self backgroundRecordingID];
	[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
    
    // Remove temp memory and end background task
    [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:outputFilePath] error:nil];
    if (backgroundRecordingID != UIBackgroundTaskInvalid)
        [[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];
    
    if ([isFinished boolValue]) {
        if (recordCounter > 9 && capturedCounter >= 2) {
            //            [self setupPlayer:[NSURL fileURLWithPath:converteAudioPath]];
            [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[_firstImageView.image CGImage] orientation:(ALAssetOrientation)[_firstImageView.image imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error){
                [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[_secondImageView.image CGImage] orientation:(ALAssetOrientation)[_secondImageView.image imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error){
                    [SVProgressHUD dismiss];
                    [self moveToRenderView];
                }];
            }];
        }
    }
}

@end
