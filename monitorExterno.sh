#!/bin/bash

#LINK: https://github.com/brunodles/linux-second-screen

#Install Arch in Kindle PW2:
#	https://www.youtube.com/watch?v=C8aFW5wROS4&feature=youtu.be

	# 1.Get root access and KUAL 
	#	+LINK: https://www.mobileread.com/forums/showthread.php?t=275880 
	#	(but I recommend searching around on that forum for information relevant to your situation) 
	#		+agregar al kernel driver "usbnet":
	#			https://superuser.com/questions/145933/how-to-add-usbnet-driver-to-the-linux-kernel
	#			LEER: http://how-to.wikia.com/wiki/How_to_configure_the_Linux_kernel/drivers/usb/net
	#			LEER2: https://unix.stackexchange.com/questions/185729/enabling-ethernet-over-usb-support-in-linux-kernel
	#		+como conectarse por ssh al kindle:
	#			https://www.mobileread.com/forums/showthread.php?t=204942
	#
	# 2.Create filesystem image file, and install Arch base system into it 
	#	+LINK: https://www.mobileread.com/forums/showthread.php?t=243173
	#
	# 3.Inside chroot, install X server, some window manager, and other things you'll need. 
	#	Also, install Xephyr, a windowed X client. 
	# 
	#4.Set up some mounting, GUI launching, and unmounting scripts for automation 
	#	+LINK: https://www.mobileread.com/forums/showthread.php?p=3223845#post3223845
	#
##<<<<<<<<<<<<<<<<<<<<--------------------------------------------------------->>>>>>>>>>>>>>>>>>>>>>
##PASSWD: x11vnc

## PARAMS
## Device resolution using [width]x[height], without bracets. Sample 800x600
## -v - VIRTUAL display to be used. Sample v1, v2, v3
## -left  - If our device is on the left
## -right - If our device is on the right
## -hst	  - Subtract status bar size from virtual display
## -hsb	  - Subtract system bar size from virtual display

### Uncomment what you are using, hardcoded
## Laptop
#fisical="LVDS1"
##PRUEBA
fisical="eDP1"
## VGA
#fisical="VGA1"
## HDMI
#fisical="HDM1"

## ADB path. hardcoded
#adb_bin=~/android-sdk-linux/platform-tools/adb


## Log and Run commands
function run () {
	echo "$1"
	$1
}

#echo "Esperando a dispositivo para stremear.."
run "adb wait-for-device"

adb_bin=adb
echo $@
## Regex to understand params
virtual=$(echo $@ | grep -Po '\-v\d' | grep -Po '\d')
device=$(echo $@ | grep -Po '\d+x\d+')
position=$(echo $@ | grep -Po '\-(left|right)' | grep -Po '\w+')
hide_statusbar=$(echo $@ | grep -Po '\-hst')
hide_systembar=$(echo $@ | grep -Po '\-hsb')
orientation=$(echo $@ | grep -Po '\-(vertical|horizontal)' | grep -Po '\w+')

echo $orientation




## Use VIRTUAL1 if none was passed
if [ -z "$virtual" ] ; then
	virtual="VIRTUAL1"
else
	virtual="VIRTUAL${virtual}"
fi
echo $virtual
## Find Android device Resolution, some devices works
if [ -z "$device" ] ; then
	device=$($adb_bin shell dumpsys window displays | grep init | cut -d'=' -f 2 | cut -d' ' -f 1)
fi
if [ -z "$device" ] ; then
	echo "Can't read device resolution using adb"
	#Moto Z Play Vertical
	d_width=456
	d_height=768

	#Moto Z Play Horizontal
	#d_width=768
	#d_height=456

	#Titan Cecilia -Horizontal
	#d_width=1024
	#d_height=600

	#Titan Cecilia -Vertical
	#d_width=600
	#d_height=1024

	#Tablet Kanji Vertical
	#d_width=768
	#d_height=1232

	#Tablet Kanji Horizontal
	#d_width=1232
	#d_height=768



			
			
#	exit 0
else
	## Device width and height
	d_width=$(echo $device | cut -d'x' -f 1)
	d_height=$(echo $device | cut -d'x' -f 2)
	#echo "lei tamaño del dispositivo conectado"


fi

echo "d_width: $d_width"
echo "d_height: $d_height"


if [ "$orientation" = "vertical" ] ; then
	d_width_aux=$(echo $d_width) 
	d_width=$(echo $d_height)
	d_height=$(echo $d_width_aux)
else
	xinerama="xinerama1"
fi



#1232x768_100.00

echo "d_width: $d_width"
echo "d_height: $d_height"



## Check param position, this position is where the user want the new screen
if [ -z "$position" ] ; then
	position="left"
fi
#echo "position= $position"
if [ "$position" = "left" ] ; then
	xinerama="xinerama0"
else
	xinerama="xinerama1"
fi


## Find Host Resolution
host=$(xdpyinfo  | grep 'dimensions:' | cut -d' ' -f 7)
h_width=$(echo $host | cut -d'x' -f 1)
h_height=$(echo $host | cut -d'x' -f 2)



## Find Possible IPs
echo "Possible IPs, use 'ifconfig' to check it out, if you want"
#linux en Ingles..
#ifconfig | grep 'inet addr' | cut -d':' -f 2 | cut -d' ' -f 1
#linux en español..
ifconfig | grep 'Direc. inet' | cut -d':' -f 2 | cut -d' ' -f 1

echo ""




## Proportion, bash don't handle float, only integers so we use bc to do that operation
##proportion=$(($d_height / $h_height))
proportion=$(bc <<< "scale=2; $d_height / $h_height")
v_width=$(bc <<< "scale=0; $d_width / $proportion")
v_height=$h_height
#echo "width   = $v_width"
status_bar=32
system_bar=48
## Remove status bar height
if [ ! -z "$hide_statusbar" ] ; then
	v_height=$(($v_height - $status_bar))
fi
## Remove system bar height
if [ ! -z "$hide_systembar" ] ; then
	v_height=$(($v_height - $system_bar))
fi
#echo "height  = $v_height"


## Build the modeline, the display configurations
modeline=$(cvt $v_width $v_height 60.00 | grep "Modeline" | cut -d' ' -f 2-17)
## Find the mode
mode=$(echo "$modeline" | cut -d' ' -f 1)
## remove quotes, don't need to remove quotes
#mode=${mode//\"}
res=$(echo ${mode//\"} | cut -d'_' -f 1)


## Evaluates the start width position, to clip vnc
#s_width=$(echo $host | cut -d'x' -f 1)
#s_width=$((s_width + 1))
#echo "s_width = $s_width"

#echo $modeline
#echo $mode

echo "device  = $device"
#echo "width   = $d_width"
#echo "height  = $d_height"

echo "host    = $host"
#echo "width   = $h_width"
#echo "height  = $h_height"
echo "scale   = $proportion"

echo "Display = $virtual"

echo "virtual = $res"
echo ""	


#en caso que este conectado por usb se puede utilizar:
echo "Habilito en la tablet el Forwading.."
run "adb reverse tcp:5901 tcp:5901"
run "adb reverse --list"

## Create Virtual Display
echo "Creo el display Virtual VIRTUAL1.."
run "xrandr --newmode $modeline"
run "xrandr --addmode $virtual $mode"
run "xrandr --output $virtual --mode $mode --${position}-of ${fisical}"


## Start VNC
#si el cliente VNC soporta -ncache:		 -ncache 7 -ncache_cr
#run "x11vnc -clip ${xinerama} -xrandr -ncache 1 -nosel -viewonly -fixscreen \"V=2\" -noprimary -nosetclipboard -noclipboard -cursor arrow -nopw -nowf -nonap -noxdamage -sb 0 -display :0"
#si el cliente VNC no soporta -ncache:
echo "Ejecuto el servicio del monitor Externo con VNC.."
#run "x11vnc -clip ${xinerama} -ncache_cr -xrandr -nosel -xd_area 0 -fixscreen \"V=2\" -noprimary -nosetclipboard -noclipboard -cursor arrow -nopw -nowf -nonap -noxdamage -sb 0 -display :0"
run "x11vnc -clip ${xinerama} -ncache_cr -xrandr -noprimary -nosetclipboard -noclipboard -cursor arrow  -usepw -display :0 -ultrafilexfer -noxdamage"

## Turn VirtualDisplay off
echo "Desactivo el display Virtual VIRTUAL1.."
run "xrandr --output $virtual --off"
run "xrandr --delmode $virtual $mode"
run "xrandr --rmmode $mode"
run "xrandr -s 0"

##Disable port for Reverse:
echo "si todavia esta conectada la tablet, elimino el Forwading.."
run "adb reverse --remove tcp:5901"


#y luego conectarse a localhost:5901 desde el cliente
#Referencia: http://www.codeka.com.au/blog/2014/11/connecting-from-your-android-device-to-your-host-computer-via-adb