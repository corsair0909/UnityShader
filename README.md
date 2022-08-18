# 从0开始的着色器生活

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

## [视差映射(Parallax Mapping)](https://github.com/corsair0909/-0-Shader/tree/main/Assets/Parallax)    
为了赋予模型表面遮挡关系的细节。引入了一张高度图    
可以和法线贴图一起使用，来产生一些真实的效果    
高度图一般视为顶点位移来使用，此时需要三角形足够多，模型足够精细，否则看起来会有块状    
如果在有限的三角形面的情况下，怎么办？这就用到了视差映射技术    

核心技术：一张存储模型信息的高度图，利用模型表面高度信息来对纹理进行偏移（低位置的信息被高位置的信息遮挡掉了，所以会采样更高的信息）。

### 普通视差映射算法
*下面几个例子分别是在普通视差映射算法、陡峭视差映射算法、浮雕映射算法下的对比*
<img width="709" alt="截屏2022-06-30 23 01 23" src="https://user-images.githubusercontent.com/49482455/176710901-7c8931d7-9017-4e2c-b440-6413799adde5.png">    
### 陡峭视差映射算法.     
<img width="604" alt="截屏2022-06-30 23 04 06" src="https://user-images.githubusercontent.com/49482455/176711353-5baf41af-ee41-46c8-b878-5f22d049e4ca.png">
陡峭视差映射因为其分层采样深度的算法能看到在高度变化剧烈的地方产生分层，但得到的效果更好。    


### 浮雕映射算法    
下图是浮雕映射算法在分层100层后得到的结果


<img width="604" alt="截屏2022-06-30 23 07 06" src="https://user-images.githubusercontent.com/49482455/176712084-064f5a81-fe66-46cb-802b-1d3d16541503.png">


<img width="604" alt="截屏2022-06-30 23 07 06" src="https://user-images.githubusercontent.com/49482455/176712084-064f5a81-fe66-46cb-802b-1d3d16541503.png">

### [浮雕映射算法（Parallax Occulotion Mapping POM)视差云应用](https://github.com/corsair0909/-0-Shader/tree/main/Assets/Shader/Parallax/pom_Cloud)
![Could](https://user-images.githubusercontent.com/49482455/178109629-561ed1e1-a73f-4551-9fd1-84052a54f877.gif)
#### 参考链接


[Unity Shader基于视差映射的云海效果](https://zhuanlan.zhihu.com/p/83355147)


[百人计划先行版笔记1（视差体积云）](https://zhuanlan.zhihu.com/p/445385622)


## [模版测试](https://github.com/corsair0909/-0-Shader/tree/main/Assets/Shader/StencilTest)

· Ref：要比较的参考值和要写入缓冲区的值 0-255之间的整数     
· ReadMask：用于比较参考值和缓冲区中的内容 8为掩码     
· WriteMask：指定写操作将会影响模版缓冲区的那些位置     
· Comp：比较函数，枚举类型，默认 Always         
· Pass：模版测试和深度测试都通过，如何处理缓冲区中的内容 默认Keep。      
· Fail：两测试未通过如何处理，默认Keep     
· ZFail：模版测试通过但深度测试失败，如何处理，默认Keep。   

![QQ20220709-220123-HD](https://user-images.githubusercontent.com/49482455/178109912-a508f632-ec54-4a66-ac34-b3eadd7a3654.gif)


### 参考链接
[https://zhuanlan.zhihu.com/p/384529130](https://zhuanlan.zhihu.com/p/384529130)



[LearnOpenGL](https://learnopengl-cn.github.io/04%20Advanced%20OpenGL/02%20Stencil%20testing/)



[Unity Shader 模板测试（Stencil）](https://zhuanlan.zhihu.com/p/388735435)

## [卡通渲染(NPR)](https://github.com/corsair0909/UnityShader/tree/main/Assets/Shader/NPR).    
<img width="1153" alt="截屏2022-07-11 21 53 32" src="https://user-images.githubusercontent.com/49482455/178281487-f8be6df2-68db-4432-98f4-07a7faef7f1e.png">

### 实现思路    
#### 描边     
顶点沿法线方向外扩，并剔除正面得到描边（Bakc Faceing）
##### 1、法线方向   
描边相对于世界空间下不变，相机距离越近描边会变得越粗，将外扩的大小调整到NDC空间下消除影响
UNITY_MATRIX_IT_MV 矩阵用于变化法线，将法线变换到View空间。    
TransformViewToProjection（）方法将法线向量变换到投影空间。管线会自动进行透视除法（除以w分量），为了得到不受透视除法影响的法线向量，在变换到投影空间下后与w分量相乘用来抵消透视除法带来影响。
##### 2、屏幕宽高比    
NDC空间下的xy范围为[0-1],无法直接适配到16:9屏幕宽高比中，轮廓线的水平方向会变粗，所以需要重新计算屏幕宽高比     
aspect = _ScreenParams.y/_ScreenParams.x；   
##### 3、平均法线  
MeshFilter组件包含了对网格的引用，MeshRender组件渲染MeshFilter组件引用的网格。 MeshFilter.Mesh属性包含了引用的网格的顶点中的数据，顶点数据类型为Vector3类型。通过字典数据结构保存每个顶点和顶点对应的法线，将共用顶点的法线进行Normalized。    
[MeshFilter Unity手册](https://docs.unity.cn/cn/2020.3/ScriptReference/30_search.html?q=MeshFilter).   
[Unity 平均法线工具](https://zhuanlan.zhihu.com/p/109101851)
##### 4、Perlin Noise 不规则法线       
Perlin Noise生成算法得到随机大小，记得使用NDC坐标（乘以变换后顶点的w分量）
#### 光照计算。  
##### 1、Ramp（渐变贴图采样）。   
tex2D(_RampTex,float2(NdotL,0.5f))    
##### 2、边缘光。   
边缘光是以视线（V）向量和法线（N）向量的点积，视线和法线的夹角越大边缘光越亮。1减去点击部分得到剩余的部分。
##### 3、二分色 ：二分色可以用来表示卡通渲染中皮革、漆面产生的另外的颜色部分    
在高光公式的计算中将NdotH改为VdotN，大于阈值的部分在对高光颜色提亮（乘以指定的数乘）    
##### 4、SDF面部阴影。   
SDF面部阴影贴图中有光照的部分只有一侧，当光照方向转动到另一侧时需要反转uv的水平方向再次采样视线阴影平滑过渡。
指定觉得的正前方和侧方向量，正前方与光照方向的夹角表示光照结果的阈值，点积结果需要映射到[0,1]范围内。    
侧方向和灯光方向的夹角的正负决定使用那一侧的光照方向。   
isShadow：step函数将光照计算结果限制在一侧的阴影中    
Bias：光照结果和阴影结果的差做smoothness平滑过渡。   
阴影和非阴影部分的过渡使用，根据bias的结果在有光照和无光照的面部颜色之间插值过渡

### 参考链接。    
[从零开始的卡通渲染](https://zhuanlan.zhihu.com/p/109101851).     
[卡通渲染基本光照模型的实现](https://zhuanlan.zhihu.com/p/95986273).         
[原神Shader渲染还原解析](https://zhuanlan.zhihu.com/p/435005339).      
[Unity着色器《原神》面部平滑阴影解决思路](https://zhuanlan.zhihu.com/p/402037562).     
[原神角色渲染Shader分析还原](https://zhuanlan.zhihu.com/p/360229590).       
[神作面部阴影渲染还原](https://zhuanlan.zhihu.com/p/279334552).      
[二次元角色卡通渲染—面部篇](https://zhuanlan.zhihu.com/p/411188212).    

## [FlowMap水面](https://github.com/corsair0909/UnityShader/tree/main/Assets/Shader/FlowMap).    
![QQ20220716-152941-HD](https://user-images.githubusercontent.com/49482455/179894389-1a087dae-677a-4bf0-917f-6002c8bf238f.gif)
### FlowMap    
FlowMap中的每个像素保存着一个向量，指向当前像素该运动到的方向，向量值域[0-1]需要映射到颜色值域[-1,1].     
FlowMap采样周期函数，通过FlowMap贴图对UV偏移量构造相差半个周期的函数来避免扰动uv时出现的断层情况        
根据水面深度和水下深度的差计算水面边缘、水下能见度模拟。    
使用法线贴图对水下物体进行折射扭曲，水下深度-表面深度<0说明在水面上方，不需要发生折射。    
### 参考链接    
[Unity 水、流体、波纹基础系列](https://mp.weixin.qq.com/s/k8kPxMc8uB3T7eCYsdopGg)    
[Toon Water Shader](https://roystan.net/articles/toon-water.html)    
[UnityShader·水面](https://zhuanlan.zhihu.com/p/144818695)     

## [Dota2角色](https://github.com/corsair0909/UnityShader/tree/main/Assets/Shader/Dota2).    
<img width="1285" alt="截屏2022-07-17 01 46 20" src="https://user-images.githubusercontent.com/49482455/179896446-59f3a5e3-17d9-4722-bf80-7f4ada3610d3.png">    
Dota2角色中使用非常多的遮罩贴图，此处不一一说明，参考链接中有多各个贴图的详细介绍   


### 参考链接
[Dota2角色渲染，用unity重现其shader](https://zhuanlan.zhihu.com/p/267361085).       
[Mask的艺术 – 近似PBR的Dota2角色渲染](https://zhuanlan.zhihu.com/p/27254617)      
[在Unity中复刻基于PBS的Dota2着色器](http://gypsumlabs.github.io/2017/03/28/unity-dota2-shader/)    
[Steam创意工坊](https://help.steampowered.com/zh-cn/faqs/view/299C-D7F9-09A5-98B6#source1).     
[庄懂ap-12](https://www.bilibili.com/video/BV1DQ4y1P7wG?spm_id_from=333.999.0.0)。    

## [水墨画模仿（简易版）](https://github.com/corsair0909/UnityShader/tree/main/Assets/Shader/WashPainting).   
<img width="1285" alt="截屏2022-07-17 15 59 31" src="https://user-images.githubusercontent.com/49482455/179907255-e0dc55bd-0113-4f4b-a523-cdff899214dd.png">


### 实现思路    


大体想法使用毛笔的笔触和噪音来干扰RampTex的色阶效果


## [ShadowMap(PCF)](https://github.com/corsair0909/UnityShader/tree/main/Assets/Shader/ShadowMap/PCF/PCFCutsom).   
<img width="799" alt="截屏2022-07-28 12 52 59" src="https://user-images.githubusercontent.com/49482455/181424039-9dbf43a9-04ee-42c7-982d-c4410da668db.png">。      
### ShadowMap    
<img width="698" alt="截屏2022-07-28 13 03 05" src="https://user-images.githubusercontent.com/49482455/181424795-14ff4e28-4f4a-48d2-a2d1-b91643aaed0c.png">    
上图对ShadowMap做出了解释，从光源位置渲染出场景的深度图，称之为ShadowMap，再与片元真正深度进行比较，片元深度大于ShadowMap中深度的位置说明有物体挡住这部分，就认为他在阴影中    


### PCF算法核心思想    
PCF(Percentage-Closer Filtering)是ShadowMap的扩展技术，能够制作边缘相对平滑的阴影（模糊边缘阴影），在ShadowMap的基础上模糊渲染出的shadowMap。


### 参考链接    
[Unity实时阴影实现——Shadow Mapping](https://zhuanlan.zhihu.com/p/45653702).     
[PCF软阴影技术讲解](https://blog.csdn.net/jxw167/article/details/65632580).    
[实时渲染｜Shadow Map：PCF、PCSS、VSM、MSM](https://zhuanlan.zhihu.com/p/369710758#:~:text=PCF是shadow%20map的扩展技术，用于提供一种人工伪造的软阴影，其主要方式是在计算着色点与shadow,map中该点深度值的比较的时候，不仅采样该像素点的深度值，同时采样周边多个shadow%20map点深度值，逐一比较并求平均值，从而获得了一个从0到1的连续分布，能够表现不同明暗程度的阴影%E3%80%82.)     
[技术美术知识学习4300：实时阴影](https://blog.csdn.net/qq_36005498/article/details/120441189).   


## [草地(几何+曲面细分着色器)](https://github.com/corsair0909/UnityShader/tree/main/Assets/Shader/GeometryShader)
![lQLPJxaUH4czMRzNAmDNA6SwJhyz0tCd7JgC88BT7ABuAA_932_608 png_720x720g](https://user-images.githubusercontent.com/49482455/184465405-a854cc72-42c3-4ea9-b2f7-71781f483cc7.jpg)

### 实现
1、几何着色器和曲面细分着色器的联合使用：VertexShader->（传递数据）->TessellationShader->(传细分后的数据)->GeometryShader->（传递新产生的顶点）->framentShader
#### 曲面细分着色器  
细分控制着色器hullShader：起到专递数据的作用，通过5个特性配置数据      
细分计算着色器DomainShader：计算由hullShader传入的细分顶点的位置（也可以进行空间变换），特性决定输入类型。  
由于三角形顶点无法使用xy坐标定位，需要三角形中的重心坐标对每个顶点数据进行重新定位，曲面细分后每一组细分都会有自己的重心坐标SV_DomainLocation    
#### 几何着色器    
将图元作为输入，生成新的顶点输出，将顶点附加到输出流来一次输出一个顶点，流的拓扑由固定的选择来确定（TriangleStream、LineStream、PointStream）作为GS输出阶段的流选择
新
将图元作为输入，生成新的顶点输出，将顶点附加到输出流来一次输出一个顶点，流的拓扑由固定的选择来确定（TriangleStream、LineStream、PointStream）作为GS输出阶段的流选
PS：新生成的顶点也要进行空间变换，所以在顶点着色器中不进行变换，而是延迟到新的顶点计算完成后。  
一次Append函数会想流提交一个顶点，顶点会根据流的拓扑选择组成新的形状。    
#### 草地生成     
以片元上的任意一顶点（包括中心点）为基准，在左右两侧和法线方向上的点生成新的顶点组成三角形。
为了确保草地可以在任意平面上正常生成（也即草的生长方向在任意平面上垂直片元），将使用切线空间，一般规定向上方向为Y轴，但切线空间向上方向为第三个分量Z轴，在设置草的高度时将高度参数设置到Z分量上.   
<img width="560" alt="截屏2022-08-13 11 28 14" src="https://user-images.githubusercontent.com/49482455/184466755-9c6a1c85-8233-475c-be71-e149c7ce9561.png">    
#### 剩下的细节    
风：FlowMap贴图采样出的随机向量，得出绕风向量旋转的矩阵添加到变换矩阵中（此处变换矩阵指位置变换）   
弯曲度：绕水平方向轴求出变换矩阵，添加参数控制弯曲度    
朝向：绕树枝方向轴求出变换矩阵（切线空间的第三个分量）    
三个矩阵对新生成的顶点进行变换得到不同朝向的草    
曲率：宏定义 BLADE_SEGMENTS*2+1 中定义了层数Segment和所需要的顶点数量，根据层数计算每一层草的高度和宽度。


### 参考链接
[Roystan](https://roystan.net/articles/grass-shader.html)    
[细分着色器(Tessellation Shader)在Unity顶点着色器中的写法以及各参数变量解释](https://blog.csdn.net/liu_if_else/article/details/75039895)    
[Unity Shader:曲面细分着色器](https://zhuanlan.zhihu.com/p/342308199)    
[LearnOpenGL-几何着色器](https://learnopengl-cn.readthedocs.io/zh/latest/04%20Advanced%20OpenGL/09%20Geometry%20Shader/)
[Shader特效—— 爆炸，沙化](https://blog.csdn.net/xdedzl/article/details/89644365)    
[Geometry Shader学习笔记](https://blog.csdn.net/qq_37925032/article/details/82936769)    
[三维绕任意轴旋转矩阵](https://blog.csdn.net/qq_44800780/article/details/102895109)

## [景深（Depth Of Field)](https://github.com/corsair0909/UnityShader/tree/main/Assets/Shader/DOF)    
CommanderBuffer实现  
<img width="1285" alt="截屏2022-08-18 11 58 41" src="https://user-images.githubusercontent.com/49482455/185302572-0e8e38c4-e126-4489-a387-08cb6aa39cf8.png">  
深度图实现    
<img width="1285" alt="截屏2022-08-18 13 31 29" src="https://user-images.githubusercontent.com/49482455/185302581-477d9d48-40ec-43b9-9396-87c4d4722707.png">


