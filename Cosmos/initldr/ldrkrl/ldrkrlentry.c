// 该函数在 initldr32.asm 文件中被调用
void ldrkrl_entry()
{
  // init_bstartparm() 函数是收集机器环境信息的主函数
  init_bstartparm();
  return;
}