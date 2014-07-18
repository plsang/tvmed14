function sift_sfv_learn_appearance_model(proj_dir, feat_pat);
	
	set_env;
	
	parms.feat_dim_proj = 80;
	parms.appearance_components = 256;
	parms.spatial_components = '1';
	
	d = 2;
	D = parms.feat_dim_proj;
	C = str2num(parms.spatial_components);
	K = parms.appearance_components;
	
	parms.imagevec_function = @get_asfv;
    parms.imagevec_dim = K * (1 + 2 * D + C * (1 + 2 * d));
			
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
	
	f_selected_positions = sprintf('%s/feature/bow.codebook.devel/%s/data/selected_positions_%d.mat', ...
		proj_dir, feat_pat, num_features);
	
	if ~exist(f_selected_positions, 'file'),
		error('File %s not found!\n', f_selected_positions);
	end
	
	fprintf('Loading selected positions <%s>...\n', f_selected_positions);
	load(f_selected_positions, 'positions');
	
	parms.appearance_subspace_filename = sprintf('%s/feature/bow.codebook.devel/%s/data/sfv_appearance_subspace_%d.mat', ...
		proj_dir, feat_pat, parms.appearance_components);
		
	parms.appearance_model_filename = sprintf('%s/feature/bow.codebook.devel/%s/data/sfv_appearance_model_%d.mat', ...
		proj_dir, feat_pat, parms.appearance_components);
	
	parms.spatial_model_filename = sprintf('%s/feature/bow.codebook.devel/%s/data/sfv_spatial_model_%d.mat', ...
		proj_dir, feat_pat, parms.appearance_components);
	
	parms.normalizer_filename = sprintf('%s/feature/bow.codebook.devel/%s/data/sfv_normalizer_%d.mat', ...
		proj_dir, feat_pat, parms.appearance_components);	
		
	if ~exist(parms.appearance_subspace_filename,'file'),
		parms.appearance_subspace = sift_sfv_get_pca(feats);
		save(parms.appearance_subspace_filename,'-struct','parms','appearance_subspace');
	else
		fprintf('Loading cached normalizer from %s\n', parms.appearance_subspace_filename);
		tmp = load(parms.appearance_subspace_filename);
		parms.appearance_subspace = tmp.appearance_subspace;
		clear tmp;
	end
	
	parms.appearance_projected = sift_sfv_pca_project(feats, parms.appearance_subspace, parms.feat_dim_proj);
	
	% learn appearance_model (or gmm codebook)
	if ~exist(parms.appearance_model_filename,'file'),
		[w, mu, sigma] = yael_gmm(single(parms.appearance_projected), parms.appearance_components, ...
										  'redo', 10, ...
										  'niter', 100, ...
										  'seed', now);
		
		parms.appearance_model.mix = w';
		parms.appearance_model.M = mu;
		parms.appearance_model.Psi = sigma;
		parms.appearance_model.W = zeros(size(mu,1),0,size(mu,2));
		clear w; clear mu; clear sigma;
		save(parms.appearance_model_filename,'-struct','parms','appearance_model');
	else
		fprintf('Loading cached appearance model from <%s>\n', parms.appearance_model_filename);
        tmp = load(parms.appearance_model_filename);
        parms.appearance_model = tmp.appearance_model;
        clear tmp;
	end
	
	% set spatial model
	if ~exist(parms.spatial_model_filename,'file'),
		parms.spatial_model = set_spatial_model(parms);
		save(parms.spatial_model_filename,'-struct','parms','spatial_model');
	else
		fprintf('Loading cached spatial model from %s\n', parms.spatial_model_filename);
        tmp = load(parms.spatial_model_filename);
        parms.spatial_model = tmp.spatial_model;
        clear tmp;
	end
	
	% learn normalizer
	
	if (exist(parms.normalizer_filename,'file'))
		fprintf('Loading cached normalizer from %s\n', parms.normalizer_filename);
		tmp = load(parms.normalizer_filename);
		parms.normalizer = tmp.normalizer;
		clear tmp;
	else       
		%parms = sample_training_features(parms);               
		parms.normalizer = [];
		parms.normalizer = parms.imagevec_function(positions, parms.appearance_projected, parms.appearance_model, parms.spatial_model, parms.normalizer);
		parms.normalizer.additive = -parms.normalizer.additive; % we need to subtract the mean vector
		parms.normalizer = parms.imagevec_function(positions, parms.appearance_projected, parms.appearance_model, parms.spatial_model, parms.normalizer);
		save(parms.normalizer_filename,'-struct','parms','normalizer');
	end
	
end