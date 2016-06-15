
create procedure wOPIncasare_p (@sesiune varchar(50), @parXML xml) 
as             
begin try
	declare 
		@utilizator varchar(100), @formular varchar(200), @generez int, @contcasa varchar(40)

	set @generez=1
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	IF OBJECT_ID('tempdb.dbo.#propu') IS NOT NULL
		drop table #propu

	select * into #propu from dbo.fPropUtiliz(@sesiune)

	select @contcasa=rtrim(valoare) from #propu where cod_proprietate='CONTCASA'
	select @formular=rtrim(valoare) from #propu where cod_proprietate='FORMCHIT'
	select @generez=1
	
	IF ISNULL(@formular,'')=''
		select @formular=valoare from #propu where cod_proprietate='FORMPLIN'
	
	IF OBJECT_ID('tempdb.dbo.#dateinc') IS NOT NULL
		drop table #dateinc

	create table #dateinc (tert varchar(20), factura varchar(20), data datetime, valoare decimal(17,2), lm varchaR(20), comanda varchar(20), contcasa varchar(40), formular varchar(100), generare int)

	insert into #dateinc (tert, factura, data, valoare, lm, comanda, contcasa, formular,generare)
	select
		isnull(@parXML.value('(*/@tert)[1]','varchar(20)'),''),    
		isnull(@parXML.value('(*/@factura)[1]','varchar(20)'),''), 
		isnull(@parXML.value('(*/@data)[1]','datetime'),''),       
		isnull(@parXML.value('(*/@valtotala)[1]','decimal(17,2)'),0),     		
		isnull(@parXML.value('(*/@lm)[1]','varchar(9)'),''),         
		isnull(@parXML.value('(*/@comanda)[1]','varchar(20)'),''),				
		@contcasa, @formular ,1
		

	/* 
		Toate valorile se pot modifica in #dateinc prin procedura SP-> 
		Exemplu:
			-> sa se sugereze ca valoare de incasat, doar valoare ramasa a facturii (caz de incasari multiple, etc)
		
	*/
	IF EXISTS (select 1 from sysobjects where name ='wOPIncasare_pSP')
		exec wOPIncasare_pSP @sesiune=@sesiune, @parXML=@parXML

	select *  from #dateinc for xml raw, root('Date')


end try
begin catch 
	select '1' as inchideFereastra for xml raw, root('Mesaje')
    declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@eroare, 16, 1) 
end catch
