等价 awk 输出第一个列
```shell
# awk '{print $1}'
# 去掉 -l 会没有换行
perl -lane 'print $F[0]'
```
输出文件指定行(第1行)
```shell
perl -ane 'print if($. ==1)'
```
