function [ X ] = densetraj_extract_features( video_file, descriptor, start_frame, end_frame)
%EXTRACT_FEATURES Summary of this function goes here
%   Detailed explanation goes here
	set_env;

	configs = set_global_config();
	logfile = sprintf('%s/%s.log', configs.logdir, mfilename);
	
	if ~exist('descriptor', 'var'),
		descriptor = 'full';
	end
	
    %%densetraj = '/net/per900a/raid0/plsang/tools/dense_trajectory_release/release/DenseTrack';
	densetraj = 'LD_PRELOAD=/net/per900a/raid0/plsang/usr.local/lib/libstdc++.so /net/per900a/raid0/plsang/tools/improved_trajectory_release/release/DenseTrackStab_HOGHOFMBH';
    % Set up the mpeg audio decode command as a readable stream

	cmd = [densetraj, ' ', video_file];
	
	if exist('start_frame', 'var') && exist('end_frame', 'var'),
		cmd = [densetraj, ' ', video_file, ' -S ', num2str(start_frame), ' -E ', num2str(end_frame)];
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
	full_dim = 396;						% default of dense trajectories 7 + 30 + 96 + 108 + 192
	
    % open pipe
    p = popenr(cmd);

    if p < 0
      error(['Error running popenr(', cmd,')']);
    end


    BLOCK_SIZE = 50000;                          % initial capacity (& increment size)
    listSize = BLOCK_SIZE;                      % current list capacity
    X = zeros(feat_dim, listSize);
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
      X(:, listPtr) = Y(start_idx:end_idx);
      listPtr = listPtr + 1; 
      
      if( listPtr+(BLOCK_SIZE/1000) > listSize )  
            listSize = listSize + BLOCK_SIZE;       % add new BLOCK_SIZE slots
            X(:, listPtr+1:listSize) = 0;
      end
    
    end

    %toc

    X(:, listPtr:end) = [];   % remove unused slots
    
    % Close pipe
    popenr(p, -1);


end
