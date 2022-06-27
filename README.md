# 从0开始的着色器生活
![69460492_p0_master1200](https://user-images.githubusercontent.com/49482455/171035627-fd5fb592-5d83-4c71-b802-9ca5123888d4.jpg)

## [billboard](https://github.com/corsair0909/-0-Shader/tree/main/Assets/BillBoard)
![QQ20220613-174417-HD](https://user-images.githubusercontent.com/49482455/173327281-75f4e81c-7367-42ff-9e67-595a5deb2b4b.gif)
### 实现思路    
构建新的旋转矩阵，使用旋转矩阵旋转被着色的物体。旋转矩阵的需要3个基向量，分别是表面法线方向（normal），向上的方向（up），向右的方向（right），还需要一个位置不变的锚点，用于确定在旋转时的位置。通常是通过计算得出表面法线方向和向上方向，但二者有时并不是正交的，可以固定二者其一，通过差积得出新的向量构成旋转矩阵。right = up X normal , up1 = right X normal。    
根据原始位置相对于锚点的偏移量以及旋转矩阵计算新的顶点位置，最后将新的顶点位置转换到裁剪空间下。    
片元着色器中返回贴图采样结果即可。

<img width="1202" alt="截屏2022-06-13 18 03 31" src="https://user-images.githubusercontent.com/49482455/173331009-e8fe6b02-7c39-4567-9ec0-8af5707ad975.png">

## [玻璃(水晶材质)](https://github.com/corsair0909/-0-Shader/tree/main/Assets/Glass)
<img width="1180" alt="截屏2022-06-14 23 55 20" src="https://user-images.githubusercontent.com/49482455/173622143-3b95bc4b-7118-4a0e-b5fc-3b7c381f7974.png">.      
### 实现思路        
玻璃1：用反射方向和折射方向分别对天空盒CubeMap采样，计算菲涅尔参数，使用其在两个采样结果之间插值过度.       
玻璃2：设置为透明渲染队列。对法线贴图进行扭曲，使用grabpass抓取当前相机的图像用屏幕坐标采样。根据扭曲的法线计算反射方向并采样cubemap。在两个采样结果之间插值.    
玻璃3：原理与玻璃1相同.    
> 玻璃1、3使用的菲涅尔计算公式： float fresnel = max(0, min(1, _FresnelBias + _FresnelScale * pow(min(0.0, 1.0 - dot(I, N)), _FresnelPower)));   
### 参考链接。       
[反射方向计算公式推导](https://blog.csdn.net/yinhun2012/article/details/79466517 ).      
[折射方向计算公式](https://blog.csdn.net/rickshaozhiheng/article/details/51596595 ).     
[Shader入门精要的实现方法](https://www.cnblogs.com/koshio0219/p/11114659.html)

## [消融](https://github.com/corsair0909/-0-Shader/tree/main/Assets/Disslove).    
Clip函数剔除小于阈值的像素.       
![QQ20220614-232012-HD](https://user-images.githubusercontent.com/49482455/173624535-bb5ac904-09e7-4a99-810f-09790dc8e652.gif)
### 定向消融     
首先需要设置锚点并计算世界空间下顶点位置到锚点的向量。求出该向量在指定的消融方向上的投影，并将其应用在disslove值的计算上.    
### 参考链接。   
[定向消融、向心消融](https://zhuanlan.zhihu.com/p/321338977)

## [序列帧动画](https://github.com/corsair0909/-0-Shader/tree/main/Assets/SequeneAnim).    
![QQ20220620-113559-HD](https://user-images.githubusercontent.com/49482455/175051202-3204b1b9-6315-4a6b-ad54-61636e3b4543.gif).     
### 实现
#### 行列数计算
行数 = time/HorizontalCount。  
列数 = time - 行数 * HorizontalCount    
#### 缩放UV    
序列帧图片包含多张关键帧，需要把采样坐标映射到每个关键帧图像范围内。（可以理解为只显示一张关键帧的大小）     
注意：序列帧的播放顺序为从上到下，而uv竖直方向的顺序为从下到上，因此竖直方向上为减去偏移量。    
