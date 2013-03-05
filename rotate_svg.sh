#!/bin/bash

function error {
  echo "ERROR: $1"
  echo ""
  echo "usage: $0 <right || left> <source directory> <target directory>"
  exit 1
}

#
# configuration
#
inkscape_path="/Applications/Inkscape.app/Contents/Resources/bin/inkscape"

#
# parameters
#

source_dir=$(cd "$2" 2>/dev/null && echo `pwd`)
if [[ ! -d "$source_dir" ]]; then
  error "source directory doesn't exist"
fi

target_dir=$(cd "$3" 2>/dev/null && echo `pwd`)
if [[ ! -d "$target_dir" ]]; then
  error "target directory doesn't exist"
fi

# choose rotate verb for inskape or throw error if angle parameter is not supported
if [ "$1" = "right" ]; then
  inkscape_verb_rotate="ObjectRotate90"
elif [ "$1" = "left" ]; then
  inkscape_verb_rotate="ObjectRotate90CCW"
else
  error "rotation angle not supported"
fi

#
# processing svg files
#
echo "* processing files in $source_dir"

if [ "$(ls -A "$source_dir/"*.svg 2>/dev/null)" = "" ]; then
  error "source directory is empty"
fi

for source_svg_path in "$source_dir/"*.svg
do
  svg_filename=$(basename $source_svg_path)
  target_svg_path="$target_dir/$svg_filename"

  echo "* rotate $svg_filename"

  if [ "$source_svg_path" != "$target_svg_path" ]; then
    cp -f "$source_svg_path" "$target_svg_path" > /dev/null 2> /dev/null
  fi
  `$inkscape_path $target_svg_path --verb=EditSelectAll --verb=SelectionGroup --verb=$inkscape_verb_rotate --verb=FitCanvasToSelectionOrDrawing --verb=FileSave --verb=FileClose > /dev/null  2>/dev/null`
done

exit 0;
