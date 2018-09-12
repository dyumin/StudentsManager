//
//  FacesExtractor.m
//  StudentsManager-IOS
//
//  Created by Дюмин Алексей on 12/09/2018.
//  Copyright © 2018 Bauman. All rights reserved.
//

#import "FacesExtractor.h"

#include <dlib/dnn.h>
#include <dlib/gui_widgets.h>
#include <dlib/clustering.h>
#include <dlib/string.h>
#include <dlib/image_io.h>
#include <dlib/image_saver/image_saver.h>
#include <dlib/image_processing/frontal_face_detector.h>

using namespace dlib;
using namespace std;


// ----------------------------------------------------------------------------------------

// The next bit of code defines a ResNet network.  It's basically copied
// and pasted from the dnn_imagenet_ex.cpp example, except we replaced the loss
// layer with loss_metric and made the network somewhat smaller.  Go read the introductory
// dlib DNN examples to learn what all this stuff means.
//
// Also, the dnn_metric_learning_on_images_ex.cpp example shows how to train this network.
// The dlib_face_recognition_resnet_model_v1 model used by this example was trained using
// essentially the code shown in dnn_metric_learning_on_images_ex.cpp except the
// mini-batches were made larger (35x15 instead of 5x5), the iterations without progress
// was set to 10000, and the training dataset consisted of about 3 million images instead of
// 55.  Also, the input layer was locked to images of size 150.
template <template <int,template<typename>class,int,typename> class block, int N, template<typename>class BN, typename SUBNET>
using residual = add_prev1<block<N,BN,1,tag1<SUBNET>>>;

template <template <int,template<typename>class,int,typename> class block, int N, template<typename>class BN, typename SUBNET>
using residual_down = add_prev2<avg_pool<2,2,2,2,skip1<tag2<block<N,BN,2,tag1<SUBNET>>>>>>;

template <int N, template <typename> class BN, int stride, typename SUBNET>
using block  = BN<con<N,3,3,1,1,relu<BN<con<N,3,3,stride,stride,SUBNET>>>>>;

template <int N, typename SUBNET> using ares      = relu<residual<block,N,affine,SUBNET>>;
template <int N, typename SUBNET> using ares_down = relu<residual_down<block,N,affine,SUBNET>>;

template <typename SUBNET> using alevel0 = ares_down<256,SUBNET>;
template <typename SUBNET> using alevel1 = ares<256,ares<256,ares_down<256,SUBNET>>>;
template <typename SUBNET> using alevel2 = ares<128,ares<128,ares_down<128,SUBNET>>>;
template <typename SUBNET> using alevel3 = ares<64,ares<64,ares<64,ares_down<64,SUBNET>>>>;
template <typename SUBNET> using alevel4 = ares<32,ares<32,ares<32,SUBNET>>>;

using anet_type = loss_metric<fc_no_bias<128,avg_pool_everything<
alevel0<
alevel1<
alevel2<
alevel3<
alevel4<
max_pool<3,3,2,2,relu<affine<con<32,7,7,2,2,
input_rgb_image_sized<150>
>>>>>>>>>>>>;

// ----------------------------------------------------------------------------------------

std::vector<matrix<rgb_pixel>> jitter_image(
                                            const matrix<rgb_pixel>& img
                                            );



@implementation FacesExtractor

+ (UIImage*) convertToUIImage:(const matrix<rgb_pixel>&)matrix
{
    NSString* fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @"image.png"];
    
    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    
    save_bmp(matrix, fileURL.path.UTF8String);
    
    UIImage* image = [UIImage imageWithData:[NSData dataWithContentsOfURL:fileURL]];
    
    [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
    
    return image;
}

+ (NSArray<UIImage *> *)getFaceImagesFromImageAtPath:(NSString*)imagePath
{
    NSString* shapePredictorModel = [[NSBundle mainBundle] pathForResource:@"shape_predictor_5_face_landmarks" ofType:@"dat"];
    
    NSString* dlibFaceRecognitionModel = [[NSBundle mainBundle] pathForResource:@"dlib_face_recognition_resnet_model_v1" ofType:@"dat"];
    
    // The first thing we are going to do is load all our models.  First, since we need to
    // find faces in the image we will need a face detector:
    frontal_face_detector detector = get_frontal_face_detector();
    // We will also use a face landmarking model to align faces to a standard pose:  (see face_landmark_detection_ex.cpp for an introduction)
    shape_predictor sp;
    deserialize(shapePredictorModel.UTF8String) >> sp;
    // And finally we load the DNN responsible for face recognition.
    anet_type net;
    deserialize(dlibFaceRecognitionModel.UTF8String) >> net;
    
    matrix<rgb_pixel> img;
    load_image(img, imagePath.UTF8String);
    
//    return [NSArray arrayWithObject:[FacesExtractor convertToUIImage:img]];
    
    // Run the face detector on the image of our action heroes, and for each face extract a
    // copy that has been normalized to 150x150 pixels in size and appropriately rotated
    // and centered.
    std::vector<matrix<rgb_pixel>> faces;
    for (auto face : detector(img))
    {
        NSLog(@"1");
        auto shape = sp(img, face);
        NSLog(@"2");
        matrix<rgb_pixel> face_chip;
        NSLog(@"3");
        extract_image_chip(img, get_face_chip_details(shape,150,0.25), face_chip);
        NSLog(@"4");
        UIImageWriteToSavedPhotosAlbum([FacesExtractor convertToUIImage:face_chip], nil, nil, nil);
        NSLog(@"5");
        faces.push_back(move(face_chip));
        NSLog(@"6");
    }
    
    
    return nil;
}

@end
