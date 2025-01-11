%% Robert Belanec
%% I have tried to write the code as much self-explanatory as possible.

%% Main function. To start query this function in swipl.
%% +MapFile
main(MapFile):-
    process_file(MapFile, S0, G),

    write('S0 = '),
    writeln(S0),

    write('G = '),
    writeln(G),

    find_plan(S0, G, s(0), Plan),

    write('Plan = '),
    writeln(Plan).

natural(0).
natural(s(X)):- natural(X).

%% Process file into list and get S0 and G
%% +File, -S0out, -G
process_file(File, S0out, G):-
    open(File, read, Fd),
    get_map_width(Fd, Width),

    writeln('Current map:'),
    seek(Fd, 0, bof, _),        %% return to begining of the file
    read_file(Fd, [], Map),
    seen(),
    
    write('\n\n'),

    get_S0(0, Width, Map, [], S0),
    get_G(S0, G),
    append(S0,[width(Width)],S0out).

%% Read file until EOF.
%% +Fd, +Map, -Map
read_file(Fd, Map, Map):-
    at_end_of_stream(Fd).

read_file(Fd, Map, FinalMap):-
    \+ at_end_of_stream(Fd),

    get_char(Fd, C),
    process_char(C, Map, NewMap),
    read_file(Fd, NewMap, FinalMap).

%% Append character from file into the map list
%% +Map, -Map
process_char('#', Map, NewMap):-
    append(Map, ['#'], NewMap),
    write('#').

process_char('\n', Map, Map):-
    write('\n').

process_char(' ', Map, NewMap):-
    append(Map, [' '], NewMap),
    write(' ').

process_char('C' ,Map, NewMap):-
    append(Map, ['C'], NewMap),
    write('C').

process_char('c' ,Map, NewMap):-
    append(Map, ['c'], NewMap),
    write('c').

process_char('X', Map, NewMap):-
    append(Map, ['X'], NewMap),
    write('X').

process_char('S', Map, NewMap):-
    append(Map, ['S'], NewMap),
    write('S').

process_char('s', Map, NewMap):-
    append(Map, ['s'], NewMap),
    write('s').

%% Get length of the first line
%% +Fd, -Width
get_map_width(Fd, Width):-
    read_line_to_codes(Fd,Line),
    length(Line,Width).

%% Get fluents(next, free, crates, sokoban, X) from map, to create S0
%% +Pos, +Width, +Map, +S0, -S0
get_S0(Pos, _, Map, S0, S0):-
    length(Map, MapSize),
    Pos is MapSize.

get_S0(Pos, Width, Map, S0, NewS0):-
    get_next_right(Pos, Map, S0, NewRightS0),
    get_next_left(Pos, Map, NewRightS0, NewLeftS0),
    get_next_up(Pos, Width, Map, NewLeftS0, NewUpS0),
    get_next_down(Pos, Width, Map, NewUpS0, NewDownS0),

    get_free(Pos, Map, NewDownS0, NewFreeS0),
    get_crate(Pos, Map, NewFreeS0, NewCS0),
    get_sokoban(Pos, Map, NewCS0, NewSS0),
    get_x(Pos, Map, NewSS0, NewXS0),

    NewPos is Pos + 1,
    get_S0(NewPos, Width, Map, NewXS0, NewS0),!. %% we have also used cut operator to prevent backtracking as we want only the frist solution

%% Check if current position is free and append it to S0 if yes
%% +Pos, +Map, +S0, -S0
get_free(Pos, Map, S0, NewS0):-
    nth0(Pos, Map, C),
    C \== '#',
    C \== 'C',
    C \== 'c',
    C \== 'S',
    C \== 's',

    append(S0, [free(Pos)], NewS0),!.

get_free(_, _, S0, S0).

%% Check if current position and its neighbors are connected, if yes append next to S0
%% +Pos, +Map, +S0, -S0
get_next_right(Pos, Map, S0, NewS0):-
    nth0(Pos, Map, C),
    C \== '#',

    NextPos is Pos + 1,
    nth0(NextPos, Map, NextC),
    NextC \== '#',

    \+ member(next(Pos, NextPos), S0),
    \+ member(next(NextPos, Pos), S0),

    append(S0, [next(Pos, NextPos), next(NextPos, Pos)], NewS0),!.

get_next_right(_, _, S0, S0).

get_next_left(Pos, Map, S0, NewS0):-
    nth0(Pos, Map, C),
    C \== '#',

    NextPos is Pos - 1,
    nth0(NextPos, Map, NextC),
    NextC \== '#',

    \+ member(next(Pos, NextPos), S0),
    \+ member(next(NextPos, Pos), S0),

    append(S0, [next(Pos, NextPos), next(NextPos, Pos)], NewS0),!.

get_next_left(_, _, S0, S0).

get_next_up(Pos, Width, Map, S0, NewS0):-
    nth0(Pos ,Map, C),
    C \== '#',

    NextPos is Pos - Width,
    nth0(NextPos, Map, NextC),
    NextC \== '#',

    \+ member(next(Pos, NextPos), S0),
    \+ member(next(NextPos, Pos), S0),


    append(S0, [next(Pos, NextPos), next(NextPos, Pos)], NewS0),!.

get_next_up(_, _, _, S0, S0).

get_next_down(Pos, Width, Map, S0, NewS0):-
    nth0(Pos, Map, C),
    C \== '#',

    NextPos is Pos + Width,
    nth0(NextPos, Map, NextC),
    NextC \== '#',

    \+ member(next(Pos, NextPos), S0),
    \+ member(next(NextPos, Pos), S0),

    append(S0, [next(Pos, NextPos), next(NextPos, Pos)], NewS0),!.

get_next_down(_, _, _, S0, S0).


%% Check if current position is crate, if yes append next to S0
%% +Pos, +Map, +S0, -S0
get_crate(Pos, Map, S0, NewS0):-
    nth0(Pos, Map, C),
    C == 'C',

    \+ member(at(C, Pos), S0),
    append(S0, [at(C, Pos)], NewS0),!.

get_crate(Pos, Map, S0, NewS0):-
    nth0(Pos, Map, C),
    C == 'c',

    \+ member(at('C', Pos), S0),
    \+ member(at('X', Pos), S0),

    append(S0, [at('C', Pos)], NewCS0),
    append(NewCS0, [at('X', Pos)], NewS0),!.

get_crate(_, _, S0, S0).

%% Check if current position is sokoban, if yes append next to S0
%% +Pos, +Map, +S0, -S0
get_sokoban(Pos, Map, S0, NewS0):-
    nth0(Pos, Map, C),
    C == 'S',

    \+ member(at(C, Pos), S0),
    append(S0, [at(C, Pos)], NewS0),!.

get_sokoban(Pos, Map, S0, NewS0):-
    nth0(Pos, Map, C),
    C == 's',

    \+ member(at('S', Pos), S0),
    \+ member(at('X', Pos), S0),

    append(S0, [at('S', Pos)], NewSS0),
    append(NewSS0, [at('X', Pos)], NewS0),!.

get_sokoban(_, _, S0, S0).

%% Check if current position is X, if yes append next to S0
%% +Pos, +Map, +S0, -S0
get_x(Pos, Map, S0, NewS0):-
    nth0(Pos, Map, C),
    C == 'X',

    \+ member(at(C, Pos), S0),
    append(S0, [at(C, Pos)], NewS0),!.

get_x(_, _, S0, S0).

get_pos(at(_,X),X).

%% Change C to X to get the goal state
%% +S0, -G
get_G(S0,G):-
    delete_list([at('X',_)],S0,Del), %% Delete X
    subtract(S0, Del, Xs), %% get X only by substrating the S0 and deleted X
    x_to_c(Xs,G). %% change X to to C

x_to_c([],[]).
x_to_c([X|Xs],Cs):- get_pos(X, Y), append(Ys, [at('C',Y)], Cs), x_to_c(Xs, Ys),!.

is_subset([],_).
is_subset([X|Xs], Ys):- member(X, Ys), is_subset(Xs, Ys).

delete_list([],Xs,Xs).
delete_list([X|Xs], Ys, Zs):- delete(Ys, X, As), delete_list(Xs, As, Zs).

get_p(pushable(X,Y),X,Y).


%% Check if pushable is valid (if next with pushable values exists)
%% +Pushable, +S, -ValidPushable 
valid_pushable([],_,[]).
valid_pushable([P|Px], S, ValidPushable):-
    get_p(P, X, Y),
    \+ member(next(X, Y), S),
    valid_pushable(Px, S, ValidPushable).

valid_pushable([P|Px], S, ValidPushable):-
    get_p(P, X, Y),
    member(next(X, Y), S),
    append(ValidPushableY, [pushable(X,Y)], ValidPushable),
    valid_pushable(Px, S, ValidPushableY),!.

%% Create pushables based on sokoban location
%% +S, +Pushable, -Pushable     
get_pushables(S, Pushable, NewPushable):-
    member(at('S',X), S),
    member(width(Width), S),

    X1right is X + 1,
    X2right is X + 2,
    append(Pushable,[pushable(X1right,X2right)],NewPushableRight),

    X1left is X - 1,
    X2left is X - 2,
    append(NewPushableRight,[pushable(X1left,X2left)],NewPushableLeft),

    X1up is X + Width,
    X2up is X + 2*Width,
    append(NewPushableLeft,[pushable(X1up,X2up)],NewPushableUp),

    X1down is X - Width,
    X2down is X - 2*Width,
    append(NewPushableUp,[pushable(X1down,X2down)],NewPushableDown),

    valid_pushable(NewPushableDown, S, NewPushable).

%% Delete pushables
%% +State, -NewState
del_pushables([],[]).
del_pushables([S|Sx], NewS):-
    get_p(S,_,_),
    del_pushables(Sx,NewS).

del_pushables([S|Sx], NewS):-
    \+ get_p(S,_,_),
    append(NewSY,[S],NewS),
    del_pushables(Sx,NewSY),!.

find_plan(S0, G, Steps, Plan):-
    solve(S0, G, [], Steps, Plan).

find_plan(S0, G, Steps, Plan):-
    \+ solve(S0, G, [], Steps, _),
    find_plan(S0, G, s(Steps), Plan).

%% Planning solver
solve(State, Goal, Plan, _, Plan):- is_subset(Goal, State).

solve(State, Goal, Sofar, s(X), Plan):-
    del_pushables(State,S),
    get_pushables(S,[],P),
    append(S,P,PushableState),

    opn(Op, Prec, Add, Delete),
    is_subset(Prec, PushableState),
    delete_list(Delete, PushableState, Output),
    append(Add, Output, NewState),
    append(Sofar, [Op], NewSofar),
    solve(NewState, Goal, NewSofar, X, Plan).

%% Actions
%% name, preconditions, add, delete
opn( move(X,Y),
     [ at('S',X), free(Y), next(X,Y)],
     [ at('S',Y), free(X) ],
     [ at('S',X), free(Y) ]
    ).

opn( push(Z,X,Y),
     [ at('C',X), free(Y), pushable(X,Y), at('S', Z) ],
     [ at('C',Y), at('S',X), free(Z) ],
     [ free(Y), at('C',X), pushable(X,Y), at('S',Z) ]
    ).