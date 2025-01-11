% Example input facts
width(8).
position(0..63).  % for an 8x8 map
wall(0;1;2).      % wall positions
initial_sokoban(10).
initial_crate(20;21).
goal(30;31).
#const maxsteps = 20.  % maximum solution length