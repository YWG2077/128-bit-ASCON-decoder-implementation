library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.Common.all;
use IEEE.NUMERIC_STD.ALL;


entity FSM is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC; -- active high
           start: in STD_LOGIC;  -- active high
           tagsEqual : in STD_LOGIC;
           
           input_queue_next : out STD_LOGIC;
           input_queue_blocktype : in blocktype;
           output_queue_write : out STD_LOGIC;
           
           valid : out STD_LOGIC;
           ready : out STD_LOGIC;
           
           operation : out Opcodes;
           round : out STD_LOGIC_VECTOR(3 downto 0)  -- expecting numbers 0 to 11 in binary
           );
end FSM;

architecture Behavioral of FSM is

    type ASCON_STATE is (
    Idle,
    WaitNonce,
    Init,
    InitRound,
    InitAddKey,
    InitOver,
    InitFinalWait,
    AbsorbData,
    AbsorbRound,
    AbsorbOver,
    AbsorbFinalWait,
    ApplyOne,
    AbsorbReallyEnd,
    Decode,
    DecodeOver,
    DecodeOverWait,
    DecodeRoundFinal,
    DecodeRound,
    KeyF,
    TagRound,
    TagJudge,
    TagValid,
    TagNotValid
    );
    signal current_state: ASCON_STATE;
    signal round_counter1 : integer range 0 to 11 := 0;
    signal round_counter2 : integer range 4 to 11 := 4;

begin
    --State Update Logic
    process(all)
    begin
        if rising_edge(clk) then
            case current_state is
            when Idle => 
                if start = '1' then
                    current_state <= WaitNonce;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= NOP;
                    round <= (others => '0');
                    round_counter1 <= 0;
                    round_counter2 <= 4;
                end if;
                
            when WaitNonce =>
                if input_queue_blocktype = Nonce then
                    current_state <= Init;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= Init;
                    round <= (others => '0');
                    round_counter1 <= 0;
                    round_counter2 <= 4;
                end if;
            
            when Init =>
                current_state <= InitRound;
                input_queue_next <= '0';
                output_queue_write <= '0';
                valid <= '0';
                ready <= '0';
                operation <= applyRound;
                round <= std_logic_vector(to_unsigned(round_counter1, 4));
                round_counter1 <= round_counter1 + 1;
            
            when InitRound =>
                if round_counter1 = 12 then
                    current_state <= InitAddKey;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= applyKeyI;
                    round <= (others => '0');
                    round_counter1 <= 0;
                else
                    current_state <= InitRound;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= applyRound;
                    round <= std_logic_vector(to_unsigned(round_counter1, 4));
                    round_counter1 <= round_counter1 + 1;
                end if;
            
            when InitAddKey =>
                current_state <= InitOver;
                input_queue_next <= '1';
                output_queue_write <= '0';
                valid <= '0';
                ready <= '0';
                operation <= NOP;
                round <= (others => '0');
                round_counter1 <= 0;
                round_counter2 <= 4;
            
            when InitOver =>
                current_state <= InitFinalWait;
                input_queue_next <= '0';
                output_queue_write <= '0';
                valid <= '0';
                ready <= '0';
                operation <= NOP;
                round <= (others => '0');
                round_counter1 <= 0;
                round_counter2 <= 4;
            
            when InitFinalWait =>
                if input_queue_blocktype = AData then
                    current_state <= AbsorbData;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= applyAD;
                    round <= (others => '0');
                    round_counter1 <= 0;
                    round_counter2 <= 4;
                elsif input_queue_blocktype = Message then
                    current_state <= AbsorbFinalWait;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= NOP;
                    round <= (others => '0');
                    round_counter1 <= 0;
                    round_counter2 <= 4;
                end if;
                
            when AbsorbData =>
                current_state <= AbsorbRound;
                input_queue_next <= '0';
                output_queue_write <= '0';
                valid <= '0';
                ready <= '0';
                operation <= applyRound;
                round <= std_logic_vector(to_unsigned(round_counter2, 4));
                round_counter2 <= round_counter2 + 1;
                
            when AbsorbRound =>
                if round_counter2 = 12 then
                    current_state <= AbsorbOver;
                    input_queue_next <= '1';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= NOP;
                    round <= (others => '0');
                    round_counter2 <= 4;
                else 
                    current_state <= AbsorbRound;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= applyRound;
                    round <= std_logic_vector(to_unsigned(round_counter2, 4));
                    round_counter2 <= round_counter2 + 1;
                end if;
            
            when AbsorbOver =>
                current_state <= AbsorbFinalWait;
                input_queue_next <= '0';
                output_queue_write <= '0';
                valid <= '0';
                ready <= '0';
                operation <= NOP;
                round <= (others => '0');
                round_counter1 <= 0;
                round_counter2 <= 4;
            
            when AbsorbFinalWait =>
                if input_queue_blocktype = AData then
                    current_state <= AbsorbData;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= applyAD;
                    round <= (others => '0');
                    round_counter1 <= 0;
                    round_counter2 <= 4;
                elsif input_queue_blocktype = Message then
                    current_state <= ApplyOne;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= applyOne;
                    round <= (others => '0');
                    round_counter1 <= 0;
                    round_counter2 <= 4;
                end if;
            
            when ApplyOne =>
                current_state <= AbsorbReallyEnd;
                input_queue_next <= '0';
                output_queue_write <= '0';
                valid <= '0';
                ready <= '0';
                operation <= NOP;
                round <= (others => '0');
                round_counter1 <= 0;
                round_counter2 <= 4;
                
            when AbsorbReallyEnd =>
                current_state <= Decode;
                input_queue_next <= '0';
                output_queue_write <= '0';
                valid <= '0';
                ready <= '0';
                operation <= applyDec;
                round <= (others => '0');
                round_counter1 <= 0;
                round_counter2 <= 4;
            
            when Decode =>
                current_state <= DecodeOver;
                input_queue_next <= '1';
                output_queue_write <= '1';
                valid <= '0';
                ready <= '0';
                operation <= NOP;
                round <= (others => '0');
                round_counter1 <= 0;
                round_counter2 <= 4;
            
            when DecodeOver =>
                current_state <= DecodeOverWait;
                input_queue_next <= '0';
                output_queue_write <= '0';
                valid <= '0';
                ready <= '0';
                operation <= NOP;
                round <= (others => '0');
                round_counter1 <= 0;
                round_counter2 <= 4;
                
            when DecodeOverWait =>
                if input_queue_blocktype = Message then
                    current_state <= DecodeRound;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= applyRound;
                    round <= std_logic_vector(to_unsigned(round_counter2, 4));
                    round_counter2 <= round_counter2 + 1;
                elsif input_queue_blocktype = Tag then
                    current_state <= DecodeRoundFinal;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= applyRound;
                    round <= std_logic_vector(to_unsigned(round_counter2, 4));
                    round_counter2 <= round_counter2 + 1;
                end if;
                
            when DecodeRoundFinal =>
                if round_counter2 = 12 then
                    current_state <= KeyF;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= applyKeyF;
                    round <= (others => '0');
                    round_counter2 <= 4;
                else 
                    current_state <= DecodeRoundFinal;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= applyRound;
                    round <= std_logic_vector(to_unsigned(round_counter2, 4));
                    round_counter2 <= round_counter2 + 1;
                end if;
                
            
            when DecodeRound =>
                if round_counter2 = 12 then
                    current_state <= Decode;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= applyDec;
                    round <= (others => '0');
                    round_counter2 <= 4;

                else
                    current_state <= DecodeRound;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= applyRound;
                    round <= std_logic_vector(to_unsigned(round_counter2, 4));
                    round_counter2 <= round_counter2 + 1;
                end if;
            
            when KeyF =>
                current_state <= TagRound;
                input_queue_next <= '0';
                output_queue_write <= '0';
                valid <= '0';
                ready <= '0';
                operation <= applyRound;
                round <= std_logic_vector(to_unsigned(round_counter1, 4));
                round_counter1 <= round_counter1 + 1;
            
            when TagRound =>
                if round_counter1 = 12 then
                    current_state <= TagJudge;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= NOP;
                    round <= (others => '0');
                    round_counter1 <= 0;
                else
                    current_state <= TagRound;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= applyRound;
                    round <= std_logic_vector(to_unsigned(round_counter1, 4));
                    round_counter1 <= round_counter1 + 1;
                end if;
                
                
            when TagJudge =>
                if tagsEqual = '1' then
                    current_state <= TagValid;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '1';
                    ready <= '1';
                    operation <= NOP;
                    round <= (others => '0');
                    round_counter1 <= 0;
                    round_counter2 <= 4;
                elsif tagsEqual = '0' then
                    current_state <= TagNotValid;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '1';
                    operation <= NOP;
                    round <= (others => '0');
                    round_counter1 <= 0;
                    round_counter2 <= 4;
                end if;
                
            when TagValid =>
                if input_queue_blocktype = Nonce then
                    current_state <= Init;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= Init;
                    round <= (others => '0');
                    round_counter1 <= 0;
                    round_counter2 <= 4;
                end if;
                
            when TagNotValid =>
                if input_queue_blocktype = Nonce then
                    current_state <= Init;
                    input_queue_next <= '0';
                    output_queue_write <= '0';
                    valid <= '0';
                    ready <= '0';
                    operation <= Init;
                    round <= (others => '0');
                    round_counter1 <= 0;
                    round_counter2 <= 4;
                end if;
            
            when others =>
                current_state <= Idle;
                input_queue_next <= '0';
                output_queue_write <= '0';
                valid <= '0';
                ready <= '0';
                operation <= NOP;
                round <= (others => '0');
                round_counter1 <= 0;
                round_counter2 <= 4;
                
                
            end case;  
            
            if reset = '1' then
                current_state <= Idle;
                input_queue_next <= '0';
                output_queue_write <= '0';
                valid <= '0';
                ready <= '0';
                operation <= Init;
                round <= (others => '0');
                round_counter1 <= 0;
                round_counter2 <= 4;
            end if;
        end if;
    end process;




end Behavioral;