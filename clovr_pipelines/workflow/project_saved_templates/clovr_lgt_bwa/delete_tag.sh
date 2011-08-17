#!/bin/bash

makeWSUrl.py -j '{"cluster": "local", "tag_name": "'$1'"}' 'http://localhost/vappio/tag_delete'
