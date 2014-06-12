function mfcc_encode_home_check( segment_ann, sz_pat, algo, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   

	set_env;

	if ~exist('algo', 'var'),
		algo = 'kamil';
	end
	
	% encoding type
    codebook_size = 4000;
	
	codebook_gmm_size = 256;
	
	feat_dim = 39;
	
	video_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST';	% for mfcc 
	fea_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/feature';
	%f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_%s_sorted', sz_pat);
	f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_%s', sz_pat);
	
	fprintf('Loading basic metadata...\n');
	%metadata = load(f_metadata, 'sorted_metadata');
	%metadata = metadata.sorted_metadata;
	
	metadata = load(f_metadata, 'metadata');
	metadata = metadata.metadata;
	
	fprintf('Loading segment metadata...\n');
	segments = load_segments( segment_ann, sz_pat);
	
    feature_ext = sprintf('mfcc.%s.cb%d.soft', algo, codebook_size);

    output_dir = sprintf('%s/%s/%s/%s', fea_dir, segment_ann, feature_ext, sz_pat);
    if ~exist(output_dir, 'file'),
        mkdir(output_dir);
    end
    
	feature_ext_fc = sprintf('mfcc.%s.cb%d.fc', algo, codebook_gmm_size);

    output_dir_fc = sprintf('%s/%s/%s/%s', fea_dir, segment_ann, feature_ext_fc, sz_pat);
    if ~exist(output_dir_fc, 'file'),
        mkdir(output_dir_fc);
    end
	
    codebook_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/mfcc.%s/data/codebook.kmeans.%d.%d.mat', algo, codebook_size, feat_dim);
    codebook_ = load(codebook_file, 'codebook');
    codebook = codebook_.codebook;
    
    kdtree = vl_kdtreebuild(codebook);
    
	
	% loading gmm codebook
	
	codebook_gmm_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/mfcc.%s/data/codebook.gmm.%d.%d.mat', algo, codebook_gmm_size, feat_dim);
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
		
        %output_file = [output_dir, '/', video_id, '/', video_id, '.mat'];
		
		output_fc_file = [output_dir_fc, '/', video_id, '/', video_id, '.mat'];
        
		if exist(output_fc_file, 'file') ,
            fprintf('File [%s] already exist. Skipped!!\n', output_fc_file);
            continue;
        end
        
        fprintf(' [%d --> %d --> %d] Extracting features & Encoding for [%s]...\n', start_seg, ii, end_seg, segment_id);
        
		if strcmp(segment_ann, 'segment-100000'),
			feat = mfcc_extract_features(video_file, algo);
		else
			start_frame = str2num(info.start_f);		
			end_frame = str2num(info.end_f); 
			feat = mfcc_extract_features(video_file, algo, start_frame, end_frame);
		end
		
		if isempty(feat),
			continue;
		else			    
			%code = kcb_encode(feat, codebook, kdtree);	
			code_fk = fc_encode(feat, codebook_gmm, []);	
		end
        
		output_vdir_fc = [output_dir_fc, '/', video_id];
        if ~exist(output_vdir_fc, 'file'),
            mkdir(output_vdir_fc);
        end
		
        %par_save(output_file, code); % MATLAB don't allow to save inside parfor loop          
		par_save(output_fc_file, code_fk); 
		
    end

end

function par_save( output_file, code )
  save( output_file, 'code');
end

function log (msg)
	fh = fopen('mfcc_encode_home.log', 'a+');
    msg = [msg, ' at ', datestr(now), '\n'];
	fprintf(fh, msg);
	fclose(fh);
end

