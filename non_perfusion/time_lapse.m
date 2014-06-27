function time_lapse(pid, eye, varargin)
    debug = -1;
    if length(varargin) == 1
        debug = varargin{1};
    elseif isempty(varargin)
        debug = 1;
    else
        throw(MException('MATLAB:paramAmbiguous','Incorrect number of input arugments'));
    end
    
    %Add the location of the get_path script
    addpath('..');
    addpath(genpath('../Test Set'));
    addpath('../roi_mask');
    
    %Test to make sure that all the appropiate images are available
    disp('----------Checking Files---------');
    roi_mask = zeros(1);
    image_times = [];
    try
        cur_time = 1;
        while true
            %Convert integer to string to search XML
            time_string = num2str(cur_time);
            
            %Check to see that the path to the image is readable
            the_path = get_pathv2(pid, eye, time_string, 'registered');
            img = imread(the_path);
            
            %If this is the first image in the set then initialized the output variable
            if(cur_time == 1)
                roi_mask = ones(size(img,1), size(img,2));
            end
            
            %Get the roi mask for the current image
            cur_mask  = find_roi(pid, eye, time_string, 'registered', 1);
            
            %And the roi mask for the current image with the running roi mask
            roi_mask = roi_mask & cur_mask;
            
            %Save the current time to output array
            image_times = [image_times, cur_time];
            
            %look for the next image in the set
            cur_time = cur_time + 1;
        end
    catch
        disp(['Found ', num2str(size(image_times,2)), ' images in this set!']);
    end
    disp('-------Done Checking Files-------');
    
    if(debug == 2)
        figure, imshow(roi_mask);
    end
    
    %Output results
    final_graph = double(zeros(size(roi_mask,1), size(roi_mask,2), size(image_times,2)));
    
    if(debug == 2)
        %Video writer for time lapse of intensity
        uncompressedVideo = VideoWriter([pid, '_', eye, '.avi'], 'Uncompressed AVI');
        uncompressedVideo.FrameRate = 1;
        open(uncompressedVideo);
    end
    
    %Iterate over the files
    for k=1:size(image_times, 2)
        try
            %Get the current time
            time_str = num2str(image_times(1,k));

            %Check to see that the path to the image is readable
            the_path = get_pathv2(pid, eye, time_str, 'registered');
            img = imread(the_path);
            if(size(img,3) > 1)
                img = rgb2gray(img);
            end
            
            %Get the intensities over time
            for y=1:size(img,1)
                for x=1:size(img,2)
                    if(roi_mask(y,x) == 1)
                        final_graph(y,x,k) = img(y,x);
                    end
                end
            end
            
            if(debug == 2)
                %Color the image into a heatmap
                heatmap = ind2rgb(squeeze(final_graph(:,:,k)), jet(256));
            
                %Write the heatmap to an output video stream
                writeVideo(uncompressedVideo, heatmap);
            end
        catch E
            error(E.message);
        end
    end
        
    if(debug == 2)
        %Close the output video
        close(uncompressedVideo);
    end
end