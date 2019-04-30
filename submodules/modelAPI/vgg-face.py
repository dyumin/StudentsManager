#!/usr/bin/env python3
# coding: utf-8

# This is python-2.7 code.

from keras.models import Model, Sequential, model_from_json
from keras.layers import Input, Convolution2D, ZeroPadding2D, MaxPooling2D, Flatten, Dense, Dropout, Activation
from PIL import Image
import numpy as np
import sys
from keras.preprocessing.image import load_img, save_img, img_to_array
from keras.applications.imagenet_utils import preprocess_input
from keras.preprocessing import image
import matplotlib.pyplot as plt

# MARK: preprocess image
"""
    preprocess_image(image_patg).
    Input: absoulute or reference path to the iamge.
    Output: preprocessed image.
    """
def preprocess_image(image_path):
    img = load_img(image_path, target_size=(224, 224))
    img = img_to_array(img)
    img = np.expand_dims(img, axis=0)
    img = preprocess_input(img)
    return img


# MARK: findCosineSimilarity
"""
    findCosineSimilarity(source_representation, test_representation).
    Input: source and test representations of face.
    Output: cosine similarity of faces.
    """
def findCosineSimilarity(source_representation, test_representation):
    a = np.matmul(np.transpose(source_representation), test_representation)
    b = np.sum(np.multiply(source_representation, source_representation))
    c = np.sum(np.multiply(test_representation, test_representation))
    return 1 - (a / (np.sqrt(b) * np.sqrt(c)))

# MARK: findCosineSimilarity
"""
    findEuclideanDistance(source_representation, test_representation).
    Input: source and test representations of face.
    Output: euclidean distance of faces.
    """
def findEuclideanDistance(source_representation, test_representation):
    euclidean_distance = source_representation - test_representation
    euclidean_distance = np.sum(np.multiply(euclidean_distance, euclidean_distance))
    euclidean_distance = np.sqrt(euclidean_distance)
    return euclidean_distance


# MARK: model activation
"""
    loadFaceDescriptor().
    Activates model and loads pre-trained weights.
    They should be put in the same directory with script.
    
    Output: vgg face descriptor.
    """
def loadFaceDescriptor():
    # model layers initialization
    model = Sequential()
    model.add(ZeroPadding2D((1,1),input_shape=(224,224, 3)))
    model.add(Convolution2D(64, (3, 3), activation='relu'))
    model.add(ZeroPadding2D((1,1)))
    model.add(Convolution2D(64, (3, 3), activation='relu'))
    model.add(MaxPooling2D((2,2), strides=(2,2)))

    model.add(ZeroPadding2D((1,1)))
    model.add(Convolution2D(128, (3, 3), activation='relu'))
    model.add(ZeroPadding2D((1,1)))
    model.add(Convolution2D(128, (3, 3), activation='relu'))
    model.add(MaxPooling2D((2,2), strides=(2,2)))

    model.add(ZeroPadding2D((1,1)))
    model.add(Convolution2D(256, (3, 3), activation='relu'))
    model.add(ZeroPadding2D((1,1)))
    model.add(Convolution2D(256, (3, 3), activation='relu'))
    model.add(ZeroPadding2D((1,1)))
    model.add(Convolution2D(256, (3, 3), activation='relu'))
    model.add(MaxPooling2D((2,2), strides=(2,2)))

    model.add(ZeroPadding2D((1,1)))
    model.add(Convolution2D(512, (3, 3), activation='relu'))
    model.add(ZeroPadding2D((1,1)))
    model.add(Convolution2D(512, (3, 3), activation='relu'))
    model.add(ZeroPadding2D((1,1)))
    model.add(Convolution2D(512, (3, 3), activation='relu'))
    model.add(MaxPooling2D((2,2), strides=(2,2)))

    model.add(ZeroPadding2D((1,1)))
    model.add(Convolution2D(512, (3, 3), activation='relu'))
    model.add(ZeroPadding2D((1,1)))
    model.add(Convolution2D(512, (3, 3), activation='relu'))
    model.add(ZeroPadding2D((1,1)))
    model.add(Convolution2D(512, (3, 3), activation='relu'))
    model.add(MaxPooling2D((2,2), strides=(2,2)))

    model.add(Convolution2D(4096, (7, 7), activation='relu'))
    model.add(Dropout(0.5))
    model.add(Convolution2D(4096, (1, 1), activation='relu'))
    model.add(Dropout(0.5))
    model.add(Convolution2D(2622, (1, 1)))
    model.add(Flatten())
    model.add(Activation('softmax'))
    
    # loading weights. They should be put in the same directory with script.
    model.load_weights('vgg_face_weights.h5')
    
    _vgg_face_descriptor = Model(inputs=model.layers[0].input, outputs=model.layers[-2].output)
    return _vgg_face_descriptor


# MARK: verifyFace
"""
    verifyFace(img1, img2).
    Input: absolute paths of 2 faces images to compare.
    Output: 1 - if the same person, 0 - if not.
    """
def verifyFace(img1, img2):
    # threshold value
    epsilon = 0.40
    
    vgg_face_descriptor = loadFaceDescriptor()
    img1_representation = vgg_face_descriptor.predict(preprocess_image('%s' % (img1)))[0,:]
    img2_representation = vgg_face_descriptor.predict(preprocess_image('%s' % (img2)))[0,:]
    
    cosine_similarity = findCosineSimilarity(img1_representation, img2_representation)
    euclidean_distance = findEuclideanDistance(img1_representation, img2_representation)
    
    if(cosine_similarity < epsilon):
        return 1
    else:
        return 0


#base_dir = os.path.dirname(__file__)
