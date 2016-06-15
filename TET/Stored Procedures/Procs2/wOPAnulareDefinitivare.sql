create procedure wOPAnulareDefinitivare @sesiune varchar(50), @parXML xml
as 
declare @numar varchar(20), @data datetime, @stare int, @anularedefinitivare int, 
		@tip varchar(2), @tipdoc varchar(2),@jurnal varchar(3),
		@stareold int, @stareoldDoc int, @binar varbinary(128)

select @numar=ISNULL(@parXML.value('(/parametri/@numar)[1]', 'varchar(20)'), ''),
	   @data=ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), ''),
	   @anularedefinitivare=ISNULL(@parXML.value('(/parametri/@anularedefinitivare)[1]', 'int'), '')
	   
begin try	   
if @anularedefinitivare=1
begin
     --- cazuri in care nu sunt poz., doar antet
    set @tipdoc=isnull((select max(tip) from doc where numar=@numar and data=@data),'') 
	set @tip=isnull((select max(tip) from pozdoc where numar=@numar and data=@data),@tipdoc)
	--- cazuri in care nu sunt poz., doar antet  
	set @stareoldDoc=isnull((select max(stare) from doc where Numar=@numar and data=@data),'')
	set @stareold=isnull((select max(stare) from pozdoc where Numar=@numar and data=@data),@stareoldDoc)
    set @jurnal=isnull((select max(jurnal) from doc where tip=@tip and numar=@numar and data=@data),'')
	if @jurnal='MFX'
		raiserror('Documentul ales trebuie modificat doar din meniul "Documente MF"!',16,1)
	if @data=''
		raiserror('Format data document introdusa gresit',16,1)
	if @tip in ('AP', 'TE')
		begin
			if @stareold<>'2'
				raiserror('Documentului nu i se poate anula definitivarea deoarece nu este in stare Definitiv!',16,1)
			set @binar=cast('modificaredocdefinitiv' as varbinary(128))
			set CONTEXT_INFO @binar
			update pozdoc set Stare='3' where Tip=@tip and Numar=@numar and data=@data
			update doc set Stare='3' where Tip=@tip and Numar=@numar and data=@data
			set CONTEXT_INFO 0x00
		    select 'Documentul cu nr:'+convert(varchar(20),@numar)+' din data de '+convert(varchar(20),@data,103)+' de tip :'+convert(varchar(20),@tip)+' a trecut in starea de operabilitate!' as textMesaj for xml raw, root('Mesaje') 	     
		end
	else 
		raiserror('Documentul nu este de tip: AP/TE sau data introdusa nu corespunde cu nr documentului introdus',16,1)
end
else
	select 'Nu ati bifat anulare definitivare!' as textMesaj for xml raw, root('Mesaje') 	    
end try
begin catch
declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 11, 1) 
end catch
