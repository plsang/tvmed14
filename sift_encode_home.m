function [ output_args ] = sift_encode_home( proj_name, kf_dir_name, szPat, codebook_size, spm, sift_algo, param, start_seg, end_seg )
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
    enc_type = 'kcb';
	
	if ~exist('codebook_size', 'var'),
		codebook_size = 4000;
	end
    
	feature_ext = sprintf('%s.%s.sift.Soft-%d-VL2.%s.devel', sift_algo, num2str(param), codebook_size, proj_name);
	if spm > 0,
		feature_ext = sprintf('%s.spm', feature_ext);
	end
	
    output_dir = sprintf('%s/%s.%s/%s', fea_dir, feature_ext, enc_type, szPat) ;
    if ~exist(output_dir, 'file'),
		mkdir(output_dir);
	end
    
    codebook_file = sprintf('/net/per900a/raid0/plsang/%s/feature/bow.codebook.%s.devel/%s.%s.sift/data/codebook.%d.mat', proj_name, proj_name, sift_algo, num2str(param), codebook_size);
	
	fprintf('Loading codebook [%s]...\n', codebook_file);
    codebook_ = load(codebook_file, 'codebook');
    codebook = codebook_.codebook;
    
	kdtree = vl_kdtreebuild(codebook);
	
    [segments, sinfos, vinfos] = load_segments(proj_name, szPat, kf_dir_name);
    
    if ~exist('start_seg', 'var') || start_seg < 1,
        start_seg = 1;
    end
    
    if ~exist('end_seg', 'var') || end_seg > length(segments),
        end_seg = length(segments);
    end
    
    %tic
	
    kf_dir = sprintf('/net/per900a/raid0/plsang/%s/keyframes/%s', proj_name, szPat);
	
	if strcmp(proj_name, 'trecvidmed10'),
		kf_dir = sprintf('/net/per900a/raid0/plsang/%s/keyframes', proj_name);
	end
    
		
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
		
        code = [];
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
			
			if spm > 0
				code_ = sift_encode_spm(size(im), frames, descrs, codebook, kdtree, enc_type);
			else
				code_ = kcb_encode(descrs, codebook, kdtree);	
			end
			
			code = [code code_];
		end
		fprintf('\n');
		% averaging...
		code = mean(code, 2);
                
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
  save( output_file, 'code', '-v7.3');
end

function log (msg)
	fh = fopen('sift_encode_home.log', 'a+');
    msg = [msg, ' at ', datestr(now)];
	fprintf(fh, msg);
	fprintf(fh, '\n');
	fclose(fh);
end

