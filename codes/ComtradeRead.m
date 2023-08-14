function [t,data,f,samp_rate] = ComtradeRead()
%% 导入数据

[CFGFileName,PathName] = uigetfile('*.cfg','选择.CFG文件'); %打开.CFG文件
CFGPathFile = [PathName CFGFileName]; %读取.CFG文件路径和名称
DatFileName = [CFGFileName(:,1:length(CFGFileName)-4) '.dat']; %获得.DAT文件名称
DATPathFile = [PathName  DatFileName]; %获得.DAT文件路径

%% 读取配置文件

% cfg 文件
% 500 kV line, 135.220miles
% 6, 6A, 0D 
% 通道总数，模拟通道数量，状态通道数量
% 1, Current_Meter__line_of_interest_A1-A2__at_side_A1__Phase_A, , , A, 0.060072180, -86.697059631, 0.000000000
% 编号，名称，-，-，单位，变化因子A，变化因子B，时间偏移
% 实际值=A*采样值+B
% 60.000000 频率
% 1 采样频率个数
% 4800.0307201966, 7200 采样频率，数据点总数
% 04/08/2016,12:00:00.000000 采样开始时间
% 04/08/2016,12:00:00.000000 采样结束时间
% BINARY 编码格式
CFGid = fopen(CFGPathFile);
CFG = textscan(CFGid,'%s','delimiter','\n');
fclose(CFGid);
CFG_len = length(CFG{1,1});
CFG_str = cell(size(CFG{1,1}));
for i = 1:CFG_len
    temp_str = char(CFG{1,1}{i});
    CFG_str{i}=textscan(temp_str,'%s','delimiter',',');
end

% 通道数目
No_Ch = str2double(cell2mat(CFG_str{2,1}{1,1}(1)));
Ana_Ch = CFG_str{2,1}{1,1}{2,1};
Ana_Ch(length(Ana_Ch)) = [];
Ana_Ch = str2double(Ana_Ch);
Dig_Ch = CFG_str{2,1}{1,1}{3,1};
Dig_Ch(length(Dig_Ch)) = [];
Dig_Ch = str2double(Dig_Ch);

% 系统频率
f = textscan(cell2mat(CFG_str{3+No_Ch,1}{1,1}(1)),'%f');
f = f{1,1};

% 采样频率
samp_rate = textscan(cell2mat(CFG_str{5+No_Ch,1}{1,1}(1)),'%f');
samp_rate = samp_rate{1,1};

% 数据长度
dat_len = textscan(cell2mat(CFG_str{5+No_Ch,1}{1,1}(2)),'%f');
dat_len = dat_len{1,1};

% 存储格式
format=char(CFG_str{8+No_Ch,1}{1,1}(1));

%% 读取数据文件

% 采样编号，时间，模拟数据（A1...An）

DAT_id = fopen(DATPathFile);
algdat = zeros(dat_len,Ana_Ch+2);
num = zeros(dat_len,1);
time = zeros(dat_len,1);

if strcmpi(format, 'BINARY')
    for i = 1:dat_len
        num(i) = fread(DAT_id,1,'int32');
        time(i) = fread(DAT_id,1,'int32');
        row_array = fread(DAT_id,Ana_Ch+ceil(Dig_Ch/16),'int16');
        for j=3:Ana_Ch+2
            algdat(i,j) = row_array(j-2);
        end
    end
    algdat(:,1) = num;
    algdat(:,2) = time;
else
    DAT = textscan(DAT_id, '%s', 'delimiter', '\n');
    for i = 1:dat_len
        DAT_str = textscan(char(DAT{1,:}(i)), '%n', 'delimiter', ',');
        for j=1:Ana_Ch+2
            algdat(i,j) = dat_string(j);
        end
    end
end

fclose(DAT_id);
t = algdat(:,2)./1000;

%% 获得最终数据

data = zeros(dat_len, Ana_Ch);
for i = 1:Ana_Ch
    j = i+2;
    var_string = strcat('Ch',char((CFG_str{j,1}{1,1}{1,1})));
    multiplier = str2double(CFG_str{j,1}{1,1}{6,1});
    offset = str2double(CFG_str{j,1}{1,1}{7,1});
    data(:,i) = algdat(:,i+2)*multiplier+offset;
end