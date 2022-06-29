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


## [自定义PBR](https://github.com/corsair0909/-0-Shader/tree/main/Assets/PBR)    
<img width="1164" alt="截屏2022-06-28 20 47 26" src="https://user-images.githubusercontent.com/49482455/176182188-7def2ee4-7744-42dc-90dd-e442f212bd99.png">    
### PBR光照           
PBR光照模型需要满足如下三个条件


*1、基于微平面的表面模型*        

物体表面不存在完全光滑，微表面模型认为模型表面是由朝向各个方向的微小的镜平面组成，镜平面小到无法由像素区分。因此制定一个粗糙度（roughness）通过统计学的方法估算在给定方向上微表面的朝向。这个指定的方向就是观察方向V和光线方向L之间的半程向量（Halfwat Vector）h 。 h = normailze(viewDir + LightDir).

*2、能量守恒定律*     

即反射出的光能量不能大于入射光的能量。光线到达物体表面后一部分光线会进入物体内部，在物体内部的分子之间反射直到能量耗尽（转化为热能之类的能量转移）或再次到达表面被散射出去。

*3、应用基于物理的BDRF函数*

LearnOpenGL
> BRDF，或者说双向反射分布函数，它接受入射（光）方向ωi，出射（观察）方向ωo，平面法线n以及一个用来表示微平面粗糙程度的参数a作为函数的输入参数。BRDF可以近似的求出每束光线对一个给定了材质属性的平面上最终反射出来的光线所作出的贡献程度。    

> BRDF基于我们之前所探讨过的微平面理论来近似的求得材质的反射与折射属性。对于一个BRDF，为了实现物理学上的可信度，它必须遵守能量守恒定律，也就是说反射光线的总和永远不能超过入射光线的总量。严格上来说，同样采用ωi和ωo作为输入参数的 Blinn-Phong光照模型也被认为是一个BRDF。然而由于Blinn-Phong模型并没有遵循能量守恒定律，因此它不被认为是基于物理的渲染。现在已经有很好几种BRDF都能近似的得出物体表面对于光的反应，但是几乎所有实时渲染管线使用的都是一种被称为Cook-Torrance BRDF模型。    

也就是说基于物理的BRDF在以光入射方向和观察方向作为输入的同时还需要遵循能量守恒定律。    

#### Cook-Torrance.   
F = Kd * Lambert + Ks * Cook-Torrance.   
Kd kS为漫反射和镜面反射系数
本例子中lambert部分使用了Diseny BRDF中的漫反射部分，F90代表着将Roughness考虑到漫反射部分的计算，粗糙度越大看到的漫反射越多，强度越低，反之得到相反结果。     
#### IBL（Image Based Light）。    
IBL将场景看作一个整体光源，也就是间接光的模拟方法，这里是PBR区别于经验光照模型的核心部分。IBL也被分为漫反射部分和镜面反射部分。    
##### IBL_Diffuse    
球谐函数是间接光照计算的重要方式，以归一化的法线向量作为输入的出计算结果。本例中还有通过环境贴图采样的方式计算间接光漫反射颜色的方法。     
IBL部分的漫反射系数Kd是由NdotV向量根据能量守恒计算得出的，因为菲涅尔项与视角方向和法线方向的夹角有关。而直接光照部分的漫反射系数Kd是由VdotH向量计算的，因为微平面理论的存在使得法线分布函数D描述了微平面和半程向量的趋向。
##### IBL_Specular。   
<img width="576" alt="截屏2022-06-28 23 21 12" src="https://user-images.githubusercontent.com/49482455/176217533-95808b88-96d0-4f5f-a5a4-263b229a9767.png">
上图为Epic公司对这部分光照计算的简化结果，左侧部分可以看做天空盒采样的结果，右侧部分一般为一个定值，常规操作是使用LUT图    
LUT图的采样需要以NdotV为U方向，Roughness为V方向构成的二维坐标来采样。    
Unity对环境立方体题图（天空盒）积分运算得出模糊的全局光照贴图，使用一个环境光照贴图级数对立方体纹理采样，控制使用mipmap的层级，越大得到的结果越模糊。

### PBR光照结果分解          
Final = 直接光照结果+间接光照结果。两个光照结果可再分为漫反射结果和镜面反射结果        
### 参考链接。    
https://www.cnblogs.com/anesu/p/15786470.html#/c/subject/p/15786470.html    
https://zhuanlan.zhihu.com/p/407007915    
https://zhuanlan.zhihu.com/p/57771965    
https://github.com/csdjk/LearnUnityShader/blob/master/Assets/Scenes/PBR/PBR_Custom/PBR_Custom.shader     
https://blog.csdn.net/weixin_42825810/article/details/103761869     
https://learnopengl-cn.github.io/07%20PBR/02%20Lighting/    

https://www.iflyrec.com/views/html/editor.html?id=PWmz2206281739A054F3D500008&audios=127173364     

