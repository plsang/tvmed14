function [ output_args ] = densetraj_do_clustering( descriptor, cluster_count, max_features, app_kmeans )
%DO_CLUSTERING Summary of this function goes here
%   Detailed explanation goes here
	if ~exist ('max_features', 'var'),
		max_features = 1000000;
	end
	
	if ~exist ('cluster_count', 'var'),
		cluster_count = 4000;
	end
	
	if ~exist ('app_kmeans', 'var'),
		app_kmeans = 0;
	end
	
	output_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/densetrajectory.%s/data/codebook.kmeans.%d.mat', descriptor, cluster_count);
	if exist(output_file, 'file'),
		fprintf('File [%s] already exists. skipped!\n', output_file);
		return;
	end
	
	selected_feat_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/densetrajectory.%s/data/selected_feats_%d_%d.mat', descriptor, max_features);
    load(selected_feat_file, 'feats');
  
    maxcomps = ceil(cluster_count/4);
    
    if app_kmeans == 1,
        codebook = featpipem.lib.annkmeans(feats, cluster_count, ...
        'verbose', true, 'MaxNumComparisons', maxcomps, ...
        'MaxNumIterations', 150);
    else
        codebook = vl_kmeans(feats, cluster_count, ...
        'verbose', 'algorithm', 'elkan');
    end
	
    save(output_file, 'codebook', '-v7.3');
    
end

