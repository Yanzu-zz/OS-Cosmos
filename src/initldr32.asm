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
  
GDT_START:
knull_dsc: dq 0
kcode_dsc: dq 0x00cf9a000000ffff ;a-e
kdata_dsc: dq 0x00cf92000000ffff
k16cd_dsc: dq 0x00009a000000ffff ;16位代码段描述符
k16da_dsc: dq 0x000092000000ffff ;16位数据段描述符
GDT_END:
GDT_PTR:
GDTLEN   dw GDT_END-GDT_START-1  ;GDT界限
GDTBASE  dd GDT_START

IDT_PTR:
IDTLEN  dw 0x3ff
IDTBAS  dd 0  ;这是BIOS中断表的地址和长度