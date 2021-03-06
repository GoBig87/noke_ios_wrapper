from toolchain import CythonRecipe, shprint
from os.path import join
from distutils.dir_util import copy_tree
import fnmatch
import sh
import os

class NokeRecipe(CythonRecipe):
    version = "master"
    url = "https://github.com/GoBig87/noke_ios_wrapper/archive/{version}.zip"
    library = "noke.a"
    depends = ["python3", "hostpython3"]
    pre_build_ext = True
    archs = ['arm64']

    def install(self):
        pass
        arch = list(self.filtered_archs)[0]
        build_dir = join(self.get_build_dir(arch.arch), 'build', 'lib.macosx-10.14-x86_64-3.7')
        filename = '__init__.py'
        with open(os.path.join(build_dir, filename), 'wb'):
            pass
        dist_dir  = join(self.ctx.dist_dir, 'root', 'python3', 'lib', 'python3.7', 'site-packages', 'noke')
        copy_tree(build_dir, dist_dir)

    def biglink(self):
        dirs = []
        for root, dirnames, filenames in os.walk(self.build_dir):
            if fnmatch.filter(filenames, "*.so.*"):
                dirs.append(root)
            if fnmatch.filter(filenames, "*.o.*"):
                dirs.append(root)
        cmd = sh.Command(join(self.ctx.root_dir, "tools", "biglink"))
        shprint(cmd, join(self.build_dir, "noke.a"), *dirs)

recipe = NokeRecipe()