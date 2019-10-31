function x = image_stitching()

%{
Code influenced (and restructured) from: 
% http://www.vlfeat.org/applications/sift-mosaic-code.html
%}

% read images
% ADD 600*650 resolution images IN ORDER!

im1=imread('../data/1.JPG');
im2=imread('../data/2.JPG');
im3=imread('../data/3.JPG');    
im4=imread('../data/4.JPG');
im5=imread('../data/5.JPG');
imagesOriginal = {im1, im2, im3, im4, im5};
figure(1) ; clf ;
montage({im1,im2,im3,im4,im5});
numImages=5;

% make single and grayscale
img1 = rgb2gray(im2single(im1)) ;
img2 = rgb2gray(im2single(im2)) ;
img3 = rgb2gray(im2single(im3)) ;
img4 = rgb2gray(im2single(im4)) ;
img5 = rgb2gray(im2single(im5)) ;
imagesGrayScale = {img1, img2, img3, img4, img5} ;

% Get keypoints for each image and store it.
for j=1:numImages 
   [fG,dG]= vl_sift(imagesGrayScale{j}) ;
   f{j}=fG; d{j}=dG;
end

%{
start with middle image. Stitch images to its left and right
So for 5 images - start with image3. Stitch img4 to it. then image2. then image 1 followed by
image5.
if 6 images -> stitch 3&2. Then 4 followed by 1,5 and 6

Following is the algorithm to do this
%}

midImageIndex=ceil(numImages/2); 
rotationIndices=floor(numImages/2);

%{
match first 2 images. 
iF numImages is odd then match midImage with midImage+1
if numImages is even then match midImage with midImage-1
%}
if mod(numImages,2)==0
    imgIndex1= midImageIndex-1; imgIndex2=midImageIndex;
    [X1,X2, matches] = matchImages(f{imgIndex1},d{imgIndex1},f{imgIndex2},d{imgIndex2});
    H=ransac(X1,X2,matches);
    mosaic = drawMosaic(H,imagesOriginal{imgIndex1},imagesOriginal{imgIndex2});
    mosaicSingle = rgb2gray(im2single(mosaic)) ;
    indicesToIgnore = -1; %don't stitch  midImageIndex-1 again, since already done it.
else
    imgIndex1= midImageIndex; imgIndex2=midImageIndex+1;
    [X1,X2, matches] = matchImages(f{imgIndex1},d{imgIndex1},f{imgIndex2},d{imgIndex2});
    H=ransac(X1,X2,matches);
    mosaic = drawMosaic(H,imagesOriginal{imgIndex1},imagesOriginal{imgIndex2});
    mosaicSingle = rgb2gray(im2single(mosaic)) ;   
    indicesToIgnore = 1;
end

% now match the remianing images
for j=1:rotationIndices
   for k = [-1,1] %to simulate alternatively stitching right and left.
       imageIndex=midImageIndex + (j*k); 
       %3-1 then 3+1 then 3-2 then 3+2.
       if (j*k)~=indicesToIgnore && (imageIndex~=0) 
           %ignore already matched image, or if we reach index 0.
            [fG,dG] = vl_sift(mosaicSingle);
            [X1,X2, matches] = matchImages(fG,dG,f{imageIndex},d{imageIndex});
            H=ransac(X1,X2,matches);
            mosaic = drawMosaic(H,mosaic,imagesOriginal{imageIndex});
            mosaicSingle = rgb2gray(im2single(mosaic)) ;
       end
   end
end

figure(2) ; clf ;
imagesc(mosaic) ; axis image off ;
title('Mosaic') ;
%write image
imwrite(mosaic,'../stitched.png');

%HELPER METHOD - match keypoints.
function [X1,X2,matches] = matchImages(f1,d1,f2,d2)
    [matches, scores] = vl_ubcmatch(d1,d2) ;
    % matches returns the indices of both images where keypoints matched.
    %get (x,y) coordinates of allpixels that matched. add 3d coordinate.
    X1 = f1(1:2,matches(1,:)) ; X1(3,:) = 1 ; 
    X2 = f2(1:2,matches(2,:)) ; X2(3,:) = 1 ; 
end

%HELPER METHOD - Do ransac.
function H = ransac(X1,X2,matches)
    clear H score ok ; %set variables to 0.
    numMatches = size(matches,2) ;
    for t = 1:100
        %get subset of 4 points
        subset = vl_colsubset(1:numMatches, 4) ;
        A = [] ;
        %create homography matrix.
        for i = subset
            A = cat(1, A, kron(X1(:,i)', vl_hat(X2(:,i)))) ;    
        end
        [U,S,V] = svd(A) ; 
        %H = last column after doing SVD.
        H{t} = reshape(V(:,9),3,3) ; 

      % step 3score homography
      X2_ = H{t} * X1 ; % PROJECTION of X1 with homography
      du = X2_(1,:)./X2_(3,:) - X2(1,:)./X2(3,:) ;
      dv = X2_(2,:)./X2_(3,:) - X2(2,:)./X2(3,:) ;
      ok{t} = (du.*du + dv.*dv) < 6*6 ; % if distance < threshold.
      score(t) = sum(ok{t}) ;
    end
    %step 4 - find the best one.
    [score, best] = max(score) ;
    H = H{best} ;
end

% HELPER METHOD - join 2 images based on homography model.
function mosaic = drawMosaic(H,im1,im2)
    box2 = [1  size(im2,2) size(im2,2)  1 ;
        1  1           size(im2,1)  size(im2,1) ;
        1  1           1            1 ] ;
    box2_ = inv(H) * box2 ;
    box2_(1,:) = box2_(1,:) ./ box2_(3,:) ;
    box2_(2,:) = box2_(2,:) ./ box2_(3,:) ;
    ur = min([1 box2_(1,:)]):max([size(im1,2) box2_(1,:)]) ;
    vr = min([1 box2_(2,:)]):max([size(im1,1) box2_(2,:)]) ;

    [u,v] = meshgrid(ur,vr) ;
    im1_ = vl_imwbackward(im2double(im1),u,v) ;

    z_ = H(3,1) * u + H(3,2) * v + H(3,3) ;
    u_ = (H(1,1) * u + H(1,2) * v + H(1,3)) ./ z_ ;
    v_ = (H(2,1) * u + H(2,2) * v + H(2,3)) ./ z_ ;
    im2_ = vl_imwbackward(im2double(im2),u_,v_) ;

    mass = ~isnan(im1_) + ~isnan(im2_) ;
    im1_(isnan(im1_)) = 0 ;
    im2_(isnan(im2_)) = 0 ;
    mosaic = (im1_ + im2_) ./ mass ;
end
end
