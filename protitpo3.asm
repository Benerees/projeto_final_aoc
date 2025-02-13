.data

prompt:         .asciiz "Entre duas posicoes (ex: A1 B3): "

match_msg:      .asciiz "Match encontrado!\n"

no_match_msg:   .asciiz "Nao eh match.\n"

board_label:    .asciiz "\nTabuleiro:\n   A B C D\n"

newline:        .asciiz "\n"

win_msg:        .asciiz "\nYou Win!\n"

card_msg1:      .asciiz ": "

input_buffer:   .space 100

error_msg:      .asciiz "Entrada invalida! Use o formato 'A1 B3' (letras A-D, numeros 1-4)\n"

matches_found:  .word 0    # Contador de matches encontrados

a_msg: 		.asciiz "SSD"	

b_msg: 		.asciiz "MEMORIA RAM"

c_msg: 		.asciiz "HD"

d_msg: 		.asciiz "DRAM"

e_msg: 		.asciiz "ROM"

f_msg: 		.asciiz "CACHE"

g_msg: 		.asciiz "SRAM"

h_msg: 		.asciiz "CD"


# Array de exibicao (front) - 16 posicoes iniciadas com '?'
board:  .byte '?','?','?','?',

        '?','?','?','?',

        '?','?','?','?',

        '?','?','?','?'


# Array oculto (back) - pares de letras
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

main:
    li $v0, 42       # syscall para gerar número aleatório
    li $a1, 4        # Define o intervalo de 0 a 3
    syscall
    move $t0, $a0  

    #Obtem o enderço do tabuleiro sorteado (seed)
    la $t1, tabuleiro_ponteiros  # Carrega o endereço do vetor de ponteiros
    sll $t0, $t0, 2         # Faz o deslocamento de 0(equivalente a multiplicar por 4)
    add $t1, $t1, $t0       # Adiciona o deslocamento do vetor tabuleiro_ponteiros baseado na multiplicação do valor aleatório e calculado na função acima
    lw $t2, 0($t1)          # Carrega o endereço do tabuleiro selecionado

    # Copiar tabuleiro para hidden_board
    la $t3, hidden_board    # Endereço do destino
    li $t4, 16             # Tamanho do tabuleiro
    li $t5, 0              # Índice

copy_loop:
    lb $t6, 0($t2)         # Carregar byte do tabuleiro selecionado
    sb $t6, 0($t3)         # Armazenar em hidden_board
    addiu $t2, $t2, 1      # Avançar origem
    addiu $t3, $t3, 1      # Avançar destino
    addiu $t5, $t5, 1      # Incrementar contador
    blt $t5, $t4, copy_loop # Repetir até copiar tudo

sw $zero, matches_found

game_loop:
    # Imprime o rótulo do tabuleiro
    li $v0, 4
    la $a0, board_label
    syscall

    # Inicializa contadores
    li $t0, 0          # contador de linhas

    

print_board:
    # Imprime número da linha
    li $v0, 11
    addi $a0, $t0, 49  # converte para ASCII
    syscall

    # Imprime ": "
    li $v0, 11
    li $a0, 58
    syscall

    # espaço
    li $a0, 32         
    syscall

    # Calcula posição da linha
    move $t1, $t0
    mul $t1, $t1, 4    # multiplica linha * 4
    li $t2, 0          # contador de colunas

    

print_line:
    # Carrega e imprime caractere da posição atual do board
    la $t3, board
    add $t3, $t3, $t1
    add $t3, $t3, $t2

    lb $a0, ($t3)
    li $v0, 11
    syscall

    # Imprime espaço entre colunas
    li $v0, 11
    li $a0, 32         # espaço
    syscall

    # Incrementa contador de colunas
    addi $t2, $t2, 1
    blt $t2, 4, print_line
    
    # Nova linha
    li $v0, 11
    li $a0, 10         # \n
    syscall

    # Próxima linha
    addi $t0, $t0, 1
    blt $t0, 4, print_board

get_input:    
    # Solicita input
    li $v0, 4
    la $a0, prompt
    syscall

    # Lê input
    li $v0, 8
    la $a0, input_buffer
    li $a1, 100
    syscall
    
    la $t0, input_buffer
   
    j process_input   

process_input:    
    # Processa primeira posição
    lb $t1, 0($t0)     # coluna (A-D)
    lb $t2, 1($t0)     # linha (1-4)

    # Calcula índice da primeira posição
    subi $t1, $t1, 65  # A -> 0
    subi $t2, $t2, 49  # 1 -> 0
    mul $t2, $t2, 4
    add $t3, $t1, $t2 

    # Processa segunda posição
    lb $t1, 3($t0)     # coluna (A-D)
    lb $t2, 4($t0)     # linha (1-4)
    
    # Calcula índice da segunda posição
    subi $t1, $t1, 65  # A -> 0
    subi $t2, $t2, 49  # 1 -> 0
    mul $t2, $t2, 4
    add $t4, $t1, $t2  # índice = linha*4 + coluna

    # Verifica se alguma das posições já foi revelada
    la $t0, board
    
    add $t1, $t0, $t3
    lb $t1, ($t1)
    li $t2, 'X'
    beq $t1, $t2, invalid_input
    

    add $t1, $t0, $t4
    lb $t1, ($t1)
    beq $t1, $t2, invalid_input

    # Mostra primeira carta selecionada
    la $t0, input_buffer
    lb $a0, 0($t0)     # coluna
    li $v0, 11
    syscall

    lb $a0, 1($t0)     # linha
    syscall

    # Imprime ": "
    la $a0, card_msg1
    li $v0, 4
    syscall

    # Mostra valor da primeira carta
	li $t8, 0
    la $t0, hidden_board
    add $t1, $t0, $t3
	lb $t7, 0($t1)      # valor na primeira posição
 	
    beq $t7, 'A', a_frase
    beq $t7, 'B', b_frase
    beq $t7, 'C', c_frase
    beq $t7, 'D', d_frase
    beq $t7, 'E', e_frase
    beq $t7, 'F', f_frase
    beq $t7, 'G', g_frase
    beq $t7, 'H', h_frase

a_frase:
	li $v0, 4
    la $a0, a_msg
    syscall
    beq $t8, 0, segunda_carta
    j verifica_match
    	
b_frase:
	li $v0, 4
    la $a0, b_msg
    syscall
    beq $t8, 0, segunda_carta
    j verifica_match
    	
c_frase:
    li $v0, 4
    la $a0, c_msg
    syscall
    beq $t8, 0, segunda_carta
    j verifica_match
   
d_frase:
 	li $v0, 4
    la $a0, d_msg
    syscall
    beq $t8, 0, segunda_carta
    j verifica_match
    	
e_frase:
 	li $v0, 4
    la $a0, e_msg
    syscall
    beq $t8, 0, segunda_carta
    j verifica_match

f_frase:
 	li $v0, 4
    la $a0, f_msg
    syscall
    beq $t8, 0, segunda_carta
    j verifica_match
    	
g_frase:
    li $v0, 4
    la $a0, g_msg
    syscall
    beq $t8, 0, segunda_carta
    j verifica_match
    	
h_frase:
 	li $v0, 4
    la $a0, h_msg
    syscall
    beq $t8, 0, segunda_carta
    j verifica_match


segunda_carta:
    # Nova linha
    li $v0, 11
    li $a0, 10         # \n
    syscall

    # Mostra segunda carta selecionada
    la $t0, input_buffer
    lb $a0, 3($t0)     # coluna
    li $v0, 11
    syscall

    lb $a0, 4($t0)     # linha
    syscall

    # Imprime ": "
    la $a0, card_msg1
    li $v0, 4
    syscall

    # Controlador do print
    addi $t8, $t8, 1

    la $t0, hidden_board
    add $t2, $t0, $t4
    
    lb $t7, 0($t2)      # valor na primeira posição
 	
    beq $t7, 'A', a_frase
    beq $t7, 'B', b_frase
    beq $t7, 'C', c_frase
    beq $t7, 'D', d_frase
    beq $t7, 'E', e_frase
    beq $t7, 'F', f_frase
    beq $t7, 'G', g_frase
    beq $t7, 'H', h_frase
    
 verifica_match:
	li $v0, 11
    li $a0, 10         # \n
    syscall

    # Verifica se as posições formam um par
    lb $t5, ($t1)      # valor na primeira posição
    lb $t6, ($t2)      # valor na segunda posição
    bne $t5, $t6, no_match_found

    # Match encontrado - atualiza tabuleiro
    la $t0, board
    add $t1, $t0, $t3
    li $t2, 'X'
    sb $t2, ($t1)      # marca primeira posição
    add $t1, $t0, $t4
    sb $t2, ($t1)      # marca segunda posição

    # Incrementa contador de matches
    lw $t0, matches_found
    addi $t0, $t0, 1
    sw $t0, matches_found

    # Imprime mensagem de sucesso
    li $v0, 4
    la $a0, match_msg
    syscall

    # Verifica se todos os matches foram encontrados (8 pares)
    lw $t0, matches_found
    bne $t0, 8, game_loop

    # Se chegou aqui, todos os matches foram encontrados
    li $v0, 4
    la $a0, win_msg
    syscall

    j exit

invalid_input:
    # Imprime mensagem de erro
    li $v0, 4
    la $a0, error_msg
    syscall

    j get_input

no_match_found:
    # Imprime mensagem de falha
    li $v0, 4
    la $a0, no_match_msg
    syscall

    j game_loop

exit:
    li $v0, 10
    syscall
