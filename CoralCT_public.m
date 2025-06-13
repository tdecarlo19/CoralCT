function CoralCT_public
%
% CORALCT analysis tool for computerized tomography (CT) scans and X-rays
% of coral skeletal cores
%
% This is an example version of the code that is released for transparency.
% This script points to an example data server, not the full one. Some data
% submitters have chosen to restrict access to their core images until
% publication, so the full data server location is not publicly released.
% This script is not intended to be used for analysis. Please use the main
% CoralCT app to conduct any measurements. Additionally, this script may
% encounter errors as not all features have been tested following redaction
% of non-public aspects from the main app script. Extra variable names may
% also exist, due to removal of features associated with usernames.
%
% Built with MATLAB 2023a. Other MATLAB versions might encounter lack of
% functionality or errors. As noted above, the CoralCT app should be used
% for doing any actual work, this code is shared for the sake of
% transparency.
%
% Use the MATLAB "Run" button to execute this script and then interact with
% the program through the user interface that opens.
%
%   Please contact Thomas DeCarlo (tdecarlo@tulane.edu) 
%   with any problems, questions, or concerns.
%
%   PLEASE CITE AS:
%   DeCarlo TM, Whelehan A, Hedger B, Perry D, Pompel M, Jasnos O, 
%   Strange A (2024) CoralCT: A platform for transparent and collaborative
%   analyses of growth parameters in coral skeletal cores. Limnology and 
%   Oceanography: Methods.
%   ============================
%
% The MIT License (MIT)
% 
% Copyright (c) 2025 Thomas M. DeCarlo
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.

% ============

% set global variables
global selpath saveCTdata coralDir gen X ha3 UserFig fileOpen row col
global userBands coreIn hpxS layers pxS titleName
global coralName currentSections saveName newRotTotBands xs ys
global slabDraw areWeDone jump2band insertThisBand band2delete coral
global densityWholeCore extension densityTotal volume cracks crackLayers
global bottomCore topCore h2 h3 h3_width h3_std LDBdata totBands2 thisSectionName
global h_drive dirRow thisCoralName band2erase subRegionName
global p_axial p_arc p_box b_points p_degrees t_degrees flipCore x1 y1
global collectionYear collectionMonth moveOn dataOwner serverChoice xrayPos
global xrayDPI smoothed_on dataOwners

% hide standard figures
set(0,'DefaultFigureVisible','off');

CoralCTversion = 2.64;
CoralCTformat = 'mchips'; % 'mchips' (Mac) or 'windows'

themeColor1 = [0.30, 0.75, 0.93];
themeColor2 = [0.89, 0.95, 0.95];
themeColor3 = [0.0824, 0.3098, 0.3961];

% allows some tools to correct previous coralCT band maps to this new
% version. Set to 1 to enable. Generally, this should not be used; it is
% only for the few users of the original coralCT MATLAB scripts.
previous_bands_fixing_mode = 0;

% initialize some defaults
flipCore = 0; % flip core toggle
n_loading_vids = 4; % loading videos of coring
n_loading_vidsCT = 2; % loading videos of cores
ct = 1; % CT or X-ray toggle
smoothed_on = 0; % bands smoothed or "as-clicked" toggle
HU2dens = []; % density calibration equation, in form of HU = m*density + b
crackTol = 1; % pixels in "gap" to define cracks in core. See L&O Methods publication
thresh = []; % initialize, this is for defining skeleton vs surrounding air space
saveLocal = []; % toggle to remember working directory
unsaveLocal = []; % toggle to stope remembering working directory
coastlon = [];
coastlat = [];

% initialize figure, set visibility Off until finished setting up
if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
    UserFig0 = uifigure('Visible','off','Position',[50,100,600,850],'units','normalized','Color','w');
    UserFig = uifigure('Units','pixels','Position',[54,339,1112,800],'units','normalized','Color',themeColor2,'Visible','off');
else
    UserFig = figure('Visible','off','Position',[400,400,600,200],'units','normalized','Color',themeColor2);
end
UserFig.HandleVisibility = 'callback';
iptPointerManager(UserFig, 'enable');

% locate where files are stored
refPath0 = which('ref_file.mat');
refPath0split = strsplit(refPath0,'ref_file.mat');
refPath = refPath0split{1};

% Set location of sftp Server:
ftp_ip1 = 'access-5017242120.webspace-host.com'; % could use different server for login info if desired
ftp_ip2 = 'access-5017242120.webspace-host.com'; % main data location
ftp_user1 = 'a2222258';
ftp_user2 = 'a2222258';
ftp_password = 'We<3Corals';

% loading vid at intro
if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
    dispVidCT = uihtml(UserFig0);
    dispVidCT.Position = [50,90,500,750];
    
    rng('shuffle')
    rand_vidCT = round(rand(1)*(n_loading_vidsCT-1))+1;
    dispVidCT.HTMLSource = (fullfile('loading_movies',strcat('ct_movie',num2str(rand_vidCT),'.html')));

    lblWelcome = uicontrol(UserFig0,'Style','text','String','Welcome to CoralCT',...
        'Position',[170,815,280,35],'Units','normalized','FontSize',20,'FontName','Fanta','Visible','on',...
        'BackgroundColor','w');
end

% label for connection error
if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
    lblFTPerror = uicontrol(UserFig0,'Style','text','String',...
        {'Cannot connect to CoralCache server.';...
        'You may not be connected to the internet, or the server may be temporarily down.';...
        'Please try again later or email us at support@coralct.org for help.'},...
        'units','pixel','Position',[30,200,550,80],'ForegroundColor','r',...
        'units','normalized','BackgroundColor',themeColor2,...
        'FontSize',11,'FontName','Arial','Units','normalized','Visible','off');
else
    lblFTPerror = uicontrol(UserFig,'Style','text','String',...
        {'Cannot connect to CoralCache server.';...
        'You may not be connected to the internet, or the server may be temporarily down.';...
        'Please try again later or email us at support@coralct.org for help.'},...
        'units','pixel','Position',[30,200,550,80],'ForegroundColor','r',...
        'units','normalized','BackgroundColor',themeColor2,...
        'FontSize',11,'FontName','Arial','Units','normalized','Visible','off');
end

% create options for remembering local path
if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
    saveLocal = uicheckbox(UserFig0,'Text','Save selection for next time?','Value',0,'Position',[150,20,200,25],...
        'FontSize',14,'FontName','Arial');

    unsaveLocal = uicheckbox(UserFig0,'Text','Stop remembering location','Value',0,'Position',[50,10,300,25],...
        'FontSize',14,'FontName','Arial','Visible','off');
end

% if cannot find the saved path file, create one with a not real path
try load('saved_path.mat','issavedpath','saved_selpath')
catch
    issavedpath = 0;
    saved_selpath = 'fake_path';
    refPath0 = which('ref_file.mat');
    refPath0split = strsplit(refPath0,'ref_file.mat');
    refPath = refPath0split{1};
    save(fullfile(refPath,'saved_path'),'issavedpath','saved_selpath')
end

% button for saving local path
if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
    lblSavedPath = uicontrol(UserFig0,'Style','text','String',...
        ' ',...
        'units','pixel','Position',[50,70,500,50],...
        'units','normalized','BackgroundColor','w',...
        'FontSize',11,'FontName','Arial','Units','normalized','Visible','off',...
        'horizontalAlignment','left');
else
    lblSavedPath = uicontrol(UserFig,'Style','text','String',...
        ' ',...
        'units','pixel','Position',[50,70,500,50],...
        'units','normalized','BackgroundColor','w',...
        'FontSize',11,'FontName','Arial','Units','normalized','Visible','off',...
        'horizontalAlignment','left');
end

% button for launching main program
if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
    proceedIn = uicontrol(UserFig0,'Style','pushbutton',...
        'String',{'Go!'},'Visible','on',...
        'Position',[520,60,70,70],'Units','normalized','BackgroundColor',[0.61,0.86,0.57],'ForegroundColor',[0,0,0],'FontSize',18,'FontName','Arial','Callback',@proceed_fun);
else
    proceedIn = uicontrol(UserFig,'Style','pushbutton',...
        'String',{'Go!'},'Visible','on',...
        'Position',[520,60,70,70],'Units','normalized','BackgroundColor',[0.61,0.86,0.57],'ForegroundColor',[0,0,0],'FontSize',18,'FontName','Arial','Callback',@proceed_fun);
end

% if the local path has been saved, use that
if issavedpath == 1
    selpath = saved_selpath;

    set(lblSavedPath,'Visible','on','String',...
        sprintf('Local directory is:\n %s',selpath))

    chooseDirIn = uicontrol(UserFig0,'Style','pushbutton',...
        'String',{'Change path'},'Visible','on',...
        'Position',[50,40,200,30],'Units','normalized','BackgroundColor',[0.7 0.7 0.7],'ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial','Callback',@chooseDir_fun);

    set(saveLocal,'Visible','off')
    set(unsaveLocal,'Visible','on')
    set(proceedIn,'Visible','on')

else % otherwise, create button to choose the local path

    set(proceedIn,'Visible','off')

    if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
        chooseDirIn = uicontrol(UserFig0,'Style','pushbutton',...
            'String',{'Choose local working directory'},'Visible','on',...
            'Position',[150,60,300,60],'Units','normalized','BackgroundColor',[0.61,0.86,0.57],'ForegroundColor',[0,0,0],'FontSize',14,'FontName','Arial','Callback',@chooseDir_fun);
    else
        chooseDirIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Choose local working directory'},'Visible','on',...
            'Position',[150,60,300,60],'Units','normalized','BackgroundColor',[0.61,0.86,0.57],'ForegroundColor',[0,0,0],'FontSize',14,'FontName','Arial','Callback',@chooseDir_fun);
    end
end

% start the main program
    function proceed_fun(src,event)
        uiresume(UserFig0)
    end

% set local path function
    function chooseDir_fun(src,event)
        set(chooseDirIn,'Visible','off')
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            set(UserFig0,'Visible','off')
        end
        selpath = uigetdir([],'Choose your local working folder');
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            uiresume(UserFig0)
        else
            uiresume(UserFig)
            set(UserFig,'Units','Pixels','Position',[54,339,1112,800],'Units','normalized')
        end
    end

% make sure we can connect to sftp server 1
try cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
catch
    if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
        set(UserFig0,'Visible','on')
        set(lblFTPerror,'Visible','on')
    end
end

% make sure we can access CoralCache folder of sftp server 1
try cd(cache1,'/CoralCache');
catch
    if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
        set(UserFig0,'Visible','on')
        set(lblFTPerror,'Visible','on')
    end
end

% button to see explanation of local path
if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
    selectDirHelpIn = uicontrol(UserFig0,'Style','pushbutton',...
        'String',{'Help'},'Visible','on',...
        'Position',[540,10,50,30],'Units','normalized','BackgroundColor',[255, 189, 68]/256,'ForegroundColor',[0,0,0],'FontSize',11,'FontName','Arial','Callback',@selectDirHelp_fun);
    htextLink1 = uihyperlink(UserFig0,'URL','https://www.sclerochronologylab.com/coralct.html','Text','www.coralct.org',...
        'FontSize',14,'FontName','Arial','Visible','on','Position',[390,10,120,30]);
else
    selectDirHelpIn = uicontrol(UserFig,'Style','pushbutton',...
        'String',{'Help'},'Visible','off',...
        'Position',[540,10,50,30],'Units','normalized','BackgroundColor',[255, 189, 68]/256,'ForegroundColor',[0,0,0],'FontSize',11,'FontName','Arial','Callback',@selectDirHelp_fun);
end

% explanation of local path
if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
    lblselectDirHelp = uicontrol(UserFig0,'Style','text','String',...
        {'Please select a folder on your computer where CoralCT files will be stored.';...
        'Files including core metadata, map data, CT scans, and any downloaded datasets';...
        'will be stored in this folder.'},...
        'units','pixel','Position',[30,150,550,60],'ForegroundColor','k',...
        'units','normalized','BackgroundColor','w',...
        'FontSize',11,'FontName','Arial','Units','normalized','Visible','off');
else
    lblselectDirHelp = uicontrol(UserFig,'Style','text','String','','Visible','off');
end

% turn on help label
function selectDirHelp_fun(src,event)
    set(lblselectDirHelp,'Visible','on')
end

% Pause while we wait for decision on local directory
if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
    uiwait(UserFig0)
else
    uiwait(UserFig)
end

% if decided to newly save local path, do that now
if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
    if saveLocal.Value == 1
        issavedpath = 1;
        saved_selpath = selpath;
        refPath0 = which('ref_file.mat');
        refPath0split = strsplit(refPath0,'ref_file.mat');
        refPath = refPath0split{1};
        save(fullfile(refPath,'saved_path'),'issavedpath','saved_selpath')
    end

    try % if chose to stop remembering local path, remove that now
        if unsaveLocal.Value == 1
            issavedpath = 0;
            saved_selpath = 'fake_path';
            refPath0 = which('ref_file.mat');
            refPath0split = strsplit(refPath0,'ref_file.mat');
            refPath = refPath0split{1};
            save(fullfile(refPath,'saved_path'),'issavedpath','saved_selpath')
        end
    catch
    end
end

% turn off features of first figure (we will just close it later)
set(chooseDirIn,'Visible','off')
set(proceedIn,'Visible','off')
set(lblselectDirHelp,'Visible','off')
set(selectDirHelpIn,'Visible','off')
set(htextLink1,'Visible','off')
set(unsaveLocal,'Visible','off')
set(saveLocal,'Visible','off')
set(unsaveLocal,'Visible','off')
set(lblSavedPath,'Visible','off')

% loading text while we set up main figure
if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
    lblLoadingIntro = uicontrol(UserFig0,'Style','text','String',...
        {'Loading, please wait'},...
        'units','pixel','Position',[100,50,400,60],'ForegroundColor','k',...
        'units','normalized','BackgroundColor','none',...
        'FontSize',16,'FontName','Arial','Units','normalized','Visible','on');
else
    lblLoadingIntro = uicontrol(UserFig,'Style','text','String',...
        {'Loading, please wait'},...
        'units','pixel','Position',[100,50,400,60],'ForegroundColor','k',...
        'units','normalized','BackgroundColor','none',...
        'FontSize',16,'FontName','Arial','Units','normalized','Visible','off');
end

pause(0.01) % to ensure refreshed figures

% download the core master directory from the sftp server and save it on the
% local driver in a folder called "my_corals"
try mget(cache1,'coral_directory_master.txt',fullfile(selpath,'my_corals'));
catch
    cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password); % make sure we can connect to sftp server 1
    cd(cache1,'/CoralCache');
    mget(cache1,'coral_directory_master.txt',fullfile(selpath,'my_corals'));
end

% import master directory into this session
coralDir = importdata(fullfile(selpath,'my_corals','coral_directory_master.txt'));

% button for checking latest version
latestVersionIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Check for updates'},'Visible','on',...
    'Position',[180,10,180,40],'Units','normalized','BackgroundColor',[255, 189, 68]/256,'ForegroundColor',[0,0,0],'FontSize',14,'FontName','Arial','Callback',@checkVersion_fun);

keepLatestLabel = 0; % toggle for which message to show
latest_version = []; % to display latest version number
    function checkVersion_fun(src,event)
        set(latestVersionIn,'Visible','off')
        set(lblCheckingUpdates,'Visible','on')
        pause(0.01)
        mget(cache1,'latest_version.csv',refPath);
        latest_version = importdata(fullfile(refPath,'latest_version.csv'));
        delete(fullfile(refPath,'latest_version.csv'))
        if latest_version == CoralCTversion % we are up to date
        else
            set(lblneed2Update,'Visible','on')
            keepLatestLabel = 1;
            if length(num2str(latest_version)) == 3
                set(lblneed2Update,'String',sprintf('Version %s is now available',num2str(round(latest_version*10)/10)));
            elseif length(num2str(latest_version)) == 4
                set(lblneed2Update,'String',sprintf('Version %s is now available',strcat(num2str(floor(latest_version*10)/10),'.',num2str(round((latest_version-floor(latest_version*10)/10)*100)))));
            end
            set(downloadLatestVersionIn,'Visible','on')
        end
        set(lblCheckingUpdates,'Visible','off')
    end

lblCheckingUpdates = uicontrol(UserFig,'Style','text','String','Checking for updates, please wait...',...
    'Position',[100,95,400,20],'Units','normalized','FontSize',11,'FontName','Arial','Visible','off');

lblUp2date = uicontrol(UserFig,'Style','text','String','You have the latest version of CoralCT',...
    'Position',[100,110,280,20],'Units','normalized','FontSize',12,'FontName','Arial','Visible','off');

lblneed2Update = uicontrol(UserFig,'Style','text','String',' ',...
    'Position',[100,145,215,20],'Units','normalized','FontSize',12,'FontName','Arial','Visible','off');

downloadLatestVersionIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Download new version'},'Visible','off',...
    'Position',[100,100,210,40],'Units','normalized','BackgroundColor',[255, 189, 68]/256,'ForegroundColor',[0,0,0],'FontSize',14,'FontName','Arial','Callback',@getNewVersion_fun);

    function getNewVersion_fun(src,event)
        set(gettingLatestVersion,'Visible','on')
        set(downloadLatestVersionIn,'Visible','off')
        set(lblneed2Update,'Visible','off')
        set(lblUpdatedServer,'Visible','off')
        set(lblUp2date,'Visible','off')
        pause(0.01)
        mget(cache1,strcat('latest_weblink_',CoralCTformat,'.csv'),refPath);
        latest_url = importdata(fullfile(refPath,strcat('latest_weblink_',CoralCTformat,'.csv')));
        delete(fullfile(refPath,strcat('latest_weblink_',CoralCTformat,'.csv')))
        dload_success = 0;
        try
            if strcmp('MACI64',computer)
                dlDir = fullfile('/Users',char(java.lang.System.getProperty('user.name')), 'Downloads');
                websave(fullfile(dlDir,'coralct-install'),latest_url{1});
            else
                dlDir = fullfile(getenv('USERPROFILE'), 'Downloads');
                websave(fullfile(dlDir,'coralct-install'),latest_url{1});
            end
            dload_success = 1;
        catch
            try
                websave(fullfile(selpath,'CoralCT_installer'),latest_url{1});
                unzip(fullfile(selpath,'CoralCT_installer.zip'),fullfile(selpath,'CoralCT_installer'));
                delete(fullfile(selpath,'CoralCT_installer.zip'))
                dload_success = 1;
            catch
            end
        end
        if dload_success == 0
            set(lblGotLatestVersion,'String','Download not successful. Please go to www.coralct.org')
        end
        set(lblGotLatestVersion,'Visible','on')
        set(gettingLatestVersion,'Visible','off')
    end

lblGotLatestVersion = uicontrol(UserFig,'Style','text','String','Check your Downloads folder for install file.',...
    'Position',[100,120,400,20],'Units','normalized','FontSize',11,'FontName','Arial','Visible','off');

lblGotLatestVersionHelp = uicontrol(UserFig,'Style','text','String','Go to www.coralct.org for help',...
    'Position',[100,95,400,20],'Units','normalized','FontSize',11,'FontName','Arial','Visible','off');

gettingLatestVersion = uicontrol(UserFig,'Style','text','String','Downloading, please wait...',...
    'Position',[100,95,400,20],'Units','normalized','FontSize',11,'FontName','Arial','Visible','off');

gettingUserGuide = uicontrol(UserFig,'Style','text','String','Check your downloads',...
    'Position',[780,710,200,60],'Units','normalized','FontSize',11,'FontName','Arial','Visible','off');

gettingUserGuideFail = uicontrol(UserFig,'Style','text','String',{'Something went wrong.';'Download user guide from';'www.coralct.org'},...
    'Position',[780,710,200,60],'Units','normalized','FontSize',11,'FontName','Arial','Visible','off');

getUserGuideIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Download';'User-Guide'},'Visible','on',...
    'Position',[780,710,160,60],'Units','normalized','BackgroundColor',[255, 189, 68]/256,'ForegroundColor',[0,0,0],'FontSize',14,'FontName','Arial','Callback',@downloadguide_fun);

% download current user guide
    function downloadguide_fun(src,event)
        set(getUserGuideIn,'Visible','off')
        pause(0.01)
        mget(cache1,'latest_userguide_link.csv',refPath);
        latest_url = importdata(fullfile(refPath,'latest_userguide_link.csv'));
        delete(fullfile(refPath,'latest_userguide_link.csv'))
        try
            if strcmp('MACI64',computer)
                dlDir = fullfile('/Users',char(java.lang.System.getProperty('user.name')), 'Downloads');
                websave(fullfile(dlDir,'CoralCT-UserGuide'),latest_url{1});
            else
                dlDir = fullfile(getenv('USERPROFILE'), 'Downloads');
                websave(fullfile(dlDir,'CoralCT-UserGuide'),latest_url{1});
            end
        catch
            set(gettingUserGuideFail,'Visible','on')
        end
        set(gettingUserGuide,'Visible','on')
    end

% Get the list of "regions" (column 3)
% Note we skip row 1 because it's the header information
regionList = unique(coralDir.textdata(2:end,3));

% Print text on figure to say we will check registration
lblVerifying = uicontrol(UserFig,'Style','text','String','We will email you soon once your registration is confirmed',...
    'Position',[150,590,700,30],'Units','normalized','FontSize',12,'FontName','Arial','Visible','off');

loginIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Login'},'Visible','on',...
    'Position',[600,710,160,60],'Units','normalized','FontSize',14,'FontName','Arial','BackgroundColor',themeColor1,'Callback',@login);

noSuchUser = uicontrol(UserFig,'Style','text','String','Username does not exist',...
    'Position',[250,600,500,20],'Units','normalized','FontSize',12,'FontName','Arial','Visible','off');

wrongPassword = uicontrol(UserFig,'Style','text','String','Incorrect password',...
    'Position',[250,600,500,20],'Units','normalized','FontSize',12,'FontName','Arial','Visible','off');

htextHelp = uicontrol(UserFig,'Style','text','String','Email us at support@coralct.org for assistance',...
    'Position',[650,15,500,20],'Units','normalized','FontSize',10,'FontName','Arial','Visible','on');

htextLink2 = uihyperlink(UserFig,'URL','https://www.sclerochronologylab.com/coralct.html','Text','www.coralct.org',...
    'Position',[575,15,500,20],'FontSize',14,'FontName','Arial','Visible','on');

htextLink3 = uihyperlink(UserFig,'URL','https://www.sclerochronologylab.com/coralct.html','Text','www.coralct.org',...
    'Position',[980,15,125,24],'FontSize',14,'FontName','Arial','Visible','off');

uiAbout = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'About'},'Visible','on',...
    'Position',[400,15,100,30],'Units','normalized','FontSize',12,'FontName','Arial','Callback',@about_callback);

uiAboutCancel = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Go back'},'Visible','off',...
    'Position',[400,15,100,30],'Units','normalized','FontSize',12,'FontName','Arial','Callback',@aboutCancel_callback);

htextAbout = uicontrol(UserFig,'Style','text','String',' ',...
    'Position',[150,200,500,400],'Units','normalized','FontSize',10,'FontName','Arial','Visible','off');

    function about_callback(src,event)

        about_text_label = sprintf(['CoralCT is a software program for analysis of computed tomography ' ...
            '(CT) scans or X-ray images of coral skeletal cores. This version of CoralCT is linked with CoralCache, which is ' ...
            'a repository of coral skeletal core CT scans collected around the world. For more information about how to use CoralCT, please ' ...
            'visit www.coralct.org. CoralCT and CoralCache were developed by Dr. Tom DeCarlo, with contributions ' ...
            'from Ally Whelehan, Maya Pompel, Avi Strange, and Oliwia Jasnos, and funding support from the National Science Foundation (award 2444864).\n\n' ...
            'CoralCT is a shared community resource. We encourage submissions of any available coral core CT scans. We also ' ...
            'welcome new analyses of growth rates based on the datasets stored in CoralCache. Coral cores that have ' ...
            'been used in publications should be shared openly. However, we also encourage submissions of unpublished CT scans, ' ...
            'and we are able to restrict access to data from certain cores at the request of the submitter. Please note that ' ...
            'CoralCT can only be used with cores that are stored on CoralCache. When using data from CoralCache, please be careful to cite ' ...
            'appropriate publications or acknowledge those who collected the cores. The appropriate citations and/or '...
            'acknowledgements are displayed in the output .csv file of each core.\n\nEmail us at support@coralct.org with questions ' ...
            'or for assistance with submitting datasets.']);

        set(htextAbout,'String',about_text_label)

        about_text_wrapped = textwrap(htextAbout,{htextAbout.String});

        %set(htextAbout,'String',about_text_wrapped,'Visible','on','Units','pixels',...
        %    'Position',[200,200,800,400],'Units','normalized','HorizontalAlignment', 'left')

        set(htextAbout,'String',about_text_label,'Visible','on','Units','pixels',...
            'Position',[200,200,800,400],'Units','normalized','HorizontalAlignment', 'left')

        set(h_map_cover,'Visible','off')
        set(loginIn,'Visible','off')
        set(UserSetIn,'Visible','off')
        set(htextUser,'Visible','off')
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            set(saveLogin, 'Visible','off')
        end
        set(htextPassword,'Visible','off')
        set(passwordIn,'Visible','off')
        set(noSuchUser,'Visible','off')
        set(wrongPassword,'Visible','off')
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            set(htextLeaders,'Visible','off')
            set(htextLeadersYTD,'Visible','off')
            set(htextTotalCores,'Visible','off')
            set(leaderBoard,'Visible','off')
            set(leaderBoard_2,'Visible','off')
        end
        set(latestVersionIn,'Visible','off')
        set(downloadLatestVersionIn,'Visible','off')
        set(gettingUserGuideFail,'Visible','off')
        set(getUserGuideIn,'Visible','off')
        set(gettingUserGuide,'Visible','off')
        set(lblneed2Update,'Visible','off')
        set(lblUp2date,'Visible','off')
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            set(saveLogin,'Visible','off')
        end
        set(uiAboutCancel,'Visible','off')
        set(uiAbout,'Visible','off')

        set(uiAboutCancel,'Visible','on')
        set(uiAbout,'Visible','off')

    end

    function aboutCancel_callback(src,event)

        set(uiAboutCancel,'Visible','off')
        set(uiAbout,'Visible','on')
        set(htextAbout,'Visible','off')

        set(h_map_cover,'Visible','on')
        set(loginIn,'Visible','on')
        set(UserSetIn,'Visible','on')
        set(htextUser,'Visible','on')
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            set(saveLogin, 'Visible','on')
        end
        set(htextPassword,'Visible','on')
        set(passwordIn,'Visible','on')
        set(noSuchUser,'Visible','on')
        set(wrongPassword,'Visible','on')
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            set(htextLeaders,'Visible','on')
            set(htextLeadersYTD,'Visible','on')
            set(htextTotalCores,'Visible','on')
            set(leaderBoard,'Visible','on')
            set(leaderBoard_2,'Visible','on')
        end
        set(latestVersionIn,'Visible','on')
        set(downloadLatestVersionIn,'Visible','off')
        set(getUserGuideIn,'Visible','on')
        if keepLatestLabel == 1
            set(lblneed2Update,'Visible','on')
        else
            set(lblneed2Update,'Visible','off')
        end
        set(lblUp2date,'Visible','off')
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            set(saveLogin,'Visible','on')
        end

    end

if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
    saveLogin = uicheckbox(UserFig,'Text','Remember me?','Value',0,'Position',[600,670,150,25],...
        'FontSize',14,'FontName','Arial');
end

% initialize map
pWorldMap = [];

saveFileName = [];

% login function
    function login(src,event)

        lblLoading = uicontrol(UserFig,'Style','text','String','Loading, please wait',...
            'Position',[250,560,500,40],'Units','normalized','FontSize',12,'FontName','Arial','Visible','on');

        pause(0.001)

        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            if saveLogin.Value == 1
                checkedIn = 0;
            elseif saveLogin.Value == 0 && checkedIn == 1
                checkedIn = 0;
            end
        end

        if checkedIn == 0

            try
            mget(cache1,'user_directory_names.csv',refPath);
            catch
                try
                    cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                    cd(cache1,'CoralCache')
                    mget(cache1,'user_directory_names.csv',refPath);
                catch
                    try
                        connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                        connectionEstablished = 0;
                        for ij = 1:length(connectTimes)
                            if connectionEstablished == 0
                                if connectTimes(ij) == 1
                                    waitText = [' ',num2str(connectTimes(ij)),' minute.']
                                else
                                    waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                                end
                                set(lblLoading,'Units','Pixels','Visible','on',...
                                    'String',{'Error connecting to server.';strcat('Trying again in',waitText)})
                                pause(connectTimes(ij)*60)
                                try
                                    cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                    cd(cache1,'CoralCache')
                                    mget(cache1,'user_directory_names.csv',refPath);
                                    connectionEstablished = 1;
                                    set(lblLoading,'Visible','off')
                                catch
                                end
                            end
                        end
                        if connectionEstablished == 0
                            zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                        end
                    catch
                        set(lblLoading,'Visible','on',...
                            'String',{'Error connecting to server. (code 025)';'Please try again later.'})
                        while 1==1
                            pause
                        end
                    end
                end
            end
            fid = fopen(fullfile(refPath,'user_directory_names.csv'));
            users = textscan(fid,'%s %s %s %s %s','Delimiter',',');
            try fclose(fid);
            catch
            end
            try delete(fullfile(refPath,'user_directory_names.csv'))
            catch
            end
            idx = find(strcmp(users{1},UserSetIn.String));
            if length(idx) > 0
                if strcmp(users{2}{idx},passwordIn.String)
                    loginSuccess = 1;
                    if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
                        if saveLogin.Value == 1
                            C = [{UserSetIn.String}, {passwordIn.String}];
                            fid6 = fopen(fullfile(selpath,'my_login.csv'));
                            writecell(C,fullfile(selpath,'my_login.csv'));
                            try fclose(fid6);
                            catch
                            end
                            savedLoginFilename = fullfile(selpath,strcat(UserSetIn.String,'_',passwordIn.String,'.csv'));
                            fid7 = fopen(savedLoginFilename);
                            writecell(C,savedLoginFilename);
                            try fclose(fid7);
                            catch
                            end
                            try mput(cache1,savedLoginFilename)
                            catch
                                savedLoginFilename = fullfile(selpath,strcat(UserSetIn.String,'_saved_pwd.csv'));
                                fid7 = fopen(savedLoginFilename);
                                writecell(C,savedLoginFilename);
                                try fclose(fid7);
                                catch
                                end
                                mput(cache1,savedLoginFilename)
                            end
                            delete(savedLoginFilename);
                        end
                    end
                else
                    try delete(lblLoading)
                    catch
                    end
                    loginSuccess = 0;
                    set(wrongPassword,'Visible','on')
                    set(noSuchUser,'Visible','off')
                end
            else
                try delete(lblLoading)
                catch
                end
                set(noSuchUser,'Visible','on')
                set(wrongPassword,'Visible','off')
            end
        end

        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            if saveLogin.Value == 0
                try delete(fullfile(selpath,'my_login.csv'));
                catch
                end
                try
                    savedLoginFilename = fullfile(strcat(UserSetIn.String,'_',passwordIn.String,'.csv'));
                    delete(cache1,savedLoginFilename)
                catch
                end
            end
        end

        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            if checkedIn == 1 && saveLogin.Value == 1
                if strcmp(UserSetIn.String,my_login{1}{1})
                    if strcmp(passwordIn.String,my_login{2}{1})
                        loginSuccess = 1;
                    else
                        loginSuccess = 0;
                        try delete(lblLoading)
                        catch
                        end
                        set(wrongPassword,'Visible','on')
                        set(noSuchUser,'Visible','off')
                    end
                else
                    loginSuccess = 0;
                    try delete(lblLoading)
                    catch
                    end
                    set(noSuchUser,'Visible','on')
                    set(wrongPassword,'Visible','off')
                end
            end
        end

        if loginSuccess == 1

            set(h_map_cover,'Visible','off')
            set(loginIn,'Visible','off')
            set(UserSetIn,'Visible','off')
            set(htextUser,'Visible','off')
            set(htextPassword,'Visible','off')
            set(passwordIn,'Visible','off')
            set(noSuchUser,'Visible','off')
            set(wrongPassword,'Visible','off')
            set(htextHelp,'Visible','off')
            set(htextLink2,'Visible','off')
            if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
                set(htextLeaders,'Visible','off')
                set(htextLeadersYTD,'Visible','off')
                set(htextTotalCores,'Visible','off')
                set(leaderBoard,'Visible','off')
                set(leaderBoard_2,'Visible','off')
                set(saveLogin,'Visible','off')
                set(saveLogin, 'Visible','off')
            end
            set(latestVersionIn,'Visible','off')
            set(downloadLatestVersionIn,'Visible','off')
            set(gettingUserGuideFail,'Visible','off')
            set(getUserGuideIn,'Visible','off')
            set(gettingUserGuide,'Visible','off')
            set(lblneed2Update,'Visible','off')
            set(lblUp2date,'Visible','off')
            set(uiAboutCancel,'Visible','off')
            set(uiAbout,'Visible','off')

            mainMenu

            set(0,'CurrentFigure',figtemp1);
            pWorldMap = worldmap([-90 90],[20 380]);
            plabel('off')
            mlabel('off')
            %geoshow('landareas.shp', 'FaceColor', [0 0 0])
            load('coastlines.mat')
            patchm(coastlat,coastlon,'k','EdgeColor','none')
            plotm(coralDir.data(:,3),coralDir.data(:,4),'ko','MarkerEdgeColor','k', 'MarkerFaceColor',[0.96,0.51,0.58]);

            try delete(lblLoading)
            catch
            end
            pause(0.01)
            axcopy = copyobj(pWorldMap.Children,h_map1);
            pause(0.001)

        end
        try delete(fullfile(refPath,'user_directory_names.csv'));
        catch
        end
        try delete(lblLoading)
        catch
        end
    end

if length(num2str(CoralCTversion)) == 3
    versionText = sprintf('Version %s is now available',num2str(round(CoralCTversion*10)/10));
elseif length(num2str(CoralCTversion)) == 4
    versionText = strcat(num2str(floor(CoralCTversion*10)/10),'.',num2str(round((CoralCTversion-floor(CoralCTversion*10)/10)*100)));
end

%Coral CT text on figure
htextCoralCT = uicontrol(UserFig,'Style','text','String',sprintf('CoralCT v%s',versionText),...
    'Position',[1,10,150,25],'Units','normalized','BackgroundColor','none','ForegroundColor',themeColor1,'FontSize',12,'FontName','Fanta');

% can use this for broadcasting message to all users when opening app
try mget(cache1,'outdated_message.csv',refPath);
    fid3 = fopen(fullfile(refPath,'outdated_message.csv'));
    check_outdated = textscan(fid3,'%s %s','Delimiter',',');
    try fclose(fid3);
    catch
    end
    check_vers = str2num(check_outdated{1}{1});
    if check_vers > CoralCTversion
        htextOutdated = uicontrol(UserFig,'Style','text','String',check_outdated{2},...
            'Position',[170,550,900,25],'Units','normalized','BackgroundColor',themeColor2,'ForegroundColor',[1 0 0],'FontSize',12,'FontName','Fanta');
        checkVersion_fun
    end
    delete(fullfile(refPath,'outdated_message.csv'))
catch
end

% Print text on figure to toggle saving the scan or not
htextSave = uicontrol(UserFig,'Style','text','String','Save CT data on your drive?','Visible','off',...
    'Position',[85,720,200,25],'Units','normalized','FontSize',10,'FontName','Arial');

% Create dropdown menu for user to choose to save the scan locally or not.
% This just means that, if yes, there is a folder saved locally that is
% titled with the core name. If no, the folder is just titled "dicoms" and
% it will be deleted the next time the CoralCT program is started.
saveDataIn = uicontrol(UserFig,'Style','popupmenu',...
    'Position',[60,700,250,25],'Units','normalized',...
    'String',{'No','Yes'},'Visible','off',...
    'Callback',@choose2save);

% Function to store the user input choice for saving scan data
saveCTdata = 0; % initialize (and set as default to not save)
    function choose2save(src,event)
        if saveDataIn.Value == 2 % second option, which is 'yes'
            saveCTdata = 1;
        else
            saveCTdata = 0;
        end
        if (any(areDataUnlocked<0)||any(areDataUnlocked>2))
            saveDataIn.Value = 1;
            saveCTdata = 0;
        end
    end

% initialize some variables to store core selections:
currentSubRegions = ' ';
currentRegion = [];
subRegionIn = [];
currentSubRegion = [];
sectionIn = [];
currentCores = ' ';

% Print text on figure to type in username
htextUser = uicontrol(UserFig,'Style','text','String','Username:',...
    'Position',[320,750,150,25],'Units','normalized','BackgroundColor',themeColor1,'ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial');

% Create edit bar for user to type username
UserSetIn = uicontrol(UserFig,'Style','Edit','String','TestUser1',...
    'Position',[475,750,100,25],'Units','normalized','Callback', @UserSet_Callback);
saveFileName = UserSetIn.String;

% Default username (if none given):
% saveFileName = 'undefined';

% Function to store username
    function UserSet_Callback(src,event)
        saveFileName = UserSetIn.String;
    end

% Print text on figure to type in email
htextEmail = uicontrol(UserFig,'Style','text','String','email:','Visible','off',...
    'Position',[600,750,150,25],'Units','normalized','BackgroundColor',themeColor1,'ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial');

% Create edit bar for user to type email
emailIn = uicontrol(UserFig,'Style','Edit','Visible','off',...
    'Position',[760,750,150,25],'Units','normalized','Callback', @UserSet_Callback);

% Print text on figure to type in password
htextPassword = uicontrol(UserFig,'Style','text','String','Password:',...
    'Position',[320,710,150,25],'Units','normalized','BackgroundColor',themeColor1,'ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial');

% Create edit bar for user to type password
passwordIn = uicontrol(UserFig,'Style','Edit','String','TestPassword1',...
    'Position',[475,710,100,25],'Units','normalized','Callback', @password_Callback);

% Print text on figure to type in password again
htextPasswordConfirm = uicontrol(UserFig,'Style','text','String','Confirm password:','Visible','off',...
    'Position',[600,710,150,25],'Units','normalized','BackgroundColor',themeColor1,'ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial');

% Create edit bar for user to type password again
passwordInConfirm = uicontrol(UserFig,'Style','Edit','Visible','off',...
    'Position',[760,710,100,25],'Units','normalized','Callback', @password_Callback);

% Print text on figure to type in first name
htextFirstName = uicontrol(UserFig,'Style','text','String','First Name:','Visible','off',...
    'Position',[320,710,150,25],'Units','normalized','BackgroundColor',themeColor1,'ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial');

name1 = '';
% Create edit bar for user to type first name
firstNameIn = uicontrol(UserFig,'Style','Edit','Visible','off',...
    'Position',[475,710,100,25],'Units','normalized','Callback', @name1_Callback);

% Print text on figure to type in last name
htextLastName = uicontrol(UserFig,'Style','text','String','Last Name:','Visible','off',...
    'Position',[600,710,150,25],'Units','normalized','BackgroundColor',themeColor1,'ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial');

name2 = '';
% Create edit bar for user to type last name
lastNameIn = uicontrol(UserFig,'Style','Edit','Visible','off',...
    'Position',[760,710,100,25],'Units','normalized','Callback', @name2_Callback);

% Function to store username
    function password_Callback(src,event)
        saveFileName = UserSetIn.String;
    end

% Function to store user's first name
    function name1_Callback(src,event)
        name1 = firstNameIn.String;
    end

% Function to store user's last name
    function name2_Callback(src,event)
        name2 = lastNameIn.String;
    end

checkedIn = 0;
loginSuccess = 0;

my_login = [];

if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')

    % Leaderboard
    htextLeaders = uicontrol(UserFig,'Style','text','String','Overall Leaderboard','Visible','on',...
        'Position',[200,490,250,30],'Units','normalized','BackgroundColor','none',...
        'ForegroundColor',themeColor1,'FontSize',16,'FontName','Arial');

    htextLeadersYTD = uicontrol(UserFig,'Style','text','String',strcat(char(datetime('today'),'yyyy'),' Leaderboard'),'Visible','on',...
        'Position',[635,490,250,30],'Units','normalized','BackgroundColor','none',...
        'ForegroundColor',themeColor1,'FontSize',16,'FontName','Arial');

    htextTotalCores = uicontrol(UserFig,'Style','text','String',...
        sprintf('Total cores in CoralCache: %s',num2str(length(unique(coralDir.textdata(2:end,1))))),...
        'Visible','on',...
        'Position',[335,160,420,30],'Units','normalized','BackgroundColor','none',...
        'ForegroundColor',themeColor1,'FontSize',14,'FontName','Arial');

    cmap_leader =       [0.8575    0.9443    0.7258
        0.7165    0.8965    0.6706
        0.5711    0.8479    0.6422
        0.4443    0.7922    0.6399
        0.3642    0.7277    0.6430
        0.3214    0.6597    0.6383
        0.2947    0.5918    0.6264
        0.2722    0.5253    0.6113
        0.2528    0.4593    0.5967
        0.2421    0.3916    0.5830];

    mget(cache1,'leaderboard_names.xlsx',refPath);

    [leader_data,leader_text,leader_raw] = xlsread(fullfile(refPath,'leaderboard_names.xlsx'));
    delete(fullfile(refPath,'leaderboard_names.xlsx'))

    [val, leadersIdx] = sortrows([leader_data(:,2),leader_data(:,1)],'descend');

    %leaderNames = leader_text(leadersIdx+1,1);
    leaderNames = cell(length(leadersIdx),1);
    for i7 = 1:length(leaderNames)
        leaderNames(i7) = {[leader_text{leadersIdx(i7)+1,2} ' ' leader_text{leadersIdx(i7)+1,3}]};
    end
    leaderData2Print1 = leader_data(leadersIdx,1);
    leaderData2Print2 = leader_data(leadersIdx,2);
    leaderBoardTable = table([leaderData2Print1(1:10);sum(leader_data(:,1))],...
        [leaderData2Print2(1:10);sum(leader_data(:,2))]);
    leaderNames2Print = leaderNames(1:10);
    leaderNames2Print{11} = 'Totals';
    leaderBoardTable.Properties.RowNames = leaderNames2Print;
    leaderBoardTable.Properties.VariableNames = {'Cores processed','Bands processed'};

    leaderBoard = uitable(UserFig,'Data',leaderBoardTable,'Position',[200 205 420 285],...
        'Visible','on','Units','normalized');
    leaderStyle1 = uistyle('HorizontalAlignment','center');
    addStyle(leaderBoard,leaderStyle1,'table','')
    leaderStyle2 = uistyle('FontWeight','bold');
    addStyle(leaderBoard,leaderStyle2,'table','')
    [val,idxLeader] = sort(leaderData2Print1,'descend');
    for iL = 1:length(idxLeader)
        thisCol = iL;
        if thisCol>10
            thisCol = 10;
        end
        lCol = uistyle("BackgroundColor",cmap_leader(thisCol,:));
        addStyle(leaderBoard,lCol,"cell",[iL,2])
        addStyle(leaderBoard,lCol,"cell",[idxLeader(iL),1])
    end
    lColT = uistyle("BackgroundColor",[0.9928    0.9944    0.8001]);
    addStyle(leaderBoard,lColT,"row",11)


    [val, leadersIdx_2] = sortrows([leader_data(:,3),leader_data(:,1)],'descend');
    %leaderNames_2 = leader_text(leadersIdx_2+1,1);
    leaderNames_2 = cell(length(leadersIdx_2),1);
    for i7 = 1:length(leaderNames)
        leaderNames_2(i7) = {[leader_text{leadersIdx_2(i7)+1,2} ' ' leader_text{leadersIdx_2(i7)+1,3}]};
    end
    leaderData2Print1_2 = leader_data(leadersIdx_2,3);
    leaderBoardTable_2 = table([leaderData2Print1_2(1:10);sum(leader_data(:,3))]);
    leaderNames2Print_2 = leaderNames_2(1:10);
    leaderNames2Print_2{11} = 'Totals';
    leaderBoardTable_2.Properties.RowNames = leaderNames2Print_2;
    leaderBoardTable_2.Properties.VariableNames = {'Bands year-to-date'};

    leaderBoard_2 = uitable(UserFig,'Data',leaderBoardTable_2,'Position',[660 205 280 285],...
        'Visible','on','Units','normalized');
    leaderStyle1_2 = uistyle('HorizontalAlignment','center');
    addStyle(leaderBoard_2,leaderStyle1_2,'table','')
    leaderStyle2_2 = uistyle('FontWeight','bold');
    addStyle(leaderBoard_2,leaderStyle2_2,'table','')
    for iL = 1:10
        lCol = uistyle("BackgroundColor",cmap_leader(iL,:));
        addStyle(leaderBoard_2,lCol,"cell",[iL,1])
    end
    lColT = uistyle("BackgroundColor",[0.9928    0.9944    0.8001]);
    addStyle(leaderBoard_2,lColT,"row",11)

end

% Button for data submission:
SubmitDataIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Submit data'},'Visible','off',...
    'Position',[680,730,160,60],'Units','normalized','BackgroundColor',[130, 196, 153]./255,'FontSize',14,'FontName','Arial','Callback',@submitData);

set(UserFig,'Visible','off')

% Button for returning to main menu from data access mode:
mainMenuIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Return to main menu'},'Visible','off',...
    'Position',[680,730,320,60],'Units','normalized','BackgroundColor',[0.51, 0.77, 0.59],...
    'FontSize',14,'FontName','Arial','Callback',@mainMenu);

% Function for returning to main menu
    function mainMenu(src,event)

        try set(h_map_cover,'Visible','off','Color',themeColor2,...
                'xcolor',themeColor2,'ycolor',themeColor2)
        catch
        end

        try
            delete(calibPlot)
            delete(calibLine)
        catch
        end

        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            try delete(dispVidCT)
                set(lblGracious,'Visible','off')
            catch
            end
        end

        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            try set(userTable1,'Visible','off')
                set(userTable2,'Visible','off')
            catch
            end
        end

        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            try set(userTable3,'Visible','off')
            catch
            end
        end

        set(UserFig,'Color',themeColor2)

        dataMode = 0;
        view_only = 0;
        coreIn.Value = 1;
        regionIn.Value = 1;
        subRegionIn.Value = 1;
        sectionIn.Value = 1;
        flipCore = 0;
        sectionName = '';

        set(mainMenuIn, 'Visible','off')
        set(openChooseIn, 'Visible','on')
        dispName = 'none';
        try
            try coreInfo = importdata(fullfile(selpath,'my_corals','current_scan','dicoms','CoreMetaData.csv'));
                ct = 1;
            catch
                try coreInfo = importdata(fullfile(selpath,'my_corals','current_scan','Xray','CoreMetaData.csv'));
                    ct = 0;
                catch
                end
            end
            % Load metadata
            hasDataPart = 0;
            try checkInfo = coreInfo.data;
                hasDataPart = 1;
            catch
            end
            if hasDataPart == 1
                coralName = coreInfo.textdata{1};
                sectionName = num2str(coreInfo.data);
            else
                coralName = coreInfo{1};
                if length(coreInfo)>1
                    sectionName = coreInfo{2};
                else
                    sectionName = ''; % default
                end
            end
            if strcmp(sectionName,'')
                dispName = strcat(coralName);
            else
                dispName = strcat(coralName,'/',sectionName);
            end
        catch
        end
        if ~strcmp(dispName,'none')
            set(openLastIn, 'Visible','on')
            set(openLastIn, 'String',{'Open last scan';strcat('(',dispName,')')})
        end
        set(getDataIn, 'Visible','on')
        set(saveDataIn, 'Visible','on')
        set(htextUser, 'Visible','off')
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            set(saveLogin, 'Visible','off')
            set(userProfileIn,'Visible','on')
            set(coreDirIn,'Visible','on')
        end
        set(UserSetIn, 'Visible','off')
        set(htextSave, 'Visible','on')
        set(dataModeLabel, 'Visible','off')
        set(view3DBandsIn,'Visible','off')
        set(downloadDataIn,'Visible','off')
        set(previewIn,'Visible','off')
        set(fileSizePreview,'Visible','off')
        set(checkSpeedIn,'Visible','off')
        set(coreIn,'Visible','off')
        try set(subRegionIn,'Visible','off')
        catch
        end
        try set(sectionIn,'Visible','off')
        catch
        end
        set(htextCore,'Visible','off')
        set(htextSection,'Visible','off')
        set(htextsubRegion,'Visible','off')
        set(bandsMapsIn,'Visible','off')
        set(htextBands,'Visible','off')
        set(previewIn,'Visible','off')
        set(startIn,'Visible','off')
        set(htextLocked,'Visible','off')
        set(htextNoBands,'Visible','off')
        set(htextBandsLocked,'Visible','off')
        set(regionIn,'Visible','on')
        set(htextRegion,'Visible','on')
        set(SubmitDataIn,'Visible','on')
        set(calibCurveIn,'Visible','on') % ADD BACK IN FOR CALIB BUTTON
        set(htextLink4,'Visible','on')
        set(lblThanksCT,'Visible','off')
        set(lblThanksMeta,'Visible','off')
        set(lblOverwrite,'Visible','off')
        set(lblUploadError,'Visible','off')
        set(lblUploadError2,'Visible','off')
        set(sendDataIn,'Visible','off')
        set(editDataIn,'Visible','off')
        set(sendDataFileIn,'Visible','off')
        set(sendXrayIn,'Visible','off')
        set(getMetaDataIn,'Visible','off')
        set(sendMetaDataIn,'Visible','off')
        set(sendVideoIn,'Visible','off')
        set(uiAbout3,'Visible','off')
        set(uiAboutCancel3,'Visible','off')
        set(directSubmit0In,'Visible','off')

        set(lblStderror,'Visible','off')
        set(calibCurveCreateIn,'Visible','off')
        set(calibCurveSendIn,'Visible','off')
        set(calibCurveSendDoneIn,'Visible','off')
        set(calibCurveSendChooseCoreIn,'Visible','off')
        set(haDens,'Visible','off')
        set(htextCalibStatus,'Visible','off')
        set(standardFoldersIn,'Visible','off')
        set(htextStandardFolders,'Visible','off')
        set(densTable,'Visible','off')
        set(standardGroupIn,'Visible','off')
        set(htextStandardGroup,'Visible','off')
        set(htextKnownDens,'Visible','off')
        set(stdDenSetIn,'Visible','off')
        set(calibCurveIn,'Visible','on')

    end

% Quit button
QuitIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Quit CoralCT'},'Visible','on',...
    'Position',[10,775,110,22],'Units','normalized','BackgroundColor',[255,96,92]./256,'FontSize',12,'FontName','Arial','Callback',@quit_callback);

% Function for quiting program
    function quit_callback(src,event)
        set(QuitConfirmIn,'Visible','on')
        set(QuitCancelIn,'Visible','on')
        set(QuitIn,'Visible','off')
    end

% Function for deciding not to quit program
    function quitCancel_callback(src,event)
        set(QuitConfirmIn,'Visible','off')
        set(QuitCancelIn,'Visible','off')
        set(QuitIn,'Visible','on')
    end

% Function for quiting program
    function quit2_callback(src,event)
        try close(cache1)
        catch
        end
        try close(cache2)
        catch
        end
        close all
        try close(UserFig)
        catch
        end
        moveOn = 1;
    end

% QuitConfirm button
QuitConfirmIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Yes, close now'},'Visible','off',...
    'Position',[10,774,150,24],'Units','normalized','BackgroundColor',[255,96,92]./256,'FontSize',12,'FontName','Arial','Callback',@quit2_callback);

QuitCancelIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'No, keep working'},'Visible','off',...
    'Position',[165,774,160,24],'Units','normalized','BackgroundColor',[0,202,78]./256,'FontSize',12,'FontName','Arial','Callback',@quitCancel_callback);

% button to see user profile
userProfileIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'My profile'},'Visible','off',...
    'Position',[500,660,160,60],'Units','normalized','BackgroundColor',[0, 151, 195]./255,'FontSize',14,'FontName','Arial','Callback',@userProfile);

% initialize tables to display
userTable1 = [];
userTable2 = [];
userTable3 = [];

    function userProfile(src,event)

        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            set(saveLogin, 'Visible','off')
            set(userProfileIn,'Visible','off')
            set(coreDirIn,'Visible','off')
        end

        set(h_preview,'Visible','off')
        delete(h_preview)
        h_preview = uiaxes(UserFig,'Units','Pixels','Position',[30 40 540 640],'Color',themeColor2,'Visible','off','Units','normalized');
        h_preview.InteractionOptions.DatatipsSupported = 'off';
        h_preview.InteractionOptions.ZoomSupported = "off";
        h_preview.InteractionOptions.PanSupported = "off";
        h_preview.Toolbar.Visible = 'off';

        pause(0.01)

        set(mainMenuIn,'Visible','on')

        set(lblOverwrite,'Visible','off')
        set(lblUploadError,'Visible','off')
        set(lblUploadError2,'Visible','off')
        set(startIn,'Visible','off')
        set(htextLocked,'Visible','off')
        set(regionIn,'Visible','off')
        set(subRegionIn,'Visible','off')
        set(coreIn,'Visible','off')
        set(UserSetIn,'Visible','off')
        set(startIn,'Visible','off')
        set(previewIn,'Visible','off')
        set(htextUser,'Visible','off')
        set(htextSave,'Visible','off')
        set(saveDataIn,'Visible','off')
        try
            set(sectionIn,'Visible','off')
        catch
        end
        set(openLastIn,'Visible','off')
        set(htextsubRegion,'Visible','off')
        set(htextCore,'Visible','off')
        set(htextSection,'Visible','off')
        set(htextRegion,'Visible','off')
        set(coreIn,'Visible','off')
        set(openChooseIn, 'Visible','off')
        set(fileSizePreview,'Visible','off')
        set(checkSpeedIn,'Visible','off')
        set(dataModeLabel,'Visible','off');
        set(getDataIn,'Visible','off')
        set(downloadTimePreview,'Visible','off')
        set(SubmitDataIn,'Visible','off')
        set(calibCurveIn,'Visible','off')

        set(h_map_cover,'Visible','on');

        pause(0.01)

        try mget(cache1,'log.csv',strcat(refPath));
        catch
            try
                cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
            catch
                try
                    connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                    connectionEstablished = 0;
                    for ij = 1:length(connectTimes)
                        if connectionEstablished == 0
                            if connectTimes(ij) == 1
                                waitText = [' ',num2str(connectTimes(ij)),' minute.']
                            else
                                waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                            end
                            set(lblOverwrite,'Units','Pixels','Visible','on',...
                                'String',{'Error connecting to server.';strcat('Trying again in',waitText)})
                            pause(connectTimes(ij)*60)
                            try
                                cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                connectionEstablished = 1;
                                set(lblOverwrite,'Visible','off')
                            catch
                            end
                        end
                    end
                    if connectionEstablished == 0
                        zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                    end
                catch
                    set(lblOverwrite,'Visible','on',...
                        'String',{'Error connecting to server. (code 025)';'Please try again later.'})
                    while 1==1
                        pause
                    end
                end
            end
            cd(cache1,'/CoralCache');
            mget(cache1,'log.csv',strcat(refPath));
            close(cache1);
        end
        fid4 = fopen(fullfile(refPath,'log.csv'));
        coresLog = textscan(fid4,'%s %s %s %s %s %s %s %s','Delimiter',',');
        log_users = coresLog{1};
        log_cores = coresLog{2};
        log_bands = coresLog{4};
        log_conf = coresLog{5};

        delete(fullfile(refPath,'log.csv'))

        try mget(cache1,'user_agreement_scores.csv',strcat(refPath));
        catch
            cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password); % make sure we can connect to sftp server 1
            cd(cache1,'/CoralCache');
            mget(cache1,'user_agreement_scores.csv',strcat(refPath));
            close(cache1);
        end
        fid9 = fopen(fullfile(refPath,'user_agreement_scores.csv'));
        userScores = textscan(fid9,'%s %s','Delimiter',',');
        scores_users = userScores{1};
        scores_scores = userScores{2};

        delete(fullfile(refPath,'user_agreement_scores.csv'))

        log_bands_double = NaN(length(log_bands)-1,1);
        for ib = 1:length(log_bands_double)
            log_bands_double(ib) = str2num(log_bands{ib+1});
        end

        log_conf_double = NaN(length(log_conf)-1);
        for ib = 1:length(log_conf_double)
            log_conf_double(ib) = str2num(log_conf{ib+1});
        end

        log_conf_double(log_conf_double==0.001) = NaN;

        user_rows = find(strcmp(log_users,saveFileName));
        unq_cores = unique(log_cores(user_rows));
        num_cores = length(unq_cores);
        num_bands = 0;
        unq_core_bands = NaN(num_cores,1);
        core_conf = NaN(num_cores,1);

        scores_row = find(strcmp(scores_users,saveFileName));
        my_score = scores_scores(scores_row);

        for ia = 1:num_cores
            this_core_rows = find(strcmp(log_cores(user_rows),unq_cores(ia)));
            [unq_core_bands(ia), loc] = max(log_bands_double(user_rows(this_core_rows)-1));
            num_bands = num_bands+unq_core_bands(ia);
            core_conf(ia) = log_conf_double(user_rows(this_core_rows(loc))-1);
        end

        userTable1_prep = table([{saveFileName}; {num2str(num_cores)}; {num2str(num_bands)}; my_score]);
        userTable1_prep.Properties.RowNames = {'Username'; 'Cores processed'; 'Bands processed'; 'Inter-user agreement score'};
        userTable1_prep.Properties.VariableNames = {' '};

        userTable1 = uitable(UserFig,'Data',userTable1_prep,'Position',[100 505 300 160],...
            'Visible','on','Units','normalized');
        userStyle1 = uistyle('HorizontalAlignment','center');
        addStyle(userTable1,userStyle1,'table','')
        userStyle2 = uistyle('FontWeight','bold');
        addStyle(userTable1,userStyle2,'table','')

        userTable2_prep = table(sprintfc('%9.0f',round(unq_core_bands)), sprintfc('%9.1f',round(core_conf*10)/10));
        userTable2_prep.Properties.RowNames = unq_cores;
        userTable2_prep.Properties.VariableNames = {'Bands','Confidence score'};

        userTable2 = uitable(UserFig,'Data',userTable2_prep,'Position',[500 205 300 460],...
            'Visible','on','Units','normalized');
        userStyle1 = uistyle('HorizontalAlignment','center');
        addStyle(userTable2,userStyle1,'table','')
        userStyle2 = uistyle('FontWeight','bold');
        addStyle(userTable2,userStyle2,'table','')

    end

%puts text on telling you to select your region
htextStandardGroup = uicontrol(UserFig,'Style','text','String','Select standard group:','Visible','off',...
    'Position',[680,610,160,25],'Units','normalized','BackgroundColor','none','ForegroundColor',themeColor3,'FontSize',11,'FontName','Arial');

standardGroupIn = uicontrol(UserFig,'Style','popupmenu',...
    'Position',[680,575,250,35],'Units','normalized',...
    'String','','Visible','off',...
    'Callback',@chosenStdGroup);

stdGroups = [];
htextStandardFolders = [];
standardFoldersIn = [];
htextKnownDens = [];
stdDenSetIn = [];
densTable0 = [];
densTable = [];
densValues = [];
densNames = [];
firstStd = 1;
stdGroupsNum = [];

    function chosenStdGroup(src,event)

        stdGroupsNum = standardGroupIn.Value;
        firstStd = 1;
        densValues = [];
        densNames = [];
        densTable0 = table([],[]);
        densTable0.Properties.VariableNames = {'standard','density'};

        densTable = uitable(UserFig,'Data',densTable0,'Position',[150 550 200 25*(size(densTable0,1)+1)],...
            'Visible','on','Units','normalized');

        try close(cache2)
        catch
        end
        try cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password); %
            cd(cache2,strcat('/hd1/standards/',stdGroups{stdGroupsNum},'/'))
            dirStdFolders = dir(cache2);
            stdFolders = {'';''};
            for jjj = 1:length(dirStdFolders)
                stdFolders{jjj} = dirStdFolders(jjj).name;
            end
        catch
            connectTimes = [1,2,3,5,10,60,60*12]; % minutes
            connectionEstablished = 0;
            for ij = 1:length(connectTimes)
                if connectionEstablished == 0
                    if connectTimes(ij) == 1
                        waitText = [' ',num2str(connectTimes(ij)),' minute.']
                    else
                        waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                    end
                    set(htextCalibStatus,'Visible','on',...
                        'String',{'Error connecting to server.';strcat('Trying again in',waitText)},...
                        'Units','normalized')
                    pause(connectTimes(ij)*60)
                    try
                        cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password); %
                        cd(cache2,strcat('/hd1/standards/',stdGroups{stdGroupsNum},'/'))
                        dirStdFolders = dir(cache2);
                        stdFolders = {'';''};
                        for jjj = 1:length(dirStdFolders)
                            stdFolders{jjj} = dirStdFolders(jjj).name;
                        end
                        connectionEstablished = 1;
                        set(htextCalibStatus,'Visible','off')
                    catch
                    end
                end
            end
            if connectionEstablished == 0
                zz = abjfl; % if we made it through end of loop, cause an error to display error code below
            end
            set(htextCalibStatus,'Visible','on',...
                'String',{'Error connecting to server. (code 044)';'Please try again later.'},...
                'Units','normalized')
            while 1==1
                pause
            end
        end

        htextStandardFolders = uicontrol(UserFig,'Style','text','String','Select standard:','Visible','on',...
            'Position',[660,525,150,25],'Units','normalized','BackgroundColor','none','ForegroundColor',themeColor3,'FontSize',11,'FontName','Arial');

        standardFoldersIn = uicontrol(UserFig,'Style','popupmenu',...
            'Position',[680,490,250,35],'Units','normalized',...
            'String',stdFolders,'Visible','on','Callback',@chosenStdFolder);

        function chosenStdFolder(src,event)

            try delete(htextKnownDens)
            catch
            end
            htextKnownDens = uicontrol(UserFig,'Style','text','String',sprintf('Known density (g / cubic cm):'),'Visible','on',...
            'Position',[670,430,200,25],'Units','normalized','BackgroundColor','none','ForegroundColor',themeColor3,'FontSize',11,'FontName','Arial');

            try delete(stdDenSetIn)
            catch
            end
            stdDenSetIn = uicontrol(UserFig,'Style','Edit','Visible','on',...
                'Position',[680,405,100,25],'Units','normalized','Callback', @addDensToList);

        end

    end

    function addDensToList(src,event)

        if firstStd == 1
            densNames = standardFoldersIn.String{standardFoldersIn.Value};
        else
            densNames = [densNames;string(standardFoldersIn.String{standardFoldersIn.Value})];
        end
        densValues = [densValues;str2num(stdDenSetIn.String)];
        if firstStd == 1
            densTable0 = table({densNames},{densValues});
        else
            densTable0 = table(densNames,densValues);
        end
        densTable0.Properties.VariableNames = {'standard','density'};
        delete(densTable)
        densTable = uitable(UserFig,'Data',densTable0,'Position',[150 550 200 24*(size(densTable0,1)+1)],...
                'Visible','on','Units','normalized');

        firstStd = 0;

        if size(densTable0,1) > 1
            set(calibCurveCreateIn,'Visible','on')
        end

    end
haDens = [];

thisFit = [];
doingDensCalib = 0;

htextCalibStatus = uicontrol(UserFig,'Style','text','String','','Visible','off',...
            'Position',[650,330,250,40],'Units','normalized','BackgroundColor','none','ForegroundColor',themeColor3,'FontSize',11,'FontName','Arial');

calibPlot = [];
calibLine = [];
    function densCurveMake(src,event)

        set(calibCurveCreateIn,'Enable','off')
        pause(0.01)

        doingDensCalib = 1;

        HUs = NaN(size(densValues));

        for iDens = 1:length(densValues)

            try close(cache2)
            catch
            end
            try
                cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password); %
                cd(cache2,strcat('/hd1/standards/',stdGroups{stdGroupsNum},'/',densNames(iDens)));
                mget(cache2,'dicoms.zip',fullfile(selpath,'my_corals','standards'));
            catch
                connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                connectionEstablished = 0;
                for ij = 1:length(connectTimes)
                    if connectionEstablished == 0
                        if connectTimes(ij) == 1
                            waitText = [' ',num2str(connectTimes(ij)),' minute.']
                        else
                            waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                        end
                        set(htextCalibStatus,'Visible','on',...
                            'String',{'Error connecting to server.';strcat('Trying again in',waitText)},...
                            'Units','normalized')
                        pause(connectTimes(ij)*60)
                        try
                            cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password); %
                            cd(cache2,strcat('/hd1/standards/',stdGroups{stdGroupsNum},'/',densNames(iDens)));
                            mget(cache2,'dicoms.zip',fullfile(selpath,'my_corals','standards'));
                            connectionEstablished = 1;
                            set(htextCalibStatus,'Visible','off')
                        catch
                        end
                    end
                end
                if connectionEstablished == 0
                    zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                end
                set(htextCalibStatus,'Visible','on',...
                    'String',{'Error connecting to server. (code 042)';'Please try again later.'},...
                    'Units','normalized')
                while 1==1
                    pause
                end
            end

            set(htextCalibStatus,'Visible','on','String',sprintf('Working on standard %s',densNames(iDens)))

            fileOpen = fullfile(selpath,'my_corals','standards');
            if exist(fullfile(selpath,'my_corals','standards','dicoms'),'dir')
                rmdir(fullfile(selpath,'my_corals','standards','dicoms'),'s')
            end
            unzip(fullfile(selpath,'my_corals','standards','dicoms.zip'),fullfile(selpath,'my_corals','standards','dicoms'))

            ha3 = uiaxes(UserFig,'Units','Pixels','Position',[715,40,250,60],'Units','normalized','Visible','on');
            ha3.InteractionOptions.DatatipsSupported = 'off';
            ha3.InteractionOptions.ZoomSupported = "off";
            ha3.InteractionOptions.PanSupported = "off";
            ha3.Toolbar.Visible = 'off';
            hold(ha3,'on')
            set(ha3,'Xtick',[],'YTick',[],'XLim',[0 1],'YLim',[0 1])
            set(ha3,'Visible','on')
            loadData
            gen = 'Porites';
            chooseCoreFilter
            buildCore
            HU2dens = [1,0];
            volumeDensity
            HUs(iDens) = densityWholeCore;
            doingDensCalib = 0;
            set(ha3,'Visible','off')
            delete(ha3)

        end

        set(htextCalibStatus,'Visible','off')

        haDens = uiaxes(UserFig,'Units','Pixels','Position',[80,80,400,300],'Units','normalized','Color','white','xcolor','k','ycolor','k');
        calibPlot = plot(haDens,densValues,HUs,'ko','LineWidth',2,'MarkerSize',10);
        hold(haDens,'on')
        thisFit = polyfit(densValues,HUs,1);
        calibLine = plot(haDens,[min(densValues),max(densValues)],[min(densValues),max(densValues)]*thisFit(1)+thisFit(2),'r-','LineWidth',2);
        ylabel(haDens,'Hounsfield Units (HU)')
        xlabel(haDens,'Known density (g cm^{-3})')
        set(haDens,'FontSize',14)

        set(calibCurveSendIn,'Visible','on')
        set(calibCurveSendChooseCoreIn,'Visible','on')
        set(calibCurveSendDoneIn,'Visible','on')

    end

core4calibEqn = [];
    function densCurveSendChooseCore(src,event)

        core4calibEqn = calibCurveSendChooseCoreIn.String;
        if length(find(strcmp(core4calibEqn,coralDir.textdata(:,1))))
            set(htextCalibStatus,'Visible','off')
        else
            set(htextCalibStatus,'Visible','on','String',sprintf('Invalid core name'))
        end

    end

    function densCurveSendDone(src,event)

        set(htextCalibStatus,'Visible','off')
        delete(calibPlot)
        delete(calibLine)
        set(calibCurveCreateIn,'Enable','on')
        mainMenu

    end

    function densCurveSend(src,event)

        set(calibCurveSendIn,'Enable','off')
        set(calibCurveSendDoneIn,'Enable','off')

        pause(0.01)
        dirRow = find(strcmp(core4calibEqn,coralDir.textdata(:,1)));

        if length(dirRow)

            set(htextCalibStatus,'Visible','on','String',sprintf('Applying eqn. to core %s',core4calibEqn{1}))
            pause(0.01)

            coralDir.data(dirRow-1,10) = thisFit(1);
            coralDir.data(dirRow-1,11) = thisFit(2);
            coralDirHold = coralDir;
            coralDirHold.textdata = coralDirHold.textdata(2:end,:);
            coralDirStruct = struct('name',coralDirHold.textdata(:,1),...
                'piece',coralDirHold.textdata(:,2),...
                'region',coralDirHold.textdata(:,3),...
                'sub_region',coralDirHold.textdata(:,4),...
                'genus',coralDirHold.textdata(:,5),...
                'owner',coralDirHold.textdata(:,6),...
                'notes',coralDirHold.textdata(:,7),...
                'hard_drive',coralDirHold.data(1,1),...
                'flip',coralDirHold.data(1,2),...
                'lat',coralDirHold.data(1,3),...
                'lon',coralDirHold.data(1,4),...
                'depth',coralDirHold.data(1,5),...
                'month',coralDirHold.data(1,6),...
                'year',coralDirHold.data(1,7),...
                'file_size',coralDirHold.data(1,8),...
                'unlocked',coralDirHold.data(1,9),...
                'denslope',coralDirHold.data(1,10),...
                'denintercept',coralDirHold.data(1,11),...
                'ct',coralDirHold.data(1,12),...
                'xraypos',coralDirHold.data(1,13),...
                'dpi',coralDirHold.data(1,14));
            for ic = 1:length(coralDirHold.data)
                coralDirStruct(ic).hard_drive = coralDirHold.data(ic,1);
                coralDirStruct(ic).flip = coralDirHold.data(ic,2);
                coralDirStruct(ic).lat = coralDirHold.data(ic,3);
                coralDirStruct(ic).lon = coralDirHold.data(ic,4);
                coralDirStruct(ic).depth = coralDirHold.data(ic,5);
                coralDirStruct(ic).month = coralDirHold.data(ic,6);
                coralDirStruct(ic).year = coralDirHold.data(ic,7);
                coralDirStruct(ic).file_size = coralDirHold.data(ic,8);
                coralDirStruct(ic).unlocked = coralDirHold.data(ic,9);
                coralDirStruct(ic).denslope = coralDirHold.data(ic,10);
                coralDirStruct(ic).denintercept = coralDirHold.data(ic,11);
                coralDirStruct(ic).ct = coralDirHold.data(ic,12);
                coralDirStruct(ic).xraypos = coralDirHold.data(ic,13);
                coralDirStruct(ic).dpi = coralDirHold.data(ic,14);
            end
            writetable(struct2table(coralDirStruct),fullfile(selpath,'my_corals','coral_directory_master.txt'),'Delimiter','\t')

            try mput(cache1,fullfile(selpath,'my_corals','coral_directory_master.txt'));
            catch
                try
                    cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                    cd(cache1,'CoralCache')
                    mput(cache1,fullfile(selpath,'my_corals','coral_directory_master.txt'));
                catch
                    connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                    connectionEstablished = 0;
                    for ij = 1:length(connectTimes)
                        if connectionEstablished == 0
                            if connectTimes(ij) == 1
                                waitText = [' ',num2str(connectTimes(ij)),' minute.']
                            else
                                waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                            end
                            set(htextCalibStatus,'Visible','on',...
                                'String',{'Error connecting to server.';strcat('Trying again in',waitText)},...
                                'Units','normalized')
                            pause(connectTimes(ij)*60)
                            try
                                cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                cd(cache1,'CoralCache')
                                mput(cache1,fullfile(selpath,'my_corals','coral_directory_master.txt'));
                                connectionEstablished = 1;
                                set(htextCalibStatus,'Visible','off')
                            catch
                            end
                        end
                    end
                    if connectionEstablished == 0
                        zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                    end
                    set(htextCalibStatus,'Visible','on',...
                        'String',{'Error connecting to server. (code 042)';'Please try again later.'},...
                        'Units','normalized')
                    while 1==1
                        pause
                    end
                end
            end

            set(htextCalibStatus,'Visible','on','String',sprintf('Done. Applied eqn. to core %s',core4calibEqn{1}))

            set(calibCurveSendChooseCoreIn,'String','Enter core name here');

        else
            set(htextCalibStatus,'Visible','on','String',sprintf('Invalid core name'))
        end

        set(calibCurveSendIn,'Enable','on')
        set(calibCurveSendDoneIn,'Enable','on')

    end

calibCurveSendIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Add calibration';'equation to directory'},'Visible','off',...
    'Position',[880,150,200,60],'Units','normalized','BackgroundColor',[175, 245, 220]./255,'FontSize',12,'FontName','Arial','Callback',@densCurveSend);

calibCurveSendDoneIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Done'},'Visible','off',...
    'Position',[880,80,200,30],'Units','normalized','BackgroundColor',[175, 245, 220]./255,'FontSize',12,'FontName','Arial','Callback',@densCurveSendDone);

calibCurveSendChooseCoreIn = uicontrol(UserFig,'Style','Edit',...
    'String',{'Enter core name here'},'Visible','off',...
    'Position',[660,160,180,40],'Units','normalized','BackgroundColor','white','FontSize',10,'FontName','Arial','Callback',@densCurveSendChooseCore);

calibCurveCreateIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Process density';'calibration curve'},'Visible','off',...
    'Position',[660,250,140,60],'Units','normalized','BackgroundColor',[175, 245, 220]./255,'FontSize',12,'FontName','Arial','Callback',@densCurveMake);

calibCurveIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Make CT density';'calibration curve'},'Visible','off',...
    'Position',[340,730,140,60],'Units','normalized','BackgroundColor',[175, 245, 220]./255,'FontSize',12,'FontName','Arial','Callback',@densCurve);

lblStderror = uicontrol(UserFig,'Style','text','String','Error finding standards','Visible','off',...
    'Position',[680,610,160,25],'Units','normalized','BackgroundColor','none','ForegroundColor',themeColor3,'FontSize',11,'FontName','Arial');

    function densCurve(src,event)

        set(mainMenuIn,'Visible','on')
        % Turn visibility off for all the core-selection drop-down menus
        set(startIn,'Visible','off')
        set(htextLocked,'Visible','off')
        set(regionIn,'Visible','off')
        set(subRegionIn,'Visible','off')
        set(coreIn,'Visible','off')
        set(UserSetIn,'Visible','off')
        set(startIn,'Visible','off')
        set(previewIn,'Visible','off')
        set(htextUser,'Visible','off')
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            set(saveLogin, 'Visible','off')
            set(userProfileIn,'Visible','off')
            set(coreDirIn,'Visible','off')
        end
        set(htextSave,'Visible','off')
        set(saveDataIn,'Visible','off')
        try
            set(sectionIn,'Visible','off')
        catch
        end
        set(openLastIn,'Visible','off')
        set(htextsubRegion,'Visible','off')
        set(htextCore,'Visible','off')
        set(htextSection,'Visible','off')
        set(htextRegion,'Visible','off')
        set(coreIn,'Visible','off')
        set(openChooseIn, 'Visible','off')
        set(fileSizePreview,'Visible','off')
        set(checkSpeedIn,'Visible','off')
        set(dataModeLabel,'Visible','off');
        set(getDataIn,'Visible','off')
        set(downloadTimePreview,'Visible','off')
        set(SubmitDataIn,'Visible','off')
        set(calibCurveIn,'Visible','off')
        %uistack(uiAbout3,'top')
        set(htextLink4,'Visible','on')

        set(h_map_cover,'Visible','on','Color',themeColor2,'xcolor',themeColor2,'ycolor',themeColor2);
        patch(h_map_cover,[0,1],[0,1],[1 1 1],'EdgeColor','none')

        try close(cache2)
        catch
        end
        try cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password); %
            cd(cache2,'/hd1/standards/')
            dirStd = dir(cache2);
            stdGroups = {'';''};
            for jj = 1:length(dirStd)
                stdGroups{jj} = dirStd(jj).name;
            end
            set(standardGroupIn,'String',stdGroups)
            set(standardGroupIn,'Visible','on')
            set(htextStandardGroup,'Visible','on')
        catch
            set(lblStderror,'Visible','on')
        end

    end

sortColumn  = 12;
ascendDescend = 'descend';
observer_num = [];

coreDirIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Core directory'},'Visible','off',...
    'Position',[500,730,160,60],'Units','normalized','BackgroundColor',[155, 227, 249]./255,'FontSize',14,'FontName','Arial','Callback',@coreDirectory);

% function to display core directory
    function coreDirectory(src,event)

        lblLoadingDir = uicontrol(UserFig,'Style','text','String','Loading..','BackgroundColor','none',...
            'Position',[350,655,300,35],'FontSize',14,'FontName','Arial','Units','normalized',...
            'ForegroundColor','k');

        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            set(saveLogin, 'Visible','off')
            set(userProfileIn,'Visible','off')
            set(coreDirIn,'Visible','off')
        end
        pause(0.01)

        set(mainMenuIn,'Visible','on')

        set(h_preview,'Visible','off')
        delete(h_preview)
        h_preview = uiaxes(UserFig,'Units','Pixels','Position',[30 40 540 640],'Color',themeColor2,'Visible','off','Units','normalized');
        h_preview.InteractionOptions.DatatipsSupported = 'off';
        h_preview.InteractionOptions.ZoomSupported = "off";
        h_preview.InteractionOptions.PanSupported = "off";
        h_preview.Toolbar.Visible = 'off';
        set(lblOverwrite,'Visible','off')
        set(lblUploadError,'Visible','off')
        set(lblUploadError2,'Visible','off')
        set(startIn,'Visible','off')
        set(htextLocked,'Visible','off')
        set(regionIn,'Visible','off')
        set(subRegionIn,'Visible','off')
        set(coreIn,'Visible','off')
        set(UserSetIn,'Visible','off')
        set(startIn,'Visible','off')
        set(previewIn,'Visible','off')
        set(htextUser,'Visible','off')
        set(htextSave,'Visible','off')
        set(saveDataIn,'Visible','off')
        try
            set(sectionIn,'Visible','off')
        catch
        end
        set(openLastIn,'Visible','off')
        set(htextsubRegion,'Visible','off')
        set(htextCore,'Visible','off')
        set(htextSection,'Visible','off')
        set(htextRegion,'Visible','off')
        set(coreIn,'Visible','off')
        set(openChooseIn, 'Visible','off')
        set(fileSizePreview,'Visible','off')
        set(checkSpeedIn,'Visible','off')
        set(dataModeLabel,'Visible','off');
        set(getDataIn,'Visible','off')
        set(downloadTimePreview,'Visible','off')
        set(SubmitDataIn,'Visible','off')
        set(calibCurveIn,'Visible','off')

        set(h_map_cover,'Visible','on');

        pause(0.01)

        try

        try mget(cache1,'coral_directory_citations.txt',fullfile(selpath,'my_corals'));
            citationDir = importdata(fullfile(selpath,'my_corals','coral_directory_citations.txt'));
        catch
            try
                cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
            catch
                try
                    connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                    connectionEstablished = 0;
                    for ij = 1:length(connectTimes)
                        if connectionEstablished == 0
                            if connectTimes(ij) == 1
                                waitText = [' ',num2str(connectTimes(ij)),' minute.']
                            else
                                waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                            end
                            set(lblLoadingDir,'Units','Pixels','Visible','on',...
                                'String',{'Error connecting to server.';strcat('Trying again in',waitText)})
                            pause(connectTimes(ij)*60)
                            try
                                cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                connectionEstablished = 1;
                                set(lblLoadingDir,'Visible','off')
                            catch
                            end
                        end
                    end
                    if connectionEstablished == 0
                        zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                    end
                catch
                    set(lblLoadingDir,'Visible','on',...
                        'String',{'Error connecting to server. (code 026)';'Please try again later.'})
                    while 1==1
                        pause
                    end
                end
            end
            
            cd(cache1,'/CoralCache');
            mget(cache1,'coral_directory_citations.txt',fullfile(selpath,'my_corals'));
            close(cache1);
            citationDir = importdata(fullfile(selpath,'my_corals','coral_directory_citations.txt'));
        end

        citationTableText = cell2table(citationDir.textdata);
        citationTableText.Properties.VariableNames = table2cell(citationTableText(1,:));
        citationTableText(1,:) = [];
        piece0 = strcat(' / ',table2cell(citationTableText(:,2)));
        piece0(strcmp(piece0,' /')) = {''};
        citationTableText.Properties.RowNames = strcat(table2cell(citationTableText(:,1)),piece0);
        
        coreTableText = cell2table(coralDir.textdata);
        coreTableNumeric = array2table(coralDir.data);

        coreTableText.Properties.VariableNames = table2cell(coreTableText(1,:));
        coreTableNumeric.Properties.VariableNames = table2cell(coreTableText(1,[8:21]));
        coreTableText(1,:) = [];

        userTable3_prep = [coreTableText(:,3:5), coreTableNumeric(:,[3:9,12])];
        userTable3_prep.Properties.VariableNames{2} = 'sub region';
        userTable3_prep.Properties.VariableNames{6} = 'depth (m)';
        userTable3_prep.Properties.VariableNames{9} = 'file size (MB)';
        userTable3_prep.Properties.VariableNames{10} = 'access level';
        piece0 = strcat(' / ',table2cell(coreTableText(:,2)));
        piece0(strcmp(piece0,' /')) = {''};
        userTable3_prep.Properties.RowNames = strcat(table2cell(coreTableText(:,1)),piece0);
      
        try mget(cache1,'log.csv',strcat(refPath));
        catch
            cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password); % make sure we can connect to sftp server 1
            cd(cache1,'/CoralCache');
            mget(cache1,'log.csv',strcat(refPath));
            close(cache1);
        end
        fid4 = fopen(fullfile(refPath,'log.csv'));
        coresLog = textscan(fid4,'%s %s %s %s %s %s %s %s','Delimiter',',');
        log_users = coresLog{1};
        log_cores = coresLog{2};
        log_bands = coresLog{4};
        log_conf = coresLog{5};
        log_conf_double = NaN(length(log_conf)-1);
        for ib = 1:length(log_conf_double)
            log_conf_double(ib) = str2num(log_conf{ib+1});
        end

        piece0 = strcat('_',table2cell(coreTableText(:,2)));
        piece0(strcmp(piece0,'_')) = {''};
        corenames = strcat(table2cell(coreTableText(:,1)),piece0);
        observer_num = zeros(length(corenames),1);
        mean_conf = NaN(length(corenames),1);
        for ie = 1:length(corenames)
            these_idx = find(strcmp(corenames(ie),log_cores));
            these_core_users = strcat(log_cores(these_idx),log_users(these_idx));
            observer_num(ie) = length(unique(these_core_users));
            these_conf = log_conf_double(these_idx);
            these_conf(these_conf==0.001) = [];
            mean_conf(ie) = nanmean(these_conf);
        end

        userTable3_prep.observers = observer_num;
        userTable3_prep.confidence = mean_conf;

        delete(fullfile(refPath,'log.csv'))

        dontPrint = 0;
        if min(strcmp(citationTableText.Properties.RowNames,userTable3_prep.Properties.RowNames)) == 0
            % something is wrong
            dontPrint = 1;
        else
            userTable3_prep.citation = citationTableText.citation;
            userTable3_prep.acknowledgement = citationTableText.acknowledgement;
        end

        % round depths
        userTable3_prep(:,6) = round(userTable3_prep(:,6).*10)./10;

        userTable3_final = [userTable3_prep(:,12:15), userTable3_prep(:,1:11)];

        [vals, idx_tab4] = sortrows([userTable3_final(:,12),userTable3_final(:,11)],{'year','month'},{'descend','descend'});
        userTable3_final = userTable3_final(idx_tab4,:);
        observer_num = observer_num(idx_tab4);

        if dontPrint == 0
            userTable3 = uitable(UserFig,'Data',userTable3_final,'Position',[50 50 1000 650],...
                'Visible','on','Units','normalized');

            set(userTable3,'CellSelectionCallback',@tableSelCallback);

            cmap_obs =       flipud([0.8575    0.9443    0.7258
                0.7165    0.8965    0.6706
                0.5711    0.8479    0.6422
                0.4443    0.7922    0.6399
                0.3642    0.7277    0.6430
                0.3214    0.6597    0.6383
                0.2947    0.5918    0.6264
                0.2722    0.5253    0.6113
                0.2528    0.4593    0.5967
                0.2421    0.3916    0.5830]);

            for ie = 1:length(observer_num)
                this_col = observer_num(ie)+1;
                if this_col > 10
                    this_col = 10;
                end
                l_col = uistyle("BackgroundColor",cmap_obs(this_col,:));
                addStyle(userTable3,l_col,"cell",[ie,1])
            end
        end
        lCol_t = uistyle("FontColor",[0, 102, 204]./256);
        addStyle(userTable3,lCol_t,"column",3)
        catch
        end

        set(lblLoadingDir,'Visible','off')
        
    end

    % function for hyperlinks in core directory table
    function tableSelCallback(hObject,eventData)
        % get all links/cells from the table
        links        = get(hObject,'Data');
        % assuming single column so just need the first index to get the
        % selected link/cell
        if eventData.Indices(1) > 0 && eventData.Indices(2) == 3
            selectedLink = links{eventData.Indices(1),eventData.Indices(2)};
            web(selectedLink,'-browser')
            % % build the url - find where in the string we have http
            % strtHttpIdx = strfind(selectedLink,'http');
            % % if non-empty index for http, then find where the url end
            % if ~isempty(strtHttpIdx)
            %     % we know that the > terminates the url so find all indices to this
            %     % character
            %     bracketIdcs = strfind(selectedLink,'>');
            %     % we just want the one index that corresponds to that which is greater
            %     % than the index for http; note how we subtract one since our url does
            %     % not include '>' only the last character before it
            %     endHttpIdx  = bracketIdcs(find(bracketIdcs>strtHttpIdx,1))-1;
            %     % open the url in the browser
            %     web(selectedLink(strtHttpIdx:endHttpIdx),'-browser');
            % end
        end
        if length(eventData.Indices(:,1)) > 1

            set(userTable3,'Visible','off')

            lblLoadingDir = uicontrol(UserFig,'Style','text','String','Loading..','BackgroundColor','none',...
            'Position',[350,655,300,35],'FontSize',14,'FontName','Arial','Units','normalized',...
            'ForegroundColor','k');
            pause(0.01)

            if sortColumn == eventData.Indices(1,2)
                if strcmp(ascendDescend,'ascend')
                    ascendDescend = 'descend';
                else
                    ascendDescend = 'ascend';
                end
            else
                sortColumn = eventData.Indices(1,2);
            end
            [userTable3.Data,idx_tab] = sortrows(userTable3.Data, sortColumn, ascendDescend);
            observer_num = observer_num(idx_tab);
            removeStyle(userTable3);

            if sortColumn==1
                cmap_obs =       flipud([0.8575    0.9443    0.7258
                    0.7165    0.8965    0.6706
                    0.5711    0.8479    0.6422
                    0.4443    0.7922    0.6399
                    0.3642    0.7277    0.6430
                    0.3214    0.6597    0.6383
                    0.2947    0.5918    0.6264
                    0.2722    0.5253    0.6113
                    0.2528    0.4593    0.5967
                    0.2421    0.3916    0.5830]);

                for ie = 1:length(observer_num)
                    this_col = observer_num(ie)+1;
                    if this_col > 10
                        this_col = 10;
                    end
                    l_col = uistyle("BackgroundColor",cmap_obs(this_col,:));
                    addStyle(userTable3,l_col,"cell",[ie,1])
                end
            end
            lCol_t = uistyle("FontColor",[0, 102, 204]./256);
            addStyle(userTable3,lCol_t,"column",3)
            pause(0.01)
            set(lblLoadingDir,'Visible','off')
            userTable3.Selection = [];
            set(userTable3,'Visible','on')
        end
    end

lblGracious = [];

% Function for submitting data menu
    function submitData(src,event)

        set(UserFig,'Color','w')
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')

            dispVidCT = uihtml(UserFig);
            dispVidCT.Position = [80,36,500,700];
            rng('shuffle')
            rand_vidCT = round(rand(1)*(n_loading_vidsCT-1))+1;
            dispVidCT.HTMLSource = (fullfile('loading_movies',strcat('ct_movie',num2str(rand_vidCT),'.html')));

            lblGracious = uicontrol(UserFig,'Style','text','String',{'CoralCache depends on your data!';'Thank you for sharing your data for this community effort.'},...
                'Position',[100,680,500,45],'Units','normalized','FontSize',12,'FontName','Fanta','Visible','on',...
                'BackgroundColor','w');

        end

        set(mainMenuIn,'Visible','on')
        set(sendDataIn,'Visible','on')
        set(editDataIn,'Visible','on')
        set(sendDataFileIn,'Visible','on')
        set(sendXrayIn,'Visible','on')
        set(getMetaDataIn,'Visible','on')
        set(sendMetaDataIn,'Visible','on')
        set(sendVideoIn,'Visible','on')
        set(lblOverwrite,'Visible','off')
        set(lblUploadError,'Visible','off')
        set(lblUploadError2,'Visible','off')
        %set(directSubmit0In,'Visible','on') %ZZ turn back on for direct submission

        % Turn visibility off for all the core-selection drop-down menus
        set(startIn,'Visible','off')
        set(htextLocked,'Visible','off')
        set(regionIn,'Visible','off')
        set(subRegionIn,'Visible','off')
        set(coreIn,'Visible','off')
        set(UserSetIn,'Visible','off')
        set(startIn,'Visible','off')
        set(previewIn,'Visible','off')
        set(htextUser,'Visible','off')
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            set(saveLogin, 'Visible','off')
            set(userProfileIn,'Visible','off')
            set(coreDirIn,'Visible','off')
        end
        set(htextSave,'Visible','off')
        set(saveDataIn,'Visible','off')
        try
            set(sectionIn,'Visible','off')
        catch
        end
        set(openLastIn,'Visible','off')
        set(htextsubRegion,'Visible','off')
        set(htextCore,'Visible','off')
        set(htextSection,'Visible','off')
        set(htextRegion,'Visible','off')
        set(coreIn,'Visible','off')
        set(openChooseIn, 'Visible','off')
        set(fileSizePreview,'Visible','off')
        set(checkSpeedIn,'Visible','off')
        set(dataModeLabel,'Visible','off');
        set(getDataIn,'Visible','off')
        set(downloadTimePreview,'Visible','off')
        set(SubmitDataIn,'Visible','off')
        set(calibCurveIn,'Visible','off')
        set(uiAbout3,'Visible','on')
        set(uiAboutCancel3,'Visible','off')
        %uistack(uiAbout3,'top')
        set(htextLink4,'Visible','on')

        set(h_map_cover,'Visible','on','Color','w','xcolor','w','ycolor','w');
        patch(h_map_cover,[0,1],[0,1],[1 1 1],'EdgeColor','none')

    end

editDataIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Convert or resize data'},'Visible','off',...
    'Position',[715,120,250,50],'Units','normalized','BackgroundColor',[1.0, 0.78, 0.27],'FontSize',14,'FontName','Arial','Callback',@editData);

editDataCancelIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Go back'},'Visible','off',...
    'Position',[715,120,250,50],'Units','normalized','BackgroundColor',[0.78,0.94,0.54],'FontSize',14,'FontName','Arial','Callback',@editDataCancel);

directSubmit0In = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Direct submission'},'Visible','off',...
    'Position',[715,40,250,50],'Units','normalized','BackgroundColor',[1.0, 0.78, 0.27],'FontSize',14,'FontName','Arial','Callback',@directSubmit0);

directSubmitIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Yes, I read about this';'in the user guide.'},'Visible','off',...
    'Position',[715,340,250,50],'Units','normalized','BackgroundColor',[1.0, 0.78, 0.27],'FontSize',12,'FontName','Arial','Callback',@directSubmit);

htextLinkUserGuide = uihyperlink(UserFig,'URL','https://www.sclerochronologylab.com/uploads/1/3/0/8/130817513/coralct-userguide.pdf','Text','Go to user guide',...
        'FontSize',14,'FontName','Arial','Visible','off','Position',[715,280,250,30]);

directSubmitGoIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Submit!'},'Visible','off','Enable','off',...
    'Position',[715,280,250,50],'Units','normalized','BackgroundColor',[1.0, 0.78, 0.27],'FontSize',12,'FontName','Arial','Callback',@directSubmitGo);

directSubmitMetaIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Select completed metadata';'template file'},'Visible','off',...
    'Position',[715,360,250,50],'Units','normalized','BackgroundColor',[1.0, 0.78, 0.27],'FontSize',12,'FontName','Arial','Callback',@directSubmitMeta);

directSubmitDataIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Select CT scan or X-ray'},'Visible','off',...
    'Position',[715,440,250,50],'Units','normalized','BackgroundColor',[1.0, 0.78, 0.27],'FontSize',12,'FontName','Arial','Callback',@directSubmitData);

makeMapIn0 = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Make a map'},'Visible','off',...
    'Position',[715,200,250,50],'Units','normalized','BackgroundColor',[0.67, 0.67, 0.78],'FontSize',12,'FontName','Arial','Callback',@makeMap0);

makeMapIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Send request'},'Visible','off',...
    'Position',[715,280,250,50],'Units','normalized','BackgroundColor',[0.67, 0.67, 0.78],'FontSize',12,'FontName','Arial','Callback',@makeMap);

mapCancelIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Go back'},'Visible','off',...
    'Position',[715,120,250,50],'Units','normalized','BackgroundColor',[0.78,0.94,0.54],'FontSize',14,'FontName','Arial','Callback',@mapCancel);

sendDataIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Submit data folder'},'Visible','off',...
    'Position',[715,520,250,50],'Units','normalized','BackgroundColor',[0.15, 0.67, 0.82],'FontSize',14,'FontName','Arial','Callback',@sendDataFolder);

sendDataFileIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Submit zipped file'},'Visible','off',...
    'Position',[715,600,250,50],'Units','normalized','BackgroundColor',[0.0, 0.59, 0.76],'FontSize',14,'FontName','Arial','Callback',@sendDataFile);

getMetaDataIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Get metadata template'},'Visible','off',...
    'Position',[715,280,250,50],'Units','normalized','BackgroundColor',[0.96, 0.39, 0.16],'FontSize',14,'FontName','Arial','Callback',@getMetaDataTemplate);

sendXrayIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Submit X-ray image file'},'Visible','off',...
    'Position',[715,440,250,50],'Units','normalized','BackgroundColor',[0.31, 0.74, 0.87],'FontSize',14,'FontName','Arial','Callback',@sendXrayFile);

sendMetaDataIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Submit metadata file'},'Visible','off',...
    'Position',[715,360,250,50],'Units','normalized','BackgroundColor',[0.46, 0.82, 0.93],'FontSize',14,'FontName','Arial','Callback',@sendMetaDataFile);

sendVideoIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Submit a fieldwork video';'for loading screens'},'Visible','off',...
    'Position',[715,200,250,50],'Units','normalized','BackgroundColor',[0.99, 0.54, 0.19],'FontSize',12,'FontName','Arial','Callback',@sendVideoFile);

lblThanksCT = uicontrol(UserFig,'Style','text','String','Thank you for sending your CT data!','Position',[690,30,300,40],...
    'BackgroundColor','none','FontSize',10,'FontName','Arial','Units','normalized','Visible','off');

lblThanksMeta = uicontrol(UserFig,'Style','text','String','Thank you for sending your metadata!','Position',[690,30,300,20],...
    'BackgroundColor','none','FontSize',10,'FontName','Arial','Units','normalized','Visible','off');

lblOverwrite = uicontrol(UserFig,'Style','text','String',{'This would overwrite an existing file or folder.';'Please rename your file/folder or contact Support'},'Position',[690,5,300,100],...
    'BackgroundColor','none','FontSize',11,'FontName','Arial','Units','normalized','Visible','off');

lblUploadError = uicontrol(UserFig,'Style','text','String',{'Error uploading folder!';'Try again, or convert to a zipped file'},'Position',[690,5,300,100],...
    'BackgroundColor','none','FontSize',11,'FontName','Arial','Units','normalized','Visible','off');

lblUploadError2 = uicontrol(UserFig,'Style','text','String',{'Error uploading file!';'Try again, or contact Support'},'Position',[690,5,300,100],...
    'BackgroundColor','none','FontSize',11,'FontName','Arial','Units','normalized','Visible','off');

convertTifIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Convert Tifs: choose a folder containing .tif files'},'Visible','off',...
    'Position',[715,600,300,60],'Units','normalized','BackgroundColor',[0.58,0.93,0.78],'FontSize',10,'FontName','Arial','Callback',@convertTif);

resizeDicomsIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Resize DICOMS: choose a folder containing a';'subfolder with .dcm files'},'Visible','off',...
    'Position',[715,480,300,60],'Units','normalized','BackgroundColor',[0.58,0.93,0.78],'FontSize',10,'FontName','Arial','Callback',@resizeDicoms);

rotateDicomsIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Rotate DICOMS: choose a folder containing a';'subfolder with .dcm files'},'Visible','off',...
    'Position',[715,360,300,60],'Units','normalized','BackgroundColor',[0.58,0.93,0.78],'FontSize',10,'FontName','Arial','Callback',@rotateDicoms);

cropDicomsIn0 = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Crop DICOMS: choose a folder containing a';'subfolder with .dcm files'},'Visible','off',...
    'Position',[715,240,300,60],'Units','normalized','BackgroundColor',[0.58,0.93,0.78],'FontSize',10,'FontName','Arial','Callback',@cropDicoms0);

cropDicomsInAxial = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Crop from axial view'},'Visible','off',...
    'Position',[715,480,300,60],'Units','normalized','BackgroundColor',[0.58,0.93,0.78],'FontSize',10,'FontName','Arial','Callback',@cropDicomsAxial);

cropDicomsInSagittal = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Crop from sagittal view'},'Visible','off',...
    'Position',[715,360,300,60],'Units','normalized','BackgroundColor',[0.58,0.93,0.78],'FontSize',10,'FontName','Arial','Callback',@cropDicomsSagittal);

cropDicomsInCoronal = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Crop from coronal view'},'Visible','off',...
    'Position',[715,240,300,60],'Units','normalized','BackgroundColor',[0.58,0.93,0.78],'FontSize',10,'FontName','Arial','Callback',@cropDicomsCoronal);

uiAbout3 = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Help'},'Visible','off',...
    'Position',[225,10,150,25],'Units','normalized','FontSize',11,'FontName','Arial','Callback',@about3_callback);

uiAboutCancel3 = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Done with help'},'Visible','off',...
    'Position',[225,10,150,25],'Units','normalized','FontSize',11,'FontName','Arial','Callback',@about3Cancel_callback);

htextLink4 = uihyperlink(UserFig,'URL','https://www.sclerochronologylab.com/coralct.html','Text','www.coralct.org',...
        'FontSize',14,'FontName','Arial','Visible','off','Position',[575,10,120,25]);

htextAbout3 = uicontrol(UserFig,'Style','text','String',' ',...
    'Position',[50,200,400,400],'Units','normalized','FontSize',10,'FontName','Arial','Visible','off','BackgroundColor','w');

selpath4 = [];
function cropDicoms0(src,event)
    set(UserFig,'Visible','off')
    pause(0.001)
    selpath4 = uigetdir;
    set(UserFig,'Visible','on')

    set(resizeDicomsIn,'Visible','off')
    set(rotateDicomsIn,'Visible','off')
    set(convertTifIn,'Visible','off')
    set(cropDicomsIn0,'Visible','off')
    set(cropDicomsInAxial,'Visible','on')
    set(cropDicomsInSagittal,'Visible','on')
    set(cropDicomsInCoronal,'Visible','on')

end

cropFig = [];

    function cropDicomsAxial(src,event)

        set(cropDicomsInCoronal,'Enable','off')
        set(cropDicomsInSagittal,'Enable','off')
        set(cropDicomsInAxial,'Enable','off')
        set(editDataCancelIn,'Enable','off')
        set(uiAbout3,'Enable','off')

        folder_name = 'cropped';
        mkdir(fullfile(selpath4,folder_name));

        fileOpen = selpath4;

        resizeFactor = 1;

        ha3 = uiaxes(UserFig,'Units','Pixels','Position',[715,40,250,60],'Units','normalized','Visible','on');
        ha3.InteractionOptions.DatatipsSupported = 'off';
        ha3.InteractionOptions.ZoomSupported = "off";
        ha3.InteractionOptions.PanSupported = "off";
        ha3.Toolbar.Visible = 'off';
        hold(ha3,'on')
        set(ha3,'Xtick',[],'YTick',[],'XLim',[0 1],'YLim',[0 1])
        %processNumber = processNumber + 1;
        titleName = 'loading CT data';
        [sliceLoc,metadata] = loadDataResize(resizeFactor);
        delete(p1)
        delete(ha3)
        ha3 = uiaxes(UserFig,'Units','Pixels','Position',[715,40,250,60],'Units','normalized','Visible','on');
        ha3.InteractionOptions.DatatipsSupported = 'off';
        ha3.InteractionOptions.ZoomSupported = "off";
        ha3.InteractionOptions.PanSupported = "off";
        ha3.Toolbar.Visible = 'off';
        hold(ha3,'on')
        set(ha3,'Xtick',[],'YTick',[],'XLim',[0 1],'YLim',[0 1])

        cropFig = uifigure('Visible','off','Position',[50,100,800,800],'Color','k');
        haCrop = uiaxes(cropFig,'Units','Pixels','Position',[50,50,600,600],'Units','normalized','Color','none','xcolor','k','ycolor','k');
        cropPlot = pcolor(haCrop,1:size(X,1),1:size(X,2),max(X,[],3));
        set(cropPlot,'EdgeColor','none')
        set(cropPlot,'EdgeColor','interp')
        set(haCrop,'PlotBoxAspectRatio',[1 1 1])
        set(haCrop,'DataAspectRatio',[1 1 1])
        set(haCrop,'Colormap',colormap('bone'))
        set(cropFig,'Visible','on')

        roi = drawrectangle(haCrop);

        rows_keep = round([roi.Position(2), roi.Position(2)+roi.Position(4)]);
        cols_keep = round([roi.Position(1), roi.Position(1)+roi.Position(3)]);

        if rows_keep(1)<1
            rows_keep(1) = 1;
        end
        if rows_keep(2)>length(X(:,1,1))
            rows_keep(2) = length(X(:,1,1));
        end
        if cols_keep(1)<1
            cols_keep(1) = 1;
        end
        if cols_keep(2)>length(X(1,:,1))
            cols_keep(2) = length(X(1,:,1));
        end

        close(cropFig)

        %uiwait(UserFig)

        thisUID = dicomuid;

        %processNumber = processNumber;
        titleName = 'Cropping data';
        for a = 1:layers
            thisMeta = metadata;
            %thisMeta.Width = col;
            %thisMeta.Height = row;
            thisMeta.Width = length(cols_keep(1):cols_keep(2));
            thisMeta.Height = length(rows_keep(1):rows_keep(2));
            thisMeta.SliceLocation = sliceLoc(a);
            thisMeta.ImagePositionPatient(3) = sliceLoc(a);
            thisMeta.SliceThickness = pxS;
            thisMeta.SliceInterval = pxS;
            thisMeta.SpacingBetweenSlices = pxS;
            thisMeta.PixelSpacing = [hpxS;hpxS];
            thisMeta.SeriesInstanceUID = thisUID;
            padNum = 5-numel(num2str(a));
            pad = [];
            for a2 = 1:padNum
                pad = [pad,'0'];
            end
            dicomwrite(uint16((X(rows_keep(1):rows_keep(2),cols_keep(1):cols_keep(2),a)-metadata.RescaleIntercept)/metadata.RescaleSlope),fullfile(selpath4,folder_name,strcat(pad,num2str(a),'.dcm')),thisMeta);
            progressUpdate(a/layers)
        end

        delete(p1)
        delete(ha3)

        set(cropDicomsInCoronal,'Enable','on')
        set(cropDicomsInSagittal,'Enable','on')
        set(cropDicomsInAxial,'Enable','on')
        set(editDataCancelIn,'Enable','on')
        set(uiAbout3,'Enable','on')

        editDataCancel

    end

    function cropDicomsSagittal(src,event)

        set(cropDicomsInCoronal,'Enable','off')
        set(cropDicomsInSagittal,'Enable','off')
        set(cropDicomsInAxial,'Enable','off')
        set(editDataCancelIn,'Enable','off')
        set(uiAbout3,'Enable','off')

        folder_name = 'cropped';
        mkdir(fullfile(selpath4,folder_name));

        fileOpen = selpath4;

        resizeFactor = 1;

        ha3 = uiaxes(UserFig,'Units','Pixels','Position',[715,40,250,60],'Units','normalized','Visible','on');
        ha3.InteractionOptions.DatatipsSupported = 'off';
        ha3.InteractionOptions.ZoomSupported = "off";
        ha3.InteractionOptions.PanSupported = "off";
        ha3.Toolbar.Visible = 'off';
        hold(ha3,'on')
        set(ha3,'Xtick',[],'YTick',[],'XLim',[0 1],'YLim',[0 1])
        %processNumber = processNumber + 1;
        titleName = 'loading CT data';
        [sliceLoc,metadata] = loadDataResize(resizeFactor);
        delete(p1)
        delete(ha3)
        ha3 = uiaxes(UserFig,'Units','Pixels','Position',[715,40,250,60],'Units','normalized','Visible','on');
        ha3.InteractionOptions.DatatipsSupported = 'off';
        ha3.InteractionOptions.ZoomSupported = "off";
        ha3.InteractionOptions.PanSupported = "off";
        ha3.Toolbar.Visible = 'off';
        hold(ha3,'on')
        set(ha3,'Xtick',[],'YTick',[],'XLim',[0 1],'YLim',[0 1])

        cropFig = uifigure('Visible','off','Position',[50,100,800,800],'Color','k');
        haCrop = uiaxes(cropFig,'Units','Pixels','Position',[50,50,600,600],'Units','normalized','Color','none','xcolor','k','ycolor','k');
        cropPlot = pcolor(haCrop,1:size(X,1),1:size(X,3),squeeze(max(X,[],2))');
        set(cropPlot,'EdgeColor','none')
        set(cropPlot,'EdgeColor','interp')
        set(haCrop,'PlotBoxAspectRatio',[1 1 1])
        set(haCrop,'DataAspectRatio',[pxS hpxS hpxS]./max([pxS,hpxS]))
        set(haCrop,'Colormap',colormap('bone'))
        set(cropFig,'Visible','on')

        roi = drawrectangle(haCrop);

        rows_keep = round([roi.Position(2), roi.Position(2)+roi.Position(4)]);
        cols_keep = round([roi.Position(1), roi.Position(1)+roi.Position(3)]);

        if rows_keep(1)<1
            rows_keep(1) = 1;
        end
        if rows_keep(2)>length(X(1,1,:))
            rows_keep(2) = length(X(1,1,:));
        end
        if cols_keep(1)<1
            cols_keep(1) = 1;
        end
        if cols_keep(2)>length(X(:,1,1))
            cols_keep(2) = length(X(:,1,1));
        end

        close(cropFig)

        %uiwait(UserFig)

        thisUID = dicomuid;

        %processNumber = processNumber;
        titleName = 'Cropping data';
        for a = rows_keep(1):rows_keep(2)
            thisMeta = metadata;
            %thisMeta.Width = col;
            %thisMeta.Height = row;
            thisMeta.Width = length(cols_keep(1):cols_keep(2));
            thisMeta.Height = row;
            thisMeta.SliceLocation = sliceLoc(a);
            thisMeta.ImagePositionPatient(3) = sliceLoc(a);
            thisMeta.SliceThickness = pxS;
            thisMeta.SliceInterval = pxS;
            thisMeta.SpacingBetweenSlices = pxS;
            thisMeta.PixelSpacing = [hpxS;hpxS];
            thisMeta.SeriesInstanceUID = thisUID;
            padNum = 5-numel(num2str(a));
            pad = [];
            for a2 = 1:padNum
                pad = [pad,'0'];
            end
            dicomwrite(uint16((X(:,cols_keep(1):cols_keep(2),a)-metadata.RescaleIntercept)/metadata.RescaleSlope),fullfile(selpath4,folder_name,strcat(pad,num2str(a),'.dcm')),thisMeta);
            progressUpdate(a/rows_keep(2))
        end

        delete(p1)
        delete(ha3)

        set(cropDicomsInCoronal,'Enable','on')
        set(cropDicomsInSagittal,'Enable','on')
        set(cropDicomsInAxial,'Enable','on')
        set(editDataCancelIn,'Enable','on')
        set(uiAbout3,'Enable','on')

        editDataCancel

    end

    function cropDicomsCoronal(src,event)
        
        set(cropDicomsInCoronal,'Enable','off')
        set(cropDicomsInSagittal,'Enable','off')
        set(cropDicomsInAxial,'Enable','off')
        set(editDataCancelIn,'Enable','off')
        set(uiAbout3,'Enable','off')

        folder_name = 'cropped';
        mkdir(fullfile(selpath4,folder_name));

        fileOpen = selpath4;

        resizeFactor = 1;

        ha3 = uiaxes(UserFig,'Units','Pixels','Position',[715,40,250,60],'Units','normalized','Visible','on');
        ha3.InteractionOptions.DatatipsSupported = 'off';
        ha3.InteractionOptions.ZoomSupported = "off";
        ha3.InteractionOptions.PanSupported = "off";
        ha3.Toolbar.Visible = 'off';
        hold(ha3,'on')
        set(ha3,'Xtick',[],'YTick',[],'XLim',[0 1],'YLim',[0 1])
        %processNumber = processNumber + 1;
        titleName = 'loading CT data';
        [sliceLoc,metadata] = loadDataResize(resizeFactor);
        delete(p1)
        delete(ha3)
        ha3 = uiaxes(UserFig,'Units','Pixels','Position',[715,40,250,60],'Units','normalized','Visible','on');
        ha3.InteractionOptions.DatatipsSupported = 'off';
        ha3.InteractionOptions.ZoomSupported = "off";
        ha3.InteractionOptions.PanSupported = "off";
        ha3.Toolbar.Visible = 'off';
        hold(ha3,'on')
        set(ha3,'Xtick',[],'YTick',[],'XLim',[0 1],'YLim',[0 1])

        cropFig = uifigure('Visible','off','Position',[50,100,800,800],'Color','k');
        haCrop = uiaxes(cropFig,'Units','Pixels','Position',[50,50,600,600],'Units','normalized','Color','none','xcolor','k','ycolor','k');
        cropPlot = pcolor(haCrop,1:size(X,2),1:size(X,3),squeeze(max(X,[],1))');
        set(cropPlot,'EdgeColor','none')
        set(cropPlot,'EdgeColor','interp')
        set(haCrop,'PlotBoxAspectRatio',[1 1 1])
        set(haCrop,'DataAspectRatio',[pxS hpxS hpxS]./max([pxS,hpxS]))
        set(haCrop,'Colormap',colormap('bone'))
        set(cropFig,'Visible','on')

        roi = drawrectangle(haCrop);

        rows_keep = round([roi.Position(2), roi.Position(2)+roi.Position(4)]);
        cols_keep = round([roi.Position(1), roi.Position(1)+roi.Position(3)]);

        if rows_keep(1)<1
            rows_keep(1) = 1;
        end
        if rows_keep(2)>length(X(1,1,:))
            rows_keep(2) = length(X(1,1,:));
        end
        if cols_keep(1)<1
            cols_keep(1) = 1;
        end
        if cols_keep(2)>length(X(1,:,1))
            cols_keep(2) = length(X(1,:,1));
        end

        close(cropFig)

        %uiwait(UserFig)

        thisUID = dicomuid;

        %processNumber = processNumber;
        titleName = 'Cropping data';
        for a = rows_keep(1):rows_keep(2)
            thisMeta = metadata;
            %thisMeta.Width = col;
            %thisMeta.Height = row;
            thisMeta.Width = length(cols_keep(1):cols_keep(2));
            thisMeta.Height = col;
            thisMeta.SliceLocation = sliceLoc(a);
            thisMeta.ImagePositionPatient(3) = sliceLoc(a);
            thisMeta.SliceThickness = pxS;
            thisMeta.SliceInterval = pxS;
            thisMeta.SpacingBetweenSlices = pxS;
            thisMeta.PixelSpacing = [hpxS;hpxS];
            thisMeta.SeriesInstanceUID = thisUID;
            padNum = 5-numel(num2str(a));
            pad = [];
            for a2 = 1:padNum
                pad = [pad,'0'];
            end
            dicomwrite(uint16((X(:,cols_keep(1):cols_keep(2),a)-metadata.RescaleIntercept)/metadata.RescaleSlope),fullfile(selpath4,folder_name,strcat(pad,num2str(a),'.dcm')),thisMeta);
            progressUpdate(a/rows_keep(2))
        end

        delete(p1)
        delete(ha3)

        set(cropDicomsInCoronal,'Enable','on')
        set(cropDicomsInSagittal,'Enable','on')
        set(cropDicomsInAxial,'Enable','on')
        set(editDataCancelIn,'Enable','on')
        set(uiAbout3,'Enable','on')

        editDataCancel

    end

    function about3_callback(src,event)

        set(htextAbout3,'String',' ')
        about_text_label = sprintf(['Use the buttons to the right to submit data to the CoralCache server. After ' ...
            'submitting, there will be a delay before your submission is available on CoralCT because we need to update CoralCache.' ...
            '\n\nIf submitting CT scans, these should be in DICOM format (.dcm or .dicom). Preferably, compress all of the DICOMS ' ...
            'for one core into a .zip file, name the file CORENAME.zip where CORENAME is your sample name for that core, and ' ...
            'use the ''Submit zipped file'' button. If you need to convert TIFF images into DICOMS, use the ''Submit or resize data'' button before compressing.' ...
            '\n\nSome CT scans may benefit from resizing. If the compressed file is greater than 500MB, you may experience some lagging ' ...
            'while clicking on bands. Visit www.coralct.org for additional guidance and example videos of the effects of resizing.' ...
            '\n\nYou may also upload DICOMS by selecting the folder containing the DICOM images and using the ''Submit data folder'' button. ' ...
            'However, this is not preferred because it will take much longer to upload.' ...
            '\n\nX-ray images can be submitted either by pressing the ''Submit X-ray image file'' button (for TIFF, JPG, or PNG), or by placing image ' ...
            'files in a folder and submitting the folder with the ''Submit data folder button''.' ...
            '\n\nAll submissions should include a metadata file submission, preferrably using our template. You can add multiple rows in one metadata ' ...
            'file if submitting multiple cores. Visit www.coralct.org for more guidance on the metadata template.' ...
            '\n\nWe also encourage submitting fieldwork or coral reef videos so we can add variety to the loading screens!']);

        set(htextAbout3,'String',about_text_label,'Visible','on','Units','pixels',...
            'Position',[50,120,580,530],'Units','normalized','HorizontalAlignment', 'left','FontSize',11)
        pause(0.01)

        set(dispVidCT,'Visible','off')

        set(uiAboutCancel3,'Visible','on')
        set(uiAbout3,'Visible','off')

    end

    function about3Cancel_callback(src,event)

        set(dispVidCT,'Visible','on')

        set(uiAboutCancel3,'Visible','off')
        set(htextAbout3,'Visible','off')
        set(uiAbout3,'Visible','on')

    end

    function makeMap0(src,event)
        set(makeMapIn,'Visible','on')
        set(htextLatN,'Visible','on')
        set(latNsetIn,'Visible','on')
        set(htextLatS,'Visible','on')
        set(latSsetIn,'Visible','on')
        set(htextLonE,'Visible','on')
        set(lonEsetIn,'Visible','on')
        set(htextLonW,'Visible','on')
        set(lonWsetIn,'Visible','on')
        set(htextMapName,'Visible','on')
        set(mapNameSetIn,'Visible','on')
        set(directSubmitGoIn,'Visible','off')
        set(directSubmitMetaIn,'Visible','off')
        set(directSubmitDataIn,'Visible','off')
        set(directSubmitIn,'Visible','off')
        set(htextLinkUserGuide,'Visible','off')
        set(makeMapIn0,'Visible','off')
        set(mapCancelIn,'Visible','on')
        set(mapResIn,'Visible','on')
        set(htextMapRes,'Visible','on')
        set(editDataCancelIn,'Visible','off')
        
    end

    function mapCancel(src,event)
        set(makeMapIn,'Visible','off')
        set(htextLatN,'Visible','off')
        set(latNsetIn,'Visible','off')
        set(htextLatS,'Visible','off')
        set(latSsetIn,'Visible','off')
        set(htextLonE,'Visible','off')
        set(lonEsetIn,'Visible','off')
        set(htextLonW,'Visible','off')
        set(lonWsetIn,'Visible','off')
        set(htextMapName,'Visible','off')
        set(mapNameSetIn,'Visible','off')
        set(directSubmitGoIn,'Visible','on')
        set(directSubmitMetaIn,'Visible','on')
        set(directSubmitDataIn,'Visible','on')
        set(makeMapIn0,'Visible','on')
        set(mapCancelIn,'Visible','off')
        set(mapResIn,'Visible','off')
        set(htextMapRes,'Visible','off')
        set(editDataCancelIn,'Visible','on')
        set(coordSetError,'Visible','off')
    end

htextMapRes = uicontrol(UserFig,'Style','text','String','Map resolution:','Visible','off',...
    'Position',[760,525,150,24],'Units','normalized','BackgroundColor','none','ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial');

mapResIn = uicontrol(UserFig,'Style','popupmenu',...
    'Position',[760,500,150,25],'Units','normalized',...
    'String',{'Highest','High','Intermediate','Low','Lowest'},'Visible','off',...
    'Callback',@mapRes);

mapResSave = {'Highest'};
mapResOptions = {'Highest','High','Intermediate','Low','Lowest'};
    function mapRes(src,event)
        mapResSave = mapResOptions(mapResIn.Value);
    end

coordSetError = uicontrol(UserFig,'Style','text','String',' ','Visible','off',...
    'Position',[760,680,150,40],'Units','normalized','BackgroundColor','none','ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial');


htextLonW = uicontrol(UserFig,'Style','text','String','W:','Visible','off',...
    'Position',[720,625,15,20],'Units','normalized','BackgroundColor','none','ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial');

lonWsetIn = uicontrol(UserFig,'Style','Edit','Visible','off',...
    'Position',[740,625,60,20],'Units','normalized','Callback', @makeMapWset);

mapWset = [];
    function makeMapWset(src,event)
        mapWset = str2num(lonWsetIn.String);
        set(coordSetError,'Visible','off')
        if length(mapWset) == 0
            set(coordSetError,'String','Enter only numbers','Visible','on')
        end
        try
            if mapWset >= -180 && mapWset <= 180
            else
                set(coordSetError,'String',{'Longitude must be';'within -180 to 180'},'Visible','on')
            end
        catch
        end
    end

htextLatN = uicontrol(UserFig,'Style','text','String','N:','Visible','off',...
    'Position',[800,650,15,20],'Units','normalized','BackgroundColor','none','ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial');

latNsetIn = uicontrol(UserFig,'Style','Edit','Visible','off',...
    'Position',[820,650,60,20],'Units','normalized','Callback', @makeMapNset);

mapNset = [];
    function makeMapNset(src,event)
        mapNset = str2num(latNsetIn.String);
        set(coordSetError,'Visible','off')
        if length(mapNset) == 0
            set(coordSetError,'String','Enter only numbers','Visible','on')
        end
        try
            if mapNset >= -90 && mapNset <= 90
            else
                set(coordSetError,'String',{'Latitude must be';'within -90 to 90'},'Visible','on')
            end
        catch
        end
    end

htextLatS = uicontrol(UserFig,'Style','text','String','S:','Visible','off',...
    'Position',[800,600,15,20],'Units','normalized','BackgroundColor','none','ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial');

latSsetIn = uicontrol(UserFig,'Style','Edit','Visible','off',...
    'Position',[820,600,60,20],'Units','normalized','Callback', @makeMapSset);

mapSset = [];
    function makeMapSset(src,event)
        mapSset = str2num(latSsetIn.String);
        set(coordSetError,'Visible','off')
        if length(mapSset) == 0
            set(coordSetError,'String','Enter only numbers','Visible','on')
        end
        try
            if mapSset >= -90 && mapSset <= 90
            else
                set(coordSetError,'String',{'Latitude must be';'within -90 to 90'},'Visible','on')
            end
        catch
        end
    end

htextLonE = uicontrol(UserFig,'Style','text','String','E:','Visible','off',...
    'Position',[880,625,15,20],'Units','normalized','BackgroundColor','none','ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial');

lonEsetIn = uicontrol(UserFig,'Style','Edit','Visible','off',...
    'Position',[900,625,60,20],'Units','normalized','Callback', @makeMapEset);

mapEset = [];
    function makeMapEset(src,event)
        mapEset = str2num(lonEsetIn.String);
        set(coordSetError,'Visible','off')
        if length(mapEset) == 0
            set(coordSetError,'String','Enter only numbers','Visible','on')
        end
        try
            if mapEset >= -180 && mapEset <= 180
            else
                set(coordSetError,'String',{'Longitude must be';'within -180 to 180'},'Visible','on')
            end
        catch
        end
    end

htextMapName = uicontrol(UserFig,'Style','text','String','Region or subregion name:','Visible','off',...
    'Position',[735,445,200,20],'Units','normalized','BackgroundColor','none','ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial');

mapNameSetIn = uicontrol(UserFig,'Style','Edit','Visible','off',...
    'Position',[735,420,200,20],'Units','normalized','Callback', @mapNameSet);

mapName = ' ';
    function mapNameSet(src,event)
        mapName = mapNameSetIn.String;
    end

    function makeMap(src,event)

        set(makeMapIn,'Enable','off')

        try

        if max(strcmp(mapResSave,mapResOptions))<1
            set(coordSetError,'String',{'Please choose a resolution'},'Visible','on')
            set(makeMapIn,'Enable','on')
        elseif mapWset < -180 || mapWset > 180 || mapEset < -180 || mapEset > 180
            set(coordSetError,'String',{'Longitude must be';'within -180 to 180'},'Visible','on')
            set(makeMapIn,'Enable','on')
        elseif mapNset < -90 || mapNset > 90 || mapSset < -90 || mapSset > 90
            set(coordSetError,'String',{'Latitude must be';'within -90 to 90'},'Visible','on')
            set(makeMapIn,'Enable','on')
        elseif mapNset <= mapSset
            set(coordSetError,'String',{'N value must be';'greater than S value'},'Visible','on')
            set(makeMapIn,'Enable','on')
        elseif mapEset <= mapWset
            set(coordSetError,'String',{'E value must be';'greater than W value'},'Visible','on')
            set(makeMapIn,'Enable','on')
        else
            set(coordSetError,'Visible','off')
            C = {mapResSave{1}, string(num2str(mapNset)), string(num2str(mapSset)), string(num2str(mapEset)), string(num2str(mapWset)), mapName, saveFileName};
            fid = fopen(fullfile(refPath,strcat('map_request_',num2str(mapNset), num2str(mapSset), num2str(mapEset), num2str(mapWset),'.csv')));
            writecell(C,fullfile(refPath,strcat('map_request_',num2str(mapNset), num2str(mapSset), num2str(mapEset), num2str(mapWset),'.csv')));
            try fclose(fid);
            catch
            end

            % connect
            try
                cache3 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                cd(cache3,'CoralCache/submitted_maps')
                mput(cache3,fullfile(refPath,strcat('map_request_',num2str(mapNset), num2str(mapSset), num2str(mapEset), num2str(mapWset),'.csv')))
                delete(fullfile(refPath,strcat('map_request_',num2str(mapNset), num2str(mapSset), num2str(mapEset), num2str(mapWset),'.csv')))
                close(cache3)
            catch
                try
                    connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                    connectionEstablished = 0;
                    for ij = 1:length(connectTimes)
                        if connectionEstablished == 0
                            if connectTimes(ij) == 1
                                waitText = [' ',num2str(connectTimes(ij)),' minute.']
                            else
                                waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                            end
                            set(lblSendingDirect,'Units','Pixels','Visible','on',...
                                'String',{'Error connecting to server.';strcat('Trying again in',waitText)})
                            pause(connectTimes(ij)*60)
                            try
                                cache3 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                cd(cache3,'CoralCache/submitted_maps')
                                mput(cache3,fullfile(refPath,strcat('map_request_',num2str(mapNset), num2str(mapSset), num2str(mapEset), num2str(mapWset),'.csv')))
                                delete(fullfile(refPath,strcat('map_request_',num2str(mapNset), num2str(mapSset), num2str(mapEset), num2str(mapWset),'.csv')))
                                close(cache3)
                                connectionEstablished = 1;
                                set(lblSendingDirect,'String','Sending data...')
                            catch
                            end
                        end
                    end
                    if connectionEstablished == 0
                        zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                    end
                catch
                    set(lblSendingDirect,'Visible','on',...
                        'String',{'Error connecting to server. (code 040)';'Please try again later.'})
                    while 1==1
                        pause
                    end
                end
            end
            set(coordSetError,'String',{'Submission successful'},'Visible','on')
            set(lonEsetIn,'String','')
            set(lonWsetIn,'String','')
            set(latNsetIn,'String','')
            set(latSsetIn,'String','')
            set(mapNameSetIn,'String','')
            set(makeMapIn,'Enable','on')
            pause(10)
            set(coordSetError,'Visible','off')
            
        end

        catch
            set(coordSetError,'String',{'Request unsuccessful';'please try again'},'Visible','on')
            set(makeMapIn,'Enable','on')
        end


    end


    function directSubmit0(src,event)

        set(sendDataIn,'Visible','off')
        set(editDataIn,'Visible','off')
        set(sendDataFileIn,'Visible','off')
        set(sendXrayIn,'Visible','off')
        set(getMetaDataIn,'Visible','off')
        set(sendMetaDataIn,'Visible','off')
        set(sendVideoIn,'Visible','off')
        set(mainMenuIn,'Visible','off')
        set(lblThanksCT,'Visible','off')
        set(lblThanksMeta,'Visible','off')
        set(lblOverwrite,'Visible','off')
        set(lblUploadError,'Visible','off')
        set(lblUploadError2,'Visible','off')

        set(editDataCancelIn,'Visible','on')
        set(directSubmitIn,'Visible','on')
        set(htextLinkUserGuide,'Visible','on')
        set(directSubmit0In,'Visible','off')

    end

    function directSubmit(src,event)

        set(directSubmitIn,'Visible','off')
        set(htextLinkUserGuide,'Visible','off')
        set(directSubmitGoIn,'Visible','on')
        set(directSubmitDataIn,'Visible','on')
        set(directSubmitMetaIn,'Visible','on')

        set(makeMapIn0,'Visible','on')

    end

datafile2send = [];
metafile2send = [];
selpathmeta = [];
selpathdata = [];
haveMeta = 0;
haveData = 0;

    function directSubmitMeta(src,event)

        set(UserFig,'Visible','off')
        pause(0.001)

        [metafile2send,selpathmeta] = uigetfile({'*.xlsx'},'Choose metadata');
        set(UserFig,'Visible','on')

        set(directSubmitMetaIn,'Enable','off')
        set(makeMapIn0,'Enable','off')
        haveMeta = 1;
        if haveData == 1
            set(directSubmitGoIn,'Enable','on')
        end

    end

    function directSubmitData(src,event)

        set(UserFig,'Visible','off')
        pause(0.001)

        [datafile2send,selpathdata] = uigetfile({'*.zip;*.tiff'},'Choose X-ray or CT scan');
        set(UserFig,'Visible','on')

        set(directSubmitDataIn,'Enable','off')
        set(makeMapIn0,'Enable','off')
        haveData = 1;
        if haveMeta == 1
            set(directSubmitGoIn,'Enable','on')
        end

    end

lblSendingDirect = [];
    function directSubmitGo(src,event)

        haveMeta = 0;
        haveData = 0;

        try

            set(directSubmitGoIn,'Enable','off')
            set(editDataCancelIn,'Enable','off')
            set(uiAbout3,'Enable','off')

            try delete(lblSendingDirect)
            catch
            end
            lblSendingDirect = uicontrol(UserFig,'Style','text','String','Sending data...','Position',[720,80,250,40],...
                'BackgroundColor','none','FontSize',12,'FontName','Arial','Units','normalized','Visible','on');

            pause(0.1)
            % read metadata
            [newmeta_num,newmeta_text,raw] = xlsread(fullfile(selpathmeta,metafile2send))

            successDirect = 0;
            for jji = 1%:length(newmeta_text(:,1))-1 % only read top one

                submittedCoreName = newmeta_text{jji+1,1};
                submittedSectionName = newmeta_text{jji+1,2};
                submittedRegionName = newmeta_text{jji+1,3};
                submittedSubregionName = newmeta_text{jji+1,4};
                submittedGenus = newmeta_text{jji+1,5};
                submittedOwner = newmeta_text{jji+1,6};
                submittedNotes = newmeta_text{jji+1,7};
                submittedIsCT = newmeta_num(jji,12);

                submittedCitation = newmeta_text{jji+1,8};
                submittedAcknowledge = newmeta_text{jji+1,9};

                if max(strcmp(submittedCoreName,coralDir.textdata(:,1))) == 1 && strcmp(submittedSectionName,'') && ~strcmp(submittedRegionName,'standards')
                    directSubmitErrorMsg = sprintf('Core %s name already taken',submittedCoreName);
                    set(lblSendingDirect,'String',directSubmitErrorMsg)
                    break
                end

                if max(strcmp(submittedCoreName,coralDir.textdata(:,1))) == 1 && max(strcmp(submittedSectionName,coralDir.textdata(:,2)))
                    directSubmitErrorMsg = sprintf('Core/section %s name already taken',submittedCoreName);
                    set(lblSendingDirect,'String',directSubmitErrorMsg)
                    break
                end

                % connect
                try
                    cache3 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                catch
                    try
                        connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                        connectionEstablished = 0;
                        for ij = 1:length(connectTimes)
                            if connectionEstablished == 0
                                if connectTimes(ij) == 1
                                    waitText = [' ',num2str(connectTimes(ij)),' minute.']
                                else
                                    waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                                end
                                set(lblSendingDirect,'Units','Pixels','Visible','on',...
                                    'String',{'Error connecting to server.';strcat('Trying again in',waitText)})
                                pause(connectTimes(ij)*60)
                                try
                                    cache3 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                    connectionEstablished = 1;
                                    set(lblSendingDirect,'String','Sending data...')
                                catch
                                end
                            end
                        end
                        if connectionEstablished == 0
                            zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                        end
                    catch
                        set(lblSendingDirect,'Visible','on',...
                            'String',{'Error connecting to server. (code 035)';'Please try again later.'})
                        while 1==1
                            pause
                        end
                    end
                end


                % creating folders and placing dicoms
                close(cache3)
                cache3 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                cd(cache3,'hd1')
                current_regions = dir(cache3);
                region_list = {''};
                for iij = 1:length(current_regions)
                    region_list{iij} = char(current_regions(iij).name);
                end
                if max(strcmp(submittedRegionName,region_list)) == 0
                    mkdir(cache3,submittedRegionName)
                end
                cd(cache3,submittedRegionName)

                current_subregions = dir(cache3);
                subregion_list = {''};
                for iij = 1:length(current_subregions)
                    subregion_list{iij} = char(current_subregions(iij).name);
                end
                if max(strcmp(submittedSubregionName,subregion_list)) == 0
                    mkdir(cache3,submittedSubregionName)
                end
                cd(cache3,submittedSubregionName)

                if submittedIsCT==1 && ~strcmp(datafile2send,'dicoms.zip')
                    directSubmitErrorMsg = 'Data file not named dicoms.zip';
                    set(lblSendingDirect,'String',directSubmitErrorMsg)
                    break
                end

                if submittedIsCT==0 && ~strcmp(datafile2send,'xray.tiff')
                    directSubmitErrorMsg = 'Data file not named xray.tiff';
                    set(lblSendingDirect,'String',directSubmitErrorMsg)
                    break
                end

                current_cores = dir(cache3);
                cores_list = {''};
                for iij = 1:length(current_cores)
                    cores_list{iij} = char(current_cores(iij).name);
                end
                if max(strcmp(submittedCoreName,cores_list)) == 1 && strcmp(submittedSectionName,'')
                    directSubmitErrorMsg = sprintf('Core %s folder already exists',submittedCoreName);
                    set(lblSendingDirect,'String',directSubmitErrorMsg)
                    break
                elseif max(strcmp(submittedCoreName,cores_list)) == 0
                    mkdir(cache3,submittedCoreName)
                end
                cd(cache3,submittedCoreName)

                % check for sections
                if ~strcmp(submittedSectionName,'') % there are sections
                    current_sections = dir(cache3);
                    sections_list = {''};
                    for iij = 1:length(current_sections)
                        sections_list{iij} = char(current_sections(iij).name);
                    end
                    if max(strcmp(submittedSectionName,sections_list)) == 1
                        directSubmitErrorMsg = sprintf('Section %s folder already exists',submittedSectionName);
                        set(lblSendingDirect,'String',directSubmitErrorMsg)
                        break
                    else max(strcmp(submittedCoreName,cores_list))
                        mkdir(cache3,submittedSectionName)
                    end
                    cd(cache3,submittedSectionName)

                    % place data
                    if submittedIsCT==1
                        mput(cache3,fullfile(selpathdata,'dicoms.zip'))
                    elseif submittedIsCT==0
                        mput(cache3,fullfile(selpathdata,'xray.tiff'))
                    end

                else % no sections, just add core
                    if submittedIsCT==1
                        mput(cache3,fullfile(selpathdata,'dicoms.zip'))
                    elseif submittedIsCT==0
                        mput(cache3,fullfile(selpathdata,'xray.tiff'))
                    end
                end

                % don't add to directory for standards submissions

                % import master directory list into this session (so as to
                % make sure we have latest version from server)
                try mget(cache3,'coral_directory_master.txt',fullfile(selpath,'my_corals'));
                    coralDir = importdata(fullfile(selpath,'my_corals','coral_directory_master.txt'));
                    %close(cache3);
                catch
                    cache3 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password); % make sure we can connect to sftp server 1
                    cd(cache3,'/CoralCache');
                    mget(cache3,'coral_directory_master.txt',fullfile(selpath,'my_corals'));
                    %close(cache3);
                    coralDir = importdata(fullfile(selpath,'my_corals','coral_directory_master.txt'));
                    try
                        mget(cache1,'coral_directory_master.txt',fullfile(selpath,'my_corals'));
                        coralDir = importdata(fullfile(selpath,'my_corals','coral_directory_master.txt'));
                    catch
                    end
                end


                if ~strcmp(submittedRegionName,'standards')
                    % add to metadata
                    coralDir.textdata(end+1,1:7) = newmeta_text(jji+1,1:7);
                    coralDir.data(end+1,:) = newmeta_num(jji,:);

                    coralDirHold = coralDir;
                    coralDirHold.textdata = coralDirHold.textdata(2:end,:);
                    coralDirStruct = struct('name',coralDirHold.textdata(:,1),...
                        'piece',coralDirHold.textdata(:,2),...
                        'region',coralDirHold.textdata(:,3),...
                        'sub_region',coralDirHold.textdata(:,4),...
                        'genus',coralDirHold.textdata(:,5),...
                        'owner',coralDirHold.textdata(:,6),...
                        'notes',coralDirHold.textdata(:,7),...
                        'hard_drive',coralDirHold.data(1,1),...
                        'flip',coralDirHold.data(1,2),...
                        'lat',coralDirHold.data(1,3),...
                        'lon',coralDirHold.data(1,4),...
                        'depth',coralDirHold.data(1,5),...
                        'month',coralDirHold.data(1,6),...
                        'year',coralDirHold.data(1,7),...
                        'file_size',coralDirHold.data(1,8),...
                        'unlocked',coralDirHold.data(1,9),...
                        'denslope',coralDirHold.data(1,10),...
                        'denintercept',coralDirHold.data(1,11),...
                        'ct',coralDirHold.data(1,12),...
                        'xraypos',coralDirHold.data(1,13),...
                        'dpi',coralDirHold.data(1,14));
                    for ic = 1:length(coralDirHold.data)
                        coralDirStruct(ic).hard_drive = coralDirHold.data(ic,1);
                        coralDirStruct(ic).flip = coralDirHold.data(ic,2);
                        coralDirStruct(ic).lat = coralDirHold.data(ic,3);
                        coralDirStruct(ic).lon = coralDirHold.data(ic,4);
                        coralDirStruct(ic).depth = coralDirHold.data(ic,5);
                        coralDirStruct(ic).month = coralDirHold.data(ic,6);
                        coralDirStruct(ic).year = coralDirHold.data(ic,7);
                        coralDirStruct(ic).file_size = coralDirHold.data(ic,8);
                        coralDirStruct(ic).unlocked = coralDirHold.data(ic,9);
                        coralDirStruct(ic).denslope = coralDirHold.data(ic,10);
                        coralDirStruct(ic).denintercept = coralDirHold.data(ic,11);
                        coralDirStruct(ic).ct = coralDirHold.data(ic,12);
                        coralDirStruct(ic).xraypos = coralDirHold.data(ic,13);
                        coralDirStruct(ic).dpi = coralDirHold.data(ic,14);
                    end
                    writetable(struct2table(coralDirStruct),fullfile(selpath,'my_corals','coral_directory_master.txt'),'Delimiter','\t')
                    close(cache3)
                    cache3 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                    cd(cache3,'CoralCache')
                    mput(cache3,fullfile(selpath,'my_corals','coral_directory_master.txt'))
                    % load new version into this session:
                    coralDir = importdata(fullfile(selpath,'my_corals','coral_directory_master.txt'));

                    % add to citation list
                    % import master citation list into this session
                    try mget(cache3,'coral_directory_citations.txt',fullfile(selpath,'my_corals'));
                        citationDir = importdata(fullfile(selpath,'my_corals','coral_directory_citations.txt'));
                        %close(cache3);
                    catch
                        cache3 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password); % make sure we can connect to sftp server 1
                        cd(cache3,'/CoralCache');
                        mget(cache3,'coral_directory_citations.txt',fullfile(selpath,'my_corals'));
                        %close(cache3);
                        citationDir = importdata(fullfile(selpath,'my_corals','coral_directory_citations.txt'));
                        try
                            mget(cache1,'coral_directory_citations.txt',fullfile(selpath,'my_corals'));
                            citationDir = importdata(fullfile(selpath,'my_corals','coral_directory_citations.txt'));
                        catch
                        end
                    end

                    citationDir.textdata(end+1,1:2) = newmeta_text(jji+1,1:2);
                    citationDir.textdata(end,3:4) = newmeta_text(jji+1,8:9);
                    citationDir.data(end+1,1) = 1;

                    citationDirHold = citationDir;
                    citationDirHold.textdata = citationDirHold.textdata(2:end,:);
                    citationDirStruct = struct('name',citationDirHold.textdata(:,1),...
                        'piece',citationDirHold.textdata(:,2),...
                        'citation',citationDirHold.textdata(:,3),...
                        'acknowledgement',citationDirHold.textdata(:,4));
                    for ic = 1:length(citationDirHold.data)
                        citationDirStruct(ic).num = citationDirHold.data(ic,1);
                    end
                    writetable(struct2table(citationDirStruct),fullfile(selpath,'my_corals','coral_directory_citations.txt'),'Delimiter','\t')
                    try mput(cache3,fullfile(selpath,'my_corals','coral_directory_citations.txt'));
                        close(cache3);
                    catch
                        cache3 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password); % make sure we can connect to sftp server 1
                        cd(cache3,'/CoralCache');
                        mput(cache3,fullfile(selpath,'my_corals','coral_directory_citations.txt'));close(cache3);
                        citationDir = importdata(fullfile(selpath,'my_corals','coral_directory_citations.txt'));
                        try
                            mput(cache1,fullfile(selpath,'my_corals','coral_directory_citations.txt'));
                        catch
                        end
                    end
                end
                successDirect = 1;
            end

            set(editDataCancelIn,'Enable','on')
            set(directSubmitGoIn,'Enable','off')
            set(directSubmitMetaIn,'Enable','on')
            set(directSubmitDataIn,'Enable','on')
            set(makeMapIn0,'Enable','on')
            haveMeta = 0;
            haveData = 0;
            if successDirect == 1
                set(lblSendingDirect,'Visible','off')
            end
            set(uiAbout3,'Enable','on')
        catch
            set(lblSendingDirect,'String','Unknown error, try again')
            set(editDataCancelIn,'Enable','on')
        end

    end


    function editData(src,event)

        set(sendDataIn,'Visible','off')
        set(editDataIn,'Visible','off')
        set(sendDataFileIn,'Visible','off')
        set(sendXrayIn,'Visible','off')
        set(getMetaDataIn,'Visible','off')
        set(sendMetaDataIn,'Visible','off')
        set(sendVideoIn,'Visible','off')
        set(mainMenuIn,'Visible','off')
        set(lblThanksCT,'Visible','off')
        set(lblThanksMeta,'Visible','off')
        set(lblOverwrite,'Visible','off')
        set(lblUploadError,'Visible','off')
        set(lblUploadError2,'Visible','off')

        set(editDataCancelIn,'Visible','on')
        set(convertTifIn,'Visible','on')
        set(resizeDicomsIn,'Visible','on')
        set(rotateDicomsIn,'Visible','on')
        set(cropDicomsIn0,'Visible','on')
        set(editDataCancelIn,'Visible','on')
        set(directSubmit0In,'Visible','off')

    end

    function editDataCancel(src,event)

        set(sendDataIn,'Visible','on')
        set(editDataIn,'Visible','on')
        set(sendDataFileIn,'Visible','on')
        set(sendXrayIn,'Visible','on')
        set(sendMetaDataIn,'Visible','on')
        set(getMetaDataIn,'Visible','on')
        set(sendVideoIn,'Visible','on')
        set(mainMenuIn,'Visible','on')

        set(editDataCancelIn,'Visible','off')
        set(convertTifIn,'Visible','off')
        set(resizeDicomsIn,'Visible','off')
        set(rotateDicomsIn,'Visible','off')
        set(cropDicomsIn0,'Visible','off')

        set(directSubmitMetaIn,'Enable','on')
        set(directSubmitDataIn,'Enable','on')
        %set(directSubmit0In,'Visible','on') %ZZ turn back on for direct submission
        set(directSubmitIn,'Visible','off')
        set(htextLinkUserGuide,'Visible','off')
        set(directSubmitGoIn,'Visible','off')
        set(directSubmitMetaIn,'Visible','off')
        set(directSubmitDataIn,'Visible','off')
        set(lblSendingDirect,'Visible','off')
        set(uiAbout3,'Enable','on')

        set(makeMapIn0,'Enable','on')
        set(makeMapIn0,'Visible','off')

        set(cropDicomsInAxial,'Visible','off')
        set(cropDicomsInSagittal,'Visible','off')
        set(cropDicomsInCoronal,'Visible','off')
        
    end

    function rotateDicoms(src,event)

        set(UserFig,'Visible','off')
        pause(0.001)
        selpath3 = uigetdir;
        set(UserFig,'Visible','on')

        set(resizeDicomsIn,'Visible','off')
        set(convertTifIn,'Visible','off')
        set(editDataCancelIn,'Visible','off')

        function editDataCancel3(src,event)
            set(editDataCancelIn,'Visible','on')
            set(editDataCancelIn3,'Visible','off')
            set(convertTifIn,'Visible','on')
            set(resizeDicomsIn,'Visible','on')
            set(rotateDicomsIn,'Visible','on')
            set(cropDicomsIn0,'Visible','on')
            set(htextRotate,'Visible','off')
            set(rotateSetIn,'Visible','off')
            set(launchRotateIn,'Visible','off')
        end

        editDataCancelIn3 = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Go back'},'Visible','on',...
            'Position',[715,120,250,60],'Units','normalized','BackgroundColor',[0.78,0.94,0.54],'FontSize',12,'FontName','Arial','Callback',@editDataCancel3);

        set(resizeDicomsIn,'Visible','off')
        set(rotateDicomsIn,'Visible','off')
        set(cropDicomsIn0,'Visible','off')
        set(convertTifIn,'Visible','off')
        set(editDataCancelIn,'Visible','off')

        fileOpen = selpath;

        htextRotate = uicontrol(UserFig,'Style','text','String',{'Permute dimensions';'(i.e. [3,2,1] flips the third';'dimension with the first)'},'Position',[725,340,300,80],...
            'BackgroundColor','none','FontSize',11,'FontName','Arial','Units','normalized','Visible','on');

        rotateSetIn = uicontrol(UserFig,'Style','Edit','String','[3,2,1]',...
            'Position',[795,325,150,25],'Units','normalized','FontName','Arial');

        launchRotateIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Go!'},'Visible','on',...
            'Position',[1000,240,60,60],'Units','normalized','BackgroundColor',[0.61,0.86,0.57],'ForegroundColor',[0,0,0],'FontSize',14,'FontName','Arial','Callback',@launchRotate);

        function launchRotate(src,event)
            uiresume(UserFig)
        end

        uiwait(UserFig)

        set(htextRotate,'Visible','off')
        set(rotateSetIn,'Visible','off')
        set(launchRotateIn,'Visible','off')

        pause(0.01)

        folder_name = 'rotated';
        mkdir(fullfile(selpath3,folder_name));

        [sliceLoc,metadata] = loadDataResize(1);

        X = permute(X,str2num(rotateSetIn.String));
        [ROWS,COLS,ZS] = meshgrid(hpxS:hpxS:col*hpxS,pxS:pxS:layers*pxS,hpxS:hpxS:row*hpxS);
        [ROWSq,COLSq,ZSq] = meshgrid(hpxS:hpxS:col*hpxS,linspace(pxS,layers*pxS,(layers*pxS-pxS)/hpxS),hpxS:hpxS:row*hpxS);
        X = interp3(ROWS,COLS,ZS,X,ROWSq,COLSq,ZSq);
        sliceLoc0 = interp1(linspace(min(sliceLoc),max(sliceLoc),layers),sliceLoc,linspace(min(sliceLoc),max(sliceLoc),(layers*pxS-pxS)/hpxS));
        pxS = hpxS;
        hpxS = abs(sliceLoc0(2)-sliceLoc0(1));
        row = length(sliceLoc0);
        layers = length(X(1,1,:));   
        sliceLoc = pxS:pxS:layers*pxS;

        thisUID = dicomuid;

        for a = 1:layers
            thisMeta = metadata;
            thisMeta.Width = col;
            thisMeta.Height = row;
            thisMeta.SliceLocation = sliceLoc(a);
            thisMeta.ImagePositionPatient(3) = sliceLoc(a);
            thisMeta.SliceThickness = pxS;
            thisMeta.SliceInterval = pxS;
            thisMeta.SpacingBetweenSlices = pxS;
            thisMeta.PixelSpacing = [hpxS;hpxS];
            thisMeta.SeriesInstanceUID = thisUID;
            padNum = 5-numel(num2str(a));
            pad = [];
            for a2 = 1:padNum
                pad = [pad,'0'];
            end
            dicomwrite(uint16((X(:,:,a)-metadata.RescaleIntercept)/metadata.RescaleSlope),fullfile(selpath3,folder_name,strcat(pad,num2str(a),'.dcm')),thisMeta);
        end

        editDataCancel3
        set(editDataCancelIn3,'Visible','off')

    end

        function [sliceLoc,metadata] = loadDataResize(voxRz)

            % load data

            [X,metadata,sliceLoc] = read_dcm3Resize(fileOpen,voxRz);

            [row,col,layers] = size(X); % size of the image

            % image pixel spacing
            hpxS = metadata.PixelSpacing(1)/(1/round(1/voxRz));

            % vertical pixel spacing (mm)
            sliceDif = median(sliceLoc(2:end)-sliceLoc(1:end-1));
            pxS = abs(sliceDif);
            if max(abs(min(sliceLoc(2:end)-sliceLoc(1:end-1))-sliceDif)) > 0.0001 || ...
                    max(abs(max(sliceLoc(2:end)-sliceLoc(1:end-1))-sliceDif)) > 0.0001
                fprintf('WARNING: UNEVEN DICOM SPACING!')

                % sort X by slice location
                sliceLoc = flipdim(sliceLoc,2);
                [b,idx] = sort(sliceLoc);
                x2 = X(:,:,idx);
                X = x2;

            end

        end

        function [X,metadata,sliceLoc] = read_dcm3Resize(dIn,voxRz)

            % read DCM files from input directory into matrix

            inpath = dIn;

            % make sure the filename ends with a '/'
            if inpath(end) ~= filesep
                inpath = [inpath filesep];
            end

            % directory of subfolders within set path
            folders = dir(inpath);

            layerCount = 0; % keep track of where to write files in matrix

            allSlice = [];

            check1 = 1; % check for whether we have found image size

            % initialize
            X = [];

            remove = [];
            for jj = 1:length(folders)
                if strcmp('.',folders(jj).name)
                    remove = [remove jj];
                end
                if strcmp('..',folders(jj).name)
                    remove = [remove jj];
                end
                if strcmp('.DS_Store',folders(jj).name)
                    remove = [remove jj];
                end
            end
            folders(remove) = [];

            breakCheck = 0;

            for j = 1:length(folders)

                % directory of DICOM files within subfolders
                D = dir([[inpath folders(j).name filesep] '*.dcm']);
                if length(D) < 1
                    D = dir([[inpath folders(j).name filesep] '*.IMA']);
                end
                if length(D) < 1
                    D = dir([[inpath folders(j).name filesep] '*.bmp']);
                end

                % remove the invisible files added by some USB drives:
                remove = [];
                for jj = 1:length(D)
                    if strcmp('._',D(jj).name(1:2))
                        remove = [remove jj];
                    end
                end
                D(remove) = [];

                % check image size
                if length(D) && check1
                    metadata = dicominfo([[inpath folders(j).name filesep] filesep D(1).name]);
                    ro = ceil(double(metadata.Height) * 1/round(1/voxRz));
                    co = ceil(double(metadata.Width) * 1/round(1/voxRz));
                    check1 = 0;
                end

                % we know each image is roXco, initialize here
                checkX = 0;
                try isempty(X);
                    nAvg = round(length(D)/ceil(length(D)*(1/round(1/voxRz))));
                    nLayers = ceil(length(D)*(1/nAvg));
                    X(:,:,end+1:end+nLayers) = 0;
                    sliceLoc(end+1:end+nLayers) = 0;
                    checkX = 1;
                catch
                end
                if checkX == 0 && check1 == 0 & ~isnan(ceil(length(D)*(1/nAvg)))
                    nAvg = round(length(D)/ceil(length(D)*(1/round(1/voxRz))));
                    nLayers = ceil(length(D)*(1/nAvg))-1;
                    X = zeros(ro,co,nLayers,'double');
                    sliceLoc = zeros(1,nLayers);
                end

                skip = 0;

                if isnan(nLayers)
                    nLayers = 0;
                end

                % iterating over each file, read the image and populate the appropriate
                % layer in matrix X
                if nLayers>1
                    for i1 = 1:nLayers

                        skipCheck = 0;

                        % read metadata
                        % if i1 == 1
                        %     metadata = dicominfo([[inpath folders(j).name] filesep D(1).name]);
                        % end

                        metadata = dicominfo([[inpath folders(j).name] filesep D((i1-1)*(nAvg)+1).name]);

                        if isfield(metadata,'SliceLocation') == 1
                            if min(abs(allSlice-metadata.SliceLocation)) == 0
                                skipCheck = 1;
                            end
                        elseif isfield(metadata,'ImagePositionPatient') == 1
                            if min(abs(allSlice-metadata.ImagePositionPatient(3))) == 0
                                skipCheck = 1;
                            end
                        elseif isfield(metadata,'InstanceNumber') == 1
                            if min(abs(allSlice-metadata.InstanceNumber)) == 0
                                skipCheck = 1;
                            end
                        end

                        % read DICOM
                        x = NaN(ro,co,nAvg);
                        for jj = 1:nAvg
                            x(:,:,jj) = imresize(dicomread([[inpath folders(j).name] filesep D((i1-1)*(nAvg)+jj).name]),1/round(1/voxRz));
                        end
                        X(:,:,i1+layerCount-skip) = mean(x,3);
                        
                        if isfield(metadata,'SliceLocation') == 1
                            sliceLoc(i1+layerCount-skip) = metadata.SliceLocation;
                        elseif isfield(metadata,'ImagePositionPatient') == 1
                            sliceLoc(i1+layerCount-skip) = metadata.ImagePositionPatient(3);
                        elseif isfield(metadata,'InstanceNumber') == 1
                            sliceLoc(i1+layerCount-skip) = metadata.InstanceNumber;
                        end

                        % delete DICOM if this is a repeat
                        if skipCheck == 1
                            X(:,:,i1+layerCount-skip) = [];
                            sliceLoc(i1+layerCount-skip) = [];
                        end

                        if isfield(metadata,'SliceLocation') == 1
                            if min(abs(allSlice-metadata.SliceLocation)) == 0
                                skip = skip + 1;
                            end
                            allSlice = [allSlice metadata.SliceLocation];
                        elseif isfield(metadata,'ImagePositionPatient') == 1
                            if min(abs(allSlice-metadata.ImagePositionPatient(3))) == 0
                                skip = skip + 1;
                            end
                            allSlice = [allSlice metadata.ImagePositionPatient(3)];
                        elseif isfield(metadata,'InstanceNumber') == 1
                            if min(abs(allSlice-metadata.InstanceNumber)) == 0
                                skip = skip + 1;
                            end
                            allSlice = [allSlice metadata.InstanceNumber];
                        end
                        progressUpdate(i1/nLayers)
                    end
                end
                if length(X)
                    layerCount = length(X(1,1,:)); % keep track of size of X
                end

                %if p == 1
                    %progressUpdate(i1/layers)
                %end

            end

            % now rescale all the intensity values in the matrix so that the matrix
            % contains the original intensity values rather than the scaled values that
            % dicomread produces
            X = X.*metadata.RescaleSlope + metadata.RescaleIntercept;

        end


    function resizeDicoms(src,event)

        set(UserFig,'Visible','off')
        pause(0.001)
        selpath3 = uigetdir;
        set(UserFig,'Visible','on')

        function editDataCancel2(src,event)
            set(editDataCancelIn,'Visible','on')
            set(editDataCancelIn2,'Visible','off')
            set(convertTifIn,'Visible','on')
            set(resizeDicomsIn,'Visible','on')
            set(rotateDicomsIn,'Visible','on')
            set(cropDicomsIn0,'Visible','on')
            set(htextFactor,'Visible','off')
            set(factorSetIn,'Visible','off')
            set(launchResizeIn,'Visible','off')
        end

        editDataCancelIn2 = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Go back'},'Visible','on',...
            'Position',[715,120,250,60],'Units','normalized','BackgroundColor',[0.78,0.94,0.54],'FontSize',12,'FontName','Arial','Callback',@editDataCancel2);

        set(resizeDicomsIn,'Visible','off')
        set(convertTifIn,'Visible','off')
        set(editDataCancelIn,'Visible','off')
        set(rotateDicomsIn,'Visible','off')
        set(cropDicomsIn0,'Visible','off')

        fileOpen = selpath3;

        folder_name = 'resized';
        mkdir(fullfile(selpath3,folder_name));

        htextFactor = uicontrol(UserFig,'Style','text','String',{'Rescale factor (0-1)';'(i.e. 0.25 reduces image size';'by 4 in each dimension)'},'Position',[725,340,300,80],...
            'BackgroundColor','none','FontSize',11,'FontName','Arial','Units','normalized','Visible','on');

        factorSetIn = uicontrol(UserFig,'Style','Edit','String',num2str(0.5),...
            'Position',[795,325,150,25],'Units','normalized','FontName','Arial');

        launchResizeIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Go!'},'Visible','on',...
            'Position',[1000,240,60,60],'Units','normalized','BackgroundColor',[0.61,0.86,0.57],'ForegroundColor',[0,0,0],'FontSize',14,'FontName','Arial','Callback',@launchResize);

        function launchResize(src,event)
            uiresume(UserFig)
        end

        uiwait(UserFig)

        set(htextFactor,'Visible','off')
        set(factorSetIn,'Visible','off')
        set(launchResizeIn,'Visible','off')

        pause(0.001)

        resizeFactor = str2num(factorSetIn.String);

        ha3 = uiaxes(UserFig,'Units','Pixels','Position',[715,40,250,60],'Units','normalized','Visible','on');
        ha3.InteractionOptions.DatatipsSupported = 'off';
        ha3.InteractionOptions.ZoomSupported = "off";
        ha3.InteractionOptions.PanSupported = "off";
        ha3.Toolbar.Visible = 'off';
        hold(ha3,'on')
        set(ha3,'Xtick',[],'YTick',[],'XLim',[0 1],'YLim',[0 1])
        %processNumber = processNumber + 1;
        titleName = 'loading CT data';
        [sliceLoc,metadata] = loadDataResize(resizeFactor);
        delete(p1)
        delete(ha3)
        ha3 = uiaxes(UserFig,'Units','Pixels','Position',[715,40,250,60],'Units','normalized','Visible','on');
        ha3.InteractionOptions.DatatipsSupported = 'off';
        ha3.InteractionOptions.ZoomSupported = "off";
        ha3.InteractionOptions.PanSupported = "off";
        ha3.Toolbar.Visible = 'off';
        hold(ha3,'on')
        set(ha3,'Xtick',[],'YTick',[],'XLim',[0 1],'YLim',[0 1])

        thisUID = dicomuid;

        %processNumber = processNumber;
        titleName = 'Resizing data';

        for a = 1:layers
            thisMeta = metadata;
            thisMeta.Width = row;
            thisMeta.Height = col;
            thisMeta.SliceLocation = sliceLoc(a);
            thisMeta.ImagePositionPatient(3) = sliceLoc(a);
            thisMeta.SliceThickness = pxS;
            thisMeta.SliceInterval = pxS;
            thisMeta.SpacingBetweenSlices = pxS;
            thisMeta.PixelSpacing = [hpxS;hpxS];
            thisMeta.SeriesInstanceUID = thisUID;
            padNum = 5-numel(num2str(a));
            pad = [];
            for a2 = 1:padNum
                pad = [pad,'0'];
            end
            dicomwrite(uint16((X(:,:,a)-metadata.RescaleIntercept)/metadata.RescaleSlope),fullfile(selpath3,folder_name,strcat(pad,num2str(a),'.dcm')),thisMeta);
            progressUpdate(a/layers)
        end        

        delete(p1)
        delete(ha3)
        %set(ha3,'Visible','off','Units','Pixels','Position',[200,160,500,50],'Units','normalized')
        editDataCancel2
        set(editDataCancelIn2,'Visible','off')

        % function [sliceLoc,metadata] = loadDataResize(voxRz)
        % 
        %     % load data
        % 
        %     [X,metadata,sliceLoc] = read_dcm3Resize(fileOpen,voxRz);
        % 
        %     [row,col,layers] = size(X); % size of the image
        % 
        %     % image pixel spacing
        %     hpxS = metadata.PixelSpacing(1)/(1/round(1/voxRz));
        % 
        %     % vertical pixel spacing (mm)
        %     sliceDif = median(sliceLoc(2:end)-sliceLoc(1:end-1));
        %     pxS = abs(sliceDif);
        %     if max(abs(min(sliceLoc(2:end)-sliceLoc(1:end-1))-sliceDif)) > 0.0001 || ...
        %             max(abs(max(sliceLoc(2:end)-sliceLoc(1:end-1))-sliceDif)) > 0.0001
        %         fprintf('WARNING: UNEVEN DICOM SPACING!')
        % 
        %         % sort X by slice location
        %         sliceLoc = flipdim(sliceLoc,2);
        %         [b,idx] = sort(sliceLoc);
        %         x2 = X(:,:,idx);
        %         X = x2;
        % 
        %     end
        % 
        % end
        % 
        % function [X,metadata,sliceLoc] = read_dcm3Resize(dIn,voxRz)
        % 
        %     % read DCM files from input directory into matrix
        % 
        %     inpath = dIn;
        % 
        %     % make sure the filename ends with a '/'
        %     if inpath(end) ~= filesep
        %         inpath = [inpath filesep];
        %     end
        % 
        %     % directory of subfolders within set path
        %     folders = dir(inpath);
        % 
        %     layerCount = 0; % keep track of where to write files in matrix
        % 
        %     allSlice = [];
        % 
        %     check1 = 1; % check for whether we have found image size
        % 
        %     % initialize
        %     X = [];
        % 
        %     remove = [];
        %     for jj = 1:length(folders)
        %         if strcmp('.',folders(jj).name)
        %             remove = [remove jj];
        %         end
        %         if strcmp('..',folders(jj).name)
        %             remove = [remove jj];
        %         end
        %         if strcmp('.DS_Store',folders(jj).name)
        %             remove = [remove jj];
        %         end
        %     end
        %     folders(remove) = [];
        % 
        %     breakCheck = 0;
        % 
        %     for j = 1:length(folders)
        % 
        %         % directory of DICOM files within subfolders
        %         D = dir([[inpath folders(j).name filesep] '*.dcm']);
        %         if length(D) < 1
        %             D = dir([[inpath folders(j).name filesep] '*.IMA']);
        %         end
        %         if length(D) < 1
        %             D = dir([[inpath folders(j).name filesep] '*.bmp']);
        %         end
        % 
        %         % remove the invisible files added by some USB drives:
        %         remove = [];
        %         for jj = 1:length(D)
        %             if strcmp('._',D(jj).name(1:2))
        %                 remove = [remove jj];
        %             end
        %         end
        %         D(remove) = [];
        % 
        %         % check image size
        %         if length(D) && check1
        %             metadata = dicominfo([[inpath folders(j).name filesep] filesep D(1).name]);
        %             ro = ceil(double(metadata.Height) * 1/round(1/voxRz));
        %             co = ceil(double(metadata.Width) * 1/round(1/voxRz));
        %             check1 = 0;
        %         end
        % 
        %         % we know each image is roXco, initialize here
        %         checkX = 0;
        %         try isempty(X);
        %             nAvg = round(length(D)/ceil(length(D)*(1/round(1/voxRz))));
        %             nLayers = ceil(length(D)*(1/nAvg));
        %             X(:,:,end+1:end+nLayers) = 0;
        %             sliceLoc(end+1:end+nLayers) = 0;
        %             checkX = 1;
        %         catch
        %         end
        %         if checkX == 0 && check1 == 0 & ~isnan(ceil(length(D)*(1/nAvg)))
        %             nAvg = round(length(D)/ceil(length(D)*(1/round(1/voxRz))));
        %             nLayers = ceil(length(D)*(1/nAvg))-1;
        %             X = zeros(ro,co,nLayers,'double');
        %             sliceLoc = zeros(1,nLayers);
        %         end
        % 
        %         skip = 0;
        % 
        %         if isnan(nLayers)
        %             nLayers = 0;
        %         end
        % 
        %         % iterating over each file, read the image and populate the appropriate
        %         % layer in matrix X
        %         if nLayers>1
        %             for i1 = 1:nLayers
        % 
        %                 skipCheck = 0;
        % 
        %                 % read metadata
        %                 % if i1 == 1
        %                 %     metadata = dicominfo([[inpath folders(j).name] filesep D(1).name]);
        %                 % end
        % 
        %                 metadata = dicominfo([[inpath folders(j).name] filesep D((i1-1)*(nAvg)+1).name]);
        % 
        %                 if min(abs(allSlice-metadata.SliceLocation)) == 0
        %                     skipCheck = 1;
        %                 end
        % 
        %                 % read DICOM
        %                 x = NaN(ro,co,nAvg);
        %                 for jj = 1:nAvg
        %                     x(:,:,jj) = imresize(dicomread([[inpath folders(j).name] filesep D((i1-1)*(nAvg)+jj).name]),1/round(1/voxRz));
        %                 end
        %                 X(:,:,i1+layerCount-skip) = mean(x,3);
        %                 sliceLoc(i1+layerCount-skip) = metadata.SliceLocation;
        % 
        %                 % delete DICOM if this is a repeat
        %                 if skipCheck == 1
        %                     X(:,:,i1+layerCount-skip) = [];
        %                     sliceLoc(i1+layerCount-skip) = [];
        %                 end
        % 
        %                 if min(abs(allSlice-metadata.SliceLocation)) == 0
        %                     skip = skip + 1;
        %                 end
        % 
        %                 allSlice = [allSlice metadata.SliceLocation];
        % 
        %             end
        %         end
        %         if length(X)
        %             layerCount = length(X(1,1,:)); % keep track of size of X
        %         end
        % 
        %     end
        % 
        %     % now rescale all the intensity values in the matrix so that the matrix
        %     % contains the original intensity values rather than the scaled values that
        %     % dicomread produces
        %     X = X.*metadata.RescaleSlope + metadata.RescaleIntercept;
        % 
        % end
    end

    function convertTif(src,event)

        set(UserFig,'Visible','off')
        pause(0.001)
        selpath3 = uigetdir;
        set(UserFig,'Visible','on')

        function editDataCancel2(src,event)
            set(editDataCancelIn,'Visible','on')
            set(editDataCancelIn2,'Visible','off')
            set(convertTifIn,'Visible','on')
            set(resizeDicomsIn,'Visible','on')
            set(rotateDicomsIn,'Visible','on')
            set(cropDicomsIn0,'Visible','on')
            set(htextSlope,'Visible','off')
            set(slopeSetIn,'Visible','off')
            set(htextIntercept,'Visible','off')
            set(interceptSetIn,'Visible','off')
            set(htextSlope,'Visible','off')
            set(htextPixelSpace,'Visible','off')
            set(pixelSetIn,'Visible','off')
            set(htextSliceSpace,'Visible','off')
            set(sliceSetIn,'Visible','off')
            set(htextCoreName,'Visible','off')
            set(coreNameSetIn,'Visible','off')
            set(launchTifConversionIn,'Visible','off')
        end

        editDataCancelIn2 = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Go back'},'Visible','on',...
            'Position',[715,120,250,60],'Units','normalized','BackgroundColor',[0.78,0.94,0.54],'FontSize',12,'FontName','Arial','Callback',@editDataCancel2);


        set(resizeDicomsIn,'Visible','off')
        set(convertTifIn,'Visible','off')
        set(editDataCancelIn,'Visible','off')
        set(rotateDicomsIn,'Visible','off')
        set(cropDicomsIn0,'Visible','off')

        d1 = dir(strcat(selpath3,filesep,'*.tif'));

        folder_name = 'dicoms';
        mkdir(fullfile(selpath3,folder_name));

        thisUID = dicomuid;

        htextSlope = uicontrol(UserFig,'Style','text','String',{'Slope to rescale image intensity:'},'Position',[725,610,300,40],...
            'BackgroundColor','none','FontSize',11,'FontName','Arial','Units','normalized','Visible','on');

        slopeSetIn = uicontrol(UserFig,'Style','Edit','String',num2str(0.000015259),...
            'Position',[775,595,150,25],'Units','normalized','FontName','Arial');

        htextIntercept = uicontrol(UserFig,'Style','text','String',{'Intercept to rescale image intensity:'},'Position',[725,525,300,40],...
            'BackgroundColor','none','FontSize',11,'FontName','Arial','Units','normalized','Visible','on');

        interceptSetIn = uicontrol(UserFig,'Style','Edit','String',num2str(0),...
            'Position',[775,510,150,25],'Units','normalized','FontName','Arial');

        htextPixelSpace = uicontrol(UserFig,'Style','text','String',{'Pixel spacing (mm):'},'Position',[725,440,300,40],...
            'BackgroundColor','none','FontSize',11,'FontName','Arial','Units','normalized','Visible','on');

        pixelSetIn = uicontrol(UserFig,'Style','Edit','String',num2str(0.0762),...
            'Position',[775,425,150,25],'Units','normalized','FontName','Arial');

        htextSliceSpace = uicontrol(UserFig,'Style','text','String',{'Slice interval (mm):'},'Position',[725,355,300,40],...
            'BackgroundColor','none','FontSize',11,'FontName','Arial','Units','normalized','Visible','on');

        sliceSetIn = uicontrol(UserFig,'Style','Edit','String',num2str(0.0762),...
            'Position',[775,340,150,25],'Units','normalized','FontName','Arial');

        htextCoreName = uicontrol(UserFig,'Style','text','String',{'Core name:'},'Position',[725,270,300,40],...
            'BackgroundColor','none','FontSize',11,'FontName','Arial','Units','normalized','Visible','on');

        coreNameSetIn = uicontrol(UserFig,'Style','Edit',...
            'Position',[775,255,150,25],'Units','normalized','FontName','Arial');

        launchTifConversionIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Go!'},'Visible','on',...
            'Position',[1000,240,60,60],'Units','normalized','BackgroundColor',[0.61,0.86,0.57],'ForegroundColor',[0,0,0],'FontSize',14,'FontName','Arial','Callback',@launchTifConversion);

        function launchTifConversion(src,event)
            uiresume(UserFig)
        end

        uiwait(UserFig)

        set(htextSlope,'Visible','off')
        set(slopeSetIn,'Visible','off')
        set(htextIntercept,'Visible','off')
        set(interceptSetIn,'Visible','off')
        set(htextPixelSpace,'Visible','off')
        set(pixelSetIn,'Visible','off')
        set(htextSliceSpace,'Visible','off')
        set(sliceSetIn,'Visible','off')
        set(htextCoreName,'Visible','off')
        set(coreNameSetIn,'Visible','off')
        set(launchTifConversionIn,'Visible','off')

        pause(0.001)

        slope = str2num(slopeSetIn.String);
        intercept = str2num(interceptSetIn.String);
        width = str2num(pixelSetIn.String); % mm
        spacing = str2num(sliceSetIn.String); % mm

        ha3 = uiaxes(UserFig,'Units','Pixels','Position',[715,40,250,60],'Units','normalized','Visible','on');
        ha3.InteractionOptions.DatatipsSupported = 'off';
        ha3.InteractionOptions.ZoomSupported = "off";
        ha3.InteractionOptions.PanSupported = "off";
        ha3.Toolbar.Visible = 'off';
        hold(ha3,'on')
        set(ha3,'Xtick',[],'YTick',[],'XLim',[0 1],'YLim',[0 1])
        %processNumber = processNumber + 1;
        titleName = 'Converting Tiffs';

        for i = 1:length(d1)

            info = imfinfo(fullfile(selpath3,d1(i).name));

            currentImage = double(imread(fullfile(selpath3,d1(i).name), 'Info', info));

            % Required basic metadata
            thisMeta.Filename = coreNameSetIn.String;
            thisMeta.FileModDate = info.FileModDate;
            thisMeta.Format = 'DICOM';
            thisMeta.StudyDate = strcat(char(datetime('today'),'yyyy'),char(datetime('today'),'mm'),char(datetime('today'),'dd'));
            thisMeta.StudyTime = '12:12:12';
            thisMeta.StudyID = '1';
            thisMeta.SeriesNumber = 1;
            thisMeta.Accession = '0';
            thisMeta.PatientName = coreNameSetIn.String;
            thisMeta.ReferringPhysicianName = '';
            thisMeta.PatientBirthDate = '';
            thisMeta.PatientSex = '';
            thisMeta.PatientPosition = '';
            thisMeta.RescaleIntercept = -1000+intercept*4000;
            thisMeta.RescaleSlope = slope*4000;
            thisMeta.ColorType = 'grayscale';
            thisMeta.Modality = 'CT';
            thisMeta.ManufacturerModelName = '';
            thisMeta.DistanceSourceToDetector = 1;
            thisMeta.DistanceSourceToPatient = 1;
            thisMeta.ExposureTime = 1;
            thisMeta.BitsStored = 16;
            thisMeta.HighBit = 15;
            thisMeta.LargestImagePixelValue = max(max(max(currentImage)));


            thisMeta.Width = info.Width;
            thisMeta.Height = info.Height;
            thisMeta.PatientID = folder_name;
            thisMeta.SliceLocation = i*spacing;
            thisMeta.InstanceNumber = i;
            thisMeta.ImagePositionPatient(3) = i*spacing;
            thisMeta.SliceThickness = spacing;
            thisMeta.SpacingBetweenSlices = spacing;
            thisMeta.PixelSpacing = [width;width];
            thisMeta.SeriesInstanceUID = thisUID;
            padNum = 5-numel(num2str(i));
            pad = [];
            for a2 = 1:padNum
                pad = [pad,'0'];
            end
            dicomwrite(uint16(currentImage),fullfile(selpath3,folder_name,strcat(pad,num2str(i),'.dcm')),thisMeta);

            progressUpdate(i/length(d1))

        end

        delete(p1)
        delete(ha3)

        editDataCancel2
        set(editDataCancelIn2,'Visible','off')

    end


% Function for submitting CT data folder
    function sendDataFolder(src,event)

        set(UserFig,'Visible','off')
        set(sendDataIn,'Visible','off')
        set(editDataIn,'Visible','off')
        set(sendDataFileIn,'Visible','off')
        set(sendXrayIn,'Visible','off')
        set(getMetaDataIn,'Visible','off')
        set(sendMetaDataIn,'Visible','off')
        set(sendVideoIn,'Visible','off')
        set(mainMenuIn,'Visible','off')
        set(lblThanksCT,'Visible','off')
        set(lblThanksMeta,'Visible','off')
        set(lblOverwrite,'Visible','off')
        set(lblUploadError,'Visible','off')
        set(lblUploadError2,'Visible','off')
        set(directSubmit0In,'Visible','off')
        pause(0.001)

        selpath3 = uigetdir;
        set(UserFig,'Visible','on')
        file2send0 = strsplit(selpath3,filesep);
        file2send = file2send0{length(file2send0)};

        set(lblGracious,'String',{'CoralCache depends on your data!';'Thank you for sharing your data to help this community effort.'})

        lblSending = uicontrol(UserFig,'Style','text','String','Sending data...','Position',[720,80,250,40],...
            'BackgroundColor','none','FontSize',12,'FontName','Arial','Units','normalized');

        pause(0.001)

        try checkcon = dir(cache1);
            cd(cache1,'submitted_data')
        catch
            try
                cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
            catch
                try
                    connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                    connectionEstablished = 0;
                    for ij = 1:length(connectTimes)
                        if connectionEstablished == 0
                            if connectTimes(ij) == 1
                                waitText = [' ',num2str(connectTimes(ij)),' minute.']
                            else
                                waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                            end
                            set(lblSending,'Units','Pixels','Visible','on',...
                                'String',{'Error connecting to server.';strcat('Trying again in',waitText)})
                            pause(connectTimes(ij)*60)
                            try
                                cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                connectionEstablished = 1;
                                set(lblSending,'String','Sending data...')
                            catch
                            end
                        end
                    end
                    if connectionEstablished == 0
                        zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                    end
                catch
                    set(lblSending,'Visible','on',...
                        'String',{'Error connecting to server. (code 031)';'Please try again later.'})
                    while 1==1
                        pause
                    end
                end
            end
            cd(cache1,'CoralCache')
            cd(cache1,'submitted_data')
        end

        %cd(cache1,'submitted_data')
        thisDir = dir(cache1);
        noDuplicate = 1;
        for iii = 1:length(thisDir)
            if strcmp(thisDir(iii).name,file2send)
                set(lblOverwrite,'Visible','on')
                noDuplicate = 0;
            end
        end

        try
            submission_code = round(rand([1,4])*10);
            submission_text = strcat([num2str(submission_code(1)),num2str(submission_code(2)),num2str(submission_code(3)),num2str(submission_code(4))]);
            C = [{UserSetIn.String}, {datetime('now')}, {file2send}];
            fid8 = fopen(fullfile(refPath,strcat('new_submission_attempt_',submission_text,'.csv')));
            writecell(C,fullfile(refPath,strcat('new_submission_attempt_',submission_text,'.csv')));
            pause(2)
            mput(cache1,fullfile(refPath,strcat('new_submission_attempt_',submission_text,'.csv')));
            try fclose(fid8);
            catch
            end
            delete(fullfile(refPath,strcat('new_submission_attempt_',submission_text,'.csv')));
        catch
        end

        thisWorked = 0;
        if noDuplicate == 1
            try mput(cache1,selpath3);
                thisWorked = 1;
                set(lblThanksCT,'Visible','on','String','Thank you for sending your data!')
            catch
                set(lblUploadError,'Visible','on')
            end
        end

        set(sendDataIn,'Visible','on')
        set(editDataIn,'Visible','on')
        set(sendDataFileIn,'Visible','on')
        set(sendXrayIn,'Visible','on')
        set(getMetaDataIn,'Visible','on')
        set(sendMetaDataIn,'Visible','on')
        set(sendVideoIn,'Visible','on')
        set(mainMenuIn,'Visible','on')
        set(lblSending,'Visible','off')

        close(cache1)
        cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
        cd(cache1,'CoralCache')
        %if thisWorked == 1
            try
                try mget(cache1,'submission_log.csv',strcat(refPath));
                catch
                    try mget(cache1,'submission_log.csv',strcat(refPath));
                    catch
                    end
                end
                fid6 = fopen(fullfile(refPath,'submission_log.csv'));
                submitLog = textscan(fid6,'%s %s %s','Delimiter',',');
                try fclose(fid6);
                catch
                end
                n_submit_log = length(submitLog{1});
                submit_log_users = submitLog{1};
                submit_log_dates = submitLog{2};
                submit_log_cores = submitLog{3};
                submit_log_users{n_submit_log+1} = UserSetIn.String;
                if thisWorked == 1
                    submit_log_dates{n_submit_log+1} = datetime('now');
                else
                    submit_log_dates{n_submit_log+1} = 'unsuccessful';
                end
                submit_log_cores{n_submit_log+1} = file2send;
                C = [submit_log_users, submit_log_dates, submit_log_cores];
                fid7 = fopen(fullfile(refPath,'submission_log.csv'));
                writecell(C,fullfile(refPath,'submission_log.csv'));
                pause(2)
                mput(cache1,fullfile(refPath,'submission_log.csv'));
                try fclose(fid7);
                catch
                end
                delete(fullfile(refPath,'submission_log.csv'));
            catch
            end
        %end
    end

% Function for submitting CT data file
    function sendDataFile(src,event)

        set(UserFig,'Visible','off')
        set(sendDataIn,'Visible','off')
        set(editDataIn,'Visible','off')
        set(sendDataFileIn,'Visible','off')
        set(sendXrayIn,'Visible','off')
        set(getMetaDataIn,'Visible','off')
        set(sendMetaDataIn,'Visible','off')
        set(sendVideoIn,'Visible','off')
        set(mainMenuIn,'Visible','off')
        set(lblThanksCT,'Visible','off')
        set(lblThanksMeta,'Visible','off')
        set(lblOverwrite,'Visible','off')
        set(lblUploadError,'Visible','off')
        set(lblUploadError2,'Visible','off')
        %set(directSubmit0In,'Visible','on')
        pause(0.001)

        [file2send,selpath3] = uigetfile('.zip');
        set(UserFig,'Visible','on')

        set(lblGracious,'String',{'CoralCache depends on your data!';'Thank you for sharing your data to help this community effort.'})

        lblSending = uicontrol(UserFig,'Style','text','String','Sending data...','Position',[720,80,250,40],...
            'BackgroundColor','none','FontSize',10,'FontName','Arial','Units','normalized');

        pause(0.001)

        try checkcon = dir(cache1);
            cd(cache1,'submitted_data')
        catch
            try
                cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
            catch
                try
                    connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                    connectionEstablished = 0;
                    for ij = 1:length(connectTimes)
                        if connectionEstablished == 0
                            if connectTimes(ij) == 1
                                waitText = [' ',num2str(connectTimes(ij)),' minute.']
                            else
                                waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                            end
                            set(lblSending,'Units','Pixels','Visible','on',...
                                'String',{'Error connecting to server.';strcat('Trying again in',waitText)})
                            pause(connectTimes(ij)*60)
                            try
                                cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                connectionEstablished = 1;
                                set(lblSending,'String','Sending data...')
                            catch
                            end
                        end
                    end
                    if connectionEstablished == 0
                        zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                    end
                catch
                    set(lblSending,'Visible','on',...
                        'String',{'Error connecting to server. (code 031)';'Please try again later.'})
                    while 1==1
                        pause
                    end
                end
            end
            cd(cache1,'CoralCache')
            cd(cache1,'submitted_data')
        end

        %cd(cache1,'submitted_data')
        thisDir = dir(cache1);
        noDuplicate = 1;
        for iii = 1:length(thisDir)
            if strcmp(thisDir(iii).name,file2send)
                set(lblOverwrite,'Visible','on')
                noDuplicate = 0;
            end
        end

        try
            submission_code = round(rand([1,4])*10);
            submission_text = strcat([num2str(submission_code(1)),num2str(submission_code(2)),num2str(submission_code(3)),num2str(submission_code(4))]);
            C = [{UserSetIn.String}, {datetime('now')}, {file2send}];
            fid8 = fopen(fullfile(refPath,strcat('new_submission_attempt_',submission_text,'.csv')));
            writecell(C,fullfile(refPath,strcat('new_submission_attempt_',submission_text,'.csv')));
            pause(2)
            mput(cache1,fullfile(refPath,strcat('new_submission_attempt_',submission_text,'.csv')));
            try fclose(fid8);
            catch
            end
            delete(fullfile(refPath,strcat('new_submission_attempt_',submission_text,'.csv')));
        catch
        end

        thisWorked = 0;
        if noDuplicate == 1
            try mput(cache1,fullfile(selpath3,file2send));
                thisWorked = 1;
                set(lblThanksCT,'Visible','on','String','Thank you for sending your CT data!')
            catch
                set(lblUploadError2,'Visible','on')
            end
        end

        set(sendDataIn,'Visible','on')
        set(editDataIn,'Visible','on')
        set(sendDataFileIn,'Visible','on')
        set(sendXrayIn,'Visible','on')
        set(getMetaDataIn,'Visible','on')
        set(sendMetaDataIn,'Visible','on')
        %set(directSubmit0In,'Visible','on')
        set(sendVideoIn,'Visible','on')
        set(mainMenuIn,'Visible','on')
        set(lblSending,'Visible','off')

        close(cache1)
        cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
        cd(cache1,'CoralCache')

        %if thisWorked == 1
            try
                try mget(cache1,'submission_log.csv',strcat(refPath));
                catch
                    try mget(cache1,'submission_log.csv',strcat(refPath));
                    catch
                    end
                end
                fid6 = fopen(fullfile(refPath,'submission_log.csv'));
                submitLog = textscan(fid6,'%s %s %s','Delimiter',',');
                try fclose(fid6);
                catch
                end
                n_submit_log = length(submitLog{1});
                submit_log_users = submitLog{1};
                submit_log_dates = submitLog{2};
                submit_log_cores = submitLog{3};
                submit_log_users{n_submit_log+1} = UserSetIn.String;
                if thisWorked == 1
                    submit_log_dates{n_submit_log+1} = datetime('now');
                else
                    submit_log_dates{n_submit_log+1} = 'unsuccessful';
                end
                submit_log_cores{n_submit_log+1} = file2send;
                C = [submit_log_users, submit_log_dates, submit_log_cores];
                fid7 = fopen(fullfile(refPath,'submission_log.csv'));
                writecell(C,fullfile(refPath,'submission_log.csv'));
                pause(2)
                mput(cache1,fullfile(refPath,'submission_log.csv'));
                try fclose(fid7);
                catch
                end
                delete(fullfile(refPath,'submission_log.csv'));
            catch
            end
        %end

    end


% Function for submitting CT data file
    function sendMetaDataFile(src,event)

        set(UserFig,'Visible','off')
        set(sendDataIn,'Visible','off')
        set(editDataIn,'Visible','off')
        set(sendDataFileIn,'Visible','off')
        set(sendXrayIn,'Visible','off')
        set(getMetaDataIn,'Visible','off')
        set(sendMetaDataIn,'Visible','off')
        set(sendVideoIn,'Visible','off')
        set(mainMenuIn,'Visible','off')
        set(lblThanksCT,'Visible','off')
        set(lblThanksMeta,'Visible','off')
        set(lblOverwrite,'Visible','off')
        set(lblUploadError,'Visible','off')
        set(lblUploadError2,'Visible','off')
        set(directSubmit0In,'Visible','off')
        
        pause(0.001)

        [file2send,selpath3] = uigetfile({'*.xlsx;*.csv;*.txt;*.xls'},'File Selector');
        set(UserFig,'Visible','on')

        set(lblGracious,'String',{'CoralCache depends on your data!';'Thank you for sharing your data to help this community effort.'})

        lblSending = uicontrol(UserFig,'Style','text','String','Sending data...','Position',[200,80,500,40],...
            'BackgroundColor','none','FontSize',10,'FontName','Arial','Units','normalized');

        try checkcon = dir(cache1);
            cd(cache1,'submitted_data')
        catch
            try
                cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
            catch
                try
                    connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                    connectionEstablished = 0;
                    for ij = 1:length(connectTimes)
                        if connectionEstablished == 0
                            if connectTimes(ij) == 1
                                waitText = [' ',num2str(connectTimes(ij)),' minute.']
                            else
                                waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                            end
                            set(lblSending,'Units','Pixels','Visible','on',...
                                'String',{'Error connecting to server.';strcat('Trying again in',waitText)})
                            pause(connectTimes(ij)*60)
                            try
                                cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                connectionEstablished = 1;
                                set(lblSending,'String','Sending data...')
                            catch
                            end
                        end
                    end
                    if connectionEstablished == 0
                        zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                    end
                catch
                    set(lblSending,'Visible','on',...
                        'String',{'Error connecting to server. (code 031)';'Please try again later.'})
                    while 1==1
                        pause
                    end
                end
            end
            cd(cache1,'CoralCache')
            cd(cache1,'submitted_data')
        end

        %cd(cache1,'submitted_data')
        thisDir = dir(cache1);
        noDuplicate = 1;
        for iii = 1:length(thisDir)
            if strcmp(thisDir(iii).name,file2send)
                set(lblOverwrite,'Visible','on')
                noDuplicate = 0;
            end
        end

        try
            submission_code = round(rand([1,4])*10);
            submission_text = strcat([num2str(submission_code(1)),num2str(submission_code(2)),num2str(submission_code(3)),num2str(submission_code(4))]);
            C = [{UserSetIn.String}, {datetime('now')}, {file2send}];
            fid8 = fopen(fullfile(refPath,strcat('new_submission_attempt_',submission_text,'.csv')));
            writecell(C,fullfile(refPath,strcat('new_submission_attempt_',submission_text,'.csv')));
            pause(2)
            mput(cache1,fullfile(refPath,strcat('new_submission_attempt_',submission_text,'.csv')));
            try fclose(fid8);
            catch
            end
            delete(fullfile(refPath,strcat('new_submission_attempt_',submission_text,'.csv')));
        catch
        end

        thisWorked = 0;
        if noDuplicate == 1
            try mput(cache1,fullfile(selpath3,file2send));
                thisWorked = 1;
                set(lblThanksCT,'Visible','on','String','Thank you for sending your metadata!')
            catch
                set(lblUploadError2,'Visible','on')
            end
        end

        set(sendDataIn,'Visible','on')
        set(editDataIn,'Visible','on')
        set(sendDataFileIn,'Visible','on')
        set(sendXrayIn,'Visible','on')
        set(getMetaDataIn,'Visible','on')
        set(sendMetaDataIn,'Visible','on')
        set(sendVideoIn,'Visible','on')
        set(mainMenuIn,'Visible','on')
        set(lblSending,'Visible','off')
        %set(directSubmit0In,'Visible','on')

        close(cache1)
        cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
        cd(cache1,'CoralCache');
        %if thisWorked == 1
            try
                try mget(cache1,'submission_log.csv',strcat(refPath));
                catch
                    try mget(cache1,'submission_log.csv',strcat(refPath));
                    catch
                    end
                end
                fid6 = fopen(fullfile(refPath,'submission_log.csv'));
                submitLog = textscan(fid6,'%s %s %s','Delimiter',',');
                try fclose(fid6);
                catch
                end
                n_submit_log = length(submitLog{1});
                submit_log_users = submitLog{1};
                submit_log_dates = submitLog{2};
                submit_log_cores = submitLog{3};
                submit_log_users{n_submit_log+1} = UserSetIn.String;
                if thisWorked == 1
                    submit_log_dates{n_submit_log+1} = datetime('now');
                else
                    submit_log_dates{n_submit_log+1} = 'unsuccessful';
                end
                submit_log_cores{n_submit_log+1} = file2send;
                C = [submit_log_users, submit_log_dates, submit_log_cores];
                fid7 = fopen(fullfile(refPath,'submission_log.csv'));
                writecell(C,fullfile(refPath,'submission_log.csv'));
                pause(2)
                mput(cache1,fullfile(refPath,'submission_log.csv'));
                try fclose(fid7);
                catch
                end
                delete(fullfile(refPath,'submission_log.csv'));
            catch
            end
        %end

    end

    function sendXrayFile(src,event)

        set(UserFig,'Visible','off')
        set(sendDataIn,'Visible','off')
        set(editDataIn,'Visible','off')
        set(sendDataFileIn,'Visible','off')
        set(sendXrayIn,'Visible','off')
        set(getMetaDataIn,'Visible','off')
        set(sendMetaDataIn,'Visible','off')
        set(sendVideoIn,'Visible','off')
        set(mainMenuIn,'Visible','off')
        set(lblThanksCT,'Visible','off')
        set(lblThanksMeta,'Visible','off')
        set(lblOverwrite,'Visible','off')
        set(lblUploadError,'Visible','off')
        set(lblUploadError2,'Visible','off')
        set(directSubmit0In,'Visible','off')
        pause(0.001)

        [file2send,selpath3] = uigetfile({'*.tiff;*.tif;*.png;*.jpg'},'File Selector');
        set(UserFig,'Visible','on')

        set(lblGracious,'String',{'CoralCache depends on your data!';'Thank you for sharing your data to help this community effort.'})

        lblSending = uicontrol(UserFig,'Style','text','String','Sending data...','Position',[200,80,500,40],...
            'BackgroundColor','none','FontSize',10,'FontName','Arial','Units','normalized');

        try checkcon = dir(cache1);
            cd(cache1,'submitted_data')
        catch
            try
                cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
            catch
                try
                    connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                    connectionEstablished = 0;
                    for ij = 1:length(connectTimes)
                        if connectionEstablished == 0
                            if connectTimes(ij) == 1
                                waitText = [' ',num2str(connectTimes(ij)),' minute.']
                            else
                                waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                            end
                            set(lblSending,'Units','Pixels','Visible','on',...
                                'String',{'Error connecting to server.';strcat('Trying again in',waitText)})
                            pause(connectTimes(ij)*60)
                            try
                                cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                connectionEstablished = 1;
                                set(lblSending,'String','Sending data...')
                            catch
                            end
                        end
                    end
                    if connectionEstablished == 0
                        zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                    end
                catch
                    set(lblSending,'Visible','on',...
                        'String',{'Error connecting to server. (code 031)';'Please try again later.'})
                    while 1==1
                        pause
                    end
                end
            end
            cd(cache1,'CoralCache')
            cd(cache1,'submitted_data')
        end

        %cd(cache1,'submitted_data')
        thisDir = dir(cache1);
        noDuplicate = 1;
        for iii = 1:length(thisDir)
            if strcmp(thisDir(iii).name,file2send)
                set(lblOverwrite,'Visible','on')
                noDuplicate = 0;
            end
        end

        try
            submission_code = round(rand([1,4])*10);
            submission_text = strcat([num2str(submission_code(1)),num2str(submission_code(2)),num2str(submission_code(3)),num2str(submission_code(4))]);
            C = [{UserSetIn.String}, {datetime('now')}, {file2send}];
            fid8 = fopen(fullfile(refPath,strcat('new_submission_attempt_',submission_text,'.csv')));
            writecell(C,fullfile(refPath,strcat('new_submission_attempt_',submission_text,'.csv')));
            pause(2)
            mput(cache1,fullfile(refPath,strcat('new_submission_attempt_',submission_text,'.csv')));
            try fclose(fid8);
            catch
            end
            delete(fullfile(refPath,strcat('new_submission_attempt_',submission_text,'.csv')));
        catch
        end

        thisWorked = 0;
        if noDuplicate == 1
            try mput(cache1,fullfile(selpath3,file2send));
                thisWorked = 1;
                set(lblThanksCT,'Visible','on','String','Thank you for sending your X-ray data!')
            catch
                set(lblUploadError2,'Visible','on')
            end
        end

        set(sendDataIn,'Visible','on')
        set(editDataIn,'Visible','on')
        set(sendDataFileIn,'Visible','on')
        set(sendXrayIn,'Visible','on')
        set(getMetaDataIn,'Visible','on')
        set(sendMetaDataIn,'Visible','on')
        set(sendVideoIn,'Visible','on')
        set(mainMenuIn,'Visible','on')
        set(lblSending,'Visible','off')
        %set(directSubmit0In,'Visible','on')

        close(cache1)
        cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
        cd(cache1,'CoralCache');
        %if thisWorked == 1
            try
                try mget(cache1,'submission_log.csv',strcat(refPath));
                catch
                    try mget(cache1,'submission_log.csv',strcat(refPath));
                    catch
                    end
                end
                fid6 = fopen(fullfile(refPath,'submission_log.csv'));
                submitLog = textscan(fid6,'%s %s %s','Delimiter',',');
                try fclose(fid6);
                catch
                end
                n_submit_log = length(submitLog{1});
                submit_log_users = submitLog{1};
                submit_log_dates = submitLog{2};
                submit_log_cores = submitLog{3};
                submit_log_users{n_submit_log+1} = UserSetIn.String;
                if thisWorked == 1
                    submit_log_dates{n_submit_log+1} = datetime('now');
                else
                    submit_log_dates{n_submit_log+1} = 'unsuccessful';
                end
                submit_log_cores{n_submit_log+1} = file2send;
                C = [submit_log_users, submit_log_dates, submit_log_cores];
                fid7 = fopen(fullfile(refPath,'submission_log.csv'));
                writecell(C,fullfile(refPath,'submission_log.csv'));
                pause(2)
                mput(cache1,fullfile(refPath,'submission_log.csv'));
                try fclose(fid7);
                catch
                end
                delete(fullfile(refPath,'submission_log.csv'));
            catch
            end
        %end

    end

    function getMetaDataTemplate(src,event)

        try checkcon = dir(cache1);
        catch
            try
                cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
            catch
                try
                    connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                    connectionEstablished = 0;
                    for ij = 1:length(connectTimes)
                        if connectionEstablished == 0
                            if connectTimes(ij) == 1
                                waitText = [' ',num2str(connectTimes(ij)),' minute.']
                            else
                                waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                            end
                            set(lblThanksCT,'Units','Pixels','Visible','on',...
                                'String',{'Error connecting to server.';strcat('Trying again in',waitText)})
                            pause(connectTimes(ij)*60)
                            try
                                cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                connectionEstablished = 1;
                                set(lblThanksCT,'String','Downloading...')
                            catch
                            end
                        end
                    end
                    if connectionEstablished == 0
                        zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                    end
                catch
                    set(lblThanksCT,'Visible','on',...
                        'String',{'Error connecting to server. (code 032)';'Please try again later.'})
                    while 1==1
                        pause
                    end
                end
            end
            cd(cache1,'CoralCache')
        end

        try
            if strcmp('MACI64',computer)
                dlDir = fullfile('/Users',char(java.lang.System.getProperty('user.name')), 'Downloads');
                mget(cache1,'metadata_template.xlsx',dlDir)
            else
                dlDir = fullfile(getenv('USERPROFILE'), 'Downloads');
                mget(cache1,'metadata_template.xlsx',dlDir)
            end
            set(lblThanksCT,'Visible','on','String','Check your downloads folder.')
        catch
            set(lblThanksCT,'Visible','on','String',{'Download unsuccessful.';'Go to www.coralct.org'})
        end

    end

    function textOut = videoLabel(vid_num)
        if vid_num == 1
            textOut = 'Video: Core CS28 in the Coral Sea: Tom DeCarlo and Sanna Persson';
        elseif vid_num == 2
            textOut = 'Video: Core CS14 in the Coral Sea: Tom DeCarlo and Sanna Persson';
        elseif vid_num == 3
            textOut = 'Video: Core CS04 in the Coral Sea: Tom DeCarlo and Sanna Persson';
        elseif vid_num == 4
            textOut = 'Video: Core CS28 in the Coral Sea: Tom DeCarlo and Sanna Persson';
        end
    end

% Function for submitting CT data file
    function sendVideoFile(src,event)

        set(UserFig,'Visible','off')
        set(sendDataIn,'Visible','off')
        set(editDataIn,'Visible','off')
        set(sendDataFileIn,'Visible','off')
        set(sendXrayIn,'Visible','off')
        set(getMetaDataIn,'Visible','off')
        set(sendMetaDataIn,'Visible','off')
        set(sendVideoIn,'Visible','off')
        set(mainMenuIn,'Visible','off')
        set(lblThanksCT,'Visible','off')
        set(lblThanksMeta,'Visible','off')
        set(lblOverwrite,'Visible','off')
        set(lblUploadError,'Visible','off')
        set(lblUploadError2,'Visible','off')
        set(directSubmit0In,'Visible','off')
        pause(0.001)

        [file2send,selpath3] = uigetfile({'*.avi;*.mov;*.mp4;*.ogg;*.oga'},'File Selector');
        set(UserFig,'Visible','on')

        set(lblGracious,'String',{'CoralCache depends on your data!';'Thank you for sharing your data to help this community effort.'})

        lblSending = uicontrol(UserFig,'Style','text','String','Sending data...','Position',[720,80,250,40],...
            'BackgroundColor','none','FontSize',10,'FontName','Arial','Units','normalized');

        pause(0.001)

        try checkcon = dir(cache1);
            cd(cache1,'submitted_data')
        catch
            try
                cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
            catch
                try
                    connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                    connectionEstablished = 0;
                    for ij = 1:length(connectTimes)
                        if connectionEstablished == 0
                            if connectTimes(ij) == 1
                                waitText = [' ',num2str(connectTimes(ij)),' minute.']
                            else
                                waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                            end
                            set(lblSending,'Units','Pixels','Visible','on',...
                                'String',{'Error connecting to server.';strcat('Trying again in',waitText)})
                            pause(connectTimes(ij)*60)
                            try
                                cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                connectionEstablished = 1;
                                set(lblSending,'String','Sending data...')
                            catch
                            end
                        end
                    end
                    if connectionEstablished == 0
                        zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                    end
                catch
                    set(lblSending,'Visible','on',...
                        'String',{'Error connecting to server. (code 031)';'Please try again later.'})
                    while 1==1
                        pause
                    end
                end
            end
            cd(cache1,'CoralCache')
            cd(cache1,'submitted_data')
        end

        %cd(cache1,'submitted_data')
        thisDir = dir(cache1);
        noDuplicate = 1;
        for iii = 1:length(thisDir)
            if strcmp(thisDir(iii).name,file2send)
                set(lblOverwrite,'Visible','on')
                noDuplicate = 0;
            end
        end

        thisWorked = 0;
        if noDuplicate == 1
            try mput(cache1,fullfile(selpath3,file2send));
                thisWorked = 1;
                set(lblThanksCT,'Visible','on','String','Thank you for sending your video!')
            catch
                set(lblUploadError2,'Visible','on')
            end
        end

        set(sendDataIn,'Visible','on')
        set(editDataIn,'Visible','on')
        set(sendDataFileIn,'Visible','on')
        set(sendXrayIn,'Visible','on')
        set(getMetaDataIn,'Visible','on')
        set(sendMetaDataIn,'Visible','on')
        set(sendVideoIn,'Visible','on')
        set(mainMenuIn,'Visible','on')
        %set(directSubmit0In,'Visible','on')
        set(lblSending,'Visible','off')

        close(cache1)
        cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
        cd(cache1,'CoralCache')

        if thisWorked == 1
            try
                try mget(cache1,'submission_log.csv',strcat(refPath));
                catch
                    try mget(cache1,'submission_log.csv',strcat(refPath));
                    catch
                    end
                end
                fid6 = fopen(fullfile(refPath,'submission_log.csv'));
                submitLog = textscan(fid6,'%s %s %s','Delimiter',',');
                try fclose(fid6);
                catch
                end
                n_submit_log = length(submitLog{1});
                submit_log_users = submitLog{1};
                submit_log_dates = submitLog{2};
                submit_log_cores = submitLog{3};
                submit_log_users{n_submit_log+1} = UserSetIn.String;
                submit_log_dates{n_submit_log+1} = datetime('now');
                submit_log_cores{n_submit_log+1} = file2send;
                C = [submit_log_users, submit_log_dates, submit_log_cores];
                fid7 = fopen(fullfile(refPath,'submission_log.csv'));
                writecell(C,fullfile(refPath,'submission_log.csv'));
                pause(2)
                mput(cache1,fullfile(refPath,'submission_log.csv'));
                try fclose(fid7);
                catch
                end
                delete(fullfile(refPath,'submission_log.csv'));
            catch
            end
        end

    end


% Create worldmap to view cores
h_map1 = uiaxes(UserFig,'Units','Pixels','Position',[100 395 450 275],'Color','none','Visible','off','Units','normalized');
h_map1.InteractionOptions.DatatipsSupported = 'off';
h_map1.InteractionOptions.ZoomSupported = "off";
h_map1.InteractionOptions.PanSupported = "off";
h_map1.Toolbar.Visible = 'off';
figtemp1 = figure('Visible','off','Units','pixels');
figtemp2 = figure('Visible','off','Units','pixels');
pRegionMap = [];
pSubRegionMap = [];
coralName = [];
latestMap1 = 'World';
latestMap2 = [];
pCore = []; % handle for selected core plot
pRegion = []; % handle for regional inset box
regionBoxExists = 0; % toggle for whether we have an inset box plotted
choosingCore = 0; % toggle for whether we are just changing core or updating maps

% Create map to show chosen zoomed-in areas
h_map2 = uiaxes(UserFig,'Units','Pixels','Position',[100 75 450 275],'Visible','off','Color','none','Units','normalized');
h_map2.InteractionOptions.DatatipsSupported = 'off';
h_map2.InteractionOptions.ZoomSupported = "off";
h_map2.InteractionOptions.PanSupported = "off";
h_map2.Toolbar.Visible = 'off';

lblMapClick = [];
    function updateMap
        set(h_preview,'Visible','off') % turn off the preview axes since it will cover the maps
        set(h_map_cover,'Visible','off') % turn off the preview axes since it will cover the maps
        if preview_exists == 1
            delete(p_preview);
            preview_exists = 0;
        end

        % create a box that hides plots, while they are loading
        if choosingCore == 0
            h_map3 = uiaxes(UserFig,'Units','Pixels','Position',[70 40 500 640],'Color',themeColor2,'Units','normalized');
            patch(h_map3,[0,1],[0,1],themeColor2,'EdgeColor','none')
            set(h_map3,'Xlim',[0,1],'YLim',[0,1],'XTick',[],'YTick',[],'xcolor',themeColor2,'ycolor',themeColor2)
            h_map3.InteractionOptions.DatatipsSupported = 'off';
            h_map3.InteractionOptions.ZoomSupported = "off";
            h_map3.InteractionOptions.PanSupported = "off";
            h_map3.Toolbar.Visible = 'off';

            lblMapClick = uicontrol(UserFig,'Style','text','String','Map loading...',...
                'Position',[100, 350, 200, 100],'BackgroundColor',themeColor2,...
                'FontSize',14,'FontName','Arial',...
                'Units','normalized');
            drawnow
        end

        set(0,'CurrentFigure',figtemp1);
        if length(currentSubRegion{1})>1 % then a subregion is selected
            % do we already have it plotted?
            if ~strcmp(latestMap1,currentRegion)
                % plot the region here
                plotRegion

                % keep track of what was most recently plotted
                latestMap1 = currentRegion;
            end
            % add box showing region
            if ~strcmp(latestMap2,currentSubRegion)
                addSubRegionBox
                delete(h_map1.Children)
                try
                axcopy = copyobj(pRegionMap.Children,h_map1);
                h_map1.PlotBoxAspectRatio = pRegionMap.PlotBoxAspectRatio;
                catch
                end
            end
        else % otherwise, plot worldmap
            % do we already have it plotted?
            if ~strcmp(latestMap1,'World')
                % plot the region here
                plotWorld

                % keep track of what was most recently plotted
                latestMap1 = 'World';
            end
            % add box showing region
            addRegionBox
            delete(h_map1.Children)
            axcopy = copyobj(pWorldMap.Children,h_map1);
            h_map1.PlotBoxAspectRatio = pWorldMap.PlotBoxAspectRatio;
        end
        set(0,'CurrentFigure',figtemp2);
        if length(currentSubRegion{1})>1 % then a subregion is selected
            % do we already have it plotted?
            if ~strcmp(latestMap2,currentSubRegion)
                % plot the region here
                plotSubRegion
                delete(h_map2.Children)
                try
                axcopy = copyobj(pSubRegionMap.Children,h_map2);
                h_map2.PlotBoxAspectRatio = pSubRegionMap.PlotBoxAspectRatio;
                catch
                end

                % keep track of what was most recently plotted
                latestMap2 = currentSubRegion;
            end
        else % otherwise, plot the current region
            % do we already have it plotted?
            if ~strcmp(latestMap2,currentRegion)
                % plot the region here
                plotRegion

                delete(h_map2.Children)
                try
                axcopy = copyobj(pRegionMap.Children,h_map2);
                h_map2.PlotBoxAspectRatio = pRegionMap.PlotBoxAspectRatio;
                catch
                end

                % keep track of what was most recently plotted
                latestMap2 = currentRegion;
            end
        end

        % If a core is selected, plot it in a larger blue dot
        if length(coralName)>0 && ~strcmp(coralName,'Download all')
            dir_idx = find(strcmp(coralDir.textdata(2:end,1),coralName));
            try
                pCore = plotm(coralDir.data(dir_idx(1),3),coralDir.data(dir_idx(1),4),'ko','MarkerEdgeColor','k', 'MarkerFaceColor',[0.2,0.2,0.8],'MarkerSize',12);
                delete(h_map2.Children)
                if length(currentSubRegion{1})>1 % subregion exists
                    axcopy = copyobj(pSubRegionMap.Children,h_map2);
                    h_map2.PlotBoxAspectRatio = pSubRegionMap.PlotBoxAspectRatio;
                else % only region
                    axcopy = copyobj(pRegionMap.Children,h_map2);
                    h_map2.PlotBoxAspectRatio = pRegionMap.PlotBoxAspectRatio;
                end
            catch
            end
        end

        % remove the hiding box and delete the loading label
        if choosingCore == 0
            delete(h_map3)
            set(lblMapClick,'Visible','off')
            drawnow
        end

        set(figtemp1,'Visible','off')
        set(figtemp2,'Visible','off')
        uistack(UserFig)
    end

    function plotRegion

        try load(strcat('shorelines_',currentRegion{1},'.mat'),'shorelines','boxLat','boxLon')
        catch
            try load(fullfile(selpath,'my_map_data',strcat('shorelines_',currentRegion{1},'.mat')),'shorelines','boxLat','boxLon')
            catch
                %cache = sftp(ftp_ip,'CoralCache_beta','Corals1234'); %
                regionfile = double(currentRegion{1});
                dMap = dir(cache1);
                map_names = {''};
                for jjjj = 1:length(dMap)
                    map_names{jjjj} = char(dMap(jjjj).name);
                end
                try
                    if length(find(regionfile==32)) > 0
                        regionfile(regionfile==32) = 95;
                        regionfile = char(regionfile);
                        if max(strcmp(strcat('shorelines_',regionfile,'.mat'),map_names))
                            mget(cache1,strcat('shorelines_',regionfile,'.mat'),fullfile(selpath,'my_map_data'));
                            load(fullfile(selpath,'my_map_data',strcat('shorelines_',regionfile,'.mat')),'shorelines','boxLat','boxLon')
                            save(fullfile(selpath,'my_map_data',strcat('shorelines_',currentRegion{1},'.mat')),'shorelines','boxLat','boxLon')
                            delete(fullfile(selpath,'my_map_data',strcat('shorelines_',regionfile,'.mat')))
                        else
                            set(lblMapClick,'Visible','on','String','Map unavailable')
                            pause(0.01)
                        end
                    else
                        if max(strcmp(strcat('shorelines_',currentRegion{1},'.mat'),map_names))
                            mget(cache1,strcat('shorelines_',currentRegion{1},'.mat'),fullfile(selpath,'my_map_data'));
                            load(fullfile(selpath,'my_map_data',strcat('shorelines_',currentRegion{1},'.mat')),'shorelines','boxLat','boxLon')
                        else
                            set(lblMapClick,'Visible','on','String','Map unavailable')
                            pause(0.01)
                        end
                    end
                catch
                end
                try
                    close(cache1)
                    cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                    cd(cache1,'CoralCache')
                catch
                    try
                        connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                        connectionEstablished = 0;
                        for ij = 1:length(connectTimes)
                            if connectionEstablished == 0
                                if connectTimes(ij) == 1
                                    waitText = [' ',num2str(connectTimes(ij)),' minute.']
                                else
                                    waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                                end
                                set(lblVerifying,'Units','Pixels','Visible','on',...
                                    'String',{'Error connecting to server.';strcat('Trying again in',waitText)})
                                pause(connectTimes(ij)*60)
                                try
                                    cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                    cd(cache1,'CoralCache')
                                    connectionEstablished = 1;
                                    set(lblVerifying,'Visible','off')
                                catch
                                end
                            end
                        end
                        if connectionEstablished == 0
                            zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                        end
                    catch
                        set(lblVerifying,'Visible','on',...
                            'String',{'Error connecting to server. (code 041)';'Please try again later.'})
                        while 1==1
                            pause
                        end
                    end
                end
            end
        end
        try
            pRegionMap = worldmap(boxLat,boxLon);

            hold on

            for i = 1:length(shorelines)
                patchm(shorelines(i).Lat(1:end-1),shorelines(i).Lon(1:end-1),[0 0 0])
            end
            plotm(coralDir.data(:,3),coralDir.data(:,4),'ko','MarkerEdgeColor','k', 'MarkerFaceColor',[0.96,0.51,0.58],'MarkerSize',10);
        catch
            set(lblMapClick,'Visible','on','String','Map unavailable')
            pause(0.01)
        end

    end

    function plotSubRegion

        try load(strcat('shorelines_',currentSubRegion{1},'.mat'),'shorelines','boxLat','boxLon')
        catch
            try load(fullfile(selpath,'my_map_data',strcat('shorelines_',currentSubRegion{1},'.mat')),'shorelines','boxLat','boxLon')
            catch
                %cache = sftp(ftp_ip,'CoralCache_beta','Corals1234'); %
                cd(cache1,'shorelines');
                subregionfile = double(currentSubRegion{1});
                dMap = dir(cache1);
                map_names = {''};
                for jjjj = 1:length(dMap)
                    map_names{jjjj} = char(dMap(jjjj).name);
                end
                try
                    if length(find(subregionfile==32)) > 0
                        subregionfile(subregionfile==32) = 95;
                        subregionfile = char(subregionfile);
                        if max(strcmp(strcat('shorelines_',subregionfile,'.mat'),map_names))
                            mget(cache1,strcat('shorelines_',subregionfile,'.mat'),fullfile(selpath,'my_map_data'));
                            load(fullfile(selpath,'my_map_data',strcat('shorelines_',subregionfile,'.mat')),'shorelines','boxLat','boxLon')
                            save(fullfile(selpath,'my_map_data',strcat('shorelines_',currentSubRegion{1},'.mat')),'shorelines','boxLat','boxLon')
                            delete(fullfile(selpath,'my_map_data',strcat('shorelines_',subregionfile,'.mat')))
                        else
                            set(lblMapClick,'Visible','on','String','Map unavailable')
                            pause(0.01)
                        end
                    else
                        if max(strcmp(strcat('shorelines_',currentSubRegion{1},'.mat'),map_names))
                            mget(cache1,strcat('shorelines_',currentSubRegion{1},'.mat'),fullfile(selpath,'my_map_data'));
                            load(fullfile(selpath,'my_map_data',strcat('shorelines_',currentSubRegion{1},'.mat')),'shorelines','boxLat','boxLon')
                        else
                            set(lblMapClick,'Visible','on','String','Map unavailable')
                            pause(0.01)
                        end
                    end
                catch
                end
                try
                    close(cache1)
                    cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                    cd(cache1,'CoralCache')
                catch
                    try
                        connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                        connectionEstablished = 0;
                        for ij = 1:length(connectTimes)
                            if connectionEstablished == 0
                                if connectTimes(ij) == 1
                                    waitText = [' ',num2str(connectTimes(ij)),' minute.']
                                else
                                    waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                                end
                                set(lblVerifying,'Units','Pixels','Visible','on',...
                                    'String',{'Error connecting to server.';strcat('Trying again in',waitText)})
                                pause(connectTimes(ij)*60)
                                try
                                    cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                    cd(cache1,'CoralCache')
                                    connectionEstablished = 1;
                                    set(lblVerifying,'Visible','off')
                                catch
                                end
                            end
                        end
                        if connectionEstablished == 0
                            zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                        end
                    catch
                        set(lblVerifying,'Visible','on',...
                            'String',{'Error connecting to server. (code 041)';'Please try again later.'})
                        while 1==1
                            pause
                        end
                    end
                end
            end
        end
        try
            pSubRegionMap = worldmap(boxLat,boxLon);

            hold on

            for i = 1:length(shorelines)
                patchm(shorelines(i).Lat(1:end-1),shorelines(i).Lon(1:end-1),[0 0 0])
            end
            plotm(coralDir.data(:,3),coralDir.data(:,4),'ko','MarkerEdgeColor','k', 'MarkerFaceColor',[0.96,0.51,0.58],'MarkerSize',10);
        catch
            set(lblMapClick,'Visible','on','String','Map unavailable')
            pause(0.01)
        end

    end

    function plotWorld

        pWorldMap = worldmap([-90 90],[20 380]);
        plabel('off')
        mlabel('off')
        hold on
        %geoshow('landareas.shp', 'FaceColor', [0 0 0])
        load('coastlines.mat')
        patchm(coastlat,coastlon,'k','EdgeColor','none')
        plotm(coralDir.data(:,3),coralDir.data(:,4),'ko','MarkerEdgeColor','k', 'MarkerFaceColor',[0.96,0.51,0.58]);

    end

    function addRegionBox

        if regionBoxExists == 1
            delete(pRegion)
        end

        try load(strcat('shorelines_',currentRegion{1}','.mat'),'boxLat','boxLon')
        catch
            try load(fullfile(selpath,'my_map_data',strcat('shorelines_',currentRegion{1},'.mat')),'boxLat','boxLon')
            catch
                %cache = sftp(ftp_ip,'CoralCache_beta','Corals1234'); %
                try cd(cache1,'shorelines');
                catch
                    try cd(cache1,'CoralCache')
                        cd(cache1,'shorelines');
                    catch
                        cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                        cd(cache1,'CoralCache')
                        cd(cache1,'shorelines');
                    end
                end
                regionfile = double(currentRegion{1});
                dMap = dir(cache1);
                map_names = {''};
                for jjjj = 1:length(dMap)
                    map_names{jjjj} = char(dMap(jjjj).name);
                end
                if length(find(regionfile==32)) > 0
                    regionfile(regionfile==32) = 95;
                    regionfile = char(regionfile);
                    if max(strcmp(strcat('shorelines_',regionfile,'.mat'),map_names))
                        mget(cache1,strcat('shorelines_',regionfile,'.mat'),fullfile(selpath,'my_map_data'));
                        load(fullfile(selpath,'my_map_data',strcat('shorelines_',regionfile,'.mat')),'shorelines','boxLat','boxLon')
                        save(fullfile(selpath,'my_map_data',strcat('shorelines_',currentRegion{1},'.mat')),'shorelines','boxLat','boxLon')
                        delete(fullfile(selpath,'my_map_data',strcat('shorelines_',regionfile,'.mat')))
                    else
                        set(lblMapClick,'Visible','on','String','Map unavailable')
                        pause(0.01)
                    end
                else
                    if max(strcmp(strcat('shorelines_',currentRegion{1},'.mat'),map_names))
                        mget(cache1,strcat('shorelines_',currentRegion{1},'.mat'),fullfile(selpath,'my_map_data'));
                        load(fullfile(selpath,'my_map_data',strcat('shorelines_',currentRegion{1},'.mat')),'shorelines','boxLat','boxLon')
                    else
                        set(lblMapClick,'Visible','on','String','Map unavailable')
                        pause(0.01)
                    end
                end
                try
                    close(cache1)
                    cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                    cd(cache1,'CoralCache')
                catch
                    try
                        connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                        connectionEstablished = 0;
                        for ij = 1:length(connectTimes)
                            if connectionEstablished == 0
                                if connectTimes(ij) == 1
                                    waitText = [' ',num2str(connectTimes(ij)),' minute.']
                                else
                                    waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                                end
                                set(lblVerifying,'Units','Pixels','Visible','on',...
                                    'String',{'Error connecting to server.';strcat('Trying again in',waitText)})
                                pause(connectTimes(ij)*60)
                                try
                                    cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                    cd(cache1,'CoralCache')
                                    connectionEstablished = 1;
                                    set(lblVerifying,'Visible','off')
                                catch
                                end
                            end
                        end
                        if connectionEstablished == 0
                            zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                        end
                    catch
                        set(lblVerifying,'Visible','on',...
                            'String',{'Error connecting to server. (code 041)';'Please try again later.'})
                        while 1==1
                            pause
                        end
                    end
                end
            end
        end

        try
        pRegion = plotm([boxLat(1),boxLat(1),boxLat(2),boxLat(2),boxLat(1)],...
            [boxLon(1),boxLon(2),boxLon(2),boxLon(1),boxLon(1)],'r-','LineWidth',2);

        regionBoxExists = 1;
        catch
        end

    end

    function addSubRegionBox

        %if a region box exists delete it before making a new one
        if regionBoxExists == 1
            delete(pRegion)
        end

        try load(strcat('shorelines_',currentSubRegion{1}','.mat'),'boxLat','boxLon')
        catch
            try load(fullfile(selpath,'my_map_data',strcat('shorelines_',currentSubRegion{1},'.mat')),'boxLat','boxLon')
            catch
                %cache = sftp(ftp_ip,'CoralCache_beta','Corals1234'); %
                cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                cd(cache1,'CoralCache')
                cd(cache1,'shorelines');
                subregionfile = double(currentSubRegion{1});
                dMap = dir(cache1);
                map_names = {''};
                for jjjj = 1:length(dMap)
                    map_names{jjjj} = char(dMap(jjjj).name);
                end
                if length(find(subregionfile==32)) > 0
                    subregionfile(subregionfile==32) = 95;
                    subregionfile = char(subregionfile);
                    if max(strcmp(strcat('shorelines_',subregionfile,'.mat'),map_names))
                        mget(cache1,strcat('shorelines_',subregionfile,'.mat'),fullfile(selpath,'my_map_data'));
                        load(fullfile(selpath,'my_map_data',strcat('shorelines_',subregionfile,'.mat')),'shorelines','boxLat','boxLon')
                        save(fullfile(selpath,'my_map_data',strcat('shorelines_',currentSubRegion{1},'.mat')),'shorelines','boxLat','boxLon')
                        delete(fullfile(selpath,'my_map_data',strcat('shorelines_',subregionfile,'.mat')))
                    else
                        set(lblMapClick,'Visible','on','String','Map unavailable')
                        pause(0.01)
                    end
                else
                    if max(strcmp(strcat('shorelines_',currentSubRegion{1},'.mat'),map_names))
                        mget(cache1,strcat('shorelines_',currentSubRegion{1},'.mat'),fullfile(selpath,'my_map_data'));
                        load(fullfile(selpath,'my_map_data',strcat('shorelines_',currentSubRegion{1},'.mat')),'shorelines','boxLat','boxLon')
                    else
                        set(lblMapClick,'Visible','on','String','Map unavailable')
                        pause(0.01)
                    end
                end
                try
                    close(cache1)
                    cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                    cd(cache1,'CoralCache')
                catch
                    try
                        connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                        connectionEstablished = 0;
                        for ij = 1:length(connectTimes)
                            if connectionEstablished == 0
                                if connectTimes(ij) == 1
                                    waitText = [' ',num2str(connectTimes(ij)),' minute.']
                                else
                                    waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                                end
                                set(lblVerifying,'Units','Pixels','Visible','on',...
                                    'String',{'Error connecting to server.';strcat('Trying again in',waitText)})
                                pause(connectTimes(ij)*60)
                                try
                                    cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                    cd(cache1,'CoralCache')
                                    connectionEstablished = 1;
                                    set(lblVerifying,'Visible','off')
                                catch
                                end
                            end
                        end
                        if connectionEstablished == 0
                            zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                        end
                    catch
                        set(lblVerifying,'Visible','on',...
                            'String',{'Error connecting to server. (code 041)';'Please try again later.'})
                        while 1==1
                            pause
                        end
                    end
                end
            end
        end

        try
        %once you define lat long box this will plot it
        pRegion = plotm([boxLat(1),boxLat(1),boxLat(2),boxLat(2),boxLat(1)],...
            [boxLon(1),boxLon(2),boxLon(2),boxLon(1),boxLon(1)],'r-','LineWidth',2);

        regionBoxExists = 1;
        catch
        end

    end

dispName = 'none';
try
    try coreInfo = importdata(fullfile(selpath,'my_corals','current_scan','dicoms','CoreMetaData.csv'));
        ct = 1;
    catch
        try coreInfo = importdata(fullfile(selpath,'my_corals','current_scan','Xray','CoreMetaData.csv'));
            ct = 0;
        catch
            set(lblOpeningError,'Visible','on','String','Cannot find metadata file')
            pause
        end
    end
    % Load metadata
    hasDataPart = 0;
    try checkInfo = coreInfo.data;
        hasDataPart = 1;
    catch
    end
    if hasDataPart == 1
        coralName = coreInfo.textdata{1};
        sectionName = num2str(coreInfo.data);
    else
        coralName = coreInfo{1};
        if length(coreInfo)>1
            sectionName = coreInfo{2};
        else
            sectionName = ''; % default
        end
    end
    if strcmp(sectionName,'')
        dispName = strcat(coralName);
    else
        dispName = strcat(coralName,'/',sectionName);
    end
catch
end

% create button for this
openLastIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Open last scan';strcat('(',dispName,')')},'Visible','off',...
    'Position',[860,730,160,60],'Units','normalized','BackgroundColor',[218, 108, 143]./255,'FontSize',12,'FontName','Arial','Callback',@openLast);

% Function to import the last scan that's in the 'dicoms' folder
    function openLast(src,event)

        set(lblOpeningError,'Visible','off')

        try coreInfo = importdata(fullfile(selpath,'my_corals','current_scan','dicoms','CoreMetaData.csv'));
            ct = 1;
        catch
            try coreInfo = importdata(fullfile(selpath,'my_corals','current_scan','Xray','CoreMetaData.csv'));
                ct = 0;
            catch
                set(lblOpeningError,'Visible','on','String','Cannot find metadata file')
                pause
            end
        end

        dirRow = []; % this stores the row in directory that user chose

        set(startIn,'Visible','off')
        lblOpening = uicontrol(UserFig,'Style','text','String','Opening data...','Position',[200,150,500,20],...
            'BackgroundColor',themeColor2,'FontSize',10,'FontName','Arial','Units','normalized');

        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            dispVid = uihtml(UserFig);
            dispVid.Position = [200,250,500,500];
            rng('shuffle')
            rand_vid = round(rand(1)*(n_loading_vids-1))+1;
            dispVid.HTMLSource = (fullfile('loading_movies',strcat('core_movie',num2str(rand_vid),'.html')));
            lblVideo = uicontrol(UserFig,'Style','text','String',videoLabel(rand_vid),'Position',[200,250,500,20],...
                'FontSize',10,'FontName','Arial','Units','normalized','BackgroundColor','none');
        end

        pause(0.001)

        % Turn visibility off for all the core-selection drop-down menus
        set(regionIn,'Visible','off')
        set(subRegionIn,'Visible','off')
        set(coreIn,'Visible','off')
        set(UserSetIn,'Visible','off')
        set(startIn,'Visible','off')
        set(htextLocked,'Visible','off')
        set(previewIn,'Visible','off')
        set(htextUser,'Visible','off')
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            set(saveLogin, 'Visible','off')
            set(userProfileIn,'Visible','off')
            set(coreDirIn,'Visible','off')
        end
        set(htextSave,'Visible','off')
        set(saveDataIn,'Visible','off')
        try
            set(sectionIn,'Visible','off')
        catch
        end
        set(openLastIn,'Visible','off')
        set(htextsubRegion,'Visible','off')
        set(htextCore,'Visible','off')
        set(htextSection,'Visible','off')
        set(htextRegion,'Visible','off')
        set(coreIn,'Visible','off')
        set(openChooseIn, 'Visible','off')
        set(fileSizePreview,'Visible','off')
        set(checkSpeedIn,'Visible','off')
        set(dataModeLabel,'Visible','off');
        set(getDataIn,'Visible','off')
        set(downloadTimePreview,'Visible','off')
        set(SubmitDataIn,'Visible','off')
        set(calibCurveIn,'Visible','off')
        set(htextLink4,'Visible','off')

        map_cover = patch(h_map_cover,[0,1],[0,1],themeColor2,'EdgeColor','none');
        set(h_preview,'Visible','off')
        delete(h_preview)
        if preview_exists == 1
            delete(p_preview);
            preview_exists = 0;
        end

        delete(h_map1)
        delete(h_map2)
        delete(h_map_cover)
        pause(0.01)

        % Load metadata
        hasDataPart = 0;
        try checkInfo = coreInfo.data;
            hasDataPart = 1;
        catch
        end
        if hasDataPart == 1
            coralName = coreInfo.textdata{1};
            sectionName = num2str(coreInfo.data);
        else
            coralName = coreInfo{1};
            if length(coreInfo)>1
                sectionName = coreInfo{2};
            else
                sectionName = ''; % default
            end
        end

        saveName = strcat(saveFileName,'_');

        try findCoralMetadata(coralName,sectionName)
        catch
            try findCoralMetadata(coralName,sectionName)
            catch
                set(lblOpeningError,'Visible','on','String','Error connecting to server (code 001)')
                pause
                while 1 ~= 2
                    pause
                end
            end
        end

        set(lblOpening,'Visible','off')

        % load the dicom data from local drive into this Matlab session
        if ct == 1
            fileOpen = fullfile(selpath,'my_corals','current_scan','dicoms');
        else
            fileOpen = fullfile(selpath,'my_corals','current_scan','Xray');
        end

        if ct == 1
            % turn on visibility of loading bar (called 'ha3')
            set(ha3,'Visible','on')
            try loadData
            catch
                pause(3)
                try loadData
                catch
                    set(lblOpeningError,'Visible','on','String','Error in CT dataset (code 002)')
                    pause
                    while 1 ~= 2
                        pause
                    end
                end
            end
        else
            set(ha3,'Visible','on')
            try loadXray
            catch
                pause(3)
                try loadXray
                catch
                    set(lblOpeningError,'Visible','on','String','Error in X-ray dataset (code 003)')
                    pause
                    while 1 ~= 2
                        pause
                    end
                end
            end
        end

        % Choose core filter, which is based on the genus
        chooseCoreFilter

        % turn off loading bar once all image data in Matlab
        set(ha3,'Visible','off')
        delete(p1)
        delete(ha3)
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            delete(dispVid)
            delete(lblVideo)
        end

        % launch the main GUI for interacting with the scan
        areDataUnlocked = 1;
        core_run
    end


% Option to open user choice of existing CT scan

% create button for this
openChooseIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Open saved scan'},'Visible','off',...
    'Position',[860,660,160,60],'Units','normalized','BackgroundColor',[222, 43, 109]./255,'FontSize',14,'FontName','Arial','Callback',@openChoose);

% Function to import the last scan that's in the 'dicoms' folder
    function openChoose(src,event)
        dirRow = []; % this stores the row in directory that user chose

        set(lblOpeningError,'Visible','off')
        set(startIn,'Visible','off')
        set(htextLocked,'Visible','off')

        set(UserFig,'Visible','off')
        selpath2 = uigetdir;
        set(UserFig,'Visible','on')

        thisFolderName0 = strsplit(selpath2,filesep);
        thisFolderName = thisFolderName0{length(thisFolderName0)};

        lblOpening = uicontrol(UserFig,'Style','text','String','Opening data...','Position',[200,150,500,20],...
            'BackgroundColor',themeColor2,'FontSize',10,'FontName','Arial','Units','normalized');

        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            dispVid = uihtml(UserFig);
            dispVid.Position = [200,250,500,500];
            %
            rng('shuffle')
            rand_vid = round(rand(1)*(n_loading_vids-1))+1;
            dispVid.HTMLSource = (fullfile('loading_movies',strcat('core_movie',num2str(rand_vid),'.html')));
            lblVideo = uicontrol(UserFig,'Style','text','String',videoLabel(rand_vid),'Position',[200,250,500,20],...
                'FontSize',10,'FontName','Arial','Units','normalized','BackgroundColor','none');
        end

        pause(0.001)

        % Turn visibility off for all the core-selection drop-down menus
        set(regionIn,'Visible','off')
        set(subRegionIn,'Visible','off')
        set(coreIn,'Visible','off')
        set(UserSetIn,'Visible','off')
        set(startIn,'Visible','off')
        set(htextLocked,'Visible','off')
        set(previewIn,'Visible','off')
        set(htextUser,'Visible','off')
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            set(saveLogin, 'Visible','off')
            set(userProfileIn,'Visible','off')
            set(coreDirIn,'Visible','off')
        end
        set(htextSave,'Visible','off')
        set(saveDataIn,'Visible','off')
        try
            set(sectionIn,'Visible','off')
        catch
        end
        set(openLastIn,'Visible','off')
        set(htextsubRegion,'Visible','off')
        set(htextCore,'Visible','off')
        set(htextSection,'Visible','off')
        set(htextRegion,'Visible','off')
        set(coreIn,'Visible','off')
        %set(updateDirIn, 'Visible','off')
        set(openChooseIn, 'Visible','off')
        set(fileSizePreview,'Visible','off')
        set(checkSpeedIn,'Visible','off')
        %set(h_map_cover,'Visible','off');
        set(dataModeLabel,'Visible','off');
        set(getDataIn,'Visible','off')
        set(downloadTimePreview,'Visible','off')
        set(SubmitDataIn,'Visible','off')
        set(calibCurveIn,'Visible','off')
        set(htextLink4,'Visible','off')

        map_cover = patch(h_map_cover,[0,1],[0,1],themeColor2,'EdgeColor','none');

        set(h_preview,'Visible','off')
        delete(h_preview)
        if preview_exists == 1
            delete(p_preview);
            preview_exists = 0;
        end

        delete(h_map1)
        delete(h_map2)
        delete(h_map_cover)

        pause(0.01)

        coralName = thisFolderName;
        sectionName = '';

        try coreInfo = importdata(fullfile(selpath,'my_corals',coralName,sectionName,'dicoms','CoreMetaData.csv'));
            ct = 1;
        catch
            try coreInfo = importdata(fullfile(selpath,'my_corals',coralName,sectionName,'Xray','CoreMetaData.csv'));
                ct = 0;
            catch
                set(lblOpeningError,'Visible','on','String','Cannot find metadata file')
                pause
            end
        end

        saveName = strcat(saveFileName,'_');

        try findCoralMetadata(coralName,sectionName)
        catch
            try findCoralMetadata(coralName,sectionName)
            catch
                set(lblOpeningError,'Visible','on','String','Error connecting to server (code 004)')
                pause
                while 1 ~= 2
                    pause
                end
            end
        end

        set(lblOpening,'Visible','off')

        % load the dicom data from local drive into this Matlab session
        if ct == 1
            fileOpen = fullfile(selpath2,'dicoms');
        else
            fileOpen = fullfile(selpath2,'Xray');
        end

        if ct == 1
            % turn on visibility of loading bar (called 'ha3')
            set(ha3,'Visible','on')
            try loadData
            catch
                pause(3)
                try loadData
                catch
                    set(lblOpeningError,'Visible','on','String','Error in CT dataset (code 007)')
                    pause
                    while 1 ~= 2
                        pause
                    end
                end
            end
        else
            set(ha3,'Visible','on')
            try loadXray
            catch
                pause(3)
                try loadXray
                catch
                    set(lblOpeningError,'Visible','on','String','Error in X-ray dataset (code 008)')
                    pause
                    while 1 ~= 2
                        pause
                    end
                end
            end
        end

        % Choose core filter, which is based on the genus
        chooseCoreFilter

        % turn off loading bar once all image data in Matlab
        set(ha3,'Visible','off')
        delete(p1)
        delete(ha3)
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            delete(dispVid)
            delete(lblVideo)
        end

        % launch the main GUI for interacting with the scan
        areDataUnlocked = 1;
        core_run
    end

% Create custom pointer for clicking mode
band_pointer = NaN(16);
% this is 15x15:
% pointer_row = [1,1,1,1,1,2,2,3,4,5,6,7,8,9,10,11,12,13,14,14,15,15,15,15,15,14,14,13,12,11,10,9,8,7,6,5,4,3,2,2];
% pointer_col = [6,7,8,9,10,11,12,13,14,14,15,15,15,15,15,14,14,13,12,11,10,9,8,7,6,5,4,3,2,2,1,1,1,1,1,2,2,3,4,5];
% band_pointer_hotspot = [8,8];

% this is 9x9:
pointer_row = [1,1,1,1,1,2,3,4,5,6,7,8,9,9,9,9,9,8,7,6,5,4,3,2];
pointer_col = [3,4,5,6,7,8,9,9,9,9,9,8,7,6,5,4,3,2,1,1,1,1,1,2];
band_pointer_hotspot = [4,6];

for ii = 1:length(pointer_row)
    band_pointer(pointer_row(ii),pointer_col(ii)) = 2;
end

% Create drop-down menu to select region
regionIn = uicontrol(UserFig,'Style','popupmenu',...
    'Position',[720,570,250,35],'Units','normalized',...
    'String',regionList,'Visible','off',...
    'Callback',@chosenRegion);

%puts text on telling you to select your region
htextRegion = uicontrol(UserFig,'Style','text','String','Select a Region:','Visible','off',...
    'Position',[765,610,160,25],'Units','normalized','BackgroundColor','none','ForegroundColor',themeColor3,'FontSize',11,'FontName','Arial');

% initialize core menu
coreIn = uicontrol(UserFig,'Style','popupmenu',...
    'Position',[720,405,250,30],'Units','normalized',...
    'String',' ',...
    'Callback',@chosenCore,'Visible','off');

% initialize subregion menu
subRegionIn = uicontrol(UserFig,'Style','popupmenu',...
    'Position',[720,490,250,30],'Units','normalized',...
    'String',' ','Visible','off',...
    'Callback',@chosenSubRegion);

% Function to store user's chosen region and then open appropriate
% subregions
    function chosenRegion(src,event)

        set(htextsubRegion,'Visible','off')
        set(subRegionIn,'Visible','off')
        try set(sectionIn,'Visible','off')
        catch
        end
        set(htextSection,'Visible','off')
        set(htextCore,'Visible','off')
        set(htextBands,'Visible','off')
        set(htextNoBands,'Visible','off')
        set(htextBandsLocked,'Visible','off')
        set(bandsMapsIn,'Visible','off')
        set(startIn,'Visible','off')
        set(htextLocked,'Visible','off')
        set(checkSpeedIn,'Visible','off')
        % if speedCheck_printed == 1
        %     set(speedCheck,'Visible','off')
        %     speedCheck_printed = 0;
        % end
        set(view3DBandsIn,'Visible','off') % allow user to preview core
        set(downloadDataIn,'Visible','off') % allow user to press "Go"
        set(previewIn,'Visible','off') % allow user to preview core
        %set(fileSizePreview,'Visible','off')
        set(fileSizePreview,'Visible','off')
        set(downloadTimePreview,'Visible','off')
        set(checkSpeedIn,'Visible','off')
        set(coreIn,'Visible','off')

        currentSubRegion = {' '};
        currentRegion = regionList(regionIn.Value); % store selection from dropdown menu

        % search the master directory for matches to chosen region
        theseSubRegions = find(strcmp(coralDir.textdata(2:end,3),currentRegion));

        % find unique list of subregions in this region
        currentSubRegions = unique(coralDir.textdata(theseSubRegions+1,4));

        % If we have more than 1 subregion, create dropdown menu to select
        % the subregion
        if length(currentSubRegions) > 1

            set(subRegionIn,'Value',1);
            set(subRegionIn,'String',currentSubRegions);
            set(subRegionIn,'Visible','on');
            set(htextsubRegion,'Visible','on')

            updateMap

        else % Not multiple subregions, no need to display subregion menu
            % Find cores in this region:
            set(coreIn,'Value',1);
            theseCores = find(strcmp(coralDir.textdata(2:end,3),currentRegion));
            % check if unlocked
            areDataUnlocked = -coralDir.data(theseCores,9)+2;
            dataOwner = coralDir.textdata(theseCores+1,6);
            dataOwners = {''};
            for jjj = 1:length(dataOwner)
                dataOwners(jjj,1:length(strsplit(dataOwner{jjj},'//'))) = strsplit(dataOwner{jjj},'//');
            end
            theseCores((areDataUnlocked==-2|areDataUnlocked==4) & ~any(strcmp(saveFileName,dataOwners),2)) = [];

            % Store unique list of the cores:
            currentCores = unique(coralDir.textdata(theseCores+1,1));

            % Update dropdown menu to select core in this region:
            if dataMode == 0
                coreIn.String = currentCores;
            elseif dataMode == 1
                coreIn.String = ['Download all';currentCores];
            end
            set(coreIn,'Visible','on')
            set(htextCore,'Visible','on')
            updateMap

        end
    end

%display subregion text on figure

htextsubRegion = uicontrol(UserFig,'Style','text','String','Select a Subregion:',...
    'Position',[765,525,160,25],'Units','normalized','BackgroundColor','none',...
    'ForegroundColor',themeColor3,'FontSize',11,'FontName','Arial','Visible','off');

% desplay "select a core" text in figure
htextCore = uicontrol(UserFig,'Style','text','String','Select a Core:',...
    'Position',[765,440,160,25],'Units','normalized','BackgroundColor','none',...
    'ForegroundColor',themeColor3,'FontSize',11,'FontName','Arial','Visible','off');

%desplay 'select a section' in figure
htextSection = uicontrol(UserFig,'Style','text','String','Select a Section:',...
    'Position',[765,355,160,25],'Units','normalized','BackgroundColor','none',...
    'ForegroundColor',themeColor3,'FontSize',11,'FontName','Arial','Visible','off');

htextLocked = uicontrol(UserFig,'Style','text','String',' ',...
    'Position',[720,265,250,50],'Units','normalized','BackgroundColor','none',...
    'ForegroundColor',[0,0,0],'FontSize',11,'FontName','Arial','Visible','off');

% display 'select a band map'
htextBands = uicontrol(UserFig,'Style','text','String','Select a band map:',...
    'Position',[765,280,160,25],'Units','normalized','BackgroundColor','none',...
    'ForegroundColor',themeColor3,'FontSize',11,'FontName','Arial','Visible','off');

% create label for no existing bands
htextNoBands = uicontrol(UserFig,'Style','text','String','No band maps exist for this core',...
    'Position',[730,250,230,25],'Units','normalized',...
    'FontSize',11,'FontName','Arial','Visible','off');

% create label for locked bands
htextBandsLocked = uicontrol(UserFig,'Style','text','String','Data are locked for this core',...
    'Position',[740,250,210,25],'Units','normalized',...
    'FontSize',11,'FontName','Arial','Visible','off');

% Function to store user's chosen subregion and then open appropriate
% cores
    function chosenSubRegion(src,event)

        % if file size already displayed, delete it
        set(fileSizePreview,'Visible','off')
        set(downloadTimePreview,'Visible','off')
        set(checkSpeedIn,'Visible','off')
        try set(sectionIn,'Visible','off')
        catch
        end
        coreIn.Value = 1;
        set(htextSection,'Visible','off')
        set(startIn,'Visible','off')
        set(htextLocked,'Visible','off')
        set(checkSpeedIn,'Visible','off')
        set(previewIn,'Visible','off') % allow user to preview core
        set(htextBands,'Visible','off')
        set(htextNoBands,'Visible','off')
        set(htextBandsLocked,'Visible','off')
        set(bandsMapsIn,'Visible','off')

        subRegionNum = subRegionIn.Value; % user's input (number in list)
        subRegionName = currentSubRegions(subRegionNum); % text of subregion
        currentSubRegion = subRegionName;%subRegionName{1};

        % Find cores that belong in this subregion
        theseCores = find(strcmp(coralDir.textdata(2:end,4),subRegionName));
        % check if unlocked
        areDataUnlocked = -coralDir.data(theseCores,9)+2;
        dataOwner = coralDir.textdata(theseCores+1,6);
        dataOwners = {''};
        for jjj = 1:length(dataOwner)
            dataOwners(jjj,1:length(strsplit(dataOwner{jjj},'//'))) = strsplit(dataOwner{jjj},'//');
        end
        theseCores((areDataUnlocked==-2|areDataUnlocked==4) & ~any(strcmp(saveFileName,dataOwners),2)) = [];

        % get unique list of cores
        currentCores = unique(coralDir.textdata(theseCores+1,1));

        % Update dropdown menu to select core in this region:

        updateMap

        if dataMode == 0
            coreIn.String = currentCores;
        elseif dataMode == 1
            coreIn.String = ['Download all';currentCores];
        end
        set(coreIn,'Visible','on')
        set(htextCore,'Visible','on')
    end

dirOut = [];

bandsMapsIn = uicontrol(UserFig,'Style','popupmenu',...
    'Position',[720,250,250,25],'Units','normalized',...
    'String',' ','Visible','off',...
    'Callback',@chosenBands);

%preview_printed = 0; % toggle if we have a file size displayed

fileSizePreview = uicontrol(UserFig,'Style','text','String',' ','Visible','off',...
    'Position',[680,20,150,25],'Units','normalized','BackgroundColor','none','ForegroundColor',themeColor3,'FontSize',11,'FontName','Arial');

sectionMenuExists = 0;

downloadAllCoresToggle = 0;
areDataUnlocked = [];
% Function to interpret user's core selection
    function chosenCore(src,event)

        % if file size already displayed, delete it
        set(fileSizePreview,'Visible','off')
        set(downloadTimePreview,'Visible','off')
        set(downloadDataIn,'Visible','off')
        set(view3DBandsIn,'Visible','off')
        set(previewIn,'Visible','off') % allow user to preview core
        set(htextBands,'Visible','off')
        set(htextNoBands,'Visible','off')
        set(bandsMapsIn,'Visible','off')
        try set(sectionIn,'Visible','off')
            set(htextSection,'Visible','off')
        catch
        end

        sectionName = ''; % default

        % If a core is already selected, delete its plot from the map
        if length(coralName)>0
            delete(pCore);
        end

        if dataMode == 0
            coralNum = coreIn.Value; % user's input (number in dropdown list)
            coralName = currentCores(coralNum); % text of user's selection
            coralName = coralName{1}; % convert to string format
        elseif dataMode == 1 && coreIn.Value > 1
            coralNum = coreIn.Value; % user's input (number in dropdown list)
            coralName = currentCores(coralNum-1); % text of user's selection
            coralName = coralName{1}; % convert to string format
        elseif dataMode == 1
            coralName = 'Download all';
            sectionName = ''; % default
            set(downloadDataIn,'Visible','on')
            downloadAllCoresToggle = 1;
            % else
            %     set(downloadDataIn,'Visible','on')
            %     downloadAllCoresToggle = 1;
        end

        % search for sections within this core (first column of directory)
        theseSections = find(strcmp(coralDir.textdata(2:end,1),coralName));

        % Determine whether there are multiple sections or not
        if length(theseSections) == 1 % not multiple sections
            % Save to 'FileOpen' the location on local drive where data
            % will be stored once downloaded from server:
            ct = coralDir.data(theseSections,12);
            if saveCTdata == 1 && dataMode == 0% && dataMode == 0
                if ct == 1
                    fileOpen = fullfile(selpath,'my_corals',coralName,'dicoms');
                else
                    fileOpen = fullfile(selpath,'my_corals',coralName,'Xray');
                end
            elseif dataMode >= 0
                if dataMode == 0
                    if ct == 1
                        fileOpen = fullfile(selpath,'my_corals','current_scan','dicoms');
                    else
                        fileOpen = fullfile(selpath,'my_corals','current_scan','Xray');
                    end
                elseif dataMode == 1
                    if ct == 1
                        fileOpen = fullfile(selpath,'my_corals','current_scan_view_only','dicoms');
                    else
                        fileOpen = fullfile(selpath,'my_corals','current_scan_view_only','Xray');
                    end
                end
            end
            set(previewIn,'String',{'Preview Core'})
            set(previewIn,'Visible','on') % allow user to preview core
            preview_failed = 0;

            areDataUnlocked = -coralDir.data(theseSections,9)+2;
            dataOwner = coralDir.textdata(theseSections+1,6);
            dataOwners = {''};
            for jjj = 1:length(dataOwner)
                dataOwners(jjj,1:length(strsplit(dataOwner{jjj},'//'))) = strsplit(dataOwner{jjj},'//');
            end
            if any(strcmp(saveFileName,dataOwners),2)
                areDataUnlocked = 1; % master user identified
            end
            if areDataUnlocked < 0
                saveDataIn.Value = 1;
                saveCTdata = 0;
            end

            if dataMode == 1
                if coreIn.Value ~= 1
                    dirOut = findBandFiles(coralName,sectionName);
                    if length(dirOut) > 0 && areDataUnlocked == 1
                        bandsMapsIn.Value = 1;
                        bandsMapsIn.String = [{'Download all'};dirOut'];
                        set(bandsMapsIn,'Visible','on')
                        set(htextBands,'Visible','on')
                        set(htextNoBands,'Visible','off')
                        set(htextBandsLocked,'Visible','off')
                    elseif length(dirOut) > 0 && areDataUnlocked ~= 1
                        set(bandsMapsIn,'Visible','off')
                        set(htextBands,'Visible','off')
                        set(htextNoBands,'Visible','off')
                        set(htextBandsLocked,'Visible','on')
                    else
                        set(bandsMapsIn,'Visible','off')
                        set(htextNoBands,'Visible','on')
                        set(htextBands,'Visible','on')
                        set(htextBandsLocked,'Visible','off')
                    end
                end
            else
                if coralDir.data(theseSections,12) == 1
                    set(startIn,'Visible','on','String','Open CT scan') % allow user to press "Go"
                else
                    set(startIn,'Visible','on','String','Open 2D X-ray') % allow user to press "Go"
                end
                if (areDataUnlocked==0||areDataUnlocked==2)
                    set(htextLocked,'Visible','on','String','output data are blocked for this core');
                elseif (areDataUnlocked==-1||areDataUnlocked==3)
                    set(htextLocked,'Visible','on','String',{'output data and raw images are blocked for this core'});
                end
                set(checkSpeedIn,'Visible','on')
                thisFileSize = coralDir.data(theseSections,8);
                thisFileSizeText = sprintf('File Size: %i MB', thisFileSize);
                set(fileSizePreview,'String',thisFileSizeText)
                set(fileSizePreview,'Visible','on')
                %preview_printed = 1;
            end

        elseif length(theseSections) > 1 % multiple sections exist
            % Get unique list of sections
            
            currentSections = unique(coralDir.textdata(theseSections+1,2));

            if dataMode == 1

                % Create drop-down menu to select section
                sectionIn = uicontrol(UserFig,'Style','popupmenu',...
                    'Position',[720,320,250,30],'Units','normalized',...
                    'String',['Download all';currentSections],...
                    'Callback',@chosenSection);
                sectionMenuExists = 1;
            else
                % Create drop-down menu to select section
                sectionIn = uicontrol(UserFig,'Style','popupmenu',...
                    'Position',[720,320,250,30],'Units','normalized',...
                    'String',currentSections,...
                    'Callback',@chosenSection);
                sectionMenuExists = 1;
            end
            set(htextSection,'Visible','on')
            set(startIn,'Visible','off')
            set(htextLocked,'Visible','off')
            set(checkSpeedIn,'Visible','off')
        end

        choosingCore = 1;
        updateMap
        choosingCore = 0;

    end

    function downloadAllCoresDataInRegion

        coralNameHold = coralName;
        sectionNameHold = sectionName;

        for ii = 1:length(currentCores)
            theseSections = find(strcmp(coralDir.textdata(2:end,1),currentCores{ii}));
            for jj = 1:length(theseSections)
                dataOwner = coralDir.textdata(theseSections+1,6);
                dataOwners = {''};
                for jjj = 1:length(dataOwner)
                    dataOwners(jjj,1:length(strsplit(dataOwner{jjj},'//'))) = strsplit(dataOwner{jjj},'//');
                end
                if coralDir.data(theseSections(jj),9) == 1 || any(strcmp(saveFileName,dataOwners),2) 
                    coralName = coralDir.textdata{theseSections(jj)+1,1};
                    sectionName = coralDir.textdata{theseSections(jj)+1,2};
                    dirOut = findBandFiles(coralName,sectionName);
                    for kk = 1:length(dirOut)
                        getBandFile(coralName,sectionName,dirOut{kk})
                    end
                end
            end
        end

        coralName = coralNameHold;
        sectionName = sectionNameHold;
        set(downloadDataIn,'Visible','off')

    end

    function downloadAllSectionsDataInCore

        sectionNameHold = sectionName;

        theseSections = find(strcmp(coralDir.textdata(2:end,1),coralName));
        for jj = 1:length(theseSections)
            sectionName = coralDir.textdata{theseSections(jj)+1,2};
            dirOut = findBandFiles(coralName,sectionName);
            for kk = 1:length(dirOut)
                getBandFile(coralName,sectionName,dirOut{kk})
            end
        end

        sectionName = sectionNameHold;

    end

    function downloadAllDataInACore

        dirOut = findBandFiles(coralName,sectionName);
        for kk = 1:length(dirOut)
            getBandFile(coralName,sectionName,dirOut{kk})
        end

    end

speedCheck = 1; % to estimate download time
thisFileSize = 1;
speedCheck_printed = 0;
checkSpeedIn = uicontrol(UserFig,'Style','pushbutton',...
    'Position',[860,20,160,35],'Units','normalized',...
    'String','Check download speed','Visible','off',...
    'Callback',@checkSpeed);

% Function to test download speed
    function checkSpeed(src,event)

        set(downloadTimePreview,'Visible','off')
        lblCheckSpeed = uicontrol(UserFig,'Style','text','String','Checking connection speed...','Position',[860,15,180,40],...
            'BackgroundColor',themeColor2,'FontSize',10,'FontName','Arial','Units','normalized');

        pause(0.01)

        h_drive = '/hd1/';

        thisCoralName = 'F53B';
        test_row = find(strcmp(coralDir.textdata(:,1),thisCoralName));

        try cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password) %
        catch
            set(lblFTPerror,'Visible','on')
        end
        tic
        server_path = strcat(h_drive,'/',coralDir.textdata{test_row,3},'/',...
            coralDir.textdata{test_row,4},'/',thisCoralName);

        server_path(double(server_path)==32) = 95;

        cd(cache2,server_path)

        mget(cache2,'dicoms.zip',fullfile(selpath,'my_corals','current_scan'));
        close(cache2)
        download_time = toc;
        speedCheck = 30/download_time;

        thisDownloadTimeText = sprintf('Estimated download time: %i seconds', round((thisFileSize/speedCheck)*1.05));
        set(downloadTimePreview,'String',thisDownloadTimeText)
        set(downloadTimePreview,'Visible','on')
        set(lblCheckSpeed,'Visible','off')

        %speedCheck_printed = 1;

    end

% Function to interpret user's band-map selection
chosenBandsName = [];
downloadAllBandsToggle = 0;
    function chosenBands(src,event)

        if bandsMapsIn.Value>1
            chosenBandsNum = bandsMapsIn.Value; % user's input (number in dropdown list)
            chosenBandsName0 = dirOut(chosenBandsNum-1); % store as text
            chosenBandsName = chosenBandsName0{1}; % convert to string

            set(view3DBandsIn,'Visible','on') % allow user to preview core
            set(downloadDataIn,'Visible','on') % allow user to press "Go"
        else
            downloadAllBandsToggle = 1;
            set(view3DBandsIn,'Visible','off') % allow user to preview core
            set(downloadDataIn,'Visible','on') % allow user to press "Go"
        end

    end

sectionName = ''; % default
downloadTimePreview = uicontrol(UserFig,'Style','text','String',' ','Visible','off',...
    'Position',[840, 20,260,40],'Units','normalized','BackgroundColor',themeColor1,'ForegroundColor',[0,0,0],'FontSize',11,'FontName','Arial');

downloadAllSectionsToggle = 0;

% Function to interpret user's choice of section
    function chosenSection(src,event)

        if dataMode == 0
            sectionNum = sectionIn.Value; % user's input (number in dropdown list)
            sectionName = currentSections(sectionNum); % store as text
            sectionName = sectionName{1}; % convert to string
        elseif dataMode == 1 && sectionIn.Value > 1
            sectionNum = sectionIn.Value; % user's input (number in dropdown list)
            sectionName = currentSections(sectionNum-1); % store as text
            sectionName = sectionName{1}; % convert to string
        else
            set(downloadDataIn,'Visible','on')
            downloadAllSectionsToggle = 1;
        end

        % Save to 'FileOpen' the location on local drive where data
        % will be stored once downloaded from server:

        thisSection = find(strcmp(coralDir.textdata(2:end,1),coralName)...
            & strcmp(coralDir.textdata(2:end,2),sectionName));

        ct = coralDir.data(thisSection,12);
        if saveCTdata == 1 && dataMode == 0
            if ct == 1
                fileOpen = fullfile(selpath,'my_corals',coralName,sectionName,'dicoms');
            else
                fileOpen = fullfile(selpath,'my_corals',coralName,sectionName,'Xray');
            end
        elseif dataMode >= 0
            if dataMode == 0
                if ct == 1
                    fileOpen = fullfile(selpath,'my_corals','current_scan','dicoms');
                else
                    fileOpen = fullfile(selpath,'my_corals','current_scan','Xray');
                end
            elseif dataMode == 1
                if ct == 1
                    fileOpen = fullfile(selpath,'my_corals','current_scan_view_only','dicoms');
                else
                    fileOpen = fullfile(selpath,'my_corals','current_scan_view_only','Xray');
                end
            end
        end

        set(previewIn,'String',{'Preview Core'})
        set(previewIn,'Visible','on') % allow user to preview core
        preview_failed = 0;

        areDataUnlocked = -coralDir.data(thisSection,9)+2;
        dataOwner = coralDir.textdata(thisSection+1,6);
            dataOwners = {''};
            for jjj = 1:length(dataOwner)
                dataOwners(jjj,1:length(strsplit(dataOwner{jjj},'//'))) = strsplit(dataOwner{jjj},'//');
            end
        if any(strcmp(saveFileName,dataOwners),2)
            areDataUnlocked = 1; % master user identified
        end
        if areDataUnlocked < 0
            saveDataIn.Value = 1;
            saveCTdata = 0;
        end

        if dataMode == 1
            if downloadAllSectionsToggle == 1
                tempDirRow = find(strcmp(coralDir.textdata(2:end,1),coralName));
                areDataUnlocked = -coralDir.data(tempDirRow(1),9)+2;
            end
            if coreIn.Value ~= 1
                dirOut = findBandFiles(coralName,sectionName);
                if length(dirOut) > 0 && areDataUnlocked == 1
                    bandsMapsIn.Value = 1;
                    bandsMapsIn.String = [{'Download all'};dirOut'];
                    set(bandsMapsIn,'Visible','on')
                    set(htextBands,'Visible','on')
                    set(htextNoBands,'Visible','off')
                    set(htextBandsLocked,'Visible','off')
                elseif length(dirOut) > 0 && (areDataUnlocked==0||areDataUnlocked==2)
                    set(bandsMapsIn,'Visible','off')
                    set(htextBands,'Visible','off')
                    set(htextNoBands,'Visible','off')
                    set(htextBandsLocked,'Visible','on')
                elseif downloadAllSectionsToggle == 1 && areDataUnlocked == 1
                    set(bandsMapsIn,'Visible','off')
                    set(htextNoBands,'Visible','off')
                    set(htextBands,'Visible','off')
                    set(downloadDataIn,'Visible','on')
                else
                    set(bandsMapsIn,'Visible','off')
                    set(htextNoBands,'Visible','on')
                    set(htextBands,'Visible','off')
                    set(htextBandsLocked,'Visible','off')
                end
            end
        else
            if coralDir.data(thisSection,12) == 1
                set(startIn,'Visible','on','String','Open CT scan') % allow user to press "Go"
            else
                set(startIn,'Visible','on','String','Open 2D X-ray') % allow user to press "Go"
            end
            if (areDataUnlocked==0||areDataUnlocked==2)
                set(htextLocked,'Visible','on','String','output data are blocked for this core');
            elseif (areDataUnlocked==-1||areDataUnlocked==3)
                set(htextLocked,'Visible','on','String',{'output data and raw images are blocked for this core'});
            end
            set(checkSpeedIn,'Visible','on')
            thisFileSize = coralDir.data(thisSection,8);
            thisFileSizeText = sprintf('File Size: %i MB', thisFileSize);
            set(fileSizePreview,'String',thisFileSizeText)
            set(fileSizePreview,'Visible','on')
            %preview_printed = 1;
        end

    end

% Create "Preview" button to show quick image of core
previewIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Preview Core'},'Visible','off',...
    'Position',[720,180,250,50],'Units','normalized','BackgroundColor',[255, 156, 51]./255,'ForegroundColor',[0,0,0],'FontSize',14,'FontName','Arial','Callback',@preview_fun);

% initialize the preview axis;
h_map_cover = uiaxes(UserFig,'Units','Pixels','Position',[30 40 540 640],'Color',themeColor2,'Visible','off','Units','normalized');
h_map_cover.InteractionOptions.DatatipsSupported = 'off';
h_map_cover.InteractionOptions.ZoomSupported = "off";
h_map_cover.InteractionOptions.PanSupported = "off";
h_map_cover.Toolbar.Visible = 'off';
set(h_map_cover,'Xlim',[0,1],'YLim',[0,1],'XTick',[],'YTick',[],'xcolor',themeColor2,'ycolor',themeColor2)
patch(h_map_cover,[0,1],[0,1],themeColor2,'EdgeColor','none')
h_preview = uiaxes(UserFig,'Units','Pixels','Position',[30 40 540 640],'Color',themeColor2,'Visible','off','Units','normalized');
h_preview.InteractionOptions.DatatipsSupported = 'off';
h_preview.InteractionOptions.ZoomSupported = "off";
h_preview.InteractionOptions.PanSupported = "off";
h_preview.Toolbar.Visible = 'off';
p_preview = [];
preview_exists = 0;
preview_failed = 0;
screenshot_failed = 0;
viewScreenshotsIn = [];

    function preview_fun(src,event)

        if preview_failed == 0
            try mget(cache1,strcat('preview_images/',coralName,'_',sectionName,'.png'),fullfile(selpath,'my_corals'));

                set(h_map_cover,'Visible','on');
                patch(h_map_cover,[0,1],[0,1],themeColor2,'EdgeColor','none')

                %cache = sftp(ftp_ip,'CoralCache_beta','Corals1234'); %
                %cd(cache,'/hd1/CoralCache');

                preview_img = imread(fullfile(selpath,'my_corals','preview_images',strcat(coralName,'_',sectionName,'.png')));
                set(UserFig,'CurrentAxes',h_preview)
                set(h_preview,'Visible','on')
                p_preview = imagesc(preview_img);
                preview_exists = 1;
                %set(h_preview,'PlotBoxAspectRatio',[1 1 1])
                set(h_preview,'DataAspectRatio',[1 1 1])
                set(h_preview,'XTick',[],'YTick',[],'XLim',[0 length(preview_img(1,:,1))])

            catch

                try viewScreenshots
                catch
                    set(previewIn,'String',{'no preview';'available'})
                    preview_failed = 1;
                end
                if screenshot_failed == 1
                    set(previewIn,'String',{'no preview';'available'})
                    preview_failed = 1;
                end
            end
        end

    end

    function viewScreenshots(source,eventdata)
        screenshot_failed = 1;
        try
            set(viewScreenshotsIn,'Enable','off')
            drawnow
            thisSectionName = sectionName;
            thisCoralName = coralName;
            h_drive = '/hd1/';
            serverChoice = 1;

            dirRow = 0;
            didwematch = 0;
            while didwematch==0
                dirRow = dirRow+1;
                if strcmp('',thisSectionName)
                    isthismatch = strcmp(thisCoralName,coralDir.textdata{dirRow,1});
                else
                    isthismatch = strcmp(thisCoralName,coralDir.textdata{dirRow,1})...
                        & strcmp(thisSectionName,coralDir.textdata{dirRow,2});
                end
                if isthismatch==1
                    break
                end
            end

            sshotFig2 = uifigure('Visible','off','Position',[50,100,800,800],'Color','k');

            try
                if serverChoice == 1
                    cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password)
                elseif serverChoice == 2
                    cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password)
                elseif serverChoice == 3
                    cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                end
            catch
                try
                    if serverChoice == 1
                        cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password)
                    elseif serverChoice == 2
                        cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password)
                    elseif serverChoice == 3
                        cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                    end
                catch
                    try
                        connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                        connectionEstablished = 0;
                        for ij = 1:length(connectTimes)
                            if connectionEstablished == 0
                                if connectTimes(ij) == 1
                                    waitText = [' ',num2str(connectTimes(ij)),' minute.']
                                else
                                    waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                                end
                                set(lblOpeningError,'Units','Pixels','Visible','on','Position',[200,130,500,40],...
                                    'String',{'Error connecting to server.';strcat('Trying again in',waitText)},...
                                    'Units','normalized')
                                pause(connectTimes(ij)*60)
                                try
                                    if serverChoice == 1
                                        cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password)
                                    elseif serverChoice == 2
                                        cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password)
                                    elseif serverChoice == 3
                                        cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                    end
                                    connectionEstablished = 1;
                                    set(lblOpeningError,'Units','Pixels','Visible','off',...
                                        'Position',[200,150,500,20],'Units','normalized')
                                catch
                                end
                            end
                        end
                        if connectionEstablished == 0
                            zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                        end
                    catch
                        set(lblOpeningError,'Units','Pixels','Position',[200,130,500,40],'Visible','on',...
                            'String',{'Error connecting to server. (code 027)';'Please try again later.'},...
                            'Units','normalized')
                        while 1==1
                            pause
                        end
                    end
                end
            end

            set(sshotFig2,'Visible','off')

            if strcmp('',sectionName) % no sections
                % set directory to this coral's folder on server
                server_path = fullfile(h_drive,coralDir.textdata{dirRow,3},...
                    coralDir.textdata{dirRow,4},thisCoralName);
                if serverChoice == 1 || serverChoice == 3
                    server_path(double(server_path)==32) = char(95); % converts spaces to _
                end
            else % yes, sections
                % set directory to this sections's folder on server
                server_path = fullfile(h_drive,coralDir.textdata{dirRow,3},...
                    coralDir.textdata{dirRow,4},thisCoralName,thisSectionName);
                if serverChoice == 1 || serverChoice == 3
                    server_path(double(server_path)==32) = char(95); % converts spaces to _
                end
            end
            cd(cache2,server_path)
            dSnaps = dir(cache2);
            dirSnaps = [];
            for iii = 1:length(dSnaps)
                if length(strsplit(dSnaps(iii).name,'Screenshot'))==2
                    dirSnaps = [dirSnaps;dSnaps(iii).name];
                end
            end
            nSnaps = length(dirSnaps(:,1));
            for iii = 1:nSnaps
                mget(cache2,char(dirSnaps(iii,:)),refPath)
            end
            whichSnap = 1;
            thisImg = importdata(fullfile(refPath,char(dirSnaps(whichSnap,:))));
            sha0 = uiaxes(sshotFig2,'units','normalized','Position',[0 0 1 1]);
            set(sha0,'Color','k','xcolor','k','ycolor','k','XTick',[],'YTick',[])
            latestImg = imagesc(sha0,thisImg);

            closeSnapIn2 = uicontrol(sshotFig2,'Style','pushbutton',...
                'String',{'Close window'},'Visible','on',...
                'Position',[10,774,130,24],'Units','normalized','BackgroundColor',[255,96,92]./256,'FontSize',11,'FontName','Arial','Callback',@closeSnap2);
            nextSnapIn = uicontrol(sshotFig2,'Style','pushbutton',...
                'String',{'Next'},'Visible','on',...
                'Units','normalized','Position',[0.8,0.5,0.1,0.05],'BackgroundColor',[1 0.65 0],'FontSize',11,'FontName','Arial','Callback',@nextSnap);

            set(sshotFig2,'Visible','on')
            screenshot_failed = 0;

            %set(viewScreenshotsIn,'Enable','off')
        catch
            %set(viewScreenshotsIn,'Enable','on')
        end

        function closeSnap2(source,eventdata)
            close(sshotFig2)
            set(viewScreenshotsIn,'Enable','on')
        end

        function nextSnap(source,eventdata)
            whichSnap = whichSnap+1;
            if whichSnap>nSnaps
                whichSnap = 1;
            end
            thisImg = importdata(fullfile(refPath,char(dirSnaps(whichSnap,:))));
            delete(latestImg)
            latestImg = imagesc(sha0,thisImg);
        end
    end

% Create "View in 3D" button to allow users to view-onlyview3DBands
view3DBandsIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'View these bands in 3-D'},'Visible','off',...
    'Position',[720,110,250,50],'Units','normalized','BackgroundColor',[0.61,0.86,0.57],'ForegroundColor',[0,0,0],'FontSize',14,'FontName','Arial','Callback',@view3DBands);

view_only = 0;
saveName_previous = [];
% Function to begin view-only
    function view3DBands(src,event)

        view_only = 1;

        set(mainMenuIn,'Visible','off')
        set(htextBands,'Visible','off')
        set(bandsMapsIn,'Visible','off')
        set(view3DBandsIn,'Visible','off')

        saveName_previous = saveFileName;
        saveName0 = strsplit(chosenBandsName,'_');
        saveFileName = saveName0{1};

        start_fun

        view_only = 0;

        saveFileName = saveName_previous;

    end

% Create "Download calcification data" button
downloadDataIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Download growth data'},'Visible','off',...
    'Position',[720,50,250,50],'Units','normalized','BackgroundColor',[0.61,0.86,0.57],'ForegroundColor',[0,0,0],'FontSize',14,'FontName','Arial','Callback',@downloadData);

    function downloadData(src,event)

        set(downloadDataIn,'Visible','off')
        lblDownloading = uicontrol(UserFig,'Style','text','String','Downloading data from server...','Position',[720,50,250,50],...
            'BackgroundColor',themeColor2,'FontSize',10,'FontName','Arial','Units','normalized');
        pause(0.01)

        if downloadAllCoresToggle == 1
            downloadAllCoresDataInRegion
        elseif downloadAllSectionsToggle == 1
            downloadAllSectionsDataInCore
        elseif downloadAllBandsToggle == 1
            downloadAllDataInACore
        else
            getBandFile(coralName,sectionName,chosenBandsName);
        end

        %set(downloadDataIn,'Visible','on')
        set(lblDownloading,'Visible','off')
        pause(0.01)

        downloadAllCoresToggle = 0;
        downloadAllSectionsToggle = 0;
        downloadAllBandsToggle = 0;
    end

% Create "Go" button to begin download
startIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Go!'},'Visible','off',...
    'Position',[720,70,250,100],'Units','normalized','BackgroundColor',[242, 79, 38]./256,'ForegroundColor',[0,0,0],'FontSize',14,'FontName','Arial','Callback',@start_fun);

% Function to begin download
    function start_fun(src,event)
        dirRow = []; % this stores the row in directory that user chose

        set(lblMapClick,'Visible','off')
        set(lblOpeningError,'Visible','off')
        set(startIn,'Visible','off')
        set(htextLocked,'Visible','off')
        lblDownloading = uicontrol(UserFig,'Style','text','String','Downloading data from server...','Position',[200,150,500,20],...
            'BackgroundColor',themeColor2,'FontSize',10,'FontName','Arial','Units','normalized');

        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            dispVid = uihtml(UserFig);
            dispVid.Position = [200,250,500,500];
            rng('shuffle')
            %
            rand_vid = round(rand(1)*(n_loading_vids-1))+1;
            dispVid.HTMLSource = (fullfile('loading_movies',strcat('core_movie',num2str(rand_vid),'.html')));
            lblVideo = uicontrol(UserFig,'Style','text','String',videoLabel(rand_vid),'Position',[200,250,500,20],...
                'FontSize',10,'FontName','Arial','Units','normalized','BackgroundColor','none');
        end

        pause(0.001)

        % Turn visibility off for all the core-selection drop-down menus
        set(regionIn,'Visible','off')
        set(subRegionIn,'Visible','off')
        set(coreIn,'Visible','off')
        set(UserSetIn,'Visible','off')
        set(startIn,'Visible','off')
        set(htextLocked,'Visible','off')
        set(previewIn,'Visible','off')
        set(htextUser,'Visible','off')
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            set(saveLogin, 'Visible','off')
            set(userProfileIn,'Visible','off')
            set(coreDirIn,'Visible','off')
        end
        set(htextSave,'Visible','off')
        set(saveDataIn,'Visible','off')
        try
            set(sectionIn,'Visible','off')
        catch
        end
        set(openLastIn,'Visible','off')
        set(htextsubRegion,'Visible','off')
        set(htextCore,'Visible','off')
        set(htextSection,'Visible','off')
        set(htextRegion,'Visible','off')
        set(coreIn,'Visible','off')
        set(openChooseIn, 'Visible','off')
        set(fileSizePreview,'Visible','off')
        set(checkSpeedIn,'Visible','off')
        set(dataModeLabel,'Visible','off');
        set(getDataIn,'Visible','off')
        set(downloadTimePreview,'Visible','off')
        set(SubmitDataIn,'Visible','off')
        set(calibCurveIn,'Visible','off')
        set(htextLink4,'Visible','off')

        delete(h_map1)
        delete(h_map2)

        map_cover = patch(h_map_cover,[0,1],[0,1],themeColor2,'EdgeColor','none');
        set(h_preview,'Visible','off')
        delete(h_preview)
        if preview_exists == 1
            delete(p_preview);
            preview_exists = 0;
        end

        pause(0.01)

        % store as text how we will name the output file, which is just the
        % user's initials followed by an underscore
        saveName = strcat(saveFileName,'_');

        % pass coral and section name to 'findCoral' function to launch
        % download from the server
        try findCoral(coralName,sectionName);
        catch
            try
                connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                connectionEstablished = 0;
                for ij = 1:length(connectTimes)
                    if connectionEstablished == 0
                        if connectTimes(ij) == 1
                            waitText = [' ',num2str(connectTimes(ij)),' minute.']
                        else
                            waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                        end
                        set(lblDownloading,'Units','Pixels','Visible','on','Position',[200,130,500,40],...
                            'String',{'Error connecting to server.';strcat('Trying again in',waitText)},...
                            'Units','normalized')
                        pause(connectTimes(ij)*60)
                        try
                            findCoral(coralName,sectionName);
                            connectionEstablished = 1;
                            set(lblDownloading,'Units','Pixels','Visible','off',...
                                'Position',[200,150,500,20],'Units','normalized')
                        catch
                        end
                    end
                end
                if connectionEstablished == 0
                    zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                end
            catch
                set(lblDownloading,'Units','Pixels','Position',[200,130,500,40],'Visible','on',...
                    'String',{'Error finding data on server. (code 024)';'Please email support@coralct.org.'},...
                    'Units','normalized')
                %set(lblDownloading,'String','Error connecting to server (code 005). Please quit and try again.')
                pause
                while 1 ~= 2
                    pause
                end
            end
        end

        set(lblDownloading,'Visible','off')

        % load the dicom data from local drive into this Matlab session
        if ct == 1
            % turn on visibility of loading bar (called 'ha3')
            set(ha3,'Visible','on')
            try loadData
            catch
                try loadData
                catch
                    set(lblOpeningError,'Visible','on','String','Error in CT dataset (code 009)')
                    pause
                    while 1 ~= 2
                        pause
                    end
                end
            end
        else
            set(ha3,'Visible','on')
            try loadXray
            catch
                pause(3)
                try loadXray
                catch
                    set(lblOpeningError,'Visible','on','String','Error in X-ray dataset (code 010)')
                    pause
                    while 1 ~= 2
                        pause
                    end
                end
            end
        end

        % Choose core filter, which is based on the genus
        chooseCoreFilter

        % turn off loading bar once all image data in Matlab
        set(ha3,'Visible','off')
        delete(ha3)
        delete(h_map_cover)
        delete(p1)
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            delete(dispVid)
            delete(lblVideo)
        end

        % launch the main GUI for interacting with the scan
        core_run
    end

% Button for accessing data:
getDataIn = uicontrol(UserFig,'Style','pushbutton',...
    'String',{'Access data'},'Visible','off',...
    'Position',[680,660,160,60],'Units','normalized','BackgroundColor',[255, 237, 85]./255,'FontSize',14,'FontName','Arial','Callback',@getData);

dataMode = 0;
dataModeLabel = uicontrol(UserFig,'Style','text',...
    'String',{'In data access mode'},'Visible','off',...
    'Position',[680,670,320,30],'Units','normalized','BackgroundColor',[1.00,0.81,0.58],'FontSize',14,'FontName','Arial','Callback',@openLast);

% Get data menu
    function getData(src,event)

        dataMode = 1;

        set(mainMenuIn, 'Visible','on')
        set(openChooseIn, 'Visible','off')
        set(openLastIn, 'Visible','off')
        set(getDataIn, 'Visible','off')
        set(saveDataIn, 'Visible','off')
        set(htextUser, 'Visible','off')
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            set(saveLogin, 'Visible','off')
            set(userProfileIn,'Visible','off')
            set(coreDirIn,'Visible','off')
        end
        set(UserSetIn, 'Visible','off')
        set(htextSave, 'Visible','off')
        set(dataModeLabel, 'Visible','on')
        set(coreIn,'Visible','off')
        set(htextCore,'Visible','off')
        set(view3DBandsIn,'Visible','off') % allow user to preview core
        set(downloadDataIn,'Visible','off') % allow user to press "Go"
        set(previewIn,'Visible','off') % allow user to preview core
        set(fileSizePreview,'Visible','off')
        set(checkSpeedIn,'Visible','off')
        set(htextsubRegion,'Visible','off')
        set(htextSection,'Visible','off')
        set(subRegionIn,'Visible','off')
        set(SubmitDataIn,'Visible','off')
        set(calibCurveIn,'Visible','off')
        set(startIn,'Visible','off')
        set(htextLocked,'Visible','off')
        try
            set(sectionIn,'Visible','off')
        catch
        end

    end


% Build main GUI:

% turn ha3 on
ha3 = uiaxes(UserFig,'Units','Pixels','Position',[200,160,500,50],'Units','normalized','Visible','off');
ha3.InteractionOptions.DatatipsSupported = 'off';
ha3.InteractionOptions.ZoomSupported = "off";
ha3.InteractionOptions.PanSupported = "off";
ha3.Toolbar.Visible = 'off';
hold(ha3,'on')
set(ha3,'Xtick',[],'YTick',[],'XLim',[0 1],'YLim',[0 1])

p1 = [];
p_prop = [];

UserFig.Name = 'Welcome to CoralCT'; % welcome message at top of figure
UserFig.Resize = 'off'; % prevent resizing

% Move the GUI to the center of the screen.
movegui(UserFig,'center')

% Make the GUI visible.
UserFig.Visible = 'on';

areWeGoingBack = 0;

% Function for interacting with scans:
    function core_run

        set(UserFig,'Color','k')

        areWeEditing = 0; % toggle for whether an existing file for this core was found
        startingRotation = 0; % can use this to define initial rotation, just 0 for now...
        x_ang = 0; % this stores the rotation angle of the scan
        totBands = 0; % this stores total number of defined bands
        xIntersect = [];
        yIntersect = [];

        % check if we find an existing, work-in-progress file for this core
        if strcmp(sectionName,'')
            name2search = strcat(saveName,coralName);
        else
            name2search = strcat(saveName,coralName,'_',sectionName);
        end
        if exist(fullfile(fileOpen,strcat(name2search,'.mat')),'file')
            load(fullfile(fileOpen,strcat(name2search,'.mat')),'userBands','x_ang','contra','proj','thick')
            try load(fullfile(fileOpen,strcat(name2search,'.mat')),'h3_width','h3_std','h3_defined')
            catch
            end
            areWeEditing = 1;
            if ct == 1
                totBands = length(find(max(max(userBands)))>0);
            else
                totBands = length(find(max(userBands))>0);
            end
            % rotate bands to match the core data
            if abs(x_ang)>0 && totBands>0 && areWeGoingBack == 0
                hold_bands = zeros(length(userBands(:,1,1)),length(userBands(1,:,1)),totBands+1);
                hold_bands(:,:,2:end) = userBands(:,:,1:totBands);
                hold_bands = imrotate3(hold_bands,-x_ang,[0,0,1],'nearest','crop','FillValues',0);
                userBands(:,:,1:totBands) = hold_bands(:,:,2:end);
                hold_bands = [];
                x_ang = 0;
            end
        end

        % loaded everything, can now delete image data for view only
        if exist(fullfile(selpath,'my_corals','current_scan_view_only'),'dir')
            rmdir(fullfile(selpath,'my_corals','current_scan_view_only'),'s')
        end
        if exist(fullfile(selpath,'my_corals','current_scan_view_only'),'dir')
            rmdir(fullfile(selpath,'my_corals','current_scan_view_only'),'s')
        end

        % if unlocked set to -1, delete image data
        if (areDataUnlocked==-1||areDataUnlocked==3)
            if exist(fullfile(selpath,'my_corals','current_scan','Xray'),'dir')
                rmdir(fullfile(selpath,'my_corals','current_scan','Xray'),'s')
                mkdir(fullfile(selpath,'my_corals','current_scan','Xray'))
                delete(fullfile(selpath,'my_corals','current_scan','xray.tiff'))
            end
            if exist(fullfile(selpath,'my_corals','current_scan','dicoms'),'dir')
                rmdir(fullfile(selpath,'my_corals','current_scan','dicoms'),'s')
                mkdir(fullfile(selpath,'my_corals','current_scan','dicoms'))
                delete(fullfile(selpath,'my_corals','current_scan','dicoms.zip'))
            end
        end

        % initial setup before GUI
        j = 0; % counter for which band we're working on
        maxBands = 200; % initialized size of storage matrix, can adjust if needed

        % If we aren't editing an existing file, initialize userBands to
        % store 3-D map of user's identified band locations
        if areWeEditing == 0
            if ct == 1
                userBands = zeros(row,col,maxBands); % matrix for storing band inputs
            else
                userBands = zeros(col,maxBands); % matrix for storing band inputs
            end
        end
        haveLims = 0; % toggle for whether user has zoomed in on image
        [rowMesh ,colMesh] = meshgrid(1:row,1:col); % mesh for interpolating

        % Initialize some variables
        ldbDraw = zeros(layers,row);
        if areWeEditing == 0
            thick_mm = 3;
            thick = round(thick_mm/2/hpxS);
            contra = [300 2300];
            proj = 'mean';
        else
            try thick_mm = thick*2*hpxS;
            catch
                thick_mm = 3;
                thick = round(thick_mm/2/hpxS);
                contra = [300 2300];
                proj = 'mean';
            end
        end
        x_ang_new = 0;
        circle_j = j;
        temp_bands = zeros(row,col);
        temp_bands_idx = zeros(row,col);
        newRot = 0;
        if ct ~= 1
            thick_mm = 5;
        end

        if ct == 1
            % Find approximate location of core within the scan:

            % sample of core, just halfway down the scan
            samp = round(layers/2);

            % filter image to smooth pore spaces
            filteredXcore(:,:) = imfilter(X(:,:,samp), h2, 'replicate');

            % convert to binary image
            coralSamp = imbinarize((filteredXcore-min(min(filteredXcore)))/max(max(filteredXcore-min(min(filteredXcore)))).*255);

            % find locations of coral (value of 1 in binary)
            [r,c] = find(coralSamp); % r and c are rows and columns of coral pixels

            % determind outer bounds of core:
            [val,loc] = max(r);
            topMost = [c(loc),r(loc)];
            [val,loc] = min(r);
            bottomMost = [c(loc),r(loc)];
            [val,loc] = max(c);
            rightMost = [c(loc),r(loc)];
            [val,loc] = min(c);
            leftMost = [c(loc),r(loc)];

            % midpoint of the core in the scan
            center = [round((rightMost(1)+leftMost(1))/2),round((topMost(2)+bottomMost(2))/2)];

            % our starting point for a slice (i.e. slab) is just this middle
            % location
            slab = round(mean(center));

            % convert from pixels to distance using hpxS variable (which is
            % horizontal pixel spacing)
            slabPos = slab*hpxS;

        end

        % set up GUI

        % Initialize these labels:
        textClick = sprintf('Next band will be band %s',num2str(round(j+1)));
        lblClick = uicontrol(UserFig,'Style','text','String',textClick,'Position',[50,680,230,25],...
            'BackgroundColor','none','FontSize',14,'FontName','Arial','Units','normalized',...
            'ForegroundColor',themeColor1);
        lblCheck = uicontrol(UserFig,'Style','text','String','Return to band 1? Click above','Position',[250,680,500,25],'FontSize',18,'FontName','Arial','Units','normalized');
        set(lblCheck,'Visible','off')
        lblLoading = uicontrol(UserFig,'Style','text','String','LOADING..','BackgroundColor','none',...
            'Position',[350,655,300,35],'FontSize',18,'FontName','Arial','Units','normalized',...
            'ForegroundColor','w');
        set(lblLoading,'Visible','off')

        % Function for response to user's image brightness selection
        function brightness_Callback(source,eventdata)
            functionsOff
            currentC = get(ha,'CLim'); % get current contrast
            currentRange = max(currentC)-min(currentC); % current color range

            % the next two lines adjust the overall image color range based
            % on the new selection for brightness, such that the brightness
            % selection is the middle of the displayed color range
            contra(1) = -brightnessIn.Value-currentRange/2; % apply lower bound of contrast
            contra(2) = -brightnessIn.Value+currentRange/2; % apply upper bound of contrast

            set(ha,'CLim',contra); % set image color range
            if ct == 1
                set(ha2,'CLim',contra); % set image color range
            end
            set(lblBright,'String',strcat(num2str(round(-brightnessIn.Value)),' HU'))
            %delete(lblBright); % delete existing brightness label

            % Create new brightness label:
            % textBright = sprintf('%s HU',num2str(round(-brightnessIn.Value))); % CAN BE DELETED?
            %lblBright = uicontrol(UserFig,'Style','text','String',strcat(num2str(round(-brightnessIn.Value)),' HU'),...
            %    'Position',[850,590,83,25],'Units','normalized','BackgroundColor',themeColor1,'FontSize',14,'FontName','Arial');
            functionsOn
        end

        % Create slider bar for adjusting image brightness
        %otsu_thresh = otsuthresh(filteredXcore(:)-min(filteredXcore(:)));
        %best_thresh = min(filteredXcore(:))-otsu_thresh*range(filteredXcore(:));
        %brightnessIn = uicontrol(UserFig,'Style','slider',...
        %    'Position',[725,560,265,25],'Units','normalized',...
        %    'Min', -2000,'Max', 1500,'Value', -median(contra),'Callback', @brightness_Callback);
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            brightnessIn = uislider(UserFig,'Position',[725,585,265,25],...
                'Limits',[-2000, 1500],'Value', -median(contra),...
                'FontColor',themeColor1,'MajorTicks',[],'MinorTicks',[],...
                'ValueChangedFcn', @brightness_Callback);
        else
            brightnessIn = uicontrol(UserFig,'Style','slider',...
                'Position',[725,565,265,25],'Units','normalized',...
                'Min', -2000,'Max', 1500,'Value', -median(contra),'Callback', @brightness_Callback);
        end

        % Label for current brightness setting
        lblBright = uicontrol(UserFig,'Style','text','String',strcat(num2str(round(-brightnessIn.Value)),' HU'),...
            'Position',[850,595,83,23],'Units','normalized','ForegroundColor',themeColor1,...
            'BackGroundColor','none','FontSize',12,'FontName','Arial');

        % Function for response to user's image contrast selection
        function contrast_Callback(source,eventdata)
            functionsOff
            currentC = get(ha,'CLim'); % get current contrast
            currentMean = mean(currentC); % middle of contrast range

            % next two lines set the upper and lower bounds for the
            % contrast based on mid-point of existing contrast (i.e. the
            % brightness) and the user's selection of contrast:
            contra(1) = currentMean+contrastIn.Value/2;
            contra(2) = currentMean-contrastIn.Value/2;

            set(ha,'CLim',contra);  % set image color range
            if ct == 1
                set(ha2,'CLim',contra);  % set image color range
            end
            set(lblContrast,'String',strcat(num2str(round(-contrastIn.Value)),' HU'))
            functionsOn
        end

        % Create slider bar for adjusting image contrast
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            contrastIn = uislider(UserFig,'Position',[725,535,265,25],...
                'Limits',[-3000, -10],'Value', -range(contra),...
                'FontColor',themeColor1,'MajorTicks',[],'MinorTicks',[],...
                'ValueChangedFcn', @contrast_Callback);
        else
            contrastIn = uicontrol(UserFig,'Style','slider',...
                'Position',[725,515,265,25],'Units','normalized',...
                'Min', -3000,'Max', -10,'Value', -range(contra),'Callback', @contrast_Callback);
        end


        % Label for current contrast setting
        lblContrast = uicontrol(UserFig,'Style','text','String',strcat(num2str(round(-contrastIn.Value)),' HU'),...
            'Position',[850,545,83,23],'Units','normalized','ForegroundColor',themeColor1,...
            'BackGroundColor','none','FontSize',12,'FontName','Arial');

        % Function for response to user's image contrast selection
        function thickness_Callback(source,eventdata)
            functionsOff
            % 'thick' stores pixels into and out of screen to incorporate
            % into image display, simply update this below. The value of
            % 'hpxS' converts horizontal distance to pixels, so the user
            % selects distance (mm) and 'thick' stores this as pixels
            set(lblThick,'String',strcat(num2str(round(thickIn.Value*10)/10),' mm'))
            thick = round(thickIn.Value/2/hpxS)-1; % in pixels

            if areWeSettingDefaults == 0
                if smoothedBandsDrawn == 0
                    drawAndLabelBands
                else
                    drawAndLabelSmoothedBands
                end
            end
            functionsOn
        end

        % Create slider bar for adjusting slice thickness
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            if thick_mm<1
                thick_mm = 1;
            end
            thickIn = uislider(UserFig,'Position',[725,473,265,25],...
                'Limits',[1 10],'Value', thick_mm,...
                'FontColor',themeColor1,'MajorTicks',1:10,'MinorTicks',[],...
                'ValueChangedFcn', @thickness_Callback);
        else
            thickIn = uicontrol(UserFig,'Style','slider',...
                'Position',[725,453,265,25],'Units','normalized',...
                'Min', 1,'Max', 10,'Value', thick_mm,'Callback', @thickness_Callback);
        end

        % Label for current thickness setting
        lblThick = uicontrol(UserFig,'Style','text','String',strcat(num2str(round(thickIn.Value*10)/10),' mm'),...
            'Position',[850,484,83,23],'Units','normalized','ForegroundColor',themeColor1,...
            'BackGroundColor','none','FontSize',12,'FontName','Arial');

        % Function for response to user's image position selection
        function position_Callback(source,eventdata)
            functionsOff
            % 'slab' stores the pixel at the center of the displayed slice.
            % We just update this below (user supplies in mm, 'slab' stores
            % in pixels)
            slab = round(positionIn.Value/hpxS);
            set(lblPos,'String',strcat(num2str(round(positionIn.Value)),' mm'))

            % update the image display
            if areWeSettingDefaults == 0
                if smoothedBandsDrawn == 0
                    drawAndLabelBands
                else
                    drawAndLabelSmoothedBands
                end
            end
            functionsOn
        end

        % Create slider bar for adjusting slice position
        if ct == 1
            if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
                try positionIn = uislider(UserFig,'Position',[725,385,265,25],...
                    'Limits',[3+ceil(thick*hpxS/2) round(col*hpxS)-3-floor(thick*hpxS/2)],...
                    'Value', slabPos,'MinorTicks',[],...
                    'FontColor',themeColor1,...
                    'ValueChangedFcn', @position_Callback);
                catch
                    positionIn = uislider(UserFig,'Position',[725,385,265,25],...
                    'Limits',[thick_mm/2+thick*hpxS/2, round(col*hpxS)-thick_mm/2-thick*hpxS/2],...
                    'Value', slabPos,'MinorTicks',[],...
                    'FontColor',themeColor1,...
                    'ValueChangedFcn', @position_Callback);
                end
            else
                positionIn = uicontrol(UserFig,'Style','slider',...
                    'Position',[725,365,265,25],'Units','normalized',...
                    'Min', 1+ceil(thick*hpxS/2),'Max', round(col*hpxS)-1-floor(thick*hpxS/2),'Value', slabPos,'Callback', @position_Callback);
            end
        else
            positionIn = uicontrol(UserFig,'Style','slider',...
                'Position',[725,380,265,25],'Units','normalized',...
                'Min', 1,'Max', 3,'Value', 2,'Callback', @position_Callback);
        end

        % Label for current position setting
        lblPos = uicontrol(UserFig,'Style','text','String',strcat(num2str(round(positionIn.Value)),' mm'),...
            'Position',[850,396,83,23],'Units','normalized','ForegroundColor',themeColor1,...
            'BackGroundColor','none','FontSize',12,'FontName','Arial');

        % Function for response to user's image rotation selection
        function rotation_Callback(source,eventdata)

            functionsOff

            set(lblRot,'String',strcat(num2str(round(rotationIn.Value)),' °'))

            newRot = 1; % toggle to identify that this is a new rotation
            newRotTotBands = totBands; % WHAT DOES THIS DO?

            xs = get(ha,'XLim'); % store current x limit of display
            ys = get(ha,'YLim'); % store current y limit of display
            haveLims = 1; % toggle to store that we've saved these

            % turn on label to show this is loading because it can take a
            % while
            set(lblLoading,'Visible','on')

            % short pause because this is needed to enable the visible on
            % to take effect
            pause(0.01)

            % save previous rotation angle (currently in 'x_ang_new');
            x_ang_old = x_ang_new;

            % update 'x_ang_new' with user's selected rotation
            x_ang_new = rotationIn.Value;

            % calculate difference between previous and new rotation
            x_ang_dif = x_ang_new-x_ang_old;

            % rotate 'X' (the CT scan data)
            X = imrotate3(X,x_ang_dif,[0,0,1],'linear','crop','FillValues',-1000);

            % rotate userBands

            hold_bands = zeros(row,col,length(userBands(1,1,:))+1);
            hold_bands(:,:,2:end) = userBands;
            hold_bands = imrotate3(hold_bands,x_ang_dif,[0,0,1],'nearest','crop','FillValues',0);
            userBands = hold_bands(:,:,2:end);
            hold_bands = [];
            %userBands = imrotate3(userBands,x_ang_dif,[0,0,1],'nearest','crop','FillValues',0);

            % store our current rotation as 'x_ang'
            x_ang = x_ang_new;

            % display intersects of existing bands into this new view
            if smoothedBandsDrawn == 0
                drawAndLabelBands
            else
                drawAndLabelSmoothedBands
            end

            %haveLims = 0;

            % turn off 'Loading' label
            set(lblLoading,'Visible','off')

            functionsOn

        end

        % Create slider bar for adjusting slice position
        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            rotationIn = uislider(UserFig,'Position',[725,297,265,25],...
                'Limits',[0 180],'MajorTicks',0:15:180,'MinorTicks',[],...
                'Value', startingRotation,...
                'FontColor',themeColor1,...
                'ValueChangedFcn', @rotation_Callback);
        else
            rotationIn = uicontrol(UserFig,'Style','slider',...
                'Position',[725,277,265,25],'Units','normalized',...
                'Min', 0,'Max',180,'Value', startingRotation,'Callback', @rotation_Callback);
        end

        % Label for current rotation setting
        lblRot = uicontrol(UserFig,'Style','text','String',strcat(num2str(round(rotationIn.Value)),' °'),...
            'Position',[850,308,83,23],'Units','normalized','ForegroundColor',themeColor1,...
            'BackGroundColor','none','FontSize',12,'FontName','Arial');

        % Function for response to user's image projection selection
        function projection_Callback(source,eventdata)
            str = source.String; % string of selection
            valProj = source.Value;
            switch str{valProj}
                case 'Mean'
                    proj = 'mean'; % mean of pixels
                case 'Min'
                    proj = 'min'; % min of pixels
                case 'Max'
                    proj = 'max'; % max of pixels
            end
            if smoothedBandsDrawn == 0
                drawAndLabelBands
            else
                drawAndLabelSmoothedBands
            end
        end

        if strcmp(proj,'mean')
            projInValue = 1;
        elseif strcmp(proj,'min')
            projInValue = 2;
        else
            projInValue = 3;
        end

        % Create drop-down menu for choosing image projection
        projIn = uicontrol(UserFig,'Style','popupmenu',...
            'String',{'Mean','Min','Max'},'Value',projInValue,'Position',[850,628,150,30],...
            'Units','normalized','BackgroundColor',themeColor1,'FontSize',12,'FontName','Arial','Callback',@projection_Callback);

        % Print text for all of the slider bars:
        htext1 = uicontrol(UserFig,'Style','text','String','Projection:',...
            'Position',[725,628,120,23],'ForegroundColor',themeColor1,...
            'BackGroundColor','none','FontSize',12,'FontName','Arial','Units','normalized');
        htext2 = uicontrol(UserFig,'Style','text','String','Brightness:',...
            'Position',[725,596,120,23],'ForegroundColor',themeColor1,...
            'BackGroundColor','none','Units','normalized','FontSize',12,'FontName','Arial');
        htext3 = uicontrol(UserFig,'Style','text','String','Contrast:',...
            'Position',[725,546,120,23],'Units','normalized','ForegroundColor',themeColor1,...
            'BackGroundColor','none','FontSize',12,'FontName','Arial');
        htext4 = uicontrol(UserFig,'Style','text','String','Slice Thickness:',...
            'Position',[725,484,120,23],'Units','normalized','ForegroundColor',themeColor1,...
            'BackGroundColor','none','FontSize',12,'FontName','Arial');
        htext5 = uicontrol(UserFig,'Style','text','String','Slice Location:',...
            'Position',[725,396,120,23],'Units','normalized','ForegroundColor',themeColor1,...
            'BackGroundColor','none','FontSize',12,'FontName','Arial');
        htext6 = uicontrol(UserFig,'Style','text','String','Slice Rotation:',...
            'Position',[725,308,120,23],'Units','normalized','ForegroundColor',themeColor1,...
            'BackGroundColor','none','FontSize',12,'FontName','Arial');
        % Create option for jumping to a specific band

        % text to indicate this:
        htext7 = uicontrol(UserFig,'Style','text','String','Jump to band:',...
            'Position',[350,752,150,25],'Units','normalized','FontSize',12,'ForegroundColor',[0.78,0.94,0.54],'BackgroundColor','none','FontName','Arial');

        % Create editing bar for user to type in number
        jumpSetIn = uicontrol(UserFig,'Style','Edit','BackGroundColor',[0.7 0.7 0.7],...
            'Position',[350,725,150,25],'Units','normalized','FontName','Arial','Callback', @jumpSet_Callback);

        % Create button for user to press to launch to jump to chosen band
        jumpIn = uicontrol(UserFig,'Style','pushbutton','String',{'Apply'},...
            'Position',[350,690,150,25],'Units','normalized','BackgroundColor',[0.78,0.94,0.54],'FontName','Arial','Callback', @jump_Callback);

        % Function for response to user's selection of band to jump to
        function jumpSet_Callback(source,eventdata)
            jump2band = str2num(jumpSetIn.String); % just store it here
        end

        % Function for response to user's choice to jump to a band
        function jump_Callback(source,eventdata)

            % set the band counter ('j') to the band before the selected
            % one because when user clicks "next band", then j is advanced
            % by 1

            try
                if isfinite(jump2band) && jump2band==floor(jump2band)
                    disableAll
                    j = jump2band-1;

                    % update label that says what the next band will be
                    textClick = sprintf('Next band will be band %s',num2str(round(j+1)));
                    set(lblClick,'String',textClick)

                    set(lblDeleted,'Visible','off')

                    if ct
                        if smoothedBandsDrawn == 0
                            drawAndLabelBands
                        else
                            drawAndLabelSmoothedBands
                        end
                    else
                        if smoothedBandsDrawn == 0
                            drawAndLabelBandsXray
                        else
                            drawAndLabelSmoothedBandsXray
                        end
                    end
                    enableAll
                end
            catch
            end
        end

        if ~ct
            set(thickIn,'Visible','off')
            set(lblThick,'Visible','off')
            set(positionIn,'Visible','off')
            set(lblPos,'Visible','off')
            set(rotationIn,'Visible','off')
            set(lblRot,'Visible','off')
            set(projIn,'Visible','off')
            set(htext1,'Visible','off')
            set(htext4,'Visible','off')
            set(htext5,'Visible','off')
            set(htext6,'Visible','off')
        end


        % Create button for user to press to launch to jump to chosen band
        flipBandsIn = uicontrol(UserFig,'Style','pushbutton','String',{'flip bands'},'Visible','off',...
            'Position',[550,560,150,25],'Units','normalized','BackgroundColor',[0.58,0.97,0.82],'FontName','Arial','Callback', @flipBands_Callback);

        function flipBands_Callback(source,eventdata)
            userBands(userBands==0) = NaN;
            userBands = layers-userBands;
            userBands(isnan(userBands)) = 0;
            if smoothedBandsDrawn == 0
                drawAndLabelBands
            else
                drawAndLabelSmoothedBands
            end
        end

        twistBandsIn = uicontrol(UserFig,'Style','pushbutton','String',{'rotate bands'},'Visible','off',...
            'Position',[550,500,150,25],'Units','normalized','BackgroundColor',[0.58,0.97,0.82],'FontName','Arial','Callback', @rotateBands_Callback);

        function rotateBands_Callback(source,eventdata)
            userBands = permute(userBands,[2,1,3]);
            if smoothedBandsDrawn == 0
                drawAndLabelBands
            else
                drawAndLabelSmoothedBands
            end
        end

        swapBandsIn = uicontrol(UserFig,'Style','pushbutton','String',{'swap order'},'Visible','off',...
            'Position',[550,440,150,25],'Units','normalized','BackgroundColor',[0.58,0.97,0.82],'FontName','Arial','Callback', @swapBands_Callback);

        function swapBands_Callback(source,eventdata)
            userBands = flipdim(userBands,3);
            if smoothedBandsDrawn == 0
                drawAndLabelBands
            else
                drawAndLabelSmoothedBands
            end
        end

        shiftBandsIn = uicontrol(UserFig,'Style','edit','Visible','off',...
            'Position',[550,360,150,25],'Units','normalized','Callback', @shiftBands_Callback);

        shift_new = 0;
        function shiftBands_Callback(source,eventdata)
            % save previous rotation angle (currently in 'x_ang_new');
            shift_old = shift_new;

            % update 'x_ang_new' with user's selected rotation
            shift_new = str2num(shiftBandsIn.String);

            % calculate difference between previous and new rotation
            shift_dif = shift_new-shift_old;

            userBands(userBands>0) = userBands(userBands>0)+shift_dif;

            if smoothedBandsDrawn == 0
                drawAndLabelBands
            else
                drawAndLabelSmoothedBands
            end
        end

        if previous_bands_fixing_mode == 1
            set(flipBandsIn,'Visible','on')
            set(swapBandsIn,'Visible','on')
            set(twistBandsIn,'Visible','on')
            set(shiftBandsIn,'Visible','on')
        end


        % Create option for erasing a specific band to redo it

        % text to indicate this:
        htext8 = uicontrol(UserFig,'Style','text','String','Redo band:',...
            'Position',[550,752,150,25],'Units','normalized',...
            'ForegroundColor',[0.58,0.97,0.82],...
            'FontSize',12,'FontName','Arial','BackGroundColor','none');

        % Create editing bar for user to type in number
        eraseSetIn = uicontrol(UserFig,'Style','Edit','BackGroundColor',[0.7 0.7 0.7],...
            'Position',[550,725,150,25],'Units','normalized','FontName','Arial','Callback', @eraseSet_Callback);

        % Initialize a label for this
        lblErased = uicontrol(UserFig,'Style','text','String',sprintf('Erased band %s',eraseSetIn.String),'Position',[600,680,300,35],'FontSize',18,'FontName','Arial','Units','normalized');
        set(lblErased,'Visible','off')

        % Create button for user to press to launch to jump to chosen band
        eraseIn = uicontrol(UserFig,'Style','pushbutton','String',{'Apply'},...
            'Position',[550,690,150,25],'Units','normalized','BackgroundColor',[0.58,0.97,0.82],'FontName','Arial','Callback', @erase_Callback);

        %create option for deleting a band completely

        %text to indicate this:
        htext8b = uicontrol(UserFig,'Style','text','String','Delete band:',...
            'Position',[950,752,150,25],'Units','normalized','ForegroundColor',[0.45,0.94,0.91],...
            'FontSize',12,'FontName','Arial','BackgroundColor','none');

        % Create editing bar for user to type in number
        deleteSetIn = uicontrol(UserFig,'Style','Edit','BackGroundColor',[0.7 0.7 0.7],...
            'Position',[950,725,150,25],'Units','normalized','FontName','Arial','Callback', @deleteSet_Callback);

        % Initialize a label for this
        lblDeleted = uicontrol(UserFig,'Style','text','String',sprintf('Deleted band %s',deleteSetIn.String),'Position',[350,680,300,35],'FontSize',18,'FontName','Arial','Units','normalized');
        set(lblDeleted,'Visible','off')

        % Create button for user to press to launch to jump to chosen band
        deleteIn = uicontrol(UserFig,'Style','pushbutton','String',{'Apply'},...
            'Position',[950,690,150,25],'Units','normalized','BackgroundColor',[0.45,0.94,0.91],'FontName','Arial','Callback', @delete_Callback);

        % Function for response to user's selection of band to erase and
        function eraseSet_Callback(source,eventdata)
            band2erase = str2num(eraseSetIn.String); % simply store it here
        end

        %Function for response to user's selection of band to delete
        function deleteSet_Callback(source,eventdata)
            band2delete = str2num(deleteSetIn.String); % simply store it here
        end

        % Function for response to user's choice to redo a band
        function erase_Callback(source,eventdata)

            try
                if isfinite(band2erase) && band2erase==floor(band2erase)
                    disableAll

                    % set all band locations to zero for this band
                    if ct == 1
                        userBands(:,:,band2erase) = 0;
                    else
                        userBands(:,band2erase) = 0;
                    end

                    if length(xIntersect) >= band2erase
                        xIntersect(band2erase) = 0;
                        yIntersect(band2erase) = 0;
                    end

                    j = band2erase-1;

                    % update label that says what the next band will be
                    textClick = sprintf('Next band will be band %s',num2str(round(j+1)));
                    set(lblClick,'String',textClick)

                    % show a label that the band was deleted
                    delete(lblErased) % delete this label if it already exists

                    % display label confirming the band was deleted
                    lblErased = uicontrol(UserFig,'Style','text','String',sprintf('Erased band %s',eraseSetIn.String),'Position',[190,330,300,60],'BackgroundColor',[0.97,0.90,0.61],'FontWeight','bold','FontSize',18,'FontName','Arial','Units','normalized');
                    set(lblErased,'Visible','on')

                    % update image display
                    if ct
                        if smoothedBandsDrawn == 0
                            drawAndLabelBands
                        else
                            drawAndLabelSmoothedBands
                        end
                    else
                        if smoothedBandsDrawn == 0
                            drawAndLabelBandsXray
                        else
                            drawAndLabelSmoothedBandsXray
                        end
                    end

                    pause(3)

                    set(lblErased,'Visible','off')
                    enableAll
                end
            catch
            end
        end

        % Function for response to user's choice to delete a band
        function delete_Callback(source,eventdata)

            try
                if isfinite(band2delete) && band2delete==floor(band2delete)
                    disableAll

                    % completely delete this band
                    if ct == 1
                        userBands(:,:,band2delete) = [];
                        totBands =length(find(max(max(userBands)))>0);
                    else
                        userBands(:,band2delete) = [];
                        totBands =length(find(max(userBands))>0);
                    end


                    % show a label that the band was deleted
                    delete(lblDeleted) % delete this label if it already exists

                    % display label confirming the band was deleted
                    lblDeleted = uicontrol(UserFig,'Style','text','String',sprintf('Removed band %s',deleteSetIn.String),'Position',[190,330,300,60],'BackgroundColor',[0.97,0.90,0.61],'FontWeight','bold','FontSize',18,'FontName','Arial');
                    set(lblDeleted,'Visible','on')

                    % update image display
                    if ct
                        if smoothedBandsDrawn == 0
                            drawAndLabelBands
                        else
                            drawAndLabelSmoothedBands
                        end
                    else
                        if smoothedBandsDrawn == 0
                            drawAndLabelBandsXray
                        else
                            drawAndLabelSmoothedBandsXray
                        end
                    end

                    pause(3)

                    set(lblDeleted,'Visible','off')
                    enableAll
                end
            catch
            end

        end


        % Create option for inserting a specific band

        % text to indicate this:
        htext9 = uicontrol(UserFig,'Style','text','String','Insert band below:',...
            'Position',[750,752,150,25],'Units','normalized','ForegroundColor',[0.61,0.97,0.61],...
            'FontSize',12,'FontName','Arial','BackGroundColor','none');

        % Create editing bar for user to type in number
        insertSetIn = uicontrol(UserFig,'Style','Edit','BackGroundColor',[0.7 0.7 0.7],...
            'Position',[750,725,150,25],'Units','normalized','FontName','Arial','Callback', @insertSet_Callback);

        % Create button for user to press to insert the specified band
        insertIn = uicontrol(UserFig,'Style','pushbutton','String',{'Apply'},...
            'Position',[750,690,150,25],'Units','normalized','BackgroundColor',[0.61,0.97,0.61],'FontName','Arial','Callback', @insert_Callback);

        % Function for response to user's selection of band to insert
        function insertSet_Callback(source,eventdata)
            insertThisBand = str2num(insertSetIn.String); % simply store it here
        end

        % Function for response to user's choice to insert a band
        function insert_Callback(source,eventdata)
            disableAll

            if ct == 1
                userBands(:,:,1:insertThisBand) = userBands(:,:,1:insertThisBand); % CAN'T THIS BE DELETD?

                % Copy the bands below the chosen one, but shifted down one
                % place in the 3rd dimension of userBands
                userBands(:,:,insertThisBand+2:length(userBands(1,1,:))+1) = userBands(:,:,insertThisBand+1:length(userBands(1,1,:)));

                % Set the inserted band data to all zeros (i.e. empty)
                userBands(:,:,insertThisBand+1) = zeros(row,col);
            else
                userBands(:,1:insertThisBand) = userBands(:,1:insertThisBand);
                userBands(:,insertThisBand+2:length(userBands(1,:))+1) = userBands(:,insertThisBand+1:length(userBands(1,:)));
                userBands(:,insertThisBand+1) = zeros(col,1);
            end

            % update j to the band we inserted, assuming user will want to
            % define it now
            j = insertThisBand;

            % update label that says what the next band will be
            textClick = sprintf('Next band will be band %s',num2str(round(j+1)));
            set(lblClick,'String',textClick)

            set(lblDeleted,'Visible','off')

            % Update counter of total bands since we added one
            totBands = totBands+1;

            % update displayed image
            if ct
                if smoothedBandsDrawn == 0
                    drawAndLabelBands
                else
                    drawAndLabelSmoothedBands
                end
            else
                if smoothedBandsDrawn == 0
                    drawAndLabelBandsXray
                else
                    drawAndLabelSmoothedBandsXray
                end
            end
            enableAll
        end


        % Create option for returning to default settings

        areWeSettingDefaults = 0;
        % create pushbutton to reset to defaults
        defaultIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Restore defaults'},...
            'Position',[660,210,200,40],'Units','normalized','BackgroundColor',[1.00,0.81,0.58],'FontSize',14,'FontName','Arial','Callback',@defaults_Callback);

        % Function to reset defaults
        function defaults_Callback(source,eventdata)
            functionsOff
            areWeSettingDefaults = 1;
            set(lblLoading,'Visible','on')
            brightnessIn.Value = -1300;
            brightness_Callback
            contrastIn.Value = -2000;
            contrast_Callback
            if ct == 1
                thickIn.Value = thick_mm;
                thickness_Callback
                positionIn.Value = slabPos;
                position_Callback
                rotationIn.Value = 0;
                rotation_Callback
            end
            set(lblLoading,'Visible','off')
            areWeSettingDefaults = 0;
            functionsOn
        end

        viewNotesIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'View core notes'},...
            'Position',[840,15,120,24],'Units','normalized',...
            'BackgroundColor',[255, 189, 68]/256,'FontSize',11,...
            'FontName','Arial','Callback',@viewNotes,...
            'Visible','on');

        hideNotesIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Hide notes'},...
            'Position',[840,15,120,24],'Units','normalized',...
            'BackgroundColor',[255, 189, 68]/256,'FontSize',11,...
            'FontName','Arial','Callback',@hideNotes,...
            'Visible','off');

        editNotesIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Edit notes'},...
            'Position',[840,350,100,25],'Units','normalized',...
            'BackgroundColor',[255, 189, 68]/256,'FontSize',12,...
            'FontName','Arial','Callback',@editNotes,...
            'Visible','off');

        editNotesDoneIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Done'},...
            'Position',[840,350,100,25],'Units','normalized',...
            'BackgroundColor',[255, 189, 68]/256,'FontSize',12,...
            'FontName','Arial','Callback',@editNotesDone,...
            'Visible','off');

        htextNotes = uicontrol(UserFig,'Style','text','String',' ','BackGroundColor','w',...
            'Position',[660,380,300,250],'Units','normalized','FontSize',10,'FontName','Arial','Visible','off');

        if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
            editingNotesBox = [];
        end

        function editNotes(source,eventdata)

            check_notes = double(coralDir.textdata{dirRow,7});
            brks = find(check_notes==36);
            if length(brks>0)
                theseNotes = cell(length(brks)+1,1);
                lastPlace = 1;
                for ic = 1:length(brks)
                    theseNotes{ic} = char(check_notes(lastPlace:brks(ic)-1));
                    lastPlace = brks(ic)+1;
                end
                theseNotes{ic+1} = char(check_notes(lastPlace:end));
            else
                theseNotes = char(check_notes);
            end

            editingNotesBox = uitextarea(UserFig,'Position',[660,380,400,280],...
                'Value',theseNotes,'BackGroundColor','w',...
                'ValueChangedFcn',@(textarea,event) notesEntered(textarea));

            set(editNotesIn,'Visible','off')
            set(hideNotesIn,'Visible','off')
            set(editNotesDoneIn,'Visible','on')

        end

        function editNotesDone(source,eventdata)

            set(editNotesIn,'Visible','on')
            set(hideNotesIn,'Visible','on')
            set(editNotesDoneIn,'Visible','off')
            set(editingNotesBox,'Visible','off')

            if notes_edited == 1
                check_notes = editingNotesBox.Value{1};
                if length(editingNotesBox.Value)>1
                    for ic = 2:length(editingNotesBox.Value)
                        check_notes = strcat(check_notes,' $',editingNotesBox.Value{ic});
                    end
                end
                check_notes = double(check_notes);
                check_notes(check_notes==61) = 45; % convert = to -
                coralDir.textdata{dirRow,7} = char(check_notes);
                coralDirHold = coralDir;
                coralDirHold.textdata = coralDirHold.textdata(2:end,:);
                coralDirStruct = struct('name',coralDirHold.textdata(:,1),...
                    'piece',coralDirHold.textdata(:,2),...
                    'region',coralDirHold.textdata(:,3),...
                    'sub_region',coralDirHold.textdata(:,4),...
                    'genus',coralDirHold.textdata(:,5),...
                    'owner',coralDirHold.textdata(:,6),...
                    'notes',coralDirHold.textdata(:,7),...
                    'hard_drive',coralDirHold.data(1,1),...
                    'flip',coralDirHold.data(1,2),...
                    'lat',coralDirHold.data(1,3),...
                    'lon',coralDirHold.data(1,4),...
                    'depth',coralDirHold.data(1,5),...
                    'month',coralDirHold.data(1,6),...
                    'year',coralDirHold.data(1,7),...
                    'file_size',coralDirHold.data(1,8),...
                    'unlocked',coralDirHold.data(1,9),...
                    'denslope',coralDirHold.data(1,10),...
                    'denintercept',coralDirHold.data(1,11),...
                    'ct',coralDirHold.data(1,12),...
                    'xraypos',coralDirHold.data(1,13),...
                    'dpi',coralDirHold.data(1,14));
                for ic = 1:length(coralDirHold.data)
                    coralDirStruct(ic).hard_drive = coralDirHold.data(ic,1);
                    coralDirStruct(ic).flip = coralDirHold.data(ic,2);
                    coralDirStruct(ic).lat = coralDirHold.data(ic,3);
                    coralDirStruct(ic).lon = coralDirHold.data(ic,4);
                    coralDirStruct(ic).depth = coralDirHold.data(ic,5);
                    coralDirStruct(ic).month = coralDirHold.data(ic,6);
                    coralDirStruct(ic).year = coralDirHold.data(ic,7);
                    coralDirStruct(ic).file_size = coralDirHold.data(ic,8);
                    coralDirStruct(ic).unlocked = coralDirHold.data(ic,9);
                    coralDirStruct(ic).denslope = coralDirHold.data(ic,10);
                    coralDirStruct(ic).denintercept = coralDirHold.data(ic,11);
                    coralDirStruct(ic).ct = coralDirHold.data(ic,12);
                    coralDirStruct(ic).xraypos = coralDirHold.data(ic,13);
                    coralDirStruct(ic).dpi = coralDirHold.data(ic,14);
                end
                writetable(struct2table(coralDirStruct),fullfile(selpath,'my_corals','coral_directory_master.txt'),'Delimiter','\t')

                try mput(cache1,fullfile(selpath,'my_corals','coral_directory_master.txt'));
                catch
                    try
                        cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                        cd(cache1,'CoralCache')
                        mput(cache1,fullfile(selpath,'my_corals','coral_directory_master.txt'));
                    catch
                    end
                end
            end
            viewNotes
        end

        notes_edited = 0;
        function notesEntered(textarea)
            val = textarea.Value;
            % Check each element of text area cell array for text
            for k = 1:length(val)
                if(~isempty(val{k}))
                    notes_edited = 1;
                    break;
                end
            end
        end


        function viewNotes(source,eventdata)

            set(htextNotes,'Position',[660,380,300,250]);

            set(viewNotesIn,'Visible','off')
            set(hideNotesIn,'Visible','on')

            if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
                set(editNotesIn,'Visible','on')
            end

            set(brightnessIn,'Visible','off')
            set(contrastIn,'Visible','off')
            set(thickIn,'Visible','off')
            set(positionIn,'Visible','off')
            set(rotationIn,'Visible','off')
            set(htext1,'Visible','off')
            set(htext2,'Visible','off')
            set(htext3,'Visible','off')
            set(htext4,'Visible','off')
            set(htext5,'Visible','off')
            set(htext6,'Visible','off')
            set(lblBright,'Visible','off')
            set(lblContrast,'Visible','off')
            set(lblThick,'Visible','off')
            set(lblPos,'Visible','off')
            set(lblRot,'Visible','off')
            set(projIn,'Visible','off')


            check_notes = double(coralDir.textdata{dirRow,7});
            brks = find(check_notes==36);
            if length(brks>0)
                theseNotes = cell(length(brks)+1,1);
                lastPlace = 1;
                for ic = 1:length(brks)
                    theseNotes{ic} = char(check_notes(lastPlace:brks(ic)-1));
                    lastPlace = brks(ic)+1;
                end
                theseNotes{ic+1} = char(check_notes(lastPlace:end));
            else
                theseNotes = cell(1);
                theseNotes{1} = char(check_notes);
            end

            notes_text_label = theseNotes;%char(check_notes);
            notes_text_wrapped = cell(length(notes_text_label),1);
            counter = 0;
            for ic = 1:length(notes_text_label)
                set(htextNotes,'String',notes_text_label{ic})
                notes_text_wrapped{ic} = textwrap(htextNotes,{htextNotes.String});
                counter = counter+length(notes_text_wrapped{ic});
            end
            full_length_notes = cell(counter,1);
            counter2 = 0;
            for ic = 1:length(notes_text_wrapped)
                if length(notes_text_wrapped{ic}) > 1
                    for ic2 = 1:length(notes_text_wrapped{ic})
                        counter2 = counter2+1;
                        full_length_notes{counter2} = notes_text_wrapped{ic}{ic2};
                    end
                else
                    counter2 = counter2+1;
                    full_length_notes{counter2} = notes_text_wrapped{ic}{1};
                end
            end

            set(htextNotes,'String',full_length_notes,'Units','pixels',...
                'Position',[660,380,400,280],'Units','normalized','FontSize',10,...
                'FontName','Arial','HorizontalAlignment','left','Visible','on');

        end

        function hideNotes(source,eventdata)

            set(viewNotesIn,'Visible','on')
            set(hideNotesIn,'Visible','off')
            set(htextNotes,'Visible','off')

            if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
                set(editNotesIn,'Visible','off')
            end

            set(brightnessIn,'Visible','on')
            set(contrastIn,'Visible','on')
            set(htext2,'Visible','on')
            set(htext3,'Visible','on')
            if ct == 1
                set(htext1,'Visible','on')
                set(htext4,'Visible','on')
                set(htext5,'Visible','on')
                set(htext6,'Visible','on')
                set(lblThick,'Visible','on')
                set(lblPos,'Visible','on')
                set(lblRot,'Visible','on')
                set(projIn,'Visible','on')
                set(thickIn,'Visible','on')
                set(positionIn,'Visible','on')
                set(rotationIn,'Visible','on')
            end
            set(lblBright,'Visible','on')
            set(lblContrast,'Visible','on')

        end

        % create pushbutton to disable automatic band detection
        autoDisableIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Disable'},...
            'Position',[700,15,120,30],'Units','normalized',...
            'BackgroundColor',[1.00,0.81,0.58],'FontSize',14,...
            'FontName','Arial','Callback',@autoDisable,...
            'Visible','off');

        % create pushbutton to disable automatic band detection
        autoEnableIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Enable'},...
            'Position',[700,15,120,30],'Units','normalized',...
            'BackgroundColor',[1.00,0.81,0.58],'FontSize',14,...
            'FontName','Arial','Callback',@autoEnable,...
            'Visible','on');

        lblAutoDetection = uicontrol(UserFig,'Style','text','String','Automatic band detection:','BackgroundColor','none',...
            'Position',[660,75,200,20],'FontSize',12,'FontName','Arial','Units','normalized',...
            'ForegroundColor','w');

        lblAutoDetectionEnabled = uicontrol(UserFig,'Style','text','String','Enabled',...
            'BackgroundColor','none','Position',[660,55,200,20],...
            'FontSize',12,'FontName','Arial','Units','normalized',...
            'Visible','off','ForegroundColor','w');

        lblAutoDetectionDisabled = uicontrol(UserFig,'Style','text','String','Disabled',...
            'BackgroundColor','none','Position',[660,55,200,20],...
            'FontSize',12,'FontName','Arial','Units','normalized',...
            'Visible','on','ForegroundColor','w');

        autoDetectionToggle = 0; % disabled

        % Function to reset defaults
        function autoDisable(source,eventdata)

            set(autoDisableIn,'Visible','off')
            set(lblAutoDetectionEnabled,'Visible','off')
            set(autoEnableIn,'Visible','on')
            set(lblAutoDetectionDisabled,'Visible','on')

            autoDetectionToggle = 0; % disabled

        end

        % Function to reset defaults
        function autoEnable(source,eventdata)

            set(autoDisableIn,'Visible','on')
            set(lblAutoDetectionEnabled,'Visible','on')
            set(autoEnableIn,'Visible','off')
            set(lblAutoDetectionDisabled,'Visible','off')

            autoDetectionToggle = 1; % enabled

        end


        % Create option for being done with this scan

        % create pushbutton for this
        doneIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Save and exit'},...
            'Position',[660,160,200,40],'Units','normalized','BackgroundColor',[0.96,0.51,0.58],'FontSize',14,'FontName','Arial','Callback',@done_Callback);

        % temporarily turn off default mode buttons
        function functionsOff
            set(clickIn,'Enable','off')
            set(jumpIn,'Enable','off')
            set(eraseIn,'Enable','off')
            set(deleteIn,'Enable','off')
            set(insertIn,'Enable','off')
            set(defaultIn,'Enable','off')
            set(doneIn,'Enable','off')
            set(processIn,'Enable','off')
            set(dispSmoothBandsIn,'Enable','off')
            set(dispInterpClicksIn,'Enable','off')
            set(filterEditIn,'Enable','off')
            set(autoEnableIn,'Enable','off')
            set(viewNotesIn,'Enable','off')
            set(saveScreenshotIn,'Enable','off')
            set(viewScreenshotsIn,'Enable','off')
        end

        function functionsOn
            set(clickIn,'Enable','on')
            set(jumpIn,'Enable','on')
            set(eraseIn,'Enable','on')
            set(deleteIn,'Enable','on')
            set(insertIn,'Enable','on')
            set(defaultIn,'Enable','on')
            set(doneIn,'Enable','on')
            set(processIn,'Enable','on')
            set(dispSmoothBandsIn,'Enable','on')
            set(dispInterpClicksIn,'Enable','on')
            set(filterEditIn,'Enable','on')
            set(autoEnableIn,'Enable','on')
            set(viewNotesIn,'Enable','on')
            set(saveScreenshotIn,'Enable','on')
            set(viewScreenshotsIn,'Enable','on')
        end

        % Function to save user inputs and close
        function done_Callback(source,eventdata)

            functionsOff
            pause(0.01)

            if view_only == 0
                
                try
                    if serverChoice == 1
                        cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password)
                    elseif serverChoice == 2
                        cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password)
                    elseif serverChoice == 3
                        cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                    end
                catch
                    try
                        if serverChoice == 1
                            cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password)
                        elseif serverChoice == 2
                            cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password)
                        elseif serverChoice == 3
                            cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                        end
                    catch
                        try
                            connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                            connectionEstablished = 0;
                            for ij = 1:length(connectTimes)
                                if connectionEstablished == 0
                                    if connectTimes(ij) == 1
                                        waitText = [' ',num2str(connectTimes(ij)),' minute.']
                                    else
                                        waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                                    end
                                    set(lblOpeningError,'Units','Pixels','Visible','on','Position',[200,130,500,40],...
                                        'String',{'Error connecting to server.';strcat('Trying again in',waitText)},...
                                        'Units','normalized')
                                    pause(connectTimes(ij)*60)
                                    try
                                        if serverChoice == 1
                                            cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password)
                                        elseif serverChoice == 2
                                            cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password)
                                        elseif serverChoice == 3
                                            cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                        end
                                        connectionEstablished = 1;
                                        set(lblOpeningError,'Units','Pixels','Visible','off',...
                                            'Position',[200,150,500,20],'Units','normalized')
                                    catch
                                    end
                                end
                            end
                            if connectionEstablished == 0
                                zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                            end
                        catch
                            set(lblOpeningError,'Units','Pixels','Position',[200,130,500,40],'Visible','on',...
                                'String',{'Error connecting to server. (code 028)';'Please try again later.'},...
                                'Units','normalized')
                            while 1==1
                                pause
                            end
                        end
                    end
                end

                % Before saving, check if we are working on a core that has
                % multiple sections.
                % and save userBands to the sftp server
                if strcmp('',sectionName) % no sections
                    % set directory to this coral's folder on server
                    save(fullfile(fileOpen,name2search), 'userBands','x_ang','CoralCTversion','contra','proj','thick','h3_width','h3_std','h3_defined');
                    server_path = strcat(h_drive,coralDir.textdata{dirRow,3},'/',...
                        coralDir.textdata{dirRow,4},'/',thisCoralName);
                    if serverChoice == 1 || serverChoice == 3
                        server_path(double(server_path)==32) = 95; % converts spaces to _
                    end
                    cd(cache2,server_path)
                    mput(cache2,fullfile(fileOpen,strcat(saveName,coralName,'.mat')));

                else % yes, sections
                    % set directory to this sections's folder on server
                    save(fullfile(fileOpen,name2search), 'userBands','x_ang','CoralCTversion','contra','proj','thick','h3_width','h3_std','h3_defined');
                    server_path = strcat(h_drive,'/',coralDir.textdata{dirRow,3},'/',...
                        coralDir.textdata{dirRow,4},'/',thisCoralName,'/',thisSectionName);
                    if serverChoice == 1 || serverChoice == 3
                        server_path(double(server_path)==32) = 95; % converts spaces to _
                    end
                    cd(cache2,server_path)
                    mput(cache2,fullfile(fileOpen,strcat(saveName,coralName,'_',sectionName,'.mat')));

                end

                close(cache2)
            end

            set(UserFig,'Color',themeColor2)
            exitClickMode
            resetAxes
            mainMenu
            moveOn = 1;

            functionsOn

        end


        % Create option for being done with this scan and processing growth

        % create pushbutton for this
        processIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Process growth'},...
            'Position',[660,110,200,40],'Units','normalized','BackgroundColor',[0.61,0.86,0.57],'FontSize',14,'FontName','Arial','Callback',@process_Callback);

        % ability to extract snapshot for AI testing
        if strcmp(UserSetIn.String,'TestUser')
            set(processIn,'String',{'Save 2D for AI'},'Callback',@extract2D)
        end

        function extract2D(source,eventdata)
            image_data = corePlot.CData;
            observer_lines_x = bandsPlot.XData/hpxS;
            observer_lines_y = bandsPlot.YData/pxS;
            save(strcat(coralName,'_for_AI'),'image_data','observer_lines_x','observer_lines_y')
        end


        % Create option for identifying the next band
        % create pushbutton for this
        if ct == 1
            clickIn = uicontrol(UserFig,'Style','pushbutton',...
                'String',{'Identify next band'},...
                'Position',[50,720,250,30],'Units','normalized','BackgroundColor',[0.97,0.90,0.61],'FontSize',14,'FontName','Arial','Callback',@click_Callback);

        else
            clickIn = uicontrol(UserFig,'Style','pushbutton',...
                'String',{'Identify next band'},...
                'Position',[50,720,250,30],'Units','normalized','BackgroundColor',[0.97,0.90,0.61],'FontSize',14,'FontName','Arial','Callback',@clickXray_Callback);

        end

        % Create option for being done with the band that's in progress
        % create pushbutton for this
        doneBandIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Done with band'},'Visible','off',...
            'Position',[350,730,200,60],'Units','normalized','BackgroundColor',[0.61,0.86,0.57],'FontSize',14,'FontName','Arial','Callback',@doneBand_Callback);

        % Function to stop identifying this band
        function doneBand_Callback(source,eventdata)

            % save the userBand data locally
            save(fullfile(fileOpen,name2search), 'userBands','x_ang','CoralCTversion','contra','proj','thick','h3_width','h3_std','h3_defined');

            % this toggles within the click band function to be done with
            % clickings:
            areWeDone = 1;
            uiresume(UserFig)
        end


        % Create option for redoing the band that's in progress

        % create pushbutton for this
        redoBandIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Redo this band'},'Visible','off',...
            'Position',[600,730,200,60],'Units','normalized','BackgroundColor',[0.96,0.51,0.58],'FontSize',14,'FontName','Arial','Callback',@redoBand_Callback);

        UndoLastClickIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Undo last click'},'Visible','off',...
            'Position',[600,650,200,60],'Units','normalized','BackgroundColor',[0.76,0.45,0.45],'FontSize',14,'FontName','Arial','Callback',@UndoClick_Callback);

        oops=0; % initialize this here
        function redoBand_Callback(source,eventdata)
            oops = 1; % this toggles within the click band function
            areWeDone = 1;
            uiresume(UserFig)
        end

        function UndoClick_Callback(source,eventdata)
            if ct == 1
                temp_bands(round(x1/hpxS),slab-1:slab+1) = 0;
                temp_bands_idx(round(x1/hpxS),slab-1:slab+1) = 0;
            end
            x(x==x1) = [];
            y(y==y1) = [];
            x1 = [];
            y1 = [];
            delete(lastPoint)
            if ct == 1
                delete(lastPoint2)
            end
        end


        % REMOVED: users can just use the jump to band function and set it
        % to 1
        % Create option for returning to band 1. This is just a simplification of
        % the jump-to-band feature

        % create pushbutton for this
        % resetBandIn = uicontrol(UserFig,'Style','pushbutton',...
        %     'String',{'Return to band 1'},'Units','normalized',...
        %     'Position',[850,730,200,40],'FontSize',12,'FontName','Arial','Callback',@resetBand_Callback);

        % functin to go back to band 1
        % function resetBand_Callback(source,eventdata)
        %     j = 0; % j to 0 (because then next band will be 1)
        %
        %     % update label that says what the next band will be
        %     textClick = sprintf('Next band will be band %s',num2str(round(j+1)));
        %     %lblClick = uicontrol(UserFig,'Style','text','String',textClick,'Position',[50,680,220,25],'BackgroundColor',[1,1,1],'FontSize',14,'FontName','Arial');
        %     set(lblClick,'String',textClick)
        %
        %     set(lblCheck,'Visible','off')
        %
        %     % Update the axial plot
        %     circlePlot
        % end

        % Create response options for auto-band identification
        % Defaults
        acceptProposed = 0;
        continueAuto = 0;

        % accept this and try more auto-detection
        acceptButMoreProposedIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Accept and continue automatic on this band'},...
            'Position',[680,665,405,60],'Units','normalized','BackgroundColor',[0.61,0.86,0.57],'FontSize',12,'FontName','Arial','Callback',@acceptButMoreProposed_Callback);

        function acceptButMoreProposed_Callback(source,eventdata)
            acceptProposed = 1;
            continueAuto = 1;
        end

        % accept this but switch to manual
        acceptButManualProposedIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Accept and continue manual clicks on this band'},...
            'Position',[680,600,405,60],'Units','normalized','BackgroundColor',[0.54,0.82,0.94],'FontSize',12,'FontName','Arial','Callback',@acceptButManualProposed_Callback);

        function acceptButManualProposed_Callback(source,eventdata)
            acceptProposed = 1;
            continueAuto = 0;
        end

        % accept this and be done with the band
        acceptAndDoneProposedIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Accept and done with this band'},...
            'Position',[680,730,405,60],'Units','normalized','BackgroundColor',[0.58,0.93,0.78],'FontSize',12,'FontName','Arial','Callback',@acceptAndDoneProposed_Callback);

        function acceptAndDoneProposed_Callback(source,eventdata)
            acceptProposed = 1;
            continueAuto = 0;
            save(fullfile(fileOpen,name2search), 'userBands','x_ang','CoralCTversion','contra','proj','thick','h3_width','h3_std','h3_defined');
            areWeDone = 1;
        end

        % reject this but try again with auto-detection
        rejectAndAutoProposedIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Reject and try again with automatic'},...
            'Position',[680,535,405,60],'Units','normalized','BackgroundColor',[1.00,0.81,0.58],'FontSize',12,'FontName','Arial','Callback',@rejectAndAutoProposed_Callback);

        function rejectAndAutoProposed_Callback(source,eventdata)
            acceptProposed = 2;
            continueAuto = 1;
        end

        % reject this and switch to manual clicking
        rejectAndManualProposedIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Reject and continue manual clicks on this band'},...
            'Position',[680,470,405,60],'Units','normalized','BackgroundColor',[0.96,0.51,0.58],'FontSize',12,'FontName','Arial','Callback',@rejectAndManualProposed_Callback);

        function rejectAndManualProposed_Callback(source,eventdata)
            acceptProposed = 2;
            continueAuto = 0;
        end

        % All of these buttons are initially set to visibility off
        set(acceptButMoreProposedIn,'Visible','off')
        set(acceptButManualProposedIn,'Visible','off')
        set(acceptAndDoneProposedIn,'Visible','off')
        set(rejectAndAutoProposedIn,'Visible','off')
        set(rejectAndManualProposedIn,'Visible','off')

        if ct == 1
            % Create an axis for displaying the axial cross-section
            ha2 = uiaxes(UserFig,'Units','Pixels','Position',[875,40,200,200],'Units','normalized','Color','none','xcolor','k','ycolor','k');
            hold(ha2,'on')
            ha2.InteractionOptions.DatatipsSupported = 'off';
            ha2.InteractionOptions.ZoomSupported = "off";
            ha2.InteractionOptions.PanSupported = "off";
        end

        % Create an axis for displaying the main sagital plane
        ha = uiaxes(UserFig,'Units','Pixels','Position',[50,50,600,600],'Units','normalized','Color','none','xcolor','k','ycolor','k');
        set(ha,'XTick',[]);
        ha.InteractionOptions.DatatipsSupported = 'off';

        hz = zoom(ha);
        hp = pan(UserFig);
        hz.ActionPostCallback = @zoomPostCallback;
        hp.ActionPostCallback = @zoomPostCallback;
        scalebar = [];
        scalebar1 = [];
        scalebar2 = [];
        scaleText = [];
        scale_mm = 10;
        %set(UserFig,'WindowscrollWheelFcn', @zoomPostCallback);
        set(UserFig,'WindowButtonUpFcn', @doNothing);
        % button for checking latest version

        ha.Toolbar.Visible = 'off';

        function doNothing(obj,evd)
        end

        img_hand = imread(fullfile('loading_movies','hand.jpg'));
        img_zoomin = imread(fullfile('loading_movies','zoomin.png'));
        img_zoomout = imread(fullfile('loading_movies','zoomout.png'));

        img_hand_sized = imresize(img_hand,[20,20]);
        img_zoomin_sized = imresize(img_zoomin,[20,20]);
        img_zoomout_sized = imresize(img_zoomout,[20,20]);
        panIn = uibutton(UserFig,...
            'Position',[460,610,20,20],...
            'BackgroundColor',themeColor1,'FontSize',10,...
            'FontName','Arial','ButtonPushedFcn',@panfun,...
            'Visible','on','Icon',img_hand_sized,'Text','');

        panOut = uibutton(UserFig,...
            'Position',[460,610,20,20],...
            'BackgroundColor',themeColor1-0.3,'FontSize',10,...
            'FontName','Arial','ButtonPushedFcn',@stoppanfun,...
            'Visible','off','Icon',img_hand_sized,'Text','');

        %panon = 0;
        function panfun(obj,evd)
            set(panIn,'Visible','off')
            set(panOut,'Visible','on')
            set(zoomInIn,'Visible','on')
            set(zoomInOut,'Visible','off')
            zoom(ha,'off')
            pan(ha,'on')
            %panon = 1;
            %zoomon = 0;
        end
        function stoppanfun(obj,evd)
            set(panIn,'Visible','on')
            set(panOut,'Visible','off')
            pan(ha,'off')
            %panon = 0;
        end

        zoomInIn = uibutton(UserFig,...
            'Position',[490,610,20,20],...
            'BackgroundColor',themeColor1,'FontSize',10,...
            'FontName','Arial','ButtonPushedFcn',@zoominfun,...
            'Visible','on','Icon',img_zoomin_sized,'Text','');

        zoomInOut = uibutton(UserFig,...
            'Position',[490,610,20,20],...
            'BackgroundColor',themeColor1-0.3,'FontSize',10,...
            'FontName','Arial','ButtonPushedFcn',@stopzoominfun,...
            'Visible','off','Icon',img_zoomin_sized,'Text','');

        %zoomon = 0;
        function zoominfun(obj,evd)
            set(zoomInIn,'Visible','off')
            set(zoomInOut,'Visible','on')
            set(panIn,'Visible','on')
            set(panOut,'Visible','off')
            pan(ha,'off')
            zoom(ha,'on')
            %zoomon = 1;
            %panon = 0;
        end
        function stopzoominfun(obj,evd)
            set(zoomInIn,'Visible','on')
            set(zoomInOut,'Visible','off')
            zoom(ha,'off')
            %zoomon = 0;
        end

        zoomOutIn = uibutton(UserFig,...
            'Position',[520,610,20,20],...
            'BackgroundColor',themeColor1,'FontSize',10,...
            'FontName','Arial','ButtonPushedFcn',@zoomoutfun,...
            'Visible','on','Icon',img_zoomout_sized,'Text','');

        function zoomoutfun(obj,evd)
            set(panIn,'Visible','on')
            set(panOut,'Visible','off')
            set(zoomInIn,'Visible','on')
            set(zoomInOut,'Visible','off')
            zoom(ha,'off')
            pan(ha,'off')
            zoom(ha,'out')
        end

        function zoomPostCallback(obj,evd)
            set(lblLoading,'Visible','on')
            %iptSetPointerBehavior(ha, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'custom', 'PointerShapeCData', [NaN,NaN]))
            pause(0.01)
            set(panIn,'Enable','off')
            set(panOut,'Enable','off')
            set(zoomInIn,'Enable','off')
            set(zoomInOut,'Enable','off')
            set(zoomOutIn,'Enable','off')

            functionsOff

            ys = get(ha,'YLim');
            xs = get(ha,'XLim');
            delete(scalebar)
            delete(scalebar1)
            delete(scalebar2)
            delete(scaleText)
            % if panon == 1
            %     hp('Enable','off')
            % end
            % if zoomon == 1
            %     set(hz,'Enable','off')
            % end
            pause(0.01)
            %dispSlab
            if ct == 1
                if smoothedBandsDrawn == 0
                    drawAndLabelBands
                else
                    drawAndLabelSmoothedBands
                end
            else
                if smoothedBandsDrawn == 0
                    drawAndLabelBandsXray
                else
                    drawAndLabelSmoothedBandsXray
                end
            end
            % if ct ==  1
            %     scalebar = patch(ha,xs(1)+[range(xs)*0.05, range(xs)*0.05, range(xs)*0.05+scale_mm,...
            %         range(xs)*0.05+scale_mm, range(xs)*0.05],...
            %         ys(1)+[range(ys)*0.03, range(ys)*0.035, range(ys)*0.035,...
            %         range(ys)*0.03, range(ys)*0.03],themeColor1,'EdgeColor','none');
            %     scalebar1 = patch(ha,xs(1)+[range(xs)*0.05, range(xs)*0.05, range(xs)*0.055,...
            %         range(xs)*0.055, range(xs)*0.05],...
            %         ys(1)+[range(ys)*0.02, range(ys)*0.045, range(ys)*0.045,...
            %         range(ys)*0.02, range(ys)*0.02],themeColor1,'EdgeColor','none');
            %     scalebar2 = patch(ha,xs(1)+[range(xs)*0.045+scale_mm, range(xs)*0.045+scale_mm, range(xs)*0.05+scale_mm,...
            %         range(xs)*0.05+scale_mm, range(xs)*0.045+scale_mm],...
            %         ys(1)+[range(ys)*0.02, range(ys)*0.045, range(ys)*0.045,...
            %         range(ys)*0.02, range(ys)*0.02],themeColor1,'EdgeColor','none');
            %     scaleText = text(ha,xs(1)+range(xs)*0.06+scale_mm,...
            %         ys(1)+range(ys)*0.03,'10 mm','FontSize',12,'FontWeight','bold',...
            %         'Color',themeColor1,'VerticalAlignment','bottom');
            % else
            %     scalebar = patch(ha,xs(1)+[range(xs)*0.05, range(xs)*0.05, range(xs)*0.05+scale_mm,...
            %         range(xs)*0.05+scale_mm, range(xs)*0.05],...
            %         ys(2)-[range(ys)*0.03, range(ys)*0.035, range(ys)*0.035,...
            %         range(ys)*0.03, range(ys)*0.03],themeColor1,'EdgeColor','none');
            %     scalebar1 = patch(ha,xs(1)+[range(xs)*0.05, range(xs)*0.05, range(xs)*0.055,...
            %         range(xs)*0.055, range(xs)*0.05],...
            %         ys(2)-[range(ys)*0.02, range(ys)*0.045, range(ys)*0.045,...
            %         range(ys)*0.02, range(ys)*0.02],themeColor1,'EdgeColor','none');
            %     scalebar2 = patch(ha,xs(1)+[range(xs)*0.045+scale_mm, range(xs)*0.045+scale_mm, range(xs)*0.05+scale_mm,...
            %         range(xs)*0.05+scale_mm, range(xs)*0.045+scale_mm],...
            %         ys(2)-[range(ys)*0.02, range(ys)*0.045, range(ys)*0.045,...
            %         range(ys)*0.02, range(ys)*0.02],themeColor1,'EdgeColor','none');
            %     scaleText = text(ha,xs(1)+range(xs)*0.06+scale_mm,...
            %         ys(2)-range(ys)*0.03,'10 mm','FontSize',12,'FontWeight','bold',...
            %         'Color',themeColor1,'VerticalAlignment','bottom');
            % end
            set(panIn,'Enable','on')
            set(panOut,'Enable','on')
            set(zoomInIn,'Enable','on')
            set(zoomInOut,'Enable','on')
            set(zoomOutIn,'Enable','on')
            set(lblLoading,'Visible','off')
            % if zoomon == 1
            %     zoom(ha,'on')
            % end
            % if panon == 1
            %     pan(ha,'on')
            % end
            functionsOn
            pause(0.01)
        end

        % accept this but switch to manual
        drawDeleteBox1In = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Draw a box to delete';'clicks on this band'},'Visible','off',...
            'Position',[850   730   200    60],'Units','normalized','BackgroundColor',[255, 189, 68]/256,'FontSize',12,'FontName','Arial','Callback',@drawDeleteBox1);

        lblExplainBox = uicontrol(UserFig,'Style','text','String',{'This only applies to areas outside';'of the current slab (red box)'},'BackgroundColor','none',...
            'Position',[850,620,200,30],'FontSize',10,'FontName','Arial','Units','normalized','Visible','off','Foregroundcolor','w');

        need2delete = 0;
        area2delete = [];
        roi = [];
        function drawDeleteBox1(source,eventdata)
            roi = drawrectangle(ha);
            need2delete = 1;
            area2delete = roi.Position;
            uiresume(UserFig);
        end

        drawDeleteBox2In = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Draw a box to delete';'clicks on this band';'in axial view below'},'Visible','off',...
            'Position',[850   530   200    70],'Units','normalized','BackgroundColor',[255, 189, 68]/256,'FontSize',12,'FontName','Arial','Callback',@drawDeleteBox2);

        need2delete2 = 0;
        area2delete2 = [];
        roi2 = [];
        function drawDeleteBox2(source,eventdata)
            set(lblExplainBox,'Visible','on')
            x1 = [];
            y1 = [];
            uiresume(UserFig);
            roi2 = drawrectangle(ha2);
            need2delete2 = 1;
            area2delete2 = roi2.Position;
            set(lblExplainBox,'Visible','off')
        end

        viewScreenshotsIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'View screenshots'},'Visible','on',...
            'Position',[980,15,125,24],'Units','normalized','BackgroundColor',[1 0.65 0],'FontSize',11,'FontName','Arial','Callback',@viewScreenshots);

        saveScreenshotIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Snap screenshot'},'Visible','on',...
            'Position',[980,49,125,24],'Units','normalized','BackgroundColor',[1 0.65 0],'FontSize',11,'FontName','Arial','Callback',@screenShot);

        function screenShot(source,eventdata)
            functionsOff
            set(saveScreenshotIn,'Enable','off')
            drawnow
            sshotFig = uifigure('Visible','on','Position',[50,100,800,800],'Color','k');
            sha1 = uiaxes(sshotFig,'units','normalized','Position',[0.0300    0.1100    0.7    0.8150]);
            set(sha1,'Color','k','xcolor','k','ycolor','k','XTick',[],'YTick',[])
            box on
            axcopy = copyobj(ha.Children,sha1);
            set(sha1,'PlotBoxAspectRatio',[1 1 1])
            set(sha1,'DataAspectRatio',[1 1 1])
            set(sha1,'Colormap',colormap('bone'))
            set(sha1,'CLim',contra);
            set(sha1,'YLim',get(ha,'YLim'),'XLim',get(ha,'XLim'))
            t = datetime('now') ;
            t.Format = 'dd-MMM-uuuu HH:mm a';
            text(sha1,0.01,0.01,strcat([saveFileName,': ',char(t)]),'Color','y','units','normalized','FontSize',12)
            if strcmp(sectionName,'')
                dispTitleName = coralName;
            else
                dispTitleName = [coralName,' ',sectionName];
            end
            dispTitleName0 = double(dispTitleName);
            idxUnderScore = find(dispTitleName0==95);
            if length(idxUnderScore)
                dispTitleName = [];
                idxUnderScore = [0, idxUnderScore];
                for jjj = 2:length(idxUnderScore)
                    dispTitleName = [dispTitleName, dispTitleName0(idxUnderScore(jjj-1)+1:idxUnderScore(jjj)-1),92, 95];
                end
                dispTitleName = char([dispTitleName, dispTitleName0(idxUnderScore(jjj)+1:end)]);
            else
                %dispTitleName = coralName;
            end
            
            title(sha1,dispTitleName,'Color',themeColor1)

            if ct == 1
                sha2 = uiaxes(sshotFig,'units','normalized','Position',[0.7500    0.1100    0.2    0.2]);
                hold on
                set(sha2,'Color','k','xcolor','k','ycolor','k','XTick',[],'YTick',[])
                axcopy = copyobj(ha2.Children,sha2);
                set(sha2,'PlotBoxAspectRatio',[1 1 1])
                set(sha2,'DataAspectRatio',[1 1 1])
                set(sha2,'Colormap',colormap('bone'))
                set(sha2,'CLim',contra);
            else
                set(sha1,'YDir','reverse')
            end

            closeSnapIn = uicontrol(sshotFig,'Style','pushbutton',...
                'String',{'Close window'},'Visible','on',...
                'Position',[10,774,130,24],'Units','normalized','BackgroundColor',[255,96,92]./256,'FontSize',11,'FontName','Arial','Callback',@closeSnap);

            function closeSnap(source,eventdata)
                close(sshotFig)
                set(saveScreenshotIn,'Enable','on')
            end

            drawAnnotationIn = uicontrol(sshotFig,'Style','pushbutton',...
                'String',{'Draw textbox'},'Visible','on',...
                'Position',[160,774,140,24],'Units','normalized','BackgroundColor',[1 0.65 0],'FontSize',11,'FontName','Arial','Callback',@drawAnnote);

            textCol = [0.6 0.8 1];

            chooseColorIn = uicontrol(sshotFig,'Style','pushbutton',...
                'String',{'Choose text color'},'Visible','on',...
                'Position',[320,774,140,24],'Units','normalized','BackgroundColor',textCol,'FontSize',11,'FontName','Arial','Callback',@chooseColor);

            function chooseColor(source,eventdata)
                textCol = uisetcolor(textCol);
                set(chooseColorIn,'BackgroundColor',textCol)
            end

            editAnnotationsIn = uicontrol(sshotFig,'Style','pushbutton',...
                'String',{'Edit annotations'},'Visible','on',...
                'Position',[480,774,140,24],'Units','normalized','BackgroundColor',[0.97,0.90,0.61],'FontSize',11,'FontName','Arial','Callback',@editAnnotations);

            editAnnotationsOut = [];
            stopEditFig = [];
            keepEditingAnnotations = 0;
            function editAnnotations(source,eventdata)
                set(editAnnotationsIn,'Visible','off')
                stopEditFig = uifigure('Visible','on','Position',[800+50,900-26,182,26],'Color','k');
                editAnnotationsOut = uicontrol(stopEditFig,'Style','pushbutton',...
                    'String',{'Done Editing'},'Visible','on',...
                    'Position',[1,1,180,24],'Units','normalized','BackgroundColor',[255,96,92]./256,'FontSize',11,'FontName','Arial','Callback',@editAnnotationsDone);
                keepEditingAnnotations = 1;
                plotedit(sshotFig)
                posMain = get(sha1,'Position');
                while keepEditingAnnotations == 1
                    if sum(posMain - get(sha1,'Position'))==0
                    else
                        set(sha1,'Position',posMain)
                    end
                    pause(0.01)
                end

                function editAnnotationsDone(source,eventdata)
                    keepEditingAnnotations = 0;
                    plotedit(sshotFig,'off')
                    set(editAnnotationsIn,'Visible','on')
                    close(stopEditFig)
                end

            end

            function drawAnnote(source,eventdata)
                boxLoc = drawrectangle(sha1);
                posText = [(boxLoc.Position(1)-min(get(sha1,'XLim')))/range(get(sha1,'XLim'))*0.7+0.03,...
                    (boxLoc.Position(2)-min(get(sha1,'YLim')))/range(get(sha1,'YLim'))*0.8150*0.85+0.11+0.065,...
                    (boxLoc.Position(3))/range(get(sha1,'XLim'))*(0.7-0.03),...
                    (boxLoc.Position(4))/range(get(sha1,'YLim'))*(0.8150-0.11)];
                annotationIn = uitextarea(sshotFig,'Position',posText*800,...
                    'ValueChangedFcn',@(textarea,event) textEntered2(textarea),...
                    'FontColor','white','BackGroundColor','k','Visible','on');
                delete(boxLoc);
                text_entered = 0;
                function textEntered2(textarea)
                    val = textarea.Value;
                    for k = 1:length(val)
                        if(~isempty(val{k}))
                            text_entered = 1;
                            break;
                        end
                    end
                end
                while text_entered >= 0
                    pause(0.01)
                    if text_entered == 1
                        break
                    end
                end
                tbox = annotation(sshotFig,"textbox");
                tbox.String = val;
                tbox.Position = posText;
                tbox.FontSize = 12;
                tbox.EdgeColor = 'none';
                tbox.Color = textCol;
                delete(annotationIn)
            end

            labCol = [rand rand rand]*0.7+0.3;
            drawLineIn = uicontrol(sshotFig,'Style','pushbutton',...
                'String',{'Measure line'},'Visible','on',...
                'Position',[640,774,140,24],'Units','normalized','BackgroundColor',labCol,'FontSize',11,'FontName','Arial','Callback',@drawLine);

            lineLoc = [];
            function drawLine(source,eventdata)
                lineLoc = drawline(sha1,'Color',labCol);
                thisMeasure = sqrt(((lineLoc.Position(2,2)-lineLoc.Position(1,2)))^2 + ...
                    ((lineLoc.Position(2,1)-lineLoc.Position(1,1)))^2);
                lineLoc.Label = ['   ',num2str(round(thisMeasure*100)/100),' mm'];
                lineLoc.LabelAlpha = 0.7;
                labCol = [rand rand rand]*0.7+0.3;
                drawLineIn.BackgroundColor = labCol;
                addlistener(lineLoc,'MovingROI',@changeLine);
                addlistener(lineLoc,'ROIMoved',@changeLine);
            end

            function changeLine(src,evt)
                thisMeasure = sqrt(((lineLoc.Position(2,2)-lineLoc.Position(1,2)))^2 + ...
                    ((lineLoc.Position(2,1)-lineLoc.Position(1,1)))^2);
                lineLoc.Label = ['   ',num2str(round(thisMeasure*100)/100),' mm'];
                lineLoc.LabelAlpha = 0.7;
            end

            screenShotToServerIn = uicontrol(sshotFig,'Style','pushbutton',...
                'String',{'Send to server'},'Visible','on',...
                'Units','normalized','Position',[0.8,0.5,0.15,0.075],'BackgroundColor',[1 0.65 0],'FontSize',11,'FontName','Arial','Callback',@screenShotToServer);

            function screenShotToServer(source,eventdata)

                try
                    if serverChoice == 1
                        cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password)
                    elseif serverChoice == 2
                        cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password)
                    elseif serverChoice == 3
                        cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                    end
                catch
                    try
                        if serverChoice == 1
                            cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password)
                        elseif serverChoice == 2
                            cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password)
                        elseif serverChoice == 3
                            cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                        end
                    catch
                        try
                            connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                            connectionEstablished = 0;
                            for ij = 1:length(connectTimes)
                                if connectionEstablished == 0
                                    if connectTimes(ij) == 1
                                        waitText = [' ',num2str(connectTimes(ij)),' minute.']
                                    else
                                        waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                                    end
                                    set(lblOpeningError,'Units','Pixels','Visible','on','Position',[200,130,500,40],...
                                        'String',{'Error connecting to server.';strcat('Trying again in',waitText)},...
                                        'Units','normalized')
                                    pause(connectTimes(ij)*60)
                                    try
                                        if serverChoice == 1
                                            cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password)
                                        elseif serverChoice == 2
                                            cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password)
                                        elseif serverChoice == 3
                                            cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                        end
                                        connectionEstablished = 1;
                                        set(lblOpeningError,'Units','Pixels','Visible','off',...
                                            'Position',[200,150,500,20],'Units','normalized')
                                    catch
                                    end
                                end
                            end
                            if connectionEstablished == 0
                                zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                            end
                        catch
                            set(lblOpeningError,'Units','Pixels','Position',[200,130,500,40],'Visible','on',...
                                'String',{'Error connecting to server. (code 029)';'Please try again later.'},...
                                'Units','normalized')
                            while 1==1
                                pause
                            end
                        end
                    end
                end

                if strcmp('',sectionName) % no sections
                    % set directory to this coral's folder on server
                    server_path = strcat(h_drive,coralDir.textdata{dirRow,3},'/',...
                        coralDir.textdata{dirRow,4},'/',thisCoralName);
                    if serverChoice == 1 || serverChoice == 3
                        server_path(double(server_path)==32) = 95; % converts spaces to _
                    end
                else % yes, sections
                    % set directory to this sections's folder on server
                    server_path = strcat(h_drive,'/',coralDir.textdata{dirRow,3},'/',...
                        coralDir.textdata{dirRow,4},'/',thisCoralName,'/',thisSectionName);
                    if serverChoice == 1 || serverChoice == 3
                        server_path(double(server_path)==32) = 95; % converts spaces to _
                    end
                end
                cd(cache2,server_path)
                dSnaps = dir(cache2);
                dirSnaps = [];
                for iii = 1:length(dSnaps)
                    if length(strsplit(dSnaps(iii).name,'Screenshot'))==2
                        dirSnaps = [dirSnaps;dSnaps(iii).name];
                    end
                end
                if length(dirSnaps)
                    nSnaps = length(dirSnaps(:,1));
                else
                    nSnaps = 0;
                end
                img_text = sprintf('%05d', nSnaps+1);
                exportgraphics(sshotFig,fullfile(refPath,strcat('Screenshot_',img_text,'.png')),'BackgroundColor','k');
                mput(cache2,fullfile(refPath,strcat('Screenshot_',img_text,'.png')));

            end
            functionsOn
        end

        dispSmoothBandsIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Show smoothed bands'},'Visible','off',...
            'Position',[220   15   210    30],'Units','normalized','BackgroundColor',[1 0.65 0],'FontSize',11,'FontName','Arial','Callback',@dispSmoothBands);

        dispInterpClicksIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Show interpolated clicks'},'Visible','off',...
            'Position',[220   15   210    30],'Units','normalized','BackgroundColor','y','FontSize',11,'FontName','Arial','Callback',@dispIntClicks);

        smoothedBandsDrawn = 0;

        function dispSmoothBands(source,eventdata)
            functionsOff
            set(dispInterpClicksIn,'Visible','on')
            set(dispSmoothBandsIn,'Visible','off')
            smoothedBandsDrawn = 1;
            if ct == 1
                drawAndLabelSmoothedBands
            else
                drawAndLabelSmoothedBandsXray
            end
            functionsOn
        end

        function dispIntClicks(source,eventdata)
            functionsOff
            set(dispInterpClicksIn,'Visible','off')
            set(dispSmoothBandsIn,'Visible','on')
            smoothedBandsDrawn = 0;
            if ct == 1
                drawAndLabelBands
            else
                drawAndLabelBandsXray
            end
            functionsOn
        end

        function updateBandLines

            delete(bandsPlot)

            if ct == 1
                if smoothedBandsDrawn == 0

                    if max(max(max(userBands)))>0
                        totBands3 = find(max(max(userBands)));
                        LDBdata = zeros(row,col,max(totBands3));
                        for i4 = totBands3'
                            if max(max(userBands(:,:,i4)))>0
                                [r,c] = find(userBands(:,:,i4));
                                if ~isempty(r)
                                    v = zeros(1,length(r));
                                    for j2 = 1:length(r)
                                        v(j2) = userBands(r(j2),c(j2),i4);
                                    end
                                    warning('off','all');
                                    if length(round(griddata(r,c,v,rowMesh,colMesh)))>1
                                        LDBdata(:,:,i4) = permute(round(griddata(r,c,v,rowMesh,colMesh)),[2,1,3]);
                                    end
                                    warning('on','all');
                                end
                            end
                        end

                        LDBdata(isnan(LDBdata)) = 0;
                        ldbDraw = LDBdata;

                        reDrawLines
                        pause(0.001)
                        hold(ha,'on')
                        xIntersect = NaN(max(totBands3),1);
                        yIntersect = NaN(max(totBands3),1);
                        for i4 = totBands3'
                            if max(max(userBands(:,:,i4)))>0
                                [r,c] = find(LDBdata(:,slab,i4));
                                hold(ha,'on')
                                if length(r)>0
                                    if max(max(LDBdata(:,:,i4)))>0
                                        xIntersect(i4) = median(r)*hpxS;
                                        yIntersect(i4) = (LDBdata(round(median(r)),slab,i4)-layers)*-pxS;
                                        text(ha,xIntersect(i4),yIntersect(i4),num2str(i4),'Color','yellow','Clipping','on');
                                    end
                                end
                                hold(ha,'off')
                            end
                        end
                    end

                else

                    if max(max(max(userBands)))>0
                        totBands3 = find(max(max(userBands)));
                        LDBdata = zeros(row,col,length(userBands(1,1,1:max(totBands3))));
                        band_filt4plot = zeros(size(LDBdata));
                        surf_filt = h3;
                        for i4 = totBands3'
                            if max(max(userBands(:,:,i4)))>0
                                [r,c] = find(userBands(:,:,i4));
                                if isempty(r)
                                    break
                                end
                                v = zeros(1,length(r));
                                for j2 = 1:length(r)
                                    v(j2) = userBands(r(j2),c(j2),i4);
                                end
                                warning('off','all');
                                if length(round(griddata(r,c,v,rowMesh,colMesh)))>1
                                    LDBdata(:,:,i4) = permute(round(griddata(r,c,v,rowMesh,colMesh)),[2,1,3]);
                                end
                                warning('on','all');
                            end
                            band_filt4plot(:,:,i4) = nanconv(LDBdata(:,:,i4), surf_filt, 'nanout');
                        end

                        LDBdata(isnan(LDBdata)) = 0;
                        band_filt4plot(isnan(band_filt4plot)) = 0;

                        ldbDraw = band_filt4plot;

                        reDrawLines
                        set(bandsPlot,'Color',[1 0.65 0])
                        pause(0.001)
                        hold(ha,'on')
                        xIntersect = NaN(max(totBands3),1);
                        yIntersect = NaN(max(totBands3),1);
                        for i4 = totBands3'
                            if max(max(userBands(:,:,i4)))>0
                                [r,c] = find(LDBdata(:,slab,i4));
                                hold(ha,'on')
                                if length(r)>0
                                    if max(max(LDBdata(:,:,i4)))>0
                                        xIntersect(i4) = median(r)*hpxS;
                                        yIntersect(i4) = (LDBdata(round(median(r)),slab,i4)-layers)*-pxS;
                                        text(ha,xIntersect(i4),yIntersect(i4),num2str(i4),'Color',[1 0.65 0],'Clipping','on');
                                    end
                                end
                                hold(ha,'off')
                            end
                        end
                    end
                end

            else
                if smoothedBandsDrawn == 0

                    smoothed_on = 0;
                    reDrawLines
                    pause(0.001)
                    hold(ha,'on')
                    totBands3 = find(max(userBands));
                    xIntersect = NaN(max(totBands3),1);
                    yIntersect = NaN(max(totBands3),1);
                    for i4 = totBands3
                        if max(max(userBands(:,i4)))>0
                            c = find(userBands(:,i4));
                            hold(ha,'on')
                            if length(c)>0
                                xIntersect(i4) = median(c)*hpxS;
                                interpLab = interp1(c,userBands(c,i4),round(median(c)));
                                text(ha,xIntersect(i4),interpLab*pxS,num2str(i4),'Color','y','Clipping','on');
                            end
                            hold(ha,'off')
                        end
                    end

                else

                    smoothed_on = 1;
                    totBands3 = find(max(userBands));
                    LDBdata = zeros(col,max(totBands3));
                    band_filt = NaN(size(LDBdata));
                    h2d = sum(h3);
                    h2mid = ceil(length(h3(:,1))/2);
                    for i4 = totBands3
                        if max(max(userBands(:,i4)))>0
                            c = find(userBands(:,i4));
                            if isempty(c)
                                break
                            end
                            this_band_interp = interp1(c,userBands(c,i4),min(c):max(c));

                            for i5 = min(c):max(c)
                                h2x = i5-h2mid:i5-h2mid+length(h2d)-1;
                                thisH2d = h2d;
                                thisH2d(h2x < min(c)) = [];
                                h2x(h2x < min(c)) = [];
                                thisH2d(h2x > max(c)) = [];
                                h2x(h2x > max(c)) = [];
                                h2x = h2x-min(c)+1;
                                thisH2d = thisH2d./sum(thisH2d);
                                band_filt(i5,i4) = sum(this_band_interp(h2x).*thisH2d);
                            end
                        end
                    end
                    LDBdata = band_filt;

                    reDrawLines
                    set(bandsPlot,'Color',[1 0.65 0])

                    pause(0.001)
                    hold(ha,'on')
                    xIntersect = NaN(max(totBands3),1);
                    yIntersect = NaN(max(totBands3),1);
                    for i4 = totBands3
                        if max(max(userBands(:,i4)))>0
                            c = find(LDBdata(:,i4));
                            hold(ha,'on')
                            if length(c)>0
                                if max(LDBdata(:,i4))>0
                                    xIntersect(i4) = median(c)*hpxS;
                                    yIntersect(i4) = (LDBdata(round(median(c)),i4))*pxS;
                                    text(ha,xIntersect(i4),yIntersect(i4),num2str(i4),'Color',[1 0.65 0],'Clipping','on');
                                end
                            end
                            hold(ha,'off')
                        end
                    end

                end

            end

            drawnow;

            function reDrawLines
                if haveLims == 0
                    xs = [min([1:row].*hpxS),max([1:row].*hpxS)];
                    ys = [min([1:layers].*pxS),max([1:layers].*pxS)];
                else
                    ys = get(ha,'YLim');
                    xs = get(ha,'XLim');
                end
                hold(ha,'on')
                band_lines = [NaN,NaN];
                counter = 1;
                if ct == 1
                    totBands3 = find(max(max(userBands)));
                else
                    totBands3 = find(max(userBands));
                end
                if ct == 1
                    for i4 = totBands3'
                        if max(max(userBands(:,:,i4)))>0
                            r = find(ldbDraw(:,slab,i4));
                            if length(r)>0
                                for i6 = 1:length(r)
                                    counter = counter+1;
                                    band_lines(counter,:) = [r(i6)*hpxS,(layers-ldbDraw(r(i6),slab,i4))*pxS];
                                end
                                band_lines(counter+1,:) = [NaN,NaN];
                                counter = counter+1;
                            end
                        end
                    end
                else
                    for i4 = totBands3
                        if max(userBands(:,i4))>0
                            if smoothed_on == 0
                                c = find(userBands(:,i4));
                                band_lines(counter+1:counter+length(c),:) = [c*hpxS,userBands(c,i4)*pxS];
                            else
                                c = find(LDBdata(:,i4));
                                band_lines(counter+1:counter+length(c),:) = [c*hpxS,LDBdata(c,i4)*pxS];
                            end
                            band_lines(counter+1+length(c),:) = [NaN,NaN];
                            counter = counter+length(c)+1;
                        end
                    end
                end
                band_lines(band_lines(:,2) > ys(2),:) = NaN;
                band_lines(band_lines(:,1) > xs(2),:) = NaN;
                band_lines(band_lines(:,2) < ys(1),:) = NaN;
                band_lines(band_lines(:,1) < xs(1),:) = NaN;
                bandsPlot = plot(ha,band_lines(:,1),band_lines(:,2),'-','Color','y');
                if length(band_lines)>2
                    interpBandsPlotted = 1;
                end
                hold(ha,'off')
            end

        end


        hideInterpIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Hide interpolated bands'},'Visible','off',...
            'Position',[250   10   160    30],'Units','normalized','BackgroundColor',[0.78,0.94,0.54],'FontSize',11,'FontName','Arial','Callback',@hideInterp);

        showInterpIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Show interpolated bands'},'Visible','off',...
            'Position',[250   10   160    30],'Units','normalized','BackgroundColor',[0.78,0.94,0.54],'FontSize',11,'FontName','Arial','Callback',@showInterp);

        function hideInterp(source,eventdata)
            set(bandsPlot,'Visible','off')
            set(hideInterpIn,'Visible','off')
            set(showInterpIn,'Visible','on')
        end

        function showInterp(source,eventdata)
            set(bandsPlot,'Visible','on')
            set(hideInterpIn,'Visible','on')
            set(showInterpIn,'Visible','off')
        end

        % button to adjust filtering
        filterEditIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Edit smoothing'},...
            'Position',[500,15,160,30],'Units','normalized',...
            'BackgroundColor',[255, 189, 68]/256,'FontSize',12,...
            'FontName','Arial','Callback',@editFilters,...
            'Visible','on');

        filterEditOut = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Go back'},...
            'Position',[500,15,160,30],'Units','normalized',...
            'BackgroundColor',[255, 189, 68]/256,'FontSize',12,...
            'FontName','Arial','Callback',@cancelEditFilters_fun,...
            'Visible','off');

        aboutEditFiltersIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'What is this?'},'Visible','off',...
            'Position',[700,400,100,30],'Units','normalized','BackgroundColor','none','ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial','Callback',@aboutSmoothEdit_fun);

        aboutEditFiltersOut = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Go back'},'Visible','off',...
            'Position',[700,250,100,30],'Units','normalized','BackgroundColor','none','ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial','Callback',@cancelAboutSmoothEdit_fun);

        wasUndoOn = 0;
        wasDrawBoxOn1 = 0;
        wasDrawBoxOn2 = 0;
        washideInterpOn = 0;
        wasMainScreen = 0;
        wasAutoOn = 0;
        wasSmoothingOn = 0;

        function editFilters(src,event)

            %iptSetPointerBehavior(corePlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'watch'));
            %iptSetPointerBehavior(bandsPlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'watch'));

            set(corePlot,'ButtonDownFcn','')
            set(bandsPlot,'ButtonDownFcn','')

            if strcmp(get(UndoLastClickIn,'Visible'),'on')
                wasUndoOn = 1;
            else
                wasUndoOn = 0;
            end
            if strcmp(get(redoBandIn,'Visible'),'on')
                wasDrawBoxOn1 = 1;
            else
                wasDrawBoxOn1 = 0;
            end
            if strcmp(get(redoBandIn,'Visible'),'on')
                wasDrawBoxOn2 = 1;
            else
                wasDrawBoxOn2 = 0;
            end
            if strcmp(get(hideInterpIn,'Visible'),'on')
                washideInterpOn = 1;
            else
                washideInterpOn = 0;
            end
            if strcmp(get(dispInterpClicksIn,'Visible'),'on')
                wasSmoothingOn = 1;
            else
                wasSmoothingOn = 0;
            end

            if strcmp(get(projIn,'Visible'),'on')
                wasMainScreen = 1;
                set(htext1,'Visible','off')
                set(htext2,'Visible','off')
                set(htext3,'Visible','off')
                set(htext4,'Visible','off')
                set(htext5,'Visible','off')
                set(htext6,'Visible','off')
                set(htext7,'Visible','off')
                set(htext8,'Visible','off')
                set(htext9,'Visible','off')
                set(brightnessIn,'Visible','off')
                set(contrastIn,'Visible','off')
                set(thickIn,'Visible','off')
                set(positionIn,'Visible','off')
                set(rotationIn,'Visible','off')
                set(lblBright,'Visible','off')
                set(lblContrast,'Visible','off')
                set(lblThick,'Visible','off')
                set(lblPos,'Visible','off')
                set(lblRot,'Visible','off')
                set(projIn,'Visible','off')
                set(jumpSetIn,'Visible','off')
                set(jumpIn,'Visible','off')
                set(htext8b,'Visible','off')
                set(deleteSetIn,'Visible','off')
                set(deleteIn,'Visible','off')
                set(eraseSetIn,'Visible','off')
                set(eraseIn,'Visible','off')
                set(insertSetIn,'Visible','off')
                set(insertIn,'Visible','off')
                set(clickIn,'Visible','off')
                set(lblClick,'Visible','off')
                set(defaultIn,'Visible','off')
                set(doneIn,'Visible','off')
                set(processIn,'Visible','off')
                set(dispSmoothBandsIn,'Visible','off')
                set(dispInterpClicksIn,'Visible','off')
                set(viewNotesIn,'Visible','off')
                set(lblAutoDetection,'Visible','off')
                if strcmp(get(autoDisableIn,'Visible'),'on')
                    wasAutoOn = 1;
                end
                set(autoDisableIn,'Visible','off')
                set(autoEnableIn,'Visible','off')
                set(saveScreenshotIn,'Visible','off')
                set(viewScreenshotsIn,'Visible','off')
                set(lblAutoDetectionEnabled,'Visible','off')
                set(lblAutoDetectionDisabled,'Visible','off')
            else
                wasMainScreen = 0;
            end

            set(calibrateProposedIn,'Visible','off')
            set(calibrateProposedOut,'Visible','off')
            set(filterEditIn,'Visible','off')
            set(filterEditOut,'Visible','on')
            set(aboutEditFiltersOut,'Visible','off')
            set(hideInterpIn,'Visible','off')
            set(showInterpIn,'Visible','off')
            set(saveScreenshotIn,'Visible','off')
            set(viewScreenshotsIn,'Visible','off')
            set(doneBandIn,'Visible','off')
            set(redoBandIn,'Visible','off')
            set(UndoLastClickIn,'Visible','off')
            set(drawDeleteBox1In,'Visible','off')
            set(drawDeleteBox2In,'Visible','off')

            drawnow
            pause(0.01)

            if ct == 1
                set(ha2,'Units','Pixels','Position',[875,40,200,200],'Units','normalized')
            end

            smoothParam1In = uicontrol(UserFig,'Style','slider',...
                'Position',[700,550,300,20],'Units','normalized',...
                'Min', 1,'Max', 10,'Value', h3_width/10,'Callback', @smoothParam1_Callback);

            smoothParam2In = uicontrol(UserFig,'Style','slider',...
                'Position',[700,475,300,20],'Units','normalized',...
                'Min', 1,'Max', 5,'Value', h3_std/10,'Callback', @smoothParam2_Callback);

            lblParam1 = uicontrol(UserFig,'Style','text','String',sprintf('Filter width: %s mm',num2str(smoothParam1In.Value)),'Position',[700,575,300,20],...
                'FontSize',10,'FontName','Arial','Units','normalized','BackgroundColor','none','ForegroundColor','w');

            lblParam2 = uicontrol(UserFig,'Style','text','String',sprintf('Filter standard deviation: %s mm',num2str(smoothParam2In.Value)),'Position',[700,500,300,20],...
                'FontSize',10,'FontName','Arial','Units','normalized','BackgroundColor','none','ForegroundColor','w');

            set(aboutEditFiltersIn,'Visible','on')

            if wasSmoothingOn == 0
                dispSmoothBands;
            end

        end

        function smoothParam1_Callback(src,event)
            conversion_factor = (1./hpxS).*0.1; %(pixels per 0.1mm)
            h3_width = smoothParam1In.Value*10;
            h3_std = smoothParam2In.Value*10;
            h3 = fspecial('gaussian',round(h3_width*conversion_factor), h3_std*conversion_factor);
            set(lblParam1,'String',sprintf('Filter width: %s mm',num2str(round(h3_width*10)/100)))
            set(lblParam2,'String',sprintf('Filter standard deviation: %s mm',num2str(round(h3_std*10)/100)))
            updateBandLines
        end

        function smoothParam2_Callback(src,event)
            conversion_factor = (1./hpxS).*0.1; %(pixels per 0.1mm)
            h3_width = smoothParam1In.Value*10;
            h3_std = smoothParam2In.Value*10;
            h3 = fspecial('gaussian',round(h3_width*conversion_factor), h3_std*conversion_factor);
            set(lblParam1,'String',sprintf('Filter width: %s mm',num2str(round(h3_width*10)/100)))
            set(lblParam2,'String',sprintf('Filter standard deviation: %s mm',num2str(round(h3_std*10)/100)))
            updateBandLines
        end

        function cancelEditFilters_fun(src,event)

            iptSetPointerBehavior(corePlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'custom', 'PointerShapeCData', band_pointer, 'PointerShapeHotSpot', band_pointer_hotspot));
            iptSetPointerBehavior(bandsPlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'custom', 'PointerShapeCData', band_pointer, 'PointerShapeHotSpot', band_pointer_hotspot));

            set(filterEditIn,'Visible','on')
            set(filterEditOut,'Visible','off')
            set(calibrateProposedIn,'Visible','off')
            set(calibrateProposedOut,'Visible','off')
            set(smoothParam1In,'Visible','off')
            set(smoothParam2In,'Visible','off')
            set(lblParam1,'Visible','off')
            set(lblParam2,'Visible','off')
            set(aboutEditFiltersIn,'Visible','off')
            set(aboutEditFiltersOut,'Visible','off')
            set(htextAbout2,'Visible','off')
            if wasMainScreen == 1
                set(htext1,'Visible','on')
                set(htext2,'Visible','on')
                set(htext3,'Visible','on')
                set(htext4,'Visible','on')
                set(htext5,'Visible','on')
                set(htext6,'Visible','on')
                set(htext7,'Visible','on')
                set(htext8,'Visible','on')
                set(htext9,'Visible','on')
                set(brightnessIn,'Visible','on')
                set(contrastIn,'Visible','on')
                set(thickIn,'Visible','on')
                set(positionIn,'Visible','on')
                set(rotationIn,'Visible','on')
                set(lblBright,'Visible','on')
                set(lblContrast,'Visible','on')
                set(lblThick,'Visible','on')
                set(lblPos,'Visible','on')
                set(lblRot,'Visible','on')
                set(projIn,'Visible','on')
                set(jumpSetIn,'Visible','on')
                set(jumpIn,'Visible','on')
                set(htext8b,'Visible','on')
                set(deleteSetIn,'Visible','on')
                set(deleteIn,'Visible','on')
                set(eraseSetIn,'Visible','on')
                set(eraseIn,'Visible','on')
                set(insertSetIn,'Visible','on')
                set(insertIn,'Visible','on')
                set(clickIn,'Visible','on')
                set(lblClick,'Visible','on')
                set(defaultIn,'Visible','on')
                set(doneIn,'Visible','on')
                set(processIn,'Visible','on')
                set(lblAutoDetection,'Visible','on')
                if wasSmoothingOn == 0
                    dispIntClicks
                    set(dispSmoothBandsIn,'Visible','on')
                    set(dispInterpClicksIn,'Visible','off')
                else
                    set(dispSmoothBandsIn,'Visible','off')
                    set(dispInterpClicksIn,'Visible','on')
                end
                set(viewNotesIn,'Visible','on')
                if wasAutoOn
                    set(autoDisableIn,'Visible','on')
                    set(lblAutoDetectionEnabled,'Visible','on')
                else
                    set(autoEnableIn,'Visible','on')
                    set(lblAutoDetectionDisabled,'Visible','on')
                end
                set(saveScreenshotIn,'Visible','on')
                set(viewScreenshotsIn,'Visible','on')
            else
                if washideInterpOn == 1
                    set(hideInterpIn,'Visible','on')
                else
                    set(showInterpIn,'Visible','on')
                end
                set(saveScreenshotIn,'Visible','on')
                set(viewScreenshotsIn,'Visible','on')
                set(doneBandIn,'Visible','on')
                set(redoBandIn,'Visible','on')

                if wasUndoOn == 1
                    set(UndoLastClickIn,'Visible','on')
                else
                    set(UndoLastClickIn,'Visible','off')
                end
                if wasDrawBoxOn1 == 1
                    set(drawDeleteBox1In,'Visible','on')
                else
                    set(drawDeleteBox1In,'Visible','off')
                end
                if wasDrawBoxOn2 == 1
                    set(drawDeleteBox2In,'Visible','on')
                else
                    set(drawDeleteBox2In,'Visible','off')
                end

                set(ha2,'Units','Pixels','Position',[675,100,400,400],'Units','normalized')
            end
        end

        function cancelAboutSmoothEdit_fun(src,event)

            set(filterEditIn,'Visible','off')
            set(filterEditOut,'Visible','on')
            set(smoothParam1In,'Visible','on')
            set(smoothParam2In,'Visible','on')
            set(lblParam1,'Visible','on')
            set(lblParam2,'Visible','on')
            set(aboutEditFiltersIn,'Visible','on')
            set(aboutEditFiltersOut,'Visible','off')
            set(htextAbout2,'Visible','off')

        end

        function aboutSmoothEdit_fun(src,event)

            set(filterEditIn,'Visible','off')
            set(filterEditOut,'Visible','off')
            set(smoothParam1In,'Visible','off')
            set(smoothParam2In,'Visible','off')
            set(lblParam1,'Visible','off')
            set(lblParam2,'Visible','off')
            set(aboutEditFiltersIn,'Visible','off')
            set(aboutEditFiltersOut,'Visible','on')

            about_text_label2 = sprintf(['Smoothing bands works by filtering the locations ' ...
                'of clicks placed along each band. Here, you can choose two different ' ...
                'parameters of the smoothing filter. The idea is to smooth your bands to ' ...
                'approximately match the smoothness of the coral bands visible in the underlying ' ...
                'image. The larger the filter parameters, the smoother your bands will be. ' ...
                'Extension rate analyses are based on these smoothed bands, so this will influence ' ...
                'the output data. ']);

            set(htextAbout2,'String',about_text_label2)

            about_text_wrapped2 = textwrap(htextAbout2,{htextAbout2.String});

            set(htextAbout2,'String',about_text_label2,'Visible','on','Units','pixels',...
                'Position',[650,300,400,300],'Units','normalized','HorizontalAlignment', 'left','BackgroundColor','none','ForegroundColor','w')

        end



        % Create functions that toggle sets of displays on or off:
        % default mode is what opens initially with ability to edit image
        % accept/reject mode occurs following auto-band detection
        % clicking mode occurs while defining a band

        function disableAll
            set(clickIn,'Enable','off')
            set(jumpIn,'Enable','off')
            set(eraseIn,'Enable','off')
            set(deleteIn,'Enable','off')
            set(insertIn,'Enable','off')
            set(projIn,'Enable','off')
            set(brightnessIn,'Enable','off')
            set(contrastIn,'Enable','off')
            set(thickIn,'Enable','off')
            set(rotationIn,'Enable','off')
            set(defaultIn,'Enable','off')
            set(doneIn,'Enable','off')
            set(processIn,'Enable','off')
            set(dispSmoothBandsIn,'Enable','off')
            set(dispInterpClicksIn,'Enable','off')
            set(viewNotesIn,'Enable','off')
            set(filterEditIn,'Enable','off')
            set(autoDisableIn,'Enable','off')
            set(autoEnableIn,'Enable','off')
            set(saveScreenshotIn,'Enable','off')
            set(viewScreenshotsIn,'Enable','off')
        end

        function enableAll
            set(clickIn,'Enable','on')
            set(jumpIn,'Enable','on')
            set(eraseIn,'Enable','on')
            set(deleteIn,'Enable','on')
            set(insertIn,'Enable','on')
            set(projIn,'Enable','on')
            set(brightnessIn,'Enable','on')
            set(contrastIn,'Enable','on')
            set(thickIn,'Enable','on')
            set(rotationIn,'Enable','on')
            set(defaultIn,'Enable','on')
            set(doneIn,'Enable','on')
            set(processIn,'Enable','on')
            set(dispSmoothBandsIn,'Enable','on')
            set(dispInterpClicksIn,'Enable','on')
            set(viewNotesIn,'Enable','on')
            set(filterEditIn,'Enable','on')
            set(autoDisableIn,'Enable','on')
            set(autoEnableIn,'Enable','on')
            set(saveScreenshotIn,'Enable','on')
            set(viewScreenshotsIn,'Enable','on')
        end

        function defaultMode
            set(acceptButMoreProposedIn,'Visible','off')
            set(acceptButManualProposedIn,'Visible','off')
            set(acceptAndDoneProposedIn,'Visible','off')
            set(rejectAndAutoProposedIn,'Visible','off')
            set(rejectAndManualProposedIn,'Visible','off')
            set(brightnessIn,'Visible','on')
            set(contrastIn,'Visible','on')
            set(htext2,'Visible','on')
            set(htext3,'Visible','on')
            if ct == 1
                set(thickIn,'Visible','on')
                set(positionIn,'Visible','on')
                set(rotationIn,'Visible','on')
                set(htext1,'Visible','on')
                set(htext4,'Visible','on')
                set(htext5,'Visible','on')
                set(htext6,'Visible','on')
                set(lblThick,'Visible','on')
                set(projIn,'Visible','on')
                set(lblPos,'Visible','on')
                set(lblRot,'Visible','on')
                set(ha2,'Units','Pixels','Position',[875,40,200,200],'Units','normalized')
                circlePlot
            end
            set(htext7,'Visible','on')
            set(htext8,'Visible','on')
            set(htext8b,'Visible','on')
            set(htext9,'Visible','on')
            set(lblBright,'Visible','on')
            set(lblContrast,'Visible','on')
            set(jumpSetIn,'Visible','on')
            set(jumpIn,'Visible','on')
            set(deleteSetIn,'Visible','on')
            set(eraseSetIn,'Visible','on')
            if previous_bands_fixing_mode == 1
                set(flipBandsIn,'Visible','on')
                set(twistBandsIn,'Visible','on')
                set(swapBandsIn,'Visible','on')
                set(shiftBandsIn,'Visible','on')
            end
            set(lblErased,'Visible','off')
            set(eraseIn,'Visible','on')
            set(deleteIn,'Visible','on')
            set(defaultIn,'Visible','on')
            set(doneIn,'Visible','on')
            set(clickIn,'Visible','on')
            set(doneBandIn,'Visible','off')
            set(redoBandIn,'Visible','off')
            set(drawDeleteBox1In,'Visible','off')
            set(drawDeleteBox2In,'Visible','off')
            set(UndoLastClickIn,'Visible','off')
            set(processIn,'Visible','on')
            if smoothedBandsDrawn == 0
                set(dispSmoothBandsIn,'Visible','on')
                set(dispInterpClicksIn,'Visible','off')
            else
                set(dispSmoothBandsIn,'Visible','off')
                set(dispInterpClicksIn,'Visible','on')
            end
            set(insertSetIn,'Visible','on')
            set(insertIn,'Visible','on')
            set(viewNotesIn,'Visible','on')
            set(filterEditIn,'Visible','on')
            set(hideNotesIn,'Visible','off')
            set(htextNotes,'Visible','off')
            set(hideInterpIn,'Visible','off')
            set(showInterpIn,'Visible','off')
            set(saveScreenshotIn,'Visible','on')
            set(viewScreenshotsIn,'Visible','on')
            %set(filterEditIn,'Visible','off')
            set(filterEditOut,'Visible','off')
            set(zoomInIn,'Visible','on')
            set(zoomInOut,'Visible','off')
            set(panIn,'Visible','on')
            set(panOut,'Visible','off')
            set(zoomOutIn,'Visible','on')

            if view_only == 1
                set(jumpSetIn,'Visible','off')
                set(jumpIn,'Visible','off')
                set(deleteSetIn,'Visible','off')
                set(eraseSetIn,'Visible','off')
                set(flipBandsIn,'Visible','off')
                set(twistBandsIn,'Visible','off')
                set(swapBandsIn,'Visible','off')
                set(shiftBandsIn,'Visible','off')
                set(eraseIn,'Visible','off')
                set(deleteIn,'Visible','off')
                set(doneIn,'String','Exit')
                set(clickIn,'Visible','off')
                set(processIn,'Visible','off')
                set(dispSmoothBandsIn,'Visible','off')
                set(dispInterpClicksIn,'Visible','off')
                set(insertSetIn,'Visible','off')
                set(insertIn,'Visible','off')

                set(flipBandsIn,'Visible','off')
                set(twistBandsIn,'Visible','off')
                set(swapBandsIn,'Visible','off')
                set(shiftBandsIn,'Visible','off')

                set(lblClick,'Visible','off')
                set(htext7,'Visible','off')
                set(htext8,'Visible','off')
                set(htext8b,'Visible','off')
                set(htext9,'Visible','off')
                set(autoDisableIn,'Visible','off')
                set(lblAutoDetection,'Visible','off')
                set(lblAutoDetectionEnabled,'Visible','off')
                set(lblAutoDetectionDisabled,'Visible','off')
                set(autoEnableIn,'Visible','off')
                set(saveScreenshotIn,'Visible','off')
                set(viewScreenshotsIn,'Visible','off')

            end

        end

        function acceptRejectOn
            set(acceptButMoreProposedIn,'Visible','on')
            set(acceptButManualProposedIn,'Visible','on')
            set(acceptAndDoneProposedIn,'Visible','on')
            set(rejectAndAutoProposedIn,'Visible','on')
            set(rejectAndManualProposedIn,'Visible','on')
            set(brightnessIn,'Visible','off')
            set(contrastIn,'Visible','off')
            set(thickIn,'Visible','off')
            set(positionIn,'Visible','off')
            set(rotationIn,'Visible','off')
            set(htext1,'Visible','off')
            set(htext2,'Visible','off')
            set(htext3,'Visible','off')
            set(htext4,'Visible','off')
            set(htext5,'Visible','off')
            set(htext6,'Visible','off')
            set(htext7,'Visible','off')
            set(htext8,'Visible','off')
            set(htext8b,'Visible','off')
            set(htext9,'Visible','off')
            set(lblBright,'Visible','off')
            set(lblContrast,'Visible','off')
            set(lblThick,'Visible','off')
            set(lblPos,'Visible','off')
            set(lblRot,'Visible','off')
            set(jumpSetIn,'Visible','off')
            set(jumpIn,'Visible','off')
            set(flipBandsIn,'Visible','off')
            set(twistBandsIn,'Visible','off')
            set(swapBandsIn,'Visible','off')
            set(shiftBandsIn,'Visible','off')
            set(deleteSetIn,'Visible','off')
            set(eraseSetIn,'Visible','off')
            set(eraseIn,'Visible','off')
            set(deleteIn,'Visible','off')
            set(defaultIn,'Visible','off')
            set(projIn,'Visible','off')
            set(doneIn,'Visible','off')
            set(clickIn,'Visible','off')
            set(doneBandIn,'Visible','off')
            set(redoBandIn,'Visible','off')
            set(drawDeleteBox1In,'Visible','off')
            set(drawDeleteBox2In,'Visible','off')
            set(UndoLastClickIn,'Visible','off')
            set(processIn,'Visible','off')
            set(dispSmoothBandsIn,'Visible','off')
            set(dispInterpClicksIn,'Visible','off')
            set(insertSetIn,'Visible','off')
            set(insertIn,'Visible','off')
            set(hideInterpIn,'Visible','off')
            set(showInterpIn,'Visible','off')
            set(zoomInIn,'Visible','off')
            set(zoomInOut,'Visible','off')
            set(panIn,'Visible','off')
            set(panOut,'Visible','off')
            set(zoomOutIn,'Visible','off')
        end

        function clickingMode
            set(acceptButMoreProposedIn,'Visible','off')
            set(acceptButManualProposedIn,'Visible','off')
            set(acceptAndDoneProposedIn,'Visible','off')
            set(rejectAndAutoProposedIn,'Visible','off')
            set(rejectAndManualProposedIn,'Visible','off')
            set(brightnessIn,'Visible','off')
            set(contrastIn,'Visible','off')
            set(thickIn,'Visible','off')
            set(positionIn,'Visible','off')
            set(rotationIn,'Visible','off')
            set(htext1,'Visible','off')
            set(htext2,'Visible','off')
            set(htext3,'Visible','off')
            set(htext4,'Visible','off')
            set(htext5,'Visible','off')
            set(htext6,'Visible','off')
            set(htext7,'Visible','off')
            set(htext8,'Visible','off')
            set(htext8b,'Visible','off')
            set(htext9,'Visible','off')
            set(lblBright,'Visible','off')
            set(lblContrast,'Visible','off')
            set(lblThick,'Visible','off')
            set(lblPos,'Visible','off')
            set(lblRot,'Visible','off')
            set(jumpSetIn,'Visible','off')
            set(jumpIn,'Visible','off')
            set(deleteSetIn,'Visible','off')
            set(deleteIn,'Visible','off')
            set(defaultIn,'Visible','off')
            set(projIn,'Visible','off')
            set(doneIn,'Visible','off')
            set(clickIn,'Visible','off')
            set(doneBandIn,'Visible','on')
            set(redoBandIn,'Visible','on')
            set(drawDeleteBox1In,'Visible','on')
            if ct == 1
                set(drawDeleteBox2In,'Visible','on')
                set(ha2,'Units','Pixels','Position',[675 100 400 400],'Units','normalized')
                %circlePlot
            end
            set(processIn,'Visible','off')
            set(dispSmoothBandsIn,'Visible','off')
            set(dispInterpClicksIn,'Visible','off')
            set(insertSetIn,'Visible','off')
            set(insertIn,'Visible','off')
            set(eraseSetIn,'Visible','off')
            set(eraseIn,'Visible','off')
            set(flipBandsIn,'Visible','off')
            set(twistBandsIn,'Visible','off')
            set(swapBandsIn,'Visible','off')
            set(shiftBandsIn,'Visible','off')
            set(viewNotesIn,'Visible','off')
            %set(filterEditIn,'Enable','off')
            set(hideNotesIn,'Visible','off')
            set(htextNotes,'Visible','off')
            if interpBandsPlotted == 1
                set(hideInterpIn,'Visible','on')
                set(showInterpIn,'Visible','off')
            end
            if smoothedBandsDrawn == 1
                set(filterEditIn,'Visible','on')
            else
                set(filterEditIn,'Visible','off')
            end
            set(filterEditOut,'Visible','off')
            %currentLimX = get(ha,'XLim');
            %currentLimY = get(ha,'YLim');
            set(zoomInIn,'Visible','off')
            set(zoomInOut,'Visible','off')
            set(panIn,'Visible','off')
            set(panOut,'Visible','off')
            set(zoomOutIn,'Visible','off')

        end


        function acceptRejectOff
            set(acceptButMoreProposedIn,'Visible','off')
            set(acceptButManualProposedIn,'Visible','off')
            set(acceptAndDoneProposedIn,'Visible','off')
            set(rejectAndAutoProposedIn,'Visible','off')
            set(rejectAndManualProposedIn,'Visible','off')
            if interpBandsPlotted == 1
                set(hideInterpIn,'Visible','on')
                set(showInterpIn,'Visible','off')
                set(bandsPlot,'Visible','on')
            end
        end

        function acceptRejectBackOn
            set(acceptButMoreProposedIn,'Visible','on')
            set(acceptButManualProposedIn,'Visible','on')
            set(acceptAndDoneProposedIn,'Visible','on')
            set(rejectAndAutoProposedIn,'Visible','on')
            set(rejectAndManualProposedIn,'Visible','on')
        end

        % Function to update display of image and intersections of bands
        function drawAndLabelBands

            set(lblLoading,'Visible','on')
            pause(0.01)
            if previous_bands_fixing_mode == 1
                inds2delete = [];
                totBands3 = find(max(max(userBands)));
                for i4 = totBands3'
                    if max(max(userBands(:,:,i4)))>0
                        [r,c] = find(userBands(:,:,i4));
                        if length(unique(r)) == 1 || length(unique(c)) == 1
                            inds2delete = [inds2delete;i4];
                        end
                    end
                end
                userBands(:,:,inds2delete) = [];
                totBands =length(find(max(max(userBands)))>0);
                if length(inds2delete) > 0
                    save(fullfile(fileOpen,name2search), 'userBands','x_ang','CoralCTversion','contra','proj','thick','h3_width','h3_std','h3_defined');
                end
                inds2delete = [];
            end

            if max(max(max(userBands)))>0
                totBands3 = find(max(max(userBands)));
                LDBdata = zeros(row,col,max(totBands3));
                for i4 = totBands3'
                    if max(max(userBands(:,:,i4)))>0
                        [r,c] = find(userBands(:,:,i4));
                        if ~isempty(r)
                            v = zeros(1,length(r));
                            for j2 = 1:length(r)
                                v(j2) = userBands(r(j2),c(j2),i4);
                            end
                            warning('off','all');
                            if length(round(griddata(r,c,v,rowMesh,colMesh)))>1
                                LDBdata(:,:,i4) = permute(round(griddata(r,c,v,rowMesh,colMesh)),[2,1,3]);
                            end
                            warning('on','all');
                        end
                    end
                end

                LDBdata(isnan(LDBdata)) = 0;
                ldbDraw = LDBdata;

                dispSlab
                pause(0.001)
                hold(ha,'on')
                xIntersect = NaN(max(totBands3),1);
                yIntersect = NaN(max(totBands3),1);
                for i4 = totBands3'
                    if max(max(userBands(:,:,i4)))>0
                        [r,c] = find(LDBdata(:,slab,i4));
                        hold(ha,'on')
                        if length(r)>0
                            if max(max(LDBdata(:,:,i4)))>0
                                xIntersect(i4) = median(r)*hpxS;
                                yIntersect(i4) = (LDBdata(round(median(r)),slab,i4)-layers)*-pxS;
                                text(ha,xIntersect(i4),yIntersect(i4),num2str(i4),'Color','yellow','Clipping','on');
                            end
                        end
                        hold(ha,'off')
                    end
                end
            else
                dispSlab
            end
            if smoothedBandsDrawn == 0
                set(dispSmoothBandsIn,'Visible','on')
                set(dispInterpClicksIn,'Visible','off')
            else
                set(dispSmoothBandsIn,'Visible','off')
                set(dispInterpClicksIn,'Visible','on')
            end
            %smoothedBandsDrawn = 0;
            set(lblLoading,'Visible','off')
        end


        function drawAndLabelSmoothedBands

            set(lblLoading,'Visible','on')
            pause(0.01)

            if max(max(max(userBands)))>0
                totBands3 = find(max(max(userBands)));
                LDBdata = zeros(row,col,length(userBands(1,1,1:max(totBands3))));
                band_filt4plot = zeros(size(LDBdata));
                surf_filt = h3;
                for i4 = totBands3'
                    if max(max(userBands(:,:,i4)))>0
                        [r,c] = find(userBands(:,:,i4));
                        if isempty(r)
                            break
                        end
                        v = zeros(1,length(r));
                        for j2 = 1:length(r)
                            v(j2) = userBands(r(j2),c(j2),i4);
                        end
                        warning('off','all');
                        if length(round(griddata(r,c,v,rowMesh,colMesh)))>1
                            LDBdata(:,:,i4) = permute(round(griddata(r,c,v,rowMesh,colMesh)),[2,1,3]);
                        end
                        warning('on','all');
                    end
                    band_filt4plot(:,:,i4) = nanconv(LDBdata(:,:,i4), surf_filt, 'nanout');
                end

                LDBdata(isnan(LDBdata)) = 0;
                band_filt4plot(isnan(band_filt4plot)) = 0;

                ldbDraw = band_filt4plot;

                dispSlab
                set(bandsPlot,'Color',[1 0.65 0])
                pause(0.001)
                hold(ha,'on')
                xIntersect = NaN(max(totBands3),1);
                yIntersect = NaN(max(totBands3),1);
                for i4 = totBands3'
                    if max(max(userBands(:,:,i4)))>0
                        [r,c] = find(LDBdata(:,slab,i4));
                        hold(ha,'on')
                        if length(r)>0
                            if max(max(LDBdata(:,:,i4)))>0
                                xIntersect(i4) = median(r)*hpxS;
                                yIntersect(i4) = (LDBdata(round(median(r)),slab,i4)-layers)*-pxS;
                                text(ha,xIntersect(i4),yIntersect(i4),num2str(i4),'Color',[1 0.65 0],'Clipping','on');
                            end
                        end
                        hold(ha,'off')
                    end
                end
            else
                dispSlab
                set(bandsPlot,'Color','m')
            end
            if smoothedBandsDrawn == 0
                set(dispSmoothBandsIn,'Visible','on')
                set(dispInterpClicksIn,'Visible','off')
            else
                set(dispSmoothBandsIn,'Visible','off')
                set(dispInterpClicksIn,'Visible','on')
            end
            set(lblLoading,'Visible','off')
        end

        function drawAndLabelBandsXray
            set(lblLoading,'Visible','on')
            pause(0.01)

            smoothed_on = 0;
            dispSlab
            pause(0.001)
            hold(ha,'on')
            totBands3 = find(max(userBands));
            xIntersect = NaN(max(totBands3),1);
            yIntersect = NaN(max(totBands3),1);
            for i4 = totBands3
                if max(max(userBands(:,i4)))>0
                    c = find(userBands(:,i4));
                    hold(ha,'on')
                    if length(c)>0
                        xIntersect(i4) = median(c)*hpxS;
                        interpLab = interp1(c,userBands(c,i4),round(median(c)));
                        text(ha,xIntersect(i4),interpLab*pxS,num2str(i4),'Color','y','Clipping','on');
                    end
                    hold(ha,'off')
                end
            end
            if smoothedBandsDrawn == 0
                set(dispSmoothBandsIn,'Visible','on')
                set(dispInterpClicksIn,'Visible','off')
            else
                set(dispSmoothBandsIn,'Visible','off')
                set(dispInterpClicksIn,'Visible','on')
            end
            set(lblLoading,'Visible','off')
        end

        function drawAndLabelSmoothedBandsXray
            set(lblLoading,'Visible','on')
            pause(0.01)

            smoothed_on = 1;
            totBands3 = find(max(userBands));
            LDBdata = zeros(col,max(totBands3));
            band_filt = NaN(size(LDBdata));
            h2d = sum(h3);
            h2mid = ceil(length(h3(:,1))/2);
            for i4 = totBands3
                if max(max(userBands(:,i4)))>0
                    c = find(userBands(:,i4));
                    if isempty(c)
                        break
                    end
                    this_band_interp = interp1(c,userBands(c,i4),min(c):max(c));

                    for i5 = min(c):max(c)
                        h2x = i5-h2mid:i5-h2mid+length(h2d)-1;
                        thisH2d = h2d;
                        thisH2d(h2x < min(c)) = [];
                        h2x(h2x < min(c)) = [];
                        thisH2d(h2x > max(c)) = [];
                        h2x(h2x > max(c)) = [];
                        h2x = h2x-min(c)+1;
                        thisH2d = thisH2d./sum(thisH2d);
                        band_filt(i5,i4) = sum(this_band_interp(h2x).*thisH2d);
                    end
                end
            end
            LDBdata = band_filt;

            dispSlab
            set(bandsPlot,'Color',[1 0.65 0])

            pause(0.001)
            hold(ha,'on')
            xIntersect = NaN(max(totBands3),1);
            yIntersect = NaN(max(totBands3),1);
            for i4 = totBands3
                if max(max(userBands(:,i4)))>0
                    c = find(LDBdata(:,i4));
                    hold(ha,'on')
                    if length(c)>0
                        if max(LDBdata(:,i4))>0
                            xIntersect(i4) = median(c)*hpxS;
                            yIntersect(i4) = (LDBdata(round(median(c)),i4))*pxS;
                            text(ha,xIntersect(i4),yIntersect(i4),num2str(i4),'Color',[1 0.65 0],'Clipping','on');
                        end
                    end
                    hold(ha,'off')
                end
            end
            if smoothedBandsDrawn == 0
                set(dispSmoothBandsIn,'Visible','on')
                set(dispInterpClicksIn,'Visible','off')
            else
                set(dispSmoothBandsIn,'Visible','off')
                set(dispInterpClicksIn,'Visible','on')
            end
            set(lblLoading,'Visible','off')
        end

        corePlot = [];
        bandsPlot = [];
        % Function to update display of image
        function dispSlab

            if haveLims == 0
                xs = [min([1:row].*hpxS),max([1:row].*hpxS)];
                ys = [min([1:layers].*pxS),max([1:layers].*pxS)];
            else
                ys = get(ha,'YLim');
                xs = get(ha,'XLim');
                %set(ha,'Visible','off')
                % ha_copy = uiaxes('Position',get(ha,'Position'));
                % xInds = round(xs(1)./hpxS):round(xs(2)./hpxS);
                % yInds = round(ys(1)./pxS):round(ys(2)./pxS);
                % xInds(xInds<1) = 1;
                % xInds(xInds>row) = row;
                % yInds(yInds<1) = 1;
                % yInds(yInds>layers) = layers;
                % corePlot2 = pcolor(ha_copy,xInds.*hpxS,yInds.*pxS,slabDraw(yInds,xInds));
                % set(ha_copy,'XLim',xs,'YLim',ys)
                % axis equal
                % if ct == 1
                %     set(corePlot2,'EdgeColor','none')
                %     set(corePlot2,'EdgeColor','interp')
                % end
                % set(ha_copy,'PlotBoxAspectRatio',[1 1 1])
                % set(ha_copy,'DataAspectRatio',[1 1 1])
                % set(ha_copy,'Colormap',colormap('bone'))
                % set(ha_copy,'CLim',contra);
                % drawnow
            end
            
            interpBandsPlotted = 0;
            set(lblLoading,'Visible','on')
            if ct == 1
                slabDraw = zeros(row,1,layers);
                if strcmp(proj,'min')
                    slabDraw(:,:,1:layers)  = min(X(:,slab-thick:slab+thick,:),[],2);
                elseif strcmp(proj,'mean')
                    slabDraw(:,:,1:layers)  = mean(X(:,slab-thick:slab+thick,:),2);
                elseif strcmp(proj,'max')
                    slabDraw(:,:,1:layers)  = max(X(:,slab-thick:slab+thick,:),[],2);
                end
                slabDraw = permute(slabDraw,[3,1,2]);
            end
            if ct == 1
                xInds = round(xs(1)./hpxS):round(xs(2)./hpxS);
                yInds = round(ys(1)./pxS):round(ys(2)./pxS);
                xInds(xInds<1) = 1;
                xInds(xInds>row) = row;
                yInds(yInds<1) = 1;
                yInds(yInds>layers) = layers;
                %hold off
                %axis equal
                %if sum(get(ha,'DataAspectRatio')==[1,1,1])<3 || range(get(ha,'XLim')) ~= range(get(ha,'YLim'))
                    %set(ha,'DataAspectRatio',[1,1,1]);
                    axis(ha,'equal')
                %end
                %ha_copy = copyobj(ha,UserFig)
                corePlot = pcolor(ha,xInds.*hpxS,yInds.*pxS,slabDraw(yInds,xInds));
                ys = get(ha,'YLim');
                xs = get(ha,'XLim');
                haveLims = 1;
                set(ha,'YColor','white')
                ylabel('mm')
                scalebar = patch(ha,xs(1)+[range(xs)*0.05, range(xs)*0.05, range(xs)*0.05+scale_mm,...
                    range(xs)*0.05+scale_mm, range(xs)*0.05],...
                    ys(1)+[range(ys)*0.03, range(ys)*0.035, range(ys)*0.035,...
                    range(ys)*0.03, range(ys)*0.03],themeColor1,'EdgeColor','none');
                scalebar1 = patch(ha,xs(1)+[range(xs)*0.05, range(xs)*0.05, range(xs)*0.055,...
                    range(xs)*0.055, range(xs)*0.05],...
                    ys(1)+[range(ys)*0.02, range(ys)*0.045, range(ys)*0.045,...
                    range(ys)*0.02, range(ys)*0.02],themeColor1,'EdgeColor','none');
                scalebar2 = patch(ha,xs(1)+[range(xs)*0.045+scale_mm, range(xs)*0.045+scale_mm, range(xs)*0.05+scale_mm,...
                    range(xs)*0.05+scale_mm, range(xs)*0.045+scale_mm],...
                    ys(1)+[range(ys)*0.02, range(ys)*0.045, range(ys)*0.045,...
                    range(ys)*0.02, range(ys)*0.02],themeColor1,'EdgeColor','none');
                scaleText = text(ha,xs(1)+range(xs)*0.06+scale_mm,...
                    ys(1)+range(ys)*0.03,'10 mm','FontSize',12,'FontWeight','bold',...
                    'Color',themeColor1,'VerticalAlignment','bottom');
            else
                corePlot = imagesc(ha,[1:col].*hpxS,[1:layers].*pxS,(slabDraw));
                ys = get(ha,'YLim');
                xs = get(ha,'XLim');
                scalebar = patch(ha,xs(1)+[range(xs)*0.05, range(xs)*0.05, range(xs)*0.05+scale_mm,...
                    range(xs)*0.05+scale_mm, range(xs)*0.05],...
                    ys(2)-[range(ys)*0.03, range(ys)*0.035, range(ys)*0.035,...
                    range(ys)*0.03, range(ys)*0.03],themeColor1,'EdgeColor','none');
                scalebar1 = patch(ha,xs(1)+[range(xs)*0.05, range(xs)*0.05, range(xs)*0.055,...
                    range(xs)*0.055, range(xs)*0.05],...
                    ys(2)-[range(ys)*0.02, range(ys)*0.045, range(ys)*0.045,...
                    range(ys)*0.02, range(ys)*0.02],themeColor1,'EdgeColor','none');
                scalebar2 = patch(ha,xs(1)+[range(xs)*0.045+scale_mm, range(xs)*0.045+scale_mm, range(xs)*0.05+scale_mm,...
                    range(xs)*0.05+scale_mm, range(xs)*0.045+scale_mm],...
                    ys(2)-[range(ys)*0.02, range(ys)*0.045, range(ys)*0.045,...
                    range(ys)*0.02, range(ys)*0.02],themeColor1,'EdgeColor','none');
                scaleText = text(ha,xs(1)+range(xs)*0.06+scale_mm,...
                    ys(2)-range(ys)*0.03,'10 mm','FontSize',12,'FontWeight','bold',...
                    'Color',themeColor1,'VerticalAlignment','bottom');
            end

            if strcmp(sectionName,'')
                dispTitleName = coralName;
            else
                dispTitleName = [coralName,' ',sectionName];
            end
            dispTitleName0 = double(dispTitleName);
            idxUnderScore = find(dispTitleName0==95);
            if length(idxUnderScore)
                dispTitleName = [];
                idxUnderScore = [0, idxUnderScore];
                for jjj = 2:length(idxUnderScore)
                    dispTitleName = [dispTitleName, dispTitleName0(idxUnderScore(jjj-1)+1:idxUnderScore(jjj)-1),92, 95];
                end
                dispTitleName = char([dispTitleName, dispTitleName0(idxUnderScore(jjj)+1:end)]);
            else
                %dispTitleName = coralName;
            end
            
            title(dispTitleName,'Color',themeColor1)

            hold(ha,'on')
            band_lines = [NaN,NaN];
            counter = 1;
            if ct == 1
                totBands3 = find(max(max(userBands)));
            else
                totBands3 = find(max(userBands));
            end
            if ct == 1
                for i4 = totBands3'
                    if max(max(userBands(:,:,i4)))>0
                        r = find(ldbDraw(:,slab,i4));
                        if length(r)>0
                            for i6 = 1:length(r)
                                counter = counter+1;
                                band_lines(counter,:) = [r(i6)*hpxS,(layers-ldbDraw(r(i6),slab,i4))*pxS];
                            end
                            band_lines(counter+1,:) = [NaN,NaN];
                            counter = counter+1;
                        end
                    end
                end
            else
                for i4 = totBands3
                    if max(userBands(:,i4))>0
                        if smoothed_on == 0
                            c = find(userBands(:,i4));
                            band_lines(counter+1:counter+length(c),:) = [c*hpxS,userBands(c,i4)*pxS];
                        else
                            c = find(LDBdata(:,i4));
                            band_lines(counter+1:counter+length(c),:) = [c*hpxS,LDBdata(c,i4)*pxS];
                        end
                        band_lines(counter+1+length(c),:) = [NaN,NaN];
                        counter = counter+length(c)+1;
                    end
                end
            end
            band_lines(band_lines(:,2) > ys(2),:) = NaN;
            band_lines(band_lines(:,1) > xs(2),:) = NaN;
            band_lines(band_lines(:,2) < ys(1),:) = NaN;
            band_lines(band_lines(:,1) < xs(1),:) = NaN;
            bandsPlot = plot(ha,band_lines(:,1),band_lines(:,2),'-','Color','y');
            if length(band_lines)>2
                interpBandsPlotted = 1;
            end
            hold(ha,'off')

            if ct == 1
                set(corePlot,'EdgeColor','none')
                set(corePlot,'EdgeColor','interp')
            end
            set(ha,'PlotBoxAspectRatio',[1 1 1])
            set(ha,'DataAspectRatio',[1 1 1])
            set(ha,'Colormap',colormap('bone'))
            set(ha,'CLim',contra);

            drawnow
            %set(ha,'Visible','on')
            % if exist('ha_copy')
            %     delete(ha_copy)
            % end

            set(lblLoading,'Visible','off')
            if haveLims==1
                set(ha,'YLim',ys)
                set(ha,'XLim',xs)
            end
            if ct == 1
                circlePlot
            end
        end

        % Function to display axial image
        function circlePlot

            %set(UserFig,'CurrentAxes',ha2);
            %axes(ha2)
            if j>1 && (max(max(temp_bands))>0 || max(max(max(userBands(:,:,j-1:j))))>0)

                if (max(max(temp_bands))>0 || max(max(userBands(:,:,j)))>0)
                    plot_bands = zeros(row,col,2);
                    plot_bands(:,:,1) = temp_bands;
                    plot_bands(:,:,2) = userBands(:,:,j);
                    these_user_bands = max(plot_bands,[],3);
                    title_num = num2str(j);
                    %coreSampLayer = round(median(these_user_bands(find(these_user_bands>0))));
                else
                    these_user_bands = userBands(:,:,j-1);
                    title_num = num2str(j-1);
                end
                coreSampLayer = round(median(these_user_bands(find(these_user_bands>0))));
                p_axial = pcolor(ha2,X(:,:,layers-coreSampLayer)');
                title(ha2,sprintf('band %s',title_num),'Color',themeColor1);
                %set(ha2,'XLim',xs)
                [r_blue,c_blue] = find(these_user_bands>0);
                hold(ha2,'on')
                b_points = plot(ha2,r_blue,c_blue,'.','Color','y','MarkerSize',10);
                hold(ha2,'off')
            elseif j==1 && (max(max(temp_bands))>0 || max(max(max(userBands(:,:,j))))>0)
                plot_bands = zeros(row,col,2);
                plot_bands(:,:,1) = temp_bands;
                plot_bands(:,:,2) = userBands(:,:,j);
                these_user_bands = max(plot_bands,[],3);
                coreSampLayer = round(median(these_user_bands(find(these_user_bands>0))));
                p_axial = pcolor(ha2,X(:,:,layers-coreSampLayer)');
                title(ha2,sprintf('band %s',num2str(j)),themeColor1);
                [r_blue,c_blue] = find(these_user_bands>0);
                hold(ha2,'on')
                b_points = plot(ha2,r_blue,c_blue,'.','Color','y','MarkerSize',10);
                hold(ha2,'off')
            else
                coreSampLayer = round(layers/2);
                p_axial = pcolor(ha2,X(:,:,coreSampLayer)');
            end
            set(p_axial,'EdgeColor','none')
            set(p_axial,'EdgeColor','interp')
            set(ha2,'PlotBoxAspectRatio',[1 1 1])
            set(ha2,'DataAspectRatio',[1 1 1])
            set(ha2,'Colormap',colormap('bone'))
            set(ha2,'CLim',contra);

            filteredCore = imfilter(X(:,:,layers+1-coreSampLayer), h2, 'replicate');
            coreSamp = imbinarize((filteredCore-min(min(filteredCore)))/max(max(filteredCore-min(min(filteredCore)))).*255);

            [ro,co] = find(coreSamp);

            [val,loc] = max(ro);
            tops = [co(loc),ro(loc)];
            [val,loc] = min(ro);
            bottoms = [co(loc),ro(loc)];
            [val,loc] = max(co);
            rights = [co(loc),ro(loc)];
            [val,loc] = min(co);
            lefts = [co(loc),ro(loc)];

            offsets = mean([rights(1)-lefts(1),tops(2)-bottoms(2)])*0.15;
            set(ha2,'Xtick',[],'Ytick',[],'CLim',contra,'XLim',...
                round([lefts(1)-offsets rights(1)+offsets]),'YLim',round([bottoms(2)-offsets tops(2)+offsets]))
            our_box = [1,slab-thick/2; 1,slab+thick/2; col,slab+thick/2; col,slab-thick/2; 1,slab-thick/2];
            hold(ha2,'on')
            p_box = plot(ha2,our_box(:,1),our_box(:,2),'r-','LineWidth',1);
            circle_j = j;
            % circle plot
            rad = max([rights(1)-lefts(1),tops(2)-bottoms(2)])/1.7;
            this_center = [mean([rights(1),lefts(1)]),slab];
            these_angles = linspace(+pi/(180/x_ang_new), pi+pi/(180/x_ang_new), 500);
            arc_x = rad * cos(these_angles) + this_center(1);
            arc_y = rad * sin(these_angles) + this_center(2);
            p_arc = plot(ha2,arc_x,arc_y,'-','Color','m');
            ticks_set = [0,45,90,135,180];
            ticks_plot = ticks_set+x_ang_new;
            for i2 = 1:length(ticks_set)
                dummy_x = linspace(rad*cosd(ticks_plot(i2))+this_center(1),this_center(1),100);
                dummy_y = linspace(rad*sind(ticks_plot(i2))+this_center(2),this_center(2),100);
                p_degrees = plot(ha2,[dummy_x(1),dummy_x(7)],[dummy_y(1),dummy_y(7)],'k-','Color','m');
                t_degrees = text(ha2,dummy_x(14),dummy_y(14),num2str(ticks_set(length(ticks_set)+1-i2)),...
                    'FontSize',9,'Color','m','HorizontalAlignment','center','FontWeight','bold','FontName','Arial');
            end
            hold(ha2,'off')
            drawnow
        end

        function checkOut = checkDone

            checkOut = areWeDone;

        end


        currentYlim = [];
        currentXlim = [];

        interpBandsPlotted = 0;
        x = [];
        y = [];
        lastPoint = [];
        lastPoint2 = [];

        function click_Callback(source,eventdata)

            x1 = [];
            y1 = [];

            iptSetPointerBehavior(corePlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'watch'));
            iptSetPointerBehavior(bandsPlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'watch'));

            pause(0.02)

            clickingMode

            pause(0.02)

            % if interpBandsPlotted == 1
            %     set(hideInterpIn,'Visible','on')
            %     set(showInterpIn,'Visible','off')
            % end

            if strcmp(get(autoEnableIn,'Visible'),'on')
                isEnableVis = 1;
                set(autoEnableIn,'Visible','off')
            else
                isEnableVis = 0;
            end


            function mouse_click(src,eventData)
                % get coordinates of click
                coords = eventData.IntersectionPoint;
                x1 = coords(1);
                y1 = coords(2);
                uiresume(UserFig)
            end

            pause(0.02)
            currentYlim = get(ha,'YLim');
            currentXlim = get(ha,'XLim');
            pause(0.02)

            hz.Enable = 'off';
            hp.Enable = 'off';

            %zoomPostCallback

            ha.InteractionOptions.ZoomSupported = "off";
            ha.InteractionOptions.PanSupported = "off";

            set(lblCheck,'Visible','off')
            set(lblDeleted,'Visible','off')

            areWeDone = 0;

            if ct == 1
                temp_bands = zeros(row,col);
                temp_bands_idx = zeros(row,col);
            else
                temp_bands = zeros(1,col);
                temp_bands_idx = zeros(1,col);
            end

            j = j+1;

            if ct == 1
                circlePlot
            end

            x = [];
            y = [];
            b = [];
            b1 = 1;
            bands = 0;
            apply_auto = 1;

            add2circle = 0;
            hold(ha,'on')
            iptSetPointerBehavior(corePlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'custom', 'PointerShapeCData', band_pointer, 'PointerShapeHotSpot', band_pointer_hotspot));
            iptSetPointerBehavior(bandsPlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'custom', 'PointerShapeCData', band_pointer, 'PointerShapeHotSpot', band_pointer_hotspot));
            b1 = 1;

            set(drawDeleteBox1In,'Visible','off')
            set(UndoLastClickIn,'Visible','off')

            pause(0.02)

            while areWeDone == 0

                textClick = sprintf('Currently on band %s',num2str(round(j)));
                set(lblClick,'String',textClick)

                pause(0.01);
                if areWeDone == 1
                    set(lblClick,'String',' ')
                    break
                end

                if (length(~isnan(xIntersect))+length(find(xIntersect==0)))<1
                    newRot = 0;
                end

                pointsFromIntersect = 0;
                if ct == 1
                    if j <= length(xIntersect)
                        if newRot == 1 && isnan(xIntersect(j)) == 0 && xIntersect(j) ~= 0 && autoDetectionToggle == 1
                            % simulate click on band intersection
                            apply_auto = 1;
                            x1 = xIntersect(j);
                            y1 = yIntersect(j);
                            pointsFromIntersect = 1;
                            b1 = 1;
                            xIntersect(j) = NaN;
                            yIntersect(j) = NaN;
                        else
                            set(0, 'CurrentFigure', UserFig);
                            set(corePlot,'ButtonDownFcn',@mouse_click)
                            set(bandsPlot,'ButtonDownFcn',@mouse_click)
                            uiwait(UserFig);
                            set(corePlot,'ButtonDownFcn','')
                            set(bandsPlot,'ButtonDownFcn','')
                        end
                    else
                        set(0, 'CurrentFigure', UserFig);
                        set(corePlot,'ButtonDownFcn',@mouse_click)
                        set(bandsPlot,'ButtonDownFcn',@mouse_click)
                        uiwait(UserFig);
                        set(corePlot,'ButtonDownFcn','')
                        set(bandsPlot,'ButtonDownFcn','')
                    end
                else
                    set(0, 'CurrentFigure', UserFig);
                    set(corePlot,'ButtonDownFcn',@mouse_click)
                    set(bandsPlot,'ButtonDownFcn',@mouse_click)
                    uiwait(UserFig);
                    set(corePlot,'ButtonDownFcn','')
                    set(bandsPlot,'ButtonDownFcn','')
                end

                if add2circle == 0
                    iptSetPointerBehavior(corePlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'watch'));
                    iptSetPointerBehavior(bandsPlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'watch'));
                end

                if ct == 1
                    plotcirc = 1;
                end

                if apply_auto==1 && autoDetectionToggle == 1 && ~isempty(y1)
                    iptSetPointerBehavior(corePlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'watch'));
                    iptSetPointerBehavior(bandsPlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'watch'));
                    if y1/pxS < layers && y1/pxS > 0 && x1/hpxS < col && x1/hpxS > 0
                        proposed_bands = bandDetection(x1,y1);
                        p_prop = plot(ha,proposed_bands(:,1).*hpxS,proposed_bands(:,2).*pxS,'mo');
                    end
                    breakLoop = 0;
                    continueAuto = 0;
                    acceptProposed = 0;
                    acceptRejectOn
                    set(calibrateProposedIn,'Visible','on')
                    while breakLoop == 0
                        pause(0.1)
                        apply_auto = 0;
                        if acceptProposed == 1
                            clickingMode
                            x1 = proposed_bands(:,1)'.*hpxS;
                            y1 = proposed_bands(:,2)'.*pxS;
                            plotcirc = 0;
                            k_count = 0;
                            for k = 1:length(proposed_bands(:,1))
                                if round(proposed_bands(k,1)) > 0 && layers-round(proposed_bands(k,2)) > 0
                                    k_count = k_count+1;
                                    if ct == 1
                                        temp_bands(round(proposed_bands(k,1)),slab-1:slab+1) = repmat(layers-round(proposed_bands(k,2)),[1,3]);
                                        temp_bands_idx(round(proposed_bands(k,1)),slab-1:slab+1) = k_count;
                                    else
                                        temp_bands(round(proposed_bands(k,1))) = layers-round(proposed_bands(k,2));
                                        temp_bands_idx(round(proposed_bands(k,1))) = k_count;
                                    end
                                end
                            end
                            if ct == 1
                                totBands = max([length(find(max(max(userBands)))>0),j]);
                            else
                                totBands = max([length(find(max(userBands))>0),j]);
                            end
                            try set(p_prop,'Visible','off')
                            catch
                            end
                            [xPlot, idxPlot] = sort(proposed_bands(:,1));
                            plot(ha,xPlot.*hpxS,proposed_bands(idxPlot,2).*pxS,'-','Color','white')
                            circlePlot
                            if continueAuto == 1
                                breakLoop = 1;
                                apply_auto = 1;
                            elseif continueAuto == 0
                                breakLoop = 1;
                                apply_auto = 0;
                            end
                        end
                        if acceptProposed == 2
                            clickingMode
                            if pointsFromIntersect == 1
                                x1 = [];
                                y1 = [];
                            end
                            try set(p_prop,'Visible','off')
                            catch
                            end
                            if continueAuto == 1
                                breakLoop = 1;
                                apply_auto = 1;
                            elseif continueAuto == 0
                                breakLoop = 1;
                                apply_auto = 0;
                            end
                        end
                    end
                    set(calibrateProposedIn,'Visible','off')
                    breakLoop = 0;
                    acceptProposed = 0;
                    if ct == 1
                        totBands = max([length(find(max(max(userBands)))>0),j]);
                    else
                        totBands = max([length(find(max(userBands))>0),j]);
                    end
                    iptSetPointerBehavior(corePlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'custom', 'PointerShapeCData', band_pointer, 'PointerShapeHotSpot', band_pointer_hotspot));
                    iptSetPointerBehavior(bandsPlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'custom', 'PointerShapeCData', band_pointer, 'PointerShapeHotSpot', band_pointer_hotspot));
                    clearvars proposed_bands
                end
                acceptProposed = 0;

                if length(x1)==1
                    lastPoint = scatter(ha,x1,y1,100,3000);
                    pause(0.01)
                end

                if (autoDetectionToggle == 1 && apply_auto == 0) || (apply_auto == 0 && length(x1)>=1)
                    set(drawDeleteBox1In,'Visible','on')
                    set(UndoLastClickIn,'Visible','on')
                end

                if need2delete == 1
                    inds4deletion = find(x>area2delete(1) & x<area2delete(1)+area2delete(3) &...
                        y>area2delete(2) & y<area2delete(2)+area2delete(4));
                    clicksDeleted = plot(ha,x(inds4deletion),y(inds4deletion),'yx','markersize',15);
                    x(inds4deletion) = [];
                    y(inds4deletion) = [];
                    for ic = 1:length(inds4deletion)
                        temp_bands(temp_bands_idx==inds4deletion(ic)) = 0;
                    end
                    set(clicksDeleted,'ButtonDownFcn',@mouse_click)
                    need2delete = 0;
                    delete(roi)
                end

                if need2delete2 == 1
                    [ro,co] = find(userBands(:,:,j));
                    inds4deletion = find(ro>area2delete2(1) & ro<area2delete2(1)+area2delete2(3) &...
                        co>area2delete2(2) & co<area2delete2(2)+area2delete2(4));
                    for ic = 1:length(inds4deletion)
                        userBands(ro(inds4deletion),co(inds4deletion),j) = 0;
                    end
                    need2delete2 = 0;
                    delete(roi2)
                    circlePlot
                    if ~isempty(x)
                        hold(ha2,'on')
                        plot(ha2,x./hpxS,slab,'.','Color','y','MarkerSize',10)
                        hold(ha2,'off')
                    end
                end

                if length(x1)>0
                    if ct == 1
                        temp_bands(round(x1/hpxS),slab-1:slab+1) = repmat(layers-round(y1/pxS),[3,1])';
                        temp_bands_idx(round(x1/hpxS),slab-1:slab+1) = length(x)+1;
                    else
                        temp_bands(round(x1/hpxS)) = layers-round(y1/pxS);
                        temp_bands_idx(round(x1/hpxS)) = length(x)+1;
                    end
                    if autoDetectionToggle == 0
                        set(UndoLastClickIn,'Visible','on')
                        set(drawDeleteBox1In,'Visible','on')
                    end
                end

                x = [x x1];
                y = [y y1];
                b = [b b1];

                if ct == 1
                    totBands = max([length(find(max(max(userBands)))>0),j]);
                else
                    totBands = max([length(find(max(userBands))>0),j]);
                end

                if areWeDone == 1
                    set(lblClick,'String',' ')
                    break
                end

                if ct == 1
                    if add2circle == 0
                        circlePlot
                        add2circle = 1;
                        iptSetPointerBehavior(corePlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'custom', 'PointerShapeCData', band_pointer, 'PointerShapeHotSpot', band_pointer_hotspot));
                        iptSetPointerBehavior(bandsPlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'custom', 'PointerShapeCData', band_pointer, 'PointerShapeHotSpot', band_pointer_hotspot));
                    else
                        hold(ha2,'on')
                        if length(x1)>0
                            lastPoint2 = plot(ha2,x1./hpxS,slab,'.','Color','y','MarkerSize',10);
                        end
                        hold(ha2,'off')
                    end
                else
                    iptSetPointerBehavior(corePlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'custom', 'PointerShapeCData', band_pointer, 'PointerShapeHotSpot', band_pointer_hotspot));
                    iptSetPointerBehavior(bandsPlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'custom', 'PointerShapeCData', band_pointer, 'PointerShapeHotSpot', band_pointer_hotspot));
                end
            end

            set(lblLoading,'Visible','on')
            iptSetPointerBehavior(corePlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'arrow'));
            iptSetPointerBehavior(bandsPlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'arrow'));
            if oops == 0
                %[xSort,idx] = sort(x);
                %ySort = y(idx);
                % hold(ha,'on')
                % plot(ha,xSort,ySort,'-','Color','white')
                % delete(findobj(ha, 'type', 'Scatter'));
                % hold(ha,'off')
                % drawnow
                textClick = sprintf('Next band will be band %s',num2str(round(j+1)));
                set(lblClick,'String',textClick)

                if ct == 1
                    [ro, co] = find(temp_bands);
                    for i2 = 1:length(ro)
                        userBands(ro(i2),co(i2),j) = temp_bands(ro(i2),co(i2));
                    end
                    temp_bands = zeros(row,col);
                    temp_bands_idx = zeros(row,col);
                else
                    userBands(:,j) = temp_bands;
                    temp_bands = zeros(1,col);
                    temp_bands_idx = zeros(1,col);
                end

                % keep track of how many bands identified for whole core
                clicks = length(b(b==1)) + length(b(b==3));
                if ct == 1
                    totBands = max([length(find(max(max(userBands)))>0),j-1]);
                else
                    totBands = max([length(find(max(userBands))>0),j-1]);
                end
                if j > totBands && clicks > 1
                    if ct == 1
                        totBands = max([length(find(max(max(userBands)))>0),j]);
                    else
                        totBands = max([length(find(max(userBands))>0),j]);
                    end
                end

                pause(0.01)
                save(fullfile(fileOpen,name2search), 'userBands','x_ang','CoralCTversion','contra','proj','thick','h3_width','h3_std','h3_defined');

                updateBandLines
                set(lblLoading,'Visible','off')
                % hold(ha,'on')
                % if ~isempty(x)
                %     text(x(1),y(1),num2str(j),'Color','white','Clipping','on')
                % end
                % hold(ha,'off')

            else
                hold(ha,'on')
                oops = 0;
                plot(ha,x,y,'yx','markersize',15)
                hold(ha,'off')
                pause(3)
                j = j-1;
                if smoothedBandsDrawn == 0
                    drawAndLabelBands
                else
                    drawAndLabelSmoothedBands
                end
                click_Callback
            end
            set(lblLoading,'Visible','off')
            defaultMode
            %ha.InteractionOptions.ZoomSupported = "on";
            %ha.InteractionOptions.PanSupported = "on";
            set(UndoLastClickIn,'Visible','off')
            set(drawDeleteBox1In,'Visible','off')
            if isEnableVis == 1
                set(autoEnableIn,'Visible','on')
            end

        end

        function clickXray_Callback(source,eventdata)

            x1 = [];
            y1 = [];

            iptSetPointerBehavior(corePlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'watch'));
            iptSetPointerBehavior(bandsPlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'watch'));

            pause(0.01)

            clickingMode

            pause(0.01)

            if strcmp(get(autoEnableIn,'Visible'),'on')
                isEnableVis = 1;
                set(autoEnableIn,'Visible','off')
            else
                isEnableVis = 0;
            end

            if interpBandsPlotted == 1
                set(hideInterpIn,'Visible','on')
                set(showInterpIn,'Visible','off')
            end

            function mouse_click(src,eventData)
                % get coordinates of click
                coords = eventData.IntersectionPoint;
                x1 = coords(1);
                y1 = coords(2);
                uiresume(UserFig)
            end

            pause(0.01)
            currentYlim = get(ha,'YLim');
            currentXlim = get(ha,'XLim');
            pause(0.01)

            hz.Enable = 'off';
            hp.Enable = 'off';

            ha.InteractionOptions.ZoomSupported = "off";
            ha.InteractionOptions.PanSupported = "off";

            set(lblCheck,'Visible','off')
            set(lblDeleted,'Visible','off')

            areWeDone = 0;

            j = j+1;

            x = [];
            y = [];
            b = [];
            apply_auto = 1;

            hold(ha,'on')
            iptSetPointerBehavior(corePlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'custom', 'PointerShapeCData', band_pointer, 'PointerShapeHotSpot', band_pointer_hotspot));
            iptSetPointerBehavior(bandsPlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'custom', 'PointerShapeCData', band_pointer, 'PointerShapeHotSpot', band_pointer_hotspot));
            b1 = 1;

            pause(0.01)

            while areWeDone == 0

                textClick = sprintf('Currently on band %s',num2str(round(j)));
                set(lblClick,'String',textClick)

                set(0, 'CurrentFigure', UserFig);
                set(corePlot,'ButtonDownFcn',@mouse_click)
                set(bandsPlot,'ButtonDownFcn',@mouse_click)
                uiwait(UserFig);
                set(corePlot,'ButtonDownFcn','')
                set(bandsPlot,'ButtonDownFcn','')

                lastPoint = scatter(ha,x1,y1,100,3000);
                pause(0.01)

                if apply_auto==1 && autoDetectionToggle == 1
                    iptSetPointerBehavior(corePlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'watch'));
                    iptSetPointerBehavior(bandsPlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'watch'));
                    if y1/pxS < layers && y1/pxS > 0 && x1/hpxS < col && x1/hpxS > 0
                        proposed_bands = bandDetection(x1,y1);
                        p_prop = plot(ha,proposed_bands(:,1).*hpxS,proposed_bands(:,2).*pxS,'mo');
                    end
                    breakLoop = 0;
                    continueAuto = 0;
                    acceptProposed = 0;
                    acceptRejectOn
                    set(calibrateProposedIn,'Visible','on')
                    while breakLoop == 0
                        pause(0.1)
                        apply_auto = 0;
                        if acceptProposed == 1
                            clickingMode
                            x1 = proposed_bands(:,1)'.*hpxS;
                            y1 = proposed_bands(:,2)'.*pxS;

                            try set(p_prop,'Visible','off')
                            catch
                            end
                            [xPlot, idxPlot] = sort(proposed_bands(:,1));
                            plot(ha,xPlot.*hpxS,proposed_bands(idxPlot,2).*pxS,'-','Color','white')

                            if continueAuto == 1
                                breakLoop = 1;
                                apply_auto = 1;
                            elseif continueAuto == 0
                                breakLoop = 1;
                                apply_auto = 0;
                            end
                        end
                        if acceptProposed == 2
                            clickingMode
                            try set(p_prop,'Visible','off')
                            catch
                            end
                            if continueAuto == 1
                                breakLoop = 1;
                                apply_auto = 1;
                            elseif continueAuto == 0
                                breakLoop = 1;
                                apply_auto = 0;
                            end
                        end
                    end
                    set(calibrateProposedIn,'Visible','off')

                    acceptProposed = 0;

                    totBands = max([length(find(max(userBands))>0),j]);

                    iptSetPointerBehavior(corePlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'custom', 'PointerShapeCData', band_pointer, 'PointerShapeHotSpot', band_pointer_hotspot));
                    iptSetPointerBehavior(bandsPlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'custom', 'PointerShapeCData', band_pointer, 'PointerShapeHotSpot', band_pointer_hotspot));
                    clearvars proposed_bands
                end
                acceptProposed = 0;

                if areWeDone == 1
                    set(lblClick,'String',' ')
                    break
                end

                if need2delete == 1
                    inds4deletion = find(x>area2delete(1) & x<area2delete(1)+area2delete(3) &...
                        y>area2delete(2) & y<area2delete(2)+area2delete(4));
                    clicksDeleted = plot(ha,x(inds4deletion),y(inds4deletion),'yx','markersize',15);
                    x(inds4deletion) = [];
                    y(inds4deletion) = [];
                    set(clicksDeleted,'ButtonDownFcn',@mouse_click)
                    need2delete = 0;
                    delete(roi)
                end

                if length(x1)>0
                    if autoDetectionToggle == 0
                        set(UndoLastClickIn,'Visible','on')
                        set(drawDeleteBox1In,'Visible','on')
                    end
                end

                x = [x x1];
                y = [y y1];
                b = [b b1];

                totBands = max([length(find(max(userBands))>0),j]);

                iptSetPointerBehavior(corePlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'custom', 'PointerShapeCData', band_pointer, 'PointerShapeHotSpot', band_pointer_hotspot));
                iptSetPointerBehavior(bandsPlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'custom', 'PointerShapeCData', band_pointer, 'PointerShapeHotSpot', band_pointer_hotspot));

            end

            set(lblLoading,'Visible','on')
            iptSetPointerBehavior(corePlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'arrow'));
            iptSetPointerBehavior(bandsPlot, @(UserFig, currentPoint)set(UserFig, 'Pointer', 'arrow'));
            if oops == 0
                [xSort,idx] = sort(x);
                ySort = y(idx);
                %hold(ha,'on')
                %plot(ha,xSort,ySort,'-','Color','white')
                %hold(ha,'off')
                %drawnow
                
                textClick = sprintf('Next band will be band %s',num2str(round(j+1)));
                set(lblClick,'String',textClick)

                userBands(round(x/hpxS),j) = round(y/pxS);

                % keep track of how many bands identified for whole core
                clicks = length(b(b==1)) + length(b(b==3));
                totBands = max([length(find(max(userBands))>0),j-1]);
                if j > totBands && clicks > 1
                    totBands = max([length(find(max(userBands))>0),j]);
                end

                pause(0.01)
                save(fullfile(fileOpen,name2search), 'userBands','x_ang','CoralCTversion','contra','proj','thick','h3_width','h3_std','h3_defined');

                updateBandLines
                
                set(lblLoading,'Visible','off')
                %hold(ha,'on')
                %text(x(1),y(1),num2str(j),'Color','white','Clipping','on')
                %hold(ha,'off')

            else
                hold(ha,'on')
                oops = 0;
                plot(ha,x,y,'yx','markersize',15)
                hold(ha,'off')
                j = j-1;
                click_Callback
            end
            set(lblLoading,'Visible','off')
            defaultMode
            %ha.InteractionOptions.ZoomSupported = "on";
            %ha.InteractionOptions.PanSupported = "on";
            set(UndoLastClickIn,'Visible','off')
            if isEnableVis == 1
                set(autoEnableIn,'Visible','on')
            end
        end

        howManyTimesGoneBack = 0;
        finishIn = [];
        requestNotesAgain = [];
        goBackIn = [];
        deletePrevOutputs = [];
        requestYearAgain = [];
        topBandYearText = [];
        topBandYearIn = [];
        process_notesIn = [];
        labelEnterNotes = [];
        confidenceBands = [];
        labelEnterConfidence = [];
        notes_entered = [];
        inputTopYear = [];
        function process_Callback(source,eventdata)

            try cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                cd(cache1,'CoralCache')
            catch
                try cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                    cd(cache1,'CoralCache')
                catch
                    try
                        connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                        connectionEstablished = 0;
                        for ij = 1:length(connectTimes)
                            if connectionEstablished == 0
                                if connectTimes(ij) == 1
                                    waitText = [' ',num2str(connectTimes(ij)),' minute.']
                                else
                                    waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                                end
                                set(lblOpeningError,'Units','Pixels','Visible','on','Position',[200,130,500,40],...
                                    'String',{'Error connecting to server.';strcat('Trying again in',waitText)},...
                                    'Units','normalized')
                                pause(connectTimes(ij)*60)
                                try
                                    cache1 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                    connectionEstablished = 1;
                                    set(lblOpeningError,'Units','Pixels','Visible','off',...
                                        'Position',[200,150,500,20],'Units','normalized')
                                catch
                                end
                            end
                        end
                        if connectionEstablished == 0
                            zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                        end
                    catch
                        set(lblOpeningError,'Units','Pixels','Position',[200,130,500,40],'Visible','on',...
                            'String',{'Error connecting to server. (code 030)';'Please try again later.'},...
                            'Units','normalized')
                        while 1==1
                            pause
                        end
                    end
                end
            end

            save(fullfile(fileOpen,name2search), 'userBands','x_ang','CoralCTversion','contra','proj','thick','h3_width','h3_std','h3_defined');

            exitClickMode

            % accept this and try more auto-detection
            if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
                confidenceBands = uiknob(UserFig,'Limits',[0 10],...
                    'Position',[600,650,60,60],'FontSize',12,'FontName','Arial',...
                    'FontColor',[1 1 1],'Value',0.001);
            else
                confidenceBands = uicontrol(UserFig,'Style','slider',...
                    'Position',[600,650,200,20],'Units','normalized',...
                    'Min', 0,'Max', 10,'Value', 0.001);
            end

            labelEnterConfidence = uicontrol(UserFig,'Style','text','String',...
                {'Rate your confidence in identifying bands:';'(1 = no confidence / 10 = highest)'},...
                'Position',[200 650 350 40],'BackgroundColor','none','ForeGroundColor',themeColor1,...
                'FontSize',12,'FontName','Arial','Units','normalized');

            this_year = collectionYear;
            try this_month = datestr(datetime(1,collectionMonth,1),'mmmm');
            catch
                this_month = '';
            end

            if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
                labelEnterNotes = uicontrol(UserFig,'Style','text','String',...
                    {'Please enter any notes to save'; 'with the output file'},...
                    'Position',[200 510 300 40],'BackgroundColor','none','ForeGroundColor',themeColor1,...
                    'FontSize',12,'FontName','Arial','Units','normalized');
            end

            topBandYearText = uicontrol(UserFig,'Style','text','String',...
                sprintf('Core %s was collected in %s %s.\nPlease estimate the calendar year of your first band:',coralName,this_month,num2str(this_year)),...
                'Visible','on','Position',[560,510,400,60],'Units','normalized',...
                'BackgroundColor','none','ForeGroundColor',themeColor1,'FontSize',12,'FontName','Arial');

            topBandYearIn = uicontrol(UserFig,'Style','Edit','Visible','on',...
                'Position',[700,480,100,25],'FontSize',12,'FontName','Arial',...
                'Callback',@topBandYear);

            function topBandYear(source,eventdata)
                if strcmp(get(requestYearAgain,'Visible'),'on')
                    try inputTopYear = str2num(topBandYearIn.String);
                        if inputTopYear>1900 && inputTopYear<2030
                            set(requestYearAgain,'Visible','off')
                        end
                    end
                end
            end

            goBackIn = uicontrol(UserFig,'Style','pushbutton',...
                'String',{'Go back'},'Visible','on',...
                'Position',[850,710,150,30],'Units','normalized','BackgroundColor',[0.97,0.90,0.61],...
                'FontSize',14,'FontName','Arial','Callback',@goBack);

            function goBack(src,event)

                howManyTimesGoneBack = howManyTimesGoneBack +1;
                set(finishIn,'Visible','off')
                set(requestNotesAgain,'Visible','off')
                set(goBackIn,'Visible','off')
                set(deletePrevOutputs,'Visible','off')

                set(requestYearAgain,'Visible','off')
                set(topBandYearText,'Visible','off')
                set(topBandYearIn,'Visible','off')
                if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
                    set(process_notesIn,'Visible','off')
                    set(labelEnterNotes,'Visible','off')
                end
                set(confidenceBands,'Visible','off')
                set(labelEnterConfidence,'Visible','off')
                areWeGoingBack = 1;
                core_run
                areWeGoingBack = 0;
            end

            notes_entered = 0;

            if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
                process_notesIn = uitextarea(UserFig,'Position',[200 200 300 300],...
                    'ValueChangedFcn',@(textarea,event) textEntered(textarea));
            else
                process_notesIn.Value = cell(1);
                process_notesIn.Value{1} = 'none';
            end

            function textEntered(textarea)
                val = textarea.Value;
                % Check each element of text area cell array for text
                for k = 1:length(val)
                    if(~isempty(val{k}))
                        notes_entered = 1;
                        break;
                    end
                end
            end

            finishIn = uicontrol(UserFig,'Style','pushbutton',...
                'String',{'Send outputs to CoralCache server'},'Visible','on',...
                'Position',[400,100,350,40],'Units','normalized','BackgroundColor',[0.61,0.86,0.57],....
                'ForegroundColor',[0,0,0],'FontSize',14,'FontName','Arial','Callback',@finish_fun);

            requestYearAgain = uicontrol(UserFig,'Style','text','String',...
                'Please estimate the top calendar year in YYYY format',...
                'Visible','off','Position',[375,150,400,25],'Units','normalized',...
                'ForegroundColor',themeColor2,'FontSize',12,'FontName','Arial',...
                'BackgroundColor',[0 0 0]);

            requestNotesAgain = uicontrol(UserFig,'Style','text','String',...
                'Are you sure you do not want to enter any notes?',...
                'Visible','off','Position',[375,70,400,25],'Units','normalized',...
                'ForegroundColor',themeColor2,'FontSize',12,'FontName','Arial',...
                'BackgroundColor',[0 0 0]);

            deletePrevOutputs = uicheckbox(UserFig,'Text','Delete your previous output files',...
                'Value',0,'Position',[420,30,250,25],...
                'FontSize',14,'FontName','Arial','FontColor',themeColor2);

            inputTopYear = 0;
            overRideNotes = 0;
            function finish_fun(source,eventdata)
                try inputTopYear = str2num(topBandYearIn.String);
                    if inputTopYear>1900 && inputTopYear<2030
                        set(requestYearAgain,'Visible','off')
                        if notes_entered == 1
                            % if howManyTimesGoneBack>0
                            %     for ij = 1:howManyTimesGoneBack
                            %         uiwait(UserFig)
                            %     end
                            % end
                            %uiresume(UserFig)
                            finishProcess
                        elseif overRideNotes == 1
                            % if howManyTimesGoneBack>0
                            %     for ij = 1:howManyTimesGoneBack
                            %         uiwait(UserFig)
                            %     end
                            % end
                            %uiresume(UserFig)
                            finishProcess
                        else
                            set(requestNotesAgain,'Visible','on')
                            set(finishIn,'String','Press again to proceed')
                            overRideNotes = 1;
                        end
                    else
                        set(requestYearAgain,'Visible','on')
                    end
                catch
                    %set(requestYearAgain,'Visible','on')
                end
            end
        end

        function finishProcess
            %uiwait(UserFig)

            set(finishIn,'Visible','off')
            set(requestNotesAgain,'Visible','off')
            set(goBackIn,'Visible','off')
            set(deletePrevOutputs,'Visible','off')

            set(requestYearAgain,'Visible','off')
            set(topBandYearText,'Visible','off')
            set(topBandYearIn,'Visible','off')
            if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
                set(process_notesIn,'Visible','off')
                set(labelEnterNotes,'Visible','off')
            end
            set(confidenceBands,'Visible','off')
            set(labelEnterConfidence,'Visible','off')
            set(lblLoading,'Visible','on')

            pause(0.01)

            try
                if serverChoice == 1
                    cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password);
                elseif serverChoice == 2
                    cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password);
                elseif serverChoice == 3
                    cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                end
            catch
                try
                    if serverChoice == 1
                        cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password);
                    elseif serverChoice == 2
                        cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password);
                    elseif serverChoice == 3
                        cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                    end
                catch
                    try
                        connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                        connectionEstablished = 0;
                        for ij = 1:length(connectTimes)
                            if connectionEstablished == 0
                                if connectTimes(ij) == 1
                                    waitText = [' ',num2str(connectTimes(ij)),' minute.']
                                else
                                    waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                                end
                                set(lblOpeningError,'Units','Pixels','Visible','on','Position',[200,130,500,40],...
                                    'String',{'Error connecting to server.';strcat('Trying again in',waitText)},...
                                    'Units','normalized')
                                pause(connectTimes(ij)*60)
                                try
                                    if serverChoice == 1
                                        cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password)
                                    elseif serverChoice == 2
                                        cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password)
                                    elseif serverChoice == 3
                                        cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                    end
                                    connectionEstablished = 1;
                                    set(lblOpeningError,'Units','Pixels','Visible','off',...
                                        'Position',[200,150,500,20],'Units','normalized')
                                catch
                                end
                            end
                        end
                        if connectionEstablished == 0
                            zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                        end
                    catch
                        set(lblOpeningError,'Units','Pixels','Position',[200,130,500,40],'Visible','on',...
                            'String',{'Error connecting to server. (code 011)';'Please try again later.'},...
                            'Units','normalized')
                        while 1==1
                            pause
                        end
                    end
                end
            end
            if strcmp('',thisSectionName)
                server_path = strcat(h_drive,coralDir.textdata{dirRow,3},'/',...
                    coralDir.textdata{dirRow,4},'/',thisCoralName);
            else
                server_path = strcat(h_drive,'/',coralDir.textdata{dirRow,3},'/',...
                    coralDir.textdata{dirRow,4},'/',thisCoralName,'/',thisSectionName);
            end
            if serverChoice == 1 || serverChoice == 3
                server_path(double(server_path)==32) = 95; % converts spaces to _
            end
            cd(cache2,server_path)

            % Before saving, check if we are working on a core that has
            % multiple sections.
            if strcmp('',sectionName) % no sections
                % set directory to this coral's folder on server
                mput(cache2,fullfile(fileOpen,strcat(saveName,coralName,'.mat')));
            else % yes, sections
                % set directory to this sections's folder on server
                mput(cache2,fullfile(fileOpen,strcat(saveName,coralName,'_',sectionName,'.mat')));
            end

            if ct == 1
                ha3 = uiaxes(UserFig,'Units','Pixels','Position',[200,160,500,50],'Units','normalized','Visible','off');
                ha3.InteractionOptions.DatatipsSupported = 'off';
                ha3.InteractionOptions.ZoomSupported = "off";
                ha3.InteractionOptions.PanSupported = "off";
                ha3.Toolbar.Visible = 'off';
                hold(ha3,'on')
                set(ha3,'Xtick',[],'YTick',[],'XLim',[0 1],'YLim',[0 1])
                processingGrowth = 1;
            end

            if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
                if ct == 1
                    set (ha3,'Units','Pixels','Position',[300,30,500,50],'Units','normalized')
                    dispVid = uihtml(UserFig);
                    dispVid.Position = [200,100,700,700];
                    dispVid.HTMLSource = (fullfile('loading_movies',strcat('analysis_movie.html')));
                    set(UserFig,'Color','k')
                    set(lblLoading,'BackGroundColor','k')
                else
                    dispVid = uihtml(UserFig);
                    dispVid.Position = [200,250,500,500];
                    rng('shuffle')
                    rand_vid = round(rand(1)*(n_loading_vids-1))+1;
                    dispVid.HTMLSource = (fullfile('loading_movies',strcat('core_movie',num2str(rand_vid),'.html')));
                    lblVideo = uicontrol(UserFig,'Style','text','String',videoLabel(rand_vid),'Position',[200,250,500,20],...
                        'FontSize',10,'FontName','Arial','Units','normalized','BackgroundColor','none');
                end

            end

            pause(0.001)

            if ct == 1
                set(ha3,'Visible','on')
                x_ang_old = x_ang_new;
                % update 'x_ang_new' with user's selected rotation
                x_ang_new = 0;
                % calculate difference between previous and new rotation
                x_ang_dif = x_ang_new-x_ang_old;
                % rotate 'X' (the CT scan data)
                X = imrotate3(X,x_ang_dif,[0,0,1],'linear','crop','FillValues',-1000);
                % rotate userBands
                userBands = imrotate3(userBands,x_ang_dif,[0,0,1],'nearest','crop','FillValues',0);

                userBands(userBands==0) = NaN;
                userBands = layers-userBands;
                userBands(isnan(userBands)) = 0;

                buildCore

                try extension_rate

                    % average density between bands (all voxels between the bands)
                    densityBetweenBands

                catch
                    % something is wrong with the bands such as out of
                    % order or missing numbers or crossing
                    youMessedUp = uicontrol(UserFig,'Style','text','String',...
                        'Error with banding, cannot process. (code 023)',...
                        'Visible','on','Position',[375,90,400,25],'Units','normalized',...
                        'ForegroundColor',themeColor2,'FontSize',12,'FontName','Arial',...
                        'BackgroundColor',[0 0 0]);
                    pause
                    while 1 ~= 2
                        pause
                    end
                end

            else

                userBands(userBands==0) = NaN;
                userBands = layers-userBands;
                userBands(isnan(userBands)) = 0;

                extension_rate_Xray
                densityBetweenBandsXray
                densityTotal = (densityTotal-HU2dens(2))/HU2dens(1);
            end

            % retain only central 90% of extensions
            for iii = 1:length(extension(:,1))
                checkNaNs = find(~isnan(extension(iii,:)));
                q1 = quantile(extension(iii,checkNaNs),0.05);
                q2 = quantile(extension(iii,checkNaNs),0.95);
                extension(iii,extension(iii,checkNaNs)<q1 | extension(iii,checkNaNs)>q2) = NaN;
            end

            densityTotal = flipud(densityTotal);
            travelTotal = flipud(nanmean(extension,2));
            travelTotal_std = flipud(nanstd(extension,[],2));
            calcifTotal = densityTotal.*travelTotal;
            calcifTotal_std = densityTotal.*travelTotal_std;
            HUmean = densityTotal*HU2dens(1)+HU2dens(2);

            if ct == 1
                % Compute volume and density
                volumeDensity

                delete(ha3)
                processingGrowth = 0;
            end

            set(lblLoading,'Visible','off')

            if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
                delete(dispVid)
                if ct == 1
                    set(UserFig,'Color',themeColor2)
                else
                    delete(lblVideo)
                end
            end

            ctOrXray = 'CT';
            if ct == 0
                ctOrXray = 'Xray';
                volume = NaN;
                densityWholeCore = NaN;
            end

            % save output in coral folder
            fid2 = fopen(fullfile(fileOpen,strcat('calcification_output_',saveName,char(datetime('today')),'.csv')),'w');
            % print column headers
            fprintf(fid2,'%s\n',strcat(['Using bands defined by ',saveName]));
            fprintf(fid2,'%s\n',['name,','whole-core mean density (g cm^-3),','whole-core mean HU,','volume (cm^3),','number of images,','horizontal pixel spacing (mm),','vertical pixel spacing (mm),','confidence rating,','CT or Xray,','CoralCT version,','Bands filter width (mm),','Bands filter std dev (mm),']);
            versionTextPrint = strcat(num2str(floor(CoralCTversion*10)/10),'.',num2str(round((CoralCTversion-floor(CoralCTversion*10)/10)*100)));
            fprintf(fid2, '%s\n',  strcat(coralName,...
                ', ',num2str(densityWholeCore),', ',num2str(densityWholeCore*HU2dens(1)+HU2dens(2)),...
                ', ',num2str(volume),', ',num2str(layers),', ',num2str(hpxS),', ',num2str(pxS),', ',num2str(confidenceBands.Value),', ',ctOrXray,', ',versionTextPrint,...
                ', ',num2str(h3_width/10), ', ',num2str(h3_std/10)));
            if notes_entered == 1
                fprintf(fid2,'%s',strcat('Processing notes:',', ',process_notesIn.Value{1}));
                if length(process_notesIn.Value) > 1
                    for jj = 2:length(process_notesIn.Value)
                        fprintf(fid2,'; %s',process_notesIn.Value{jj});
                    end
                end
            else
                fprintf(fid2,'%s',strcat('Processing notes: none'));
            end
            check_notes = double(coralDir.textdata{dirRow,7});
            brks = find(check_notes==36);
            if length(brks>0)
                theseNotes = cell(length(brks)+1,1);
                lastPlace = 1;
                for ic = 1:length(brks)
                    theseNotes{ic} = char(check_notes(lastPlace:brks(ic)-1));
                    lastPlace = brks(ic)+1;
                end
                theseNotes{ic+1} = char(check_notes(lastPlace:end));
            else
                theseNotes = cell(1);
                theseNotes{1} = char(check_notes);
            end
            if length(theseNotes) == 1
                fprintf(fid2,'\n%s',strcat('Additional notes:',', ',theseNotes{1}));
            else
                fprintf(fid2,'\n%s',strcat('Additional notes:'));
                for ic = 1:length(theseNotes)
                    fprintf(fid2,'\n%s',strcat(theseNotes{ic}));
                end
            end
            fprintf(fid2,'\n\n%s\n','Top of Core');
            fprintf(fid2,'%s\n',strcat('band',', ','Estimated year',', ','Hounsfield Units',', ','Density (g cm^-3)',', ',...
                'Extension (cm)',', ','Extension standard deviation (cm)',', ','Calcification (g cm^-2 yr^-1)',...
                ', ','Calcification standard deviation (g cm^-2 yr^-1)'));
            for iY = length(densityTotal):-1:1
                fprintf(fid2,'%s\n', strcat(num2str(length(densityTotal)-iY+1),', ',...
                    num2str(inputTopYear +1 - (length(densityTotal)-iY+1)),', ',...
                    num2str(HUmean(iY)),', ',...
                    num2str(densityTotal(iY)),', ',...
                    num2str(travelTotal(iY)/10),', ',...
                    num2str(travelTotal_std(iY)/10),', ',...
                    num2str(calcifTotal(iY)/10),', ',...
                    num2str(calcifTotal_std(iY)/10)));
            end
            fprintf(fid2,'%s\n','Bottom of Core');
            fprintf(fid2,'%s\n',' ');
            fprintf(fid2,'%s\n',' ');
            fclose(fid2);

            if deletePrevOutputs.Value == 1
                dirInit = dir(cache2);
                indsWithBands = [];
                dirOutput = [];
                for iii = 1:length(dirInit)
                    if length(strsplit(dirInit(iii).name,'.csv'))==2
                        indsWithBands = [indsWithBands; iii];
                        thisName = strsplit(dirInit(iii).name,'.csv');
                        dirOutput = [dirOutput; thisName(1)];
                    end
                end

                for iii = 1:length(dirOutput)
                    getInits = strsplit(dirOutput{iii},'_'); % initials in the csv file
                    chosenInits0 = strsplit(saveFileName,'_');
                    chosenInits = chosenInits0{1}; % initials in the chosen file
                    if strcmp(getInits{3},chosenInits)
                        delete(cache2,strcat(dirOutput{iii},'.csv'));
                    end
                end
            end

            mput(cache2,fullfile(fileOpen,strcat('calcification_output_',saveName,char(datetime('today')),'.csv')));

            delete(fullfile(fileOpen,strcat('calcification_output_',saveName,char(datetime('today')),'.csv')))

            close(cache2)

            try mget(cache1,'log.csv',strcat(refPath));
            catch
                try mget(cache1,'log.csv',strcat(refPath));
                catch
                    set(lblOpeningError,'Visible','on','String',{'Error connecting to server. (code 012)';'Please try again later.'})
                    pause
                    while 1 ~= 2
                        pause
                    end
                end
            end
            fid4 = fopen(fullfile(refPath,'log.csv'));
            coresLog = textscan(fid4,'%s %s %s %s %s %s %s %s','Delimiter',',');
            n_entries = length(coresLog{1});
            log_users = coresLog{1};
            log_cores = coresLog{2};
            log_dates = coresLog{3};
            log_bands = coresLog{4};
            log_conf = coresLog{5};
            log_contra1 = coresLog{6};
            log_contra2 = coresLog{7};
            log_thick = coresLog{8};

            add2leaders = find(strcmp(log_users,saveFileName) & strcmp(log_cores,coralName));
            if ~length(add2leaders) > 0 % this user has not analyzed this core before
                try mget(cache1,'leaderboard_names.xlsx',strcat(refPath));
                catch
                    try mget(cache1,'leaderboard_names.xlsx',strcat(refPath));
                    catch
                        set(lblOpeningError,'Visible','on','String',{'Error connecting to server. (code 013)';'Please try again later.'})
                        pause
                        while 1 ~= 2
                            pause
                        end
                    end
                end
                [leader_data,leader_text,leader_raw] = xlsread(fullfile(refPath,'leaderboard_names.xlsx'));
                userIdx = find(strcmp(leader_text(:,1),saveFileName));
                if length(userIdx) == 1 % this user exists already
                    leader_raw{userIdx,4} = leader_raw{userIdx,4}+1;
                    leader_raw{userIdx,5} = leader_raw{userIdx,5}+length(densityTotal);
                    leader_raw{userIdx,6} = leader_raw{userIdx,6}+length(densityTotal);
                    writecell(leader_raw,fullfile(refPath,'leaderboard_names.xlsx'));
                    try mput(cache1,fullfile(refPath,'leaderboard_names.xlsx'));
                    catch
                        try mput(cache1,fullfile(refPath,'leaderboard_names.xlsx'));
                        catch
                            set(lblOpeningError,'Visible','on','String',{'Error connecting to server. (code 014)';'Please try again later.'})
                            pause
                            while 1 ~= 2
                                pause
                            end
                        end
                    end
                    delete(fullfile(refPath,'leaderboard_names.xlsx'))
                else % add user to leaderboard (removed from public version)
                    n_leaders_now = length(leader_raw(:,1));
                    mget(cache1,'user_directory_names.csv',refPath);
                    fid = fopen(fullfile(refPath,'user_directory_names.csv'));
                    users = textscan(fid,'%s %s %s %s %s','Delimiter',',');
                    fclose(fid);
                    try delete(fullfile(refPath,'user_directory_names.csv'))
                    catch
                    end
                    idx_user = find(strcmp(users{1},saveFileName));
                    this_first_name = users{4}{idx_user};
                    this_last_name = users{5}{idx_user};
                    leader_raw(n_leaders_now+1,:) = {saveFileName, this_first_name, this_last_name, 1, length(densityTotal), length(densityTotal)};
                    writecell(leader_raw,fullfile(refPath,'leaderboard_names.xlsx'));
                    try mput(cache1,fullfile(refPath,'leaderboard_names.xlsx'));
                    catch
                        try mput(cache1,fullfile(refPath,'leaderboard_names.xlsx'));
                        catch
                            set(lblOpeningError,'Visible','on','String',{'Error connecting to server. (code 015)';'Please try again later.'})
                            pause
                            while 1 ~= 2
                                pause
                            end
                        end
                    end
                    delete(fullfile(refPath,'leaderboard_names.xlsx'))
                end
            else % are we adding bands?
                prev_of_this_core = log_bands(add2leaders);
                n_bands_previously = zeros(length(prev_of_this_core),1);
                for jj = 1:length(prev_of_this_core)
                    n_bands_previously(jj) = str2num(prev_of_this_core{jj});
                end
                if max(n_bands_previously) < length(densityTotal) % we added some bands
                    band2add4leaderboard = length(densityTotal)-max(n_bands_previously);
                    try mget(cache1,'leaderboard_names.xlsx',strcat(refPath));
                    catch
                        try mget(cache1,'leaderboard_names.xlsx',strcat(refPath));
                        catch
                            set(lblOpeningError,'Visible','on','String',{'Error connecting to server. (code 016)';'Please try again later.'})
                            pause
                            while 1 ~= 2
                                pause
                            end
                        end
                    end
                    [leader_data,leader_text,leader_raw] = xlsread(fullfile(refPath,'leaderboard_names.xlsx'));
                    userIdx = find(strcmp(leader_text(:,1),saveFileName));
                    leader_raw{userIdx,5} = leader_raw{userIdx,5}+length(densityTotal)-max(n_bands_previously);
                    leader_raw{userIdx,6} = leader_raw{userIdx,6}+length(densityTotal)-max(n_bands_previously);
                    writecell(leader_raw,fullfile(refPath,'leaderboard_names.xlsx'));
                    try mput(cache1,fullfile(refPath,'leaderboard_names.xlsx'));
                    catch
                        try mput(cache1,fullfile(refPath,'leaderboard_names.xlsx'));
                        catch
                            set(lblOpeningError,'Visible','on','String',{'Error connecting to server. (code 017)';'Please try again later.'})
                            pause
                            while 1 ~= 2
                                pause
                            end
                        end
                    end
                    delete(fullfile(refPath,'leaderboard_names.xlsx'))
                end
            end

            if strcmp(sectionName,'')
                name2save = strcat(coralName);
            else
                name2save = strcat(coralName,'_',sectionName);
            end

            log_users{n_entries+1} = saveFileName;
            log_cores{n_entries+1} = name2save;
            log_dates{n_entries+1} = char(datetime('today'));
            log_bands{n_entries+1} = num2str(length(densityTotal));
            log_conf{n_entries+1} = num2str(confidenceBands.Value);
            log_contra1{n_entries+1} = contra(1);
            log_contra2{n_entries+1} = contra(2);
            log_thick{n_entries+1} = thick;

            C = [log_users log_cores log_dates log_bands log_conf log_contra1 log_contra2 log_thick];

            writecell(C,fullfile(refPath,'log.csv'));
            try fclose(fid);
            catch
            end
            try mput(cache1,fullfile(refPath,'log.csv'));
            catch
                try mput(cache1,fullfile(refPath,'log.csv'));
                catch
                    set(lblOpeningError,'Visible','on','String',{'Error connecting to server. (code 018)';'Please try again later.'})
                    pause
                    while 1 ~= 2
                        pause
                    end
                end
            end
            delete(fullfile(refPath,'log.csv'))

            set(UserFig,'Color',themeColor2)
            resetAxes
            mainMenu
            moveOn = 1;

        end

        function exitClickMode

            set(acceptButMoreProposedIn,'Visible','off')
            set(acceptButManualProposedIn,'Visible','off')
            set(acceptAndDoneProposedIn,'Visible','off')
            set(rejectAndAutoProposedIn,'Visible','off')
            set(rejectAndManualProposedIn,'Visible','off')
            set(brightnessIn,'Visible','off')
            set(contrastIn,'Visible','off')
            set(thickIn,'Visible','off')
            set(positionIn,'Visible','off')
            set(rotationIn,'Visible','off')
            set(htext1,'Visible','off')
            set(htext2,'Visible','off')
            set(htext3,'Visible','off')
            set(htext4,'Visible','off')
            set(htext5,'Visible','off')
            set(htext6,'Visible','off')
            set(htext7,'Visible','off')
            set(htext8,'Visible','off')
            set(htext8b,'Visible','off')
            set(htext9,'Visible','off')
            set(lblBright,'Visible','off')
            set(lblContrast,'Visible','off')
            set(lblThick,'Visible','off')
            set(lblPos,'Visible','off')
            set(lblRot,'Visible','off')
            set(jumpSetIn,'Visible','off')
            set(jumpIn,'Visible','off')
            set(deleteSetIn,'Visible','off')
            set(deleteIn,'Visible','off')
            set(defaultIn,'Visible','off')
            set(projIn,'Visible','off')
            set(doneIn,'Visible','off')
            set(clickIn,'Visible','off')
            set(doneBandIn,'Visible','off')
            set(redoBandIn,'Visible','off')
            set(drawDeleteBox1In,'Visible','off')
            set(drawDeleteBox2In,'Visible','off')
            %set(resetBandIn,'Visible','off')
            set(processIn,'Visible','off')
            set(dispSmoothBandsIn,'Visible','off')
            set(dispInterpClicksIn,'Visible','off')
            set(insertSetIn,'Visible','off')
            set(insertIn,'Visible','off')
            set(eraseSetIn,'Visible','off')
            set(eraseIn,'Visible','off')
            set(lblClick,'Visible','off')
            set(lblLoading,'Visible','off')
            set(autoDisableIn,'Visible','off')
            set(autoEnableIn,'Visible','off')
            set(lblAutoDetectionDisabled,'Visible','off')
            set(lblAutoDetectionEnabled,'Visible','off')
            set(lblAutoDetection,'Visible','off')
            set(saveScreenshotIn,'Visible','off')
            set(viewScreenshotsIn,'Visible','off')
            set(flipBandsIn,'Visible','off')
            set(twistBandsIn,'Visible','off')
            set(swapBandsIn,'Visible','off')
            set(shiftBandsIn,'Visible','off')

            set(viewNotesIn,'Visible','off')
            set(filterEditIn,'Visible','off')
            set(hideNotesIn,'Visible','off')
            set(htextNotes,'Visible','off')

            set(panIn,'Visible','off')
            set(panOut,'Visible','off')
            set(zoomInIn,'Visible','off')
            set(zoomInOut,'Visible','off')
            set(zoomOutIn,'Visible','off')

            delete(p1)

            delete(ha)

            if ct == 1
                delete(ha2)
                delete(p_axial)
                delete(p_arc)
                delete(p_box)
                delete(b_points)
                delete(p_degrees)
                delete(t_degrees)
            end

        end

        function resetAxes

            currentRegion = [];
            currentSubRegion = {' '};
            coralName = [];

            % Create worldmap to view cores
            h_map1 = uiaxes(UserFig,'Units','Pixels','Position',[100 395 450 275],'Color','none','Visible','off','Units','normalized');
            h_map1.InteractionOptions.DatatipsSupported = 'off';
            h_map1.InteractionOptions.ZoomSupported = "off";
            h_map1.InteractionOptions.PanSupported = "off";
            set(0,'CurrentFigure',figtemp1);
            pWorldMap = worldmap([-90 90],[20 380]);
            plabel('off')
            mlabel('off')
            geoshow('landareas.shp', 'FaceColor', [0 0 0])
            plotm(coralDir.data(:,3),coralDir.data(:,4),'ko','MarkerEdgeColor','k', 'MarkerFaceColor',[0.96,0.51,0.58]);
            axcopy = copyobj(pWorldMap.Children,h_map1);
            h_map2 = uiaxes(UserFig,'Units','Pixels','Position',[100 75 450 275],'Visible','off','Color','none','Units','normalized');
            h_map2.InteractionOptions.DatatipsSupported = 'off';
            h_map2.InteractionOptions.ZoomSupported = "off";
            h_map2.InteractionOptions.PanSupported = "off";

            h_map_cover = uiaxes(UserFig,'Units','Pixels','Position',[30 40 540 640],'Color',themeColor2,'Visible','on','Units','normalized');
            set(h_map_cover,'Xlim',[0,1],'YLim',[0,1],'XTick',[],'YTick',[],'xcolor',themeColor2,'ycolor',themeColor2)
            patch(h_map_cover,[0,1],[0,1],themeColor2,'EdgeColor','none')
            h_map_cover.InteractionOptions.DatatipsSupported = 'off';
            h_map_cover.InteractionOptions.ZoomSupported = "off";
            h_map_cover.InteractionOptions.PanSupported = "off";
            h_map_cover.Toolbar.Visible = 'off';

            h_preview = uiaxes(UserFig,'Units','Pixels','Position',[30 40 540 640],'Color',themeColor2,'Visible','off','Units','normalized');
            h_preview.InteractionOptions.DatatipsSupported = 'off';
            h_preview.InteractionOptions.ZoomSupported = "off";
            h_preview.InteractionOptions.PanSupported = "off";
            h_preview.Toolbar.Visible = 'off';

            ha3 = uiaxes(UserFig,'Units','Pixels','Position',[200,160,500,50],'Units','normalized','Visible','off');
            hold(ha3,'on')
            set(ha3,'Xtick',[],'YTick',[],'XLim',[0 1],'YLim',[0 1])
            ha3.InteractionOptions.DatatipsSupported = 'off';
            ha3.InteractionOptions.ZoomSupported = "off";
            ha3.InteractionOptions.PanSupported = "off";
            ha3.Toolbar.Visible = 'off';

        end


        if ct == 1

            % set up slab positions: sample core for general location within image
            samp = round(layers/2);
            filteredXcore(:,:) = imfilter(X(:,:,samp), h2, 'replicate');

            coralSamp = imbinarize((filteredXcore-min(min(filteredXcore)))/max(max(filteredXcore-min(min(filteredXcore)))).*255);

            [r,c] = find(coralSamp);

            [val,loc] = max(r);
            topMost = [c(loc),r(loc)];
            [val,loc] = min(r);
            bottomMost = [c(loc),r(loc)];
            [val,loc] = max(c);
            rightMost = [c(loc),r(loc)];
            [val,loc] = min(c);
            leftMost = [c(loc),r(loc)];

            center = [round((rightMost(1)+leftMost(1))/2),round((topMost(2)+bottomMost(2))/2)];

            slab = round(mean(center));
            slabPos = slab*hpxS;

        end

        moveOn = 0;

        defaultMode

        try
            if ct == 1
                if smoothedBandsDrawn == 0
                    drawAndLabelBands
                else
                    drawAndLabelSmoothedBands
                end
            elseif ct == 0
                if smoothedBandsDrawn == 0
                    drawAndLabelBandsXray
                else
                    drawAndLabelSmoothedBandsXray
                end
            end
        catch
            set(lblLoading,'Visible','on','FontSize',12,'String','Cannot display core (code 019)')
            pause
            while 1 ~= 2
                pause
            end
        end

        % button for adjusting auto-band detection method
        calibrateProposedIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Band-detection settings'},'Visible','off',...
            'Position',[180,10,200,30],'Units','normalized','BackgroundColor',[255, 189, 68]/256,'ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial','Callback',@adjustBandDetect_fun);

        calibrateProposedOut = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Go back'},'Visible','off',...
            'Position',[180,10,200,30],'Units','normalized','BackgroundColor',[0, 202, 78]/256,'ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial','Callback',@cancelAdjustBandDetect_fun);

        aboutCalibrateIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'What is this?'},'Visible','off',...
            'Position',[700,250,100,30],'Units','normalized','BackgroundColor','none','ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial','Callback',@aboutCalibrate_fun);

        aboutCalibrateCancelIn = uicontrol(UserFig,'Style','pushbutton',...
            'String',{'Go back'},'Visible','off',...
            'Position',[700,250,100,30],'Units','normalized','BackgroundColor','none','ForegroundColor',[0,0,0],'FontSize',12,'FontName','Arial','Callback',@aboutCalibrateCancel_fun);

        htextAbout2 = uicontrol(UserFig,'Style','text','String',' ',...
            'Position',[650,300,300,300],'Units','normalized','FontSize',10,'FontName','Arial','Visible','off');

        proposed_bands = [];
        ha4 = [];
        p_prop4 = [];
        corePlot4 = [];
        filtParam1In = [];
        filtParam2In = [];
        smoothParam1In = [];
        smoothParam2In = [];
        lblParam1 = [];
        lblParam2 = [];
        lblSmoothParam1 = [];
        lblSmoothParam2 = [];
        lblFilterType = [];
        searchDistIn = [];
        lblSearchDist = [];

        function cancelAdjustBandDetect_fun(src,event)

            acceptRejectBackOn
            set(calibrateProposedIn,'Visible','on')
            set(calibrateProposedOut,'Visible','off')
            set(filterIn,'Visible','off')
            set(filtParam1In,'Visible','off')
            set(filtParam2In,'Visible','off')
            set(lblParam1,'Visible','off')
            set(lblParam2,'Visible','off')
            set(lblFilterType,'Visible','off')
            set(searchDistIn,'Visible','off')
            set(lblSearchDist,'Visible','off')
            set(aboutCalibrateIn,'Visible','off')
            set(aboutCalibrateCancelIn,'Visible','off')
            set(htextAbout2,'Visible','off')
            set(hideInterpIn,'Visible','off')
            set(showInterpIn,'Visible','off')
            try delete(p_prop4)
            catch
            end
            try delete(corePlot4)
            catch
            end
            try delete(ha4)
            catch
            end
            try delete(p_prop)
            catch
            end
            p_prop = plot(ha,proposed_bands(:,1).*hpxS,proposed_bands(:,2).*pxS,'mo');
            set(ha2,'Units','Pixels','Position',[675,100,400,400],'Units','normalized')

        end

        function aboutCalibrateCancel_fun(src,event)

            set(calibrateProposedIn,'Visible','on')
            set(calibrateProposedOut,'Visible','on')
            set(filterIn,'Visible','on')
            set(filtParam1In,'Visible','on')
            set(filtParam2In,'Visible','on')
            set(lblParam1,'Visible','on')
            set(lblParam2,'Visible','on')
            set(lblFilterType,'Visible','on')
            set(searchDistIn,'Visible','on')
            set(lblSearchDist,'Visible','on')
            set(aboutCalibrateIn,'Visible','on')
            set(aboutCalibrateCancelIn,'Visible','off')
            set(htextAbout2,'Visible','off')


        end

        function aboutCalibrate_fun(src,event)

            set(calibrateProposedIn,'Visible','off')
            set(calibrateProposedOut,'Visible','off')
            set(filterIn,'Visible','off')
            set(filtParam1In,'Visible','off')
            set(filtParam2In,'Visible','off')
            set(lblParam1,'Visible','off')
            set(lblParam2,'Visible','off')
            set(lblFilterType,'Visible','off')
            set(searchDistIn,'Visible','off')
            set(lblSearchDist,'Visible','off')
            set(aboutCalibrateIn,'Visible','off')
            set(aboutCalibrateCancelIn,'Visible','on')

            about_text_label2 = sprintf(['Automatic band detection works by filtering the core image ' ...
                'and tracing both left and right the "valley" of low (or high) density of the ' ...
                'identified band. This process depends on how the image is filtered (blurred), ' ...
                'and there are many ways to do that. Here, you can choose two different ' ...
                'types of filters and adjust the parameters of the filter. The idea is to ' ...
                'adjust the setting until the proposed band (the magenta dots) fit well to the ' ...
                'band visible on the image. Note that this feature may not work well for all ' ...
                'cores and it should not be relied up blindly. Automatic detection is meant to ' ...
                'be a convenience to enable quicker analysis of nicely-banded corals, but corals ' ...
                'with complicated banding patterns or low-resolution scans will likely need to be clicked ' ...
                'on manually.']);

            set(htextAbout2,'String',about_text_label2)

            about_text_wrapped2 = textwrap(htextAbout2,{htextAbout2.String});

            set(htextAbout2,'String',about_text_label2,'Visible','on','Units','pixels',...
                'Position',[650,300,400,300],'Units','normalized','HorizontalAlignment', 'left','BackgroundColor','none','ForegroundColor','w')

        end


        function adjustBandDetect_fun(src,event)

            acceptRejectOff
            set(calibrateProposedIn,'Visible','off')
            set(calibrateProposedOut,'Visible','on')
            set(aboutCalibrateIn,'Visible','on')
            set(hideInterpIn,'Visible','off')
            set(showInterpIn,'Visible','off')

            if ct == 1
                set(ha2,'Units','Pixels','Position',[875,40,200,200],'Units','normalized')
            end

            ha4 = uiaxes(UserFig,'Units','Pixels','Position',[50,50,600,600],'Units','normalized','Color','none','xcolor','k','ycolor','k');
            set(ha4,'XTick',[],'YTick',[]);
            ha4.InteractionOptions.DatatipsSupported = 'off';

            img_filt = imfilter(slabDraw,h1,'replicate');

            corePlot4 = pcolor(ha4,[1:row].*hpxS,[1:layers].*pxS,img_filt);
            set(corePlot4,'EdgeColor','none')
            set(corePlot4,'EdgeColor','interp')
            set(ha4,'PlotBoxAspectRatio',[1 1 1])
            set(ha4,'DataAspectRatio',[1 1 1])
            set(ha4,'Colormap',colormap('bone'))
            set(ha4,'CLim',contra);
            set(ha4,'YLim',currentYlim,'XLim',currentXlim)
            hold(ha4,'on')

            proposed_bands = bandDetection(x1,y1);
            p_prop4 = plot(ha4,proposed_bands(:,1).*hpxS,proposed_bands(:,2).*pxS,'mo');

            drawnow

            % initialize core menu
            filterIn = uicontrol(UserFig,'Style','popupmenu',...
                'Position',[700,550,150,30],'Units','normalized',...
                'String',{'Gaussian','Streak'},'Value',1,...
                'Callback',@chooseFilter,'Visible','on');

            filtParam1In = uicontrol(UserFig,'Style','slider',...
                'Position',[700,475,300,20],'Units','normalized',...
                'Min', 0.1,'Max', 30,'Value', 11,'Callback', @filtParam1_Callback);

            filtParam2In = uicontrol(UserFig,'Style','slider',...
                'Position',[700,400,300,20],'Units','normalized',...
                'Min', 0.1,'Max', 18,'Value', 5,'Callback', @filtParam2_Callback);

            searchDistIn = uicontrol(UserFig,'Style','slider',...
                'Position',[700,325,300,20],'Units','normalized',...
                'Min', 0.1,'Max', 3,'Value', 0.5,'Callback', @searchDist_Callback);

            lblParam1 = uicontrol(UserFig,'Style','text','String',sprintf('Filter width: %s mm',num2str(filtParam1In.Value)),'Position',[700,500,300,20],...
                'FontSize',10,'FontName','Arial','Units','normalized','BackgroundColor','none','ForegroundColor','w');

            lblParam2 = uicontrol(UserFig,'Style','text','String',sprintf('Filter standard deviation: %s mm',num2str(filtParam2In.Value)),'Position',[700,425,300,20],...
                'FontSize',10,'FontName','Arial','Units','normalized','BackgroundColor','none','ForegroundColor','w');

            lblSearchDist = uicontrol(UserFig,'Style','text','String',sprintf('Max vertical change per pixel: %s mm',num2str(searchDistIn.Value)),'Position',[700,350,300,20],...
                'FontSize',10,'FontName','Arial','Units','normalized','BackgroundColor','none','ForegroundColor','w');

            lblFilterType = uicontrol(UserFig,'Style','text','String','Filter type','Position',[700,585,200,20],...
                'FontSize',10,'FontName','Arial','Units','normalized','BackgroundColor','none','ForegroundColor','w');

        end

        function updateProposedBands
            try delete(p_prop4)
            catch
            end
            proposed_bands = bandDetection(x1,y1);
            p_prop4 = plot(ha4,proposed_bands(:,1).*hpxS,proposed_bands(:,2).*pxS,'mo');
        end

        function updateProposedBandsImage
            hold(ha4,'off')
            img_filt = imfilter(slabDraw,h1,'replicate');
            corePlot4 = pcolor(ha4,[1:row].*hpxS,[1:layers].*pxS,img_filt);
            set(corePlot4,'EdgeColor','none')
            set(corePlot4,'EdgeColor','interp')
            set(ha4,'PlotBoxAspectRatio',[1 1 1])
            set(ha4,'DataAspectRatio',[1 1 1])
            set(ha4,'Colormap',colormap('bone'))
            set(ha4,'CLim',contra);
            set(ha4,'YLim',currentYlim,'XLim',currentXlim)
            hold(ha4,'on')
        end

        function filtParam1_Callback(src,event)
            filt_param1 = filtParam1In.Value;
            updateFilter
            updateProposedBandsImage
            editingProposedSettings=1;
            updateProposedBands
            editingProposedSettings=0;
        end

        function filtParam2_Callback(src,event)
            filt_param2 = filtParam2In.Value;
            if filterIn.Value == 2
                filt_param2 = filt_param2*10;
            end
            updateFilter
            updateProposedBandsImage
            editingProposedSettings=1;
            updateProposedBands
            editingProposedSettings=0;
        end

        function searchDist_Callback(src,event)
            search_vertical_mm = searchDistIn.Value;
            editingProposedSettings=1;
            updateProposedBands
            editingProposedSettings=0;
            set(lblSearchDist,'String',sprintf('Max vertical change per pixel: %s mm',num2str(round(searchDistIn.Value*10)/10)))
        end

        filterIn = [];
        function chooseFilter(src,event)

            filt_param1 = 11;
            filt_param2 = 5;
            filtParam1In.Value = filt_param1;
            filtParam2In.Value = filt_param2;

            if filterIn.Value == 1
                h1 = fspecial('gaussian',round(filt_param1*((1./hpxS).*0.1)), ((1./hpxS).*0.1)*filt_param2);
                set(lblParam1,'String',sprintf('Filter width: %s mm',num2str(round(filtParam1In.Value*10)/10)))
                set(lblParam2,'String',sprintf('Filter standard deviation: %s mm',num2str(round(filtParam2In.Value*10)/10)))
            elseif  filterIn.Value == 2
                h1 = fspecial('motion',round(filt_param1*((1./hpxS).*0.1)),filt_param2);
                set(lblParam1,'String',sprintf('Streak length: %s mm',num2str(round(filtParam1In.Value*10)/10)))
                set(lblParam2,'String',sprintf('Filter angle: %s°',num2str(round(filtParam2In.Value*10))))
            end

            updateFilter
            updateProposedBandsImage
            editingProposedSettings=1;
            updateProposedBands
            editingProposedSettings=0;

        end


        function updateFilter
            if filterIn.Value == 1
                h1 = fspecial('gaussian',round(filt_param1*((1./hpxS).*0.1)), ((1./hpxS).*0.1)*filt_param2);
                set(lblParam1,'String',sprintf('Filter width: %s mm',num2str(round(filtParam1In.Value*10)/10)))
                set(lblParam2,'String',sprintf('Filter standard deviation: %s mm',num2str(round(filtParam2In.Value*10)/10)))
            elseif  filterIn.Value == 2
                h1 = fspecial('motion',round(filt_param1*((1./hpxS).*0.1)),filt_param2);
                set(lblParam1,'String',sprintf('Streak length: %s mm',num2str(round(filtParam1In.Value*10)/10)))
                set(lblParam2,'String',sprintf('Filter angle: %s°',num2str(round(filtParam2In.Value*10))))
            end
        end

        filt_param1 = 11;
        filt_param2 = 5;
        h1 = fspecial('gaussian',round(filt_param1*((1./hpxS).*0.1)), ((1./hpxS).*0.1)*filt_param2);
        search_vertical_mm = 0.5;
        editingProposedSettings=0;

        function proposed_points=bandDetection(x,y)

            if editingProposedSettings == 0
                h1 = fspecial('gaussian',round(11*((1./hpxS).*0.1)), ((1./hpxS).*0.1)*5);
            end

            img_filt = imfilter(double(slabDraw),h1,'replicate');

            img_min = min(min(img_filt));

            % max will be 60 degree angle
            max_ang = 60;
            mm_slope_tol = 3;
            h_pixels_slope = (mm_slope_tol/pxS)./(hpxS*tand(max_ang));

            search_offset = 0;

            search_vertical = round(search_vertical_mm/pxS); % number of pixels
            if search_vertical<1
                search_vertical = 1;
            end
            user_point = [round(x/hpxS),round(y/pxS)];
            [this_min,min_loc] = min(img_filt(...
                user_point(2)-search_vertical:user_point(2)+search_vertical,user_point(1)));
            abs_min_loc = user_point(2)-(search_vertical+1)+min_loc;

            valley_search_lims = 3.5; % mm
            valley_search_pxs = round(valley_search_lims/(pxS/10));

            valley_height_tolerance = 0.5;

            valley_lims = abs_min_loc-valley_search_pxs:abs_min_loc+valley_search_pxs;

            if max(valley_lims)>layers
                valley_lims(valley_lims>layers) = [];
            end
            if min(valley_lims)<1
                valley_lims(valley_lims<1) = [];
            end

            if max(valley_lims)>1
                [these_peaks,peak_locs] = findpeaks(img_filt(valley_lims,user_point(1)));
                lower_peaks = find(valley_lims(peak_locs)<abs_min_loc);
                upper_peaks = find(valley_lims(peak_locs)>abs_min_loc);
                search_midpoint = round(median(valley_lims));
                [a,lower_peak_loc] = min(abs(search_midpoint-(valley_lims(1)-1+peak_locs(lower_peaks))));
                peak = NaN(2,1);
                if length(img_filt(valley_lims(1)-1+peak_locs(lower_peaks(lower_peak_loc)),user_point(1)))==1
                    peak(1) = img_filt(valley_lims(1)-1+peak_locs(lower_peaks(lower_peak_loc)),user_point(1));
                end
                [a,upper_peak_loc] = min(abs(search_midpoint-(valley_lims(1)-1+peak_locs(upper_peaks))));
                if length(img_filt(valley_lims(1)-1+peak_locs(upper_peaks(upper_peak_loc)),user_point(1))) == 1
                    peak(2) = img_filt(valley_lims(1)-1+peak_locs(upper_peaks(upper_peak_loc)),user_point(1));
                end

                orig_valley_height = mean(peak,'omitnan')-this_min;

                conf_band = 1;
                band_coordinates = [user_point(1),abs_min_loc];
                counter = 1;
                this_x = user_point(1);
                latest_y = abs_min_loc;
                do_left = 1;
                slopeSign = 1;

                while conf_band==1
                    if do_left==1
                        this_x = this_x-1;
                    else
                        this_x = this_x+1;
                    end
                    current_search = latest_y-search_vertical+search_offset:...
                        latest_y+search_vertical+search_offset;

                    if max(current_search)>layers
                        current_search(current_search>layers) = [];
                    end
                    if min(current_search)<1
                        current_search(current_search<1) = [];
                    end

                    [this_min,min_loc] = min(img_filt(current_search,this_x));

                    abs_min_loc = current_search(min_loc);

                    valley_lims = abs_min_loc-valley_search_pxs:abs_min_loc+valley_search_pxs;

                    if max(valley_lims)>layers
                        valley_lims(valley_lims>layers) = [];
                    end
                    if min(valley_lims)<1
                        valley_lims(valley_lims<1) = [];
                    end

                    if max(valley_lims)>1
                        [these_peaks,peak_locs] = findpeaks(img_filt(valley_lims,this_x));
                        lower_peaks = find(valley_lims(peak_locs)<abs_min_loc);
                        upper_peaks = find(valley_lims(peak_locs)>abs_min_loc);
                        search_midpoint = round(median(valley_lims));
                        peak = NaN(2,1);
                        [a,lower_peak_loc] = min(abs(search_midpoint-(valley_lims(1)-1+peak_locs(lower_peaks))));
                        if length(img_filt(valley_lims(1)-1+peak_locs(lower_peaks(lower_peak_loc)),this_x))
                            peak(1) = img_filt(valley_lims(1)-1+peak_locs(lower_peaks(lower_peak_loc)),this_x);
                        end
                        [a,upper_peak_loc] = min(abs(search_midpoint-(valley_lims(1)-1+peak_locs(upper_peaks))));
                        if length(img_filt(valley_lims(1)-1+peak_locs(upper_peaks(upper_peak_loc)),this_x))
                            peak(2) = img_filt(valley_lims(1)-1+peak_locs(upper_peaks(upper_peak_loc)),this_x);
                        end

                        this_valley_height = nanmean(peak)-this_min;

                        if this_valley_height>orig_valley_height*valley_height_tolerance && this_min > mean([contra(1),img_min]) %...
                            counter = counter+1;
                            latest_y = abs_min_loc;
                            band_coordinates(counter,:) = [this_x,abs_min_loc];

                            if counter>round(h_pixels_slope)
                                lengthfit = round(h_pixels_slope);
                            else
                                lengthfit = counter;
                            end
                            if counter > 2
                                if do_left == 1
                                    [x_check,idx] = sort(band_coordinates(:,1),'descend');
                                    y_check = band_coordinates(idx,2);
                                elseif do_left == 0
                                    [x_check,idx] = sort(band_coordinates(:,1),'ascend');
                                    y_check = band_coordinates(idx,2);
                                end
                                b = regress(y_check(1:lengthfit),[...
                                    ones(lengthfit,1),x_check(1:lengthfit)]);
                                if (b(2)*lengthfit)>mm_slope_tol*(lengthfit/h_pixels_slope)
                                    search_offset = -1*slopeSign;
                                elseif (b(2)*lengthfit)<-mm_slope_tol*(lengthfit/h_pixels_slope)
                                    search_offset = 1*slopeSign;
                                else
                                    search_offset = 0;
                                end
                            end

                        elseif do_left == 1
                            do_left = 0;
                            slopeSign = -1;
                            this_x = user_point(1);
                            latest_y = user_point(2);
                        elseif do_left == 0
                            conf_band = 0;
                        end

                    end
                end
            end
            trim_mm = 2;
            trim_pixels = round(trim_mm./hpxS);
            [b idx] = sort(band_coordinates(:,1));
            band_coordinates = band_coordinates(idx,:);
            if length(band_coordinates(:,1))>(trim_pixels*2.5)
                trim_inds = [1:trim_pixels,(length(band_coordinates(:,1))-trim_pixels):length(band_coordinates(:,1))];
                band_coordinates(trim_inds,:) = [];
            end
            proposed_points = band_coordinates;
        end

        while moveOn == 0
            pause(2)
        end
    end

    function findCoral(corName,secName)

        thisSectionName = secName;
        thisCoralName = corName;

        if view_only == 0
            cFolderName = 'current_scan';
        elseif view_only == 1
            cFolderName = 'current_scan_view_only';
        end

        dirRow = 0;
        didwematch = 0;
        while didwematch==0
            dirRow = dirRow+1;
            if strcmp('',thisSectionName)
                isthismatch = strcmp(thisCoralName,coralDir.textdata{dirRow,1});
            else
                isthismatch = strcmp(thisCoralName,coralDir.textdata{dirRow,1})...
                    & strcmp(thisSectionName,coralDir.textdata{dirRow,2});
            end
            if isthismatch==1
                break
            end
        end
        serverChoice = [];
        if coralDir.data(dirRow-1,1) == 1
            serverChoice = 1;
            h_drive = '/hd1/';
        elseif coralDir.data(dirRow-1,1) == 2
            serverChoice = 2;
            h_drive = '/hd1/';
        elseif coralDir.data(dirRow-1,1) == 3
            serverChoice = 1;
            h_drive = '/hd1/';
        end

        flipCore = coralDir.data(dirRow-1,2);
        ct = coralDir.data(dirRow-1,12);

        try
            if serverChoice == 1
                cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password);
            elseif serverChoice == 2
                cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password);
            elseif serverChoice == 3
                cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
            end
        catch
            try
                connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                connectionEstablished = 0;
                for ij = 1:length(connectTimes)
                    if connectionEstablished == 0
                        if connectTimes(ij) == 1
                            waitText = [' ',num2str(connectTimes(ij)),' minute.']
                        else
                            waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                        end
                        set(lblOpeningError,'Units','Pixels','Visible','on','Position',[200,80,500,40],...
                            'String',{'Error connecting to server.';strcat('Trying again in',waitText)},...
                            'Units','normalized')
                        pause(connectTimes(ij)*60)
                        try
                            if serverChoice == 1
                                cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password)
                            elseif serverChoice == 2
                                cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password)
                            elseif serverChoice == 3
                                cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                            end
                            connectionEstablished = 1;
                            set(lblOpeningError,'Units','Pixels','Visible','off',...
                                'Position',[200,150,500,20],'Units','normalized')
                        catch
                        end
                    end
                end
                if connectionEstablished == 0
                    zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                end
            catch
                set(lblOpeningError,'Units','Pixels','Position',[200,80,500,40],'Visible','on',...
                    'String',{'Error connecting to server. (code 005)';'Please try again later.'},...
                    'Units','normalized')
                while 1==1
                    pause
                end
            end

        end


        if strcmp('',thisSectionName)
            server_path = strcat(h_drive,coralDir.textdata{dirRow,3},'/',...
                coralDir.textdata{dirRow,4},'/',thisCoralName);
        else
            server_path = strcat(h_drive,'/',coralDir.textdata{dirRow,3},'/',...
                coralDir.textdata{dirRow,4},'/',thisCoralName,'/',thisSectionName);
        end

        if serverChoice == 1 || serverChoice == 3
            server_path(double(server_path)==32) = 95; % converts spaces to _
        end

        cd(cache2,server_path)

        if exist(fullfile(selpath,'my_corals',cFolderName,'Xray'),'dir')
            rmdir(fullfile(selpath,'my_corals',cFolderName,'Xray'),'s')
        end
        if exist(fullfile(selpath,'my_corals',cFolderName,'dicoms'),'dir')
            rmdir(fullfile(selpath,'my_corals',cFolderName,'dicoms'),'s')
        end

        if saveCTdata == 1 && view_only == 0
            if ct == 1
                if serverChoice ~= 3
                    if strcmp('',thisSectionName)
                        mget(cache2,'dicoms.zip',fullfile(selpath,'my_corals',thisCoralName));
                    else
                        mget(cache2,'dicoms.zip',fullfile(selpath,'my_corals',thisCoralName,thisSectionName));
                    end
                else
                    if strcmp('',thisSectionName)
                        mget(cache2,'dicomFolder',fullfile(selpath,'my_corals',thisCoralName));
                        movefile(fullfile(selpath,'my_corals',thisCoralName,'dicomFolder','dicoms.zip'),fullfile(selpath,'my_corals',thisCoralName))
                        rmdir(fullfile(selpath,'my_corals',thisCoralName,'dicomFolder'),'s')
                    else
                        mget(cache2,'dicomFolder',fullfile(selpath,'my_corals',thisCoralName,thisSectionName));
                        movefile(fullfile(selpath,'my_corals',thisCoralName,thisSectionName,'dicomFolder','dicoms.zip'),fullfile(selpath,'my_corals',thisCoralName,thisSectionName))
                        rmdir(fullfile(selpath,'my_corals',thisCoralName,thisSectionName,'dicomFolder'),'s')
                    end
                end
            else
                if strcmp('',thisSectionName)
                    mget(cache2,'xray.tiff',fullfile(selpath,'my_corals',thisCoralName,'Xray'));
                else
                    mget(cache2,'xray.tiff',fullfile(selpath,'my_corals',thisCoralName,thisSectionName,'Xray'));
                end
            end
        else
            if ct == 1
                if serverChoice ~= 3
                    mget(cache2,'dicoms.zip',fullfile(selpath,'my_corals',cFolderName));
                else
                    mget(cache2,'dicomFolder',fullfile(selpath,'my_corals',cFolderName));
                    movefile(fullfile(selpath,'my_corals',cFolderName,'dicomFolder','dicoms.zip'),fullfile(selpath,'my_corals',cFolderName))
                    rmdir(fullfile(selpath,'my_corals',cFolderName,'dicomFolder'),'s')
                end
            else
                mget(cache2,'xray.tiff',fullfile(selpath,'my_corals',cFolderName,'Xray'));
            end
        end

        if saveCTdata == 1 && view_only == 0
            if ct == 1
                if strcmp('',thisSectionName)
                    unzip(fullfile(selpath,'my_corals',thisCoralName,'dicoms.zip'),fullfile(selpath,'my_corals',thisCoralName,'dicoms'));
                    fid = fopen(fullfile(selpath,'my_corals',thisCoralName,'dicoms','CoreMetaData.csv'),'w');
                    fprintf(fid,'%s\n',corName);
                    fprintf(fid,'%s\n',secName);
                    try fclose(fid);
                    catch
                    end
                    try mget(cache2,strcat(saveName,thisCoralName,'.mat'),fullfile(selpath,'my_corals',thisCoralName,'dicoms'))
                    catch
                    end
                else
                    unzip(fullfile(selpath,'my_corals',thisCoralName,thisSectionName,'dicoms.zip'),fullfile(selpath,'my_corals',thisCoralName,thisSectionName,'dicoms'));
                    fid = fopen(fullfile(selpath,'my_corals',thisCoralName,thisSectionName,'dicoms','CoreMetaData.csv'),'w');
                    fprintf(fid,'%s\n',corName);
                    fprintf(fid,'%s\n',secName);
                    try fclose(fid);
                    catch
                    end
                    try mget(cache2,strcat(saveName,thisCoralName,'_',thisSectionName,'.mat'),fullfile(selpath,'my_corals',thisCoralName,thisSectionName,'dicoms'))
                    catch
                    end
                end
            else
                if strcmp('',thisSectionName)
                    fid = fopen(fullfile(selpath,'my_corals',thisCoralName,'Xray','CoreMetaData.csv'),'w');
                    fprintf(fid,'%s\n',corName);
                    fprintf(fid,'%s\n',secName);
                    try fclose(fid);
                    catch
                    end
                    try mget(cache2,strcat(saveName,thisCoralName,'.mat'),fullfile(selpath,'my_corals',thisCoralName,'Xray'))
                    catch
                    end
                else
                    fid = fopen(fullfile(selpath,'my_corals',thisCoralName,thisSectionName,'Xray','CoreMetaData.csv'),'w');
                    fprintf(fid,'%s\n',corName);
                    fprintf(fid,'%s\n',secName);
                    try fclose(fid);
                    catch
                    end
                    try mget(cache2,strcat(saveName,thisCoralName,'_',thisSectionName,'.mat'),fullfile(selpath,'my_corals',thisCoralName,thisSectionName,'Xray'))
                    catch
                    end
                end
            end
        else

            if ct == 1
                unzip(fullfile(selpath,'my_corals',cFolderName,'dicoms.zip'),fullfile(selpath,'my_corals',cFolderName,'dicoms'));
                fid = fopen(fullfile(selpath,'my_corals',cFolderName,'dicoms','CoreMetaData.csv'),'w');
                fprintf(fid,'%s\n',corName);
                fprintf(fid,'%s\n',secName);
                fclose(fid);
            else
                fid = fopen(fullfile(selpath,'my_corals',cFolderName,'Xray','CoreMetaData.csv'),'w');
                fprintf(fid,'%s\n',corName);
                fprintf(fid,'%s\n',secName);
                fclose(fid);
            end
            if strcmp('',thisSectionName)
                if ct == 1
                    try mget(cache2,strcat(saveName,thisCoralName,'.mat'),fullfile(selpath,'my_corals',cFolderName,'dicoms'))
                    catch
                        try mget(cache2,strcat(saveName,thisCoralName,'.mat'),fullfile(selpath,'my_corals',cFolderName,'dicoms'))
                        catch
                            try mget(cache2,strcat(saveName,thisCoralName,'.mat'),fullfile(selpath,'my_corals',cFolderName,'dicoms'))
                            catch
                            end
                        end
                    end
                else
                    try mget(cache2,strcat(saveName,thisCoralName,'.mat'),fullfile(selpath,'my_corals',cFolderName,'Xray'))
                    catch
                        try mget(cache2,strcat(saveName,thisCoralName,'.mat'),fullfile(selpath,'my_corals',cFolderName,'Xray'))
                        catch
                            try mget(cache2,strcat(saveName,thisCoralName,'.mat'),fullfile(selpath,'my_corals',cFolderName,'Xray'))
                            catch
                            end
                        end
                    end
                end
            else
                if ct == 1
                    try mget(cache2,strcat(saveName,thisCoralName,'_',thisSectionName,'.mat'),fullfile(selpath,'my_corals',cFolderName,'dicoms'))
                    catch
                        try mget(cache2,strcat(saveName,thisCoralName,'_',thisSectionName,'.mat'),fullfile(selpath,'my_corals',cFolderName,'dicoms'))
                        catch
                            try mget(cache2,strcat(saveName,thisCoralName,'_',thisSectionName,'.mat'),fullfile(selpath,'my_corals',cFolderName,'dicoms'))
                            catch
                            end
                        end
                    end
                else
                    try mget(cache2,strcat(saveName,thisCoralName,'_',thisSectionName,'.mat'),fullfile(selpath,'my_corals',cFolderName,'Xray'))
                    catch
                        try mget(cache2,strcat(saveName,thisCoralName,'_',thisSectionName,'.mat'),fullfile(selpath,'my_corals',cFolderName,'Xray'))
                        catch
                            try mget(cache2,strcat(saveName,thisCoralName,'_',thisSectionName,'.mat'),fullfile(selpath,'my_corals',cFolderName,'Xray'))
                            catch
                            end
                        end
                    end
                end
            end
        end
        gen = coralDir.textdata{dirRow,5};
        collectionYear = coralDir.data(dirRow-1,7);
        collectionMonth = coralDir.data(dirRow-1,6);
        dataOwner = coralDir.textdata{dirRow,6};
        dataOwners = strsplit(dataOwner,'//');
        HU2dens = [coralDir.data(dirRow-1,10), coralDir.data(dirRow-1,11)];
        xrayPos = coralDir.data(dirRow-1,13);
        xrayDPI = coralDir.data(dirRow-1,14);

        close(cache2)
    end

    function dirOutput = findBandFiles(corName,secName)

        thisSectionName = secName;
        thisCoralName = corName;

        dirRow = 0;
        didwematch = 0;
        while didwematch==0
            dirRow = dirRow+1;
            if strcmp('',thisSectionName)
                isthismatch = strcmp(thisCoralName,coralDir.textdata{dirRow,1});
            else
                isthismatch = strcmp(thisCoralName,coralDir.textdata{dirRow,1})...
                    & strcmp(thisSectionName,coralDir.textdata{dirRow,2});
            end
            if isthismatch==1
                break
            end
        end
        serverChoice = [];
        if coralDir.data(dirRow-1,1) == 1
            serverChoice = 1;
            h_drive = '/hd1/';
        elseif coralDir.data(dirRow-1,1) == 2
            serverChoice = 2;
            h_drive = '/hd1/';
        elseif coralDir.data(dirRow-1,1) == 3
            serverChoice = 3;
            h_drive = '/hd1/';
        end
        if coralDir.data(dirRow-1,2) == 1
            flipCore = 1;
        end

        try
            if serverChoice == 1
                cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password)
            elseif serverChoice == 2
                cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password)
            elseif serverChoice == 3
                cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
            end
        catch
            try
                if serverChoice == 1
                    cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password)
                elseif serverChoice == 2
                    cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password)
                elseif serverChoice == 3
                    cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                end
            catch
                try
                    connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                    connectionEstablished = 0;
                    for ij = 1:length(connectTimes)
                        if connectionEstablished == 0
                            if connectTimes(ij) == 1
                                waitText = [' ',num2str(connectTimes(ij)),' minute.']
                            else
                                waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                            end
                            set(lblOpeningError,'Units','Pixels','Visible','on','Position',[200,130,500,40],...
                                'String',{'Error connecting to server.';strcat('Trying again in',waitText)},...
                                'Units','normalized')
                            pause(connectTimes(ij)*60)
                            try
                                if serverChoice == 1
                                    cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password)
                                elseif serverChoice == 2
                                    cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password)
                                elseif serverChoice == 3
                                    cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                end
                                connectionEstablished = 1;
                                set(lblOpeningError,'Units','Pixels','Visible','off',...
                                    'Position',[200,150,500,20],'Units','normalized')
                            catch
                            end
                        end
                    end
                    if connectionEstablished == 0
                        zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                    end
                catch
                    set(lblOpeningError,'Units','Pixels','Position',[200,130,500,40],'Visible','on',...
                        'String',{'Error connecting to server. (code 020)';'Please try again later.'},...
                        'Units','normalized')
                    pause
                    while 1 ~= 2
                        pause
                    end
                end
            end
        end

        if strcmp('',thisSectionName)
            server_path = strcat(h_drive,coralDir.textdata{dirRow,3},'/',...
                coralDir.textdata{dirRow,4},'/',thisCoralName);
        else
            server_path = strcat(h_drive,'/',coralDir.textdata{dirRow,3},'/',...
                coralDir.textdata{dirRow,4},'/',thisCoralName,'/',thisSectionName);
        end
        if serverChoice == 1 || serverChoice == 3
            server_path(double(server_path)==32) = 95; % converts spaces to _
        end
        cd(cache2,server_path)
        dirInit = dir(cache2);
        dirOutput1 = [];
        for iii = 1:length(dirInit)
            if length(strsplit(dirInit(iii).name,'.mat'))==2
                thisName0 = strsplit(dirInit(iii).name,'.mat');
                thisName = strsplit(thisName0{1},'_');
                dirOutput1 = [dirOutput1; thisName(1)];
            end
        end

        dirOutput2 = []; % for user name in the csvserverwsee
        dirOutput3 = []; % for dates
        for iii = 1:length(dirInit)
            if length(strsplit(dirInit(iii).name,'.csv'))==2
                thisName0 = strsplit(dirInit(iii).name,'.csv');
                thisName = strsplit(thisName0{1},'_');
                dirOutput2 = [dirOutput2; thisName(3)];
                dirOutput3 = [dirOutput3; thisName(4)];
            end
        end

        inds2keep1 = []; % match between .mat and .csv
        inds2keep2 = []; % match between .mat and .csv
        for iii = 1:length(dirOutput1)
            for jj = 1:length(dirOutput2)
                if strcmp(dirOutput1(iii),dirOutput2(jj))
                    inds2keep1 = [inds2keep1;iii];
                    inds2keep2 = [inds2keep2;jj];
                end
            end
        end

        dirOutput = [];
        for iii = 1:length(inds2keep1)
            dirOutput{iii} = strcat(dirOutput1{inds2keep1(iii)},'_',dirOutput3{inds2keep2(iii)});
        end

        close(cache2)
    end

    function getBandFile(corName,secName,bandName)

        thisSectionName = secName;
        thisCoralName = corName;
        thisBandName = bandName;

        dirRow = 0;
        didwematch = 0;
        while didwematch==0
            dirRow = dirRow+1;
            if strcmp('',thisSectionName)
                isthismatch = strcmp(thisCoralName,coralDir.textdata{dirRow,1});
            else
                isthismatch = strcmp(thisCoralName,coralDir.textdata{dirRow,1})...
                    & strcmp(thisSectionName,coralDir.textdata{dirRow,2});
            end
            if isthismatch==1
                break
            end
        end
        serverChoice = [];
        if coralDir.data(dirRow-1,1) == 1
            serverChoice = 1;
            h_drive = '/hd1/';
        elseif coralDir.data(dirRow-1,1) == 2
            serverChoice = 2;
            h_drive = '/hd1/';
        elseif coralDir.data(dirRow-1,1) == 3
            serverChoice = 3;
            h_drive = '/hd1/';
        end
        if coralDir.data(dirRow-1,2) == 1
            flipCore = 1;
        end

        try
            if serverChoice == 1
                cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password)
            elseif serverChoice == 2
                cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password)
            elseif serverChoice == 3
                cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
            end
        catch
            try
                if serverChoice == 1
                    cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password)
                elseif serverChoice == 2
                    cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password)
                elseif serverChoice == 3
                    cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                end
            catch
                try
                    connectTimes = [1,2,3,5,10,60,60*12]; % minutes
                    connectionEstablished = 0;
                    for ij = 1:length(connectTimes)
                        if connectionEstablished == 0
                            if connectTimes(ij) == 1
                                waitText = [' ',num2str(connectTimes(ij)),' minute.']
                            else
                                waitText = [' ',num2str(connectTimes(ij)),' minutes.']
                            end
                            set(lblOpeningError,'Units','Pixels','Visible','on','Position',[200,130,500,40],...
                                'String',{'Error connecting to server.';strcat('Trying again in',waitText)},...
                                'Units','normalized')
                            pause(connectTimes(ij)*60)
                            try
                                if serverChoice == 1
                                    cache2 = sftp(ftp_ip2,ftp_user2,"Password",ftp_password)
                                elseif serverChoice == 2
                                    cache2 = sftp(ftp_ip2,ftp_user3,"Password",ftp_password)
                                elseif serverChoice == 3
                                    cache2 = sftp(ftp_ip1,ftp_user1,"Password",ftp_password);
                                end
                                connectionEstablished = 1;
                                set(lblOpeningError,'Units','Pixels','Visible','off',...
                                    'Position',[200,150,500,20],'Units','normalized')
                            catch
                            end
                        end
                    end
                    if connectionEstablished == 0
                        zz = abjfl; % if we made it through end of loop, cause an error to display error code below
                    end
                catch
                    set(lblOpeningError,'Units','Pixels','Visible','on','Position',[200,130,500,40],...
                        'String',{'Error connecting to server. (code 021)';'Please try again later.'},...
                        'Units','normalized')
                    pause
                    while 1 ~= 2
                        pause
                    end
                end
            end
        end

        if strcmp('',thisSectionName)
            server_path = strcat(h_drive,coralDir.textdata{dirRow,3},'/',...
                coralDir.textdata{dirRow,4},'/',thisCoralName);
        else
            server_path = strcat(h_drive,'/',coralDir.textdata{dirRow,3},'/',...
                coralDir.textdata{dirRow,4},'/',thisCoralName,'/',thisSectionName);
        end
        if serverChoice == 1 || serverChoice == 3
            server_path(double(server_path)==32) = 95; % converts spaces to _
        end
        cd(cache2,server_path)

        dirInit = dir(cache2);
        indsWithBands = [];
        dirOutput = [];
        for iii = 1:length(dirInit)
            if length(strsplit(dirInit(iii).name,'.csv'))==2
                indsWithBands = [indsWithBands; iii];
                thisName = strsplit(dirInit(iii).name,'.csv');
                dirOutput = [dirOutput; thisName(1)];
            end
        end

        for iii = 1:length(dirOutput)
            getInits = strsplit(dirOutput{iii},'_'); % initials in the csv file
            chosenInits0 = strsplit(thisBandName,'_');
            chosenInits = chosenInits0{1}; % initials in the chosen file
            chosenDate = chosenInits0{2}; % initials in the chosen file
            if strcmp(getInits{3},chosenInits) && strcmp(getInits{4},chosenDate)
                mget(cache2,strcat(dirOutput{iii},'.csv'),fullfile(selpath,'my_corals','datasets',currentRegion,coralName,sectionName));
                break
            end
        end

        close(cache2)
    end

    function findCoralMetadata(corName,secName)

        thisSectionName = secName;
        thisCoralName = corName;

        dirRow = 0;
        didwematch = 0;
        while didwematch==0
            dirRow = dirRow+1;
            if strcmp('',thisSectionName)
                isthismatch = strcmp(thisCoralName,coralDir.textdata{dirRow,1});
            else
                isthismatch = strcmp(thisCoralName,coralDir.textdata{dirRow,1})...
                    & strcmp(thisSectionName,coralDir.textdata{dirRow,2});
            end
            if isthismatch==1
                break
            end
        end
        serverChoice = [];
        if coralDir.data(dirRow-1,1) == 1
            serverChoice = 1;
            h_drive = '/hd1/';
        elseif coralDir.data(dirRow-1,1) == 2
            serverChoice = 2;
            h_drive = '/hd1/';
        elseif coralDir.data(dirRow-1,1) == 3
            serverChoice = 3;
            h_drive = '/hd1/';
        end
        if coralDir.data(dirRow-1,2) == 1
            flipCore = 1;
        end
        gen = coralDir.textdata{dirRow,5};
        collectionYear = coralDir.data(dirRow-1,7);
        collectionMonth = coralDir.data(dirRow-1,6);
        dataOwner = coralDir.textdata{dirRow,6};
        dataOwners = strsplit(dataOwner,'//');
        currentRegion = coralDir.textdata{dirRow,3};
        HU2dens = [coralDir.data(dirRow-1,10), coralDir.data(dirRow-1,11)];
        xrayPos = coralDir.data(dirRow-1,13);
        xrayDPI = coralDir.data(dirRow-1,14);
    end

    function loadXray

        xrayinfo = imfinfo((fullfile(fileOpen,'xray.tiff')));

        if xrayinfo.SamplesPerPixel == 3
            slabDraw = double(rgb2gray(imread(fullfile(fileOpen,'xray.tiff'))));
        elseif xrayinfo.SamplesPerPixel == 1
            slabDraw = double(imread(fullfile(fileOpen,'xray.tiff')));
        end

        if range(slabDraw(:)) > 2^13 % 16 bit
            slabDraw = slabDraw/2^16;
        elseif range(slabDraw(:)) < 300 && range(slabDraw(:)) >2 % 8 bit
            slabDraw = slabDraw/256;
        end

        if xrayPos == 1
            slabDraw = int16((-slabDraw+1)*4000-1000);
        else
            slabDraw = int16(slabDraw*4000-1000);
        end

        if length(slabDraw(:,1)) > 1e4
            %slabDraw = imresize(slabDraw,0.5);
        end
        pxS = 25.4/xrayDPI;
        hpxS = 25.4/xrayDPI;
        [layers,col] = size(slabDraw);
        row = col;
    end

    function loadData

        % load data

        %processNumber = processNumber + 1;
        titleName = 'loading CT data';
        [X,metadata,sliceLoc] = read_dcm(fileOpen,1);

        % rotate
        X = permute(X,[2,1,3]);

        [row,col,layers] = size(X); % size of the image

        % image pixel spacing
        hpxS = metadata.PixelSpacing(1);

        % vertical pixel spacing (mm)
        sliceDif = median(sliceLoc(2:end)-sliceLoc(1:end-1));
        pxS = abs(sliceDif);
        if max(abs(min(sliceLoc(2:end)-sliceLoc(1:end-1))-sliceDif)) > 0.0001 || ...
                max(abs(max(sliceLoc(2:end)-sliceLoc(1:end-1))-sliceDif)) > 0.0001
            fprintf('WARNING: UNEVEN DICOM SPACING!')

            % sort X by slice location
            [b,idx] = sort(sliceLoc);
            X = X(:,:,idx);

        end

        if flipCore ~= 1
            X = flipdim(X,3);
            sliceLoc = flipdim(sliceLoc,2);
        end

    end

    function [X,metadata,sliceLoc] = read_dcm(dIn,p)

        % read DCM files from input directory into matrix

        inpath = dIn;

        % make sure the filename ends with a '/'
        if inpath(end) ~= filesep
            inpath = [inpath filesep];
        end

        % directory of subfolders within set path
        folders = dir(inpath);

        layerCount = 0; % keep track of where to write files in matrix

        allSlice = [];

        check1 = 1; % check for whether we have found image size

        % initialize
        X = [];

        for j = 1:length(folders)

            % directory of DICOM files within subfolders
            D = dir([[inpath folders(j).name filesep] '*.dcm']);

            % remove the invisible files added by some USB drives:
            remove = [];
            for jj = 1:length(D)
                if strcmp('._',D(jj).name(1:2))
                    remove = [remove jj];
                end
            end
            D(remove) = [];

            % check image size
            if length(D) && check1
                metadata = dicominfo([[inpath folders(j).name] filesep D(1).name]);
                ro = metadata.Height;
                co = metadata.Width;
                check1 = 0;
            end

            % we know each image is roXco, initialize here
            checkX = 0;
            try isempty(X);
                X(:,:,end+1:end+length(D)) = 0;
                sliceLoc(end+1:end+length(D)) = 0;
                checkX = 1;
            catch
            end
            if checkX == 0 && check1 == 0
                X = zeros(ro,co,length(D),'single');
                sliceLoc = zeros(1,length(D));
            end

            skip = 0;

            % iterating over each file, read the image and populate the appropriate
            % layer in matrix X
            for i1 = 1:length(D)

                skipCheck = 0;

                metadata = dicominfo([[inpath folders(j).name] filesep D(i1).name]);

                if isfield(metadata,'SliceLocation') == 1
                    if min(abs(allSlice-metadata.SliceLocation)) == 0
                        skipCheck = 1;
                    end
                elseif isfield(metadata,'ImagePositionPatient') == 1
                    if min(abs(allSlice-metadata.ImagePositionPatient(3))) == 0
                        skipCheck = 1;
                    end
                elseif isfield(metadata,'InstanceNumber') == 1
                    if min(abs(allSlice-metadata.InstanceNumber)) == 0
                        skipCheck = 1;
                    end
                end

                % read DICOM
                x = single(dicomread([[inpath folders(j).name] filesep D(i1).name]));
                X(:,:,i1+layerCount-skip) = x;
                if isfield(metadata,'SliceLocation') == 1
                    sliceLoc(i1+layerCount-skip) = metadata.SliceLocation;
                elseif isfield(metadata,'ImagePositionPatient') == 1
                    sliceLoc(i1+layerCount-skip) = metadata.ImagePositionPatient(3);
                elseif isfield(metadata,'InstanceNumber') == 1
                    sliceLoc(i1+layerCount-skip) = metadata.InstanceNumber;
                end

                % delete DICOM if this is a repeat
                if skipCheck == 1
                    X(:,:,i1+layerCount-skip) = [];
                    sliceLoc(i1+layerCount-skip) = [];
                end

                if isfield(metadata,'SliceLocation') == 1
                    if min(abs(allSlice-metadata.SliceLocation)) == 0
                        skip = skip + 1;
                    end
                elseif isfield(metadata,'ImagePositionPatient') == 1
                    if min(abs(allSlice-metadata.ImagePositionPatient(3))) == 0
                        skip = skip + 1;
                    end
                elseif isfield(metadata,'InstanceNumber') == 1
                    if min(abs(allSlice-metadata.InstanceNumber)) == 0
                        skip = skip + 1;
                    end
                end

                if isfield(metadata,'SliceLocation') == 1
                    allSlice = [allSlice metadata.SliceLocation];
                elseif isfield(metadata,'ImagePositionPatient') == 1
                    allSlice = [allSlice metadata.ImagePositionPatient(3)];
                elseif isfield(metadata,'InstanceNumber') == 1
                    allSlice = [allSlice metadata.InstanceNumber];
                end
            end
            if length(X)
                layerCount = length(X(1,1,:)); % keep track of size of X
            end

            if p == 1
                progressUpdate(j/length(folders))
            end

        end

        % now rescale all the intensity values in the matrix so that the matrix
        % contains the original intensity values rather than the scaled values that
        % dicomread produces
        % need an exception for the Australia CT scans
        if strcmp(dataOwner,'TomDeCarlo') && (strcmp(currentRegion,'Eastern Australia') || strcmp(currentRegion,'New Caledonia'))
            X = (double(X).*metadata.RescaleSlope)*(4000/(metadata.RescaleSlope*255))-1000;
        else
            X = X.*metadata.RescaleSlope + metadata.RescaleIntercept;
        end

    end

    function buildCore

        % Script to build a map of where a core exists in a 3D coral CT scan

        %processNumber = processNumber + 1;
        titleName = 'Mapping Core';

        warning('off','all')

        % scan the entire CT image
        bottomCore = 1;
        topCore = layers;

        % need an exception for the Australia CT scans
        if strcmp(dataOwner,'TomDeCarlo') && (strcmp(currentRegion,'Eastern Australia') || strcmp(currentRegion,'New Caledonia'))
            if HU2dens(1) == 703.96
                X4coral = X;
                X4coral(X4coral<52) = -1000;
            else
            end
        end

        % initialize filtered image
        filteredXcore = zeros(size(X(:,:,1)));

        % initialize matrix to store indices of where coral, cracks exist
        coral = zeros(row,col,topCore);
        cracks = zeros(row,col,topCore);

        % keep track of size of coral in voxels and if an approximate cylinder
        ellA = zeros(length(bottomCore:topCore),1);
        corA = zeros(length(bottomCore:topCore),1);

        % store coordinates of extremes of outer edges of location of core
        center = zeros(topCore-bottomCore,2); % to store center of core in each layer
        leftMost = zeros(topCore-bottomCore,2);
        rightMost = zeros(topCore-bottomCore,2);
        topMost = zeros(topCore-bottomCore,2);
        bottomMost = zeros(topCore-bottomCore,2);

        % initialize crack variables and storage
        crackA = zeros(row,col);
        crackCheck = 0;
        crackExist = 0;
        crackLayers = zeros(1,layers);
        crackStart = 1;

        for i = bottomCore:topCore % loop through DICOM images

            % filter DICOM image
            if strcmp(dataOwner,'TomDeCarlo') && (strcmp(currentRegion,'Eastern Australia') || strcmp(currentRegion,'New Caledonia'))
                filteredXcore(:,:) = imfilter(X4coral(:,:,i), h2, 'replicate');
            else
                filteredXcore(:,:) = imfilter(X(:,:,i), h2, 'replicate');
            end

            % Use thresholding to identify core region. If 'thresh' == 0, uses
            % Otsu's method, otherwise user can set defined threshold value (in HU)
            level = 0;

            thresh = multithresh(filteredXcore,1);
            if thresh > -800
                coral(:,:,i) = filteredXcore>thresh;
            else
                altThresh = multithresh(filteredXcore,3);
                if altThresh(2) > -800
                    thresh = altThresh(2);
                    coral(:,:,i) = filteredXcore>thresh;
                elseif altThresh(3) > -800
                    thresh = altThresh(3);
                    coral(:,:,i) = filteredXcore>thresh;
                end
            end

            % set borders to 0
            coral(:,1,i) = 0;
            coral(:,col,i) = 0;
            coral(1,:,i) = 0;
            coral(row,:,i) = 0;

            if thresh > -800 && sum(sum(coral(:,:,i))) > 500

                % coordinates of core
                [r,c] = find(coral(:,:,i));

                [val,loc] = max(r);
                topMost(i,1:2) = [c(loc),r(loc)];
                [val,loc] = min(r);
                bottomMost(i,1:2) = [c(loc),r(loc)];
                [val,loc] = max(c);
                rightMost(i,1:2) = [c(loc),r(loc)];
                [val,loc] = min(c);
                leftMost(i,1:2) = [c(loc),r(loc)];

                % determine the upperright, upperleft, lowerright, lowerleft
                [val,loc1] = max(r.*c); % note that 'val' does not matter for our purposes
                [val,loc2] = max((row-r).*(col-c));
                [val,loc3] = max((row-r).*c);
                [val,loc4] = max(r.*(col-c));

                % define the center.
                center(i,:) = [round((rightMost(i,1)+leftMost(i,1))/2),round((topMost(i,2)+bottomMost(i,2))/2)];

                % check if an ellipse can be defined
                check = 0;
                try fitellipse([leftMost(i,1:2);topMost(i,1:2);rightMost(i,1:2);bottomMost(i,1:2);...
                        c(loc1),r(loc1);c(loc2),r(loc2);c(loc3),r(loc3);c(loc4),r(loc4)]);
                    check = 1;
                catch
                end

                if check == 1

                    [z, a, b, alpha] = fitellipse([leftMost(i,1:2);topMost(i,1:2);rightMost(i,1:2);bottomMost(i,1:2);...
                        c(loc1),r(loc1);c(loc2),r(loc2);c(loc3),r(loc3);c(loc4),r(loc4)]);

                    ellA(i) = pi*a*b; % calculate area of ellipse
                    corA(i) = sum(sum(coral(:,:,i))); % area of coral

                    if i > 1 && (ellA(i)-corA(i))/ellA(i)*100 > crackTol % is percent crack > tolerance% ?
                        if crackCheck == 0 % not previous in a crack
                            crackCheck = 2; % start potential crack
                            crackStart = i; % note which layer the crack started in
                            crackA = coral(:,:,crackStart-1)-coral(:,:,i); % define crack area
                            cracks(:,:,i) = coral(:,:,crackStart-1)-coral(:,:,i); % store crack
                        else % previousy in a crack
                            crackA = crackA+coral(:,:,crackStart-1)-coral(:,:,i); % add on to crack area
                            crackA(crackA>0) = 1; % reset crack area to binary
                            crackA(crackA<0) = 0;
                            cracks(:,:,i) = coral(:,:,crackStart-1)-coral(:,:,i); % store crack
                        end
                    elseif crackCheck > 0 % potentially exited a crack
                        crackCheck = crackCheck - 1; % allow one layer to miss tolerance before reseting
                        if crackCheck == 0 % exited a crack
                            crackA = zeros(row,col); % reset crack area
                            if crackExist == 0 % if it was not a crack
                                cracks(:,:,crackStart:i) = 0; % delete the potential crack
                            end
                            crackExist = 0; % reset if crack was exited
                        end
                    end

                    if sum(crackA(coral(:,:,crackStart)==1)) > 0.75*sum(sum(sum(coral(:,:,i))))
                        crackExist = 1; % crack found
                        crackLayers(crackStart-1:i+1) = 1; % note which layers are crack layers
                    end

                end

            end

            progressUpdate((i-bottomCore+1)/((topCore-bottomCore)))

        end

        X(cracks==1) = NaN; % delete the crack regions in X

        warning('on','all'); % turn warnings back on

    end

    function densityBetweenBands

        % function to compute density between annual density bands in coral CT scans

        %processNumber = processNumber + 1;
        titleName = 'Annual density';

        % initialize storage
        densityTotal = zeros(totBands2-1,1);

        % prog bar reset
        p1 = patch(ha3,[0 0 1 1],[0 1 1 0],[0.2 0.2 0.2]);

        % loop through denisty bands less one because can only compute density
        % between consecutive bands
        for i = 1:totBands2-1

            titleName = 'Calculating annual density';
            progressUpdate(i/(totBands2-1));

            % matrix of zeros same size as CT scan
            Xcor = zeros(size(X));

            % difference between consectutive bands
            betweenBands1 = LDBdata(:,:,i)-LDBdata(:,:,i+1);

            % bottom band
            betweenBands2 = LDBdata(:,:,i+1);

            % define number of DICOM images above bottom band
            betweenBands1 = LDBdata(:,:,i+1)+betweenBands1;

            % set to 0 any coordinate that is not covered by both bands
            betweenBands2(isnan(betweenBands1)==1) = 0;
            betweenBands1(isnan(betweenBands1)==1) = 0;

            % find coordinates covered by both bands
            [ro,co] = find(betweenBands1);

            % set region between bands to 1 in Xcor, only if inside core
            for j = 1:length(ro)
                Xcor(ro(j),co(j),betweenBands2(ro(j),co(j)):betweenBands1(ro(j),co(j))) ...
                    = coral(ro(j),co(j),betweenBands2(ro(j),co(j)):betweenBands1(ro(j),co(j)));
            end

            % unroll region between bands
            Xcor2 = X(Xcor==1);

            % take mean of region between bands (nanmean excludes any cracks)
            mDens = nanmean(Xcor2);

            % assign mean density of this band
            densityTotal(i) = (nanmean(mDens)-HU2dens(2))/HU2dens(1); % mean density

        end

    end

    function densityBetweenBandsXray

        % initialize storage
        densityTotal = zeros(totBands2-1,1);

        % loop through denisty bands less one because can only compute density
        % between consecutive bands
        for i = 1:totBands2-1

            densityLDBdata = layers-LDBdata;

            theseXs1 = find(~isnan(densityLDBdata(:,i)'));
            theseXs2 = find(~isnan(densityLDBdata(:,i+1)'));

            theseYs = [densityLDBdata(:,i)',fliplr(densityLDBdata(:,i+1)')];
            theseYs = theseYs(~isnan(theseYs));

            [colGrid ,layerGrid] = meshgrid(1:col,1:layers);

            [count4dens1,count4dens2] = inpolygon(colGrid(:),layerGrid(:),[theseXs1,fliplr(theseXs2)],theseYs);
            count4dens = count4dens1+count4dens2;
            count4dens(count4dens>0) = 1;

            count4dens = reshape(count4dens,size(slabDraw));

            theseDens = slabDraw(logical(count4dens));

            densityTotal(i) = mean(theseDens);

        end

    end

    function volumeDensity

        % Script to compute volume and mean density of a coral CT scan. Requires
        % that 'buildCore' and 'coralStandardCurve' have already been executed.

        % check for where the core has not been built yet
        unBuilt = [1:bottomCore-1, topCore+1:layers];

        % add on to existing core where it is not already built
        for k = 1:length(unBuilt)
            i = unBuilt(k);
            filteredXcore(:,:) = imfilter(X(:,:,i), h2,'replicate');
            thresh = multithresh(filteredXcore,1);
            if thresh > -800
                coral(:,:,i) = filteredXcore>thresh;
            else
                altThresh = multithresh(filteredXcore,3);
                if altThresh(2) > -800
                    coral(:,:,i) = filteredXcore>altThresh(2);
                elseif altThresh(3) > -800
                    coral(:,:,i) = filteredXcore>altThresh(3);
                end
            end
        end

        % now calculate volume and density

        pxT = sum(sum(sum(coral))); % total voxels in core

        volume = pxT*((hpxS/10)*(hpxS/10)*(pxS/10)); % volume in cm^3

        % mean whole-core density
        densityWholeCore = (mean(X(coral==1))-HU2dens(2))/HU2dens(1);

    end


    function extension_rate

        % initialize some storage matrices here, see their usage below
        totBands = length(find(max(max(userBands)))>0);

        n_traces = 5e3;

        % make smoothed bands first
        [rowMesh ,colMesh] = meshgrid(1:row,1:col);
        LDBdata = zeros(row,col,totBands);
        band_filt = zeros(size(LDBdata));

        % prog bar reset
        p1 = patch(ha3,[0 0 1 1],[0 1 1 0],[0.2 0.2 0.2]);

        for i4 = 1:totBands

            titleName = 'Calculating annual extension';
            progressUpdate(i4/totBands);
            if max(max(userBands(:,:,i4)))>0
                [r,c] = find(userBands(:,:,i4));
                if isempty(r)
                    break
                end
                v = zeros(1,length(r));
                for j2 = 1:length(r)
                    v(j2) = userBands(r(j2),c(j2),i4);
                end
                warning('off','all');
                if length(round(griddata(r,c,v,rowMesh,colMesh)))>1
                    LDBdata(:,:,i4) = permute(round(griddata(r,c,v,rowMesh,colMesh)),[2,1,3]);
                end
                warning('on','all');
            end
            band_filt(:,:,i4) = nanconv(LDBdata(:,:,i4), h3, 'nanout');
        end

        totBands2 = length(find(max(max(~isnan(band_filt))))>0);
        extension = NaN(totBands2-1,n_traces);

        % can use those later for plotting in 3d if desired
        pointsX = NaN(totBands2,n_traces);
        pointsY = NaN(totBands2,n_traces);

        % loop through all bands less one because can only measure rates between
        % consecutive bands
        for i = 1:totBands2-1

            % seed random points within this band
            n_points = 0;
            counter = 0;
            max_top_band = max(max(band_filt(:,:,i)));
            [dx,dy] = gradient(band_filt(:,:,i+1)*pxS/hpxS);
            v = ~isnan(band_filt(:,:,i+1)) & ~isnan(dx) & ~isnan(dy);
            [r,c] = find(v);
            rand_idx = randperm(length(r));
            sampled_x = c(rand_idx);
            sampled_y = r(rand_idx);
            while n_points<n_traces && counter<length(sampled_y)
                counter = counter+1;
                new_x = sampled_x(counter);
                new_y = sampled_y(counter);
                if ~isnan(band_filt(new_y,new_x,i+1))...
                        && coral(new_y,new_x,LDBdata(new_y,new_x,i+1)) == 1

                    this_path_z = band_filt(new_y,new_x,i+1):0.1:max_top_band;
                    z_relative = this_path_z-min(this_path_z);
                    this_path_x = new_x-z_relative.*dx(new_y,new_x);
                    this_path_y = new_y-z_relative.*dy(new_y,new_x);

                    to_remove = find(this_path_x<1 | this_path_x>col |...
                        this_path_y<1 | this_path_y>row);
                    this_path_x(to_remove) = [];
                    this_path_y(to_remove) = [];
                    this_path_z(to_remove) = [];

                    costFun = NaN(length(this_path_x),1);
                    for i2 = 1:length(this_path_x)
                        costFun(i2) = abs(min(min(this_path_z(i2)-band_filt(...
                            round(this_path_y(i2)),round(this_path_x(i2)),i))));
                    end

                    [dif,layerTop]  = min(costFun);

                    if dif <=1 % successfully traced between bands

                        n_points = n_points+1;
                        pointsX(i,n_points) = new_x;
                        pointsY(i,n_points) = new_y;

                        extension(i,n_points) = sqrt(((this_path_x(layerTop)-new_x)*hpxS)^2 +...
                            ((this_path_y(layerTop)-new_y)*hpxS)^2 + ...
                            (pxS*(this_path_z(layerTop)-this_path_z(1)))^2);

                    end
                end
            end
        end

    end


    function extension_rate_Xray

        % initialize some storage matrices here, see their usage below
        totBands = length(find(max(userBands))>0);

        n_traces = 1e3;

        % make smoothed bands first
        LDBdata = zeros(col,totBands);
        band_filt = NaN(size(LDBdata));
        h2d = sum(h3);
        h2mid = ceil(length(h3(:,1))/2);
        for i4 = 1:totBands
            if max(max(userBands(:,i4)))>0
                c = find(userBands(:,i4));
                if isempty(c)
                    break
                end
                this_band_interp = interp1(c,userBands(c,i4),min(c):max(c));

                for i5 = min(c):max(c)
                    h2x = i5-h2mid:i5-h2mid+length(h2d)-1;
                    thisH2d = h2d;
                    thisH2d(h2x < min(c)) = [];
                    h2x(h2x < min(c)) = [];
                    thisH2d(h2x > max(c)) = [];
                    h2x(h2x > max(c)) = [];
                    h2x = h2x-min(c)+1;
                    thisH2d = thisH2d./sum(thisH2d);
                    band_filt(i5,i4) = sum(this_band_interp(h2x).*thisH2d);
                end
            end
        end
        LDBdata = band_filt;

        totBands2 = length(find(max(~isnan(band_filt)))>0);
        extension = NaN(totBands2-1,n_traces);

        % loop through all bands less one because can only measure rates between
        % consecutive bands
        for i = 1:totBands2-1

            % seed random points within this band
            n_points = 0;
            counter = 0;
            max_top_band = max(band_filt(:,i));
            dx = gradient(band_filt(:,i+1)*pxS/hpxS);
            c = find(userBands(:,i+1));
            while n_points<n_traces && counter<1e7
                counter = counter+1;
                new_x = round(rand(1)*(range(c)-1)+min(c));
                if abs(dx(new_x)) > 0

                    this_path_z = band_filt(new_x,i+1):0.1:max_top_band;
                    z_relative = this_path_z-min(this_path_z);
                    this_path_x = new_x-z_relative.*dx(new_x);

                    to_remove = find(this_path_x<1 | this_path_x>col);
                    this_path_x(to_remove) = [];
                    this_path_z(to_remove) = [];

                    costFun = NaN(length(this_path_x),1);
                    for i2 = 1:length(this_path_x)
                        costFun(i2) = abs(min(min(this_path_z(i2)-band_filt(...
                            round(this_path_x(i2)),i))));
                    end

                    [dif,layerTop]  = min(costFun);

                    if dif <=1 % successfully traced between bands

                        n_points = n_points+1;

                        extension(i,n_points) = sqrt(((this_path_x(layerTop)-new_x)*hpxS)^2 +...
                            (pxS*(this_path_z(layerTop)-this_path_z(1)))^2);

                    end
                end
            end
        end

    end


processingGrowth = 0;

    function progressUpdate(fraction)

        if (strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')) && ct && processingGrowth == 1
            if doingDensCalib == 1
                title(ha3,[titleName,': ',num2str(round(fraction*100)),'%'],'Color','k')
            else
                title(ha3,[titleName,': ',num2str(round(fraction*100)),'%'],'Color','white')
            end
            set(ha3,'Color',[0.2 0.2 0.2])
        else
            title(ha3,[titleName,': ',num2str(round(fraction*100)),'%'])
        end

        if mod(1,2)==0
            patch(ha3,[0 0 fraction fraction],[0 1 1 0],themeColor1)
        else
            p1 = patch(ha3,[0 0 fraction fraction],[0 1 1 0],themeColor1);
        end
        drawnow

    end

h3_defined = 0;
    function chooseCoreFilter

        % filter for core identification
        % first number is size (in voxels), second number is standard deviation
        % (in voxels). Enter 'hpxS' in workspace after loading a core to
        % see the length of one voxel (in mm). Enter 'surf(h2)' in workspace to
        % visualize what the filter looks like.
        conversion_factor = (1./hpxS).*0.1; %(pixels per 0.1mm)
        if h3_defined == 0
            h3_width = 40;
            h3_std = 15;
            h3_defined = 1;
        end
        h3 = fspecial('gaussian',round(h3_width*conversion_factor), h3_std*conversion_factor);
        if strcmp(gen,'Porites')
            h2 = fspecial('gaussian',round(40*conversion_factor), 10*conversion_factor);
        elseif strcmp(gen,'Psammacora')
            h2 = fspecial('gaussian',round(40*conversion_factor), 10*conversion_factor);
        elseif strcmp(gen,'Siderastrea')
            h2 = fspecial('gaussian',round(40*conversion_factor), 10*conversion_factor);
        elseif strcmp(gen,'Montastrea') || strcmp(gen,'Orbicella')
            h2 = fspecial('gaussian',round(60*conversion_factor), 20*conversion_factor);
        elseif strcmp(gen,'Diploastrea')
            h2 = fspecial('gaussian',round(60*conversion_factor), 20*conversion_factor);
        elseif strcmp(gen,'Diploria')
            h2 = fspecial('gaussian',round(60*conversion_factor), 20*conversion_factor);
        elseif strcmp(gen,'Pseudodiploria')
            h2 = fspecial('gaussian',round(60*conversion_factor), 20*conversion_factor);
        elseif strcmp(gen,'Favia')
            h2 = fspecial('gaussian',round(60*conversion_factor), 20*conversion_factor);
        elseif strcmp(gen,'Mussimilia')
            h2 = fspecial('gaussian',round(60*conversion_factor), 20*conversion_factor);
        elseif strcmp(gen,'Mussismilia')
            h2 = fspecial('gaussian',round(60*conversion_factor), 20*conversion_factor);
        end

    end



    function [z, a, b, alpha] = fitellipse(x, varargin)
        %FITELLIPSE   least squares fit of ellipse to 2D data
        %
        %   [Z, A, B, ALPHA] = FITELLIPSE(X)
        %       Fit an ellipse to the 2D points in the 2xN array X. The ellipse is
        %       returned in parametric form such that the equation of the ellipse
        %       parameterised by 0 <= theta < 2*pi is:
        %           X = Z + Q(ALPHA) * [A * cos(theta); B * sin(theta)]
        %       where Q(ALPHA) is the rotation matrix
        %           Q(ALPHA) = [cos(ALPHA), -sin(ALPHA);
        %                       sin(ALPHA), cos(ALPHA)]
        %
        %       Fitting is performed by nonlinear least squares, optimising the
        %       squared sum of orthogonal distances from the points to the fitted
        %       ellipse. The initial guess is calculated by a linear least squares
        %       routine, by default using the Bookstein constraint (see below)
        %
        %   [...]            = FITELLIPSE(X, 'linear')
        %       Fit an ellipse using linear least squares. The conic to be fitted
        %       is of the form
        %           x'Ax + b'x + c = 0
        %       and the algebraic error is minimised by least squares with the
        %       Bookstein constraint (lambda_1^2 + lambda_2^2 = 1, where
        %       lambda_i are the eigenvalues of A)
        %
        %   [...]            = FITELLIPSE(..., 'Property', 'value', ...)
        %       Specify property/value pairs to change problem parameters
        %          Property                  Values
        %          =================================
        %          'constraint'              {|'bookstein'|, 'trace'}
        %                                    For the linear fit, the following
        %                                    quadratic form is considered
        %                                    x'Ax + b'x + c = 0. Different
        %                                    constraints on the parameters yield
        %                                    different fits. Both 'bookstein' and
        %                                    'trace' are Euclidean-invariant
        %                                    constraints on the eigenvalues of A,
        %                                    meaning the fit will be invariant
        %                                    under Euclidean transformations
        %                                    'bookstein': lambda1^2 + lambda2^2 = 1
        %                                    'trace'    : lambda1 + lambda2     = 1
        %
        %           Nonlinear Fit Property   Values
        %           ===============================
        %           'maxits'                 positive integer, default 200
        %                                    Maximum number of iterations for the
        %                                    Gauss Newton step
        %
        %           'tol'                    positive real, default 1e-5
        %                                    Relative step size tolerance
        %   Example:
        %       % A set of points
        %       x = [1 2 5 7 9 6 3 8;
        %            7 6 8 7 5 7 2 4];
        %
        %       % Fit an ellipse using the Bookstein constraint
        %       [zb, ab, bb, alphab] = fitellipse(x, 'linear');
        %
        %       % Find the least squares geometric estimate
        %       [zg, ag, bg, alphag] = fitellipse(x);
        %
        %       % Plot the results
        %       plot(x(1,:), x(2,:), 'ro')
        %       hold on
        %       % plotellipse(zb, ab, bb, alphab, 'b--')
        %       % plotellipse(zg, ag, bg, alphag, 'k')
        %
        %   See also PLOTELLIPSE

        % Copyright Richard Brown, this code can be freely used and modified so
        % long as this line is retained
        error(nargchk(1, 5, nargin, 'struct'))

        % Default parameters
        params.fNonlinear = true;
        params.constraint = 'bookstein';
        params.maxits     = 200;
        params.tol        = 1e-5;

        % Parse inputs
        [x, params] = parseinputs(x, params, varargin{:});

        % Constraints are Euclidean-invariant, so improve conditioning by removing
        % centroid
        centroid = mean(x, 2);
        x        = x - repmat(centroid, 1, size(x, 2));

        % Obtain a linear estimate
        switch params.constraint
            % Bookstein constraint : lambda_1^2 + lambda_2^2 = 1
            case 'bookstein'
                [z, a, b, alpha] = fitbookstein(x);

                % 'trace' constraint, lambda1 + lambda2 = trace(A) = 1
            case 'trace'
                [z, a, b, alpha] = fitggk(x);
        end % switch

        % Minimise geometric error using nonlinear least squares if required
        if params.fNonlinear
            % Initial conditions
            z0     = z;
            a0     = a;
            b0     = b;
            alpha0 = alpha;

            % Apply the fit
            [z, a, b, alpha, fConverged] = ...
                fitnonlinear(x, z0, a0, b0, alpha0, params);

            % Return linear estimate if GN doesn't converge
            if ~fConverged
                warning('fitellipse:FailureToConverge', ...'
                    'Gauss-Newton did not converge, returning linear estimate');
                z = z0;
                a = a0;
                b = b0;
                alpha = alpha0;
            end
        end

        % Add the centroid back on
        z = z + centroid;

    end % fitellipse



    function [z, a, b, alpha] = fitbookstein(x)
        %FITBOOKSTEIN   Linear ellipse fit using bookstein constraint
        %   lambda_1^2 + lambda_2^2 = 1, where lambda_i are the eigenvalues of A

        % Convenience variables
        m  = size(x, 2);
        x1 = x(1, :)';
        x2 = x(2, :)';

        % Define the coefficient matrix B, such that we solve the system
        % B *[v; w] = 0, with the constraint norm(w) == 1
        B = [x1, x2, ones(m, 1), x1.^2, sqrt(2) * x1 .* x2, x2.^2];

        % To enforce the constraint, we need to take the QR decomposition
        [Q, R] = qr(B);

        % Decompose R into blocks
        R11 = R(1:3, 1:3);
        R12 = R(1:3, 4:6);
        R22 = R(4:6, 4:6);

        % Solve R22 * w = 0 subject to norm(w) == 1
        [U, S, V] = svd(R22);
        w = V(:, 3);

        % Solve for the remaining variables
        v = -R11 \ R12 * w;

        % Fill in the quadratic form
        A        = zeros(2);
        A(1)     = w(1);
        A([2 3]) = 1 / sqrt(2) * w(2);
        A(4)     = w(3);
        bv       = v(1:2);
        c        = v(3);

        % Find the parameters
        [z, a, b, alpha] = conic2parametric(A, bv, c);

    end % fitellipse



    function [z, a, b, alpha] = fitggk(x)
        % Linear least squares with the Euclidean-invariant constraint Trace(A) = 1

        % Convenience variables
        m  = size(x, 2);
        x1 = x(1, :)';
        x2 = x(2, :)';

        % Coefficient matrix
        B = [2 * x1 .* x2, x2.^2 - x1.^2, x1, x2, ones(m, 1)];

        v = B \ -x1.^2;

        % For clarity, fill in the quadratic form variables
        A        = zeros(2);
        A(1,1)   = 1 - v(2);
        A([2 3]) = v(1);
        A(2,2)   = v(2);
        bv       = v(3:4);
        c        = v(5);

        % find parameters
        [z, a, b, alpha] = conic2parametric(A, bv, c);

    end



    function [z, a, b, alpha, fConverged] = fitnonlinear(x, z0, a0, b0, alpha0, params)
        % Gauss-Newton least squares ellipse fit minimising geometric distance

        % Get initial rotation matrix
        Q0 = [cos(alpha0), -sin(alpha0); sin(alpha0) cos(alpha0)];
        m = size(x, 2);

        % Get initial phase estimates
        phi0 = angle( [1 i] * Q0' * (x - repmat(z0, 1, m)) )';
        u = [phi0; alpha0; a0; b0; z0];

        % Iterate using Gauss Newton
        fConverged = false;
        for nIts = 1:params.maxits
            % Find the function and Jacobian
            [f, J] = sys(u);

            % Solve for the step and update u
            h = -J \ f;
            u = u + h;

            % Check for convergence
            delta = norm(h, inf) / norm(u, inf);
            if delta < params.tol
                fConverged = true;
                break
            end
        end

        alpha = u(end-4);
        a     = u(end-3);
        b     = u(end-2);
        z     = u(end-1:end);


        function [f, J] = sys(u)
            % SYS : Define the system of nonlinear equations and Jacobian. Nested
            % function accesses X (but changeth it not)
            % from the FITELLIPSE workspace

            % Tolerance for whether it is a circle
            circTol = 1e-5;

            % Unpack parameters from u
            phi   = u(1:end-5);
            alpha = u(end-4);
            a     = u(end-3);
            b     = u(end-2);
            z     = u(end-1:end);

            % If it is a circle, the Jacobian will be singular, and the
            % Gauss-Newton step won't work.
            %TODO: This can be fixed by switching to a Levenberg-Marquardt
            %solver
            if abs(a - b) / (a + b) < circTol
                warning('fitellipse:CircleFound', ...
                    'Ellipse is near-circular - nonlinear fit may not succeed')
            end

            % Convenience trig variables
            c = cos(phi);
            s = sin(phi);
            ca = cos(alpha);
            sa = sin(alpha);

            % Rotation matrices
            Q    = [ca, -sa; sa, ca];
            Qdot = [-sa, -ca; ca, -sa];

            % Preallocate function and Jacobian variables
            f = zeros(2 * m, 1);
            J = zeros(2 * m, m + 5);
            for i = 1:m
                rows = (2*i-1):(2*i);
                % Equation system - vector difference between point on ellipse
                % and data point
                f((2*i-1):(2*i)) = x(:, i) - z - Q * [a * cos(phi(i)); b * sin(phi(i))];

                % Jacobian
                J(rows, i) = -Q * [-a * s(i); b * c(i)];
                J(rows, (end-4:end)) = ...
                    [-Qdot*[a*c(i); b*s(i)], -Q*[c(i); 0], -Q*[0; s(i)], [-1 0; 0 -1]];
            end
        end
    end % fitnonlinear



    function [z, a, b, alpha] = conic2parametric(A, bv, c)
        % Diagonalise A - find Q, D such at A = Q' * D * Q
        [Q, D] = eig(A);
        Q = Q';

        % If the determinant < 0, it's not an ellipse
        if prod(diag(D)) <= 0
            error('fitellipse:NotEllipse', 'Linear fit did not produce an ellipse');
        end

        % We have b_h' = 2 * t' * A + b'
        t = -0.5 * (A \ bv);

        c_h = t' * A * t + bv' * t + c;

        z = t;
        a = sqrt(-c_h / D(1,1));
        b = sqrt(-c_h / D(2,2));
        alpha = atan2(Q(1,2), Q(1,1));
    end % conic2parametric



    function [x, params] = parseinputs(x, params, varargin)
        % PARSEINPUTS put x in the correct form, and parse user parameters

        % CHECK x
        % Make sure x is 2xN where N > 3
        if size(x, 2) == 2
            x = x';
        end
        if size(x, 1) ~= 2
            error('fitellipse:InvalidDimension', ...
                'Input matrix must be two dimensional')
        end
        if size(x, 2) < 6
            error('fitellipse:InsufficientPoints', ...
                'At least 6 points required to compute fit')
        end


        % Determine whether we are solving for geometric (nonlinear) or algebraic
        % (linear) distance
        if ~isempty(varargin) && strncmpi(varargin{1}, 'linear', length(varargin{1}))
            params.fNonlinear = false;
            varargin(1)       = [];
        else
            params.fNonlinear = true;
        end

        % Parse property/value pairs
        if rem(length(varargin), 2) ~= 0
            error('fitellipse:InvalidInputArguments', ...
                'Additional arguments must take the form of Property/Value pairs')
        end

        % Cell array of valid property names
        properties = {'constraint', 'maxits', 'tol'};

        while length(varargin) ~= 0
            % Pop pair off varargin
            property      = varargin{1};
            value         = varargin{2};
            varargin(1:2) = [];

            % If the property has been supplied in a shortened form, lengthen it
            iProperty = find(strncmpi(property, properties, length(property)));
            if isempty(iProperty)
                error('fitellipse:UnknownProperty', 'Unknown Property');
            elseif length(iProperty) > 1
                error('fitellipse:AmbiguousProperty', ...
                    'Supplied shortened property name is ambiguous');
            end

            % Expand property to its full name
            property = properties{iProperty};

            % Check for irrelevant property
            if ~params.fNonlinear && ismember(property, {'maxits', 'tol'})
                warning('fitellipse:IrrelevantProperty', ...
                    'Supplied property has no effect on linear estimate, ignoring');
                continue
            end

            % Check supplied property value
            switch property
                case 'maxits'
                    if ~isnumeric(value) || value <= 0
                        error('fitcircle:InvalidMaxits', ...
                            'maxits must be an integer greater than 0')
                    end
                    params.maxits = value;
                case 'tol'
                    if ~isnumeric(value) || value <= 0
                        error('fitcircle:InvalidTol', ...
                            'tol must be a positive real number')
                    end
                    params.tol = value;
                case 'constraint'
                    switch lower(value)
                        case 'bookstein'
                            params.constraint = 'bookstein';
                        case 'trace'
                            params.constraint = 'trace';
                        otherwise
                            error('fitellipse:InvalidConstraint', ...
                                'Invalid constraint specified')
                    end
            end % switch property
        end % while

    end % parseinputs

    function c = nanconv(a, k, varargin)
        % NANCONV Convolution in 1D or 2D ignoring NaNs.
        %   C = NANCONV(A, K) convolves A and K, correcting for any NaN values
        %   in the input vector A. The result is the same size as A (as though you
        %   called 'conv' or 'conv2' with the 'same' shape).
        %
        %   C = NANCONV(A, K, 'param1', 'param2', ...) specifies one or more of the following:
        %     'edge'     - Apply edge correction to the output.
        %     'noedge'   - Do not apply edge correction to the output (default).
        %     'nanout'   - The result C should have NaNs in the same places as A.
        %     'nonanout' - The result C should have ignored NaNs removed (default).
        %                  Even with this option, C will have NaN values where the
        %                  number of consecutive NaNs is too large to ignore.
        %     '2d'       - Treat the input vectors as 2D matrices (default).
        %     '1d'       - Treat the input vectors as 1D vectors.
        %                  This option only matters if 'a' or 'k' is a row vector,
        %                  and the other is a column vector. Otherwise, this
        %                  option has no effect.
        %
        %   NANCONV works by running 'conv2' either two or three times. The first
        %   time is run on the original input signals A and K, except all the
        %   NaN values in A are replaced with zeros. The 'same' input argument is
        %   used so the output is the same size as A. The second convolution is
        %   done between a matrix the same size as A, except with zeros wherever
        %   there is a NaN value in A, and ones everywhere else. The output from
        %   the first convolution is normalized by the output from the second
        %   convolution. This corrects for missing (NaN) values in A, but it has
        %   the side effect of correcting for edge effects due to the assumption of
        %   zero padding during convolution. When the optional 'noedge' parameter
        %   is included, the convolution is run a third time, this time on a matrix
        %   of all ones the same size as A. The output from this third convolution
        %   is used to restore the edge effects. The 'noedge' parameter is enabled
        %   by default so that the output from 'nanconv' is identical to the output
        %   from 'conv2' when the input argument A has no NaN values.
        %
        % See also conv, conv2
        %
        % AUTHOR: Benjamin Kraus (bkraus@bu.edu, ben@benkraus.com)
        % Copyright (c) 2013, Benjamin Kraus
        % $Id: nanconv.m 4861 2013-05-27 03:16:22Z bkraus $

        % Process input arguments
        for arg = 1:nargin-2
            switch lower(varargin{arg})
                case 'edge'; edge = true; % Apply edge correction
                case 'noedge'; edge = false; % Do not apply edge correction
                case {'same','full','valid'}; shape = varargin{arg}; % Specify shape
                case 'nanout'; nanout = true; % Include original NaNs in the output.
                case 'nonanout'; nanout = false; % Do not include NaNs in the output.
                case {'2d','is2d'}; is1D = false; % Treat the input as 2D
                case {'1d','is1d'}; is1D = true; % Treat the input as 1D
            end
        end

        % Apply default options when necessary.
        if(exist('edge','var')~=1); edge = false; end
        if(exist('nanout','var')~=1); nanout = false; end
        if(exist('is1D','var')~=1); is1D = false; end
        if(exist('shape','var')~=1); shape = 'same';
        elseif(~strcmp(shape,'same'))
            error([mfilename ':NotImplemented'],'Shape ''%s'' not implemented',shape);
        end

        % Get the size of 'a' for use later.
        sza = size(a);

        % If 1D, then convert them both to columns.
        % This modification only matters if 'a' or 'k' is a row vector, and the
        % other is a column vector. Otherwise, this argument has no effect.
        if(is1D);
            if(~isvector(a) || ~isvector(k))
                error('MATLAB:conv:AorBNotVector','A and B must be vectors.');
            end
            a = a(:); k = k(:);
        end

        % Flat function for comparison.
        o = ones(size(a));

        % Flat function with NaNs for comparison.
        on = ones(size(a));

        % Find all the NaNs in the input.
        n = isnan(a);

        % Replace NaNs with zero, both in 'a' and 'on'.
        a(n) = 0;
        on(n) = 0;

        % Check that the filter does not have NaNs.
        if(any(isnan(k)));
            error([mfilename ':NaNinFilter'],'Filter (k) contains NaN values.');
        end

        % Calculate what a 'flat' function looks like after convolution.
        if(any(n(:)) || edge)
            flat = conv2(on,k,shape);
        else flat = o;
        end

        % The line above will automatically include a correction for edge effects,
        % so remove that correction if the user does not want it.
        if(any(n(:)) && ~edge); flat = flat./conv2(o,k,shape); end

        % Do the actual convolution
        c = conv2(a,k,shape)./flat;

        % If requested, replace output values with NaNs corresponding to input.
        if(nanout); c(n) = NaN; end

        % If 1D, convert back to the original shape.
        if(is1D && sza(1) == 1); c = c.'; end

    end

lblOpeningError = uicontrol(UserFig,'Style','text','String',' ','Position',[200,150,500,20],...
    'BackgroundColor',themeColor2,'FontSize',10,'FontName','Arial','Units','normalized','Visible','off');

if strcmp(CoralCTformat,'mchips') || strcmp(CoralCTformat,'windows')
    close(UserFig0)
end
set(UserFig,'Visible','on')
%pause(0.1)

end
