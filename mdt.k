module MDT-SYNTAX

	/*
	 * TM states
	 */
	syntax States ::= List{Int, ","}

	/*
	 * TM Final state declaration
	 */
	syntax FinalState ::= "Final" ":" Int
	
	/*
	 * TM Initial state declaration
	 */
	syntax InitialState ::= "Initial" ":" Int

	syntax Movement ::= "L" | "R" | "-"

	/*
	 * TM Transitions declaration
	 */
	syntax Transition ::= "(" Int "," String "," Int "," String "," Movement ")"
						|	Transition Transition [left]

	/*
	 * Initial tape declaration
	 */
	syntax InitialTape ::= List{String, ","}

    /*
     * Program structure
     */
	syntax Program ::= States FinalState InitialState Transition InitialTape

endmodule


module MDT
	imports MDT-SYNTAX

	/*
	 * Transitions-configuration map key
	 */
	syntax K ::= "(" Int "," String ")"
	
	/*
	 * Transitions-configuration map value
	 */
	syntax K ::= "(" Int "," String "," Movement ")"

    /*
	 * Program initial configuration
	 */
	configuration 
	<T>
		<k> $PGM:Program </k>
		<tape> .Map </tape>
		<current-state> 0 </current-state>
		<current-position> 0 </current-position>
		<transitions> .Map </transitions>
		<states> .Set </states>
		<final-state> 0 </final-state>
		<initial-state> 0 </initial-state>
	</T>

    /*
	 * Structural rule for defining the program parsing order
	 */
	rule SI:States F:FinalState I:InitialState TT:Transition Tape:InitialTape 
		=> SI ~> F ~> I ~> TT ~> Tape [structural]

    /*
	 * Structural rule for defining the transitions parsing order
	 */
	rule T1:Transition T2:Transition => T1 ~> T2 [structural]

    /*
	 * Rule for parsing MDT states
	 */
	rule <k> ( Q, Qs:States => Qs ) ... </k>
		<states> S:Set => S SetItem(Q) </states>

    /*
	 * Rule for "ending" the state parsing phase (after parsing all the states, we are left with a blank Set, which we rewrite as .K)
	 */
	rule <k> .States => .K ... </k>

    /*
	 * Rule for parsing the final state
	 */
	rule <k> Final: Fi:Int => .K ... </k>
		<final-state> I => Fi </final-state>

    /*
	 * Rule for parsing the initial state (and consequently the current state)
	 */
	rule <k> Initial: In:Int => .K ... </k>
		<initial-state> I => In </initial-state>
		<current-state> I => In </current-state>

    /*
	 * Rule for parsing the list of transitions in the transition map, which has the couple (CurrentState, ReadSymbol) as key and (NextState, WriteSymbol, Move) as value
	 */
	rule <k> ( CurrentState:Int , ReadSymbol:String , NextState:Int , WriteSymbol:String , Move:Movement ) => .K ... </k>
		<transitions> Transition:Map => Transition[ (CurrentState, ReadSymbol) <- (NextState, WriteSymbol, Move)] </transitions>

    /*
     * Rule for parsing the initial tape in the tape map, which is has the key position and the value ReadSymbol (we can consider it as an array)
     */
	rule <k> ( ReadSymbol, ITape:InitialTape => ITape ) ... </k>
		<tape> Tape:Map => Tape[ size(Tape) <- ReadSymbol ] </tape> // NOTE: we use the size for indexing to the right position
	
    /*
     * Rule for making the actual MDT computations. This rule is triggered when we finished parsing the MDT source file
     */
	rule <k> .K </k>
		<transitions> ... (CurrentState, ReadSymbol:String) |-> (NextState:Int, WriteSymbol:String, Move:Movement) ... </transitions>
		<current-state> CurrentState:Int => NextState </current-state>
		<current-position> CurrentPosition:Int => CurrentPosition +Movement Move </current-position>
		<final-state> FinalState:Int </final-state>		
		<tape> Tape:Map => Tape[CurrentPosition <- WriteSymbol] </tape>
		when CurrentState =/=Int FinalState andBool CurrentPosition >=Int 0 andBool CurrentPosition <Int size(Tape) andBool ReadSymbol ==TapeChar Tape[CurrentPosition]
	
    /*
     * This rule is triggered when we exceed the initial tape size (like when going with negative indexes or beyond the initial size)
     */
	rule <k> .K </k>
		<transitions> ... (CurrentState, "*") |-> (NextState:Int, WriteSymbol:String, Move:Movement) ... </transitions> // NOTE: we assume that a transition with * exists, otherwise the computation ends
		<current-state> CurrentState:Int => NextState </current-state>
		<current-position> CurrentPosition:Int => CurrentPosition +Movement Move </current-position>
		<final-state> FinalState:Int </final-state>		
		<tape> Tape:Map => Tape[CurrentPosition <- WriteSymbol] </tape>
		when CurrentState =/=Int FinalState andBool (CurrentPosition <Int 0 orBool CurrentPosition >=Int size(Tape))

	/*
	 * Equals with tape chars
	 */
	syntax Bool ::= K "==TapeChar" K [function, left]
	rule "*" ==TapeChar S:String => true
	rule S:String ==TapeChar "*" => true
	rule S1:String ==TapeChar S2:String => S1 ==String S2 when S1 =/=String "*" andBool S2 =/=String "*"
	rule S:String ==TapeChar .K => false

	/*
	 * Calculate movement
	 */
	syntax Int ::= Int "+Movement" Movement [function, left]
	rule I:Int +Movement Mv:Movement => I +Int 1 when Mv ==K R
	rule I:Int +Movement Mv:Movement => I -Int 1 when Mv ==K L
	rule I:Int +Movement Mv:Movement => I when Mv ==K - 

endmodule