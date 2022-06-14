# 从0开始的着色器生活
![69460492_p0_master1200](https://user-images.githubusercontent.com/49482455/171035627-fd5fb592-5d83-4c71-b802-9ca5123888d4.jpg)

## [billboard](https://github.com/corsair0909/-0-Shader/tree/main/Assets/BillBoard)
![QQ20220613-174417-HD](https://user-images.githubusercontent.com/49482455/173327281-75f4e81c-7367-42ff-9e67-595a5deb2b4b.gif)
### 实现思路    
构建新的旋转矩阵，使用旋转矩阵旋转被着色的物体。旋转矩阵的需要3个基向量，分别是表面法线方向（normal），向上的方向（up），向右的方向（right），还需要一个位置不变的锚点，用于确定在旋转时的位置。通常是通过计算得出表面法线方向和向上方向，但二者有时并不是正交的，可以固定二者其一，通过差积得出新的向量构成旋转矩阵。right = up X normal , up1 = right X normal。    
根据原始位置相对于锚点的偏移量以及旋转矩阵计算新的顶点位置，最后将新的顶点位置转换到裁剪空间下。    
片元着色器中返回贴图采样结果即可。

<img width="1202" alt="截屏2022-06-13 18 03 31" src="https://user-images.githubusercontent.com/49482455/173331009-e8fe6b02-7c39-4567-9ec0-8af5707ad975.png">


