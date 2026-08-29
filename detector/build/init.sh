#!/usr/bin/env bash

BUILD_DIR=${PWD}
export STDVIEW_45=/classes/ece6745/install/adks/freepdk-45nm/stdview

cp ../test/detector-test.py ./01-cocotb-rtl-sim
cp ../test/detector-test.py ./03-cocotb-gl-sim
cp ../test/detector-test.py ./05-cocotb-ba-sim

cp ../test/detector-fl.py ./01-cocotb-rtl-sim
cp ../test/detector-fl.py ./03-cocotb-gl-sim
cp ../test/detector-fl.py ./05-cocotb-ba-sim