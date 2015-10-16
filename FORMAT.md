# xtcutil JSON format

xtcutil extracts information from xtrkcad file as JSON.
This file explains the details of the JSON format.

## Overall structure

A xtrkcad file contains a model railroad layout.
A railroad layout consists of parts.
A part consists of edges.
A part has one or more states.
A part defines paths which is a sequence of edges.
A path belong to a state.
The path is usable only if the state of the part is the state.
A edge connect between two nodes.
A node is shared by several edges.

`xtcutil graph foo.xtc' generates an array of objects.
The object has "type" member and it distinguish the type of the object.
The value of "type" member is one of follows.

- "node"
- "edge"
- "straightline"
- "curveline"
- "part"
- "path"

The position is represented in rectangular coordinate system.
In a 2D image, the positive X axis heads left and
the positive Y axis heads upper.
Z axis is also used.

Angles in X-Y plane are represented in radian.
0 means positive X axis.
pi/2 means positive Y axis.

## node object

A node object has following members.

- type: "node"
- name: NNAME           # the name of the node
- degree: INTEGER       # the number of the edges connected to this node
- pos: [X, Y, Z]        # the position of this node as 3-element array
- max_gap: NUMBER       # ideally this should be zero.  maximum distance to the connected edges. (debug)
- comments: [STRING, ...]       # comments (debug)

"Change Elevations" command of xtrkcad can specify the height of a node.
It is used as Z value of pos member.
The heights are interpolated to nodes which height is not specified.
However the interpolation alogrighm is different from xtrkcad, the result can be different.

The name of the node, NNAME, is also specifiable from xtrkcad using "Change Elevations".
Choose "Station" to specify the name of the node.
If it is not specified, xtcutil generate the name automatically.

## edge object

A edge connects two nodes: node0 and node1.
A edge object has following members.

- type: "edge"
- name: ENAME           # the name of the edge
- part: "T{INDEX}"      # the name of the part which contains this edge
- angle0: NUMBER        # the angle of direction at node0
- pos0: [X, Y, Z]       # the position of node0 as 3-element array
- node0: NNAME          # the name of node0
- node1: NNAME          # the name of node1
- pos1: [X, Y, Z]       # the position of node1 as 3-element array
- angle1: NUMBER        # the angle of direction at node1
- distance: NUMBER      # the distance between node0 and node1 through this edge

There is straightline or curveline object for each edge to represent actual
shape of the edge.

## straightline object

A straightline object has following members.

- type: "straightline"
- name: ENAME           # the name of the edge

## curveline object

A curveline represents an arc.
A curveline object has following members.

- type: "curveline"
- name: ENAME           # the name of the edge
- center: [X, Y]        # the center of the arc as 2-element array
- radius: NUMBER        # the radius of the arc.
- angle0: NUMBER        # the start angle
- angle1: NUMBER        # the end angle

angle0 < angle1.

## part object

A part represents a part which contains several edges.
A part object has following members.

- type: "part"
- part: "T{INDEX}"      # the name of the part
- numstates: INTEGER    # the number of states of this part

numstates is 1 for usual tracks and 2 for usual switches.
A turntable may have more states.
Actual state names can be obtained from corresponding path objects.

## path object

A path represents a path in a part.
A path object has following members.

- type: "part"
- part: "T{INDEX}"      # the name of the part
- state: STRING         # the name of the state
- edges: [[0 or 1, ENAME], ...] # the edges of the path.

A path object means the specified edges are connected when the state is STRING
given by the state member.

If [[0, edgeA], [1, edgeB]] is specified and the state of the part enables this path,
a train can pass from edgeA's node0 to edgeA's node1 (same as edgeB's node1) via edgeA and
from edgeB's node1 to edgeB's node0 via edgeB.
