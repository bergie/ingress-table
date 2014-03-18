Ingress Table
=============

The software side of a "physical Intel map", built with [NoFlo](http://noflojs.org) and [MicroFlo](http://microflo.org).

## How does this work?

We have a NoFlo graph that periodically pulls portal status information from a cloud-based data provider, and converts that to status information to be shown on the table surface.

The status information is then transmitted to a microcontroller that shows portal owners, attack notifications, etc. using the LEDs.

## Starting and Stopping the Service

This is the configuration file for supervisord (needs to be installed through apt-get install supervisor):. Filename: /etc/supervisor/conf.d/ingress-table.conf

    [program:ingress_table]
    command=node ./node_modules/.bin/noflo graphs/bgt9b.json
    directory=/home/ubuntu/ingress-table
    stdout_logfile=/home/ubuntu/ingress_table_output.txt
    redirect_stderr=true
    autostart=true
    user=ubuntu
    stopwaitsecs=2

The stopwaitsecs=2 is there because we need to do a kill -9 after the service is stopped.

You can start/stop the service using these commands:

    supervisorctl start ingress_table
    supervisorctl stop ingress_table



## Hardware

* Beaglebone Black running NoFlo
* Launchpad Tiva running MicroFlo
* Individually controllable LEDs for portals
* LED strips for street and floor lighting
* USB chargers for agents running out of battery

## LED strip i/o pins

```
J2
---

(was PF0 Red1) but is also connected to reset btn
PB7 Green1
PB6 Blue1

PA2 -> SSI0Clk => Portallights Clock (CKI)

J4
---

PF3 Red2
PC4 Green2
PC5 Blue2

PF2 Red Bottom

J3
---

PD0 Red3
PD1 Green3
PF1 Blue3

J1
---
PB4 Red1
PB5 Red4
PE4 Green4
PE5 Blue4

PA6 Green Bottom
PA7 Blue Bottom

PA5 -> SSI0Tx => Portallights Data (SDI)
```

**Note**: out-of-the box on the Tiva the pins PB6, PB7, PD0, PD1 can't be used. You [can disconnect the R9 and R10 resistors](http://e2e.ti.com/support/microcontrollers/tiva_arm/f/908/t/290329.aspx) to make them usable.
