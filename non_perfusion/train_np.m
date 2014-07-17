function train_np()
    addpath(genpath('../liblinear-1.94'))

    t = cputime;
    %Get feaure vectors
    filename = 'np_data.mat';
    data_file = matfile(filename);
    instance_matrix =  data_file.dataset;

    %Disp some informaiton to the user
    e = cputime - t;
    disp(['Time to load features (min): ', num2str(e / 60.0)]);

    %get category for every pixel
    label_vector = data_file.classes;

    %Try to get at least 20% positive instances by discarding a certain
    %percentage of negatives
    numneg = sum(label_vector==0);
    numpos = sum(label_vector==1);
    if numpos/(numneg+numpos) < .2
        numdiscard = numneg - 4*numpos;
        discard_vector = zeros(length(label_vector),1);
        indices = randperm(length(label_vector),length(label_vector));
        discard_count = 0;
        for i = indices
            if label_vector(i) == -1 
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
    
    disp(['Number of Positive Instances: ', num2str(sum(label_vector==1)), ' Number of Negative Instances: ', ... 
        num2str(sum(label_vector==0)), ' Total: ', num2str(numel(label_vector))]);  
    
    %Scale all features to [0 1] (x'=(x-mi)/(Mi-mi))
     %find max and min of each column
    mins = min(instance_matrix);
    maxs = max(instance_matrix);
    scaling_factors = [mins; maxs];
    
    %scale each column
    for i = 1:size(instance_matrix,2)
        instance_matrix(:,i) = (instance_matrix(:,i)-mins(i))/(maxs(i)-mins(i));
    end
         
    t = cputime;
    disp('Building SVM classifier...Please Wait')

	np_combined_classifier =  train(label_vector, sparse(instance_matrix), '-s 2');

    save('np_combined_classifier.mat', 'np_combined_classifier', 'scaling_factors');
    
    %Disp some informaiton to the user
    e = cputime - t;
    disp(['Time to build classifier (min): ', num2str(e / 60.0)]);
     
end