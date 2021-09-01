# Protein Heat Map 

## This code was made to work with MATLAB R2021a and requires the Image Processing Toolbox to work properly.

## What are Heat Map?

If you look in literature regarding protein staining and their depictions you will find colorful images showing results for popular stains such as DAPI, which binds to DNA and shows cell nuclei, or carmine, which binds to glycogen. One popular staining protcol used in the cardiac field is the Movat's pentachrome stain whcich stains for elastin, colalgen, mucin, fibrin, and muscle. 

This code was developed to automatically segment images that were stained using a method as stated above, but meant for Movats, and then plot the intensity of each protein using a colormap (Heat Map). Information regarding the percentage of area covered by each protein and their relative statistics is also given. Images are saved as high quality PNGs and data is saved as a small CSV file.

### More information regarding immunostaining can be found in the reference given below.

1. [Alturkistani, Hani A et al. “Histological Stains: A Literature Review and Case Study.” Global journal of health science vol. 8,3 72-9. 25 Jun. 2015, doi:10.5539/gjhs.v8n3p72](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4804027/)

## What does this code do?

Given an input stained image (assumed to be in color) the code will attempt to segment it into a given number of proteins and label them as such. Heat maps are then generated and saved as PNG files alongside statistics in a CSV.

### Original
<a href="url"><img src="https://github.com/DThornz/Protein-Heat-Map-/blob/main/E_2movats_outer_x20_1_FullImg.png" align="center" width="778.8" height="503.2" ></a>


### Segmented with Area Percentages
<a href="url"><img src="https://github.com/DThornz/Protein-Heat-Map-/blob/main/Example%20Results/E_2movats_outer_x20_1_FullImg_Thresholding.png" align="center" height="505" width="952.6" ></a>


### Elastin Intesity Heat Map
<a href="url"><img src="https://github.com/DThornz/Protein-Heat-Map-/blob/main/Example%20Results/E_2movats_outer_x20_1_FullImg_Elastin_Intensity.png" align="center" width="778.8" height="503.2" ></a>


## How does it do it?

Given a starting image there are a number of image processing steps done:

1. Image denoising (medfilt2/wiener2)
2. Image thresholding (multithresh)
3. Image quantization (imquantize)
4. Area calculations (bwarea)
5. Intensity mean/standard deviation calculation (mean2/std2)

[Details on the mathematics and usage of each step can be found in the MATLAB documentation.](https://www.mathworks.com/help/images/)

[Feel free to fork this on GitHub](https://github.com/DThornz/Protein-Heat-Map-/fork)


