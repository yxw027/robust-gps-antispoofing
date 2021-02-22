% set exp data directory and the log files that will be processed
function config = SetConfig
    config.Base = './ExpData/';
    config.LogFile = {
        'gnss_log_2019_12_12_11_07_38.txt' 
        'gnss_log_2019_12_12_11_09_53.txt'
        'gnss_log_2019_12_12_11_12_10.txt'
        'gnss_log_2019_12_12_11_14_48.txt'
        'gnss_log_2019_12_12_11_17_47.txt'
        'gnss_log_2019_12_12_11_20_28.txt'
        'gnss_log_2019_12_12_11_22_59.txt'
        'gnss_log_2019_12_12_11_25_30.txt'
        'gnss_log_2019_12_12_11_27_48.txt'
        'gnss_log_2019_12_12_11_30_06.txt'
    };
end
