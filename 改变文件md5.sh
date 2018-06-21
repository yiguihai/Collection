#While I agree with @sauravc, there is a way to do it if you don’t mind the possibility of corrupting the file.

#If you change the file in any way, you can recalculate the MD5.

#You can potentially change a file by opening it in your preferred editor, making an addition or subtraction, then saving it again.

#If you want a quick way to do this via command line, you can use either dd or truncate like this:

dd if=/dev/zero bs=1 count=10 >> <yourfile>.<ext>
or
truncate -s +10 <yourfile>.<ext>
#Either command should add 10 bytes to the end of your file. This should mean the MD5 (when next calculated) should be different.

#Beware

#This has the potential to corrupt your files, and should be tested thoroughly first.
