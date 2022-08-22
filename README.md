# Viewer workflow.

Links within the README:
* [Script Setup](#script-setup)
* [Workflow Setup](#workflow-setup)
* [Wrapper Script](#the-wrapper-script)
* [Call script directly](#calling-the-script-directly)

## Requirements
#### Ruby version 2.7.6

## Script Setup
* Install rvm, if not present, from [here](https://rvm.io/rvm/install)
* Install ruby v.2.7.6: `$ rvm install ruby 2.7.6`
* The .ruby-gemset file in the directory will automatically create a gemset
* Install bundle: `gem install bundle`
* Install required gems by running the command: `$ bundle`

## Workflow Setup
* The publishing workflow can be run two ways: either with a wrapper script or calling the script directly.
