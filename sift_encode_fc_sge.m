function sift_encode_fc_sge( proj_name, exp_ann, sift_algo, param, codebook_size, dimred, spm, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   

	% update: Jun 25th, SPM suported
    % setting
    set_env;
	
	if ~exist('version', 'var'),
		version = 'v14.1.1';  %% using both event video + bg video
	end
	
    % encoding type
    enc_type = 'fisher';
	
	f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_devel.mat');  % for kinddevel only
	fprintf('Loading basic metadata...\n');
	metadata = load(f_metadata, 'metadata');
	metadata = metadata.metadata;
	
	configs = set_global_config();
	logfile = sprintf('%s/%s.log', configs.logdir, mfilename);
	msg = sprintf('Start running %s(%s, %s, %s, %s, %d, %d, %d, %d, %d)', mfilename, proj_name, exp_ann, sift_algo, param, codebook_size, dimred, spm, start_seg, end_seg);
	logmsg(logfile, msg);
	change_perm(logfile);
	tic;
	
	if ~exist('codebook_size', 'var'),
		codebook_size = 256;
	end
    
	if ~exist('spm', 'var'),
		spm = 0;
	end
	
	default_dim = 128;
	if ~exist('dimred', 'var'),
		dimred = 80;
	end
	
	feat_pat = sprintf('%s.%s.%s.sift', sift_algo, num2str(param), version);
	feature_ext = sprintf('%s.cb%d.%s', feat_pat, codebook_size, enc_type);
	if spm > 0,
		feature_ext = sprintf('%s.spm', feature_ext);
	end
	
	if dimred < default_dim,,
		feature_ext = sprintf('%s.pca', feature_ext);
	end
	
	output_dir = sprintf('/net/per610a/export/das11f/plsang/%s/feature/%s/%s', proj_name, exp_ann, feature_ext);
    if ~exist(output_dir, 'file'),
		mkdir(output_dir);
		change_perm(output_dir);
    end
    
    codebook_file = sprintf('/net/per610a/export/das11f/plsang/%s/feature/bow.codebook.devel/%s/data/codebook.gmm.%d.%d.mat', ...
		proj_name, feat_pat, codebook_size, dimred);
		
	fprintf('Loading codebook [%s]...\n', codebook_file);
    codebook_ = load(codebook_file, 'codebook');
    codebook = codebook_.codebook;
 
 	low_proj = [];
	if dimred < default_dim,
		lowproj_file = sprintf('/net/per610a/export/das11f/plsang/%s/feature/bow.codebook.devel/%s/data/lowproj.%d.%d.mat', ...
			proj_name, feat_pat, dimred, default_dim);
			
		fprintf('Loading low projection matrix [%s]...\n', lowproj_file);
		low_proj_ = load(lowproj_file, 'low_proj');
		low_proj = low_proj_.low_proj;
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
			
			[frames, descrs] = sift_extract_features( img_path, sift_algo, param );
            
            % if more than 50% of points are empty --> possibley empty image
            if isempty(descrs) || sum(all(descrs == 0, 1)) > 0.5*size(descrs, 2),
                %warning('Maybe blank image...[%s]. Skipped!\n', img_name);
                continue;
            end
			
			code_ = sift_do_encoding(enc_type, descrs, codebook, [], low_proj);
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
	msg = sprintf('Finish running %s(%s, %s, %s, %s, %d, %d, %d, %d, %d). Elapsed time: %s', mfilename, proj_name, exp_ann, sift_algo, param, codebook_size, dimred, spm, start_seg, end_seg, elapsed_str);
	logmsg(logfile, msg);
	
    %toc
    quit;

end