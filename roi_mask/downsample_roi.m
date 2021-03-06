function [instance_matrix, label_vector] = downsample_roi(instance_matrix, label_vector)
%Try to get at least 20% positive instances by discarding a certain
    %percentage of negatives
    negative_label = 0;
    positive_label = 1;
    cutoff = 0.2;
    
    %Make this number larger to get more negative samples to be more selective
    %Make this number smaller to get less negative samples to be less selective
    %4 For example get you to 20% positive samples and 80% negative
    numposmulti = 8;
    
    numneg = sum(label_vector==negative_label);
    numpos = sum(label_vector==positive_label);
    if numpos/(numneg+numpos) < cutoff
        numdiscard = numneg - numposmulti*numpos;
        discard_vector = zeros(length(label_vector),1);
        indices = randperm(length(label_vector),length(label_vector));
        discard_count = 0;
        for i = indices
            if label_vector(i) == negative_label 
                discard_vector(i) = 1;
                discard_count = discard_count + 1;

            end
            if discard_count == numdiscard
                break
            end
        end
        discard_vector = logical(discard_vector);
        label_vector(discard_vector) = [];
        instance_matrix(discard_vector,:) = [];
    end
    disp(sum(label_vector==positive_label)/numel(label_vector))
end