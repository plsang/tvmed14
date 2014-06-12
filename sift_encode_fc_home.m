function [ output_args ] = sift_encode_fc_home( proj_name, kf_dir_name, szPat, sift_algo, param, codebook_size, dimred, spm, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   

	% update: Jun 25th, SPM suported
    % setting
    set_env;

    fea_dir = sprintf('/net/per900a/raid0/plsang/%s/feature/%s', proj_name, kf_dir_name);
    if ~exist(fea_dir, 'file'),
            mkdir(fea_dir);
    end
        
    % encoding type
    enc_type = 'fc';
	
	if ~exist('codebook_size', 'var'),
		codebook_size = 256;
	end
    
	if ~exist('spm', 'var'),
		spm = 0;
	end
	
	default_dim = 128;
	if ~exist('dimred', 'var'),
		dimred = default_dim;
	end

	
	feature_ext = sprintf('%s.%s.sift.cb%d.%s.devel.accumulate', sift_algo, num2str(param), codebook_size, proj_name);
	if spm > 0,
		feature_ext = sprintf('%s.spm', feature_ext);
	end
	
	if dimred < default_dim,,
		feature_ext = sprintf('%s.pca', feature_ext);
	end
	
	
    output_dir = sprintf('%s/%s.%s/%s', fea_dir, feature_ext, enc_type, szPat) ;
    if ~exist(output_dir, 'file'),
		mkdir(output_dir);
	end
    
    codebook_file = sprintf('/net/per900a/raid0/plsang/%s/feature/bow.codebook.%s.devel/%s.%s.sift/data/codebook.gmm.%d.%d.mat', ...
		proj_name, proj_name, sift_algo, num2str(param), codebook_size, dimred);
		
	fprintf('Loading codebook [%s]...\n', codebook_file);
    codebook_ = load(codebook_file, 'codebook');
    codebook = codebook_.codebook;
 
	
 	low_proj = [];
	if dimred < default_dim,
		lowproj_file = sprintf('/net/per900a/raid0/plsang/%s/feature/bow.codebook.%s.devel/%s.%s.sift/data/lowproj.%d.%d.mat', ...
			proj_name, proj_name, sift_algo, num2str(param), dimred, default_dim);
			
		fprintf('Loading low projection matrix [%s]...\n', lowproj_file);
		low_proj_ = load(lowproj_file, 'low_proj');
		low_proj = low_proj_.low_proj;
	end
	

	
    [segments, sinfos, vinfos] = load_segments(proj_name, szPat, kf_dir_name);
    
    if ~exist('start_seg', 'var') || start_seg < 1,
        start_seg = 1;
    end
    
    if ~exist('end_seg', 'var') || end_seg > length(segments),
        end_seg = length(segments);
    end
    
    %tic
	
    kf_dir = sprintf('/net/per900a/raid0/plsang/%s/keyframes/%s', proj_name, szPat);
    
	fisher_params.grad_weights = false;		% "soft" BOW
	fisher_params.grad_means = true;		% 1st order
	fisher_params.grad_variances = true;	% 2nd order
	fisher_params.alpha = single(1.0);		% power normalization (set to 1 to disable)
	fisher_params.pnorm = single(0.0);		% norm regularisation (set to 0 to disable)
			
    parfor ii = start_seg:end_seg,
        segment = segments{ii};                 
    
        pattern =  '(?<video>\w+)\.\w+\.frame(?<start>\d+)_(?<end>\d+)';
        info = regexp(segment, pattern, 'names');
        
        output_file = [output_dir, '/', info.video, '/', segment, '.mat'];
        if exist(output_file, 'file'),
            fprintf('File [%s] already exist. Skipped!!\n', output_file);
            continue;
        end
        
        video_kf_dir = fullfile(kf_dir, info.video);
        
        start_frame = str2num(info.start);
        end_frame = str2num(info.end);
        
		kfs = dir([video_kf_dir, '/*.jpg']);
       
		%% update Jul 5, 2013: support segment-based
		max_frames = max(vinfos.(info.video));
		max_keyframes = length(kfs);
		
        start_kf = floor(start_frame*max_keyframes/max_frames) + 1;
		end_kf = floor(end_frame*max_keyframes/max_frames);
		
		fprintf(' [%d --> %d --> %d] Extracting & encoding for [%s - %d/%d kfs (%d - %d)]...\n', start_seg, ii, end_seg, segment, end_kf - start_kf + 1, max_keyframes, start_kf, end_kf);
		
		cpp_handle = mexFisherEncodeHelperSP('init', codebook, fisher_params);
        
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
			
			[frames, descrs] = sift_extract_features( im, sift_algo, param )
            
            % if more than 50% of points are empty --> possibley empty image
            if sum(all(descrs == 0, 1)) > 0.5*size(descrs, 2),
                warning('Maybe blank image...[%s]. Skipped!\n', img_name);
                continue;
            end
			
			if ~isempty(low_proj)
				descrs = low_proj * descrs;   
			end
			
			if spm > 0
				error('Not supported for now!!\n');
			else
				mexFisherEncodeHelperSP('accumulate', cpp_handle, single(descrs));
			end
				
		end
		
		
		code = mexFisherEncodeHelperSP('getfk', cpp_handle);
        
		mexFisherEncodeHelperSP('clear', cpp_handle);        
		
        % output code
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
	fh = fopen('/net/per900a/raid0/plsang/tools/kaori-secode-med11/log/sift_encode_fc_home.log', 'a+');
    msg = [msg, ' at ', datestr(now), '\n'];
	fprintf(fh, msg);
	fclose(fh);
end

