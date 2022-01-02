// GRUB 头的 C 语言部分，用于放置二级引导器到指定内存中

#define MDC_ENDGIC 0xaaffaaffaaffaaff
#define MDC_RVGIC 0xffaaffaaffaaffaa
#define REALDRV_PHYADR 0x1000
#define IMGFILE_PHYADR 0x4000000
#define IMGKRNL_PHYADR 0x2000000
#define LDRFILEADR IMGFILE_PHYADR
#define MLOSDSC_OFF (0x1000)
#define MRDDSC_ADR (mlosrddsc_t *)(LDRFILEADR + 0x1000)

void inithead_entry()
{
  write_realintsvefile();
  write_ldrkrlfile();
  return;
}

// 把映像文件中的 initldrsve.bin 文件写入到特定的内存地址空间中
void write_realintsvefile()
{
  fhdsc_t *fhdscstart = find_file("initldrsve.bin");
  if (fhdscstart == NULL)
  {
    error("not file initldrsve.bin");
  }
  m2mcopy((void *)((u32_t)(fhdscstart->fhd_intsfsoff) + LDRFILEADR),
          (void *)REALDRV_PHYADR, (sint_t)fhdscstart->fhd_frealsz);
  return;
}

// 写 initldrkrl.bin 文件到特定的内存中
void write_ldrkrlfile()
{
  fhdsc_t *fhdscstart = find_file("initldrkrl.bin");
  if (fhdscstart == NULL)
  {
    error("not file initldrkrl.bin");
  }
  m2mcopy((void *)((u32_t)(fhdscstart->fhd_intsfsoff) + LDRFILEADR),
          (void *)ILDRKRL_PHYADR, (sint_t)fhdscstart->fhd_frealsz);
  return;
}

// 在映像文件中查找对应的文件
fhdsc_t *find_file(char_t *fname)
{
  mlosrddsc_t *mrddadrs = MRDDSC_ADR;
  if (mrddadrs->mdc_endgic != MDC_ENDGIC ||
      mrddadrs->mdc_rv != MDC_RVGIC ||
      mrddadrs->mdc_fhdnr < 2 ||
      mrddadrs->mdc_filnr < 2)
  {
    error("no mrddsc");
  }

  s64_t rethn = -1;
  fhdsc_t *fhdscstart = (fhdsc_t *)((u32_t)(mrddadrs->mdc_fhdbk_s) + LDRFILEADR);
  for (u64_t i = 0; i < mrddadrs->mdc_fhdnr; i++)
  {
    if (strcmpl(fname, fhdscstart[i].fhd_name) == 0)
    {
      rethn = (s64_t)i;
      goto ok_l;
    }
  }

  rethn = -1;
ok_l:
  if (rethn < 0)
  {
    error("not find file");
  }

  return &fhdscstart[rethn];
}