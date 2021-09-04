%{
    Asad Mirza
    PhD Candidate, Florida International University
    CV-PEUTICS Laboratory, https://cvpeutics.fiu.edu/
    8/31/2021
    
    Code to segment cell image into it's respective protein parts and
    quantify their intensities.
    
    It works as follows:
    1. User is asked to select original stained image.
    2. The code will then attempt to denoise the data at the user's
    request.
    3. The user is asked to give how many proteins are in the image to
    segment and what their respective names are (darkest to lightest)
    4. Multi Otsu thresholding is used to determine the various regions of
    the image corresponding to similar colors, and thus the same proteins.
    5. Averages and standard deviations of each region's intensities are
    then found and plotted.
    6. High quality tiff exports are then made of the images with legends and
    colorbars.

    Contact Info:
    amirz013@fiu.edu
    amirza.dev
%}
clear;clc;close all force
%% Load in Image Data
full_img_path=uipickfiles('Prompt','Select Original Full Image');
try
    [filepath,name,ext] = fileparts(full_img_path);
catch
    [filepath,name,ext] = fileparts(full_img_path{1});
end
% Check if any files are selected in the first place
if isempty(full_img_path) || length(full_img_path)==0%#ok<ISMT>
    error('No image selected.')
end

%% Read Image Data
% Read in full and segmented image
full_img=imread(full_img_path{1});

% Do image size checks
im_size=size(full_img);
if im_size(3)~= 3
    error('Image is not in color, thresholding code will not work.')
end

%% Remove Image Noise
% Ask user if they'd like to remove any image noise from original image
answer_denoising = questdlg('Would you like the original image to first be denoised?', ...
    'Denoising Prompt', ...
    'Yes','No','No');
% Handle response
switch answer_denoising
    case 'Yes' % If yes denoise image
        fprintf('...Denoising image... \n')
        noisyRGB=full_img;
        kernal=[5 5]; % Size of averaging kernal, 3x3 in this case, higher values indicates more smoothing
        % Split color img into RGB and run denoising algorithim on each
        [noisyR,noisyG,noisyB] = imsplit(noisyRGB);
        % 2 algorithims used, median filter and wiener
        % Median works by taking the median value around each pixel
        % according to kernal size. Pixel value is then replaced with
        % median.
        % Wiener works by taking the mean and standard deviation value
        % around each pixel according to kernal size. If pixel value is
        % outside of +/- standard deviation of mean value is replaced with
        % average.
        
        denoisedR = medfilt2(noisyR,kernal);
        denoisedG = medfilt2(noisyG,kernal);
        denoisedB = medfilt2(noisyB,kernal);
        denoisedRGB_Med = cat(3,denoisedR,denoisedG,denoisedB);
        
        denoisedR = wiener2(noisyR,kernal);
        denoisedG = wiener2(noisyG,kernal);
        denoisedB = wiener2(noisyB,kernal);
        denoisedRGB_Wiener = cat(3,denoisedR,denoisedG,denoisedB);
        
        % Ask user if they wish to plot original noisy image and each denoised version
        answer_plot = questdlg('Would you like to see the denoised results?', ...
            'Denoising Plot Prompt', ...
            'Yes','No','No');
        switch answer_plot
            case 'Yes' % If yes plot the results and wait for user to close window
                fig=figure;
                subplot_tight(1,3,1, [0.01 0.01])
                imshow(noisyRGB,[]);
                title('Noisy Original')
                subplot_tight(1,3,2, [0.01 0.01])
                imshow(denoisedRGB_Med,[]);
                title('Denoised - Median Filter')
                subplot_tight(1,3,3, [0.01 0.01])
                imshow(denoisedRGB_Wiener,[]);
                title('Denoised - Wiener Filter')
                linkaxes
                fprintf('Close plot to continue code. \n')
                uiwait(fig)
            case 'No'
                fprintf('Bypassing plotting, continuing code. \n') 
        end
        
        % Figure out which image has less noise and select that as the
        % image to use for later processing
        noisyPSNR_Med = psnr(noisyRGB,denoisedRGB_Med);
        noisyPSNR_Wiener = psnr(noisyRGB,denoisedRGB_Wiener);
        
        noisy_img_pick=[noisyPSNR_Med,noisyPSNR_Wiener];
        [~,I]=max(noisy_img_pick);
        
        if I==1
            processed_img=denoisedRGB_Med;
            fprintf('Median image chosen: larger peak signal-to-noise ratio (PSNR) \n')
        else
            processed_img=denoisedRGB_Wiener;
            fprintf('Wiener image chosen: larger peak signal-to-noise ratio (PSNR) \n')
        end
    case 'No' % If no was selected bypass denoising
        processed_img=full_img;
        fprintf('...Bypassing image denoising, continuing code... \n')
end
close all force
%% Segment Image and Ask User to Confirm
segmentation_result='No';
figure
% Ask user if segmentation was done correctly, if not keeping repeating
% until true
while strcmp(segmentation_result,'No')
    prompt = {'Enter number of suspected proteins:','Enter their names, darkest to lightest, space separated:'};
    dlgtitle = 'Segmentation Inputs';
    dims = [1 50];
    definput = {'3','Elastin Elastin/Mucin Mucin'};
    answer_denoising = inputdlg(prompt,dlgtitle,dims,definput);
    
    num_proteins=str2double(answer_denoising{1}); % Number of suspected proteins in image
    num_segments=num_proteins+1; % Number of actual segments that will be done, extra is the background
    
    % Specify the protein names, in order of darkest to lightest
    proteins_names=split(answer_denoising{2})';
    proteins_names{end+1}='Background'; % Add background to end of list
    
    nThresholds=num_proteins;
    img=processed_img;
    img=rgb2gray(img);
    % Run Otsu Multithresh Algorithim
    thresholds = multithresh(img, nThresholds);
    % Quantize image into bins based on results
    [quantizedImg, quantIndex] = imquantize(img, thresholds);
    % Convert quantization in proper image to view
    % quantizedImg_RGB = label2rgb(255*quantizedImg/num_segments);
    quantizedImg_to_view = 255*quantizedImg/num_segments;
    % Plot segmented image
    imagesc(quantizedImg_to_view)
    % Turn off x/y axis
    axis off
    % Adjust axis to account for image
    axis image
    % Set up tick values to be at center of colorbar
    c=colorbar;
    c.Ticks=linspace(min(c.Limits),max(c.Limits),num_segments);
    % Add on area percentages to colorbar legend
    c.TickLabels=proteins_names;
    colormap(jet(num_segments))
    % Pretty up graph
    c.FontName='Times';
    c.FontSize=20;
    c.FontWeight='bold';
    c.Label.String='Protein';
    % Enlarge figure
    g=gcf;
    g.Color='w';
    g.Position=[1,41,1920,963];
    
    segmentation_result = questdlg('Was the segmentation result correct? Meaning, do the colors for the proteins match the colorbar labels?', ...
        'Denoising Plot Prompt', ...
        'Yes','No','No');
    clf
end
close all force
%% Calculate Protein Amounts by Area
% Compute protein areas and relative tissue percentages
for ii=1:numel(unique(quantIndex))
    seg_name{ii}=proteins_names{ii};
    seg_area(ii)=bwarea(quantizedImg==ii);
    if ii==numel(unique(quantIndex))
        seg_area(ii)=bwarea(quantizedImg~=ii);
        seg_percentage=100*seg_area(1:end-1)./seg_area(end);
    end
end
% Report values and save for titles later
for ii=1:numel(unique(quantIndex))-1
    fprintf('Total %s Area is %3.2f%%\n',seg_name{ii},seg_percentage(ii))
    title_strs{ii}=sprintf('%s (%3.2f%%)',seg_name{ii},seg_percentage(ii));
end
%% Show Cell with Protein Calssified and Percentages by Area
figure
% Plot segmented image
imagesc(quantizedImg_to_view)
% Turn off x/y axis
axis off
% Adjust axis to account for image
axis image
% Set up tick values to be at center of colorbar
c=colorbar;
c.Ticks=linspace(min(c.Limits),max(c.Limits),num_segments);
% Add on area percentages to colorbar legend
c.TickLabels=[title_strs proteins_names{end}];
colormap(jet(num_segments))
% Pretty up graph
c.FontName='Times';
c.FontSize=20;
c.FontWeight='bold';
c.Label.String='Protein';
% Enlarge figure
g=gcf;
g.Color='w';
g.Position=[1,41,1920,963];
% Save image as high quality tiff
filename=[pwd '\' name '_Thresholding' '.png'];
print(gcf,filename,'-dpng','-r300')
% Close figure
close all force
%% Compute Each Protein's Average Intensity and Standard Deviation
for ii=1:numel(unique(quantIndex))-1
    mask=quantizedImg==ii;
    temp=im2double(rgb2gray(processed_img));
    temp=temp(mask);
    temp_mean=trimmean(temp,10);
    temp_std=std(temp);
    protein_means(ii)=temp_mean;
    protein_std(ii)=temp_std;
    fprintf('%s Intensity: %3.4f +/- %3.4f AU \n',proteins_names{ii},temp_mean,temp_std);
    title_strs{ii}=sprintf('%s Intensity: %3.4f +/- %3.4f AU \n',proteins_names{ii},temp_mean,temp_std);
end
%% Plot Average Intensity of Each Protein with Standard Deviation
figure
for ii=1:numel(unique(quantIndex))-1
    % Create mask based on each protein
    mask=quantizedImg==ii;
    % Plot original full image as background
    imshow(processed_img)
    
    % Add stats as x axis label
    xlabel(title_strs{ii})
    hold on
    
    h=imagesc(im2double(rgb2gray(processed_img)),'AlphaData',mask);
    % Turn off x/y axis
    axis off
    % Adjust axis to account for image
    axis image
    
    c=colorbar;
    % Make it look pretty
    c.FontName='Times';
    c.FontWeight='bold';
    c.FontSize=20;
    c.Label.String='Protein Expression';
    colormap jet(1024)
    shading interp
    caxis([0 1])
    
    f=gcf;
    f.Color='w';
%     f.Position=[1,41,1920,963];
    
    g=gca;
    g.FontName='Times New Roman';
    g.FontWeight='bold';
    g.FontSize=20;
    g.LineWidth=2;
    
    % Save image as high quality tiff
    filename=[name '_' proteins_names{ii} '_Intensity' '.png'];
    filename = replace(filename,'/','_');
    filename = [pwd '\' filename];
    print(gcf,filename,'-dpng','-r300')
    
    clf
end
close all force
%% Export CSV Table of Data
T=table(protein_means',protein_std');
T.Properties.VariableNames={'Mean','Standard Deviation'};
for ii=1:numel(proteins_names)-1
    T.Properties.RowNames(ii)=string(proteins_names{ii});
end
T.Properties.DimensionNames{1}=name;
table_name=[name '_' 'AvgStds' '.csv'];
writetable(T,table_name,'WriteRowNames',true)
fprintf('...Code finished... \n')