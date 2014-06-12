function [ output_args ] = densetraj_encode_sge( segment_ann, sz_pat, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   
   
    
    % setting
    set_env;
    
    bow_encoding = 1;	
	fc_encoding = 0;	
	dimred = 128;
	
    video_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST-RSZ';
	fea_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/feature';
	%f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_%s_sorted', sz_pat);
	
	f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_devel_sorted');  % for kinddevel only
	
	fprintf('Loading basic metadata...\n');
	metadata = load(f_metadata, 'metadata');
	metadata = metadata.metadata;
	
	fprintf('Loading segment metadata...\n');
	segments = load_segments( segment_ann, sz_pat);
	
    % encoding type
    codebook_size = 4000;
	
	codebook_gmm_size = 256;
	
	feature_ext = sprintf('densetrajectory.mbh.cb%d.soft', codebook_size);

    output_dir = sprintf('%s/%s/%s/%s', fea_dir, segment_ann, feature_ext, sz_pat );
    if ~exist(output_dir, 'file'),
        mkdir(output_dir);
    end
    
	feature_ext_fc = sprintf('densetrajectory.mbh.cb%d.fc', codebook_gmm_size);
	if dimred > 0,
		feature_ext_fc = sprintf('densetrajectory.mbh.cb%d.fc.pca', codebook_gmm_size);
	end

    output_dir_fc = sprintf('%s/%s/%s/%s', fea_dir, segment_ann, feature_ext_fc, sz_pat );
	
    if ~exist(output_dir_fc, 'file'),
        mkdir(output_dir_fc);
    end
	
    codebook_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/densetrajectory.mbh/data/codebook.kmeans.%d.mat', codebook_size);
    codebook_ = load(codebook_file, 'codebook');
    codebook = codebook_.codebook;
    
    kdtree = vl_kdtreebuild(codebook);
    
	
	% loading gmm codebook
	
	codebook_gmm_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/densetrajectory.mbh/data/codebook.gmm.%d.mat', codebook_gmm_size);
	low_proj = [];
	
	if dimred > 0,
		codebook_gmm_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/densetrajectory.mbh/data/codebook.gmm.%d.%d.mat', codebook_gmm_size, dimred);
		low_proj_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/densetrajectory.mbh/data/lowproj.%d.%d.mat', dimred, 192);
		low_proj_ = load(low_proj_file, 'low_proj');
		low_proj = low_proj_.low_proj;
	end
    codebook_gmm_ = load(codebook_gmm_file, 'codebook');
    codebook_gmm = codebook_gmm_.codebook;
	
    if start_seg < 1,
        start_seg = 1;
    end
    
    if end_seg > length(segments),
        end_seg = length(segments);
    end
    
   
	pattern =  '(?<video>\w+)\.\w+\.frame(?<start_f>\d+)_(?<end_f>\d+)';
		
    for ii = start_seg:end_seg,
	
		segment_id = segments{ii};
		
		info = regexp(segment_id, pattern, 'names');
		
		video_id = info.video;
	
        video_file = fullfile(video_dir, metadata.(video_id).ldc_pat);
		
		if ~strcmp(segment_ann, 'segment-100000'),
			output_file = [output_dir, '/', video_id, '/', segment_id, '.mat'];		
			output_fc_file = [output_dir_fc, '/', video_id, '/', segment_id, '.mat'];
		else
			output_file = [output_dir, '/', video_id, '/', video_id, '.mat'];
			output_fc_file = [output_dir_fc, '/', video_id, '/', video_id, '.mat'];
		end
		
        if exist(output_file, 'file') && exist(output_fc_file, 'file') ,
            fprintf('File [%s] and [%s] already exist. Skipped!!\n', output_file, output_fc_file);
            continue;
        end
        
		start_frame = str2num(info.start_f);
		
		end_frame = str2num(info.end_f);
		
        fprintf(' [%d --> %d --> %d] Extracting & Encoding for [%s]...\n', start_seg, ii, end_seg, video_id);
        
        [code, code_fk] = densetraj_extract_and_encode(video_file, start_frame, end_frame, codebook, kdtree, codebook_gmm, low_proj, bow_encoding, fc_encoding); %important
        
        % output code
        output_vdir = [output_dir, '/', video_id];
        if bow_encoding == 1 && ~exist(output_vdir, 'file'),
            mkdir(output_vdir);
        end
        
		output_vdir_fc = [output_dir_fc, '/', video_id];
        if fc_encoding == 1 && ~exist(output_vdir_fc, 'file'),
            mkdir(output_vdir_fc);
        end
		
		if bow_encoding == 1,
			par_save(output_file, code); % MATLAB don't allow to save inside parfor loop          
		end	
		
		if fc_encoding == 1,
			par_save(output_fc_file, code_fk); 
		end

    end
    
    %toc
	quit
end

function par_save( output_file, code )
	save( output_file, 'code');
end

function log (msg)
	fh = fopen('/net/per900a/raid0/plsang/tools/kaori-secode-med13/log/densetraj_encode_sge.log', 'a+');
    msg = [msg, ' at ', datestr(now), '\n'];
	fprintf(fh, msg);
	fclose(fh);
end

