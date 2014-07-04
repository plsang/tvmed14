function mfcc_encode_home( exp_ann, algo, version, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   

	set_env;

	if ~exist('algo', 'var'),
		algo = 'rastamat';
	end
	
	codebook_gmm_size = 256;
	
	feat_dim = 39;
	dimred = 0;	% don't use PCA for MFCC
	
	configs = set_global_config();
	logfile = sprintf('%s/%s.log', configs.logdir, mfilename);
	msg = sprintf('Start running %s(%s, %d)', mfilename, exp_ann, dimred);
	logmsg(logfile, msg);
	tic;
	
	video_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST';	% for mfcc 
	fea_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/feature';
	%f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_%s_sorted', sz_pat);
	
	fprintf('Loading basic metadata...\n');
	f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_devel.mat');  % for kinddevel only
	metadata = load(f_metadata, 'metadata');
	metadata = metadata.metadata;
	
	fprintf('Loading metadata...\n');
	medmd_file = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/medmd.mat';
	load(medmd_file, 'MEDMD'); 
	
	train_clips = [MEDMD.EventKit.EK10Ex.clips, MEDMD.EventKit.EK100Ex.clips, MEDMD.EventKit.EK130Ex.clips, MEDMD.EventBG.default.clips];
	train_clips = unique(train_clips);
	
	test_clips = MEDMD.RefTest.KINDREDTEST.clips;
	
	clips = [train_clips, test_clips];
    
	feature_ext_fc = sprintf('mfcc.%s.%s.cb%d.fc', algo, version, codebook_gmm_size);
	
	if dimred > 0,
		feature_ext_fc = sprintf('mfcc.%s.%s.cb%d.fc.pca', algo, version, codebook_gmm_size);
	end
	
	output_dir_fc = sprintf('%s/%s/%s', fea_dir, exp_ann, feature_ext_fc);
    if ~exist(output_dir_fc, 'file'),
        mkdir(output_dir_fc);
    end

	feat_pat = sprintf('mfcc.%s.%s', algo, version);
	
	low_proj = [];
	
	if dimred > 0,
		codebook_gmm_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/%s/data/codebook.gmm.%d.%d.mat', feat_pat, codebook_gmm_size, dimred);
		low_proj_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/%s/data/lowproj.%d.%d.mat', feat_pat, dimred, feat_dim);
		low_proj_ = load(low_proj_file, 'low_proj');
		low_proj = low_proj_.low_proj;
	else
		codebook_gmm_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/%s/data/codebook.gmm.%d.%d.mat', feat_pat, codebook_gmm_size, feat_dim);
		codebook_gmm_ = load(codebook_gmm_file, 'codebook');
		codebook_gmm = codebook_gmm_.codebook;
	end
	
    codebook_gmm_ = load(codebook_gmm_file, 'codebook');
    codebook_gmm = codebook_gmm_.codebook;
	
	if ~exist('start_seg', 'var') || start_seg < 1,
        start_seg = 1;
    end
    
    if ~exist('end_seg', 'var') || end_seg > length(clips),
        end_seg = length(clips);
    end
	
    parfor ii = start_seg:end_seg,
        
		video_id = clips{ii};
	
        video_file = fullfile(video_dir, metadata.(video_id).ldc_pat);
        
		output_fc_file = sprintf('%s/%s/%s.mat', output_dir_fc, fileparts(metadata.(video_id).ldc_pat), video_id);
		
		if exist(output_fc_file, 'file') ,
            fprintf('File [%s] already exist. Skipped!!\n', output_fc_file);
            continue;
        end
        
        fprintf(' [%d --> %d --> %d] Extracting features & Encoding for [%s]...\n', start_seg, ii, end_seg, video_id);
        
		feat = mfcc_extract_features(video_file, algo);
		
		if isempty(feat),
			continue;
		else			    
			code = fc_encode(feat, codebook_gmm, low_proj);	
		end
        
		par_save(output_fc_file, code); 
		
    end
	
	
	elapsed = toc;
	elapsed_str = datestr(datenum(0,0,0,0,0,elapsed),'HH:MM:SS');
	
	msg = sprintf('Finish running %s(%s, %d). Elapsed time: %s', mfilename, exp_ann, dimred, elapsed_str);
	logmsg(logfile, msg);
end

