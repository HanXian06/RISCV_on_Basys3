# RISCV_on_Basys3
建议上传代码时按模块先创建Branch，再上传至对应Branch中。

如需PR至main分支，建议对所在模块进行仿真并验证功能正确；建议仿真文件、波形等上传至对应Branch，但不用PR至main分支。

上传后请维护者按时间倒序修改README，说明本次维护更新内容以及项目开展情况；各Branch的README不做要求（如果你没有时间的话）。

## 10/28 修改：陈珂乐
修改了IF下的PC模块，加载地址最低位强制置0，用于兼容jalr指令。
新增了MA模块，包含DMEM的IP调用，以及load_extend子模块，用于处理非整字load的位扩展。DMEM额外另存Branch。当前IF、ID、MA均未仿真。
写到这里突然想起来MA的注释没写，等我写完再提交一版。顺便我来再把WB一起写了。

## 11/27 修改：陈珂乐
修改了ID模块，新增x0_call信号处理lui指令时ALU需要加x0的情况。各模块暂未仿真。

## 11/26 修改：陈珂乐
上传了IF、ID模块以及异步复位rst_sync模块。IMEM本作为IF的子模块，但作为IP调用，所以隔离出了IMEM Branch。以上提交的模块暂未仿真。
