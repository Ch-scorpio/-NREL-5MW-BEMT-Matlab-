# -NREL-5MW-BEMT-Matlab-
叶片参数使用开源的NREL 5MW风机叶片，详情可见Definition of a 5-MW Reference Wind Turbine for Offshore System Development。本人代码小白，编写代码过程中使用了AI辅助，程序中可能存在错误，仅供产参。
# 使用说明
## 运行步骤
1. 文件 `BEMT.m` 为主程序，可以直接在 Matlab 中打开即可。
2. 后缀为 `.mat` 的文件（例如：`table_Cylinder1.mat`、`table_DU21.mat`、`table_DU25.mat` 等）为 NREL 5MW 叶片翼型在不同角度下的 Cl、Cd 系数矩阵文件。
3. 将 `.mat` 文件和 `BEMT.m` 文件放在同一文件夹。
4. 在Matlab中直接运行BEMT.m程序，等待结果输出即可。

---

## 补充说明
1. 该代码中可能存在错误，程序**仅供学习参考**。
2. `.mat` 文件中的数据详见《Definition of a 5-MW Reference Wind Turbine for Offshore System Development》中的附录 B。
3. 代码编写技术有限，编写时使用了 AI 辅助。

4月25日修改了BEMT.m中关于dQ公式的错误。
