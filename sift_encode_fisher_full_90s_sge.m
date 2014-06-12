function [ output_args ] = sift_encode_fisher_full_90s_sge( szPat, sift_algo, param, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   

	%Usage:
	%In: 
	%	clustering_algo: kmeans, gmm
	%	dimred: 		 feat dim, default 128, ortherwise using pca
	
	% update: Jun 25th, SPM suported
    % setting
    set_env;

	f_metadata = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_%s_sorted.mat', szPat);
	fprintf('Loading sorted metadata...\n');
	metadata_ = load(f_metadata, 'metadata');
	metadata = metadata_.metadata;
	
	videos = fieldnames(metadata);
	fprintf('--- %d video info loaded...\n', length(videos));
	
    kf_dir = '/net/per610a/export/das11f/plsang/trecvidmed13/keyframes';
	
    fea_dir = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/segment-100000');
    if ~exist(fea_dir, 'file'),
        mkdir(fea_dir);
    end
        
    seg_fea_dir = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/segment-90');
    if ~exist(seg_fea_dir, 'file'),
        mkdir(seg_fea_dir);
    end
	
	
	enc_type = 'fisher';
	clustering_algo = 'gmm';
	codebook_size = 256;
	spm = 0;
	dimred = 80;
	default_dim = 128;
	
	feature_ext = sprintf('%s.%s.sift.cb%d.devel.%s', sift_algo, num2str(param), codebook_size, enc_type);
	if spm > 0,
		feature_ext = sprintf('%s.spm', feature_ext);
	end
	
	if dimred < default_dim,,
		feature_ext = sprintf('%s.pca', feature_ext);
	end
	
    output_dir = sprintf('%s/%s/%s', fea_dir, feature_ext, szPat) ;
    if ~exist(output_dir, 'file'),
		mkdir(output_dir);
	end
    
    codebook_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/%s.%s.sift/data/codebook.%s.%d.%d.mat', ...
		sift_algo, num2str(param), clustering_algo, codebook_size, dimred);
		
	fprintf('Loading codebook [%s]...\n', codebook_file);
    codebook_ = load(codebook_file, 'codebook');
    codebook = codebook_.codebook;
 
	
 	low_proj = [];
	if dimred < default_dim,
		lowproj_file = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/feature/bow.codebook.devel/%s.%s.sift/data/lowproj.%d.%d.mat', ...
			sift_algo, num2str(param), dimred, default_dim);
			
		fprintf('Loading low projection matrix [%s]...\n', lowproj_file);
		low_proj_ = load(lowproj_file, 'low_proj');
		low_proj = low_proj_.low_proj;
	end
	
	
    if ~exist('start_seg', 'var') || start_seg < 1,
        start_seg = 1;
    end
    
    if ~exist('end_seg', 'var') || end_seg > length(videos),
        end_seg = length(videos);
    end
    
	output_dir = sprintf('%s/%s/%s', fea_dir, feature_ext, szPat) ;
    if ~exist(output_dir, 'file'),
		mkdir(output_dir);
	end
	
	seg_output_dir = sprintf('%s/%s/%s', seg_fea_dir, feature_ext, szPat) ;
    if ~exist(seg_output_dir, 'file'),
		mkdir(seg_output_dir);
	end
	
    %tic
	
	fisher_params.grad_weights = false;		% "soft" BOW
	fisher_params.grad_means = true;		% 1st order
	fisher_params.grad_variances = true;	% 2nd order
	fisher_params.alpha = single(1.0);		% power normalization (set to 1 to disable)
	fisher_params.pnorm = single(0.0);		% norm regularisation (set to 0 to disable)
		
    for ii = start_seg:end_seg,
        
    
		video_name = videos{ii};
        
		output_file = [output_dir, '/', video_name, '/', video_name, '.mat'];
        if exist(output_file, 'file'),
            fprintf('File [%s] already exist. Skipped!!\n', output_file);
            continue;
        end
			
		video_kf_dir = fullfile(kf_dir, metadata.(video_name).ldc_pat);
		video_kf_dir = video_kf_dir(1:end-4);	
        
		kfs = dir([video_kf_dir, '/*.jpg']);
		max_keyframes = length(kfs);
		max_frames = metadata.(video_name).num_frames;

		mfile = sprintf('/net/per610a/export/das11f/plsang/trecvidmed13/metadata/segment-90/%s/%s.lst', szPat, video_name);
		if ~exist(mfile, 'file'),
			msg = sprintf('Meta file [%s] not found!', mfile);
			warning(msg);
			log(msg);
			continue;
		end
		
		segments = textread(mfile, '%s');
		
		fprintf(' [%d --> %d --> %d] Extracting & encoding for video [%s - %d kfs]...\n', start_seg, ii, end_seg, video_name, length(kfs));
		
		cpp_handle = mexFisherEncodeHelperSP('init', codebook, fisher_params);
		
		pattern = '(?<video>\w+)\.\w+\.frame(?<start_f>\d+)_(?<end_f>\d+)';
		
		for kk = 1:length(segments),
			segment = segments{kk};
			info = regexp(segment, pattern, 'names');
			start_frame = str2num(info.start_f);
			end_frame = str2num(info.end_f);
			
			start_kf = floor(start_frame*max_keyframes/max_frames) + 1;
			end_kf = floor(end_frame*max_keyframes/max_frames);
			
			seg_output_file = [seg_output_dir, '/', video_name, '/', segment, '.mat'];
			%if exist(seg_output_file, 'file'),
			%	fprintf('File [%s] already exist. Skipped!!\n', seg_output_file);
			%	continue;
			%end	
		
			for jj = start_kf:end_kf,
				
				if ~mod(jj, 10),
					fprintf('%d ', jj);
				end
				img_name = kfs(jj).name;
				img_path = fullfile(video_kf_dir, img_name);
			
				try
					im = imread(img_path);
				catch
					warning('Error while reading image [%s]!!\n', img_path);
					continue;
				end
				
				[frames, descrs] = sift_extract_features( im, sift_algo, param );
				
				% if more than 50% of points are empty --> possibley empty image
				if sum(all(descrs == 0, 1)) > 0.5*size(descrs, 2),
					warning('Maybe blank image...[%s]. Skipped!\n', img_name);
					continue;
				end
				
				if ~isempty(low_proj),
					descrs = low_proj * descrs;   
				end
				
				if spm > 0,
					error('Not supported for now!!\n');
				else
					mexFisherEncodeHelperSP('accumulate', cpp_handle, single(descrs));
				end
				
			end
			
			fprintf('\n');
		
			seg_code = mexFisherEncodeHelperSP('getfk', cpp_handle);
			
			seg_code = sign(seg_code) .* sqrt(abs(seg_code));
			
			% saving output for segment
			seg_output_vdir = [seg_output_dir, '/', video_name];
			if ~exist(seg_output_vdir, 'file'),
				mkdir(seg_output_vdir);
			end
			par_save(seg_output_file, seg_code);
			
		end
		
        
		code = mexFisherEncodeHelperSP('getfk', cpp_handle);
        
		% important: power normalization with alpha = 0.5
		code = sign(code) .* sqrt(abs(code));
		
		mexFisherEncodeHelperSP('clear', cpp_handle);       
		
		output_vdir = [output_dir, '/', video_name];
        if ~exist(output_vdir, 'file'),
            mkdir(output_vdir);
        end
		
		% saving output for video
		par_save(output_file, code); % MATLAB don't allow to save inside parfor loop
        
    end
    
    %toc
    quit;

end

function par_save( output_file, code )
  save( output_file, 'code');
end

function log (msg)
	fh = fopen('/net/per900a/raid0/plsang/tools/kaori-secode-med13/log/sift_encode_fisher_full_90s_sge.log', 'a+');
    msg = [msg, ' at ', datestr(now), '\n'];
	fprintf(fh, msg);
	fclose(fh);
end

