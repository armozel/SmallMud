'From Cuis 6.0 [latest update: #5608] on 14 February 2023 at 2:22:40 pm'!
'Description '!
!provides: 'SmallMud' 1 7!
SystemOrganization addCategory: 'SmallMud-Core'!
SystemOrganization addCategory: 'SmallMud-Network'!
SystemOrganization addCategory: 'SmallMud-Utils'!
SystemOrganization addCategory: 'SmallMud'!


!classDefinition: #SmallMudCommand category: 'SmallMud-Core'!
Object subclass: #SmallMudCommand
	instanceVariableNames: 'name aliases'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'SmallMud-Core'!
!classDefinition: 'SmallMudCommand class' category: 'SmallMud-Core'!
SmallMudCommand class
	instanceVariableNames: ''!

!classDefinition: #SmallMudServer category: 'SmallMud-Network'!
Object subclass: #SmallMudServer
	instanceVariableNames: 'accessSema connections listenerSocket serverProcess'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'SmallMud-Network'!
!classDefinition: 'SmallMudServer class' category: 'SmallMud-Network'!
SmallMudServer class
	instanceVariableNames: ''!

!classDefinition: #SmallMudSocketListener category: 'SmallMud-Network'!
Object subclass: #SmallMudSocketListener
	instanceVariableNames: 'socket port backlogSize listenProcess'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'SmallMud-Network'!
!classDefinition: 'SmallMudSocketListener class' category: 'SmallMud-Network'!
SmallMudSocketListener class
	instanceVariableNames: ''!

!classDefinition: #AnsiCode category: 'SmallMud-Utils'!
Object subclass: #AnsiCode
	instanceVariableNames: 'code name'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'SmallMud-Utils'!
!classDefinition: 'AnsiCode class' category: 'SmallMud-Utils'!
AnsiCode class
	instanceVariableNames: ''!

!classDefinition: #AnsiColor category: 'SmallMud-Utils'!
AnsiCode subclass: #AnsiColor
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'SmallMud-Utils'!
!classDefinition: 'AnsiColor class' category: 'SmallMud-Utils'!
AnsiColor class
	instanceVariableNames: ''!


!SmallMudCommand methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 09:58:39'!
aliases
	^aliases! !

!SmallMudCommand methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 09:58:53'!
execute: aMessage
	self subclassResponsibility! !

!SmallMudCommand methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 10:20:02'!
initialize
	name _ nil.
	aliases _ OrderedCollection new.
	messageParts _ nil! !

!SmallMudCommand methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 09:58:31'!
name
	^name! !

!SmallMudServer methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 13:48:06'!
destroy
	serverProcess ifNotNil: [
		serverProcess terminate.
		serverProcess _ nil].
	listenerSocket ifNotNil: [
		listenerSocket destroy.
		listenerSocket _ nil].
	(connections notNil and: [connections notEmpty])
		ifTrue: [
			connections do: [:c | c destroy].
			connections _ OrderedCollection new]! !

!SmallMudServer methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 13:51:41'!
initPort: aPortNumber
	accessSema _ Semaphore forMutualExclusion.
	connections _ OrderedCollection new.
	listenerSocket _ SmallMudSocketListener port: aPortNumber backlogSize: 10 acceptor: self.
	self setupServerProcess
	! !

!SmallMudServer methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 14:19:46'!
onAcceptConnection: aSocket
	accessSema critical: [connections addLast: (SocketStream on: aSocket)]! !

!SmallMudServer methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 14:20:21'!
processMessages
	accessSema critical: [
		connections do: [:c |
			|msg|
			msg _ c nextLineCrLf.
			(msg notNil and: [msg notEmpty]) 
				ifTrue: [
					Transcript show: 'Received message: ', msg asString.
					c sendCommand: 'ECHO: ', msg]
		]
	]! !

!SmallMudServer methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 14:21:05'!
pruneStaleConnections
	accessSema critical: [
		|foundStale|
		foundStale _ false. 
		 connections do: [:c |
			c isConnected ifFalse: [
				c destroy.
				foundStale _ true]].
		foundStale ifTrue: [
			connections _ connections select: [:c | c isConnected]]
	]! !

!SmallMudServer methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 13:47:44'!
serverLoop
	[
		"I will update this to be a user defined tick rate"
		100 milliSeconds asDelay wait.
		self processMessages.
		self pruneStaleConnections.
	] repeat.! !

!SmallMudServer methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 12:01:57'!
setupServerProcess
	serverProcess ifNotNil: [^false].
	serverProcess _ [self serverLoop] newProcess.
	serverProcess name: 'SmallMudServer'.
	serverProcess priority: Processor highIOPriority.
	serverProcess resume.! !

!SmallMudServer class methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 12:00:11'!
port: aPortNumber
	^self new initPort: aPortNumber! !

!SmallMudSocketListener methodsFor: 'public' stamp: 'RPH 2/14/2023 11:20:30'!
destroy
	listenProcess ifNotNil: [
		listenProcess terminate.
		listenProcess _ nil].
	socket ifNotNil: [
		socket destroy.
		socket _ nil]! !

!SmallMudSocketListener methodsFor: 'public' stamp: 'RPH 2/14/2023 13:50:39'!
initPort: aPortNumber backlogSize: aBacklogSize acceptor: anObject
	port _ aPortNumber.
	backlogSize _ aBacklogSize.
	self when: #acceptConnection send: #onAcceptConnection: to: anObject.
	self setupSocket.
	self setupProcess! !

!SmallMudSocketListener methodsFor: 'public' stamp: 'RPH 2/14/2023 11:20:52'!
isValid
	^listenProcess notNil! !

!SmallMudSocketListener methodsFor: 'private' stamp: 'RPH 2/14/2023 14:22:32'!
listenLoop

	[
		|connection|
		connection _ 
			socket waitForAcceptFor: 10 ifTimedOut: [nil].
		(connection notNil and:[connection isConnected]) ifTrue: [
			self triggerEvent: #acceptConnection with: connection.
			self changed: self].
		connection _ nil.
	] repeat! !

!SmallMudSocketListener methodsFor: 'private' stamp: 'RPH 2/14/2023 13:46:11'!
setupProcess
	listenProcess ifNotNil: [^false].
	listenProcess _ [self listenLoop] newProcess.
	listenProcess name: 'SmallMudSocketListener'.
	listenProcess priority: Processor highIOPriority.
	listenProcess resume.
	^true! !

!SmallMudSocketListener methodsFor: 'private' stamp: 'RPH 2/14/2023 14:10:28'!
setupSocket
	socket ifNotNil: [^false].
	socket _ Socket newTCP.
	socket initializeNetwork.
	socket listenOn: port backlogSize: backlogSize.
	Transcript show: 'Listener Socket: ', socket asString.
	^true! !

!SmallMudSocketListener class methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 13:51:13'!
port: aPortNumber backlogSize: aBacklogSize acceptor: anObject
	^self new initPort: aPortNumber backlogSize: aBacklogSize acceptor: anObject! !

!AnsiCode methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 10:23:15'!
code
	^code! !

!AnsiCode methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 10:23:38'!
initCode: aNumber name: aString
	code _ aNumber.
	name _ aString! !

!AnsiCode methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 10:23:21'!
name
	^name! !

!AnsiCode methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 10:24:30'!
toEscapedCode
	code ifNil: [^nil].
	^ Character escape asString, '[', code asString, 'm'! !

!AnsiCode class methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 10:40:43'!
Bold
	^self code: 1 name: 'bold'! !

!AnsiCode class methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 10:25:18'!
Reset
	^self code: 0 name: 'reset'! !

!AnsiCode class methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 10:41:19'!
Reverse
	^self code: 7 name: 'reverse'! !

!AnsiCode class methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 10:40:56'!
Underline
	^self code: 4 name: 'underline'! !

!AnsiCode class methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 10:25:00'!
code: aNumber name: aString
	^self new initCode: aNumber name: aString! !

!AnsiColor methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 10:39:30'!
toBright
	code ifNil: [^nil].
	^ Character escape asString, '[', code asString, ';1m'.! !

!AnsiColor methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 10:26:05'!
toPlain
	^super toEscapedCode.! !

!AnsiColor class methodsFor: 'foreground colors' stamp: 'RPH 2/14/2023 10:38:17'!
BlackFg
	^self code: 30 name: 'black'! !

!AnsiColor class methodsFor: 'foreground colors' stamp: 'RPH 2/14/2023 10:38:23'!
BlueFg
	^self code: 34 name: 'blue'! !

!AnsiColor class methodsFor: 'foreground colors' stamp: 'RPH 2/14/2023 10:38:26'!
CyanFg
	^self code: 36 name: 'cyan'! !

!AnsiColor class methodsFor: 'foreground colors' stamp: 'RPH 2/14/2023 10:38:30'!
GreenFg
	^self code: 32 name: 'green'! !

!AnsiColor class methodsFor: 'foreground colors' stamp: 'RPH 2/14/2023 10:38:33'!
MagentaFg
	^self code: 35 name: 'magenta'! !

!AnsiColor class methodsFor: 'foreground colors' stamp: 'RPH 2/14/2023 10:38:36'!
RedFg
	^self code: 31 name: 'red'! !

!AnsiColor class methodsFor: 'foreground colors' stamp: 'RPH 2/14/2023 10:38:39'!
WhiteFg
	^self code: 37 name: 'white'! !

!AnsiColor class methodsFor: 'foreground colors' stamp: 'RPH 2/14/2023 10:38:42'!
YellowFg
	^self code: 33 name: 'yellow'! !

!AnsiColor class methodsFor: 'background colors' stamp: 'RPH 2/14/2023 10:37:44'!
BlackBg
	^self code: 40 name: 'black'! !

!AnsiColor class methodsFor: 'background colors' stamp: 'RPH 2/14/2023 10:37:49'!
BlueBg
	^self code: 44 name: 'blue'! !

!AnsiColor class methodsFor: 'background colors' stamp: 'RPH 2/14/2023 10:37:52'!
CyanBg
	^self code: 46 name: 'cyan'! !

!AnsiColor class methodsFor: 'background colors' stamp: 'RPH 2/14/2023 10:37:59'!
GreenBg
	^self code: 42 name: 'green'! !

!AnsiColor class methodsFor: 'background colors' stamp: 'RPH 2/14/2023 10:38:03'!
MagentaBg
	^self code: 45 name: 'magenta'! !

!AnsiColor class methodsFor: 'background colors' stamp: 'RPH 2/14/2023 10:38:06'!
RedBg
	^self code: 41 name: 'red'! !

!AnsiColor class methodsFor: 'background colors' stamp: 'RPH 2/14/2023 10:38:10'!
WhiteBg
	^self code: 47 name: 'white'! !

!AnsiColor class methodsFor: 'background colors' stamp: 'RPH 2/14/2023 10:38:13'!
YellowBg
	^self code: 43 name: 'yellow'! !

!AnsiColor class methodsFor: 'as yet unclassified' stamp: 'RPH 2/14/2023 10:37:24'!
code: aNumber name: aString
	^self new initCode: aNumber name: aString! !
