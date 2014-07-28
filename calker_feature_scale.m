function [scaled_data, scale_params] = calker_feature_scale(data, scale_params)
	% data: column vector, ie: d x n_samples
	
	if exist('scale_params', 'var'),
		minimums = scale_params.minimums;
		ranges = scale_params.ranges;		
	else
		scale_params = struct;
		minimums = min(data, [], 2);
		ranges = max(data, [], 2) - minimums;
		
		%important
		ranges(ranges == 0) = 1;
		
		scale_params.minimums = minimums;
		scale_params.ranges = ranges;
	end
	
	scaled_data = (data - repmat(minimums, 1, size(data, 2))) ./ repmat(ranges, 1, size(data, 2));
	
end