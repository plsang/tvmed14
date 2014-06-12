function list_num_frames = med13_check_metadata
	f_metadata = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_test.mat';
	
	fprintf('Loading test metadata...\n');
	load(f_metadata, 'metadata');
	
	videos = fieldnames(metadata);
	video_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST-RSZ';
	
	list_num_frames = zeros(length(videos), 1);
	
	fprintf('%d videos loaded...\n', length(videos));
	
	for ii = 1:length(videos),
	
		if ~mod(ii, 1000),
			fprintf('%d ', ii);
		end
		
		video_id = videos{ii};
		
		video_file = fullfile(video_dir, metadata.(video_id).ldc_pat);
		
		if ~exist(video_file, 'file'),
			error('File does not exist!\n');
		end
		
		if metadata.(video_id).fps > 50,
			error('FPS too high [%s-%f]!\n', video_id, metadata.(video_id).fps);
		end
		
		list_num_frames(ii) = metadata.(video_id).num_frames;
	end
	
	[sorted_list, sort_idx] = sort(list_num_frames, 'descend');
	
	fprintf('Generating sorted metadata...\n');
	sorted_metadata = struct;
	for ii = 1:length(sort_idx),
		if ~mod(ii, 1000),
			fprintf('%d ', ii);
		end
		video_idx = sort_idx(ii);
		video_id = videos{video_idx};
		
		sorted_metadata.(video_id).fps = metadata.(video_id).fps;
		sorted_metadata.(video_id).num_frames = metadata.(video_id).num_frames;
		sorted_metadata.(video_id).ldc_pat = metadata.(video_id).ldc_pat;	
	end
	
	
	f_sorted_metadata = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_test_sorted.mat';
	save(f_sorted_metadata, 'sorted_metadata');
	
end