cd ..
for item in kernel/runtime/std/typeinfo/*.d;
do
	echo "--> $item"
	ldc -nodefaultlib -g -I. -Ibuild/dsss_imports/. -m64 -Ikernel/runtime/. -code-model=large -c $item -odbuild/dsss_objs/G/. ;\
done
cd build
