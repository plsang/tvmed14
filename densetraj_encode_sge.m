function [ output_args ] = densetraj_encode_sge( dt_type, exp_ann, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   
   
    % encoding method: fisher vector
	% representation: video-based, (can be extended to segment level)
	% power normalization, which one is the best? alpha = 0.2? 
	
    % setting
    set_env;
    
    %bow_encoding = 1;	
	%fc_encoding = 0;	
	dimred = 128;
	
    video_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST-RSZ';
	fea_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/feature';
	%f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_%s_sorted', sz_pat);
	
	f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_devel.mat');  % for kinddevel only
	
	fprintf('Loading basic metadata...\n');
	metadata = load(f_metadata, 'metadata');
	metadata = metadata.metadata;
	
	fprintf('Loading metadata...\n');
	medmd_file = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/medmd.mat';
	load(medmd_file, 'MEDMD'); 
	
	train_clips = [MEDMD.EventKit.EK10Ex.clips, MEDMD.EventKit.EK100Ex.clips, MEDMD.EventKit.EK130Ex.clips, MEDMD.EventBG.default.clips];
	train_clips = unique(train_clips);
	
	test_clips = MEDMD.RefTest.KINDREDTEST.clips;
	
	clips = [train_clips, test_clips];
	
	codebook_gmm_size = 256;
    
	feature_ext_fc = sprintf('densetrajectory.mbh.cb%d.fc', codebook_gmm_size);
	if dimred > 0,
		feature_ext_fc = sprintf('densetrajectory.mbh.cb%d.fc.pca', codebook_gmm_size);
	end

    output_dir_fc = sprintf('%s/%s/%s/%s', fea_dir, exp_ann, feature_ext_fc);
	
    if ~exist(output_dir_fc, 'file'),
        mkdir(output_dir_fc);
    end
	
	% loading gmm codebook
	
	codebook_gmm_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/densetraj.mbh.%s/data/codebook.gmm.%d.mat', dt_type, codebook_gmm_size);
	low_proj = [];
	
	if dimred > 0,
		codebook_gmm_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/densetraj.mbh.%s/data/codebook.gmm.%d.%d.mat', dt_type, codebook_gmm_size, dimred);
		low_proj_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/densetraj.mbh.%s/data/lowproj.%d.%d.mat', dt_type, dimred, 192);
		low_proj_ = load(low_proj_file, 'low_proj');
		low_proj = low_proj_.low_proj;
	end
    codebook_gmm_ = load(codebook_gmm_file, 'codebook');
    codebook_gmm = codebook_gmm_.codebook;
	
    if start_seg < 1,
        start_seg = 1;
    end
    
    if end_seg > length(clips),
        end_seg = length(clips);
    end
 
    for ii = start_seg:end_seg,
	
		video_id = clips{ii};
	
        video_file = fullfile(video_dir, metadata.(video_id).ldc_pat);
		
		fileparts(metadata.(video_id).ldc_pat);
		
		output_fc_file = sprintf('%s/%s/%s.mat', output_dir_fc, fileparts(metadata.(video_id).ldc_pat), video_id);
		
        if exist(output_fc_file, 'file') ,
            fprintf('File [%s] already exist. Skipped!!\n', output_fc_file);
            continue;
        end
		
        fprintf(' [%d --> %d --> %d] Extracting & Encoding for [%s]...\n', start_seg, ii, end_seg, video_id);
        
        code = densetraj_extract_and_encode(dt_type, video_file, codebook_gmm, low_proj); %important
        
		par_save(output_fc_file, code); 	

    end
    
    %toc
	quit
end

