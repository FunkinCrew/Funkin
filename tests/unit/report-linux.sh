#!/bin/bash

cd ./report/
genhtml -o ./html/ ./lcov.info
