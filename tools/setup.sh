#!/bin/bash
mkdir -p weewx_code



git clone git@github.com:bellrichm/WeeWX-Extras weewx_code/WeeWX-Extras
git clone git@github.com:bellrichm/configs weewx_code/configs
git clone git://rmbell.local/secrets weewx_code/secrets

mkdir weewx_code/forks
git clone git@github.com:bellrichm/fuzzy-archer weewx_code/forks/fuzzy-archer
git clone git@github.com:bellrichm/vds-weewx-v3-mem-extension weewx_code/forks/vds-weewx-v3-mem-extension
git clone git@github.com:bellrichm/weewx-belchertown weewx_code/forks/weewx-belchertown
git clone git@github.com:bellrichm/weewx-celestial weewx_code/forks/weewx-celestial
git clone git@github.com:bellrichm/weewx-cmon weewx_code/forks/weewx-cmon
git clone git@github.com:bellrichm/weewx-loopdata weewx_code/forks/weewx-loopdata
git clone git@github.com:bellrichm/weewx-nws weewx_code/forks/weewx-nws
git clone git@github.com:bellrichm/weewx-skyfield weewx_code/forks/weewx-skyfield
git clone git@github.com:bellrichm/weewx-wdc weewx_code/forks/weewx-wdc
git clone git@github.com:bellrichm/weewx-xaggs weewx_code/forks/weewx-xaggs

git -C weewx_code/forks/weewx-celestial checkout mqtt
git -C weewx_code/forks/weewx-skyfield checkout file_location

mkdir -p weewx_code/weewx-extensions
git clone git@github.com:weewx-extensions/aqi-xtype weewx_code/weewx-extensions/aqi-xtype
git clone git@github.com:weewx-extensions/development-tools weewx_code/weewx-extensions/development-tools
git clone git@github.com:weewx-extensions/jas weewx_code/weewx-extensions/jas
git clone git@github.com:weewx-extensions/healthchecks weewx_code/weewx-extensions/healthchecks
git clone git@github.com:weewx-extensions/pushover weewx_code/weewx-extensions/pushover
git clone git@github.com:weewx-extensions/test weewx_code/weewx-extensions/test

mkdir -p ~/weewx_code/weewx-mqtt
git clone git@github.com:weewx-mqtt/mqttcommon weewx_code/weewx-mqtt/mqttcommon
git clone git@github.com:weewx-mqtt/plugin-loopdata weewx_code/weewx-mqtt/plugin-loopdata
git clone git@github.com:weewx-mqtt/publish weewx_code/weewx-mqtt/publish
git clone git@github.com:weewx-mqtt/replicate weewx_code/weewx-mqtt/replicate
git clone git@github.com:weewx-mqtt/subscribe weewx_code/weewx-mqtt/subscribe

mkdir weewx_code/weewx-releases
wget -P weewx_code/weewx-releases https://weewx.com/downloads/released_versions/weewx-5.5.2.tgz 
tar -xzf weewx_code/weewx-releases/weewx-5.5.2.tgz -C weewx_code/weewx-releases/
rm weewx_code/weewx-releases/weewx-5.5.2.tgz

wget -P weewx_code/weewx-releases https://weewx.com/downloads/released_versions/weewx-5.0.0.tgz 
tar -xzf weewx_code/weewx-releases/weewx-5.0.0.tgz -C weewx_code/weewx-releases/
rm weewx_code/weewx-releases/weewx-5.0.0.tgz

git clone git@github.com:weewx/weewx weewx_code/weewx-releases/weewx-clone
git clone git@github.com:bellrichm/weewx weewx_code/weewx-releases/weewx-fork
ln -s ../weewx-releases/weewx-fork weewx_code/weewx-mqtt
ln -s ../weewx-releases/weewx-clone weewx_code/weewx-mqtt

ln -s weewx_code/weewx-releases/weewx-fork weewx

ln -s ../../../weewx_code/weewx-extensions/aqi-xtype/bin/user/aqitype.py weewx-data/bin/user
ln -s ../../../weewx_code/WeeWX-Extras/bin/user/backup.py weewx-data/bin/user
ln -s ../../../weewx_code/forks/weewx-belchertown/bin/user/belchertown.py weewx-data/bin/user
ln -s ../../../weewx_code/weewx-mqtt/plugin-loopdata/bin/user/mqttloopdata.py weewx-data/bin/user
ln -s ../../../weewx_code/forks/weewx-celestial/bin/user/celestial_page.py weewx-data/bin/user
ln -s ../../../weewx_code/forks/weewx-celestial/bin/user/celestial_sky.py weewx-data/bin/user
ln -s ../../../weewx_code/forks/weewx-celestial/bin/user/celestial.py weewx-data/bin/user
ln -s ../../../weewx_code/forks/weewx-cmon/bin/user/cmon.py weewx-data/bin/user
ln -s ../../../weewx_code/weewx-extensions/healthchecks/bin/user/healthchecks.py weewx-data/bin/user
ln -s ../../../weewx_code/forks/fuzzy-archer/bin/user/historygenerator.py weewx-data/bin/user
ln -s ../../../weewx_code/weewx-extensions/jas/bin/user/jas_templates.py weewx-data/bin/user
ln -s ../../../weewx_code/weewx-extensions/jas/bin/user/jas.py weewx-data/bin/user
ln -s ../../../weewx_code/forks/fuzzy-archer/bin/user/jsonengine.py weewx-data/bin/user
ln -s ../../../weewx_code/forks/fuzzy-archer/bin/user/largeimagegenerator.py weewx-data/bin/user
ln -s ../../../weewx_code/forks/weewx-loopdata/bin/user/loopdata.py weewx-data/bin/user
ln -s ../../../weewx_code/forks/vds-weewx-v3-mem-extension/bin/user/mem.py weewx-data/bin/user
ln -s ../../../weewx_code/weewx-mqtt/publish/bin/user/mqttaggregatevalues.py weewx-data/bin/user
ln -s ../../../weewx_code/weewx-mqtt/publish/bin/user/mqttarchivevalues.py weewx-data/bin/user
ln -s ../../../weewx_code/weewx-mqtt/mqttcommon/bin/user/mqttcommon.py weewx-data/bin/user
ln -s ../../../weewx_code/weewx-mqtt/publish/bin/user/mqttconfigha.py weewx-data/bin/user
ln -s ../../../weewx_code/weewx-mqtt/publish/bin/user/mqtthaconfig.py weewx-data/bin/user
ln -s ../../../weewx_code/weewx-mqtt/plugin-loopdata/bin/user/mqttloopdata.py weewx-data/bin/user
ln -s ../../../weewx_code/weewx-mqtt/publish/bin/user/mqttmessagetracker.py weewx-data/bin/user
ln -s ../../../weewx_code/weewx-mqtt/publish/bin/user/mqttpublish.py weewx-data/bin/user
ln -s ../../../weewx_code/weewx-mqtt/replicate/bin/user/mqttreplicate.py weewx-data/bin/user
ln -s ../../../weewx_code/weewx-mqtt/subscribe/bin/user/mqttsubscribe.py weewx-data/bin/user
ln -s ../../../weewx_code/weewx-mqtt/publish/bin/user/mqtttracker.py weewx-data/bin/user
ln -s ../../../weewx_code/weewx-extensions/pushover/bin/user/notify.py weewx-data/bin/user
ln -s ../../../weewx_code/forks/weewx-nws/bin/user/nws.py weewx-data/bin/user
ln -s ../../../weewx_code/WeeWX-Extras/bin/user/observationtime.py weewx-data/bin/user
ln -s ../../../weewx_code/weewx-extensions/pushover/bin/user/pushover.py weewx-data/bin/user
ln -s ../../../weewx_code/WeeWX-Extras/bin/user/replicatedb.py weewx-data/bin/user
ln -s ../../../weewx_code/weewx-mqtt/replicate/bin/user/run_mqttreplicate.py weewx-data/bin/user
ln -s ../../../weewx_code/WeeWX-Extras/bin/user/runreports.py weewx-data/bin/user
ln -s ../../../weewx_code/forks/fuzzy-archer/bin/user/sunevents.py weewx-data/bin/user
ln -s ../../../weewx_code/forks/weewx-wdc/bin/user/weewx_wdc.py weewx-data/bin/user
ln -s ../../../weewx_code/forks/weewx-skyfield/bin/user/wxskyfield_de421.bsp weewx-data/bin/user
ln -s ../../../weewx_code/forks/weewx-skyfield/bin/user/wxskyfield_lines.dat weewx-data/bin/user
ln -s ../../../weewx_code/forks/weewx-skyfield/bin/user/wxskyfield_sky.py weewx-data/bin/user
ln -s ../../../weewx_code/forks/weewx-skyfield/bin/user/wxskyfield_stars.dat.gz weewx-data/bin/user
ln -s ../../../weewx_code/forks/weewx-skyfield/bin/user/wxskyfield.py weewx-data/bin/user
ln -s ../../../weewx_code/forks/weewx-xaggs/bin/user/xaggs.py weewx-data/bin/user

ln -s ../../weewx_code/weewx-extensions/aqi-xtype/skins/aqitype weewx-data/skins
ln -s ../../weewx_code/forks/weewx-belchertown/skins/Belchertown weewx-data/skins
ln -s ../../weewx_code/forks/fuzzy-archer/skins/Bootstrap weewx-data/skins
ln -s ../../weewx_code/forks/weewx-celestial/skins/Celestial weewx-data/skins
ln -s ../../weewx_code/forks/weewx-cmon/skins/cmon weewx-data/skins
ln -s ../../weewx_code/WeeWX-Extras/skins weewx-data/skins
ln -s ../../weewx_code/WeeWX-Extras/skins/develop weewx-data/skins
ln -s ../../weewx_code/weewx-extensions/healthchecks/skins/healthchecks weewx-data/skins
ln -s ../../weewx/src/weewx_data/skins/Horizon weewx-data/skins
ln -s ../../weewx_code/weewx-extensions/jas/skins/jas weewx-data/skins
ln -s ../../weewx_code/forks/weewx-loopdata/skins/LoopData weewx-data/skins
ln -s ../../weewx_code/forks/vds-weewx-v3-mem-extension/skins/mem weewx-data/skins
ln -s ../../weewx_code/forks/weewx-celestial/skins/MQTTCelestial weewx-data/skins
ln -s ../../weewx_code/weewx-mqtt/plugin-loopdata/skins/MQTTLoopData weewx-data/skins
ln -s ../../weewx_code/forks/weewx-nws/skins/nws weewx-data/skins
ln -s ../../weewx_code/forks/weewx-loopdata/skins/ScriptData weewx-data/skins
ln -s ../../weewx_code/forks/weewx-skyfield/skins/Skyfield weewx-data/skins
ln -s ../../weewx_code/forks/weewx-wdc/skins/weewx-wdc weewx-data/skins


weewx_code/configs/extensions/development-config.sh

weewx_code/WeeWX-Extras/utils/listVersions.py

# pyenv install 3.15
# pyenv global 3.15
# pip install configobj
# pip install ct3
# pip install Pillow
# pip install paho.mqtt
# pip install jplephem
# pip install skyfield


python weewx/src/weectl.py station create weewx-data --no-prompt

mkdir weewx-data/run

python weewx/src/weewxd.py --config weewx-data/weewx.conf
