function [ code, code_fk ] = densetraj_extract_and_encode( video_file, start_frame, end_frame, codebook, kdtree, codebook_gmm, low_proj, bow_encoding, fc_encoding)
%EXTRACT_AND_ENCODE Summary of this function goes here
%   Detailed explanation goes here
	
    % densetraj = '/net/per900a/raid0/plsang/tools/dense_trajectory_release/release/DenseTrack_FULL';
	% densetraj = '/net/per900a/raid0/plsang/software/dense_trajectory_release_v1.1/release/DenseTrack';
	% densetraj = '/net/per900a/raid0/plsang/tools/dense_trajectory_release/release/DenseTrack';  % same with DenseTrack_FULL
	densetraj = '/net/per900a/raid0/plsang/tools/dense_trajectory_release/release/DenseTrack_MBH';
	
	%% fisher initialization
	fisher_params.grad_weights = false;		% "soft" BOW
    fisher_params.grad_means = true;		% 1st order
    fisher_params.grad_variances = true;	% 2nd order
    fisher_params.alpha = single(1.0);		% power normalization (set to 1 to disable)
    fisher_params.pnorm = single(0.0);		% norm regularisation (set to 0 to disable)
	
	cpp_handle = mexFisherEncodeHelperSP('init', codebook_gmm, fisher_params);
	
    % Set up the mpeg audio decode command as a readable stream
    cmd = [densetraj, ' ', video_file, ' -S ', num2str(start_frame), ' -E ', num2str(end_frame)];
	% cmd = [densetraj, ' ', video_file];

    % open pipe
    p = popenr(cmd);

    if p < 0
		error(['Error running popenr(', cmd,')']);
    end

	feat_dim = 192;
	full_dim = 199;		
	
    BLOCK_SIZE = 50000;                          % initial capacity (& increment size)
    %listSize = BLOCK_SIZE;                      % current list capacity
    X = zeros(feat_dim, BLOCK_SIZE);
    listPtr = 1;
    
    %tic

    code = zeros(size(codebook, 2), 1);
    
    while true,

      % Get the next chunk of data from the process
      Y = popenr(p, full_dim, 'float');
	  
      if isempty(Y), break; end;

	  if length(Y) ~= full_dim,
			msg = ['wrong dimension [', num2str(length(Y)), '] when running [', cmd, '] at ', datestr(now)];
			log(msg);
			continue;                                    
	  end
	  
      %X = [X Y(8:end)]; % discard first 7 elements
      X(:, listPtr) = Y(8:end);
      listPtr = listPtr + 1; 
      
      if listPtr > BLOCK_SIZE,
          % kcb encoding
               
		   if bow_encoding == 1,
			  code_ = kcb_encode(X, codebook, kdtree);
			 
			  code = code + code_;
		   end
		  
			% fisher encoding
		 if fc_encoding == 1,
			if ~isempty(low_proj),	
				mexFisherEncodeHelperSP('accumulate', cpp_handle, single(low_proj * X));
			else
				mexFisherEncodeHelperSP('accumulate', cpp_handle, single(X));
			end
		 end 
		   
		  
          listPtr = 1;
          X(:,:) = 0;
          
      end
    
    end

    if (listPtr > 1)
        
        X(:, listPtr:end) = [];   % remove unused slots
        
		if bow_encoding == 1,
			  code_ = kcb_encode(X, codebook, kdtree);
			 
			  code = code + code_;
		end
		
		 % fisher encoding
		if fc_encoding == 1,
			if ~isempty(low_proj),	
				mexFisherEncodeHelperSP('accumulate', cpp_handle, single(low_proj * X));
			else
				mexFisherEncodeHelperSP('accumulate', cpp_handle, single(X));
			end
		end
		
    end
    
	code_fk = mexFisherEncodeHelperSP('getfk', cpp_handle);
    
	mexFisherEncodeHelperSP('clear', cpp_handle);
	
	% power normalization (with alpha = 0.5) 		
	code_fk = sign(code_fk) .* sqrt(abs(code_fk));    
	
    % Close pipe
    popenr(p, -1);

end


function log (msg)
	fh = fopen('/net/per900a/raid0/plsang/tools/kaori-secode-med13/log/densetraj_extract_and_encode.log', 'a+');
	fprintf(fh, [msg, '\n']);
	fclose(fh);
end
