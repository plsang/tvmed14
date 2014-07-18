function sift_encode_fc_sge( proj_name, exp_ann, sift_algo, param, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   

	% update: Jun 25th, SPM suported
    % setting
    set_env;
	
	if ~exist('version', 'var'),
		version = 'v14.3';  %% using both event video + bg video
	end
	
	%% parameters for Spatial FV
	parms.feat_dim_orig = 128;
	parms.feat_dim_proj = 80;
	parms.appearance_components = 256;
	parms.spatial_components = '1';
	
	d = 2;
	D = parms.feat_dim_proj;
	C = str2num(parms.spatial_components);
	K = parms.appearance_components;
	parms.imagevec_function = @get_asfv;
    parms.imagevec_dim = K * (1 + 2 * D + C * (1 + 2 * d));
	
	
    % encoding type
    enc_type = 'fisher';
	
	f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_devel.mat');  % for kinddevel only
	fprintf('Loading basic metadata...\n');
	metadata = load(f_metadata, 'metadata');
	metadata = metadata.metadata;
	
	configs = set_global_config();
	logfile = sprintf('%s/%s.log', configs.logdir, mfilename);
	msg = sprintf('Start running %s(%s, %s, %s, %s, %d, %d, %d, %d, %d)', mfilename, proj_name, exp_ann, sift_algo, param, start_seg, end_seg);
	logmsg(logfile, msg);
	change_perm(logfile);
	tic;
	
	proj_root_dir = '/net/per610a/export/das11f/plsang';
	proj_dir = sprintf('%s/%s', proj_root_dir, proj_name);
	
	feat_pat = sprintf('%s.%s.%s.sift', sift_algo, num2str(param), version);
	feature_ext = sprintf('%s.cb%d.%s', feat_pat, parms.appearance_components, enc_type);
	
	
	parms.appearance_subspace_filename = sprintf('%s/feature/bow.codebook.devel/%s/data/sfv_appearance_subspace_%d.mat', ...
		proj_dir, feat_pat, parms.appearance_components);
		
	parms.appearance_model_filename = sprintf('%s/feature/bow.codebook.devel/%s/data/sfv_appearance_model_%d.mat', ...
		proj_dir, feat_pat, parms.appearance_components);
	
	parms.spatial_model_filename = sprintf('%s/feature/bow.codebook.devel/%s/data/sfv_spatial_model_%d.mat', ...
		proj_dir, feat_pat, parms.appearance_components);
	
	parms.normalizer_filename = sprintf('%s/feature/bow.codebook.devel/%s/data/sfv_normalizer_%d.mat', ...
		proj_dir, feat_pat, parms.appearance_components);	
		
	% load low proj
	if ~exist(parms.appearance_subspace_filename,'file'),
		error();
	else
		fprintf('Loading cached appearance subspace from %s\n', parms.appearance_subspace_filename);
		tmp = load(parms.appearance_subspace_filename);
		parms.appearance_subspace = tmp.appearance_subspace;
		clear tmp;
	end
	
	% load appearance_model (or gmm codebook)
	if ~exist(parms.appearance_model_filename,'file'),
		error();
	else
		fprintf('Loading cached appearance model from <%s>\n', parms.appearance_model_filename);
        tmp = load(parms.appearance_model_filename);
        parms.appearance_model = tmp.appearance_model;
        clear tmp;
	end
	
	% set spatial model
	if ~exist(parms.spatial_model_filename,'file'),
		error();
	else
		fprintf('Loading cached spatial model from %s\n', parms.spatial_model_filename);
        tmp = load(parms.spatial_model_filename);
        parms.spatial_model = tmp.spatial_model;
        clear tmp;
	end
	
	if ~exist(parms.normalizer_filename,'file'),
		error();
	else
		fprintf('Loading cached normalizer from %s\n', parms.normalizer_filename);
		tmp = load(parms.normalizer_filename);
		parms.normalizer = tmp.normalizer;
		clear tmp;
	end   
	
	if parms.feat_dim_proj < parms.feat_dim_orig,,
		feature_ext = sprintf('%s.pca', feature_ext);
	end
	
	output_dir = sprintf('/net/per610a/export/das11f/plsang/%s/feature/%s/%s', proj_name, exp_ann, feature_ext);
    if ~exist(output_dir, 'file'),
		mkdir(output_dir);
		change_perm(output_dir);
    end
 
	fprintf('Loading metadata...\n');
	medmd_file = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/medmd.mat';
	load(medmd_file, 'MEDMD'); 
	
	train_clips = [MEDMD.EventKit.EK10Ex.clips, MEDMD.EventKit.EK100Ex.clips, MEDMD.EventKit.EK130Ex.clips, MEDMD.EventBG.default.clips];
	%train_clips = [MEDMD.EventKit.EK130Ex.clips, MEDMD.EventBG.default.clips];
	train_clips = unique(train_clips);
	
	test_clips = MEDMD.RefTest.KINDREDTEST.clips;
	
	clips = [train_clips, test_clips];
    
    if ~exist('start_seg', 'var') || start_seg < 1,
        start_seg = 1;
    end
    
    if ~exist('end_seg', 'var') || end_seg > length(clips),
        end_seg = length(clips);
    end
    
    %tic
	
    kf_dir = sprintf('/net/per610a/export/das11f/plsang/%s/keyframes', proj_name);
    
    for ii = start_seg:end_seg,
        video_id = clips{ii};                 
        
		output_file = sprintf('%s/%s/%s.mat', output_dir, fileparts(metadata.(video_id).ldc_pat), video_id);
		
        if exist(output_file, 'file'),
            fprintf('File [%s] already exist. Skipped!!\n', output_file);
            continue;
        end
        
		video_kf_dir = fullfile(kf_dir, metadata.(video_id).ldc_pat);
		video_kf_dir = video_kf_dir(1:end-4);
		kfs = dir([video_kf_dir, '/*.jpg']);
       
		%% update Jul 5, 2013: support segment-based
		
		fprintf(' [%d --> %d --> %d] Extracting & encoding for [%s - %d kfs]...\n', start_seg, ii, end_seg, video_id, length(kfs));
        
		code = cell(length(kfs), 1);
		
		for jj = 1:length(kfs),
			if ~mod(jj, 10),
				fprintf('%d ', jj);
			end
			img_name = kfs(jj).name;
			img_path = fullfile(video_kf_dir, img_name);
			
			[f, d, image_size] = sift_extract_features( img_path, sift_algo, param );
            
            % if more than 50% of points are empty --> possibley empty image
            if isempty(d) || sum(all(d == 0, 1)) > 0.5*size(d, 2),
                %warning('Maybe blank image...[%s]. Skipped!\n', img_name);
                continue;
            end
			
			data.d = d;
            data.f = f;
            n_features = size(data.d, 2);
            data.d = double(data.d);            
            data_sq = (data.d).^2;
            zerovec_indices = find(sum(data_sq)==0);
            nonzerovec_indices = find(sum(data_sq)~=0);
            data.d(:,nonzerovec_indices) = bsxfun(@rdivide, data.d(:,nonzerovec_indices), sqrt(sum(data_sq(:,nonzerovec_indices))));
            if ~isempty(zerovec_indices),
               data.d(:,zerovec_indices) = zeros(parms.feat_dim_orig, length(zerovec_indices));     
            end 
            data.f = data.f(1:2,:) ./ (image_size' * ones(1,n_features));
			
			%code_ = sift_do_encoding(enc_type, descrs, codebook, [], low_proj);
			appearance_projected = sift_sfv_pca_project(data.d, parms.appearance_subspace, parms.feat_dim_proj);
			code_ = parms.imagevec_function(data.f, appearance_projected, parms.appearance_model, parms.spatial_model, parms.normalizer);
			
			% apply power normalization
			code_ = sign(code_) .* sqrt(abs(code_));
		
			code{jj} = code_;	
		end 
        
		code = cat(2, code{:});
		code = mean(code, 2);
		
		% apply power normalization again
		code = sign(code) .* sqrt(abs(code));
		
        par_save(output_file, code, 1); % MATLAB don't allow to save inside parfor loop             
		%change_perm(output_file);
        
    end
    
	elapsed = toc;
	elapsed_str = datestr(datenum(0,0,0,0,0,elapsed),'HH:MM:SS');
	msg = sprintf('Finish running %s(%s, %s, %s, %s, %d, %d, %d, %d, %d). Elapsed time: %s', mfilename, proj_name, exp_ann, sift_algo, param, start_seg, end_seg, elapsed_str);
	logmsg(logfile, msg);
	
    %toc
    quit;

end