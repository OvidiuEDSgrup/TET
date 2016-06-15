--***
create procedure wOPAnulareDoc @sesiune varchar(50), @parXML xml          
as        
       
declare @subunitate char(9),@tip char(2),@numar char(20),@datadoc datetime,@tert char(13), @userASiS varchar(20),@mesaj varchar(100), 
@numars char(20),@gestiune char(13),@datastorno datetime ,@codbare char(1),@lunabloc int,@anulbloc int,@subtip varchar(2), 
@databloc datetime,@plata_inc char(1),@facttert varchar(40),@contspgestiune char(40),@tipgestiune char(1), 
@err int, @eroare varchar(254), @faraMesaj int, @anularePI int

EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output   

begin try	
	/*	Apelat SP pentru validari specifice. */
	if exists (select 1 from sysobjects where [type]='P' and [name]='wOPAnulareDocSP')
		exec wOPAnulareDocSP @sesiune, @parXML output

	select
		@facttert = ISNULL(@parXML.value('(/parametri/@factura)[1]', 'varchar(40)'), ''),        
		@tert = ISNULL(@parXML.value('(/parametri/@tert)[1]', 'varchar(13)'), '')   ,    
		--set @tip='AP'    
		@tip=ISNULL(@parXML.value('(/parametri/@tip)[1]', 'varchar(2)'), '')  ,         
		@numar=ISNULL(@parXML.value('(/parametri/@numar)[1]', 'char(20)'), '') ,       
		@datadoc=ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '') ,  
		@subtip=ISNULL(@parXML.value('(/parametri/@subtip)[1]', 'varchar(2)'), ''),       /*datadoc=datafacturii*/
		--set @tert=ISNULL(@parXML.value('(/parametri/@tert)[1]', 'char(13)'), '')        
		@faraMesaj=ISNULL(@parXML.value('(/parametri/@faraMesaj)[1]', 'int'), 0), --parametru trimis din wOPAnulareBon, default afiseaza mesaj
		@anularePI=ISNULL(@parXML.value('(/parametri/@anularePI)[1]', 'int'), 0)
     
      
	set @lunabloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNABLOC'), 1)
	set @anulbloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULBLOC'), 1901)
	if @lunabloc not between 1 and 12 or @anulbloc<=1901 
		set @databloc='01/01/1901' 
	else 
		set @databloc=dateadd(month,1,convert(datetime,str(@lunabloc,2)+'/01/'+str(@anulbloc,4)))
	
	begin	 
	if @datadoc<@databloc
		begin
			set @mesaj='Nu poate fi anulata o factura dintr-o perioada care a fost blocata! Data blocarii: '+convert(char(10),@databloc,103)
			raiserror(@mesaj,11,1)
		end
	if exists (select * from LegaturiStornare where idSursa in (select idPozDoc from pozdoc where subunitate=@subunitate and tip=@tip and numar=@numar and data=@datadoc))
	begin
		declare @nrdSt varchar(10), @dataSt datetime
		select top 1 @nrdSt=numar, @dataSt=data from pozdoc where idPozdoc in (select idStorno from LegaturiStornare where idSursa in (select idPozDoc from pozdoc where subunitate=@subunitate and tip=@tip and numar=@numar and data=@datadoc))
		set @mesaj='Nu se poate anula factura stornata! Stornati factura de stornare: '+@nrdSt+' din '+convert(char(10),@dataSt,103)
		raiserror(@mesaj,11,1)
	end
	if exists (select * from LegaturiStornare where idStorno in (select idPozDoc from pozdoc where subunitate=@subunitate and tip=@tip and numar=@numar and data=@datadoc))
	begin
		delete from LegaturiStornare where idStorno in (select idPozDoc from pozdoc where subunitate=@subunitate and tip=@tip and numar=@numar and data=@datadoc)
	end
	insert into docsters (Subunitate, Tip, Numar, Data, Tert, Factura, Gestiune, Cod, Cod_intrare, Gestiune_primitoare, Cont,  Cont_cor, Cantitate, 
			Pret, Pret_vanzare,  Jurnal, Utilizator, Data_operarii, Ora_operarii, Data_stergerii) 
	select Subunitate, Tip, Numar, Data, max(Tert), max(Factura), max(Gestiune), Cod, Cod_intrare, max(Gestiune_primitoare), max(Cont_de_stoc), max(Cont_corespondent), sum(Cantitate),
			sum(Pret_de_stoc), sum(Pret_vanzare), max(Jurnal), @userASiS, max(Data_operarii), max(Ora_operarii), dateadd(ms,10*row_number() over(order by getdate()),getdate())
	from pozdoc where subunitate=@subunitate and tip=@tip and numar=@numar and data=@datadoc
	group by subunitate, tip, numar, data, cod, cod_intrare, Ora_operarii

	-- daca aviz in baza unei comenzi de livrare
	if @subtip='AK' and exists (select 1 from LegaturiContracte l, pozdoc p where subunitate=@subunitate and tip=@tip and numar=@numar and data=@datadoc and l.idpozdoc=p.idPozDoc)
		delete LegaturiContracte from LegaturiContracte l, pozdoc p where subunitate=@subunitate and tip=@tip and numar=@numar and data=@datadoc and l.idpozdoc=p.idPozDoc
	
	declare @binar varbinary(128)
	set @binar=cast('anularedocdefinitiv' as varbinary(128))
	set CONTEXT_INFO @binar	 

	delete pozdoc where subunitate = @subunitate and tip = @tip and Numar = @numar and Data = @datadoc
	update doc set Stare='1' where subunitate=@subunitate and tip=@tip and numar=@numar and data=@datadoc

	set CONTEXT_INFO 0x00
	
	--delete doc where tip=@tip and Numar=@numar and Data=@datadoc

	if @subtip='AK' and exists (select contract from con where Contract=@numar and Tert=@tert and Data=@datadoc and Tip='BK')
	begin
		delete pozcon where Contract=@numar and Data=@datadoc and Tip='BK'
		delete con where Contract=@numar and Data=@datadoc and Tip='BK'
	end

	if @anularePI=1 and @tip in ('AP','AS')--dacas e solicita anularea incasarilor de pe factura, se sterg si incasarile de pe factura anulata
		delete from pozplin where Subunitate=@subunitate and Factura=@facttert and tert=@tert

	-->generare inregistrari contabile
	exec faInregistrariContabile @dinTabela=0, @Subunitate=@subunitate, @Tip=@tip, @Numar=@numar, @Data=@datadoc
	
	if @faraMesaj=0
		select 'S-a anulat documentul cu numarul '+rtrim(@numar)+' din data '+convert(char(10),@datadoc,103) as textMesaj for xml raw, root('Mesaje')
	end
end try  

begin catch  
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch

