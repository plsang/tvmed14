function [ output_args ] = densetraj_encode_sge_2014( exp_ann, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   
   
    
    % setting
    set_env;
	dimred = 0;
	
	configs = set_global_config();
	logfile = sprintf('%s/%s.log', configs.logdir, mfilename);
	msg = sprintf('Start running %s(%s, %d, %d)', mfilename, exp_ann, start_seg, end_seg);
	logmsg(logfile, msg);
	change_perm(logfile);
	tic;
	
    video_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST-RSZ';
	fea_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/feature';
	
    % encoding type
	codebook_gmm_size = 256;
    
	feature_ext_fc = sprintf('densetrajectory.mbh.cb%d.fc', codebook_gmm_size);
	if dimred > 0,
		feature_ext_fc = sprintf('densetrajectory.mbh.cb%d.fc.pca', codebook_gmm_size);
	end

    output_dir = sprintf('%s/%s/%s', fea_dir, exp_ann, feature_ext_fc );
	
    if ~exist(output_dir, 'file'),
        mkdir(output_dir);
    end
		
	% loading gmm codebook
	
	codebook_gmm_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/densetrajectory.mbh/data/codebook.gmm.%d.mat', codebook_gmm_size);
	low_proj = [];
	
    codebook_gmm_ = load(codebook_gmm_file, 'codebook');
    codebook_gmm = codebook_gmm_.codebook;
	
	fprintf('Loading metadata...\n');
	%ldc_pat = 'LDC2014E16';
	%ldc_pat = 'LDC2014E42';
	ldc_pat = 'LDC2014E56';
	
	medmd_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/medmd_2014_%s.mat', ldc_pat);
	load(medmd_file, 'MEDMD'); 
	
	clips = MEDMD.(ldc_pat).clips;
	[durations, sorted_clip_idx] = sort(MEDMD.(ldc_pat).durations, 'descend');
	clips = clips(sorted_clip_idx);
	
    if start_seg < 1,
        start_seg = 1;
    end
    
    if end_seg > length(clips),
        end_seg = length(clips);
    end
		
    for ii = start_seg:end_seg,
		
		video_id = clips{ii};
	
		if ~isfield(MEDMD.lookup, video_id),
			msg = sprintf('Warning, file info not found <%s>\n', video_id);
			logmsg(logfile, msg);
			continue;
		end
		
        video_file = sprintf('%s/%s/%s.mp4', video_dir, MEDMD.lookup.(video_id).ldc_pat, video_id);
		
		if ~exist(video_file, 'file'),
			msg = sprintf('Warning, video file not found <%s>\n', video_file);
			logmsg(logfile, msg);
			continue;
		end
		
		%video_file = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST-RSZ/LDC2012E26/HVC043179.mp4';
		
		output_file = sprintf('%s/%s/%s.mat', output_dir, MEDMD.lookup.(video_id).ldc_pat, video_id);
		
        if exist(output_file, 'file') ,
            fprintf('File [%s] already exist. Skipped!!\n', output_file);
            continue;
        end
		
        fprintf(' [%d --> %d --> %d] Extracting & Encoding for [%s]. Durations [%d] s.....\n', start_seg, ii, end_seg, video_id, durations(ii));
        
        code = densetraj_extract_and_encode_2014('dt', video_file, 1, MEDMD.lookup.(video_id).num_frames, codebook_gmm, low_proj); %important
		
		par_save(output_file, code, 1); 

    end
    
	elapsed = toc;
	elapsed_str = datestr(datenum(0,0,0,0,0,elapsed),'HH:MM:SS');
	msg = sprintf('Finish running %s(%s, %d, %d). Elapsed time: %s', mfilename, exp_ann, start_seg, end_seg, elapsed_str);
	logmsg(logfile, msg);
	
    %toc
	quit
end
