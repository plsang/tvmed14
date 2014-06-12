function codebook = do_clustering_kmeans(proj_dir, feat_pat, cluster_count, num_features, app_kmeans)
%DO_CLUSTERING Summary of this function goes here
%   Detailed explanation goes here
	
	% proj_dir = '/net/per610a/export/das11f/plsang/ucf101'
	set_env;
	
	if ~exist('num_features', 'var'),
		num_features = 1000000;
	end
	
	if ~exist('cluster_count', 'var'),
		cluster_count = 4000;
	end
	
	if ~exist ('app_kmeans', 'var'),
		app_kmeans = 0;
	end
	
	f_selected_feats = sprintf('%s/feature/bow.codebook.devel/%s/data/selected_feats_%d.mat', ...
		proj_dir, feat_pat, num_features);
		
	if ~exist(f_selected_feats, 'file'),
		error('File %s not found!\n', f_selected_feats);
	end
	
	load(f_selected_feats, 'feats');

	feats = single(feats);
	
	feat_dim = size(feats, 1);
	
	output_file = sprintf('%s/feature/bow.codebook.devel/%s/data/codebook.kmeans.%d.%d.mat', ...
		proj_dir, feat_pat, cluster_count, feat_dim);
		
	if exist(output_file),
		fprintf('File [%s] already exist. skipped!\n', output_file);
		return;
	end
	
    if app_kmeans == 1,
		maxcomps = ceil(cluster_count/4);	
        codebook = featpipem.lib.annkmeans(feats, cluster_count, ...
        'verbose', true, 'MaxNumComparisons', maxcomps, ...
        'MaxNumIterations', 150);
    else
        codebook = vl_kmeans(feats, cluster_count, ...
        'verbose', 'algorithm', 'elkan');
    end
	
	fprintf('Done training codebook!\n');
    save(output_file, 'codebook', '-v7.3'); 
    
end

