function [ X ] = densetraj_extract_features( video_file, descriptor, gap)
%EXTRACT_FEATURES Summary of this function goes here
%   Detailed explanation goes here
	
	if ~exist('gap', 'var'),
		gap = 1;
	end
	
	if ~exist('descriptor', 'var'),
		descriptor = 'full';
	end
	
    densetraj = '/net/per900a/raid0/plsang/tools/dense_trajectory_release/release/DenseTrack';
    % Set up the mpeg audio decode command as a readable stream
    cmd = [densetraj, ' ', video_file, ' -G ', num2str(gap)];

	switch descriptor,
		case 'trajshape'
			start_idx = 8;
			end_idx = 37;
		case 'hog'
			start_idx = 38;
			end_idx = 133;
		case 'hof'
			start_idx = 134;
			end_idx = 241;
		case 'mbh'
			start_idx = 242;
			end_idx = 433;
		case 'full'
			start_idx = 8;
			end_idx = 433;
		otherwise
			error('Unknown descriptor for dense trajectories!!\n');
	end
	
	feat_dim = end_idx - start_idx + 1;
	full_dim = 433;						% default of dense trajectories 7 + 30 + 96 + 108 + 192
	
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
			log(msg);
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

function log (msg)
	fh = fopen('/net/per900a/raid0/plsang/tools/kaori-secode-ucf101/log/densetraj_extract_features.log', 'a+');
	fprintf(fh, msg);
	fprintf(fh, '\r\n');
	fclose(fh);
end
