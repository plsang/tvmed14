function sift_select_features( sift_algo, param, version )
%SELECT_FEATURES Summary of this function goes here
%   Detailed explanation goes here
	% nSize: step for dense sift
    % parameters
	
	%%
	if ~exist('version', 'var'),
		version = 'v14.1';  %% using both event video + bg video
	end

	set_env;
	
    max_features = 1000000;
	video_sampling_rate = 1;
    sample_length = 5; % frames
    ensure_coef = 1.1;
	
	configs = set_global_config();
	logfile = sprintf('%s/%s.log', configs.logdir, mfilename);
	msg = sprintf('Start running %s(%s, %s)', mfilename, sift_algo, param);
	logmsg(logfile, msg);
	tic;
	
	f_metadata = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_devel.mat';
	fprintf('Loading metadata...\n');
	metadata_ = load(f_metadata, 'metadata');
	metadata = metadata_.metadata;
	
    kf_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/keyframes';
	
    % csv_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/MEDDATA/databases';
	% eventbg_csv = 'EVENTS-BG_20130405_ClipMD.csv';
	% f_eventvideo_csv = 'EVENTS-130Ex_20130405_ClipMD.csv';

	% f_eventvideo_csv = fullfile(csv_dir,f_eventvideo_csv);	
	% f_eventbg_csv = fullfile(csv_dir, eventbg_csv);
	
	% list_eventvideo = load_video_list(f_eventvideo_csv);
	% list_bgvideo = load_video_list(f_eventbg_csv);
	
	% list_video = [list_eventvideo, list_bgvideo];
	
	fprintf('Loading metadata...\n');
	medmd_file = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/medmd.mat';
	load(medmd_file, 'MEDMD'); 
	
	clips = [MEDMD.EventKit.EK10Ex.clips, MEDMD.EventKit.EK100Ex.clips, MEDMD.EventKit.EK130Ex.clips, MEDMD.EventBG.default.clips];
	%clips = MEDMD.EventBG.default.clips;
	list_video = unique(clips);	% 4992 clips
	
	num_selected_videos = ceil(video_sampling_rate * length( list_video ));
	rand_index = randperm(length(list_video));
	selected_index = rand_index(1:num_selected_videos);
    selected_videos = list_video(selected_index);
	
	
	max_features_per_video = ceil(ensure_coef * max_features/length(selected_videos));
    
	max_features_per_video
    
    feats = cell(length(selected_videos), 1);

	output_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/%s.%s.%s.sift/data/selected_feats_%d.mat', sift_algo, num2str(param), version, max_features);
	if exist(output_file),
		fprintf('File [%s] already exist. Skipped\n', output_file);
		return;
	end
	
    parfor ii = 1:length(selected_videos),
        video_name = selected_videos{ii};
        
		video_kf_dir = fullfile(kf_dir, metadata.(video_name).ldc_pat);
		video_kf_dir = video_kf_dir(1:end-4);							% remove .mp4
        
		kfs = dir([video_kf_dir, '/*.jpg']);
        
		selected_idx = [1:length(kfs)];
		if length(kfs) > sample_length,
			rand_idx = randperm(length(kfs));
			selected_idx = selected_idx(rand_idx(1:sample_length));
		end
		
		fprintf('Computing features for: %d - %s %f %% complete\n', ii, video_name, ii/length(selected_videos)*100.00);
		feat = [];
		for jj = selected_idx,
			img_name = kfs(jj).name;
			img_path = fullfile(video_kf_dir, img_name);
			
			[frames, descrs] = sift_extract_features( img_path, sift_algo, param );
            
            % if more than 50% of points are empty --> possibley empty image
            if isempty(descrs) || sum(all(descrs == 0, 1)) > 0.5*size(descrs, 2),
                warning('Maybe blank image...[%s]. Skipped!\n', img_name);
                continue;
            end
			feat = [feat descrs];
		end
        
        if size(feat, 2) > max_features_per_video,
            feats{ii} = vl_colsubset(feat, max_features_per_video);
        else
            feats{ii} = feat;
        end
        
    end
    
    % concatenate features into a single matrix
    feats = cat(2, feats{:});
    
    if size(feats, 2) > max_features,
         feats = vl_colsubset(feats, max_features);
    end

	output_dir = fileparts(output_file);
	if ~exist(output_dir, 'file'),
		mkdir(output_dir);
		%cmd = sprintf('mkdir -p %s', output_dir);
		%system(cmd);
	end
	
	fprintf('Saving selected features to [%s]...\n', output_file);
    save(output_file, 'feats', '-v7.3');
    
	elapsed = toc;
	elapsed_str = datestr(datenum(0,0,0,0,0,elapsed),'HH:MM:SS');
	msg = sprintf('Finish running %s(%s, %s). Elapsed time: %s', mfilename, sift_algo, param, elapsed_str);
	logmsg(logfile, msg);
end

