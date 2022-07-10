
.286

IDEAL
MODEL small
STACK 9999h

DATASEG

include "menu.asm"

; constant macros
PRESSED equ 1d
NOT_PRESSED equ 0d
MENU_CHAR equ 'm'
QUIT_CHAR equ 'q'
QUIT_OPTION equ 2d
MENU_COLOR equ 031H
START_MENU_ROW equ 2d 
START_MENU_COL equ 0d 
INVALID_PATH_VAL equ 1d
CONT_CHAR equ 'c'
VALID_FILE equ 0d
BMP_END_SIZE equ 4d	
BMP_COLS_AMOUNT equ 320d
BMP_ROWS_AMOUNT equ 200d
BMP_HEADER_SIZE equ 54d
BMP_PALETTE_SIZE equ 400h ; 256*4
SCREEN_START_OFFSET equ 0A000h
PATH_LENGTH equ 100d
OUTPUT_PATH_LENGTH equ 14d
MAX_FILES equ 10d
; function macros

arg1 equ [word ptr bp+4]
arg2 equ [word ptr bp+6]
arg3 equ [word ptr bp+8]
arg4 equ [word ptr bp+10]
arg5 equ [word ptr bp+12]

; variables
NUMBER_OF_FILES db 0d
PaletteBuffer db 300h dup(0)

_image_name db 'ascii.bmp',0

_error_image db 'Error.bmp', 0

_open_menu db 9d, 9d, 'Welcome! This is the ascii image generator system!',13 ,10, 13 ,10
db 9d, 9d, 'Please Enter the path for your image file.', 13, 10, 13 ,10
db 9d, 9d,'It has to be in BMP format 200x320.', 13, 10, 13 ,10
db 9d, 9d,'Enter path (Maximum 100 characters): ', '$'
output_file_name db 0, 'asciiGenResult.txt', 0 ; 30d dup(0)
len dw 20
y_coordinate dw 180
y_temp dw 0
x_coordinate dw 0
x_temp dw 0
color dw 60d
CURRENT_LINE_LENGTH equ 321d 
input_file_handle dw ?
input_file_path db 101 dup(0)
Palette db BMP_PALETTE_SIZE dup(0)
ScrLine db BMP_COLS_AMOUNT dup(0)
OutputLine db 1280 dup(0)
currentLine db CURRENT_LINE_LENGTH dup(0)
Header db BMP_HEADER_SIZE dup(0)
output_file_handle dw ?
error_file_handle dw ?
theme_file_handle dw ?
pathSuffix db '.bmp', 0







CODESEG



; Docs
; * open file spesified by filename
; * @param filename (arg1) string
; * @param file handle (arg2)
; void _open_file(const char *filename, Handle *file_handle)
proc _open_file
	push bp
	mov bp, sp
	push dx
	push si

	mov si, arg2 ; store handle object address
    mov ah, 3Dh
    xor al, al
    mov dx, arg1 ; push file name
	int 21h
    jc openerror ; check for errors
	mov [si], ax
	mov ax, VALID_FILE
    jmp opened_sucessfuly
    openerror:
		; display error theme
		mov ax, INVALID_PATH_VAL
	opened_sucessfuly:
	; restore registers
	pop si
	pop dx
	pop bp
    ret 4d
endp _open_file

; Docs
; display BMP error image
; * @param input_handle (arg1) handle
; void _display_error(Handle *input_handle)
proc display_error

	push bp
	mov bp, sp
	push si

	push offset Header
	push offset Palette
	push offset ScrLine
	push arg1
	push offset error_file_handle
	call display_image

	push [error_file_handle]
	call closefile
	pop si
	pop bp
	ret 2d
endp display_error

; Docs
; * Read BMP file's header
; * @param input_file_handle (arg1) string
; * @param header (arg2) string
; void _read_header(Handle *input_file_handle, char *header)
proc ReadHeader
	; read bmp file header, 54 bytes
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	push si
	mov si, arg1 ; input file handle
	mov ah, 3fh ;  read using handle
	mov bx, [si]
	mov cx, BMP_HEADER_SIZE
	mov dx, arg2
	int 21h

	; restore regs
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 4d

endp ReadHeader


; Docs
; * Read BMP file's palette
; * @param input_file_handle (arg1) string
; * @param palette (arg2) string
; void _read_palette(Handle *input_file_handle, char *palette)
proc ReadPalette
	; read BMP file color palette, 256 colors * 4 bytes (400h)
	push bp
	mov bp, sp
	push ax
	push cx
	push dx
	push si
	push bx

	mov ah, 3fh 
	mov cx, BMP_PALETTE_SIZE
	mov si, arg1
	mov bx, [si] ;  file handle
	mov dx, arg2 ; palette
	int 21h
	; restore
	pop bx
	pop si
	pop dx
	pop cx
	pop ax
	pop bp
	ret 4d
endp ReadPalette

; Docs
; * Read BMP file's line
; * @param input_file_handle (arg1) string
; * @param line (arg2) string
; void _read_out_line(Handle *input_file_handle, char *line)
proc ReadOutLine
	push bp
	mov bp, sp
	push ax
	push cx
	push dx
	push si
	push bx
	
	mov si, arg1 ; input file handle
	mov ah, 3fh
	mov cx, BMP_COLS_AMOUNT
	mov bx, [si]
	mov dx, arg2 ; address of line 
	int 21h
	; restore
	pop bx
	pop si
	pop dx
	pop cx
	pop ax
	pop bp
	ret 4d
endp ReadOutLine

; Docs
; * copy the colors palette to the video memory
; * The number of the first color should be sent to port 3C8h
; * The palette is sent to port 3C9h
; * copy BMP file's palette to video memory
; * @param palette (arg1) string
; void _copy_pal(const char *palette)
proc CopyPal
	push bp
	mov bp, sp
	push si
	push cx
	push dx
	push ax
	
	mov si, arg1 ; palette address
	mov cx, 256
	mov dx, 3C8h
	mov al, 0
	; copy starting color to port 3C8h
	out dx, al
	; copy palette itself to port 3C9h
	inc dx
	PalLoop:
		; Note: colors in a BMP file are saved as BGR values rather than RGB
		mov al, [si+2] ; get red value
		shr al, 2 ; Max. is 255, but vidro palette maximal value is 63,
		; therefore dividing by 4
		out dx, al ; send it
		mov al, [si+1] ; get green value
		shr al, 2
		out dx, al ; send it
		mov al, [si] ; get blue value
		shr al, 2
		out dx, al ; send it
		add si, 4 ; point to next color (There is a null chr, after every color, [si+3])
	loop palloop

	pop ax
	pop dx
	pop cx
	pop si
	pop bp
	ret 2d
		 
endp CopyPal

; Docs
; * copy image colors to the screen (each color value to the corresponding pixel) 
; * BMP graphics are saved upside-down
; * read the graphic line by line (200 lines in vga format)
; * displaying the lines from bottom to top
; * @param input_file_handle (arg1) handle
; * @param scrLine (arg2) line
; void _copy_bit_map(Handle *input_file_handle, char *scrLine)
proc CopyBitmap
	; BMP graphics are saved upside-down
	; read the graphic line by line (200 lines in vga format)
	; displaying the lines from bottom to top
	push bp
	mov bp, sp

	push ax
	push es
	push cx
	push di
	push si
	push dx
	push bx

	mov ax, SCREEN_START_OFFSET ; screen start
	mov es, ax
	mov cx, BMP_ROWS_AMOUNT
	PrintBMPLoop:
		push cx
		; di =cx*320, point to the correct screent line
		mov di, cx
		shl cx, 6
		shl di, 8
		add di, cx
		; Read one line, load line to ScrLine
		mov ah, 3fh ; read from handle object
		mov cx, BMP_COLS_AMOUNT
		mov si, arg1
		mov bx, [si] ; file handle
		mov dx, arg2 ; line segment
		int 21h
		; Copy one line into video memory
		cld ;  Clear diection flag, for movsb
		mov cx, BMP_COLS_AMOUNT
		mov si, arg2
		rep movsb ; Cope line to the screen
		; rep movsb is name as the follwing code:
		; mov es:di, ds:si
		; inc si
		; inc di
		; dec cx
		; ...;loop until cx=0
		pop cx
	loop PRINTBMPLOOP
	; restore
	pop bx
	pop dx
	pop si
	pop di
	pop cx
	pop es
	pop ax
	pop bp
	ret 4d
endp CopyBitmap

; Docs
; create new file
; * @param output_file_name (arg1) string
; * @param output_file_handle (arg2) handle
; void _create_file(const char *output_file_name, Handle *output_file_handle)
proc CreateFile
	push bp
	mov bp, sp
	push ax
	push cx
	push dx
	push si
	
	mov si, arg2; output file handle address
	mov ah, 3ch 
    mov cx, 1         
    mov dx, arg1 ; output_file name
    int 21h 
	jc createerror
    mov [si], ax
	jmp created_succesfuly
	createError:
	    push offset _error_image
		call display_error
		mov ah, 1
		int 21h
		; back to text mode
		mov ah, 0
		mov al, 2
		int 10h 
		mov dx, offset _open_menu
		mov ah, 09h
		int 21h
		; exit
		mov ax, 4c00h
    	int 21h
	created_succesfuly:

	pop si
	pop dx
	pop cx
	pop ax
	pop bp
    ret 4d
endp CreateFile

; Docs
; convert image specified by file to ascii image
; * @param input_file_handle (arg1) handle
; * @param output_file_handle (arg2) handle
; * @param output_line (arg3) string
; * @param current_line (arg4) string
; void _convert_pal_to_ascii(Handle *input_file_handle, Handle *output_file_handle
; 							char *output_line, char *current_line)
proc convertPalToAscii
	; BMP graphics are saved upside-down
	; read the graphic line by line (200 lines in vga format)
	; displaying the lines from bottom to top
	; move file cursor to last line
	push bp
	mov bp, sp
	push cx
	push dx
	push ax
	push bx
	push si
	push di

	mov cx, BMP_ROWS_AMOUNT
	WriteLines:
		push cx ; saves cx	

		; set file cursor to next line (from end to start)
		mov dx, cx ;  compute lines(from end)*320
		shl cx, 6
		shl dx, 8
		add dx, cx
		add dx, 1079d
		mov ah, 42h
		mov al, 00h
		mov si, arg1 ; input file handle
		mov bx, [si]
		xor cx, cx
		int 21h
		
		; di =cx*320, point to the correct screent line
		push arg3 ; output_line
		push arg1 ; input file handle
		call readoutline

		mov si, arg3 ; output line
		mov di, arg4 ; current line 
		mov cx, BMP_COLS_AMOUNT
		convertLineToAscii:
			; mov ax, [si]
			; convert index pixel*table_length / 255
			xor ah, ah
			mov al, [byte ptr si]
			push di ;  saves current_line ptr
			mov di, offset ascii_table
			add di, ax
			mov al, [byte ptr di]
			pop di ; restore current line ptr
			mov [byte ptr di], al ; store new ascii value in current line
			inc di
			inc si
		loop convertlinetoascii
		mov [byte ptr di], 10d ; new line
		; write line to out file
		mov ah, 40h
		mov si, arg2 ; output file handle
		mov bx, [si]
		mov cx, 321
		mov dx, arg4 ; current line to write
		int 21h
		
		pop cx ; restore cx
	loop WriteLines
	; restore regs
	pop di
	pop si
	pop bx
	pop ax
	pop dx
	pop cx
	pop bp
	ret 8d
endp convertPalToAscii

; Docs
; close file
; * @param file_handle (arg1) handle
; void _close(Handle *file_handle)
proc closeFile
	; saves regs
	push bp
	mov bp, sp
	push ax
	push bx

	mov ah, 3Eh
	mov bx, arg1 ; file handle 
	int 21h
	; restore regs
	pop bx
	pop ax
	pop bp
	ret 2d
endp closeFile

; Docs
; display BMP image specified by input file
; * @param input_handle (arg1) handle
; * @param input_name (arg2) const char *
; * @param ScrLine (arg3) char *
; * @param Palette (arg4) char *
; * @param Header (arg5) char *
; void _display_image(Handle *input_handle, const char * input_name,
; char *ScrLine, char *Palette, char *Header)
proc display_image
	push bp
	mov bp, sp
	push ax
	push si

	mov ax, 13h
	int 10h 

	push arg1
	push arg2
	call _OPEN_FILE

	push arg5
	push arg1
	call READHEADER

	push arg4
	push arg1
	call READPALETTE
	
	push arg4
	call COPYPAL
	
	push arg3
	push arg1
	call COPYBITMAP
	

	pop si
	pop ax
	pop bp
	ret 10d

endp display_image

; Docs
; checks if the path given by the user if valid
; * @param last_four_bytes (arg1) handle
; void _valid_path(const char *last_four_bytes)
proc validPath
	push bp
	mov bp, sp
	push si
	push di
	push cx
	mov si, arg1 ; last four bytes of path

	mov di, offset pathsuffix
	mov cx, BMP_END_SIZE
	compareBytes:

		mov dl, [byte ptr di]
		cmp dl, [byte ptr si]
		JNE invalidPath
		
		inc di
		inc si
	loop comparebytes
	jmp IsvalidPath
	invalidPath:
		push offset _error_image
		call display_error
		mov ax, INVALID_PATH_VAL
		jmp endValidPath
	IsvalidPath:
	mov ax, VALID_FILE
	; check file could be opened
	push offset input_file_handle
	push offset input_file_path
	call _open_file
	cmp ax, INVALID_PATH_VAL
	je invalidpath
	endValidPath:
	pop cx
	pop di
	pop si
	pop bp
	ret 2d
endp validPath

; Docs
; get image path from user
; int _get_client_path()
proc getClientPath
	push bp
	mov bp, sp
	push cx
	push si
	push dx

	mov si, offset input_file_path
	mov cx, PATH_LENGTH
	getCharacters:
		; get character
		mov ah, 1h
		int 21h
		cmp al, 13d ; compare to enter
		JE finishedReading
		mov [byte ptr si], al
		inc si
	loop getcharacters
	finishedReading:
		mov [byte ptr si], 0d ; null character
		sub si, BMP_END_SIZE ; last four bytes
		; mov ah, 02d
		; mov al, [byte ptr si]
		; int 21h
		push si
		; chack if path ends with .bmp
		call validPath 
		cmp ax, VALID_FILE ; no error
	JE continueClientPath
	; load one character
	waitForContCharacters:
		mov ah, 06h
		mov dl, 0FFh
		int 21h
		cmp al, CONT_CHAR ; cont
		JE finished_continue
		cmp al, QUIT_CHAR ; quit
		JE quit_finished
	JMP waitForContCharacters ; restrict to m, q
	finished_continue:
		mov ax, INVALID_PATH_VAL
		jmp CONTINUECLIENTPATH
	quit_finished:
	
		mov ax, QUIT_OPTION
	continueClientPath:
	pop dx
	pop si
	pop cx
	pop bp
	ret
endp getclientpath

; Docs
; sets cursor position
; int _set_cursor_pos()
proc set_cursor_pos
	push bp
	mov bp, sp
	push ax
	push bx
	mov ah, 02
	mov bh, 0 ; page number (0 for graphics modes)
	; dh = row
	; dl = col
	int 10h
	pop bx
	pop ax
	pop bp
	ret
endp set_cursor_pos

; Docs
; displays the program menu
; int _display_menu()
proc display_menu
	push bp
	mov bp, sp

	; back to text mode
	doTillValidPathOrQuit:
		mov ah, 0
		mov al, 2
		int 10h
		; change bkacground color
		mov ah, 00
		mov al, 03
		int 10h
		; set color
		mov ah, 09    ; DISPLAY OPTION
		mov bh, 00    ; PAGE 0
		mov al, 20H   ; ASCII FOR SPACE
		mov cx, 800H  ; REPEAT IT 800H, to fill screen
		mov bl, MENU_COLOR  ; COLOR
		int 10H

		; set cursor position
		mov dh, START_MENU_ROW ; row
		mov dl, START_MENU_COL ; col
		call set_cursor_pos
		mov dx, offset menu
		mov ah, 09h
		int 21h
		; print menu string

		mov dx, offset _open_menu
		mov ah, 09h
		int 21h
		; get client path and validate
		call getclientpath
		cmp ax, INVALID_PATH_VAL
		JE dotillvalidpathorquit
	pop bp
	ret
endp display_menu

; Docs
; contorls the program flow
; int _control_flow()
proc control_flow
	push bp
	mov bp, sp
	pusha
	mov ax, 1h
	int 33h
	; wait for character
	wait_for_character:
		mov ah, 06h
		mov dl, 0FFh
		int 21h
		cmp al, MENU_CHAR ; menu
		JE menu_case
		cmp al, QUIT_CHAR ; quit
		JE quit_case
		push [len]
		push [y_coordinate]
		push [x_coordinate]
		call press_button
		cmp ax, PRESSED
		JAE menu_case
	JMP wait_for_character ; restrict to m, q
	menu_case:
		call display_menu
		cmp ax, QUIT_OPTION
		JE quit_case
		jmp end_control_flow
	quit_case:
		mov ah, 0
		mov al, 2
		int 10h 
		mov ax, 4c00h
    	int 21h
	end_control_flow:
	popa
	pop bp
	ret
endp control_flow

; Docs
; draws a rectangle
; * @param x_coordinate (arg1) int
; * @param y_coordinate (arg2) int
; * @param len (arg3) int
; * @param color (arg4) int
; int _draw_rect(int x_coordinate, int y_coordinate, int len, int color)
proc draw_rect
	push bp
	mov bp, sp
	pusha
	mov cx, arg3 ; len
	mov ax, arg2 ; y
	mov [y_temp], ax
	rect:
		push arg4
		push arg3
		push [y_temp]
		push arg1
		call draw_line
		inc [y_temp] ;column
	loop rect
	popa
	pop bp
	ret 8d
endp draw_rect

; Docs
; draws a line
; * @param x_coordinate (arg1) int
; * @param y_coordinate (arg2) int
; * @param len (arg3) int
; * @param color (arg4) int
; int _draw_line(int x_coordinate, int y_coordinate, int len, int color)
proc draw_line
	push bp
	mov bp, sp
	pusha
	; move x_coordinate to x_temp
	mov ax, arg1 ; x
	mov [x_temp], ax
	mov cx, arg3
	draw:
	; push color, x, y
	push arg4 ; color
	push arg2 ; y
	push [x_temp] ; x
	call draw_pixel
	inc [x_temp]
	loop draw
	popa
	pop bp
	ret 8d
endp draw_line

; Docs
; draws a pixel in a position
; * @param x_coordinate (arg1) int
; * @param y_coordinate (arg2) int
; * @param color (arg3) int
; int _draw_pixel(int x_coordinate, int y_coordinate, int color)
proc draw_pixel
	push bp
	mov bp, sp
	pusha
	xor bh, bh ; bh = 0
	mov cx, arg1
	mov dx, arg2
	mov ax, arg3
	mov ah, 0ch
	int 10h
	popa
	pop bp
	ret 6d
endp draw_pixel

; Docs
; displays the main theme
; * @param image_path (arg1) const char *
; void _display_theme(const char *image_path)
proc display_theme
	push bp
	mov bp, sp
	push si

	push offset Header
	push offset Palette
	push offset ScrLine
	push arg1 ; image path
	push offset theme_file_handle
	call display_image

	push [theme_file_handle]
	call closefile

	pop si
	pop bp
	ret 2d
endp display_theme

; Docs
; checks if the user pressed the mouse buttons, and if the cursor was in the square
; [arg1, arg1+len] X [arg2, arg2 + len] (cartesean multiplication)
; * @param x_coordinate (arg1) int
; * @param y_coordinate (arg2) int
; * @param length (arg3) int
; * @return ax stores 1 if it is true, 0 otherwise
; int _press_button(int x_coordinate, int y_coordinate, int len)
proc press_button
	push bp
	mov bp, sp
	
	xor ax, ax
	mov ax, 3h ; read mouse status and position
	int 33h
	mov ax, NOT_PRESSED
	cmp bx, PRESSED ; check left mouse click
	JNE end_press_button; if left click not pressed….
	; compare x
	push ax
	mov ax, arg1
	cmp cx, ax ; column
	pop ax
	JL end_press_button
	push ax
	mov ax, arg1
	add ax, arg3
	cmp cx, ax
	pop ax
	JA end_press_button
	; compare y
	push ax
	mov ax, arg2
	cmp dx, ax ; row
	pop ax
	JL end_press_button
	push ax
	mov ax, arg2
	add ax, arg3
	cmp dx, ax
	pop ax
	JA end_press_button
	mov ax, PRESSED
	end_press_button:
	pop bp
	ret 6d
endp press_button


; Docs
; display BMP image specified by input file, but doesn't open file in the begining
; * @param input_handle (arg1) handle
; * @param input_name (arg2) const char *
; * @param ScrLine (arg3) char *
; * @param Palette (arg4) char *
; * @param Header (arg5) char *
; void _display_user_image(Handle *input_handle, const char * input_name,
; char *ScrLine, char *Palette, char *Header)
proc display_user_image
	push bp
	mov bp, sp
	mov ax, 13h
	int 10h 
	push arg5
	push arg1
	call READHEADER

	push arg4
	push arg1
	call READPALETTE
	
	push arg4
	call COPYPAL
	
	push arg3
	push arg1
	call COPYBITMAP
	mov si, arg1
	push [si]
	call closefile
	pop bp
	ret 10d

endp display_user_image

; Docs
; convert image fiven by user to ascii and save it in the file "ASCIIGEN<num>.txt"
; void _convert_to_ascii_all()
proc convert_to_ascii_all
	push bp
	mov bp, sp
	pusha

	; push ds
	; push offset PaletteBuffer
	; call savepalette
	
	push offset Header
	push offset Palette
	push offset ScrLine
	push offset input_file_path
	push offset input_file_handle
	call display_user_image

	push offset input_file_handle
	push offset input_file_path
	call _open_file

	push offset output_file_handle
	push offset output_file_name
	call createfile

	; process BMP file
	push offset Header
	push offset input_file_handle
	call ReadHeader

	push offset Palette
	push offset input_file_handle
	call Readpalette
	
	push offset currentLine
	push offset OutputLine
	push offset output_file_handle
	push offset input_file_handle
	call convertPalToAscii

	; wait for key press

	mov ah, 1h
	int 21h

	; back to text mode

	mov ah, 0
	mov al, 2
	int 10h 
	
	; close output file
	push [output_file_handle]
	call closefile
	push [input_file_handle]
	call closefile

	popa
	pop bp
	ret 

endp convert_to_ascii_all

start:
    mov ax, @data
    mov ds, ax

	keep_doing_till_quit:
		; convert path
		mov al, [number_of_files]
		add al, 48d
		mov [output_file_name], al

		push offset _image_name
		call display_theme

		push [color]
		push [len]
		push [y_coordinate]
		push [x_coordinate]
		call draw_rect
	
		call control_flow

		call convert_to_ascii_all

		inc [number_of_files]
		mov al, [number_of_files]
		cmp al, MAX_FILES
		JE exit
	jmp keep_doing_till_quit




exit:
    mov ax, 4c00h
    int 21h


END start
