function analyze_fovea(debug)
    
    addpath('..');
    addpath(genpath('../Test Set'))
    addpath('../OD Detection - Chris')

    if ~isdir('./results')
        mkdir('./results');
    end

    results_file = './results/analyze_results.txt';

    %Get the images to include from this list
    fid = fopen('fovea_draw.testing', 'r');
    includes = textscan(fid,'%q %q %d %*[^\n]');
    fclose(fid);

    numimages = size(includes{1}, 1);

    fout = fopen(results_file, 'w');
    
    disp('----------Results----------');
    line = 'Img, Distance';
    fprintf(fout, '%s\n', line);
    
    
    %Run through the images and make sure that they exist
    for k=1:numimages
       pid = char(includes{1}{k});
       eye = char(includes{2}{k});
       time = num2str((includes{3}(k)));
       
       image_exists = get_pathv2(pid, eye, time, 'original');
       if isempty(image_exists)
           error([pid, ' ', eye, ' ', time, 'original not found in XML'])
       else
           disp(image_exists)
       end
       imread(image_exists);
            
       [x,y] = get_fovea(pid, eye, time);
       if isempty(x)
           error([pid, ' ', eye, ' ', time, ' fovea not labeled in XML'])
       end
    end
    disp('All images valid.  Running tests')
    disp('-----------------------------');
    
    distances = zeros(numimages, 1);

    for k=1:numimages
        pid = char(includes{1}{k});
        eye = char(includes{2}{k});
        time = num2str(includes{3}(k));  
        
        %Etimate fovea
        e = cputime;
        [final_od_img, img_vessel, img_angles,~] = find_od(pid, eye, time, 1, 'off');
        if ~any(final_od_img(:))
            continue
        end
        [ x,y,h ] = find_fovea( img_vessel, img_angles, final_od_img, debug );
        t = (cputime - e)/60.0;
        disp(['TOTAL PROCESSING TIME (MIN): ', num2str(t)])
        if x == -1
            %Write error message 
            line = [pid,' ', eye, ' (', time, '), ERROR, -1'];
            disp(line);
            fprintf(fout, '%s\n', line);
            disp('--------------------------------------');
        else
            %Get the user labeled fovea
            [x_fov,y_fov] = get_fovea(pid, eye, time);

            %Show location on original image
            original_path = get_pathv2(pid,eye,time,'original');
            original_img = im2double(imread(original_path));
            original_img = imresize(original_img, [768 768]);
            if(size(original_img, 3) > 1)
                original_img = rgb2gray(original_img);
            end
            combined_img = display_anatomy( original_img, final_od_img, img_vessel, x, y );
            imwrite(combined_img,['./results/',pid,'_',eye,'_',time,'-processed.tif'], 'tiff');
            
            if debug == 2
                saveas(h,['./results/',pid,'_',eye,'_',time,'-lines.png']);
            end


            %Get some statistics about the quality of the fovea estimation
            distances(k) = sqrt((x-x_fov)^2+(y-y_fov)^2);

           %Write the results from this badboy  
            line = [pid,' ', eye, ' (', time, '), ', num2str(distances(k))];
            disp(line);
            fprintf(fout, '%s\n', line);
            disp('--------------------------------------');
        end
    end
    
    fclose(fout);
end
