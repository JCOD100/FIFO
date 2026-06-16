`timescale 1ns / 1ps

module FIFO_one_sync #(
    MEM_SIZE  = 6,  // кол-во данных в буфере
    DATA_SIZE = 8,  // размер данных в буфере    
    localparam ADDR_SIZE = $clog2(MEM_SIZE)
)
(
    input                   clk,
    input                   reset,
    input                   enable,
    input                   read_mode,
    input                   write_mode,
    input [DATA_SIZE - 1:0] data_in,
    
    output  reg [DATA_SIZE - 1: 0] data_out,
    output  reg                    valid,
    output  reg                    full,
    output  reg                    empty
    );
    
    reg [DATA_SIZE - 1: 0] mem [0: ADDR_SIZE - 1]; // ¬нутренн€€ пам€ть устройства
    
    // указатели на чтение (текущий и следующий)
    reg [ADDR_SIZE - 1: 0] read_pointer;
    reg [ADDR_SIZE - 1: 0] read_pointer_next;
    
    // укзаатели на запись (текущий и следующий)
    reg [ADDR_SIZE - 1: 0] write_pointer;
    reg [ADDR_SIZE - 1: 0] write_pointer_next;
    
    // регистры дл€ хранени€ заполненности/пустоты буфера
    reg full_next;
    reg empty_next;
    
    reg [1:0] operation;
    localparam NONE = 0, READ = 1, WRITE = 2, READ_AND_WRITE = 3;
    
    integer i;
    
    // изначальный сброс
    initial begin
        operation = NONE;
        
        empty      = 1;
        empty_next = 1;
        
        full      = 0;
        full_next = 0;
        
        read_pointer      = 0;
        read_pointer_next = 0;
        
        write_pointer      = 0;
        write_pointer_next = 0;
        
        valid = 0;
        
        data_out = { DATA_SIZE{1'b0} };
        
        for (i = 0; i < MEM_SIZE; i = i + 1) begin
            mem[i] = { DATA_SIZE{1'b0} };
        end
    
    end
    
    // чтение
    always @(posedge clk) begin
        if (enable && read_mode && !empty) begin
            data_out <= mem[read_pointer];
            valid    <= 1;
        end else
            valid <= 0;
    end
    
    // запись
    always @(posedge clk) begin
        if (enable && write_mode && !full)
            mem[write_pointer] <= data_in;
    end
    
    
    
    // »зменение значений
    always @(posedge clk) begin
        if (reset) begin
            read_pointer  <= 0;
            write_pointer <= 0;
            full          <= 0;
            empty         <= 1;
        end else if (enable) begin
            read_pointer  <= read_pointer_next;        
            write_pointer <= write_pointer_next;
            full          <= full_next;
            empty         <= empty_next;
        end
        
    end
    
    // ‘ункци€, помогающа€ вычисл€ть следующее значение указател€ 
    /* потом по€снить зачем так*/
    function [ADDR_SIZE - 1: 0] NEXT(input [ADDR_SIZE - 1: 0] pointer);
    begin
        if (pointer == ADDR_SIZE - 1)
            NEXT = 0;
        else
        NEXT = pointer + 1; 
    end
    endfunction
    
    // комбинационна€ логика 
    
    always @* begin
    
        case ( {write_mode, read_mode} )
            2'b10:
                operation = (!full) ? WRITE : NONE;
            2'b01:
                operation = (!empty) ? READ: NONE;
            2'b11: 
                case ( {full, empty} )
                    2'b01: 
                        operation = WRITE;
                    2'b10:
                        operation = READ;
                    default:
                        operation = READ_AND_WRITE;
                endcase
 
            default: operation = NONE;
        
        endcase
    
        case (operation)
            NONE: begin
                read_pointer_next = read_pointer;
                write_pointer_next = write_pointer;
                full_next = full;
                empty_next = empty;
            end
            
            READ: begin
                read_pointer_next = NEXT(read_pointer);
                write_pointer_next = write_pointer;
                full_next = 0;
                empty_next = (read_pointer_next == write_pointer);     
            end
            
            WRITE: begin
                read_pointer_next = read_pointer;
                write_pointer_next = NEXT(write_pointer);
                full_next = (write_pointer_next == read_pointer);
                empty_next = 0;
            
            end
            
            READ_AND_WRITE: begin
                read_pointer_next = NEXT(read_pointer);
                write_pointer_next = NEXT(write_pointer);
                full_next = full;
                empty_next = empty;            
            end
        endcase
    end                
endmodule
