.stack 100h

.data
   
   TITLE_TEXT DB 0Ah, 0Ah
           DB 0Dh, 0Ah      
           DB 0Dh, 0Ah 
           DB 0Dh, 0Ah 
           DB 09h, "  ______   ____  _____       _       ___  ____   ________ ", 0Dh, 0Ah  
           DB 09h, " / ____ \ |_   \|_   _|     / \     |_  ||_  _| |_   __  |", 0Dh, 0Ah 
           DB 09h, "| (___ \_|  |   \ | |      / _ \      | |_/ /     | |_ \_|", 0Dh, 0Ah 
           DB 09h, " _.____`.   | |\ \| |     / ___ \     |  __'.     |  _| _ ", 0Dh, 0Ah  
           DB 09h, "| \____) | _| |_\   |_  _/ /   \ \_  _| |  \ \_  _| |__/ |", 0Dh, 0Ah 
           DB 09h, " \______.'|_____|\____||____| |____||____||____||________|", 0Dh, 0Ah,0Dh, 0Ah, 0Dh, 0Ah, 0Dh, 0Ah 
           DB 09h,09h,09h, "Press any key to start game$"
                                                                                                           
                                                                         
   GAME_MAP_TEXT DB 'Select game map', 0dh, 0ah
                 DB '1. Map I', 0dh, 0ah
                 DB '2. Map II', 0dh, 0ah
                 DB 'Please enter your choice: $'
   
   GAME_OVER DB 'Game Over!$'
   YOUR_SCORE DB 'Your score is:$'
   
   INVALID_CHOICE_MSG DB 0dh,0ah,'Invalid choice!$'
   
   ovh DB 2,0,0,0

   ;Const
   MAP_WIDTH EQU 80;
   MAP_HEIGHT EQU 25;  
   
   WALL_COLOR EQU 15; White
   SNAKE_HEAD_COLOR EQU 14; Yellow
   SNAKE_BODY_COLOR EQU 2; Green
   FOOD_COLOR EQU 14; Yellow
   SPACE_COLOR EQU 0; BLack
   
   WALL_SYMBOL EQU 219 ; black square
   SNAKE_HEAD_SYMBOL EQU 145; 
   SNAKE_BODY_SYMBOL EQU 35
   FOOD_SYMBOL EQU 3
          
   mapData DB MAP_WIDTH * MAP_HEIGHT dup(' ')       
   mapDataRowIndex DW 0,80,160,240,320,400,480,560, 640, 720, 800, 880, 960, 1040, 1120, 1200, 1280,1360,1440, 1520, 1600, 1680, 1760, 1840,1920
   
   DiX DB 1,0,-1,0
   DiY DB 0,1,0,-1  
   
   currentDirection DW 0
   currentSnakeLength DW 3 
   oldSnakeTail DB -1,-1          
   snakeXSegements DB 41,40,39, MAP_WIDTH * MAP_HEIGHT dup(?)
   snakeYSegements DB 13,13,13, MAP_WIDTH * MAP_HEIGHT dup(?)
   
   score DB '0','0','0','0'
   gameMap DB 0
   
.code


Main PROC
   MOV AX, @data
   MOV DS, AX
   
   ;Print title
   LEA DX, TITLE_TEXT
   MOV AH, 9
   INT 21h
  
   ;Wait for key pressing
   MOV AH, 0
   INT 16h
   
select_map:   
   CALL ClearScreen
   
   LEA DX, GAME_MAP_TEXT
   MOV AH, 9
   INT 21h
   
   MOV ovh[0], 2
   LEA DX, ovh
   MOV AH, 0ah
   INT 21h 
   
   CMP ovh[2], '2'
   JE store_choice
   CMP ovh[2], '1'
   JE store_choice    
   
   LEA DX, INVALID_CHOICE_MSG
   MOV AH, 9
   INT 21h 
   
   ; Delay 2s ~ 2,000,000 microsecond ~ 0x1E8480
   MOV DX, 8480h
   MOV CX, 1Eh
   MOV AL, 0h
   MOV AH, 86h       
   INT 15h  
   
   JMP select_map
   
store_choice:
   ; Store prev option to gameMap
   MOV AL, ovh[2]  
   MOV gameMap, AL 
   CALL GameStart 
   RET
Main ENDP   

GameStart PROC  
   CALL ClearScreen
  
   CALL InitializeMap
   CALL SpawnFood
   
   MOV currentDirection, 0
GAME_LOOP: 
   
   ; Get available key in buffer, if no key pressed, ZF = 1, otherwise ZF = 1             
   MOV AL, 0
   MOV AH, 1
   INT 16h
   
   JZ END_KEY_CASE
   
   ; Read available key, Key's Ascii code in AL and Key's Scan code in AH
   MOV AH, 0
   INT 16h
   
   AND AL, 11011111b
   KEY_CASE:
   CMP AL, 57h ; 'W' scancode
   JE MOVE_UP
   CMP AL, 41h ; 'A' scancode
   JE MOVE_LEFT
   CMP AL, 53h ; 'S' scancode
   JE MOVE_DOWN
   CMP AL, 44h ; 'D' scancode  
   JE MOVE_RIGHT                                                                 
   JMP END_KEY_CASE
   
   MOVE_UP:  
       CMP currentDirection, 1
       JE END_KEY_CASE
       MOV currentDirection, 3
       JMP END_KEY_CASE
   MOVE_LEFT:
       CMP currentDirection, 0
       JE END_KEY_CASE
       MOV currentDirection, 2
       JMP END_KEY_CASE
   MOVE_DOWN: 
       CMP currentDirection, 3
       JE END_KEY_CASE
       MOV currentDirection, 1
       JMP END_KEY_CASE
   MOVE_RIGHT:  
       CMP currentDirection, 2
       JE END_KEY_CASE
       MOV currentDirection, 0
       JMP END_KEY_CASE
         
   END_KEY_CASE:
   
   HANDLE:
      CALL MoveSnake
      
      MOV DL, [snakeXSegements]
      MOV DH, [snakeYSegements]
      CALL GetMapDataXY      
      CMP AL, FOOD_SYMBOL
      JE hit_food
      CMP AL, ' '
      JE draw_snake
      
      CALL EndGame
      RET
      
      hit_food:  
      CALL SnakeEatFood
      CALL SpawnFood 
      
      draw_snake:
      CALL DrawSnake

   JMP GAME_LOOP
   
   RET
GameStart ENDP

EndGame PROC 
   CALL ClearScreen
   MOV AH, 15; White color for text
   
   LEA SI, GAME_OVER
   MOV DH, 10
   MOV DL, 35
   CALL PrintStringAtPos
   
   LEA SI, YOUR_SCORE
   MOV DH, 12
   MOV DL, 30
   CALL PrintStringAtPos
   
   MOV SI, 0 
   MOV AH, 15;  white color
   MOV DH, 12
   MOV DL, 46
   print_score_loop:
      CMP SI, 4
      JE end_print_score 
      MOV AL, [score + SI]
      CALL PrintCharAtPos
      INC SI
      INC DL    
      JMP print_score_loop
   end_print_score:
   
   RET
EndGame ENDP

InitializeMap PROC  
   CMP gameMap, '1'
   JE draw_map_1
   CMP gameMap, '2'
   JE draw_map_2   
   ;Use default 
   
   
   draw_map_1: 
      MOV AH, WALL_COLOR
      MOV AL, WALL_SYMBOL
      
      MOV DL, 0          
      draw_map_1_horizontal:
      ; Print border character at the top of screen
      MOV DH, 0
      CALL SetMapDataXY
      CALL PrintCharAtPos 
      
      ; Print border character at the bottom of screen
      MOV DH, MAP_HEIGHT - 1
      CALL SetMapDataXY 
      CALL PrintCharAtPos
       
      INC DL 
      CMP DL, MAP_WIDTH
      JL draw_map_1_horizontal
        
      MOV DH, 0
      draw_map_1_vertical:
      ; Print border character at the left side of screen
      MOV DL, 0
      CALL SetMapDataXY
      CALL PrintCharAtPos
      
      ;Print border character at the right side of screen
      MOV DL, MAP_WIDTH - 1 
      CALL SetMapDataXY 
      CALL PrintCharAtPos
      
      INC DH
      CMP DH, MAP_HEIGHT
      JL draw_map_1_vertical  
      
   RET
   
   draw_map_2:
      ; No border
   
   end_draw_map:
   
   RET
InitializeMap ENDP
  
DrawSnake PROC  
   
   MOV AL, SNAKE_BODY_SYMBOL
   MOV AH, SNAKE_BODY_COLOR
   MOV DL, [snakeXSegements+1]
   MOV DH, [snakeYSegements+1] 
   CALL PrintCharAtPos 
   CALL SetMapDataXY
   ;
   MOV AL, SNAKE_HEAD_SYMBOL   
   MOV AH, SNAKE_HEAD_COLOR
   MOV DL, [snakeXSegements]
   MOV DH, [snakeYSegements] 
   CALL PrintCharAtPos        
   CALL SetMapDataXY           
   
   ; Remove old tail on screen by putting space char  
   CMP b.[oldSnakeTail], -1
   JE end_delete_old_tail
 
   MOV DL, [oldSnakeTail]
   MOV DH, [oldSnakeTail+1]   
   MOV AH, SPACE_COLOR
   MOV AL, ' ' 
   CALL PrintCharAtPos
   CALL SetMapDataXY   
   
   end_delete_old_tail:
   RET
DrawSnake ENDP

MoveSnake PROC  
   MOV SI, currentSnakeLength  
   
   ;Store old tail
   MOV AL, [snakeXSegements+SI-1]
   MOV AH, [snakeYSegements+SI-1]
   MOV [oldSnakeTail], AL
   MOV [oldSnakeTail+1], AH
    
   move_loop:  
      DEC SI 
      MOV AL, [snakeXSegements+SI-1]
      MOV AH, [snakeYSegements+SI-1] 
      MOV [snakeXSegements+SI], AL 
      MOV [snakeYSegements+SI], AH
      
      CMP SI, 1
      JG move_loop
   end_move_loop:  
   
   MOV SI, currentDirection 
   MOV AL, [DiX+SI]
   MOV AH, [DiY+SI]
   
   ADD [snakeXSegements], AL
   ADD [snakeYSegements], AH
   
   CALL CheckSnakeMoveOutSide  

   RET
MoveSnake ENDP

SnakeEatFood PROC
   INC currentSnakeLength
   MOV SI, currentSnakeLength
   
   MOV AL, [oldSnakeTail]
   MOV AH, [oldSnakeTail+1]
   MOV [snakeXSegements + SI -1], AL
   MOV [snakeYSegements + SI -1], AH
   
   MOV [oldSnakeTail], -1
   MOV [oldSnakeTail+1], -1 
   
   MOV AL, 1  
   MOV SI, 3
   increase_score_loop:  
      ADD [score + SI], AL 
      MOV AL, 0
      CMP [score + SI], '9'
      JLE next_loop
      MOV [score + SI], '0'
      MOV AL, 1
      next_loop:
      
      DEC SI
      CMP SI, 0
      JGE increase_score_loop    
   RET
SnakeEatFood ENDP

CheckSnakeMoveOutSide PROC
   CMP [snakeXSegements], MAP_WIDTH
   JL check_x_next 
   SUB [snakeXSegements], MAP_WIDTH
   check_x_next:
   CMP [snakeXSegements], 0
   JGE check_next:   
   ADD [snakeXSegements], MAP_WIDTH
    
   check_next:
   CMP [snakeYSegements], MAP_HEIGHT
   JL check_y_next
   SUB [snakeYSegements], MAP_HEIGHT    
   check_y_next:
   CMP [snakeYSegements], 0
   JGE end_1
   ADD [snakeYSegements], MAP_HEIGHT
   end_1:
   
   RET
CheckSnakeMoveOutSide ENDP
  
SpawnFood PROC  
   regen:
   MOV BL, 0
   MOV BH, MAP_WIDTH - 1
   CALL Random
   MOV DL, AH
   
   MOV BL, 0
   MOV BH, MAP_HEIGHT - 1
   CALL Random   
   MOV DH, AH
   
   CALL GetMapDataXY
   
   CMP AL, ' '
   JNE regen

   ; Draw food on screen
   MOV AL, FOOD_SYMBOL
   MOV AH, FOOD_COLOR  
   CALL PrintCharAtPos    
   CALL SetMapDataXY
   
   RET
SpawnFood ENDP

SetMapDataXY PROC   
   MOV BL, DH
   XOR BH, BH
   MOV SI, BX  
   SHL SI,1
   MOV DI, [mapDataRowIndex+SI]  
   MOV BL, DL
   ADD DI, BX
   MOV mapData[DI], AL
    
   RET
SetMapDataXY ENDP 


; DH = y pos, DL = x pos, AL will hold map pixel data
GetMapDataXY PROC
   MOV BL, DH
   XOR BH, BH
   MOV SI, BX 
   SHL SI,1
   MOV DI, [mapDataRowIndex+SI] 
   MOV BL, DL
   ADD DI, BX
   MOV AL,mapData[DI]                 
   
   RET
GetMapDataXY ENDP   

; SI -> offset of string, DH -> Y Pos, DL -> X Pos, AH = Color
PrintStringAtPos PROC
   
   write_string_loop:
      LODSB
      CMP AL, '$' 
      JE end_write_string_loop
      
      write_string_loop_do: 
      PUSH SI
      CALL PrintCharAtPos
      POP SI
      
      INC DL
      JMP write_string_loop
      
   end_write_string_loop:
   
   RET
PrintStringAtPos ENDP     

; DH = y pos, DL = x pos, al = char, ah = attribute
PrintCharAtPos PROC   
   PUSH AX
   PUSH CX
   
   MOV BL, AH 
   MOV BH, 0    
   
   MOV AH, 02h 
   INT 10h
   
   MOV AH, 9  
   MOV CX, 1
   INT 10h   
   
   POP CX
   POP AX
   RET
PrintCharAtPos ENDP

ClearScreen PROC 
   MOV AH, 0
   MOV AL, 03h
   INT 10h
                                                                             
   RET
ClearScreen ENDP   

; Random number: BL for min value, BH for max value, AH hold random value
Random PROC 
   PUSH DX
   
   MOV AH, 2Ch
   INT 21h;  Lâys ng?u nhiên  
   
   XOR AX, AX
   MOV AL, DL  
   XOR CX, CX
   MOV CL, BH
   SUB CL, BL
   INC CL
   DIV CL
   ADD AH, BL 
   
   POP DX
   RET
Random ENDP

ENDS main   