
CREATE procedure wPostezInPozDoc @sesiune varchar(50), @parXML xml
as
	/** Procedura se apeleaza in momentul in care se inchide o macheta de Document PozDoc (RM, AP, AS ....)-> va trebui pus la toate 
		in webConfigTipuri coloana ProcInchidereMacheta
	**/
	declare 
		@sb varchar(9), @tip varchar(2), @numar varchar(20), @data datetime

	set @sb=@parXML.value('(/*/@subunitate)[1]','varchar(9)')
	set @tip=@parXML.value('(/*/@tip)[1]','varchar(2)')
	set @numar=@parXML.value('(/*/@numar)[1]','varchar(20)')
	set @data=@parXML.value('(/*/@data)[1]','datetime')

	exec faInregistrariContabile @dinTabela=0, @Subunitate=@sb,@Tip=@tip,@Numar=@numar, @Data=@data
