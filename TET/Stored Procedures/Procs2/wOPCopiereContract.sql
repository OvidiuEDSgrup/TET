--***
create procedure  wOPCopiereContract  @sesiune varchar(50), @parXML xml 
as
begin try 
	declare @cantitate float , @termen datetime, @contract varchar(20),@tipDoc varchar(2),@TermPeSurse int,@n_data datetime,@n_termen datetime,
		@cod varchar(20), @data datetime, @tert varchar(20), @utilizator varchar(50),@n_contract varchar(20),@sub varchar(1),@diferentaZi int,
		@userASiS varchar(20),@diferentaAn int,@pret_nomencl float,@an_termene int,@tip varchar(2),@subtip varchar(2),@meniu varchar(2),
		@f_contract VARCHAR(20),@f_tert VARCHAR(13), @datajos datetime, @datasus datetime, @f_loc_de_munca varchar(13)
	
	exec luare_date_par 'UC', 'POZSURSE', @TermPeSurse output, 0, ''
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
 
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	IF @userASiS IS NULL
		RETURN -1

	--exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	declare @fltLmUt int	
	select @fltLmUt=isnull((select count(1) from LMFiltrare),0)

	select @contract=ISNULL(@parXML.value('(/parametri/@numar)[1]', 'varchar(20)'), ''),
		@tert=ISNULL(@parXML.value('(/parametri/@tert)[1]', 'varchar(20)'), ''),
		@data=ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '1901-01-01'),
		
		@n_contract=ISNULL(@parXML.value('(/parametri/@n_numar)[1]', 'varchar(20)'), ''),
		@n_termen=ISNULL(@parXML.value('(/parametri/@n_termen)[1]', 'datetime'), '1901-01-01'),
		@an_termene=ISNULL(@parXML.value('(/parametri/@an_termene)[1]', 'int'), 0),
		@n_data=ISNULL(@parXML.value('(/parametri/@n_data)[1]', 'datetime'), '1901-01-01'),
		@tip=ISNULL(@parXML.value('(/parametri/@tip)[1]', 'varchar(20)'), ''),
		@subtip=ISNULL(@parXML.value('(/parametri/@subtip)[1]', 'varchar(20)'), ''),
		@meniu=ISNULL(@parXML.value('(/parametri/@codMeniu)[1]', 'varchar(2)'), ''),
		@datajos=ISNULL(@parXML.value('(/parametri/@datajos)[1]', 'datetime'), '1901-01-01'),
		@datasus=ISNULL(@parXML.value('(/parametri/@datasus)[1]', 'datetime'), '2901-01-01'),
		@f_contract=upper(ISNULL(@parXML.value('(/parametri/@f_contract)[1]', 'varchar(20)'), '')),
		@f_tert=upper(ISNULL(@parXML.value('(/parametri/@f_tert)[1]', 'varchar(13)'), '')),
		@f_loc_de_munca=upper(ISNULL(@parXML.value('(/parametri/@f_loc_de_munca)[1]', 'varchar(20)'), '')),
		@tipDoc='BF'


	-------------------------daca nu este intros numarul de contract se da numar din plaja------------------
	--sp_help con
	declare @Csub varchar(9),@Ctip varchar(2),@Cdata datetime,@Ccontract varchar(20), @Ctert varchar(13),@nr_contracte float,@contr_vechi varchar(20) 
	set @nr_contracte=0
	
	declare crscontracte cursor for  --curosr pentru parcurgerea contractelor care urmeaza a fi copiate
	select con.subunitate,con.tip, con.data, con.contract, con.tert
	FROM con   
	where con.tip=@tipDoc		
		and con.subunitate=@sub
		-- 
		and (con.data=@data or @tip<>'BF')
		and (con.tert=@tert or @tip<>'BF')
		and (con.contract=@contract or @tip<>'BF')
		-- 
		and con.data between isnull(@datajos,'1901-01-01') and isnull(@datasus,'2901-01-01')  
		and (isnull(@f_contract,'')='' or con.contract=@f_contract)   
		and (isnull(@f_tert,'')='' or con.tert=@f_tert)		
		and (dbo.f_areLMFiltru(@utilizator) =0 or exists(select (1) from LMFiltrare pr where pr.utilizator=@utilizator and pr.cod=con.Loc_de_munca))   
		and (con.loc_de_munca =@f_loc_de_munca or isnull(@f_loc_de_munca,'')='')  
	GROUP by con.subunitate,con.Tip,con.Contract,con.Data,con.tert     
	ORDER by contract  
	open crscontracte
	fetch next from crscontracte into @Csub,@Ctip,@Cdata,@Ccontract, @Ctert
	while @@fetch_status = 0
	begin
 		if @meniu='YZ' or (@tip='BF' and ISNULL(@n_contract,'')='')
		begin
			declare @NrDocFisc int, @fXML xml
			
			set @fXML = '<row/>'
			set @fXML.modify ('insert attribute codMeniu {"CO"} into (/row)[1]')
			set @fXML.modify ('insert attribute tip {sql:variable("@tipDoc")} into (/row)[1]')
			set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')
			--set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')
			
			exec wIauNrDocFiscale @parXML=@fXML, @Numar=@NrDocFisc output
			
			if ISNULL(@NrDocFisc, 0)<>0
				set @n_contract=LTrim(RTrim(CONVERT(char(8), @NrDocFisc)))
			if isnull(@n_contract, '')=''
			begin
				declare @ParUltNr char(9), @UltNr int
				set @ParUltNr='NRCNT' + @tipDoc
				exec luare_date_par 'UC', @ParUltNr, '', @UltNr output, 0
				while @UltNr=0 or exists (select 1 from con where subunitate=@Sub and tip=@tipDoc and contract=rtrim(ltrim(convert(char(9), @UltNr))))
					set @UltNr=@UltNr+1
				set @n_contract=rtrim(ltrim(convert(char(9), @UltNr)))
				exec setare_par 'UC', @ParUltNr, null, null, @UltNr, null
			end
		end
		
	 ------------------------------insert in con-------------------------------------------
		insert into con (Subunitate,Tip,Contract,Tert,Punct_livrare,Data,Stare,Loc_de_munca,Gestiune,
			Termen,Scadenta,Discount,Valuta,Curs,
			Mod_plata,Mod_ambalare,Factura,Total_contractat,Total_TVA,Contract_coresp,Mod_penalizare,
			Procent_penalizare,Procent_avans,Avans,Nr_rate,Val_reziduala,Sold_initial,Cod_dobanda,Dobanda,Incasat,
			Responsabil,Responsabil_tert,Explicatii,Data_rezilierii) 	
	   
		select Subunitate, tip, @n_Contract, tert, Punct_livrare, @n_data,0,Loc_de_munca,Gestiune,
			@n_termen,Scadenta,Discount,Valuta,Curs,	Mod_plata,Mod_ambalare,Factura,Total_contractat,Total_TVA,Contract_coresp,Mod_penalizare,
			Procent_penalizare,Procent_avans,Avans,Nr_rate,Val_reziduala,Sold_initial,Cod_dobanda,Dobanda,Incasat,
			Responsabil,Responsabil_tert,Explicatii,Data_rezilierii
		from con	
		where Subunitate=@Csub and tip=@Ctip and data=@Cdata and Contract=@Ccontract and tert=@Ctert	
		
		
		------------------------------insert in pozcon----------------------------------------			
		insert into pozcon 
			(Subunitate,Tip,Contract,Tert,Punct_livrare,Data,Cod,Cantitate,
			Pret,Pret_promotional,Discount,Termen,Factura,Cant_disponibila,Cant_aprobata,Cant_realizata,
			Valuta,Cota_TVA,Suma_TVA,Mod_de_plata,UM,Zi_scadenta_din_luna,Explicatii,Numar_pozitie,Utilizator,
			Data_operarii,Ora_operarii) 
				
		select Subunitate,Tip,@n_contract,Tert,Punct_livrare,@n_data,Cod,Cantitate,
			Pret,Pret_promotional,Discount,@n_termen,Factura,Cant_disponibila,Cant_aprobata,0,
			Valuta,Cota_TVA,Suma_TVA,Mod_de_plata,UM,Zi_scadenta_din_luna,Explicatii,Numar_pozitie, @userASiS,
			convert(datetime, convert(char(10), getdate(), 104), 104), RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
		from pozcon
		where Subunitate=@Csub and tip=@Ctip and data=@Cdata and Contract=@Ccontract and tert=@Ctert	
			
		
		--------------------------------insert in extcon---------------------------------------
		insert extcon 
		   (Subunitate,Tip,Contract,Tert,Data,Numar_pozitie,Precizari,Clauze_speciale,Modificari,Data_modificari,Descriere_atasament,
		   Atasament,Camp_1,Camp_2,Camp_3,Camp_4,Camp_5,Utilizator,Data_operarii,Ora_operarii)
		
		select Subunitate,Tip,@n_contract,Tert,@n_data,Numar_pozitie,Precizari,Clauze_speciale,Modificari,Data_modificari,Descriere_atasament,
		   Atasament,Camp_1,Camp_2,Camp_3,Camp_4,Camp_5,@userASiS,
		   convert(datetime, convert(char(10), getdate(), 104), 104), RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
		from extcon 
		where Subunitate=@Csub and tip=@Ctip and data=@Cdata and Contract=@Ccontract and tert=@Ctert				     
		
		
		--------------------------------insert in termene--------------------------------------
		
		set @diferentaZi=DATEDIFF(MONTH,@Cdata,@n_data)
		set @diferentaAn=DATEDIFF(yy,@Cdata,@n_data)
		set @pret_nomencl=isnull((select pret_vanzare from nomencl where cod=@cod),0)
		
		if isnull(@an_termene,0)=0
		begin
			insert termene 
				(Subunitate, Tip, Contract, Tert, Cod, 
				Data, Termen, 
				Cantitate, Cant_realizata, Pret, Explicatii,  Val1, Val2, Data1, Data2)
			select Subunitate, Tip, @n_contract, Tert, Cod, 
				@n_data,(case when year(@n_data)>=YEAR(@Cdata) then dateadd(yy,@diferentaAn,termen) else /*dateadd(MONTH,@diferentaZi,termen)*/dateadd(yy,1,termen) end ),
				Cantitate, 0, (case when @pret_nomencl<>0 then @pret_nomencl else pret end), Explicatii,  0, 0, Data1, Data2	
			from termene
			where Subunitate=@Csub and tip=@Ctip and data=@Cdata and Contract=@Ccontract and tert=@Ctert	
		end
		else
		begin
			set @diferentaAn=@an_termene-isnull((select top 1 year(termen) from termene 
												where Subunitate=@Csub and tip=@Ctip and data=@Cdata and Contract=@Ccontract and tert=@Ctert order by data),0)
			insert termene 
				(Subunitate, Tip, Contract, Tert, Cod, 
				Data, Termen, 
				Cantitate, Cant_realizata, Pret, Explicatii,  Val1, Val2, Data1, Data2)
			select Subunitate, Tip, @n_contract, Tert, Cod, 
				@n_data,dateadd(yy,@diferentaAn,termen),
				Cantitate, 0, (case when @pret_nomencl<>0 then @pret_nomencl else pret end), Explicatii,  0, 0, Data1, Data2	
			from termene
			where Subunitate=@Csub and tip=@Ctip and data=@Cdata and Contract=@Ccontract and tert=@Ctert	
		end	
		
		set @nr_contracte=@nr_contracte+1--numarare contracte generate
		fetch next from crscontracte into @Csub,@Ctip,@Cdata,@Ccontract, @Ctert
	end				
	begin try 
		close crscontracte 
	end try 
	begin catch end catch
	begin try 
		deallocate crscontracte 
	end try 
	begin catch end catch
 
	if @nr_contracte>0 
		if @meniu='YZ' and @nr_contracte>1--apelata din meniul principal
			select 'Operatia de copiere contracte a fost finalizata! Au fost generate '+ convert(varchar(10),@nr_contracte)+' contracte!' as textMesaj, 'Finalizare operatie' as titluMesaj 
			for xml raw, root('Mesaje')
		else
			select 'Operatia de copiere contract a fost finalizata! A fost generat contractul cu numarul: '+RTRIM(@n_contract)+'.' as textMesaj, 'Finalizare operatie' as titluMesaj 
			for xml raw, root('Mesaje')				
	else
		select 'Verificati datele, nu au fost generate contracte noi!' as textMesaj, 'Finalizare operatie' as titluMesaj 
		for xml raw, root('Mesaje')
end try
 
begin catch
 declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
--select * from extcon
