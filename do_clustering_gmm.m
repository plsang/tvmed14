function codebook = do_clustering_gmm(proj_dir, feat_pat, dimred, num_features, cluster_count, GMM_init)
%DO_CLUSTERING Summary of this function goes here
%   Detailed explanation goes here
	
	% proj_dir = '/net/per610a/export/das11f/plsang/ucf101'
	set_env;
	
    % ann kmeans parameters
    cluster_count = 256;
    %%maxcomps = ceil(cluster_count/4);
	maxcomps = 0;

	if ~exist('dimred', 'var'),
		dimred = 0;
	end
	
	if ~exist('num_features', 'var'),
		num_features = 1000000;
	end
	
	if ~exist('cluster_count', 'var'),
		cluster_count = 256;
	end
	
	if ~exist('GMM_init', 'var'),
		GMM_init = 'kmeans';
	end
	
	f_selected_feats = sprintf('%s/feature/bow.codebook.devel/%s/data/selected_feats_%d.mat', ...
		proj_dir, feat_pat, num_features);
		
	if ~exist(f_selected_feats, 'file'),
		error('File %s not found!\n', f_selected_feats);
	end
	
	fprintf('Loading selected features <%s>...\n', f_selected_feats);
	load(f_selected_feats, 'feats');
	
	feats = single(feats);
	
	feat_dim = size(feats, 1);
	
	f_low_proj_matrix = sprintf('%s/feature/bow.codebook.devel/%s/data/lowproj.%d.%d.mat', ...
		proj_dir, feat_pat, dimred, feat_dim);
	
	low_proj = [];
	if dimred > 0,
		if exist(f_low_proj_matrix, 'file'),
			fprintf('Loading pca matrix...!\n');	
			load(f_low_proj_matrix, 'low_proj');
		else
			fprintf('Calculating pca matrix...!\n');	
			low_proj = princomp(feats');
			low_proj = low_proj(:, 1:dimred)';
			fprintf('Saving pca matrix...!\n');	
			save(f_low_proj_matrix, 'low_proj');
		end
	end
	
	if ~isempty(low_proj),
		fprintf('Applying pca matrix ...\n');
		feats = low_proj * feats;
		feat_dim = size(feats, 1);
	end
	
	output_file = sprintf('%s/feature/bow.codebook.devel/%s/data/codebook.gmm.%d.%d.mat', ...
		proj_dir, feat_pat, cluster_count, feat_dim);
		
	if exist(output_file),
		fprintf('File [%s] already exist. skipped!\n', output_file);
		return;
	end
	
	feats = single(feats);
	if isequal(GMM_init, 'kmeans')
		
		fprintf('Computing initial means using K-means...\n');

		% if maxcomps is below 1, then use exact kmeans, else use approximate
		% kmeans with maxcomps number of comparisons for distances
		if maxcomps < 1
			init_mean = vl_kmeans(feats, cluster_count, ...
				'verbose', 'algorithm', 'elkan');
		else
			init_mean = featpipem.lib.annkmeans(feats, cluster_count, ...
				'verbose', false, 'MaxNumComparisons', maxcomps, ...
				'MaxNumIterations', 100);
		end
		
		fprintf('Computing initial variances and coefficients...\n');

		% compute hard assignments
		kd_tree = vl_kdtreebuild(init_mean, 'numTrees', 3) ;
		assign = vl_kdtreequery(kd_tree, init_mean, feats);

		% mixing coefficients
		init_coef = single(vl_binsum(zeros(cluster_count, 1), 1, double(assign)));
		init_coef = init_coef / sum(init_coef);

		% variances
		init_var = zeros(size(feats, 1), cluster_count, 'single');

		for i = 1:cluster_count
			feats_cluster = feats(:, assign == i);
			init_var(:, i) = var(feats_cluster, 0, 2);
		end
		
	elseif isequal(GMM_init, 'rand')
		init_mean = [];
		init_var = [];
		init_coef = [];
	end
    
	
	fprintf('Clustering features using GMM...\n');

	% call FMM mex
	gmm_params = struct;

	if ~isempty(init_mean) && ~isempty(init_var) && ~isempty(init_coef)
		codebook = mexGmmTrainSP(feats, cluster_count, gmm_params, init_mean, init_var, init_coef);
	else
		codebook = mexGmmTrainSP(feats, cluster_count, gmm_params);
	end

	fprintf('Done training codebook!\n');
	
    save(output_file, 'codebook', '-v7.3');
    
end

