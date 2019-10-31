# Image Stitching (Computer Vision in MATLAB)
The idea is to design a Computer Vision algorithm that takes in any number of images(even at different rotations or scale) and then stitching all of them to form a panaroma.
The algorithm uses keypoint detection using SIFT, matches the keypoints, and stitches a pair of images using RANSAC and Homography matrices. 

**NOTE** - 
* The algorithm works for images with resolution of approximtely 600*650 pixels.
* All input images must be provided in order

EXAMPLE (Input Images):
![Image 1](/data/1.jpg) ![Image 2](/data/2.jpg) ![Image 3](/data/3.jpg) ![Image 4](/data/4.jpg) ![Image 5](/data/5.jpg)

Output Image
![stitched](/stitched.png)

## Prerequisites:
* MATLAB
* [MATLAB VLFeat Library for using SIFT](http://www.vlfeat.org/install-matlab.html)
Instructions to install:
a. Unpack the latest VLFeat binary distribution in a directory of your choice
b. Let VLFEATROOT denote this directory. To add the library to MATLAB search path, in the MATLAB prompt enter
```
	run('VLFEATROOT/toolbox/vl_setup')
```
c. Now run:
```
	vl_version verbose
```	
to check that everything is in order.

## CODE

The main code is in `src/image_stitching.m`

It reads the images stored in data directory and it outputs 2 images - a montage showing all the input images and the final stitched image.
The stitched image is stored is the main directory as `stitched.png`

## Understanding the Code
The images were loaded from the data folder into the algorithm and then converted to single, greyscale images. 
Each of the images are then passed through a SIFT detector to find the keypoint indices of each image. (Refer [here](http://www.vlfeat.org/matlab/vl_sift.html)

In order to stitch the images together, each of the images key points needed to be matched using their SIFT descriptors.  RANSAC is then used to find each of the transformations between images, it is used because it finds the most likely transformation by removing outliers. This transformation is then applied to the next image, and the two are stitched together.
(Leanr more about RANSAC [here]())

In order for the outputted image to not look distorted, each image needed to be stitched in a particular order. 
*	If there is an odd number of images: 
	* The starting point is the exact middle image.
	*	This is then stitched with the image to its right.
	*	The two stitched images are then stitched with the image to its left.
	*	An alternating pattern of right and left is then used to stitch the remaining images.
*	If there is an even number of images:
	*	The starting point is the middle-left image.
	*	This is then stitched with the image to its left.
	*	The two stitched images are then stitched with the image to its right.
	*	An alternating pattern of left and right is then used to stitch the remaining images.
	
This way the algorithm can work for any number of images.


## Improvements
An improvement would be to make the alogrithm more efficient i.e. decrease the time taken for the algorithm to output the final stitched image, as working with high-resolution images ( 1024 * 768 pixels) is very time-intensive.

## References
http://www.vlfeat.org/applications/sift-mosaic-code.html


