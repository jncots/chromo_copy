from pathlib import Path
from setuptools import setup
import sys
import subprocess as subp
import os

cwd = Path(__file__).parent

sys.path.append(str(cwd))
from cmake_ext import CMakeExtension, CMakeBuild, get_models  # noqa: E402

if not os.environ.get("CI", False):
    if (cwd / ".git").exists():
        # make sure that submodules are up-to-date,
        # it is a common error to forget this when
        # switching between development branches
        subp.check_call(["git", "submodule", "update"])


# for convenience, support building extra models via extra.cfg
# extra.cfg is not tracked by git, so can be freely modified
# extra.cfg example:
# -----
# sib23c00
# sib23c02
# sib23c03
# dev_dpmjetIII193=/full/path/to/dir/dpmjetIII-19.3
# ----

# Set environment variable VIRTUAL_ENV to venv directory
# It is required in FindPython to find a correct version of python
# when venv is used in cibuildwheel. It is rather the problem of
# cibuildwheel, which uses venv without activating it. So setting
# VIRTUAL_ENV imitates the activation. The workaround should be remove
# when `cibuildwheel` fixes this problem.
os.environ["VIRTUAL_ENV"] = str(Path(sys.executable).absolute().parents[1])

ext_modules = []
for model in get_models():
    ext_modules.append(CMakeExtension(f"chromo.models._{model}"))

setup(
    zip_safe=False,
    ext_modules=ext_modules,
    cmdclass={"build_ext": CMakeBuild},
)
