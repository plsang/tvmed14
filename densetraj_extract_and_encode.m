function code = densetraj_extract_and_encode( descriptor, video_file, codebook, low_proj)
%EXTRACT_AND_ENCODE Summary of this function goes here
%   Detailed explanation goes here
	
	set_env;

	configs = set_global_config();
	logfile = sprintf('%s/%s.log', configs.logdir, mfilename);
	
    % densetraj = '/net/per900a/raid0/plsang/tools/dense_trajectory_release/release/DenseTrack_FULL';
	% densetraj = '/net/per900a/raid0/plsang/software/dense_trajectory_release_v1.1/release/DenseTrack';
	% densetraj = '/net/per900a/raid0/plsang/tools/dense_trajectory_release/release/DenseTrack';  % same with DenseTrack_FULL
	% densetraj = '/net/per900a/raid0/plsang/tools/dense_trajectory_release/release/DenseTrack_MBH';
	
	% switch dt_type,
		% case 'dt'
			% densetraj = '/net/per900a/raid0/plsang/tools/dense_trajectory_release/release/DenseTrack_MBH';
		% case 'idt'
			% densetraj = 'LD_PRELOAD=/net/per900a/raid0/plsang/usr.local/lib/libstdc++.so /net/per900a/raid0/plsang/tools/improved_trajectory_release/release/DenseTrackStab_MBH';
		% otherwise
			% error('Unsupported Dense Trajectory Type\n');
	% end
	
	densetraj = 'LD_PRELOAD=/net/per900a/raid0/plsang/usr.local/lib/libstdc++.so /net/per900a/raid0/plsang/tools/improved_trajectory_release/release/DenseTrackStab_HOGHOFMBH';
	
	%% fisher initialization
	fisher_params.grad_weights = false;		% "soft" BOW
    fisher_params.grad_means = true;		% 1st order
    fisher_params.grad_variances = true;	% 2nd order
    fisher_params.alpha = single(1.0);		% power normalization (set to 1 to disable)
    fisher_params.pnorm = single(0.0);		% norm regularisation (set to 0 to disable)
	
	cpp_handle = mexFisherEncodeHelperSP('init', codebook, fisher_params);
	
    % Set up the mpeg audio decode command as a readable stream
    % cmd = [densetraj, ' ', video_file, ' -S ', num2str(start_frame), ' -E ', num2str(end_frame)];
	cmd = [densetraj, ' ', video_file];

    % open pipe
    p = popenr(cmd);

    if p < 0
		error(['Error running popenr(', cmd,')']);
    end

	switch descriptor,
		case 'hoghof'
			start_idx = 1;
			end_idx = 204;
		case 'mbh'
			start_idx = 205;
			end_idx = 396;
		case 'hoghofmbh'
			start_idx = 1;
			end_idx = 396;
		otherwise
			error('Unknown descriptor for dense trajectories!!\n');
	end
	
	feat_dim = end_idx - start_idx + 1;
	full_dim = 396;		
	
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
			logmsg(logfile, msg);
			continue;                                    
	  end
	  
      %X = [X Y(8:end)]; % discard first 7 elements
      X(:, listPtr) = Y(start_idx:end_idx);
      listPtr = listPtr + 1; 
      
      if listPtr > BLOCK_SIZE,
               
		if ~isempty(low_proj),	
			mexFisherEncodeHelperSP('accumulate', cpp_handle, single(low_proj * X));
		else
			mexFisherEncodeHelperSP('accumulate', cpp_handle, single(X));
		end
				  
	    listPtr = 1;
	    X(:,:) = 0;
          
      end
    
    end

    if (listPtr > 1)
        
        X(:, listPtr:end) = [];   % remove unused slots
        
		if ~isempty(low_proj),	
			mexFisherEncodeHelperSP('accumulate', cpp_handle, single(low_proj * X));
		else
			mexFisherEncodeHelperSP('accumulate', cpp_handle, single(X));
		end
		
    end
    
	code = mexFisherEncodeHelperSP('getfk', cpp_handle);
    
	mexFisherEncodeHelperSP('clear', cpp_handle);
	
	% power normalization (with alpha = 0.5) 		
	code = sign(code) .* sqrt(abs(code));    
	
    % Close pipe
    popenr(p, -1);

end
