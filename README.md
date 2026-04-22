# -NREL-5MW-BEMT-Matlab-
叶片参数使用开源的NREL 5MW风机叶片，详情可见Definition of a 5-MW Reference Wind Turbine for Offshore System Development。本人代码小白，编写代码过程中使用了AI辅助，程序中可能存在错误，仅供产参。
# 使用说明
## 运行步骤
1. 文件 `BEMT.m` 为主程序，直接在 Matlab 中打开即可。
2. 后缀为 `.mat` 的文件（例如：`table_Cylinder1.mat`、`table_DU21.mat`、`table_DU25.mat` 等）为 NREL 5MW 叶片翼型在不同角度下的 Cl、Cd 系数矩阵文件。
3. 将 `.mat` 文件和 `BEMT.m` 文件放在同一文件夹（不放在同一文件夹可能也无影响）。
4. 运行代码前，在 Matlab 中依次双击打开 8 个 `.mat` 文件，将矩阵数据保存在工作区。
5. 检查是否将 `BEMT.m` 文件中的 `clc; clear; close all;` 注释掉，避免运行时清空工作区。
6. 运行程序，等待结果输出。

---

## 补充说明
1. 该代码中可能存在错误，程序**仅供学习参考**。
2. `.mat` 文件中的数据详见《Definition of a 5-MW Reference Wind Turbine for Offshore System Development》中的附录 B。
3. 代码编写技术有限，编写时使用了 AI 辅助。
4. 可在 `BEMT.m` 中添加加载 `.mat` 文件的代码，但多次尝试均提示报错，目前暂按现有方式使用。
