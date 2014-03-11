function [ datafeatures, dataclass ] = get_training_data( I, Icolored, resize )
%REQUIRES: I is an image matrix, Icolored is the 
%          same image as I with pixels in class of interest colored red,
%          resize is bool for 768 by 768 scaling
%EFFECTS: Returns datafeatures - array of feature vectors size numpixels x
%                   length of feature vectors
%                 dataclass - array of pixel classes -1 or 1 of size numpixels x 1


if length(size(I))==3
       I=rgb2gray(I);
end

if size(Icolored,3)>3
    Icolored=Icolored(:,:,1:3);
end

I=im2double(I);
I = crop_footer(I);
Icolored = crop_footer(Icolored);
if resize
    I=imresize(I, [768 768]);
    Icolored=imresize(Icolored, [768 768]);
end


% %Gabor filter input image
H=fspecial('Gaussian',[5 5], 1);
I=imfilter(I,H);

%Run Gabor Filtering
gabors = apply_gabor_wavelet(I,0);

%assign pixels their classes
classes = Icolored(:,:,1)>Icolored(:,:,2);
classes = double(classes);
classes(classes==0)=-1;

stdI=std(I(:));
meanI=mean2(I);
[h,w]=size(I);
numPixels = h*w;
datafeatures = zeros(numPixels,size(gabors,3)+1);
dataclass = zeros(numPixels,1);
for i= 1:h
    for j= 1:w
        index= (i-1)*w+j;
        datafeatures(index,1:size(gabors,3)) = gabors(i,j,:);
        datafeatures(index,size(gabors,3)+1) = (I(i,j)-meanI)./stdI;
        dataclass(index) = classes(i,j);
    end
end

clear gabors

end
