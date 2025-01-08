import clingo

def solve():
    asp_code_base = """
        #include <incmode>.
        #program base.
        % Определение локаций
        location(loc1;loc2;loc3).
        % Определение направлений
        direction(dir_left;dir_right).
        % Определение игрока и камня
        player(p1).
        stone(s1).
        % Определение возможных перемещений между локациями
        movedir(loc1,loc2,dir_right).
        movedir(loc2,loc1,dir_left).
        movedir(loc2,loc3,dir_right).
        movedir(loc3,loc2,dir_left).
        % Начальное состояние
        init(at(p1,loc1)).
        init(at(s1,loc2)).
        init(clear(loc3)).
        % Целевое состояние
        goal(at(s1,loc3)).
        % Начальное состояние переносится в holds на шаге 0
        holds(F,0) :- init(F).
    """

    asp_code_step = """
        #program step(t).
        % Generate - генерация возможных действий
        1 <= { move(p1,X,Y,t) : location(X), location(Y), movedir(X,Y,D), holds(at(p1,X),t-1) } <= 1.
        1 <= { push(s1,X,Y,Z,t) : location(X), location(Y), location(Z), 
          movedir(X,Y,D), movedir(Y,Z,D), 
          holds(at(p1,X),t-1), holds(at(s1,Y),t-1), holds(clear(Z),t-1) } <= 1.
        
        % Test - проверка корректности действий
        :- move(p1,X,Y,t), holds(at(s1,Y),t-1).
        :- move(p1,_,Y,t), push(s1,_,_,_,t).
        :- push(s1,_,_,_,t), move(p1,_,_,t).
        
        % Define - определение результатов действий
        % Для движения игрока
        holds(at(p1,Y),t) :- move(p1,X,Y,t).
        holds(clear(X),t) :- move(p1,X,Y,t).
        % Для толкания камня
        holds(at(p1,Y),t) :- push(s1,X,Y,Z,t).
        holds(at(s1,Z),t) :- push(s1,X,Y,Z,t).
        holds(clear(X),t) :- push(s1,X,Y,Z,t).
        
        % Сохранение состояний, если не было изменений
        holds(at(O,L),t) :- holds(at(O,L),t-1), not holds(clear(L),t), location(L), (player(O) ; stone(O)).
        holds(clear(L),t) :- holds(clear(L),t-1), not holds(at(_,L),t), location(L).
    """

    asp_code_check = """
        #program check(t).
        #external query(t).
        % Test - проверка достижения цели
        :- query(t), goal(F), not holds(F,t).
        #show move/4.
        #show push/5.
    """

    def on_model(model):
        print("Found solution:", model)

    max_step = 10
    control = clingo.Control()
    control.configuration.solve.models = 1

    # add each #program
    control.add("base", [], asp_code_base)
    control.add("step", ["t"], asp_code_step)
    control.add("check", ["t"], asp_code_check)

    parts = []
    parts.append(("base", []))
    control.ground(parts)

    ret, step = None, 1
    while step <= max_step and (step == 1 or not ret.satisfiable):
        parts = []
        control.release_external(clingo.Function("query", [clingo.Number(step - 1)]))
        parts.append(("step", [clingo.Number(step)]))
        parts.append(("check", [clingo.Number(step)]))
        control.cleanup()
        control.ground(parts)
        control.assign_external(clingo.Function("query", [clingo.Number(step)]), True)
        print(f"Solving step: t={step}")
        ret = control.solve(on_model=on_model)
        print(f"Returned: {ret}")
        step += 1

if __name__ == "__main__":
    try:
        solve()
    except Exception as e:
        print(f"An error occurred: {e}")