function convert_csv()
	indir = '/net/per610a/export/das11f/plsang/trecvidmed13/submission/AH/threshold/';
	list = dir(indir);
	for ii = 1:length(list),
		file_name = list(ii).name;
		if ~isempty(strfind(file_name, '.csv')),
			csv_file = fullfile(indir, file_name);
			fprintf('Converting %s ...\n', csv_file);
			convert_csv_(csv_file);
		end
	end
end

function convert_csv_(csv_file)
	outdir = '/net/per610a/export/das11f/plsang/trecvidmed13/submission/AH/threshold/converted';
	
	fh = fopen(csv_file, 'r');
	infos = textscan(fh, '%s %s %s %s %s %s %s', 'delimiter', ',');
	fclose(fh);
	
	[~, csv_name] = fileparts(csv_file);
	f_out = sprintf('%s/%s.csv', outdir, csv_name);
	
	fh = fopen(f_out, 'w');
	
	for ii=1:length(infos{1}),
		fprintf(fh, '"%s","%s","%s","%s","%s","%s","%s"\n', infos{1}{ii},  infos{2}{ii},  infos{3}{ii},  infos{4}{ii},  infos{5}{ii},  infos{6}{ii},  infos{7}{ii});
	end
		
	fclose(fh);
	
end
