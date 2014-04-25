import re, subprocess, sys

directory = sys.argv[1]
if directory == "":
	print "Proper usage is python path.py <directory_name>"

p = subprocess.Popen(["find", "./"+directory, "-name", "log*"], stdout=subprocess.PIPE)
output, err = p.communicate()
foutput = output.split("\n")
for file_name in foutput:
    if re.search("2\.0$",file_name):
		fp = open(file_name, "r")
		wp = open("sdmaps","w+")
		for line in fp:
			if re.search("path from node",line):
				path_line = line[line.find(":")+1:]
				src_node = path_line[1:path_line.find("-->")]
				dst_node = path_line.split(">")[-1].strip()
			if re.search("candidate",line) and re.search(path_line,line):
				metric_line = line[line.find("metric")+6:line.find(":")-1]
				if float(metric_line) != 0:
					metric_line = str(1/float(metric_line))
				else:
					metric_line = "infinity"
				cont ="node:"+src_node.strip()+"  node"+dst_node+"  : "+metric_line.strip()+"\n"
				wp.write(cont)
		wp.close()
		fp.close()

