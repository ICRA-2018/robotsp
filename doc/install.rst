*******
Install
*******

The following instructions have been tested in **Ubuntu 16.04** (Xenial), 64
bits.

ROS Kinetic
===========

Set-up your computer to accept software from *packages.ros.org* and set-up your
keys following the steps described at
http://wiki.ros.org/kinetic/Installation/Ubuntu

Now, install the ROS bare bones::

  # Installation
  sudo apt-get update
  sudo apt-get install python-rosdep python-wstool ros-kinetic-ros-base
  # Initialize rosdep
  sudo rosdep init
  rosdep update

OpenRAVE
========

OpenRAVE is one of the most powerful existing simulation and motion planning
environments. It is widely used in academia and industry.

Here you can find the *automated* installation scripts:
https://github.com/crigroup/openrave-installation

.. note:: If the *automated* method fails, you can try the manual method:
  https://crigroup.gitbooks.io/osrobotics/content/installation/motion_planning.html

ROS Package installation
========================

Go to your ROS working directory::

  cd ~/catkin_ws/src

Use ``wstool`` to download the required repositories::

  wstool init .
  wstool merge https://raw.github.com/crigroup/robotsp/master/robotsp.rosinstall
  wstool update

Install any missing dependencies using rosdep::

  rosdep update
  rosdep install --from-paths . --ignore-src -y

Now, compile your ROS workspace::

  cd ~/catkin_ws && catkin_make

Testing the Installation
========================

Make sure you always source the appropriate ROS setup file, e.g::

  source ~/catkin_ws/devel/setup.bash

The following will run the tests of the ``robotsp`` package::

  roscd robotsp/tests
  nosetests -v
