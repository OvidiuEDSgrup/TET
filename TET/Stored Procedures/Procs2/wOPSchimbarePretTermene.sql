--***
create procedure wOPSchimbarePretTermene @sesiune varchar(50), @parXML xml 
as     
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPSchimbarePretTermeneSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPSchimbarePretTermeneSP @sesiune, @parXML output
	return @returnValue
end

declare @TermPeSurse int,@f_sursa varchar(13), @iDoc int ,@numarpoz int ,@data_pret datetime,@pret_nou float,@cod_pret varchar(20),
		@f_beneficiar varchar(13),@f_loc_de_munca varchar(13),@schimbare_pret_nomencl bit,@sub varchar(1), @utilizator char(10),
		@f_contract varchar(20),@tip varchar(2),@subtip varchar(2),@mesaj varchar(200)
begin try 		
	exec luare_date_par 'UC', 'POZSURSE', @TermPeSurse output, 0, ''
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	if @utilizator is null
		return -1
		
	select 
		@tip=ISNULL(@parXML.value('(/parametri/@tip)[1]', 'varchar(2)'), ''),	
		@subtip=ISNULL(@parXML.value('(/parametri/@subtip)[1]', 'varchar(2)'), ''),	
		
		@cod_pret=ISNULL(@parXML.value('(/parametri/@cod_pret)[1]', 'varchar(20)'), ''),
		@pret_nou=ISNULL(@parXML.value('(/parametri/@pret_nou)[1]', 'float'), ''),
		@data_pret=ISNULL(@parXML.value('(/parametri/@data_pret)[1]', 'datetime'), ''),
		@schimbare_pret_nomencl=ISNULL(@parxml.value('(/parametri/@schimbare_pret_nomencl)[1]', 'bit'),0),

		@f_beneficiar=ISNULL(@parXML.value('(/parametri/@f_beneficiar)[1]', 'varchar(13)'), ''),
		@f_contract=ISNULL(@parXML.value('(/parametri/@f_contract)[1]', 'varchar(20)'), ''),
		@f_loc_de_munca=ISNULL(@parXML.value('(/parametri/@f_loc_de_munca)[1]', 'varchar(20)'), ''),
		@f_sursa=ISNULL(@parXML.value('(/parametri/@f_sursa)[1]', 'varchar(20)'), '')

	if  @tip='BF'and @subtip='PR'--operatie apelata de pe contract
	begin
		select --citim datele din pozitia selectata
			@cod_pret=ISNULL(@parXML.value('(/parametri/row/@cod)[1]', 'varchar(20)'), ''),
			@f_contract=ISNULL(@parXML.value('(/parametri/@numar)[1]', 'varchar(20)'), ''),
			@f_sursa=ISNULL(@parXML.value('(/parametri/row/@modplata)[1]', 'varchar(20)'), '')
		
		if  @tip='BF'and @subtip='PR' and isnull(@cod_pret,'')='' or not exists (select cod from nomencl where cod=@cod_pret)--mesaj de eroare dc. nu se selecteaza o pozitie
 			raiserror('wOPSchimbarePretTermene:Selectati o pozitie pentru modificare pret!',11,1)		
	end
	else--operatie apelata din meniul de operatii
	begin
		if @cod_pret=''  or not exists (select cod from nomencl where cod=@cod_pret)
 			raiserror('wOPSchimbarePretTermene:Campul corespunzator codului de nomenclator nu au fost completate corect!',11,1)
	end
		
	if isnull(@pret_nou,0)=0
		raiserror('wOPSchimbarePretTermene:Pretul nu poate fi 0!',11,1)
	
	--select @cod_pret,@pret_nou,@data_pret,@schimbare_pret_nomencl,@f_beneficiar,@f_contract,@f_loc_de_munca,@f_sursa
	if @schimbare_pret_nomencl=1
		update nomencl set Pret_vanzare=@pret_nou where cod=@cod_pret
	
	declare @tipR varchar(2), @termenR datetime, @cantitateR float,@tertR varchar(13), @dataR datetime, @contractR varchar(20),
			@codR varchar(20),@val2R int,@pretR float,@explicatiiR varchar(50) ,@cant_pret_nou float,@cant_pret_vechi float ,@nr_contracte float,
			@contr_vechi varchar(20) 
	set @nr_contracte=0
	
	declare pret_nou cursor for 
	select t.tip,t.termen,t.tert,t.data, t.contract, t.cod,t.cantitate,t.val2,t.pret,t.explicatii
	from termene t 
		inner join pozcon p on p.subunitate=t.subunitate and p.tert=t.tert and p.contract=t.contract 
			and p.cod=@cod_pret 
			and (p.contract =@f_contract or isnull(@f_contract,'')='')
			and (p.mod_de_plata =@f_sursa or isnull(@f_sursa,'')='')
			and (year(@data_pret)<year(t.termen) or (year(@data_pret)=year(t.termen) and month(@data_pret)<=month(t.termen)))
			and t.cod=(case when isnull(@TermPeSurse,0)=0 then p.cod else ltrim(str(p.numar_pozitie)) end)
			and t.tip='BF' and  t.cant_realizata=0 and t.val2=0
		inner join con c on t.subunitate=c.subunitate and t.tip='BF' and t.tert=c.tert and t.contract=c.contract and t.data=c.data 
			and p.cod=@cod_pret 
			and (c.contract =@f_contract or isnull(@f_contract,'')='')
			and (year(@data_pret)<year(t.termen) or (year(@data_pret)=year(t.termen) and month(@data_pret)<=month(t.termen)))
			and (c.tert =@f_beneficiar or isnull(@f_beneficiar,'')='')
			and  t.cant_realizata=0 and t.val2=0
	where t.tip='BF' and  t.cant_realizata=0 and t.val2=0
	  --and p.cod=@cod_pret
	  --and (c.tert =@f_beneficiar or isnull(@f_beneficiar,'')='')
	 -- and (c.contract =@f_contract or isnull(@f_contract,'')='')
	  and (c.loc_de_munca =@f_loc_de_munca or isnull(@f_loc_de_munca,'')='')
	  and (p.mod_de_plata =@f_sursa or isnull(@f_sursa,'')='')
	  and (dbo.f_areLMFiltru(@utilizator)=0 or exists(select (1) from LMFiltrare pr where pr.utilizator=@utilizator and pr.cod=c.Loc_de_munca)) 
	
	open pret_nou 
	fetch next from pret_nou into @tipR, @termenR,@tertR, @dataR, @contractR, @codR, @cantitateR,@val2R,@pretR,@explicatiiR
		while @@FETCH_STATUS=0
		begin
			--raiserror ('aici',11,1)
			if @termenR=(select min(termen) from termene where Contract=@contractR and data=@dataR and tip=@tipR and tert=@tertR 
														   and cod=@codR and termen>=@data_pret /*and MONTH(termen)=MONTH(@data_pret)*/) 
			   and day(@data_pret)<>1 and (not exists (select termen from termene where Contract=@contractR and data=@dataR and tip=@tipR and tert=@tertR 
														  and cod=@codR and termen=dateadd(day,-1,@data_pret)))	 
					begin
					
						set @cant_pret_nou=round((@cantitateR*(DAY(@termenR)-DAY(@data_pret)+1))/DAY(@termenR),5)
						set @cant_pret_vechi=@cantitateR-@cant_pret_nou
					    
						delete termene where Contract=@contractR and data=@dataR and tip=@tipR 
										 and tert=@tertR and cod=@codR and termen=@termenR
										 and Cantitate=@cantitateR	
						insert termene (Subunitate, Tip, Contract, Tert, Cod,Data, Termen, Cantitate, Cant_realizata, Pret, Explicatii, 
										Val1, Val2, Data1, Data2)
								 select @sub, @tipR, @contractR, @tertR, @codR,@dataR,dateadd(day,-1,@data_pret),@cant_pret_vechi, 0 ,@pretR, @explicatiiR,
										0,0,'1901-01-01','01/01/1901'
						insert termene (Subunitate, Tip, Contract, Tert, Cod,Data, Termen, Cantitate, Cant_realizata, Pret, Explicatii, 
										Val1, Val2, Data1, Data2)
								 select @sub, @tipR, @contractR, @tertR, @codR,@dataR,@termenR,@cant_pret_nou, 0 ,@pret_nou, @explicatiiR,
										0,0,'1901-01-01','01/01/1901'
													
					end
			else		
			/*if (((month(@termenR)>month(@data_pret) or (DAY(@data_pret)=1) and (month(@termenR)=month(@data_pret))) and YEAR(@termenR)=YEAR(@data_pret))or(YEAR(@termenR)>YEAR(@data_pret)))*/
			if @termenR>=@data_pret 	
			begin
				 update termene set Pret=@pret_nou 
				 where termen=@termenR and data=@dataR and Contract=@contractR and tip=@tipR and cod=@codR and tert=@tertR
			end	
			update con set Total_contractat=isnull((select SUM(round(cantitate*pret,2)) from Termene 
													where subunitate=@sub and tip=@tipR and contract=@contractR and tert=@tertR and data=@dataR),0)
			where tip=@tipR and contract=@contractR and tert=@tertR and data=@dataR and subunitate=@sub  
			
			if @contr_vechi is null or @contr_vechi<>@contractR
			begin
				set @contr_vechi=@contractR
				set @nr_contracte=@nr_contracte+1
			end
			fetch next from pret_nou into @tipR, @termenR,@tertR, @dataR, @contractR, @codR, @cantitateR,@val2R,@pretR,@explicatiiR
		end
	close pret_nou
	deallocate pret_nou	
	--select * from termene  
	if @nr_contracte>0 
		if @tip<>'BF'--apelata din meniul de operatii
			select 'Operatia de schimbare pret a fost finalizata! A fost modificat pretul pe '+ convert(varchar(10),@nr_contracte)+' contracte!' as textMesaj, 'Finalizare operatie' as titluMesaj 
			for xml raw, root('Mesaje')
		else
			select 'Operatia de schimbare pret a fost finalizata!' as textMesaj, 'Finalizare operatie' as titluMesaj 
			for xml raw, root('Mesaje')				
	else
		select 'Verificati datele, nu au fost identificate termene pentru schimbarea pretului!' as textMesaj, 'Finalizare operatie' as titluMesaj 
		for xml raw, root('Mesaje')
end try
begin catch
	set @mesaj=ERROR_MESSAGE()
end catch

declare @cursorStatus int
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='pret_nou' and session_id=@@SPID )
if @cursorStatus=1 
	close pret_nou
if @cursorStatus is not null 
	deallocate pret_nou

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
--select * from pozcon
