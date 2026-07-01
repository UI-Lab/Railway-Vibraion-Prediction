clc;
clear;
close all;

path = 'G:\Thesis\Documents\Line 6 Metrp Tehran Tests\Results';
file = 'R12-T-07-11-53-TR-545-AW5-D.xlsx';

Data = readmatrix(file);

acc_A = Data(1:end,4); % On the rail feet (north)
acc_B =  Data(1:end,5); % On the slab
acc_C =  Data(1:end,6); % close to the slab
acc_D =  Data(1:end,7); % On the rail feet (south)

t = 0:1/1000:length(acc_A)/1000-1/1000; %Time

acc_A = acc_A - mean(acc_A); % On the rail feet (north)
acc_B =  acc_B - mean(acc_B); % On the slab
acc_C =  acc_C - mean(acc_C); % close to the slab
acc_D =  acc_D - mean(acc_D); % On the rail feet (south)

PPA_A = acc_A;
PPA_B = acc_B;
PPA_C = acc_C;
PPA_D = acc_D;

% Signal length
LA = length(PPA_A);
LB = length(PPA_B);
LC = length(PPA_C);
LD = length(PPA_D);
% Sampling Rate and Duration
dt = t(10)-t(9);
fs = 1/dt;

% Filter the signal
lowcut = 2; % Lower cutoff frequency (Hz)
highcut = 499; % Upper cutoff frequency (Hz)
order = 4; % Filter order

% Design Butterworth band-pass filter
[b, a] = butter(order, [lowcut, highcut]/(fs/2), 'bandpass');

% Filter the signal
PPA_A = filtfilt(b,a,PPA_A); % On the rail feet (north)
PPA_B = filtfilt(b,a,PPA_B); % On the slab
PPA_C = filtfilt(b,a,PPA_C); % close to the slab
PPA_D = filtfilt(b,a,PPA_D); % On the rail feet (south)

% Notch Filter
fo = 49.9/(fs/2);  
bw = fo/35;
[b,a] = iirnotch(fo,bw);

% Filter the signal
PPA_A = filtfilt(b,a,PPA_A); % On the rail feet (north)
PPA_B = filtfilt(b,a,PPA_B); % On the slab
PPA_C = filtfilt(b,a,PPA_C); % close to the slab
PPA_D = filtfilt(b,a,PPA_D); % On the rail feet (south)


% 2. One-second RMS (Root Mean Square) value - Sliding window RMS
RMSA = zeros(length(PPA_A),1);
for i = 1:length(PPA_A)
    if fs+i < length(PPA_A)
        RMSA(i) = rms(PPA_A(i:fs+i));
    else
        RMSA(i) = rms(PPA_A(i-fs:i-1));
    end
end

RMSB = zeros(length(PPA_B),1);
for i = 1:length(PPA_B)
    if fs+i < length(PPA_B)
        RMSB(i) = rms(PPA_B(i:fs+i));
    else
        RMSB(i) = rms(PPA_B(i-fs:i-1));
    end
end

RMSC = zeros(length(PPA_C),1);
for i = 1:length(PPA_C)
    if fs+i < length(PPA_C)
        RMSC(i) = rms(PPA_C(i:fs+i));
    else
        RMSC(i) = rms(PPA_C(i-fs:i-1));
    end
end

RMSD = zeros(length(PPA_D),1);
for i = 1:length(PPA_D)
    if fs+i < length(PPA_D)
        RMSD(i) = rms(PPA_D(i:fs+i));
    else
        RMSD(i) = rms(PPA_D(i-fs:i-1));
    end
end

% Perform FFT (on filtered signal)
N = length(PPA_A); % Length of the signal
f = (0:N-1)*(fs/N); % Frequency vector
f(1)=0.01;
signal_fftA = fft(PPA_A); % Compute the FFT
signal_fftB = fft(PPA_B); % Compute the FFT
signal_fftC = fft(PPA_C); % Compute the FFT
signal_fftD = fft(PPA_D); % Compute the FFT

P2A = abs(signal_fftA/N); % Two-sided spectrum
P1A = P2A(2:N/2+1); % Single-sided spectrum
P1A(2:end-1) = 2*P1A(2:end-1); % Correct amplitude for single-sided spectrum

P2B = abs(signal_fftB/N); % Two-sided spectrum
P1B = P2B(2:N/2+1); % Single-sided spectrum
P1B(2:end-1) = 2*P1B(2:end-1); % Correct amplitude for single-sided spectrum

P2C = abs(signal_fftC/N); % Two-sided spectrum
P1C = P2C(2:N/2+1); % Single-sided spectrum
P1C(2:end-1) = 2*P1C(2:end-1); % Correct amplitude for single-sided spectrum

P2D = abs(signal_fftD/N); % Two-sided spectrum
P1D = P2D(2:N/2+1); % Single-sided spectrum
P1D(2:end-1) = 2*P1D(2:end-1); % Correct amplitude for single-sided spectrum

f_single = f(2:N/2+1); % Frequency vector for single-sided spectrum

% Define the center frequencies for one-third octave bands
f_min = 2; % Minimum frequency in Hz
f_max = fs / 2+20; % Nyquist frequency

% Generate center frequencies for one-third octave bands
f_center = f_min * (2.^(0:1/3:log2(f_max/f_min))); % Center frequencies for 1/3 octave bands

AMP_A = zeros(length(f_center), 1); % Preallocate PPV array for one-third octave bands
AMP_B = zeros(length(f_center), 1); % Preallocate PPV array for one-third octave bands
AMP_C = zeros(length(f_center), 1); % Preallocate PPV array for one-third octave bands
AMP_D = zeros(length(f_center), 1); % Preallocate PPV array for one-third octave bands

for i = 1:length(f_center)
    % Define lower and upper bounds of the band
    f_low = f_center(i) / (2^(1/6)); % Lower frequency bound (one-third octave)
    f_high = f_center(i) * (2^(1/6)); % Upper frequency bound (one-third octave)
    
    % Find the indices corresponding to this band
    band_indicesR = find(f_single >= f_low & f_single <= f_high);
    % Calculate the PPV for this band (maximum amplitude in the band)
    if ~isempty(band_indicesR)
        AMP_A(i) = max(P1A(band_indicesR)); % Peak amplitude within the band
    else
        AMP_A(i) = 0; % If no frequencies in this band, set PPV to zero
    end
    
    if ~isempty(band_indicesR)
        AMP_B(i) = max(P1B(band_indicesR)); % Peak amplitude within the band
    else
        AMP_B(i) = 0; % If no frequencies in this band, set PPV to zero
    end
    
    if ~isempty(band_indicesR)
        AMP_C(i) = max(P1C(band_indicesR)); % Peak amplitude within the band
    else
        AMP_C(i) = 0; % If no frequencies in this band, set PPV to zero
    end
    
    if ~isempty(band_indicesR)
        AMP_D(i) = max(P1D(band_indicesR)); % Peak amplitude within the band
    else
        AMP_D(i) = 0; % If no frequencies in this band, set PPV to zero
    end
   
end

f_center = f_center.';
% Convert to dB scale
PPA_ref = 1e-6; % Reference PPV for dB conversion, adjust as needed

AMP_A_dB = 20 * log10(AMP_A ./ PPA_ref);
AMP_B_dB = 20 * log10(AMP_B ./ PPA_ref);
AMP_C_dB = 20 * log10(AMP_C ./ PPA_ref);
AMP_D_dB = 20 * log10(AMP_D ./ PPA_ref);

% Maximums
% Time domain ppv
PPA_A_max = max(PPA_A); % Max On the rail feet (north)
PPA_B_max = max(PPA_B); % Max On the slab
PPA_C_max = max(PPA_C); % Max close to the slab
PPA_D_max = max(PPA_D); % Max On the rail feet (south)

% Time domain RMS
RMSA_max = max(RMSA); % Max On the rail feet (north)
RMSB_max = max(RMSB); % Max On the slab
RMSC_max = max(RMSC); % Max close to the slab
RMSD_max = max(RMSD); % Max On the rail feet (south)

% Frequency domain
[P1A_max,fA_max] = max(P1A); % Max On the rail feet (north)
[P1B_max,fB_max] = max(P1B); % Max On the slab
[P1C_max,fC_max] = max(P1C); % Max close to the slab
[P1D_max,fD_max] = max(P1D); % Max On the rail feet (south)

P1A_max = 20 * log10(P1A_max ./ PPA_ref); % Max On the rail feet (north)
P1B_max = 20 * log10(P1B_max ./ PPA_ref); % Max On the slab
P1C_max = 20 * log10(P1C_max ./ PPA_ref); % Max close to the slab
P1D_max = 20 * log10(P1D_max ./ PPA_ref); % Max On the rail feet (south)

% Create the table
T_maximums = table([PPA_A_max;PPA_B_max;PPA_C_max;PPA_D_max],...
                   [fA_max;fB_max;fC_max;fD_max],...
                   [P1A_max;P1B_max;P1C_max;P1D_max],...
                   [RMSA_max;RMSB_max;RMSC_max;RMSD_max],...
                   'VariableNames',{'Maximum PPV (mm/s)','Frequency (Hz)','Maximum Amplitude (dB)','Maximum RMS (dB)'},...
                   'RowNames',{'On the rail feet (A)';'On the slab (B)';'Close the the slab (C)';'On the other Rail (D)'});


T_frequency_domain = table(f_center,AMP_A_dB,AMP_B_dB,AMP_C_dB,AMP_D_dB,'VariableNames',{'Frequency(Hz)','On the rail feet (A)','On the slab (B)','Close the the slab (C)','On the other Rail (D)'});


% Plots
fnom = file(1:end-5);
b1 = [fnom 'Time domain A.jpg'];
b2 = [fnom 'Time domain B.jpg'];
b3 = [fnom 'Time domain C.jpg'];
b4 = [fnom 'Time domain D.jpg'];

b6 = [fnom 'Frequency domain A.jpg'];
b7 = [fnom 'Frequency domain B.jpg'];
b8 = [fnom 'Frequency domain C.jpg'];
b9 = [fnom 'Frequency domain D.jpg'];

b11 = [fnom 'One-third Octave band A.jpg'];
b12 = [fnom 'One-third Octave band B.jpg'];
b13 = [fnom 'One-third Octave band C.jpg'];
b14 = [fnom 'One-third Octave band D.jpg'];

% Plot the original and windowed signals to visualize the effect
figure(1);
plot(t,PPA_A, 'LineWidth', 1.5, 'color', 'k');
hold on
plot(t,RMSA, 'LineWidth', 2.5, 'color', 'r');
legend('PPA','RMS')
% Set logarithmic scale for x-axis
set(gca,'XColor', [0,0,0], 'YColor', [0,0,0]);
set(gca, 'XLim', [t(1), t(end)]);
% Set font and color for axis ticks
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14); % Tick labels
% Set axis labels with font size 22 and black color
xlabel('Time [sec]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
ylabel('Peak particle acceleration [m/s^{2}]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
% Add black box around the plot
set(gca, 'Box', 'on', 'LineWidth', 1.2);
% Finish plotting
grid on
set(figure(1), 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); % Make the figure full screen
saveas(figure(1), b1); % Save as PNG with 300 DPI

figure(2);
plot(t,PPA_B, 'LineWidth', 1.5, 'color', 'k');
hold on
plot(t,RMSB, 'LineWidth', 2.5, 'color', 'r');
legend('PPA','RMS')
% Set logarithmic scale for x-axis
set(gca,'XColor', [0,0,0], 'YColor', [0,0,0]);
set(gca, 'XLim', [t(1), t(end)]);
% Set font and color for axis ticks
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14); % Tick labels
% Set axis labels with font size 22 and black color
xlabel('Time [sec]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
ylabel('Peak particle acceleration [m/s^{2}]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
% Add black box around the plot
set(gca, 'Box', 'on', 'LineWidth', 1.2);
% Finish plotting
grid on
set(figure(2), 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); % Make the figure full screen
saveas(figure(2), b2); % Save as PNG with 300 DPI

figure(3);
plot(t,PPA_C, 'LineWidth', 1.5, 'color', 'k');
hold on
plot(t,RMSC, 'LineWidth', 2.5, 'color', 'r');
legend('PPA','RMS')
% Set logarithmic scale for x-axis
set(gca,'XColor', [0,0,0], 'YColor', [0,0,0]);
set(gca, 'XLim', [t(1), t(end)]);
% Set font and color for axis ticks
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14); % Tick labels
% Set axis labels with font size 22 and black color
xlabel('Time [sec]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
ylabel('Peak particle acceleration [m/s^{2}]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
% Add black box around the plot
set(gca, 'Box', 'on', 'LineWidth', 1.2);
% Finish plotting
grid on
set(figure(3), 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); % Make the figure full screen
saveas(figure(3), b3); % Save as PNG with 300 DPI

figure(4);
plot(t,PPA_D, 'LineWidth', 1.5, 'color', 'k');
hold on
plot(t,RMSD, 'LineWidth', 2.5, 'color', 'r');
legend('PPA','RMS')
% Set logarithmic scale for x-axis
set(gca,'XColor', [0,0,0], 'YColor', [0,0,0]);
set(gca, 'XLim', [t(1), t(end)]);
% Set font and color for axis ticks
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14); % Tick labels
% Set axis labels with font size 22 and black color
xlabel('Time [sec]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
ylabel('Peak particle acceleration [m/s^{2}]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
% Add black box around the plot
set(gca, 'Box', 'on', 'LineWidth', 1.2);
% Finish plotting
grid on
set(figure(4), 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); % Make the figure full screen
saveas(figure(4), b4); % Save as PNG with 300 DPI


% Plot the single-sided amplitude spectrum
figure(6);
plot(f_single,P1A,'LineWidth',1.5,'color','k');
hold on
plot(f_single,P1A/sqrt(2),'LineWidth',2,'color','r');
legend('FFT','RMS')
% Set scale for x-axis
set(gca,'XColor', [0,0,0], 'YColor', [0,0,0]);
set(gca, 'XLim', [f_single(1), f_single(end)]);
% Set font and color for axis ticks
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14); % Tick labels
% Set axis labels with font size 22 and black color
xlabel('Frequency [Hz]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
ylabel('Amplitude [mm/s/Hz]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
% Add black box around the plot
set(gca, 'Box', 'on', 'LineWidth', 1.2);
% Finish plotting
grid on
set(figure(6), 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); % Make the figure full screen
saveas(figure(6), b6); % Save as PNG with 300 DPI

% Plot the single-sided amplitude spectrum
figure(7);
plot(f_single,P1B,'LineWidth',1.5,'color','k');
hold on
plot(f_single,P1B/sqrt(2),'LineWidth',2,'color','r');
legend('FFT','RMS')
% Set scale for x-axis
set(gca,'XColor', [0,0,0], 'YColor', [0,0,0]);
set(gca, 'XLim', [f_single(1), f_single(end)]);
% Set font and color for axis ticks
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14); % Tick labels
% Set axis labels with font size 22 and black color
xlabel('Frequency [Hz]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
ylabel('Amplitude [mm/s/Hz]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
% Add black box around the plot
set(gca, 'Box', 'on', 'LineWidth', 1.2);
% Finish plotting
grid on
set(figure(7), 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); % Make the figure full screen
saveas(figure(7), b7); % Save as PNG with 300 DPI

% Plot the single-sided amplitude spectrum
figure(8);
plot(f_single,P1C,'LineWidth',1.5,'color','k');
hold on
plot(f_single,P1C/sqrt(2),'LineWidth',2,'color','r');
legend('FFT','RMS')
% Set scale for x-axis
set(gca,'XColor', [0,0,0], 'YColor', [0,0,0]);
set(gca, 'XLim', [f_single(1), f_single(end)]);
% Set font and color for axis ticks
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14); % Tick labels
% Set axis labels with font size 22 and black color
xlabel('Frequency [Hz]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
ylabel('Amplitude [mm/s/Hz]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
% Add black box around the plot
set(gca, 'Box', 'on', 'LineWidth', 1.2);
% Finish plotting
grid on
set(figure(8), 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); % Make the figure full screen
saveas(figure(8), b8); % Save as PNG with 300 DPI

% Plot the single-sided amplitude spectrum
figure(9);
plot(f_single,P1D,'LineWidth',1.5,'color','k');
hold on
plot(f_single,P1D/sqrt(2),'LineWidth',2,'color','r');
legend('FFT','RMS')
% Set scale for x-axis
set(gca,'XColor', [0,0,0], 'YColor', [0,0,0]);
set(gca, 'XLim', [f_single(1), f_single(end)]);
% Set font and color for axis ticks
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14); % Tick labels
% Set axis labels with font size 22 and black color
xlabel('Frequency [Hz]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
ylabel('Amplitude [mm/s/Hz]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
% Add black box around the plot
set(gca, 'Box', 'on', 'LineWidth', 1.2);
% Finish plotting
grid on
set(figure(9), 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); % Make the figure full screen
saveas(figure(9), b9); % Save as PNG with 300 DPI

% Plot One-Third Octave Band in dB
figure(11);
stairs(f_center, AMP_A_dB, 'LineWidth', 2.5, 'color', [0,0,0]);
hold on
stairs(f_center, AMP_A_dB-3.0103, 'LineWidth', 2.5, 'color', [0.4,0.4,0.4]);
legend('PPA','RMS')
% Set logarithmic scale for x-axis
set(gca, 'XScale', 'log');
set(gca, 'XTick', [2,4,8,16,31.5,63,101.5], 'XColor', [0,0,0], 'YColor', [0,0,0]);
set(gca, 'XLim', [f_center(1), f_center(end)]);
% Set font and color for axis ticks
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14); % Tick labels
% Set axis labels with font size 22 and black color
xlabel('1/3 Octave Band Center Frequency [Hz]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
ylabel('Amplitude [dB ref 1\mu m/s^{2}]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
% Add black box around the plot
set(gca, 'Box', 'on', 'LineWidth', 1.2);
grid on
set(figure(11), 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); % Make the figure full screen
saveas(figure(11), b11); % Save as PNG with 300 DPI

figure(12);
stairs(f_center, AMP_B_dB, 'LineWidth', 2.5, 'color', [0,0,0]);
hold on
stairs(f_center, AMP_B_dB-3.0103, 'LineWidth', 2.5, 'color', [0.4,0.4,0.4]);
legend('PPA','RMS')
% Set logarithmic scale for x-axis
set(gca, 'XScale', 'log');
set(gca, 'XTick', [2,4,8,16,31.5,63,101.5], 'XColor', [0,0,0], 'YColor', [0,0,0]);
set(gca, 'XLim', [f_center(1), f_center(end)]);
% Set font and color for axis ticks
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14); % Tick labels
% Set axis labels with font size 22 and black color
xlabel('1/3 Octave Band Center Frequency [Hz]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
ylabel('Amplitude [dB ref 1\mu m/s^{2}]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
% Add black box around the plot
set(gca, 'Box', 'on', 'LineWidth', 1.2);
grid on
set(figure(12), 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); % Make the figure full screen
saveas(figure(12), b12); % Save as PNG with 300 DPI

figure(13);
stairs(f_center, AMP_C_dB, 'LineWidth', 2.5, 'color', [0,0,0]);
hold on
stairs(f_center, AMP_C_dB-3.0103, 'LineWidth', 2.5, 'color', [0.4,0.4,0.4]);
legend('PPA','RMS')
% Set logarithmic scale for x-axis
set(gca, 'XScale', 'log');
set(gca, 'XTick', [2,4,8,16,31.5,63,101.5], 'XColor', [0,0,0], 'YColor', [0,0,0]);
set(gca, 'XLim', [f_center(1), f_center(end)]);
% Set font and color for axis ticks
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14); % Tick labels
% Set axis labels with font size 22 and black color
xlabel('1/3 Octave Band Center Frequency [Hz]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
ylabel('Amplitude [dB ref 1\mu m/s^{2}]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
% Add black box around the plot
set(gca, 'Box', 'on', 'LineWidth', 1.2);
grid on
set(figure(13), 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); % Make the figure full screen
saveas(figure(13), b13); % Save as PNG with 300 DPI

figure(14);
stairs(f_center, AMP_D_dB, 'LineWidth', 2.5, 'color', [0,0,0]);
hold on
stairs(f_center, AMP_D_dB-3.0103, 'LineWidth', 2.5, 'color', [0.4,0.4,0.4]);
legend('PPA','RMS')
% Set logarithmic scale for x-axis
set(gca, 'XScale', 'log');
set(gca, 'XTick', [2,4,8,16,31.5,63,101.5], 'XColor', [0,0,0], 'YColor', [0,0,0]);
set(gca, 'XLim', [f_center(1), f_center(end)]);
% Set font and color for axis ticks
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14); % Tick labels
% Set axis labels with font size 22 and black color
xlabel('1/3 Octave Band Center Frequency [Hz]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
ylabel('Amplitude [dB ref 1\mu m/s^{2}]', 'FontName', 'Times New Roman', ...
       'FontSize', 20, 'Color', [0,0,0]);
% Add black box around the plot
set(gca, 'Box', 'on', 'LineWidth', 1.2);
grid on
set(figure(14), 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); % Make the figure full screen
saveas(figure(14), b14); % Save as PNG with 300 DPI

% Save data as en excel file
filename = 'Full Results.xlsx';
writetable(T_maximums,fullfile(path,filename),'sheet',file(1:end-4),'Range','A2:F7');

writetable(T_frequency_domain,fullfile(path,filename),'sheet',file(1:end-4),'Range','H1:M25');




















































































































