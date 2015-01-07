export path
path or= {}

require 'pstructs'

import getinfo from debug
import Stack from pstruct
import Read, Write, Open, Exists, IsDir, MakeDir from file
import find, sub, match, len from string
import concat from table

select = select

path.curfile = ->
	getinfo(2, 'S').short_src
path.cwd = ->
	match(getinfo(2, 'S').short_src, '(.*)/.*%.[^.]*')


--@ path - the path to process
-- returns folder name, filename, extension
path.parts = (path) ->
	match(path, '(.*)/(.*)%.([^.]*)')
file = (path) ->
	match(path, '.*/(.*)%.[^.]*')
path.file = file
directory = (path) ->
	match(path, '(.*)/.*%.[^.]*')
path.directory
extension = (path) ->
	match(path, '.*/.*%.([^.]*)')
path.extension

--! condenses the given process. processes .. and condenses empty //'s that might work their way in
--@ path - the path to process
path.condense = (...) ->
	stack = Stack()

	numparts = select('#', ...)
	curpart = 1
	path = select(curpart, ...)

	last = 0
	while true
		next = find(path, '/', last+1)

		seg = sub(path, last+1, next and next-1)
		if len(seg) > 0 then
			if seg == '..' then
				stack\pop!
			elseif seg ~= '.'
				stack\push(seg)

		if next
			last = next
		elseif curpart < numparts
			curpart += 1
			path = select(curpart, ...)
			last = 0
		else
			break

	concat(stack\getValues(), '/')

path.join = (...) ->
	path.condense(concat({...}))

path.rebase = (path, root) ->
	_, rootIndex = find(path, root, 1, true)
	if rootIndex
		sub(path, rootIndex+2)
	else
		path
