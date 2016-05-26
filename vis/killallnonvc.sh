ps x | grep noVNC | awk '{ print $1 }' | xargs -n 1 kill -9 
