`ifndef RV32F_TYPES_PKG_SV
`define RV32F_TYPES_PKG_SV
package rv32f_types_pkg;
    parameter FOP_W = 7;
    parameter F_FUNCT_W = 7;
    typedef enum logic [FOP_W-1:0] {
        FLW       = 7'b0000111,
        FSW       = 7'b0100111,
        F_RTYPE   = 7'b1010011 //for add sub and mul
    } f_opcode_t;

    typedef enum logic [F_FUNCT_W-1:0] {
        FADD      = 7'b0,
        FSUB      = 7'b0000100,
        FMUL      = 7'b0001000
    } f_funct7_t;

endpackage

`endif
