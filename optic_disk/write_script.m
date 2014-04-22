%Takes the output generated by find_vessels for one test image and writes
%output images and stats to results directory and text file, respectively

if ~isdir('./results')
    mkdir('./results');
end

results_file='results.txt';

output_results = zeros(3,8);

imwrite(gabor_bin,['./results/', pid, '-', time '-gabor vessels','.tif'],'tiff');
imwrite(lineop_bin,['./results/', pid, '-', time '-lineop vessels','.tif'],'tiff');
imwrite(combined_bin,['./results/', pid, '-', time '-combined vessels','.tif'],'tiff');

%Calculate some stats about the quality of each pixel classification
output_results(1, :) = determine_stats(gabor_bin, vessel_img);
output_results(2, :) = determine_stats(lineop_bin, vessel_img);
output_results(3, :) = determine_stats(combined_bin, vessel_img);

%Disp to user the results from this badboy

fout = fopen(results_file, 'a');

disp('----------Results----------');
line = 'Img, True Positive, True Negative, False Positive, False Negative, Total Positive Count, Total Negative Count, Accuracy, Precision';
disp(line);
fprintf(fout, '%s', line);

test{1} = 'gabor';
test{2} = 'lineop';
test{3}='combined';


for j = 1:3
    numline = num2str(output_results(j,1));
    for l=2:size(output_results,2)
        numline = [numline, ', ', num2str(output_results(j,l));];
    end

    line = [pid, '(', time, ') - ',test{j}, ' ', numline];
    disp(line);
    %update text file 
    fprintf(fout, '%s\n', line);
end