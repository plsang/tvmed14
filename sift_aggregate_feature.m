function sift_aggregate_feature( feature_ext, segment_ann, szPat, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   

    set_env;

    fea_dir = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/%s', segment_ann);
    if ~exist(fea_dir, 'file'),
        mkdir(fea_dir);
    end
	
    output_dir = sprintf('%s/%s/%s', fea_dir, feature_ext, szPat) ;
    if ~exist(output_dir, 'file'),
		mkdir(output_dir);
	end
	
	output_kf_feat_dir = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/keyframes/%s/%s', feature_ext, szPat) ;
	
    segments = load_segments(segment_ann, szPat);
    
    if ~exist('start_seg', 'var') || start_seg < 1,
        start_seg = 1;
    end
    
    if ~exist('end_seg', 'var') || end_seg > length(segments),
        end_seg = length(segments);
    end
    
    %tic
	f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_%s.mat', szPat);
	fprintf('Loading metadata...\n');
	metadata_ = load(f_metadata, 'metadata');
	metadata = metadata_.metadata;
	
    kf_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/keyframes';
	pattern =  '(?<video>\w+)\.\w+\.frame(?<start_f>\d+)_(?<end_f>\d+)';
	
    parfor ii = start_seg:end_seg,
        segment = segments{ii};                 
    
        info = regexp(segment, pattern, 'names');
        
		video_kf_dir = fullfile(kf_dir, metadata.(info.video).ldc_pat);
		video_kf_dir = video_kf_dir(1:end-4);	
		kfs = dir([video_kf_dir, '/*.jpg']);
		max_keyframes = length(kfs);
		max_frames = metadata.(info.video).num_frames;
		
		if strcmp(segment_ann, 'segment-100000'),
		
			output_file = [output_dir, '/', info.video, '/', info.video, '.mat'];
			start_kf = 1;
			end_kf = max_keyframes;
		else
			output_file = [output_dir, '/', info.video, '/', segment, '.mat'];	
			
			
			start_frame = str2num(info.start_f);
			end_frame = str2num(info.end_f);
		   
			%% update Jul 5, 2013: support segment-based
			
			
			start_kf = floor(start_frame*max_keyframes/max_frames) + 1;
			end_kf = floor(end_frame*max_keyframes/max_frames);
		end
		
		
        if exist(output_file, 'file'),
            fprintf('File [%s] already exist. Skipped!!\n', output_file);
            continue;
        end
		
		feat_file = sprintf('%s/%s.mat', output_kf_feat_dir, info.video);
		if ~exist(feat_file, 'file'),
			warning('Feature file not found! [%s] ', feat_file);
			continue;
		end
			
		codes = load(feat_file, 'codes');	% column vector: 65536x1
		codes = codes.codes;
		
		fprintf(' [%d --> %d --> %d] Aggregating for [%s - %d/%d kfs (%d - %d)]...\n', start_seg, ii, end_seg, segment, end_kf - start_kf + 1, length(codes), start_kf, end_kf);
		
		code = [];
		for jj = start_kf:end_kf,
			if ~mod(jj, 10),
				fprintf('%d ', jj);
			end
			
			descrs = codes{jj};
            % if more than 50% of points are empty --> possibley empty image
            if isempty(descrs) || any(isnan(descrs)),
                continue;
            end
			
			code = [code, descrs];
		end
		fprintf('\n');
		% averaging...
		code = mean(code, 2);
        
		output_vdir = [output_dir, '/', info.video];
        if ~exist(output_vdir, 'file'),
            mkdir(output_vdir);
        end
		
        par_save(output_file, code); % MATLAB don't allow to save inside parfor loop             
        
    end
    
    %toc
    % quit;

end

function par_save( output_file, code )
	save( output_file, 'code');
end

function log (msg)
	fh = fopen('/net/per900a/raid0/plsang/tools/kaori-secode-med13/log/sift_aggregate_feature.log', 'a+');
    msg = [msg, ' at ', datestr(now), '\n'];
	fprintf(fh, msg);
	fclose(fh);
end