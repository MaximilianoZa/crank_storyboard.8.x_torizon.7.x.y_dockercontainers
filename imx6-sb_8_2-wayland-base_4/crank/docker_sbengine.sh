crank_dir=/usr/crank
scp_dir=$crank_dir/scp
sbengine_ext=.gapp

#runtime=/usr/crank/runtimes/linux-imx6-armle-opengles_2.0-wayland-obj
runtime=/usr/crank/runtimes/linux-armv7le-opengles_2.0-wayland-obj

sb_binary=$runtime/bin/sbengine
sb_app=Thermostat/Thermostat.gapp
#sb_app=EvCharger/EV_Charger.gapp
demo_app=$crank_dir/apps/$sb_app

sb_options='-vv -orender_mgr,fullscreen,multisample=0 -omodel3d,max_lights=4 -omtdev,device=/dev/input/event2'
echo "-vv -orender_mgr,fullscreen,multisample=0 -omodel3d,max_lights=4 -omtdev,device=/dev/input/event2"

#ENV Variables
export SB_PLUGINS=$runtime/plugins
export LD_LIBRARY_PATH=$runtime/lib:$LD_LIBRARY_PATH
export LD_PRELOAD=/usr/lib/arm-linux-gnueabihf/libwayland-egl.so.1

export XDG_RUNTIME_DIR=/tmp/1000-runtime-dir
export WAYLAND_DISPLAY=wayland-0
export DISPLAY=:0


#Verify that SCP directory exists, and check if .gapp file is stored in it.
#If a .gapp file exists run sbengine on this app, otherwise execute demo
#launcher
scp_app=$(find /usr/crank/scp -name *.gapp -print -quit)
echo $scp_app
if [ -z $scp_app ]; then
    echo "Starting Crank Demo Application..."
    echo $sb_app    
    $sb_binary $sb_options $demo_app
else
    echo "Starting Storyboard SCP Application..."
    echo $scp_app    
    $sb_binary $sb_options $scp_app
fi