function [ out ] = focal_stacking( fPath )
% fPath = the input folder contains images (jpg) to be merged
% will apply wildcard * to include all images under the spcified folder

% CONST parameters:
    
avgFilterSize = 60;

    inputFiles = dir(strcat(fPath, './*.jpg'));
    % for Windows environment, use below:
    % inputFiles = dir(strcat(fPath, '.\*.jpg'));
    % Be sure to replace all the "/" with "\" in this code

    % create variables
    numImgs = length(inputFiles);
    imgIn = cell(1, numImgs);
    imgIn2Gray = cell(1, numImgs);
    imgLa = cell(1, numImgs);

    % create Laplacian filter using "fspecial" from MATLAB
    h = fspecial('laplacian');

    % create average filter to smooth the Laplacian results
    g = fspecial('average', [avgFilterSize, avgFilterSize]);

    % take first image as a sample to determine size
    imgName = inputFiles(1).name;
    imgInSample = imread(strcat(fPath, '/', imgName));
    [m,n,d] = size(imgInSample);

    % sum of laplacian
    % create an empty matrix of the same size of the images
    LaImgTotal = double(zeros(m, n));
    % for loop to add up one by one
    for i=1:1:numImgs
        imgName = inputFiles(i).name;
        imgIn{i} = imread(strcat(fPath, '/', imgName));
        imgIn2Gray{i} = rgb2gray(imgIn{i});

        % apply laplacian
        imgLa{i} = abs(imfilter(imgIn2Gray{i}, h)); % 'replicate', 'same'));

        tmpImgLa = imgLa{i};
        tmpImgLa(tmpImgLa < 20) = 0;
        LaImgTotal = LaImgTotal + double(tmpImgLa);
        
        % not yet applied average filter
        % figure, imshow(imgLa{i}, []);

        
        % apply average filter
        imgLa{i} = imfilter(double(imgLa{i}), double(g)); % 'replicate', 'same');
        %imgLa{i} = medfilt2(imgLa{i}, [10, 10]);
        imgLa{i}(imgLa{i}<=0) = eps;
        % Show blurred Laplace results of each image
        figure, imshow(imgLa{i}, []);
        % imwrite(imgLa{i}, strcat(fPath,'/output_JPG/LaplacianBlurred',i,'Size',fltrSize,'.png'), 'png');
    end
    % figure, imshow(uint8(LaImgTotal));
    save('totalLap', 'LaImgTotal');

    % assign the corresponding pixel with the highest Lapacian value
    Map = uint16(zeros(m, n));
    for i=1:1:m
        for j=1:1:n
            selectedImage = 1;
            maxLap = imgLa{selectedImage}(i, j);
            for k = 1 + 1:1:numImgs
                if (imgLa{k}(i, j) > maxLap)
                    maxLap = imgLa{k}(i, j);
                    selectedImage = k;
                end
            end
            out(i, j, :) = imgIn{selectedImage}(i, j, :);
            Map(i, j) = selectedImage;
        end
    end
    laRes = abs(imfilter(rgb2gray(out), h, 'replicate', 'same'));
    laErr = uint8(laRes) - uint8(LaImgTotal);
    laErr(laErr < 0) = 0;
    % smoothed laplacian only
    figure, imshow(out);
    % imwrite(out, strcat(fPath,'/output_JPG/OutputSize',fltrSize,'.png'), 'png');
    % figure, imshow(laErr);
    figure, imshow(Map, []);
    % imwrite(Map, strcat(fPath,'/output_JPG/MapSize',fltrSize,'.png'), 'png');
    end

