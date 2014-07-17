function sift_sfv_learn_appearance_model(proj_dir, feat_pat);
	
	set_env;
	
	feat_dim_proj = 80;
	appearance_components = 256;
	
	if ~exist('num_features', 'var'),
		num_features = 1000000;
	end
	
	f_selected_feats = sprintf('%s/feature/bow.codebook.devel/%s/data/selected_feats_%d.mat', ...
		proj_dir, feat_pat, num_features);
		
	if ~exist(f_selected_feats, 'file'),
		error('File %s not found!\n', f_selected_feats);
	end
	
	fprintf('Loading selected features <%s>...\n', f_selected_feats);
	load(f_selected_feats, 'feats');
	
	appearance_subspace = sift_sfv_get_pca(feats);
	
	appearance_projected = sift_sfv_pca_project(feats, appearance_subspace, feat_dim_proj);
	
	parms.appearance_model_filename = sprintf('%s/feature/bow.codebook.devel/%s/data/sfv_appearance_model_%d.mat', ...
		proj_dir, feat_pat, appearance_components);
	
	parms.spatial_model_filename = sprintf('%s/feature/bow.codebook.devel/%s/data/sfv_spatial_model_%d.mat', ...
		proj_dir, feat_pat, appearance_components);
		
	% learn appearance_model (or gmm codebook)
	if ~exist(parms.appearance_model_filename,'file'),
		[w, mu, sigma] = yael_gmm(single(appearance_projected), appearance_components, ...
										  'redo', 10, ...
										  'niter', 20, ...
										  'seed', now);
		
		parms.appearance_model.mix = w';
		parms.appearance_model.M = mu;
		parms.appearance_model.Psi = sigma;
		parms.appearance_model.W = zeros(size(mu,1),0,size(mu,2));
		clear w; clear mu; clear sigma;
		save(parms.appearance_model_filename,'-struct','parms','appearance_model');
	end
	
	% set spatial model
	if ~exist(parms.spatial_model_filename,'file'),
		parms.spatial_components = 1;
		parms.spatial_model = set_spatial_model(parms);
		save(parms.spatial_model_filename,'-struct','parms','spatial_model');
	end
	
	
end