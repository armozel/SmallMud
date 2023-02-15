'From Cuis 6.0 [latest update: #5608] on 14 February 2023 at 7:59:17 pm'!
'Description '!
!provides: 'SmallMud' 1 9!
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


!SmallMudCommand methodsFor: 'as yet unclassified' stamp: 'RH 2/14/2023 17:15:16'!
aliases
	^aliases! !

!SmallMudCommand methodsFor: 'as yet unclassified' stamp: 'RH 2/14/2023 17:15:09'!
execute: aMessage
	self subclassResponsibility! !

!SmallMudCommand methodsFor: 'as yet unclassified' stamp: 'RH 2/14/2023 17:15:04'!
initialize
	name _ nil.
	aliases _ OrderedCollection new! !

!SmallMudCommand methodsFor: 'as yet unclassified' stamp: 'RH 2/14/2023 17:15:12'!
name
	^name! !

!SmallMudServer methodsFor: 'as yet unclassified' stamp: 'RH 2/14/2023 17:15:29'!
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

!SmallMudServer methodsFor: 'as yet unclassified' stamp: 'RH 2/14/2023 17:15:37'!
initPort: aPortNumber
	accessSema _ Semaphore forMutualExclusion.
	connections _ OrderedCollection new.
	listenerSocket _ SmallMudSocketListener port: aPortNumber backlogSize: 10 acceptor: self.
	self setupServerProcess
	! !

!SmallMudServer methodsFor: 'as yet unclassified' stamp: 'RH 2/14/2023 17:15:45'!
onAcceptConnection: aSocket
	accessSema critical: [connections addLast: (SocketStream on: aSocket)]! !

!SmallMudServer methodsFor: 'as yet unclassified' stamp: 'RH 2/14/2023 18:10:53'!
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

!SmallMudServer methodsFor: 'as yet unclassified' stamp: 'RH 2/14/2023 17:16:18'!
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

!SmallMudServer methodsFor: 'as yet unclassified' stamp: 'RH 2/14/2023 17:16:33'!
serverLoop
	[
		"I will update this to be a user defined tick rate"
		100 milliSeconds asDelay wait.
		self processMessages.
		self pruneStaleConnections
	] repeat! !

!SmallMudServer methodsFor: 'as yet unclassified' stamp: 'RH 2/14/2023 17:16:43'!
setupServerProcess
	serverProcess ifNotNil: [^false].
	serverProcess _ [self serverLoop] newProcess.
	serverProcess name: 'SmallMudServer'.
	serverProcess priority: Processor highIOPriority.
	serverProcess resume! !

!SmallMudServer class methodsFor: 'as yet unclassified' stamp: 'RH 2/14/2023 17:16:48'!
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

!SmallMudSocketListener class methodsFor: 'as yet unclassified' stamp: 'RH 2/14/2023 17:16:55'!
port: aPortNumber backlogSize: aBacklogSize acceptor: anObject
	^self new initPort: aPortNumber backlogSize: aBacklogSize acceptor: anObject! !
