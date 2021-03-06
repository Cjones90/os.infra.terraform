#!/bin/bash

DELAY_BETWEEN_SERVICE_REMOVAL=5

SLEEP_FOR_X_AFTER_DRAIN=15
SLEEP_FOR_X_AFTER_DEMOTION=5

while getopts "fzm:i:r:" flag; do
    # These become set during 'getopts'  --- $OPTIND $OPTARG
    case "$flag" in
        f) FORCE_LEAVE=true;;
        r) ROLE=$OPTARG;;
        z) DO_NOTHING=true;;
    esac
done

### Purely used to bypass the whole script if any of the previous steps were done
###  but still need to run the destroy provisioner
if [ $DO_NOTHING ]; then exit 0; fi;

DOCKER_MACHIVE_TO_REMOVE=`hostname`

if [ -z "$ROLE" ]; then echo "Please provide a role with the -r flag   '-r ROLE'"; exit 1; fi

#### Only managers and web roles are part of a docker swarm
if [ "$ROLE" != "manager" ] && [ "$ROLE" != "web" ]; then
    echo "Only roles 'manager' and 'web' are acceptable roles to leave the swarm at the moment."
    exit 0;
fi

##### TODO: For now all we use are managers. Once we start wanting to use workers then
#####    we need to revisit the best way for a worker gracefully exit the swarm FROM the worker
#####    as workers cannot update services/nodes.
##### We most likely need to look for a manager to perform the actions and adjust this script accordingly
if [ "$ROLE" = "web" ]; then echo "We are leaving the swarm directly without pre-emptive updates to services/nodes"; exit 1; fi


#### TODO: If we're the last member of a swarm we get stuck trying to place a constraint
####   on ourselves
if [ "$ROLE" = "manager" ]; then
    #### TODO: If we're the last member of a swarm we get stuck trying to place a constraint
    ####   on ourselves
    #### We're still experimenting with just draining the node, waiting a bit,
    ####   then leaving vs rebalancing ALL services across ALL nodes (this would
    ####   scale poorly) now that we handle healthchecks properly and updated docker
    ####   that fixed a crucual internal load balancing bug
    # for SERVICE_NAME in `docker service ls --format "{{.Name}}"`; do
    #     echo "Adding restraint to remove $SERVICE_NAME from $DOCKER_MACHIVE_TO_REMOVE";
    #     docker service update $SERVICE_NAME --constraint-add "node.hostname != $DOCKER_MACHIVE_TO_REMOVE";
    #     echo "Finished removing $SERVICE_NAME from $DOCKER_MACHIVE_TO_REMOVE";
    #     echo "Sleeping $DELAY_BETWEEN_SERVICE_REMOVAL seconds for graceful re-balance";
    #     sleep $DELAY_BETWEEN_SERVICE_REMOVAL;
    # done

    echo "Draining $DOCKER_MACHIVE_TO_REMOVE"
    docker node update --availability="drain" $DOCKER_MACHIVE_TO_REMOVE
    sleep $SLEEP_FOR_X_AFTER_DRAIN

    #### See above
    # for SERVICE_NAME in `docker service ls --format "{{.Name}}"`; do
    #     echo "Removing constraint for $SERVICE_NAME";
    #     docker service update $SERVICE_NAME --constraint-rm "node.hostname != $DOCKER_MACHIVE_TO_REMOVE";
    #     echo "Finished removing constraint for $SERVICE_NAME";
    #     # echo "Sleeping 5 seconds for graceful re-balance";
    #     # sleep 5;
    # done

    echo "Demoting $DOCKER_MACHIVE_TO_REMOVE"
    docker node demote $DOCKER_MACHIVE_TO_REMOVE
    sleep $SLEEP_FOR_X_AFTER_DEMOTION
fi


## I assume if we leave successfully its exit 0
echo "Leaving swarm"
docker swarm leave


### Let us just leave and move on
if [[ $FORCE_LEAVE ]]; then
    docker swarm leave --force
    exit 0;
fi
