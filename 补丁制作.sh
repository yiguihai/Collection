diff 源文件 修改好后的文件 生成的补丁文件路径
diff -uN 123.log 456.log > 456.patch

patch 需要修改的文件 补丁文件
patch -p0 Makefile <Makefile.patch
