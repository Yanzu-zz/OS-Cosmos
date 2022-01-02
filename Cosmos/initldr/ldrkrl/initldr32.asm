; 二级引导器核心入口汇编部分
; 检查 CPU 是否支持 64 位工作模式、手机内存布局信息，看看是不是合乎我们操作系统的最低运行要求
; 还需要设置操作系统需要的 MMU 页表、设置显卡模式、释放中文字体文件

_entry:
  cli            ; 关中断
  lgdt [GDT_PTR] ; 加载 GT 地址到 GDTR 寄存器
  lidt [IDT_PTR] ; 加载 IDT 地址到 IDTR 寄存器
  jmp dword 0x8 :_32bits_mode ; 长跳转刷新 CS 影子寄存器

; 初始化 CPU 相关寄存器
_32bits_mode:
  mov ax, 0x10 ; 数据段选择子（目的）
  mov ds, ax
  mov ss, ax
  mov es, ax
  mov fs, ax
  mov gs, ax
  xor eax,eax
  xor ebx,ebx
  xor ecx,ecx
  xor edx,edx
  xor edi,edi
  xor esi,esi
  xor ebp,ebp
  xor esp,esp
  mov esp, 0x90000 ; 使得栈底指向 0x90000
  call ldrkrl_entry ; 调用函数
  xor ebx, ebx
  jmp 0x2000000
  jmp $

; C 语言环境下调用 BIOS 中断，需要处理的问题如下：
;   1. 保存 C 语言环境下的 CPU 上下文 ，即保护模式下的所有通用寄存器、段寄存器、程序指针寄存器，栈寄存器，把它们都保存在内存中。
;   2. 切换回实模式，调用 BIOS 中断，把 BIOS 中断返回的相关结果，保存在内存中。
;   3. 切换回保护模式，重新加载第 1 步中保存的寄存器。这样 C 语言代码才能重新恢复执行。
realadr_call_entry:
  pushad  ; 保存通用寄存器
  push ds
  push es
  push fs ; 保存 4 个段寄存器
  push gs
  call save_eip_jmp
  pop gs
  pop fs
  pop es  ; 回复 4 个段寄存器
  pop ds
  popad   ; 回复通用寄存器
  ret
save_eip_jmp:
  pop esi ; 弹出 call save_eip_jmp 时保存的 eip 到 esi 寄存器中
  mov [PM32_EIP_OFF], esi ; 把 eip 保存到特定的内存空间中
  mov [PM32_ESP_OFF], esp ; 把 esp 保存到特定的内存空间中
  ; 长跳转，表示把[cpmty_mode]处的数据装入 CS：EIP
  ; 即把 cpmty_mode 处的第一个 4 字节装入 eip，把其后的 2 字节装入 cs；就是把 0x18：0x1000 装入到 CS：EIP 中
  ; 这个 0x18 就是段描述索引
  jmp dword far [cpmty_mode] 
cpmty_mode:
  dd 0x1000
  dw 0x18
  jmp $
  
GDT_START:
knull_dsc: dq 0
kcode_dsc: dq 0x00cf9a000000ffff ; a-e
kdata_dsc: dq 0x00cf92000000ffff
k16cd_dsc: dq 0x00009a000000ffff ; 16位代码段描述符
k16da_dsc: dq 0x000092000000ffff ; 16位数据段描述符
GDT_END:
GDT_PTR:
GDTLEN   dw GDT_END-GDT_START-1  ; GDT界限
GDTBASE  dd GDT_START

IDT_PTR:
IDTLEN  dw 0x3ff
IDTBAS  dd 0  ; 这是BIOS中断表的地址和长度