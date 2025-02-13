.data

# Mensagens exibidas ao jogador
prompt:         .asciiz "Entre duas posicoes (ex: A1 B3): "
match_msg:      .asciiz "Match encontrado!\n"
no_match_msg:   .asciiz "Nao eh match.\n"
board_label:    .asciiz "\nTabuleiro:\n   A B C D\n"
newline:        .asciiz "\n"
win_msg:        .asciiz "\nYou Win!\n"
card_msg1:      .asciiz ": "
input_buffer:   .space 100
error_msg:      .asciiz "Entrada invalida! Use o formato 'A1 B3' (letras A-D, numeros 1-4)\n"

# Contador de pares encontrados
matches_found:  .word 0

# Nomes das cartas no tabuleiro oculto
a_msg:          .asciiz "SSD"
b_msg:          .asciiz "MEMORIA RAM"
c_msg:          .asciiz "HD"
d_msg:          .asciiz "DRAM"
e_msg:          .asciiz "ROM"
f_msg:          .asciiz "CACHE"
g_msg:          .asciiz "SRAM"
h_msg:          .asciiz "CD"

# Tabuleiro visível ao jogador
board:          .byte '?','?','?','?',
                      '?','?','?','?',
                      '?','?','?','?',
                      '?','?','?','?'


# Tabuleiros ocultos com pares de cartas
hidden_board_1:   .byte 'A','B','C','D',
                        'E','F','G','H',
                        'A','B','C','D',
                        'E','F','G','H'
        
hidden_board_2:   .byte 'B','A','C','G',
                        'G','F','D','H',
                        'A','B','E','D',
                        'E','H','C','F'
            
hidden_board_3:   .byte 'A','A','C','G',
                        'H','F','G','H',
                        'B','E','B','D',
                        'E','D','C','F'
   
hidden_board_4:   .byte 'F','D','E','G',
                        'G','F','H','D',
                        'A','C','C','A',
                        'B','H','B','E'
                
hidden_board:     .space 16
             
tabuleiro_ponteiros:   .word hidden_board_1, hidden_board_2, hidden_board_3, hidden_board_4

    .text
    .globl main

# Inicializa o jogo e seleciona a seed
main:
    li $v0, 42       # syscall para gerar número aleatório
    li $a1, 4        # Define o intervalo de 0 a 3
    syscall
    move $t0, $a0  

    #Obtem o enderço do tabuleiro sorteado (seed)
    la $t1, tabuleiro_ponteiros  # Carrega o endereço do vetor de ponteiros
    sll $t0, $t0, 2         # Faz o deslocamento de 0(equivalente a multiplicar por 4)
    add $t1, $t1, $t0       # Adiciona o deslocamento do vetor tabuleiro_ponteiros baseado na multiplicação do valor aleatório e calculado na função acima
    lw $t2, 0($t1)          # Carrega o endereço do tabuleiro da seed

    la $t3, hidden_board    
    li $t4, 16             
    li $t5, 0

copy_loop:
    lb $t6, 0($t2)         # Carregar byte do tabuleiro da seed
    sb $t6, 0($t3)         # Armazena no tabuleiro do jogo
    addiu $t2, $t2, 1  
    addiu $t3, $t3, 1     
    addiu $t5, $t5, 1     
    blt $t5, $t4, copy_loop

# Entra no loop principal
game_body:
    sw $zero, matches_found
    jal game_loop
    li $v0, 10
    syscall

# Loop principal do jogo, exibe o tabuleiro e processa entradas do usuário
game_loop:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

game_loop_start:
    jal print_board
    jal get_input
    jal process_input

    lw $t0, matches_found
    li $t1, 8
    bne $t0, $t1, game_loop_start

    li $v0, 4
    la $a0, win_msg
    syscall

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Exibe o tabuleiro com as posições atuais
print_board:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    li $v0, 4
    la $a0, board_label
    syscall

    li $t0, 0  # Índice da linha atual

print_board_loop:
    li $v0, 11
    addi $a0, $t0, 49
    syscall

    li $v0, 11
    li $a0, 58
    syscall
    li $a0, 32
    syscall

    move $t1, $t0
    mul $t1, $t1, 4  # Calcula deslocamento da linha
    li $t2, 0  # Índice da coluna atual

print_row:
    la $t3, board
    add $t3, $t3, $t1
    add $t3, $t3, $t2
    lb $a0, ($t3)
    li $v0, 11
    syscall

    li $v0, 11
    li $a0, 32
    syscall

    addi $t2, $t2, 1
    blt $t2, 4, print_row

    li $v0, 11
    li $a0, 10
    syscall

    addi $t0, $t0, 1
    blt $t0, 4, print_board_loop

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Obtém a entrada do usuário e armazena no buffer
get_input:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    li $v0, 4
    la $a0, prompt
    syscall

    li $v0, 8
    la $a0, input_buffer
    li $a1, 100
    syscall

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Processa a entrada do usuário, verifica pares e atualiza o jogo
process_input:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    la $t0, input_buffer
    jal calculate_position
    move $t3, $v0

    addi $t0, $t0, 3
    jal calculate_position
    move $t4, $v0

    jal check_revealed
    bnez $v0, invalid_input

    la $t0, input_buffer
    move $a0, $t3
    jal show_card
    move $t5, $v0

    addi $t0, $t0, 3
    move $a0, $t4
    jal show_card
    move $t6, $v0

    beq $t5, $t6, match_found

    li $v0, 4
    la $a0, no_match_msg
    syscall
    j process_input_end

match_found:
    la $t0, board
    add $t1, $t0, $t3
    li $t2, 'X'
    sb $t2, ($t1)
    add $t1, $t0, $t4
    sb $t2, ($t1)

    lw $t0, matches_found
    addi $t0, $t0, 1
    sw $t0, matches_found

    li $v0, 4
    la $a0, match_msg
    syscall

process_input_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

invalid_input:
    li $v0, 4
    la $a0, error_msg
    syscall
    j process_input_end

# Converte uma posição de entrada no índice correspondente do tabuleiro
calculate_position:
    lb $t1, 0($t0)
    lb $t2, 1($t0)
    subi $t1, $t1, 65
    subi $t2, $t2, 49
    mul $t2, $t2, 4
    add $v0, $t1, $t2
    jr $ra

# Verifica se uma posição já foi revelada
check_revealed:
    la $t0, board
    add $t1, $t0, $t3
    lb $t1, ($t1)
    li $t2, 'X'
    beq $t1, $t2, revealed

    add $t1, $t0, $t4
    lb $t1, ($t1)
    beq $t1, $t2, revealed

    li $v0, 0
    jr $ra

revealed:
    li $v0, 1
    jr $ra

# Exibe a carta escolhida pelo jogador e retorna seu valor
show_card:
    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $a0, 4($sp)

    lb $a0, 0($t0)
    li $v0, 11
    syscall
    lb $a0, 1($t0)
    syscall

    li $v0, 4
    la $a0, card_msg1
    syscall

    lw $t1, 4($sp)
    la $t2, hidden_board
    add $t2, $t2, $t1
    lb $a0, ($t2)
    jal print_card_text

    li $v0, 11
    li $a0, 10
    syscall

    lb $v0, ($t2)
    lw $ra, 0($sp)
    addi $sp, $sp, 8
    jr $ra
    
# Printa as mensagens das cartas
print_card_text:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    beq $a0, 'A', print_a
    beq $a0, 'B', print_b
    beq $a0, 'C', print_c
    beq $a0, 'D', print_d
    beq $a0, 'E', print_e
    beq $a0, 'F', print_f
    beq $a0, 'G', print_g
    beq $a0, 'H', print_h

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

print_a:
    la $a0, a_msg
    j print_msg
print_b:
    la $a0, b_msg
    j print_msg
print_c:
    la $a0, c_msg
    j print_msg
print_d:
    la $a0, d_msg
    j print_msg
print_e:
    la $a0, e_msg
    j print_msg
print_f:
    la $a0, f_msg
    j print_msg
print_g:
    la $a0, g_msg
    j print_msg
print_h:
    la $a0, h_msg
    j print_msg

print_msg:
    li $v0, 4
    syscall
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
