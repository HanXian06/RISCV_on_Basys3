# RISCV_on_Basys3
建议上传代码时按模块先创建Branch，再上传至对应Branch中。

如需PR至main分支，建议对所在模块进行仿真并验证功能正确；建议仿真文件、波形等上传至对应Branch，但不用PR至main分支。

上传后请维护者按时间倒序修改README，说明本次维护更新内容以及项目开展情况；各Branch的README不做要求（如果你没有时间的话）。

## 11/26 修改：陈珂乐
上传了IF、ID模块以及异步复位rst_sync模块。IMEM本作为IF的子模块，但作为IP调用，所以隔离出了IMEM Branch。以上提交的模块暂未仿真。
