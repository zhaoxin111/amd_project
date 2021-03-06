function [ data ] = compare_maculas()
% Process Image

    % Create a struct for the curve data
    data = struct(...
                  'HPRS', [], ...
                  'HPOS', [], ...
                  'MAQ',  [] ...
                 );

    %~~~Get images~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    % If an images directory exists, look there first
    path = set_path('./Images/','*.tif');

    % Open dialog box to select file
    [image_filename1,image_pathname1] = uigetfile(path, 'Select Image to Process');
    fullpath = fullfile(image_pathname1,image_filename1);
    
    % Read the image
    imgRGB=imread(fullpath);
    RGB_test=size(size(imgRGB));
    if(RGB_test(2)==3)
        img1=rgb2gray(imgRGB);
    else
        img1=imgRGB;
    end
    
    % Crop footer
    img1 = crop_footer(img1);
    % Store the size/dimensions of the image
    img_sz1 = size(img1);
         
    % Ask for input points
    figure('Name', image_filename1);
    imshow(img1);
    %uiwait(msgbox('Please click on fovea', '','modal')); 
    p = struct('fovea1', [], 'optic_disk1', [], 'bifur1', [], 'fovea2', [], 'optic_disk2', [], 'bifur2', []);
    p.fovea1 = round(ginput(1));
    %uiwait(msgbox('Please click on optic disk','', 'modal'));
    p.optic_disk1 = round(ginput(1));
    p.bifur1 = round(ginput(1));

    
    
    %~~~Get second image~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    % If an images directory exists, look there first
    path = set_path('./Images/','*.tif');

    % Open dialog box to select file
    [image_filename2,image_pathname2] = uigetfile(path, 'Select Image to Compare');
    img_path = fullfile(image_pathname2,image_filename2);
    
    % Read the image
    imgRGB=imread(img_path);
    RGB_test=size(size(imgRGB));
    if(RGB_test(2)==3)
        img2=rgb2gray(imgRGB);
    else
        img2=imgRGB;
    end
    
    % Crop footer
    img2 = crop_footer(img2);
    
     % Store the size of the image
    img_sz2 = size(img2);
        
    
   % Ask for input points
    figure('Name', image_filename2);
    imshow(img2);
    %uiwait(msgbox('Please click on fovea', '','modal')); 
    p.fovea2 = round(ginput(1));
    %uiwait(msgbox('Please click on optic disk','', 'modal'));
    p.optic_disk2 = round(ginput(1));
    p.bifur1= round(ginput(1));

    
    %~~~~~~~~~~~Image Processing~~~~~~~~~~~~~~~~~~~ 
    
    % Run gaussian filter
     r1 = round(10/770*img_sz1(1)); %scale filter size---10 by 10 pixs for 768 by 770 res (standard res - footer)
     c1 = round(10/768*img_sz1(2));
     
     H = fspecial('gaussian', [r1 c1], 5);
     proc1=imfilter(img1,H);
    
     r2 = round(10/770*img_sz2(1)); %scale filter size---10 by 10 pixs for 768 by 770 res (standard res - footer)
     c2 = round(10/768*img_sz2(2));
     
     H = fspecial('gaussian', [r2 c2], 5);
     proc2=imfilter(img2,H);
    
    %Scale intensity of img2 to img1
     proc2 = scale_intensities(proc1, p.fovea1, p.optic_disk1, proc2, p.fovea2, p.optic_disk2);
    
     % Adjust contrasts/center pix distriution on mean intensity of ring between
     % macula and optic disk
     
     % create ring mask
     [xgrd1, ygrd1] = meshgrid(1:img_sz1(2), 1:img_sz1(1));   
      x1 = xgrd1 - p.fovea1(1);    % offset the origin
      y1 = ygrd1 - p.fovea1(2);
     ro= sqrt((p.optic_disk1(1)-p.fovea1(1))^2+(p.optic_disk1(2)-p.fovea1(2))^2);
     ri = sqrt((p.optic_disk1(1)-p.fovea1(1))^2+(p.optic_disk1(2)-p.fovea1(2))^2)*.5;
     ob = x1.^2 + y1.^2 <= ro.^2; %outer bound   
     ib = x1.^2 + y1.^2 >= ri.^2; %inner bound
     ring = logical(ib.*ob);
      rep1 = mean(proc1(ring));
      if rep1 < 64
          gamma1 = 0.5;
      elseif rep1 >= 64 && rep1 < 96
          gamma1 = 0.75;
      elseif rep1 >=96 && rep1 < 160
          gamma1 = 1.0;
      elseif rep1 >= 160 && rep1 < 192
          gamma1 = 1.25;
      elseif rep1 >=192
          gamma1 = 1.5;
      end

      
       proc1 = imadjust(proc1,[],[],gamma1);

       
      [xgrd2, ygrd2] = meshgrid(1:img_sz2(2), 1:img_sz2(1));   
      x2 = xgrd2 - p.fovea2(1);    % offset the origin
      y2 = ygrd2- p.fovea2(2);
      ro= sqrt((p.optic_disk2(1)-p.fovea2(1))^2+(p.optic_disk2(2)-p.fovea2(2))^2);
      ri = sqrt((p.optic_disk2(1)-p.fovea2(1))^2+(p.optic_disk2(2)-p.fovea2(2))^2)*.5;
      ob = x2.^2 + y2.^2 <= ro.^2; %outer bound   
      ib = x2.^2 + y2.^2 >= ri.^2; %inner bound
      ring = logical(ib.*ob);
       rep2 = mean(proc2(ring));
      if rep2 < 64
          gamma2 = 0.5;
      elseif rep2 >= 64 && rep1 < 96
          gamma2 = 0.75;
      elseif rep2 >=96 && rep1 < 160
          gamma2 = 1.0;
      elseif rep2 >= 160 && rep1 < 192
          gamma2 = 1.25;
      elseif rep2 >=192
          gamma2 = 1.5;
      end
      

      
      proc2 = imadjust(proc2,[],[],gamma2);

      
    % Create a figure for the images before and after processing
    figure('Name','Processing Results');
    subplot(2,2,1);
    imshow(img1); title(strcat('Original', image_filename1));
    subplot(2,2,2);
    imshow(proc1); title(strcat('Processed', image_filename1));
    subplot(2,2,3);
    imshow(img2); title(strcat('Original', image_filename2));
    subplot(2,2,4);
    imshow(proc2); title(strcat('Processed', image_filename2));
    
       
%     %~~~~~~~~Determine Thresholds for MAQ calculation~~~~~~~~~~~
%     % Create circle mask to ignore macula
%     r=sqrt((p.optic_disk1(1)-p.fovea1(1))^2+(p.optic_disk1(2)-p.fovea1(2))^2)/2;
%     circlemask = x1.^2 + y1.^2 <= r.^2;
%     
%     % Get standard deviation of pixel inensity outside macula for img1
%     periph = double(proc1(~circlemask));
%     hypr_thrsh = 1*std(periph(:));
%     hypo_thrsh = -1*std(periph(:));

   %~~~~~~~~~~~~~~Analyze Maculas~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
   %Create macular window 1
       lbound = p.fovea1(1) - round(abs(p.fovea1(1) - p.optic_disk1(1))*.5);
       rbound = p.fovea1(1) + round(abs(p.fovea1(1) - p.optic_disk1(1))*.5);
       if lbound < 1
           lbound = 1;
       end
       if rbound > img_sz1(2)
           rbound = img_sz1(2);
       end
       width = lbound : rbound;
      
       bbound = p.fovea1(2) + round(abs(p.fovea1(1) - p.optic_disk1(1))*.5);
       tbound = p.fovea1(2) - round(abs(p.fovea1(1) - p.optic_disk1(1))*.5);
       if tbound < 1 
           tbound = 1;
       end
       if bbound > img_sz1(1)
           bbound = img_sz1(1);
       end
       height =  tbound : bbound;

   win1 = proc1(height,width);
   sz1 = size(win1);
  
    %Create macular window 2
       lbound = p.fovea2(1) - round(abs(p.fovea2(1) - p.optic_disk2(1))*.5);
       rbound = p.fovea2(1) + round(abs(p.fovea2(1) - p.optic_disk2(1))*.5);
       if lbound < 1
           lbound = 1;
       end
       if rbound > img_sz2(2)
           rbound = img_sz2(2);
       end
       width = lbound : rbound;
      
       bbound = p.fovea2(2) + round(abs(p.fovea2(1) - p.optic_disk2(1))*.5);
       tbound = p.fovea2(2) - round(abs(p.fovea2(1) - p.optic_disk2(1))*.5);
       if tbound < 1 
           tbound = 1;
       end
       if bbound > img_sz2(1)
           bbound = img_sz2(1);
       end
       height =  tbound : bbound;

       win2 = proc2(height,width);
       sz2 = size(win2);
%        
%        win2= contrast_stretch(win2, mean2(win2), 2);
%        win1 = contrast_stretch(win1,mean2(win1),2);
       

    %Call Nate's function

    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~       
     % Show maculas
    figure('Name', 'Areas of Interest');
    subplot(1,2,1);
    colormap(gray), imagesc(win2); 
    subplot(1,2,2);
    colormap(gray), imagesc(win1);
    
    % Show surfaces
    figure('Name', '3D Surfaces');
    subplot(1,2,1);   
    surf(fliplr(double(win2)),'EdgeColor', 'none'); 
    title(strcat('Previous Visit: ',image_filename2)); 
    view(153, 78);
    subplot(1,2,2);
    surf(fliplr(double(win1)),'EdgeColor', 'none');   
    title(strcat('Current Visit:',image_filename1));
    view(153, 78);
    
   
    %~~~~Show Disease Progress~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    
      
    figure('Name', 'Macular Comparison');
    subplot(2,2,1);
    imshow(win2); title('Previous Visit');
    subplot(2,2,2);
   imshow(win1); title('Current Visit');
    subplot(2,2,3);
    imshow(win1); title('Progression');
    h5=gca;

    
    %Calculate MAQ
    win_avg1 = zeros(50,50);
    win_avg2 = zeros(50,50);
    xln1 = sz1(2)/50; %create 50 by 50 grid
    yln1 = sz1(1)/50;
    xln2 = sz2(2)/50;
    yln2 = sz2(1)/50;
    m=1;
    for i = 1:yln1:sz1(1)-yln1+1
        k=1; 
         for j = 1:xln1:sz1(2)-xln1+1
            bloc = win1(round(i):round(i+yln1)-1, round(j):round(j+xln1)-1);
            win_avg1(m,k)  = mean2(bloc);
            k=k+1;
        end
        m=m+1;
    end
       m=1;
    for i = 1:yln2:sz2(1)-yln2+1
        k=1; 
         for j = 1:xln2:sz2(2)-xln2+1
            bloc = win2(round(i):round(i+yln2)-1, round(j):round(j+xln2)-1);
            win_avg2(m,k)  = mean2(bloc);
            k=k+1;
        end
        m=m+1;
    end
    
    DWB = win_avg1 - win_avg2;
    data.HPOS = sum(sum(DWB(DWB<0)));
    data.HPRS = sum(sum(DWB(DWB>0)));
    data.MAQ = sum(sum(DWB));
    
    hypr_thrsh = std(DWB(:))
    hypo_thrsh = -std(DWB(:))       
    
     %Show gridlines for MAQ calculation
    hold(h5);
    for k = 0.5:yln1:sz1(1)-rem(sz1(1),yln1)+0.5
    x = [0.5 sz1(2)+0.5];
    y = [k k];
    plot(h5,x,y,'Color','k','LineStyle','-');
    end

    for k = 0.5:xln1:sz1(2)-rem(sz1(2),xln1)+0.5
    x = [k k];
    y = [0.5 sz1(1)+0.5];
    plot(h5,x,y,'Color','k','LineStyle','-');
    end
    hold off
    
    %~~~~~~~Show changes in hypo/hyper regions~~~~~~~~~~~~~~~~~~~~~~~~~
    
    redx=ones(4,250);
    yellx=ones(4,250);
    redy=ones(4,250);
    yelly=ones(4,250);
 
    
    m = 1; 
    p1 = 1;
    p2 = 1;
    for i = 0.5:yln1:sz1(1)-rem(sz1(1),yln1)-yln1+0.5
        k=1;
        for j = 0.5:xln1:sz1(2)-rem(sz1(2),xln1)-xln1+0.5
         if DWB(m,k) > hypr_thrsh
            yelly(:,p1) = [i;i;i+yln1;i+yln1]; %specify vertices of patches
            yellx(:,p1) = [j;j+xln1;j+xln1;j];
            p1=p1+1;
         elseif DWB(m,k) < hypo_thrsh
            redy(:,p2) = [i;i;i+yln1;i+yln1];
            redx(:,p2) = [j;j+xln1;j+xln1;j];
            p2=p2+1;
         end
         k=k+1;
        end
        m=m+1;
    end

 
   % Remove zeros  
        redx = reshape(redx(redx~=1),4,[]);
        yellx = reshape(yellx(yellx~=1),4,[]);
        redy=reshape(redy(redy~=1),4,[]);
        yelly=reshape(yelly(yelly~=1),4,[]);

   % Fill patches
        hold(h5);
        alpha(patch(redx,redy,'r'),.5); 
        alpha(patch(yellx,yelly,'y'),.5);
        hold off
  
        set(h5, 'Position', [0.27 0.02000 1.5*0.3347 1.5*0.3338]); % Increase size of progression image
        
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    
    fprintf('Results: \n');
    disp(data);
    
    
%     % If a data directory exists, start there to save
%     path = set_path('Data','');
% 
%     % Open dialog box to save the data in the Data directory
%     data_filename = fullfile(path, strrep(image_filename1,'.tif','.mat'));
%     
%     % Store the surfaces into our structure
%     data.surf_new = surf_new;
%     data.surf_old = surf_old;
%     
%     % Save the structure under the filename data_filename
%     save(data_filename,'data');
%     fprintf('Processed Image Data Saved As: \n%s\n', data_filename);


end
