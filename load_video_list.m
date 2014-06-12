function list_video = load_video_list(csv_file),
	fprintf('--- Loading video from file %s ...\n', csv_file);
	
	fh = fopen(csv_file);
	
	cvs_infos = textscan(fh, '%s %s %s %s %s', 'delimiter', ',');
	clip_ids = cvs_infos{1};
	fclose(fh);
		
	clip_prefix = 'HVC';
	
	list_video = {};
	for ii = 2:length(clip_ids),
		if ~mod(ii, 1000),
			fprintf('%d ', ii);
		end
		
		clip_id = str2num(strtrim(strrep(clip_ids{ii}, '"', '')));
	
		clip_name = sprintf('%s%06d', clip_prefix, clip_id);
		
		list_video{end+1} = clip_name;
	end
	
	fprintf('\n');
end
