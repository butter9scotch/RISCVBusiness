package pipe5_types_pkg;

    /** Determine which register file is the origin **/
    typedef enum logic {
        INTEGER,
        FP
    } regsource_t;

    /** Reg # + origin **/
    typedef struct packed {
        regsource_t src;
        logic [4:0] addr;
    } rsel_t;

    typedef enum logic[1:0] {
        NO_FWD,
        FWD_M,
        FWD_W
    } bypass_t;
    
    typedef struct packed {
        logic fault_instr;
        logic mal_instr;
        logic illegal_instr;
        logic fault_ld;
        logic mal_ld;
        logic fault_st;
        logic mal_st;
        logic breakpoint;
        logic env_m;
    } exception_t;

endpackage
