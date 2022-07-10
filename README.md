# ASCII Image Generator
This is an Image to Ascii Converter written in T-assembly (TASM).

## How to run?
    1. Choose your image file.
    2. Convert The Image to BMP format (you may find the following website useful: https://convertio.co/jpg-bmp/)
    3. Run the script "convert.py": python3 convert.py <path to BMP image>
    4. Put all the source files supplied in the directory "source files" in your TASM/BIN folder, together with your converted image.
    5. Open dos box at the TASM/BIN directory/
    6. compile the program: tasm /zi base.asm
    7. linkage: tlink /v base.obj
    8. RUN: base
NOTE: We already included a compiled version, so you can simply run ASCIIG in DOSBOX.

## Further Explainations
    You can read more about the project in the MoreInfo/book.docs file.
    You can See an output exaple in the Example directory.

## Remarks
    1. After generating the ascii-image, you will recieve a text file (<number>ASCIIGE.txt)with its data, In order to get a full view of the image, you should zoom out in your text editor.
    2. Sometimes the convertion between jpg/png images to BMP might not work in the supplied website, because of size issues, to avoid that, don't use too massive images (Like the "HEIC" format in Apple IPhones).
