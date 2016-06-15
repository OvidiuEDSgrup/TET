
CREATE procedure wPostezPlin @sesiune varchar(50), @parXML xml
as
	/** Procedura se apeleaza in momentul in care se inchide o macheta de plati incasari
		in webConfigTipuri coloana ProcInchidereMacheta
	**/
	declare 
		@sb varchar(9), @tip varchar(2), @numar varchar(40), @data datetime

	set @sb=@parXML.value('(/*/@subunitate)[1]','varchar(9)')
	set @tip=@parXML.value('(/*/@tip)[1]','varchar(2)')
	set @numar=@parXML.value('(/*/@cont)[1]','varchar(40)')
	set @data=@parXML.value('(/*/@data)[1]','datetime')

	if exists (select 1 from DocDeContat where Subunitate=@sb and Tip='PI' and Numar=@numar and Data=@data)
		exec faInregistrariContabile @dinTabela=0, @Subunitate=@sb,@Tip='PI',@Numar=@numar, @Data=@data
