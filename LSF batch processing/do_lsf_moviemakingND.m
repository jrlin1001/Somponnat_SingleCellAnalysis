function do_lsf_moviemakingND()

% Define parameters related to the process---------
clear all;
signalshift = 2^9;
bgsubstractlogic = 0; % 
illumcorlogic = 1; % Algorithmic illumination correction by high-pass filter
framshift_logic = 0;
ImageIndex = 1; % 1=nomin/denomin, 2=templateCH, 3=nomin,4=denomin
intensityrange = [0.0031281 0.0036622]; % For other images
displaygate = [0.957 1.15]; % For FRET Only
filterParam = [2 2]; 
cellsize = 15;
timestamplogic = 2; % 1 = frame no, 2 = actual time
celllocationlogic = 0; % 1 = show location of tracked cells, 0 = only image
save videoparameters;
clear all;
%-------------------------------------------------
% Define information about input images-----------
ndfilename = '02152013-r1.nd';
templateCH = 1;
nominCH = 2;
denominCH = 3;
sourcefolder = '/files/ImStor/sorger/data/NIC/Pat/02-15-2013';
%------------------------------------------------
currentF = pwd;
cd(sourcefolder);
prefix = ndfilename(1:(end-3));
[notp stagePos stageName channelnames] = readndfile(ndfilename);
cd(currentF);
tps = [1 notp];
sites = 1:length(stagePos);

jobmgr = findResource('scheduler', 'type', 'lsf');
jobmgr.ClusterMatlabRoot = '/opt/matlab';
jobmgr.SubmitArguments = '-q short -W 12:00 -R "rusage[matlab_dc_lic=1]"';
job = jobmgr.createJob();

for site = sites
    
    fileformat = [prefix '_%s_s' num2str(site) '_t%g.TIF'];
    %tokens   = regexp(stageName{site}, 'r(?<row>\d+)c(?<col>\d+)f(?<field>\d+)','tokens');
    tokens   = regexp(stageName{site}, 'r(?<row>\d+)c(?<col>\d+)|r(?<row>\d+)_c(?<col>\d+)|R(?<row>\d+)C(?<col>\d+)|R(?<row>\d+)_C(?<col>\d+)','tokens');
    
    if ~isempty(tokens)
        row = str2num(tokens{1}{1});
        col = str2num(tokens{1}{2});
    else
        row = site;
        col = 1;
    end
    
    %field = tokens{1}{3};
    field = 1;
    plane = 1;
    job.createTask(@GenMov_commandline, 0, ...
        {3,sourcefolder, row, col,field,plane,templateCH,nominCH,denominCH, tps,fileformat,channelnames});
end

job.submit();

function [notp stagePos stageName waveName] = readndfile(filename)
% Search for number of string matches per line.
notp=-1;
stagePos = [];
stageName = [];
waveName = [];


if exist(filename,'file')
    fid = fopen(filename);
    y = 0;
    tline = fgetl(fid);
    sind = 1;
    wind = 1;
    notp=0;
    while ischar(tline)
        
        % Find number of time points
        
        testInd = regexp(tline,'NTimePoints');
        num = length(testInd);
        if num > 0
            tp  = regexp(tline, '(?<="NTimePoints", )\d+', 'match');
            notp = str2num(tp{1});
        end
        
        
        % Find stage naming
        testInd = regexp(tline,'Stage\d+');
        num = length(testInd);
        if num > 0
            stage  = regexp(tline, '(?<=")\w+(?=",)', 'match');
            stagePos{sind,1} = stage{1};
            stagename  = regexp(tline, '(?<="Stage\d+", ").+(?=")', 'match');
            stageName{sind,1} = stagename{1};
            sind=sind+1;
        end
        
        % Find stage naming
        testInd = regexp(tline,'WaveName\d+');
        num = length(testInd);
        if num > 0
            wavename1  = regexp(tline, '(?<="WaveName\d+", ")\w+(?=_)', 'match');
            wavename2  = regexp(tline, '(?<="WaveName\d+", "\w+_)\w+(?=")', 'match');
            waveName{wind} = ['w' num2str(wind) wavename1{1} '-' wavename2{1}];
            wind=wind+1;
        end
        
        tline = fgetl(fid);
    end
    fclose(fid);
end


