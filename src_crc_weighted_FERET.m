% optimized_sc_ttls.m
% Optimized Sparse Coding with Truncated Total Least Square (T-TLS)

clear all;

%addpath 'src_solution';

% ���ò���       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% miu=1.0e-3;
% defined_number=50; 
% lambdas=10.^[-3:3]; % ��
% sigmas=10.^[-3:3];  % ��

% ���ò�����     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numOfDb = 6;

% ���β���ָ�������ݿ�    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii=1:numOfDb
    % �����������ѡ����ĳһ���⣬    
    single = 1;  % ע�͵�������Ϊ0����������еĿ⡣
    if single > 0 % >0��ʾֻ��һ����
        ii = single
    end
    switch (ii)  
        case 1 % ���� FERET ���ݿ�   
            dbName = 'FERET';   
            % ����·��
            pathPrefix='../datasets/feret/';
            firstSample=imread('../datasets/feret/1.tif');
            [row col]=size(firstSample);
            % ���ò��Կ���Ϣ
            numOfSamples=7;
            numOfClasses=200;
        case 2 % ���� GT ���ݿ�
            dbName = 'GT';
            pathPrefix='../datasets/Georgia Tech face database crop/';
            firstSample=imread('../datasets/Georgia Tech face database crop/1_1.jpg');
            %[size_a size_b size_c]=size(firstSample);
            [row col]=size(rgb2gray(firstSample));
            numOfSamples=15;
            numOfClasses=50;
        case 3 % ���� ORL ���ݿ�            
            dbName = 'ORL';
            pathPrefix='orl/orl';
            firstSample=imread('orl/orl001.bmp');
            [row col]=size(firstSample);
            numOfSamples=10;
            numOfClasses=40; 
        case 4 % ���� LFW ���ݿ�            
            dbName = 'LFW';
            scale = 0.3;
            pathPrefix='../datasets/lfw-deepfunneled/';
            firstSample=imread('../facedatabases/lfw-deepfunneled/Aaron_Eckhart/Aaron_Eckhart_0001.jpg');
            halfSample =imresize(firstSample,scale); % ѹ����С
            [row col]=size(rgb2gray(halfSample));
            numOfSamples=5; % ȡ��5�������Ķ���
            numOfClasses=0; % ���������Ҫͳ��
            indiesOfClasses = []; % ��¼����λ��
            % ������5������������
            fileID = fopen('../facedatabases/lfw-names.txt');
            namesAndImages = textscan(fileID,'%s %d');
            fclose(fileID);
            names = namesAndImages{1,1};
            nums = namesAndImages{1,2};
            [nRow, nCol] = size(names);
            for jj=1:nRow % ������������
                numOfImages = nums(jj);
                if numOfImages >= numOfSamples  % ���������㹻
                    numOfClasses = numOfClasses + 1;
                    indiesOfClasses(numOfClasses)=jj;
                end 
            end
        case 5 % ���� COIL ���ݿ�            
            dbName = 'COIL';
            pathPrefix='../datasets/coil-20-proc/';
            firstSample=imread('../datasets/coil-20-proc/obj1__0.png');
            [row col]=size(firstSample);
            numOfSamples=72;
            numOfClasses=20; 
        case 6 % ���� Senthil IRTT ���ݿ�            
            dbName = 'Senthil_IRTT';
            pathPrefix='../datasets/Senthil_IRTT_FaceDatabase_Version1.2/';
            firstSample=imread('../datasets/Senthil_IRTT_FaceDatabase_Version1.2/s1_1.jpg');
            [row col]=size(firstSample);
            numOfSamples=10;
            numOfClasses=10; 
        otherwise
            % disp('δ֪���ݿ⣡');
    end
    % �������ݿ�
    clear inputData;
    for cc=1:numOfClasses       
        for ss=1:numOfSamples
            switch (ii)
                case 1 % FERET
                    path=[pathPrefix num2str((cc-1)*numOfSamples+ss,'%d') '.tif'];
                    inputData(cc,ss,:,:)=imread(path);
                case 2 % GT
                    path=[pathPrefix int2str(cc) '_' int2str(ss) '.jpg'];
                    colored=imread(path);
                    grayed=double(rgb2gray(colored));
                    inputData(cc,ss,:,:)= grayed(:,:);
                case 3 % ORL
                    path=[pathPrefix num2str((cc-1)*numOfSamples+ss,'%03d') '.bmp'];
                    inputData(cc,ss,:,:)=imread(path);
                case 4 % LFW
                    indexOfClass = indiesOfClasses(cc); %disp(indexOfClass);
                    %path=[pathPrefix names(indexOfClass) '/' names(indexOfClass) '_' num2str(ss, '%04d') '.jpg'];
                    path=strcat(pathPrefix,names(indexOfClass),'/',names(indexOfClass),'_',num2str(ss, '%04d'),'.jpg');
                    colored=imread(path{1});
                    grayed=double(rgb2gray(colored)); 
                    inputData(cc,ss,:,:)= imresize(grayed(:,:),scale); % ѹ����С
                case 5 % COIL
                    path=[pathPrefix 'obj' num2str(cc, '%d') '__' num2str(ss-1, '%d') '.png'];
                    inputData(cc,ss,:,:)=imread(path);
                case 6 % Senthil IRTT
                    path=[pathPrefix 's' num2str(cc, '%d') '_' num2str(ss, '%d') '.jpg'];
                    inputData(cc,ss,:,:)=imread(path);
                otherwise
                    % do nothing
            end
        end
    end
    inputData=double(inputData);
    
    % �ܲ�ͬ��ѵ������
    minTrains = 1; 
    maxTrains = floor(numOfSamples*0.8);
    %maxTrains = 2;
    clear trainData;
    clear testData;
    % Weights for addition
    a = 300;
    b = 1;
    for numOfTrain=minTrains:maxTrains
        % ����������
        numOfTest = numOfSamples-numOfTrain; 
        fprintf('ѵ������=%d��\t��������=%d��\t�� %d �����\n', numOfTrain, numOfTest, numOfClasses);
        
        % ȡ����Ӧԭʼѵ�����Ͳ��Լ�
        for cc=1:numOfClasses
            clear Ai;
            for tt=1:numOfTrain
                Ai(1,:)=inputData(cc,tt,:); % A(i)
                trainData((cc-1)*numOfTrain+tt,:)=Ai/norm(Ai);
            end
        end
        for cc=1:numOfClasses
            clear Xi;
            for tt=1:numOfTest
                Xi(1,:)=inputData(cc,tt+numOfTrain,:); % X(i)
                testData((cc-1)*numOfTest+tt,:)=Xi/norm(Xi);
            end
        end
        
        % ʵ�ָ��ֱ�ʾ����
        numOfAllTrains=numOfClasses*numOfTrain; % ѵ������
        numOfAllTests=numOfClasses*numOfTest;   % ��������
        clear usefulTrain;
        usefulTrain=trainData;
        clear preserved;
        % (T*T'+aU)-1 * T
        preserved=inv(usefulTrain*usefulTrain'+0.01*eye(numOfAllTrains))*usefulTrain;
        % �����ֲ��������ı�ʾϵ��
        clear testSample;
        %clear solutionSRC;
        %clear solutionCRC;
        %clear solutionTTLS;
        for kk=1:numOfAllTests
            testSample=testData(kk,:);            
            % CRC �⣺(T*T'+aU)^-1 * T * D(i)'
            solutionCRC=preserved*testSample';
            % ��ӡ����
            fprintf('%d ', kk);
            if mod(kk,20)==0
                fprintf('\n');
            end
            % SRC ��
            [solutionSRC, total_iter] =    SolveFISTA(usefulTrain',testSample');
            % ���㹱��ֵ
            clear contributionCRC;
            clear contributionSRC;
            clear contributionPlus;  
            for cc=1:numOfClasses
                contributionCRC(:,cc)=zeros(row*col,1);
                contributionSRC(:,cc)=zeros(row*col,1);
                
                contributionPlus(:,cc)=zeros(row*col,1); % Plus
                
                for tt=1:numOfTrain
                    % C(i) = sum(S(i)*T)
                    contributionSRC(:,cc)=contributionSRC(:,cc)+solutionSRC((cc-1)*numOfTrain+tt)*usefulTrain((cc-1)*numOfTrain+tt,:)';                    
                    contributionCRC(:,cc)=contributionCRC(:,cc)+solutionCRC((cc-1)*numOfTrain+tt)*usefulTrain((cc-1)*numOfTrain+tt,:)';  
                    % Plus
                    contributionPlus(:,cc)=contributionPlus(:,cc)+(a*solutionSRC((cc-1)*numOfTrain+tt)+b*solutionCRC((cc-1)*numOfTrain+tt))*usefulTrain((cc-1)*numOfTrain+tt,:)';
                end
            end
            % �������|�в�|����
            clear deviationSRC;
            clear deviationCRC;
            clear deviationPlus;
            for cc=1:numOfClasses
                % r(i) = |D(i)-C(i)|
                deviationSRC(cc)=norm(testSample'-contributionSRC(:,cc));                   
                deviationCRC(cc)=norm(testSample'-contributionCRC(:,cc));  
                % Plus
                deviationPlus(cc)=norm(testSample'-contributionPlus(:,cc)/(a+b));
            end
            % ʶ����
            [min_value xxSRC]=min(deviationSRC);
            labelSRC(kk)=xxSRC;
            [min_value xxCRC]=min(deviationCRC);
            labelCRC(kk)=xxCRC;
            [min_value xxPlus]=min(deviationPlus);
            labelPlus(kk)=xxPlus;
        end
        
        % ͳ��ʶ�������
        errorsSRC=0; errorsCRC=0; errorsPlus=0;   
        
        for kk=1:numOfAllTests
            inte=floor((kk-1)/numOfTest+1);
            dataLabel(kk)=inte;
            
            if labelSRC(kk)~=dataLabel(kk)
                errorsSRC=errorsSRC+1;
            end
            if labelCRC(kk)~=dataLabel(kk)
                errorsCRC=errorsCRC+1;
            end
            
            if labelPlus(kk)~=dataLabel(kk)
                errorsPlus=errorsPlus+1;
            end
        end
        
        % ͳ�ƴ�����
        errorsRatioSRC=errorsSRC/numOfClasses/numOfTest
        errorsRatioCRC=errorsCRC/numOfClasses/numOfTest
        errorsRatioPlus=errorsPlus/numOfClasses/numOfTest
        
        % ������
        result(numOfTrain, 1)=errorsRatioSRC;
        result(numOfTrain, 2)=errorsRatioCRC;
        result(numOfTrain, 3)=errorsRatioPlus;
    end
        
    % ���һ����Ĳ��ԣ�������
    jsonFile = [dbName '_plus.json'];
    dbJson = savejson('', result, jsonFile);
    %data=loadjson(jsonFile);
    %result_json = data[db_name];
    if single>0
        break; % ֻ��һ����
    end
end

disp('Test done!');

