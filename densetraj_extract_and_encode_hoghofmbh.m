function [code_hoghof, code_mbh] = densetraj_extract_and_encode_hoghofmbh( video_file, codebook_hoghof, low_proj_hoghof, codebook_mbh, low_proj_mbh)
%EXTRACT_AND_ENCODE Summary of this function goes here
%   Detailed explanation goes here
	
	set_env;

	configs = set_global_config();
	logfile = sprintf('%s/%s.log', configs.logdir, mfilename);
	
	densetraj = 'LD_PRELOAD=/net/per900a/raid0/plsang/usr.local/lib/libstdc++.so /net/per900a/raid0/plsang/tools/improved_trajectory_release/release/DenseTrackStab_HOGHOFMBH';
	
	%% fisher initialization
	fisher_params.grad_weights = false;		% "soft" BOW
    fisher_params.grad_means = true;		% 1st order
    fisher_params.grad_variances = true;	% 2nd order
    fisher_params.alpha = single(1.0);		% power normalization (set to 1 to disable)
    fisher_params.pnorm = single(0.0);		% norm regularisation (set to 0 to disable)
	
	cpp_handle_hoghof = mexFisherEncodeHelperSP('init', codebook_hoghof, fisher_params);
	cpp_handle_mbh = mexFisherEncodeHelperSP('init', codebook_mbh, fisher_params);
	
    % Set up the mpeg audio decode command as a readable stream
    % cmd = [densetraj, ' ', video_file, ' -S ', num2str(start_frame), ' -E ', num2str(end_frame)];
	cmd = [densetraj, ' ', video_file];

    % open pipe
    p = popenr(cmd);

    if p < 0
		error(['Error running popenr(', cmd,')']);
    end
	
	start_idx_hoghof = 1;
	end_idx_hoghof = 204;
	
	start_idx_mbh = 205;
	end_idx_mbh = 396;
	
	hoghof_dim = 204;
	mbh_dim = 192;
	full_dim = 396;		
	
    BLOCK_SIZE = 50000;                          % initial capacity (& increment size)
    %listSize = BLOCK_SIZE;                      % current list capacity
	X_HOGHOF = zeros(hoghof_dim, BLOCK_SIZE);
	X_MBH = zeros(mbh_dim, BLOCK_SIZE);
    %X = zeros(full_dim, BLOCK_SIZE);
    listPtr = 1;
    
    %tic
    
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
      %X(:, listPtr) = Y(start_idx:end_idx);
	  X_HOGHOF(:, listPtr) = Y(start_idx_hoghof:end_idx_hoghof);
	  X_MBH(:, listPtr) = Y(start_idx_mbh:end_idx_mbh);
      listPtr = listPtr + 1; 
      
      if listPtr > BLOCK_SIZE,
               
		mexFisherEncodeHelperSP('accumulate', cpp_handle_hoghof, single(low_proj_hoghof * X_HOGHOF));
		
		mexFisherEncodeHelperSP('accumulate', cpp_handle_mbh, single(low_proj_mbh * X_MBH));
		
		listPtr = 1;
	    X_HOGHOF(:,:) = 0;
		X_MBH(:,:) = 0;
          
      end
    
    end

    if (listPtr > 1)
        
        X_HOGHOF(:, listPtr:end) = [];   % remove unused slots
		
		X_MBH(:, listPtr:end) = [];   % remove unused slots
        
		mexFisherEncodeHelperSP('accumulate', cpp_handle_hoghof, single(low_proj_hoghof * X_HOGHOF));
		
		mexFisherEncodeHelperSP('accumulate', cpp_handle_mbh, single(low_proj_mbh * X_MBH));
		
    end
    
	code_hoghof = mexFisherEncodeHelperSP('getfk', cpp_handle_hoghof);
	code_mbh = mexFisherEncodeHelperSP('getfk', cpp_handle_mbh);
    
	mexFisherEncodeHelperSP('clear', cpp_handle_hoghof);
	mexFisherEncodeHelperSP('clear', cpp_handle_mbh);
	
	% power normalization (with alpha = 0.5) 		
	code_hoghof = sign(code_hoghof) .* sqrt(abs(code_hoghof));    
	code_mbh = sign(code_mbh) .* sqrt(abs(code_mbh));    
    % Close pipe
	
    popenr(p, -1);

end
