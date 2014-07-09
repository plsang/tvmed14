function [ output_args ] = densetraj_encode_sge( descriptor, exp_ann, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   
   
    % encoding method: fisher vector
	% representation: video-based, (can be extended to segment level)
	% power normalization, which one is the best? alpha = 0.2? 
	
    % setting
    set_env;
	dimred = 128;
	
    video_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST-RSZ';
	fea_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/feature';
	
	f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_devel.mat');  % for kinddevel only
	
	fprintf('Loading basic metadata...\n');
	metadata = load(f_metadata, 'metadata');
	metadata = metadata.metadata;
	
	fprintf('Loading metadata...\n');
	medmd_file = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/medmd.mat';
	load(medmd_file, 'MEDMD'); 
	
	%train_clips = [MEDMD.EventKit.EK10Ex.clips, MEDMD.EventKit.EK100Ex.clips, MEDMD.EventKit.EK130Ex.clips, MEDMD.EventBG.default.clips];
	train_clips = [MEDMD.EventKit.EK130Ex.clips, MEDMD.EventBG.default.clips];
	train_clips = unique(train_clips);
	
	test_clips = MEDMD.RefTest.KINDREDTEST.clips;
	
	clips = [train_clips, test_clips];
	
	codebook_gmm_size = 256;
    
	feature_ext_fc = sprintf('idensetraj.%s.cb%d.fc', descriptor, codebook_gmm_size);
	if dimred > 0,
		feature_ext_fc = sprintf('idensetraj.%s.cb%d.fc.pca', descriptor, codebook_gmm_size);
	end

    output_dir_fc = sprintf('%s/%s/%s', fea_dir, exp_ann, feature_ext_fc);
	
    if ~exist(output_dir_fc, 'file'),
        mkdir(output_dir_fc);
    end
	
	% loading gmm codebook
	
	codebook_hoghof_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/idensetraj.hoghof/data/codebook.gmm.%d.mat', codebook_gmm_size);
	codebook_mbh_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/idensetraj.mbh/data/codebook.gmm.%d.mat', codebook_gmm_size);
	low_proj = [];
	
	
	codebook_hoghof_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/idensetraj.hoghof/data/codebook.gmm.%d.%d.mat', codebook_gmm_size, dimred);
	low_proj_hoghof_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/idensetraj.hoghof/data/lowproj.%d.%d.mat', descriptor, dimred, 204);
	
	codebook_mbh_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/idensetraj.mbh/data/codebook.gmm.%d.%d.mat', codebook_gmm_size, dimred);
	low_proj_mbh_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/idensetraj.mbh/data/lowproj.%d.%d.mat', descriptor, dimred, 192);

	codebook_hoghof_ = load(codebook_hoghof_file, 'codebook');
    codebook_hoghof = codebook_hoghof_.codebook;
	
	codebook_mbh_ = load(codebook_mbh_file, 'codebook');
    codebook_mbh = codebook_mbh_.codebook;
	
	low_proj_hoghof_ = load(low_proj_hoghof_file, 'low_proj');
	low_proj_hoghof = low_proj_hoghof_.low_proj;
	
	low_proj_mbh_ = load(low_proj_mbh_file, 'low_proj');
	low_proj_mbh = low_proj_mbh_.low_proj;
	
    if start_seg < 1,
        start_seg = 1;
    end
    
    if end_seg > length(clips),
        end_seg = length(clips);
    end
 
    for ii = start_seg:end_seg,
	
		video_id = clips{ii};
	
        video_file = fullfile(video_dir, metadata.(video_id).ldc_pat);
		
		output_hoghof_file = sprintf('%s/%s/%s.hoghof.mat', output_dir_fc, fileparts(metadata.(video_id).ldc_pat), video_id);
		output_mbh_file = sprintf('%s/%s/%s.mbh.mat', output_dir_fc, fileparts(metadata.(video_id).ldc_pat), video_id);
		
        if exist(output_fc_file, 'file') ,
            fprintf('File [%s] already exist. Skipped!!\n', output_fc_file);
            continue;
        end
		
        fprintf(' [%d --> %d --> %d] Extracting & Encoding for [%s]...\n', start_seg, ii, end_seg, video_id);
        
        [code_hoghof, code_mbh] = densetraj_extract_and_encode_hoghofmbh(video_file, codebook_hoghof, low_proj_hoghof, codebook_mbh, low_proj_mbh); %important
        
		par_save(output_hoghof_file, code_hoghof); 	
		par_save(output_mbh_file, code_mbh); 	

    end
    
    %toc
	quit;
end

