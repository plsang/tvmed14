function med13_rename_feature(feature_ext, segment_ann, sz_pat)
	fea_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/feature';
	f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_%s_sorted', sz_pat);
	fprintf('Loading basic metadata...\n');
	metadata = load(f_metadata, 'sorted_metadata');
	metadata = metadata.sorted_metadata;
	
	fprintf('Loading segment metadata...\n');
	segments = load_segments( segment_ann, sz_pat);

	output_dir = sprintf('%s/%s/%s/%s', fea_dir, segment_ann, feature_ext, sz_pat );
	if ~exist(output_dir, 'file'),
       		 error(output_dir);
	end

	pattern =  '(?<video>\w+)\.\w+\.frame(?<start_f>\d+)_(?<end_f>\d+)';

	for ii=1:length(segments),
		if ~mod(ii, 1000),
			fprintf('%d ', ii);
		end

		segment_id = segments{ii};
		
		info = regexp(segment_id, pattern, 'names');
		
		video_id = info.video;

		output_file = [output_dir, '/', video_id, '/', video_id, '.mat'];

		new_output_file = [output_dir, '/', video_id, '/', segment_id, '.mat'];
		
		cmd = sprintf('mv %s %s', output_file, new_output_file);
		
		system(cmd);		
	end
end
