#!/bin/bash

	# if [[ "$1" ]] ; then
	# 	SRCDIR="$( cd $1 && pwd )"
	# else
	# 	GITDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	# 	SRCDIR="$GITDIR/src"
	# fi

	# if [[ "$2" ]]; then
	# 	docker run --rm -ti -v "$SRCDIR":/usr/app/src --device="$2":/dev/ttyS0 pcs3412_pcs3212
	# else
	# 	docker run --rm -ti -v "$SRCDIR":/usr/app/src pcs3412_pcs3212
	# fi


IMAGE="$(docker ps -q -f ancestor=pcs3412_pcs3212)"

# if [[ $IMAGE ]] ; then
# 	docker-compose up 
# else

if [[ "$1" ]] ; then
	SRCDIR="$( cd $1 && pwd )"
else
	GITDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	SRCDIR="$GITDIR/src"
fi

# xhost + local:docker

if [[ "$2" ]]; then
	docker run --rm -ti -v "$SRCDIR":/usr/app/src --device="$2":/dev/ttyS0 pcs3412_pcs3212
else
	docker run --rm -ti -v "$SRCDIR":/usr/app/src pcs3412_pcs3212
fi
# fi