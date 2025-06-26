
# Docker Commands Cheat Sheet

-------------------
### VISUAL CODE
-------------------

#### build example
`docker build -t imx8-sb_8_1-wayland-base-vivante_3 .`

#### tag example
`docker tag imx8-sb_8_1-wayland-base-vivante_3 cranksoftware/imx8-sb_8_1-wayland-base-vivante_3:v0.1`

#### push example
`docker push cranksoftware/imx8-sb_8_1-wayland-base-vivante_3:v0.1`

-------------------
### TARGET 
-------------------

### IMX6 TORIZON OS 7

#### run weston container: torizon/weston:4 

`docker container run -d --name=weston --net=host --cap-add CAP_SYS_TTY_CONFIG -v /dev:/dev -v /tmp:/tmp --device-cgroup-rule="c 13:* rmw" --device-cgroup-rule="c 226:* rmw" --device-cgroup-rule="c 10:223 rmw" torizon/weston:4 --developer`

#### run crank container - imx6-sb_8_2-wayland-base_4:v0.2
`docker run -it --rm --name=crank -v /tmp:/tmp -v /dev/dri:/dev/dri -v /var/run/dbus:/var/run/dbus --device-cgroup-rule='c 226:* rmw' cranksoftware/imx6-sb_8_2-wayland-base_4:v0.2`

### IMX8 TORIZON OS 7

#### run weston container: torizon/weston-imx8:4 

`docker container run -d --name=weston --net=host --cap-add CAP_SYS_TTY_CONFIG -v /dev:/dev -v /tmp:/tmp -v /run/udev/:/run/udev/ --device-cgroup-rule="c 4:* rmw" --device-cgroup-rule="c 253:* rmw" --device-cgroup-rule="c 13:* rmw" --device-cgroup-rule="c 226:* rmw" --device-cgroup-rule="c 10:223 rmw" --device-cgroup-rule="c 199:0 rmw" torizon/weston-imx8:4 --developer`

#### run crank container - cranksoftware/imx8-sb_8_2-wayland-base-imx8_4:v0.1
`docker run -it --rm --name=crank -v /tmp:/tmp -v /var/run/dbus:/var/run/dbus -v /dev/galcore:/dev/galcore --device-cgroup-rule='c 199:* rmw' cranksoftware/imx8-sb_8_2-wayland-base-imx8_4:v0.1`

### TI62 TORIZON OS 7

#### run weston container: torizon/weston-am64:4 

`docker container run -d --name=weston --net=host --cap-add CAP_SYS_TTY_CONFIG -v /dev:/dev -v /tmp:/tmp -v /run/udev/:/run/udev/ --device-cgroup-rule="c 4:* rmw" --device-cgroup-rule="c 13:* rmw" --device-cgroup-rule="c 226:* rmw" --device-cgroup-rule="c 10:223 rmw" torizon/weston-am62:4 --developer`

#### run crank container - ti62-sb_8_2-wayland-base-am62_4:v0.1
`docker run -d --rm --name=crank -v /tmp:/tmp -v /dev/dri:/dev/dri -v /var/run/dbus:/var/run/dbus --device-cgroup-rule='c 226:* rmw' cranksoftware/ti62-sb_8_2-wayland-base-am62_4:v0.1`