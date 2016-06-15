
create procedure wOPAlegCursuriValute @sesiune varchar(50), @parXML xml
as
begin
	declare	@procedura varchar(200)

	set @procedura= @parXML.value('(/*/@procedura)[1]','varchar(200)')
	
	IF OBJECT_ID('tempdb..#tmpcursuri') IS NOT NULL
		drop table #tmpcursuri

	create table #tmpcursuri(valuta varchar(20), curs float)

	/** Populam tabela ce se va folosi in DifCursFact */
	insert into #tmpcursuri (valuta, curs)
	select
		D.c.value('(@valuta)[1]','varchar(20)'),D.c.value('(@curs)[1]','float')
	FROM @parXML.nodes('*/DateGrid/row') D(c)

	/** Apelam procedura de generare cu parametrul explicit: sa nu mai deschidem odata macheta- fiind deja alese cursurile de la prima rulare*/
	if @parXML.value('(/*/@deschidGridValute)[1]','BIT') is null
		set @parXML.modify('insert attribute deschidGridValute {"0"} into (/*)[1]')
	else 
		set @parXML.modify('replace value of (/*/@deschidGridValute)[1] with "0"') 

	IF @procedura='facturi'
		exec wOPGenerareDifConversieLaFacturi @sesiune=@sesiune, @parXML=@parXML
	else
		if @procedura='disponibil'
			exec wOPGenerareDifCursLaDisponibil @sesiune=@sesiune, @parXML=@parXML
		else
			if @procedura='deconturi'
				exec wOPGenerareDifConversieLaDeconturi @sesiune=@sesiune, @parXML=@parXML
end
