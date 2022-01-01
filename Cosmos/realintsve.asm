; 实现 BIOS 中断的功能（从 C语言环境32位进入 BIOS 中断环境16位）
[bits 16]
_start:
; 进入实模式
_16_mode:
  mov bp, 0x20 ; 0x20 是指向 GDT 中的16位数据段描述符
  mov ds, bp
  mov es, bp
  mov ss, bp
  mov ebp, cr0
  and ebp, 0xfffffffe
  mov cr0, ebp     ; CR0.P=0 关闭保护模式
  jmp 0:real_entry ; 刷新 CS 影子寄存器，真正进入实模式
real_entry:
  mov bp, cs
  mov ds, bp
  mov es, bp
  mov ss, bp ; 重新设置实模式下的段寄存器都是CS中值，即为0
  mov sp, 08000h ; 设置栈
  mov bp, func_table
  add bp, ax ; 根据由 ax 寄存器传入的函数号，到函数表中调用对应的函数
  call [bp]  ; 调用函数表中的汇编函数，ax 是C函数中传递进来的
  cli        ; 很熟悉了吧，关中断指令
  call disable_nmi
  mov ebp, cr0
  or  ebp, 1
  mov cr0, ebp ; CR0.P=1 开启保护模式
  jmp dword 0x8 :_32bits_mode ; 传递进来的函数执行完成后，再次进入保护模式

[BITS 32]
_32bits_mode:
  mov bp, 0x10
  mov ds, bp
  mov ss, bp ; 重新设置保护模式下的段寄存器 0x10 是 32 位数据段描述符的索引
  mov esi, [PM32_EIP_OFF] ; 加载先前保存的 EIP
  mov esp, [PM32_ESP_OFF] ; 加载先前保存的 ESP
  jmp esi ; eip=esi 回到了 realadr_call_entry 函数

func_table:
  dw _getmmap ; 获取内存布局视图的函数
  dw _read    ; 读取硬盘的函数
    dw _getvbemode         ; 获取显卡 VBE 模式
    dw _getvbeonemodeinfo  ; 获取显卡 VBE 模式的数据
    dw _setvbemode         ; 设置显卡VBE模式

; 上面的代码我们只要将它编译成 16 位的二进制的文件，并把它放在 0x1000 开始的内存空间中就可以了。这样在 realadr_call_entry 函数的最后，就运行到这段代码中来了。