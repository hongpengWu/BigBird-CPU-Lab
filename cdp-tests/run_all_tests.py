from os import getenv
from os import listdir
from os import system
from os.path import isfile, join

cpu_dir = getenv("CPU_DIR", "").strip()
tb = [f for f in listdir("bin") if isfile(join("bin", f))]
success = []
fail = []
for t in tb:
    t = t.split('.')[0]
    print("\n\n==================== Testing %s ====================" % t) 
    cmd = "make run_for_python TEST=" + t
    if cpu_dir:
        cmd += " CPU_DIR=" + cpu_dir
    result = system(cmd)
    if result == 0:
        success.append(t)
    else:
        fail.append(t)
    print("==================== %s END ==================== " % t)

print("\n\n==================== SUMMARY ==================== ")
print("Passed Tests:")
print(", ".join(success))
print("Failed Tests:")
print(", ".join(fail))
