function mfcc_select_features( algo, version )
%SELECT_FEATURES Summary of this function goes here
%   Detailed explanation goes here

	set_env;
	if ~exist('version', 'var'),
		version = 'v14.1';
	end
	
	% parameters
    sample_length = 1000; % frames
    video_sampling_rate = 1;
	max_features = 1000000;
	ensure_coef = 1.1;
	
	if ~exist('algo', 'var'),
		algo = 'rastamat';
	end
	
	%% logging
	configs = set_global_config();
	logfile = sprintf('%s/%s.log', configs.logdir, mfilename);
	msg = sprintf('Start running %s(%s)', mfilename, algo);
	logmsg(logfile, msg);	
	tic;

	
	f_metadata = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_devel.mat';
	fprintf('Loading metadata...\n');
	metadata_ = load(f_metadata, 'metadata');
	metadata = metadata_.metadata;
	
    video_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST';
	
	feat_pat = sprintf('mfcc.bg.%s.%s', algo, version);

	output_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/%s/data/selected_feats_%d.mat', feat_pat, max_features);
	if exist(output_file, 'file'),
		fprintf('File [%s] already exist. skipped!!\n', output_file);
		return;
	end
	output_dir = fileparts(output_file);
	if ~exist(output_dir, 'file'),
		mkdir(output_dir);
	end
    
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
	
	clips = MEDMD.EventBG.default.clips;
	list_video = unique(clips);	% 4992 clips
	
	num_selected_videos = ceil(video_sampling_rate * length( list_video ));
	rand_index = randperm(length(list_video));
	selected_index = rand_index(1:num_selected_videos);
    selected_videos = list_video(selected_index);

	max_features_per_video = ceil(ensure_coef * max_features / length(selected_videos));
	
    feats = cell(length(selected_videos), 1);
	%length(selected_videos)
    
    parfor ii = 1:length(selected_videos),
        video_name = selected_videos{ii};
        
        video_file = fullfile(video_dir, metadata.(video_name).ldc_pat);
        
        start_frame = 1;
        end_frame = metadata.(video_name).num_frames;
        
        fprintf('Computing features for: %d - %s %f %% complete\n', ii, video_name, ii/length(selected_videos)*100.00);
    
        if end_frame - start_frame > sample_length,
            start_frame = start_frame + randi(end_frame - start_frame - sample_length);
            end_frame = start_frame + sample_length;
        end
        
        feat = mfcc_extract_features(video_file, algo, start_frame, end_frame);
		
		if isempty(feat), continue; end;
        
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

	
    save(output_file, 'feats', '-v7.3');

    elapsed = toc;
	elapsed_str = datestr(datenum(0,0,0,0,0,elapsed),'HH:MM:SS');
	
	msg = sprintf('Finish running %s(%s). Elapsed time: %s', mfilename, algo, elapsed_str);
	logmsg(logfile, msg);

	
end

