import clingo

def solve():
    asp_code_base = """
        #include <incmode>.
        #program base.
        
        % Определение игрока
        player(p1).
        
        % Определение камня
        stone(s1).
        
        % Определение локаций (три клетки в ряд)
        location(loc1;loc2;loc3).
        
        % Определение целевых и не-целевых локаций
        isgoal(loc3).
        isnongoal(loc1;loc2).
        
        % Направления движения между локациями
        movedir(loc1,loc2,dir_right).
        movedir(loc2,loc1,dir_left).
        movedir(loc2,loc3,dir_right).
        movedir(loc3,loc2,dir_left).
        
        % Начальное состояние
        init(at(p1,loc1)). % игрок в левой клетке
        init(at(s1,loc2)). % камень в средней клетке
        init(clear(loc3)). % правая клетка пуста
        
        % Целевое состояние
        goal(at(s1,loc3)). % камень должен быть в правой клетке
        
        % Определение начального состояния
        holds(F,0) :- init(F).
        
        % Вспомогательные предикаты для камней
        stone_at_goal(S,0) :- stone(S), at(S,L), isgoal(L).
        stone_not_at_goal(S,0) :- stone(S), at(S,L), isnongoal(L).
        
        % Определение свободных клеток в начальном состоянии
        clear(L,0) :- location(L), not at(_,L).
    """

    asp_code_step = """
        #program step(t).
        
         {
            move(P,From,To,Dir,t) : 
                player(P),
                movedir(From,To,Dir),
                From != To;
            pushtonongoal(P,S,Ppos,From,To,Dir,t) : 
                player(P),
                stone(S),
                movedir(Ppos,From,Dir),
                movedir(From,To,Dir),
                isnongoal(To),
                Ppos != To,
                Ppos != From,
                From != To;
            pushtogoal(P,S,Ppos,From,To,Dir,t) :
                player(P),
                stone(S),
                movedir(Ppos,From,Dir),
                movedir(From,To,Dir),
                isgoal(To),
                Ppos != To,
                Ppos != From,
                From != To;
            noop(t)
        } = 1.

        % Предусловия и эффекты (как в вашем коде)
        % [здесь идут все правила предусловий и эффектов]
        
        % Инерция
        holds(F,t) :- holds(F,t-1), not del(F,t).
    """

    asp_code_check = """
        #program check(t).
        #external query(t).
        
        % Проверка достижения цели
        :- query(t), goal(F), not holds(F,t).
        
        % Показываем все возможные действия
        #show move/5.
        #show pushtonongoal/7.
        #show pushtogoal/7.
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