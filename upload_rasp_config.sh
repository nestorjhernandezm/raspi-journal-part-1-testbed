#!/usr/bin/env bash

zip -r rasp_config rasp_config
scp rasp_config.zip js3:/afs/ies.auc.dk/project/TuneSCode/public_html/raspi/
rm rasp_config.zip
