#! /bin/bash

source /root/clovrEnv.sh

makeWSUrl.py http://localhost/vappio/clusterInfo_ws.py -j '{"name": "local"}'  
makeWSUrl.py http://localhost/vappio/listClusters_ws.py -j '{"name": "local"}'  
makeWSUrl.py http://localhost/vappio/pipelineStatus_ws.py -j '{"name": "local", "pipelines": []}'  
makeWSUrl.py http://localhost/vappio/queryTag_ws.py -j '{"name": "local"}'  
makeWSUrl.py http://localhost/vappio/task_ws.py -j '{"name": "local"}'  



