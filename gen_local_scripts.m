function gen_local_scripts(script_name, pattern, total_jobs, num_job, start_num, machine, wait_num)
	
	script_dir = '/net/per610a/export/das11f/plsang/codes/kaori-secode-med14.2';
	
	if ~exist(script_dir, 'file'), mkdir(script_dir); end;
	
	script_file = sprintf('%s/%s.local.sh', script_dir, script_name);
	
	if ~exist('start_num', 'var'),
		start_num = 1;
	end
	
	if ~exist('wait_num', 'var'),
		wait_num = 15;
	end
	
	fh = fopen(script_file, 'w');
	
	if exist('machine', 'var'),
		fprintf(fh, 'ssh %s\n', machine);
	end
	
	%fprintf(fh, 'screen -S %s\n', script_name);
	
	num_max = 200;
	num_per_job = 1;
	
	if ~exist('start_num', 'var'),
		start_num = 1;
	end
	
	for ii = 1:num_max,	
		start_idx = start_num + (ii-1)*num_per_job;
		end_idx = start_num + ii*num_per_job - 1;
		
		if(end_idx > total_jobs)
			end_idx = total_jobs;
		end
		
		params = sprintf(pattern, start_idx, end_idx);
		%fprintf(fh, 'qsub -e /dev/null -o /dev/null %s %s\n', sge_sh_file, params);
		fprintf(fh, 'matlab -nodisplay -r "%s(%s)" &\n', script_name, params);
		if mod(ii, wait_num) == 0,
			fprintf(fh, 'wait\n');
		end
		
		if end_idx == total_jobs, break; end;
	end
	
	num_per_job = ceil((total_jobs - start_num + 1)/num_job);	
	
	start_num = start_num + num_max;
	for ii = 1:num_job,
		start_idx = start_num + (ii-1)*num_per_job;
		end_idx = start_num + ii*num_per_job - 1;
		
		if(end_idx > total_jobs)
			end_idx = total_jobs;
		end
		
		params = sprintf(pattern, start_idx, end_idx);
		%fprintf(fh, 'qsub -e /dev/null -o /dev/null %s %s\n', sge_sh_file, params);
		fprintf(fh, 'matlab -nodisplay -r "%s(%s)" &\n', script_name, params);
		if mod(ii, wait_num) == 0,
			fprintf(fh, 'wait\n');
		end
		
		if end_idx == total_jobs, break; end;
	end
	
	cmd = sprintf('chmod +x %s', script_file);
	system(cmd);
	
	fclose(fh);
end