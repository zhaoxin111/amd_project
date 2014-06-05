function [final_od_image] = find_od(pid, eye, time)
%Standardize variables
std_img_size = 768;

%Add the path for the useful directories
addpath('..');
addpath(genpath('../Test Set'));
addpath('../intensity normalization');
addpath(genpath('../sfta'));
run('../vlfeat/toolbox/vl_setup');
        
%Get the path name from the image and time and then read in the image.
filename = get_pathv2((pid), (eye), num2str(time), 'original');
img = imread(filename);
img = im2double(img);

%Get the vesselized image for now (need to change to find_vessels at some time)
filename_vessel = get_pathv2(pid, eye, num2str(time), 'vessels');
img_vessel = im2double(imread(filename_vessel));

%Convert the image to gray scale if not already
if(size(img,3) ~= 1)
    img=rgb2gary(img);
end

%Apply a gaussian filter to the image
img = gaussian_filter(img);
[img, ~] = smooth_illum3(img, 0.7);

%Resize the image to a standard size
origy = size(img, 1);
origx = size(img, 2);
img = match_sizing(img, std_img_size, std_img_size);

%Print to the console the output
disp(['ID: ', pid, ' - Time: ', num2str(time)]);

%Load the prediction structs
load('od_classify_svmstruct.mat', 'od_classify_svmstruct');

x=-1;
y=-1;

od_image = zeros(size(img, 1), size(img, 2));


%Get feature vectors for each pixel in image
feature_image_g = get_fv_gabor(img);
feature_image_e = entropyfilt(img,true(9));

feature_image = zeros(size(od_image,1), size(od_image,2), size(feature_image_g,3) + size(feature_image_e,3));

for y=1:size(feature_image, 1)
    for x=1:size(feature_image, 2)
        temp = 1;
        for z1=1:size(feature_image_g,3)
            feature_image(y,x,temp) = feature_image_g(y,x,z1);
            temp = temp + 1;
        end
        for z2=1:size(feature_image_e,3)
            feature_image(y,x,temp) = feature_image_e(y,x,z2);
            temp = temp + 1;
        end
    end
end

%Classify the feature vectors for each pixel
for y=1:size(feature_image, 1)
    temp_rearrange = squeeze(feature_image(y,:,:));
    class_estimates = svmclassify(od_classify_svmstruct, temp_rearrange);
    for x=1:size(feature_image, 2)
        od_image(y,x) = class_estimates(x);
    end
end

%Refine the possibilites of the optic disc
final_od_image = refine_od(od_image, img_vessel);

%Show the overlay of the results
figure(2), imshowpair(final_od_image, img);

%Resize the image to its original size
final_od_image = match_sizing(final_od_image, origx, origy);

end

function other()
number_of_pixels_per_box = 8;
%Divide the image up into equal sized boxes
subimage_size = floor(std_img_size / number_of_pixels_per_box);

if 0
    %This is a window based feature descriptor
    for x=1:subimage_size
        for y=1:subimage_size
            xs = ((x - 1) * number_of_pixels_per_box) + 1;
            xe = xs + number_of_pixels_per_box - 1;

            ys = ((y - 1) * number_of_pixels_per_box) + 1;
            ye = ys + number_of_pixels_per_box - 1;

            if(ye > size(img, 1))
                ye = size(img, 1);
                ys = ye - number_of_pixels_per_box;
            end
            if(xe > size(img, 2))
                xe = size(img, 2);
                xs = xe - number_of_pixels_per_box;
            end

            %Get the original image window
            subimage = img(ys:ye, xs:xe);

            feature_vectors = text_algorithm(subimage);
            grouping = svmclassify(od_classify_svmstruct, feature_vectors);

            for xt=xs:xe
                for yt=ys:ye
                    od_image(yt,xt) = grouping;
                end
            end
        end
    end        
elseif 0
    texture_results = vl_hog(single(img), number_of_pixels_per_box, 'verbose') ;

    for y=1:size(texture_results,1)
        for x=1:size(texture_results,2)
            class_estimates = svmclassify(od_classify_svmstruct, squeeze(texture_results(y,x,:)).');

            od_image(((y-1)*number_of_pixels_per_box)+1:y*number_of_pixels_per_box, ((x-1)*number_of_pixels_per_box)+1:x*number_of_pixels_per_box) = class_estimates;
        end
    end
end
end