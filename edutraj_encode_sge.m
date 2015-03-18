function [ output_args ] = edutraj_encode_sge( config_name, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   
   
    % encoding method: fisher vector
	% representation: video-based, (can be extended to segment level)
	% power normalization, which one is the best? alpha = 0.2? 
	
    % setting
    set_env;
    exp_ann = 'eduardo.idensetraj';
    codebook_gmm_size = 256;
	dimred = 128;
	
	configs = set_global_config();
	logfile = sprintf('%s/%s.log', configs.logdir, mfilename);
	msg = sprintf('Start running %s(%s, %d, %d)', mfilename, exp_ann, start_seg, end_seg);
	logmsg(logfile, msg);
	change_perm(logfile);
	tic;
	
    video_dir = '/net/per610a/export/das11f/plsang/dataset/MED/LDCDIST-RSZ';
	fea_dir = '/net/per610a/export/das11f/plsang/trecvidmed/feature';
	
	%f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_devel.mat');  % for kinddevel only
	
	%fprintf('Loading basic metadata...\n');
	%metadata = load(f_metadata, 'metadata');
	%metadata = metadata.metadata;
	
	%fprintf('Loading metadata...\n');
	medmd_file = '/net/per610a/export/das11f/plsang/trecvidmed14/metadata/medmd_2014_devel_ps.mat';
	%medmd_file = '/net/per610a/export/das11f/plsang/trecvidmed14/metadata/medmd_2014_test_ps.mat';
	load(medmd_file, 'MEDMD'); 
	metadata = MEDMD.lookup;
	
	%train_clips = [MEDMD.EventKit.EK10Ex.clips, MEDMD.EventKit.EK100Ex.clips, MEDMD.EventKit.EK130Ex.clips, MEDMD.EventBG.default.clips];
	%train_clips = [MEDMD.EventKit.EK130Ex.clips, MEDMD.EventBG.default.clips];
	%train_clips = [MEDMD.EventKit.EK10Ex.clips, MEDMD.EventKit.EK100Ex.clips];
	%[train_clips, train_clips_idx] = unique(train_clips);
	
	%train_clips_durations = [MEDMD.EventKit.EK10Ex.durations, MEDMD.EventKit.EK100Ex.durations, MEDMD.EventKit.EK130Ex.durations, MEDMD.EventBG.default.durations];
	%train_clips_durations = [MEDMD.EventKit.EK130Ex.durations, MEDMD.EventBG.default.durations];
	%train_clips_durations = [MEDMD.EventKit.EK10Ex.durations, MEDMD.EventKit.EK100Ex.durations];
	%train_clips_durations = train_clips_durations(train_clips_idx);
	%[train_clips_durations, sorted_train_idx] = sort(train_clips_durations, 'descend');
	%train_clips = train_clips(sorted_train_idx);
	
	%test_clips = MEDMD.RefTest.KINDREDTEST.clips;
	%[test_clips_durations, sorted_test_idx] = sort(MEDMD.RefTest.KINDREDTEST.durations, 'descend');
	%test_clips = MEDMD.RefTest.MEDTEST.clips;
	%[test_clips_durations, sorted_test_idx] = sort(MEDMD.RefTest.MEDTEST.durations, 'descend');
	%test_clips = test_clips(sorted_test_idx);
	
	%research_clips = MEDMD.Research.default.clips; % 10161 clips, ~314 hours
	%[research_clips_durations, sorted_test_idx] = sort(MEDMD.Research.default.durations, 'descend');
	%research_clips = research_clips(sorted_test_idx);
	
	%clips = [train_clips, test_clips];
	%durations = [train_clips_durations, test_clips_durations];
	%clips = research_clips;
	%durations = research_clips_durations;
	
	clips = MEDMD.RefTest.KINDREDTEST.clips;
	durations = MEDMD.RefTest.KINDREDTEST.durations;
    
    [durations, sorted_idx] = sort(durations, 'descend');
    clips = clips(sorted_idx);
    
	feature_ext_fc = sprintf('idensetraj.hoghofmbh.cb%d.fc.pca%d.%s', codebook_gmm_size, dimred, config_name);
	
    output_dir_fc = sprintf('%s/%s/%s', fea_dir, exp_ann, feature_ext_fc);
	
    if ~exist(output_dir_fc, 'file'),
        mkdir(output_dir_fc);
		change_perm(output_dir_fc);
    end
	
	% loading gmm codebook
	
	codebook_hoghof_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/idensetraj.hoghof/data/codebook.gmm.%d.mat', codebook_gmm_size);
	codebook_mbh_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/idensetraj.mbh/data/codebook.gmm.%d.mat', codebook_gmm_size);
	low_proj = [];
	
	
	codebook_hoghof_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/idensetraj.hoghof/data/codebook.gmm.%d.%d.mat', codebook_gmm_size, dimred);
	low_proj_hoghof_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/idensetraj.hoghof/data/lowproj.%d.%d.mat', dimred, 204);
	
	codebook_mbh_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/idensetraj.mbh/data/codebook.gmm.%d.%d.mat', codebook_gmm_size, dimred);
	low_proj_mbh_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/idensetraj.mbh/data/lowproj.%d.%d.mat', dimred, 192);

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
        
        % if ~strcmp(video_id, 'HVC000363')
            % continue;
        % end
        
		if ~isfield(metadata, video_id),
			msg = sprintf('Unknown location of video <%s>\n', video_id);
			logmsg(logfile, msg);
			continue;
		end
		
        %video_file = fullfile(video_dir, metadata.(video_id).ldc_pat);
		video_file = fullfile(video_dir, metadata.(video_id));
		
		%output_hoghof_file = sprintf('%s/%s/%s.hoghof.mat', output_dir_fc, fileparts(metadata.(video_id).ldc_pat), video_id);
		%output_mbh_file = sprintf('%s/%s/%s.mbh.mat', output_dir_fc, fileparts(metadata.(video_id).ldc_pat), video_id);
		%output_file = sprintf('%s/%s/%s.mat', output_dir_fc, fileparts(metadata.(video_id).ldc_pat), video_id);
		output_file = sprintf('%s/%s/%s.mat', output_dir_fc, fileparts(metadata.(video_id)), video_id);
		
		fprintf(' [%d --> %d --> %d] Extracting & Encoding for [%s], durations %d s...\n', start_seg, ii, end_seg, video_id, durations(ii));
		%fprintf(' [%d --> %d --> %d] Extracting & Encoding for [%s]...\n', start_seg, ii, end_seg, video_id);
		
        if exist(output_file, 'file'),
            fprintf('File [%s] already exist. Skipped!!\n', output_file);
            continue;
        end
        
        [code_hoghof, code_mbh] = edutraj_extract_and_encode_hoghofmbh(video_file, codebook_hoghof, low_proj_hoghof, codebook_mbh, low_proj_mbh); %important
        
		code = [code_hoghof; code_mbh];
		
		par_save(output_file, code, 1); 	
		%change_perm(output_file);
		
		clear code_hoghof code_mbh code;

    end
    
	elapsed = toc;
	elapsed_str = datestr(datenum(0,0,0,0,0,elapsed),'HH:MM:SS');
	msg = sprintf('Finish running %s(%s, %d, %d). Elapsed time: %s', mfilename, exp_ann, start_seg, end_seg, elapsed_str);
	logmsg(logfile, msg);

	%toc
	quit;
end
