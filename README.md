# hackatom6-stash-controller-workshop

Stash and Controller workshop support material.

## Get Started

You should open 2 terminal tabs.

- In the 1st terminal:

```bash
cd step1
./hackatom-node.sh
```

This will run a local node with a single validator, called `ALICE`. Wait for the node to produce blocks before moving on to the next step.

- In the 2nd terminal:

```bash
cd step2
./hackatom-stash-controller.sh
```

This will perform a set of commands against the running node. Each action in the Bash script comes with some comments.
