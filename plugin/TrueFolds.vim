" Author:  Gnedov Pavel
" License: GPLv3

if !has('python')
    echo "Error: Required vim compiled with +python"
    finish
endif

" ##############################################################################

python << endpython

import vim
import re
import logging

try:
	class TrueFolds:
		# def setText( self, t ):
		# 	self.text = t.split("\n")

		def __init__(self):
			logging.basicConfig( filename='truefolds.log', level=logging.ERROR, format='%(filename)s:%(lineno)s %(levelname)s:%(message)s' )

		def getLine( self, n ):
			if n <= self.getLength():
				return vim.current.buffer[n-1]
			else:
				return None
	
		def getLength(self):
			try:
				return len( vim.current.buffer )
			except Exception, e:
				return 0
	
		def setTabSize( self, ts ):
			self.tabSize = ts
	
		def setShiftWidth( self, sw ):
			self.shiftWidth = sw
	
		def getSpaceSize( self, n ):
			count = 0
			line = self.getLine(n)
			first = True
			notSpace = re.compile("\S")
			notWord = re.compile("\W")
			if line != None:
				for symbol in line:
					if symbol == " ":
						first = False
						count = count + 1
					elif symbol == "\t":
						first = False
						count = count + self.tabSize
					elif notWord.match(symbol) and notSpace.match(symbol) and first:
						continue
					else:
						break
			return count

		def getNotSpaceSymbol( self, n ):
			count = 0
			line = self.getLine(n)
			if line != None:
				for symbol in line:
					if ( symbol == " " ) or ( symbol == "\t" ):
						count = count + 1
					else:
						break
			return count+1
	
		def getLevel( self, n ):
			return ( self.getSpaceSize(n) // self.shiftWidth )
	
		def isEmptyLine( self, n ):
			regexp = re.compile(".*\\w.*")
			if ( regexp.match( self.getLine(n) ) ) or ( self.isClosedLine(n) ) or ( self.isOpenedLine(n) ):
				return False
			else:
				return True
	
		def isClosedLine( self, n ):
			regexp = re.compile("^\\s*[\\}\\]\\)].*$")
			if regexp.match( self.getLine(n) ):
				return True
			else:
				return False

		def isOpenedLine( self, n ):
			regexp = re.compile("^\\s*[\\{\\[\\(]$")
			if regexp.match( self.getLine(n) ):
				return True
			else:
				return False
	
		def isCommentLine( self, n ):
			line = self.getLine(n)
			symbol = self.getNotSpaceSymbol(n)
			syn = vim.eval( "synIDattr(synIDtrans(synID(" + str(n) + "," + str(symbol) + ",1)),\"name\")" )
			if syn == "Comment":
				return True
			else:
				return False

		def getNextNonEmptyLine( self, n ):
			i = n + 1
			l = self.getLength()
			while i < l:
				if not( self.isEmptyLine(i) ):
					break
				i = i + 1
			return i

		def getPrevNonEmptyLine( self, n ):
			i = n - 1
			while i >= 0:
				if not( self.isEmptyLine(i) ):
					break
				i = i - 1
			if i < 0:
				i = 0
			return i
	
		def getTrueLevel( self, n ):
			res = ""
			prevLine     = self.getPrevNonEmptyLine(n)
			nextLine     = self.getNextNonEmptyLine(n)
			nextNextLine = self.getNextNonEmptyLine(nextLine)
			prevLevel    = self.getLevel( prevLine )
			currentLevel = self.getLevel(n)
			nextLevel    = self.getLevel( nextLine )
			nextNextLevel= self.getLevel( nextNextLine )
			if self.isCommentLine(n):
				if ( self.isCommentLine(n+1) ) and ( not( self.isCommentLine(n-1) ) ):
					res = ">" + str( currentLevel + 1 )
				elif self.isCommentLine(n-1):
					res = str( currentLevel + 1 )
				else:
					res = str(currentLevel)
			elif self.isClosedLine(n):
				res = str(currentLevel+1)
			elif self.isOpenedLine(n):
				if ( prevLevel < currentLevel ) or ( self.isClosedLine(prevLine) ):
					res = ">" + str(nextLevel)
				else:
					res = str(nextLevel)
			elif self.isEmptyLine(n):
				if ( self.isClosedLine( nextLine ) ):
					res = str(prevLevel)
				else:
					res = str( nextLevel )
			else:
				if ( nextLevel > currentLevel ):
					res = ">" + str(nextLevel)
				elif ( ( nextLevel == currentLevel ) and ( self.isOpenedLine(nextLine) ) ):
					res = ">" + str(nextNextLevel)
				else:
					res = str(currentLevel)
			return res
	
	trueFolds = TrueFolds()
	trueFolds.setTabSize( int( vim.eval("&ts") ) )
	trueFolds.setShiftWidth( int( vim.eval("&shiftwidth") ) )
	
except Exception, e:
	logging.error( 'Exception at init TrueFolds: ' + e )
	print(e)

endpython

" ##############################################################################

function! TrueFoldsLevel(lnum)
python << endpython
import vim
import re

try:
	lnum = int( vim.eval("a:lnum") )
	level = trueFolds.getTrueLevel(lnum)
	vim.command( "return \"" + str(level) + "\"" )

except Exception, e:
	logging.error( 'Exception at TrueFoldsLevel ' + e )
	print(e)

endpython
endfunction

" ##############################################################################

function! TrueFoldsUpdateSettings()
python << endpython

try:
	trueFolds.setTabSize( int( vim.eval("&ts") ) )
	trueFolds.setShiftWidth( int( vim.eval("&shiftwidth") ) )

except Exception, e:
	logging.error( 'Exception at TrueFoldsUpdateSettings ' + e )
	print(e)

endpython
endfunction
