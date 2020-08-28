import os
import sys

with open(sys.argv[1], 'r') as conf:
    with open("src/spark_config.h", 'w') as conf_h:
        for line in conf.readlines():
            if line[:2] == '--':
                conf_h.write("//" + line[2:])
            elif ":=" in line:
                var, val = line.split(":=")
                val = val.replace("True", "ENABLED");
                val = val.replace("False", "DISABLED");
                conf_h.write(f"#define {var} {val}")
            else:
                conf_h.write("\n")
