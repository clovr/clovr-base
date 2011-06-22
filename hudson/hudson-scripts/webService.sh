#!/bin/bash
set -e
source /root/clovrEnv.sh

makeWSUrl.py http://localhost/vappio/clusterInfo_ws.py -j '{"cluster": "local"}'  
makeWSUrl.py http://localhost/vappio/listClusters_ws.py -j '{"cluster": "local"}'  
makeWSUrl.py http://localhost/vappio/pipeline_list -j '{"cluster": "local"}'
makeWSUrl.py http://localhost/vappio/tag_list -j '{"cluster": "local"}'  
makeWSUrl.py http://localhost/vappio/task_ws.py -j '{"cluster": "local"}'  



