# 当前设计资源

后续页面设计使用[视觉规范](../../product/design.md)和 [HTML 手册](../index.html)，完整对应关系维护在 [catalog.json](../catalog.json)。

- [core-pages/](core-pages/)：核心页面效果图及生成提示词，覆盖首页、课表、学习任务、倒计时、工具箱、点名和设置。
- [random-tools/](random-tools/)：随机工具详情效果图、页面提示词及签袋素材生成记录。
- [icons/](icons/)：独立界面 SVG。
- [illustrations/](illustrations/)：贴纸与场景插画。
- [materials/](materials/)：纸张、撕边和胶带素材。
- [tokens.css](tokens.css)、[materials.css](materials.css)：视觉变量与通用材质样式；保留同级 materials 目录即可复用。
- [截图索引](screenshots/README.md)：现行独立动效截图、六个基础页面的原样板截图与手册检查证据。

复用时保持文件与通用材质样式的相对目录。资源更新与手册同步见[维护说明](../README.md)。提示词记录图片生成过程，页面实现遵循视觉规范中的当前约束。

## 提示词的使用范围

提示词保留原始生成输入，含当时使用的参数与示例文案。现行页面要求与数值分别查阅视觉规范和 tokens.css。

- 提示词中的参数、示例文案和“图像特征”均为历史资料；参考图及缺失的生成输入见各自记录。
- 新增或替换稿件时更新资源清单的采用关系，保留来源说明；不要为统一参数而改写原始提示词正文。
