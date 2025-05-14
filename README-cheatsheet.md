
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

#### run crank container [ GPU access IMX6: --device-cgroup-rule='c 226 ]
`docker run -it --rm --name=crank -v /tmp:/tmp -v /dev/dri:/dev/dri -v /var/run/dbus:/var/run/dbus --device-cgroup-rule='c 226:* rmw' cranksoftware/imx6-sb_8_2-wayland-base_4:v0.1`

