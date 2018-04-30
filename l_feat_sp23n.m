function [labels,modes,z,mu] = l_feat_sp23n(img, data)
%vectors: 1,2,3-average lab color; 4:homomorphic 5:n-bright 6:n-skew 7:n-sat
%8,9,10:self-bright/skew/sat 11:n-homo
%imgr: ground truth if not empty

img = imguidedfilter(img);
img = double(img);

[h w d] = size(img);

data=double(data);
un = unique(data);
N = length(un);
labels = data;
for i=N:-1:1
    if (un(i)==i) break; end
    labels(data==un(i))=i;
end
%labels = reshape(data,w,h)';

% imshow(labels/max(l));
% [fimage labels modes regSize grad conf] = edison_wrapper(img, @rgb2Lab);
% lab_seg=fimage(:,:,1);
% labels = labels+1;
% 
yuv = rgb2yuv(img);
hsi = rgb2hsi(img);

Y = yuv(:,:,1);
U = yuv(:,:,2);
V = yuv(:,:,3);
S = hsi(:,:,2);
R = img(:,:,1);
G = img(:,:,2);
B = img(:,:,3);
S(Y<2) = 1;
clear yuv;
clear hsi;

N = max(max(labels));

z = zeros(N,23);


%% self features
img_homo = zeros(h,w);
imgh = h_homof(img);
vh = zeros(N,1);
for i=1:N
    v = Y(labels==i);
    r = R(labels==i); r=sort(r);
    g = G(labels==i); g=sort(g);
    b = B(labels==i); b=sort(b);
    n = round(0.95*sum(sum(labels==i)));
    z(i,6) = max([r(n) g(n) b(n)]);
    z(i,1) = mean(v);
    z(i,5) = skewness(v);
    z(i,2) = mean(U(labels==i));
    z(i,3) = mean(V(labels==i));
    vs = S(labels==i);
    z(i,7) = mean(vs);
    vh(i) = mean(imgh(labels==i));
end
modes = z(:,1:3);

%% GMM regression

homo = reshape(imgh,[],1);
GM = fitgmdist(homo,2);
if (GM.mu(1,1)<=GM.mu(2,1)) i=1; else i=2; end
% sig = GM.Sigma;
% if (sig(1)<100) sig(1)=100; end
% if (sig(2)<100) sig(2)=100; end
% GM.Sigma = sig;
GM.mu
P = posterior(GM,vh);
P = P(:,3-i);
z(:,4) = P;
mu = GM.mu;

for i=1:N
    img_homo(labels==i) = z(i,4);
end

% P = posterior(GM,reshape(lab_seg,[],1));
% P = P(:,3-i);
% img_homo = reshape(P,h,w);
% figure; imshow(img_homo);
% 
%% neighborhood
for i=1:N
    reg = double(labels==i);
    r0 = sqrt(sum(sum(reg)));
    for k=1:4
        nsize = ceil(0.5*k*r0);
        se = strel('disk',nsize);
        nreg = imdilate(reg,se) - reg;
        vn = Y(nreg>0);
        r = R(nreg>0); r=sort(r);
        g = G(nreg>0); g=sort(g);
        b = B(nreg>0); b=sort(b);
        n = round(0.95*sum(sum(nreg>0)));
        z(i,4*k+6) = max([r(n) g(n) b(n)]);
        z(i,4*k+5) = skewness(vn);
%         z(i,4*k+6) = max(vn);
        vs = S(nreg>0);
        z(i,4*k+7) = mean(vs);
        vh = img_homo(nreg>0);
        z(i,4*k+4) = mean(vh);
    end
end

z(isnan(z))=0;

% % for i=1:w*h
% %     for k=1:3
% %         img_sr(i,k) = c(labels(i),k);
% %     end
% %     img_b(i) = bright(labels(i));
% %     img_sk(i) = sk(labels(i));
% %     img_sat(i) = sat(labels(i));
% %     img_nb(i) = nbright(labels(i));
% %     img_nsk(i) = nsk(labels(i));
% %     img_nsat(i) = nsat(labels(i));
% % end
% % img_sk = (img_sk-min(img_sk))/(max(img_sk)-min(img_sk));
% % img_nsk = (img_nsk-min(img_nsk))/(max(img_nsk)-min(img_nsk));
% % img_sr = reshape(img_sr,[h w 3]);
% % img_b = reshape(img_b,[h w])/255;
% % img_sk = reshape(img_sk,[h w]);
% % img_sat = reshape(img_sat,[h w]);
% % img_nb = reshape(img_nb,[h w])/255;
% % img_nsk = reshape(img_nsk,[h w]);
% % img_nsat = reshape(img_nsat,[h w]);
% % 
% % %% figure
% % figure;hold on;
% % subplot(331);imshow(img);title('input');
% % subplot(332);imshow(img_sr);title('seg');
% % subplot(333);imshow(img_homo);title('homomorphic');
% % subplot(334);imshow(img_b);title('bright');
% % subplot(335);imshow(img_sk);title('skewness');
% % subplot(336);imshow(img_sat);title('sat');
% % subplot(337);imshow(img_nb);title('bright(N)');
% % subplot(338);imshow(img_nsk);title('skewness(N)');
% % subplot(339);imshow(img_nsat);title('sat(N)');
