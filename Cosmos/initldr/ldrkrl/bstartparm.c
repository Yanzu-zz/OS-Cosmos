// 初始化 machbstart_t 结构体，清0，并设置一个标志
void machbstart_t_init(machbstart_t *initp)
{
  memset(initp, 0, sizeof(machbstart_t));
  initp->mb_migc = MBS_MIGC;
  return;
}

// 负责检查 CPU 模式、手机内存信息，设置内核栈，设置内核字体、建立内核 MMU 页表数据
void init_bstartparm()
{
  machbstart_t *mbsp = MBSPADR; // 1MB的内存地址
  machbstart_t_init(mbsp);

  // 后面还会有更多的活计的

  return;
}

// 首先要检查我们的 CPU，因为它是执行程序的关键。我们要搞清楚它能执行什么形式的代码，支持 64 位长模式吗？
// 这个工作我们交给 init_chkcpu() 函数来干，由于我们要 CPUID 指令来检查 CPU 是否支持 64 位长模式，所以这个函数中需要找两个帮工
// chk_cpuid、chk_cpu_longmode 来干两件事，一个是检查 CPU 否支持 CPUID 指令，然后另一个用 CPUID 指令检查 CPU 支持 64 位长模式。

// 通过改写 Eflags 寄存器的第21位，观察其位的变化判断是否支持 CPUID
int chk_cpuid()
{
  int rets = 0;
  __asm__ __volatile__(
      "pushfl \n\t"
      "popl %%eax \n\t"
      "movl %%eax,%%ebx \n\t"
      "xorl $0x0200000,%%eax \n\t"
      "pushl %%eax \n\t"
      "popfl \n\t"
      "pushfl \n\t"
      "popl %%eax \n\t"
      "xorl %%ebx,%%eax \n\t"
      "jz 1f \n\t"
      "movl $1,%0 \n\t"
      "jmp 2f \n\t"
      "1: movl $0,%0 \n\t"
      "2: \n\t"
      : "=c"(rets)
      :
      :);

  return rets;
}

// 检查CPU是否支持长模式
int chk_cpu_longmode()
{
  int rets = 0;
  __asm__ __volatile__(
      "movl $0x80000000,%%eax \n\t"
      "cpuid \n\t"                  // 把eax中放入0x80000000调用CPUID指令
      "cmpl $0x80000001,%%eax \n\t" // 看eax中返回结果
      "setnb %%al \n\t"             // 不为0x80000001,则不支持0x80000001号功能
      "jb 1f \n\t"
      "movl $0x80000001,%%eax \n\t"
      "cpuid \n\t"         // 把eax中放入0x800000001调用CPUID指令，检查edx中的返回数据
      "bt $29,%%edx  \n\t" // 长模式 支持位  是否为1
      "setcb %%al \n\t"
      "1: \n\t"
      "movzx %%al,%%eax \n\t"
      : "=a"(rets)
      :
      :);

  return rets;
}

// 检查 CPU 主函数
void init_chkcpu(machbstart_t *mbsp)
{
  if (!chk_cpuid())
  {
    kerror("Your CPU is not support CPUID sys is die!");
    CLI_HALT();
  }
  if (!chk_cpu_longmode())
  {
    kerror("Your CPU is not support 54bits mode sys is die!");
    CLI_HALT();
  }

  mbsp->mb_cpumode = 0x40; // 如果成功则设置机器信息结构的 CPU 模式为 64 位
  return;
}
