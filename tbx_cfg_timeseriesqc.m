function timeseriesqc_tools = tbx_cfg_timeseriesqc
% 'Timeseries QC' - MATLABBATCH configuration
%
% This MATLABBATCH configuration file has been generated automatically by MATLABBATCH using ConfGUI. It describes menu
% structure, validity constraints and links to run time code. Changes to this file will be overwritten if the ConfGUI
% batch is executed again.
%
% Created on 2008-07-01
% Updated on 2024-03-21

% ---------------------------------------------------------------------
% imgs Image Series
% ---------------------------------------------------------------------
imgs         = cfg_files;
imgs.tag     = 'imgs';
imgs.name    = 'Session';
imgs.help    = {'Select a time series of images for this session.'};
imgs.filter = 'image';
imgs.ufilter = '.*';
imgs.num     = [1 Inf];
imgs.preview = @(f) spm_check_registration(char(f));

% ---------------------------------------------------------------------
% sessions Sessions/Subjects
% ---------------------------------------------------------------------
sessions         = cfg_repeat;
sessions.tag     = 'sessions';
sessions.name    = 'Data';
sessions.help    = {
    'Add new sessions for this subject.'
    'Each series will be processed independently.'
    };
sessions.values  = { imgs };
sessions.num     = [1 Inf];

% ---------------------------------------------------------------------
% vf Create Difference Images
% ---------------------------------------------------------------------
vf         = cfg_menu;
vf.tag     = 'vf';
vf.name    = 'Create Difference Images';
vf.help    = {'Select whether difference images should be written to disk.'};
vf.def = @(val)run_timeseriesqc('defaults','vf',val{:});
vf.labels = {
             'No'
             'Yes'
             }';
vf.values = {
             false
             true
             }';

% ---------------------------------------------------------------------
% timeseriesqc Estimate Timeseries QC
% ---------------------------------------------------------------------
timeseriesqc_est         = cfg_exbranch;
timeseriesqc_est.tag     = 'timeseriesqc_est';
timeseriesqc_est.name    = 'Timeseries QC Estimation';
timeseriesqc_est.val     = {sessions vf };
timeseriesqc_est.help    = {'Run timeseries QC.'};
timeseriesqc_est.prog = @(job)run_timeseriesqc('run','timeseriesqc',job);
timeseriesqc_est.vout = @vout_timeseriesqc;

% ---------------------------------------------------------------------
% fnQC Timeseries Analysis Data Files
% ---------------------------------------------------------------------
fnQC         = cfg_files;
fnQC.tag     = 'fnQC';
fnQC.name    = 'Timeseries QC Output Files';
fnQC.help    = {'Select one or more files. If more than one file is selected, each report will be displayed on a separate page of the SPM graphics window.'};
fnQC.filter = 'mat';
fnQC.ufilter = '^timeseriesqc.mat$';
fnQC.num     = [1 Inf];

% ---------------------------------------------------------------------
% doprint Print to File
% ---------------------------------------------------------------------
doprint         = cfg_menu;
doprint.tag     = 'doprint';
doprint.name    = 'Print to File';
doprint.def = @(val)run_timeseriesqc('defaults','doprint',val{:});
doprint.labels = {
                  'Yes'
                  'No'
                  }';
doprint.values = {
                  true
                  false
                  }';

% ---------------------------------------------------------------------
% timeseriesqc_plot Plot Analysis Results
% ---------------------------------------------------------------------
timeseriesqc_plot         = cfg_exbranch;
timeseriesqc_plot.tag     = 'timeseriesqc_plot';
timeseriesqc_plot.name    = 'Timeseries QC Output Plot';
timeseriesqc_plot.val     = {fnQC doprint };
timeseriesqc_plot.help    = {'Plot output from timeseries QC estimation.'};
timeseriesqc_plot.prog = @(job)run_timeseriesqc('run','timeseriesqc_plot',job);

% ---------------------------------------------------------------------
% timeseriesqc_tools TimeseriesQC
% ---------------------------------------------------------------------
timeseriesqc_tools         = cfg_repeat;
timeseriesqc_tools.tag     = 'timeseriesqc_tools';
timeseriesqc_tools.name    = 'TimeseriesQC';
timeseriesqc_tools.values  = {timeseriesqc_est timeseriesqc_plot };
timeseriesqc_tools.num     = [1 Inf];
timeseriesqc_tools.forcestruct = true;

%==========================================================================
function dep = vout_timeseriesqc(job)
for k=1:numel(job.imgs)
    cdep(1)            = cfg_dep;
    cdep(1).sname      = sprintf('Timeseries QC Output (Sess %d)', k);
    cdep(1).src_output = substruct('.','sess', '()',{k}, '.','tdfile');
    cdep(1).tgt_spec   = cfg_findspec({{'filter','mat','strtype','e'}});
    if k == 1
        dep = cdep;
    else
        dep = [dep cdep];
    end
end
