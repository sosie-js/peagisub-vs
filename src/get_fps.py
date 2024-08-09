################################################################################
#
# usage:
#   python get_fps.py /source/video.mp4
#                             |                 
#                             absolute path     
#                                               
################################################################################


import sys
import os
import subprocess

absolute_filepath_to_source_video = sys.argv[1]

def get_frame_rate(filename):
    if not os.path.exists(filename):
        sys.stderr.write("ERROR: filename %r was not found!" % (filename,))
        return -1         
    out = subprocess.check_output(["ffprobe",filename,"-v","0","-of","csv=p=0","-select_streams","v:0","-show_entries","stream=r_frame_rate"])
    rate = out.decode()[0:-2] #get rid of ,\n
    if len(rate.split('/'))==2:
        return rate
    return "0"

print(get_frame_rate(absolute_filepath_to_source_video))
