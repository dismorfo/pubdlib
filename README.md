This codebase reads a wip and imports a photo document into the dlts_photo collection for the viewer workflow. It is part of the image publishing workflow.

To get an overview of the full image publishing workflow, please see here: [Photo_Publishing_Workflow](./Photo_Publishing_Workflow.md)

Links within the README:
* [Script Setup](#script-setup)
* [Workflow Setup](#workflow-setup)
* [Wrapper Script](#the-wrapper-script)
* [Call script directly](#calling-the-script-directly)

## Requirements
#### Ruby version 2.7.3

## Script Setup
* Install rvm, if not present, from [here](https://rvm.io/rvm/install)
* Install ruby v.2.4.1: `$ rvm install ruby 2.7.3`
* The .ruby-gemset file in the directory will automatically create a gemset
* Install bundle: `gem install bundle`
* Install required gems by running the command: `$ bundle`

## Workflow Setup
* The publishing workflow can be run two ways: either with a wrapper script or calling the script directly.

#### The wrapper script
* The wrapper script requires an input directory with specific files. For example: if a directory called publish-me is created, the following files are needed:

```
$ ls publish-me
se_list
wip_path
collection_url
```

* **se_list**: list of SEs to be published
* **wip_path**: /path to wip/
* **collection_url**: /collection url/
* The script then should be called the following way:
* cd /to/viewer_photo/repo
* ruby import_photo.rb /path/to/publish-me import-type-parameter
* mongo only
* only updates the mongo database, does not create jsons which will populate the viewer database
* all
* updates the mongo database and generates jsons
* drupal only
* only generates jsons

#### Calling the script directly
If the user doesn't want to use the wrapper script, the script can be called directly by specifying the following parameters:
* with import type parameter **all**:
* `ruby run_import_photo.rb -p /path/to/wip -i "all" -f /path/to/file/containing/se_list -c "path/to/collection url"`
* with import type parameter **drupal only**:
* `ruby run_import_photo.rb -p /path/to/wip -i "drupal only" -f /path/to/file/containing/se_list -c "path/to/collection  url"`
* with import type parameter **mongo only**:
* `ruby run_import_photo.rb -p /path/to/wip -i "mongo only" -f /path/to/se_list`
