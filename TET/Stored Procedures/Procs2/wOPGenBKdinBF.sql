--***
create procedure [dbo].[wOPGenBKdinBF] @sesiune varchar(50), @parXML xml 
as 
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPGenBKdinBFSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPGenBKdinBFSP @sesiune, @parXML output
	return @returnValue
end
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPGenBKdinBFSP2')
	exec @returnValue = wOPGenBKdinBFSP2 @sesiune, @parXML output
begin try 
begin tran GenBKdinBF 
	declare @luna varchar(20),@an varchar(20),@sub char(9), @data_jos datetime , @data_sus datetime , @data datetime,@formular varchar(13),
	 @data_operarii datetime, @ora_operarii char(6), @err int, @TermPeSurse int, @data_lunii varchar(20),@datap varchar(20),
	 @utilizator varchar(50),@beneficiar varchar(20),@numar_pozitie int ,@codMeniu varchar(2),@generare int, @stare varchar(1), @inXML int,
	 @indbug varchar(40), @fcontract varchar(20), @ftert varchar(20), @fdata datetime, @ftermen datetime, @cantitate float, @datascad datetime,
	 @fcant_realizata float, @val1 float, @poznerealizate int,@tip char(2), @numardoc varchar(8), @datadoc datetime, @facturadoc varchar(20),
	 @numele_delegatului varchar(30),@seria_buletin varchar(10),@numar_buletin varchar(10),@eliberat varchar(30),@mijloc_de_transport varchar(30),
	 @ora_expedierii varchar(6),@explicatii_anexaf varchar(100),@numarul_mijlocului varchar(13),@data_expedierii datetime,@tipDoc varchar(2),
	 @subtip varchar(2),@f_beneficiar varchar(13),@f_loc_de_munca varchar(13),@genRealizari bit,@genFacturi bit,@realizari int,@NrAvizeUnitar int,
	 @Periodicitate int,@aviz_coresp varchar(20),@cont_coresp varchar(13) ,@jurnal varchar(3),@cont_factura varchar(13),@zilescad int
	
	set @realizari=0 
	--
	set @tipDoc='AP'
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output 
	exec luare_date_par 'UC', 'POZSURSE', @TermPeSurse output, 0, ''
	exec luare_date_par 'GE','NRAVIZEUN', @NrAvizeUnitar output, 0, '' 
	--exec luare_date_par 'UC','INDAVIZ',0,0,@indbug output
	exec luare_date_par 'UC','PERIODCON',@Periodicitate output,0,''

	select
		 @codMeniu=ISNULL(@parXML.value('(/parametri/@codMeniu)[1]', 'varchar(20)'), ''),
		 @subtip=ISNULL(@parXML.value('(/parametri/@subtip)[1]', 'varchar(2)'), ''),
		 @tip=ISNULL(@parXML.value('(/parametri/@tip)[1]', 'varchar(2)'), ''),
		 @inXML = isnull(@parXML.value('(/parametri/@inXML)[1]','varchar(1)'),0),
		 @formular=ISNULL(@parXML.value('(/parametri/@formular)[1]', 'varchar(13)'), ''),
		 @cont_factura=ISNULL(@parXML.value('(/parametri/@cont_factura)[1]', 'varchar(13)'), ''),
		 @jurnal=ISNULL(@parXML.value('(/parametri/@jurnal)[1]', 'varchar(3)'), ''),
		 @data_jos=isnull(@parXML.value('(/parametri/@datajos)[1]','datetime'),'1901-01-01'),
		 @data_sus=isnull(@parXML.value('(/parametri/@datasus)[1]','datetime'),'2901-01-01'),
		 @genRealizari = isnull(@parXML.value('(/parametri/@genRealizari)[1]','bit'),0),
		 @zilescad = @parXML.value('(/parametri/@zilescad)[1]','int'),
		 @genFacturi = isnull(@parXML.value('(/parametri/@genFacturi)[1]','bit'),0),
		 
		 ---------date pentru facturare prin 418-----------
		 @aviz_coresp= upper(isnull(@parXML.value('(/parametri/@aviz_coresp)[1]','varchar(20)'),'')),
		 @cont_coresp= upper(isnull(@parXML.value('(/parametri/@cont)[1]','varchar(13)'),'')),
		 
		 ---------date necesare a fi scrise in anexafac-----------
		 @numele_delegatului= upper(isnull(@parXML.value('(/parametri/@numele_delegatului)[1]','varchar(30)'),'')),
		 @seria_buletin= upper(isnull(@parXML.value('(/parametri/@seria_buletin)[1]','varchar(10)'),'')),
		 @numar_buletin= upper(isnull(@parXML.value('(/parametri/@numar_buletin)[1]','varchar(10)'),'')),
		 @eliberat= upper(isnull(@parXML.value('(/parametri/@eliberat)[1]','varchar(30)'),'')),
		 @mijloc_de_transport= upper(isnull(@parXML.value('(/parametri/@mijloc_de_transport)[1]','varchar(30)'),'')),
		 @numarul_mijlocului= upper(isnull(@parXML.value('(/parametri/@numarul_mijlocului)[1]','varchar(13)'),'')),
		 @explicatii_anexaf= upper(isnull(@parXML.value('(/parametri/@explicatii_anexaf)[1]','varchar(100)'),'')),
		 @ora_expedierii= isnull(@parXML.value('(/parametri/@ora_expedierii)[1]','varchar(6)'),''),
		 @data_expedierii= isnull(@parXML.value('(/parametri/@data_expedierii)[1]','datetime'),'1900-01-01')    

	if (@codMeniu='GF')		
	begin
		select @f_beneficiar=upper(ISNULL(@parXML.value('(/parametri/@f_beneficiar)[1]', 'varchar(13)'), '')),
			 @f_loc_de_munca=upper(ISNULL(@parXML.value('(/parametri/@f_loc_de_munca)[1]', 'varchar(20)'), '')),
			 @datadoc=ISNULL(@parXML.value('(/parametri/@datadoc)[1]', 'datetime'), '1901-01-01')
			
		--Verificare luna blocata in CG

		declare @aiCG int, @liCG int
		declare @fltLmUt int	
		select @fltLmUt=isnull((select count(1) from LMFiltrare),0) 			
		
		set @liCG=ISNULL((select max(val_numerica )from par where Tip_parametru='GE' and Parametru='LUNABLOC'),0) 
		set @aiCG=ISNULL((select max(val_numerica) from par where Tip_parametru='GE' and Parametru='ANULBLOC'),0)
		
		--if (@stare='F')
				--raiserror('Nu se poate genera alta factura pentru o realizare deja facturata!' , 11, 1) 
		/*if @aiCG>YEAR(@data_jos) or (@aiCG=YEAR(@data_jos) and @liCG>=MONTH(@data_jos))
			raiserror('wOPGenBKdinBF:Data de inceput a perioadei e in luna BLOCATA!', 11, 1) 
		if @aiCG>YEAR(@data_sus) or (@aiCG=YEAR(@data_sus) and @liCG>=MONTH(@data_sus))
			raiserror('wOPGenBKdinBF:Data de sfarsit a perioadei e in luna BLOCATA!', 11, 1) 
		 */		 
		if @genFacturi=0 and @genRealizari=0 and @codMeniu='GF' 
			raiserror('wOPGenBKdinBF:Cel putin una din cele 2 optiuni "Generare Facturi" si "Generare Realizari" trebuie sa fie selectata!!!!!!!!!!',11,1) 
	end
	else 
	if (@subtip in ('KE','KX'))
	begin
		select @numardoc=upper(ISNULL(@parXML.value('(/parametri/@numardoc)[1]', 'varchar(8)'), '')),
			@facturadoc=upper(ISNULL(@parXML.value('(/parametri/@facturadoc)[1]', 'varchar(20)'), '')),
			@datadoc=ISNULL(@parXML.value('(/parametri/@datadoc)[1]', 'datetime'), '1901-01-01'),
			@generare=ISNULL(@parXML.value('(/parametri/@generare)[1]', 'int'), ''),
			@fcontract=upper(ISNULL(@parXML.value('(/parametri/@numar)[1]', 'varchar(20)'), '')),
			@ftert=upper(ISNULL(@parXML.value('(/parametri/@tert)[1]', 'varchar(20)'), '')),
			@fdata=ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '1901-01-01'),
			@stare=ISNULL(@parXML.value('(/parametri/@stare)[1]', 'varchar(1)'), '')
		
		set @poznerealizate=isnull((select count(1) from termene where subunitate=@sub and tip='BF' and contract=@fcontract 
					and data=@fdata and termen between @data_jos and @data_sus and Val2=0),0)
		--if @poznerealizate>0 
		--	raiserror('wOPGenBKdinBF:Pentru facturarea unui contract, este necesar ca toate termenele lui din perioada selectata sa fie realizate!!',11,1)	
		/*Silviu: fara not exists deoarece se permite generarea de factura chiar daca nu sunt toate termenele realizate!*/
		if exists(select 1 from con where tip=@tip and data=@fdata and tert=@ftert and Contract=@numardoc) and @numardoc<>''
			raiserror ('wOPGenBKdinBF:Numar de document utilizat!! Introduceti un alt numar de document!!',11,1) 	 
		 
	end

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	set @data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104)
	set @ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
		
		-----------------------------------Generare realizari daca e pusa bifa -----------------------------------------------
		
	if @codMeniu='GF' and @genRealizari=1
	begin
		declare @tipR varchar(2), @termenR datetime, @cantitateR float,@tertR varchar(13), @dataR datetime, @contractR varchar(20), @codR varchar(20)
		declare genterm cursor for 
			select t.tip,t.termen, t.cantitate,t.tert,t.data, t.contract, t.cod
			from termene t 
				inner join pozcon p on p.subunitate=t.subunitate and p.tert=t.tert and p.contract=t.contract 
								 and t.cod=(case when @TermPeSurse=0 then p.cod else ltrim(str(p.numar_pozitie)) end)
								 and t.tip='BF' and t.termen between @data_jos and @data_sus and t.cant_realizata=0 and t.val2=0
				inner join con c on t.subunitate=c.subunitate and t.tert=c.tert and t.contract=c.contract and t.data=c.data and c.stare='1'
			where t.tip='BF' and t.termen between @data_jos and @data_sus and c.stare='1'and t.cant_realizata=0 and t.val2=0
			 and (c.tert =@f_beneficiar or isnull(@f_beneficiar,'')='')
			 and (c.loc_de_munca =@f_loc_de_munca or isnull(@f_loc_de_munca,'')='')
			 and (dbo.f_areLMFiltru(@utilizator)=0 or exists(select (1) from LMFiltrare pr where pr.utilizator=@utilizator and pr.cod=c.Loc_de_munca)) 
		open genterm 
		fetch next from genterm into @tipR, @termenR, @cantitateR,@tertR, @dataR, @contractR, @codR
			while @@FETCH_STATUS=0
				begin 
				update termene set Val2='1', Val1=@cantitateR where Contract=@contractR and termen=@termenR and tert=@tertR and data=@dataR and cod=@codR
				set @realizari =@realizari+1
				fetch next from genterm into @tipR, @termenR, @cantitateR,@tertR, @dataR, @contractR, @codR
				end
		close genterm
		deallocate genterm
	end
		
		------------------------------------------Generare facturi---------------------------------------------------------------
	if (@codMeniu='GF' and @genFacturi=1)or @subtip in ('KE','KX')
	begin	
		declare @contract char(20), @tert char(13), @termen datetime,
			@valuta char(3), @loc_de_munca char(9), @explicatii char(50), @punctlivrare varchar(10),
			@factura char(20), @curs float, @scadenta int,@generareV int,@gestiune varchar(13)
		set @generareV=0
		declare @codT char(20), @termenT datetime, @cantfact float,@proc_tva float, @cont_de_stoc char(13), @cont_corespondentT char(13),@pretT float,
			@cont_tva char(13),@DELE varchar(max), @modplataT char(8), @nrpozT int,@cant_realizataT float,@dataT datetime,@cantitateT float,
			@val1T float,@val2T bit,@explicatiiT varchar(50)
		
		------------------mesaje de informare detaliate------------------------  
		if not exists (select top 1 con.contract, con.data,con.tert,max(con.valuta) as valuta, max(con.loc_de_munca) as loc_de_munca, max(con.explicatii) as explicatii,  
						max(con.scadenta)as scadenta, max(con.punct_livrare)as punct_livrare,max(con.termen)as termen,max(con.gestiune)  
				FROM con   
				   inner join termene t on t.tip=con.tip and t.contract=con.contract and t.tert = con.tert and t.data=con.data and t.subunitate=1   
						  and t.termen between @data_jos and @data_sus and t.val2=1 and t.Cant_realizata<>t.val1  
				where con.tip='BF'  
				   and (isnull(@fcontract,'')='' or con.contract=@fcontract)   
				   and (isnull(@ftert,'')='' or con.tert=@ftert)  
				   and (isnull(@fdata,'1901-01-01')='1901-01-01' or con.data=@fdata)  
				   --and (@ftermen='01/01/1901' or t.termen=@ftermen)-- daca vreau sa gen fact pentru intreaga luna elimin cond de pe aceasta linie  
				   and (dbo.f_areLMFiltru(@utilizator) =0 or exists(select (1) from LMFiltrare pr where pr.utilizator=@utilizator and pr.cod=con.Loc_de_munca))   
				   and con.stare='1'  
				   and (con.tert =@f_beneficiar or isnull(@f_beneficiar,'')='')  
				   and (con.loc_de_munca =@f_loc_de_munca or isnull(@f_loc_de_munca,'')='')  
				GROUP by con.subunitate,con.Tip,con.Contract,con.Data,con.tert     
				ORDER by contract)  
			raiserror('wOPGenBKdinBF:Nu exista cantitate de facturat!',16,1)  
	
		if not exists (select top 1 con.contract, con.data,con.tert,max(con.valuta) as valuta, max(con.loc_de_munca) as loc_de_munca, max(con.explicatii) as explicatii,  
							max(con.scadenta)as scadenta, max(con.punct_livrare)as punct_livrare,max(con.termen)as termen,max(con.gestiune)  
				FROM con   
					inner join termene t on t.tip=con.tip and t.contract=con.contract and t.tert = con.tert and t.data=con.data and t.subunitate=1   
					and t.termen between @data_jos and @data_sus and t.val2=1 and t.Cant_realizata<>t.val1 and t.pret<>0   
				where con.tip='BF'  
					and (isnull(@fcontract,'')='' or con.contract=@fcontract)   
					and (isnull(@ftert,'')='' or con.tert=@ftert)  
					and (isnull(@fdata,'1901-01-01')='1901-01-01' or con.data=@fdata)  
					--and (@ftermen='01/01/1901' or t.termen=@ftermen)-- daca vreau sa gen fact pentru intreaga luna elimin cond de pe aceasta linie  
					and (dbo.f_areLMFiltru(@utilizator) =0 or exists(select (1) from LMFiltrare pr where pr.utilizator=@utilizator and pr.cod=con.Loc_de_munca))   
					and con.stare='1'  
					and (con.tert =@f_beneficiar or isnull(@f_beneficiar,'')='')  
					and (con.loc_de_munca =@f_loc_de_munca or isnull(@f_loc_de_munca,'')='')  
				GROUP by con.subunitate,con.Tip,con.Contract,con.Data,con.tert     
				ORDER by contract)  
			raiserror('wOPGenBKdinBF:Termenele selectate nu au pret!',16,1)  
		-----------------------------------------------------------------------  
		
		-->>>>>>>>>>>>>>>>>>>>>Cursor pe contractele ce trebuie facturate<<<<<<<<<<<<<<<<<<<<<<<---
			declare crscontracte cursor for  
			select con.contract, con.data,con.tert,max(con.valuta) as valuta, max(con.loc_de_munca) as loc_de_munca, max(con.explicatii) as explicatii,  
					max(con.scadenta)as scadenta, max(con.punct_livrare)as punct_livrare,max(con.termen)as termen,max(con.gestiune)  
			FROM con   
				inner join termene t on t.tip=con.tip and t.contract=con.contract and t.tert = con.tert and t.data=con.data and t.subunitate=1   
				and t.termen between @data_jos and @data_sus and t.val2=1 and t.Cant_realizata<>t.val1 and t.pret<>0   
			  --and not exists(select 1 from Termene t2 where t.Tip=t2.Tip and t.Data=t2.Data and t.Contract=t2.Contract   
			  --and t.Tert=t2.Tert and t2.Val2=0 and t2.Termen between @data_jos and @data_sus)  
			where con.tip='BF'  
				and (isnull(@fcontract,'')='' or con.contract=@fcontract)   
				and (isnull(@ftert,'')='' or con.tert=@ftert)  
				and (isnull(@fdata,'1901-01-01')='1901-01-01' or con.data=@fdata)  
				--and (@ftermen='01/01/1901' or t.termen=@ftermen)-- daca vreau sa gen fact pentru intreaga luna elimin cond de pe aceasta linie  
				and (dbo.f_areLMFiltru(@utilizator) =0 or exists(select (1) from LMFiltrare pr where pr.utilizator=@utilizator and pr.cod=con.Loc_de_munca))   
				and con.stare='1'  
				and (con.tert =@f_beneficiar or isnull(@f_beneficiar,'')='')  
				and (con.loc_de_munca =@f_loc_de_munca or isnull(@f_loc_de_munca,'')='')  
			GROUP by con.subunitate,con.Tip,con.Contract,con.Data,con.tert     
			ORDER by contract  
		open crscontracte
		fetch next from crscontracte into @contract,@data, @tert, @valuta, @loc_de_munca, @explicatii, @scadenta, @punctlivrare,@termen,@gestiune
		while @@fetch_status = 0
		begin
			if ISNULL(@datadoc, '01/01/1901')='01/01/1901'
				set @datadoc=@data_sus
			set @curs=isnull((select top 1 curs from curs where valuta=@valuta and data<=@datadoc order by data desc),'')
		
			declare @fXML xml, @NrDocFisc varchar(10), @serie varchar(9),@numarAP varchar(8)	
				
				if @subtip in ('KE','KX') and @numardoc<>''-->daca s-a introdus numar de ap pe macheta
					if exists (select Factura from pozdoc where factura=@facturadoc and data=@datadoc
														 and((tip in ('AP','AS') and @NrAvizeUnitar=1) or tip=@tipDoc ))
						raiserror('wOPGenBKdinBF:Numarul acesta de factura a fost deja utilizat!!!',11,1)
					else
					begin
						set @numarAP=@numardoc 
						if ISNULL(@facturadoc,'')=''--daca s-a introdus factura pe macheta aceasta va fi dusa mai departe, dc nu factura va deveni numarAP introdus pe macheta
							set @factura=@numardoc
						else
							set @factura=@facturadoc	
					end	
				else--daca nu s-a introdus numar de AP pe macheta
				--daca exista procedura wScriuPozdocSP(generareaza numar si factura cu serie), o apelam
				if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozdocSP')
				begin	
				declare @inputSP XMl
					set @inputSP=
						(select top 1 rtrim(@sub) as '@subunitate','AP' as '@tip', rtrim(@loc_de_munca) as '@lm' for xml Path,type)
					exec wScriuPozdocSP @sesiune, @inputSP output	
				
				set @numarAP=isnull(@inputSP.value('(/row/@numar)[1]', 'varchar(8)'),'')
				set @factura=isnull(@inputSP.value('(/row/@factura)[1]', 'varchar(20)'),'')				
				end
				
				if isnull(@numarAP,'')=''--daca nu s-a alocat numar pana aici, se ia numar din plaja
				begin
					set @fXML = '<row/>'
					set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')
					set @fXML.modify ('insert attribute tip {sql:variable("@tipDoc")} into (/row)[1]')
					set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
					set @fXML.modify ('insert attribute lm {sql:variable("@loc_de_munca")} into (/row)[1]')
					exec wIauNrDocFiscale @fXML, @NrDocFisc output
					
					if ISNULL(@NrDocFisc, 0)<>0
					begin
						set @numarAP=LTrim(RTrim(CONVERT(char(8), @NrDocFisc)))
						if ISNULL(@factura,'')=''
							set @factura=@numarAP
					end
					else
						raiserror('wOPGenBKdinBF:Eroare la generare numar document!!',11,1)	
				
				end	
			if @gestiune='' 
						set @gestiune='CC'--cerere expresa cristi ciupe(nu sunt de aceasi parere!!)-Andrei			
			insert into con (Subunitate,Tip,Contract,Tert,Punct_livrare,Data,Stare,Loc_de_munca,Gestiune,
				Termen,Scadenta,Discount,Valuta,Curs,
				Mod_plata,Mod_ambalare,Factura,Total_contractat,Total_TVA,Contract_coresp,Mod_penalizare,
				Procent_penalizare,Procent_avans,Avans,Nr_rate,Val_reziduala,Sold_initial,Cod_dobanda,Dobanda,Incasat,
				Responsabil,Responsabil_tert,Explicatii,Data_rezilierii) 
				values (@sub, 'BK', @numarAP, @tert, @punctlivrare, @datadoc,'1',@loc_de_munca,@gestiune,
				@termen, 0, 0, @valuta, @curs,	'','','',0,0,@contract,'',
				0,0,0,0,0,0,'',1,0,	'','',@explicatii,'1901-01-01')	
		
			-->>>>>>>>>>>>>>>>>>>>Cursor pe termenele din contracte din care se genereaza pozitiile facturi<<<<<<<<<<<<<<<<<---				
			set @nrpozT=0
				declare crstermene cursor for  
				select  p.cod,p.mod_de_plata,isnull(ex.camp_1,tr.cont_ca_beneficiar), t1.termen, t1.data, t1.cantitate,   
						t1.pret,t1.val1,t1.cant_realizata ,t1.val2,t1.explicatii    
				from termene t1  
						inner join pozcon p on p.subunitate=t1.subunitate and p.Contract=t1.contract and p.Data=t1.data and p.tert=t1.tert   
						and t1.cod=(case when @TermPeSurse=0 then p.cod else ltrim(str(p.numar_pozitie)) end)  
						inner join terti tr on tr.subunitate=t1.subunitate and tr.tert=t1.tert  
						left join extcon ex on ex.subunitate=t1.subunitate and ex.tert=t1.tert and ex.contract=t1.contract and ex.numar_pozitie=1  
				where t1.tip='BF' and t1.contract=@contract and t1.data=@data and t1.tert=@tert   
						and t1.termen between @data_jos and @data_sus and t1.val2=1 and t1.Cant_realizata<>t1.val1 and t1.pret<>0  
						--and not exists(select 1 from Termene t3 where t1.Tip=t3.Tip and t1.Data=t3.Data and t1.Contract=t3.Contract   
						--and t1.Tert=t3.Tert and t3.Val2=0 and t3.Termen between @data_jos and @data_sus)  
						/*Silviu: fara not exists deoarece se permite generarea de factura chiar daca nu sunt toate termenele realizate!*/  
				open crstermene
				fetch next from crstermene into @codT, @modplataT,@cont_corespondentT,@termenT, @dataT, @cantitateT, @pretT,@val1T,@cant_realizataT,@val2T,@explicatiiT
				while @@fetch_status = 0
				begin		
				    
					set @proc_tva=ISNULL((select Cota_TVA from nomencl where cod=@codT),0)
					set @cont_tva=ISNULL((select max(rtrim(val_alfanumerica)) from par where Tip_parametru='GE' and Parametru='CCTVA' and Val_logica=1),'4427.01')
					set @cont_de_stoc=(select max(cont) from nomencl where cod=@codT)
					/*if @nrpozT is null set @nrpozT=0
					else if (@codMeniu='GF')
						begin
							set @cantitateT = (select sum(t.cantitate) from termene t		
								inner join pozcon p on p.subunitate=t.subunitate and p.Contract=t.contract and p.tert=t.tert and p.Cod=t.Cod and p.Data=t.data
								inner join con on con.subunitate=t.subunitate and con.Contract=t.contract and con.tert=t.tert and con.Data=t.data
								where con.stare='1' and p.Tip='BF' and p.Tert=@tert and p.Subunitate=@sub and p.Contract=@contract and t.Cod=@codT )
			 	 
							set @cant_realizataT = (select sum(t.Cant_realizata) from termene t 
								inner join pozcon p on p.subunitate=t.subunitate and p.Contract=t.contract and p.Data=t.data and p.tert=t.tert and p.Cod=t.Cod
								inner join con on con.subunitate=t.subunitate and con.Contract=t.contract and con.Data=t.data and con.tert=t.tert
								where con.stare='1' and p.Tip='BF' and p.Tert=@tert and p.Subunitate=@sub and p.Contract=@contract and t.Cod=@codT )
					 
							set @val1T= (select sum(t.Val1) from termene t 
								inner join pozcon p on p.subunitate=t.subunitate and p.Contract=t.contract and p.Data=t.data and p.tert=t.tert and p.Cod=t.Cod
								inner join con on con.subunitate=t.subunitate and con.Contract=t.contract and con.Data=t.data and con.tert=t.tert
								where con.stare='1'and p.Tip='BF' and p.Tert=@tert and p.Subunitate=@sub and p.Contract=@contract and t.Cod=@codT )
							 
							set @pretT = (select max(t.Pret) from termene t 
								inner join pozcon p on p.subunitate=t.subunitate and p.Contract=t.contract and p.Data=t.data and p.tert=t.tert
								inner join con on con.subunitate=t.subunitate and con.Contract=t.contract and con.Data=t.data and con.tert=t.tert
								where con.stare='1' and p.Tip='BF' and p.Tert=@tert and p.Subunitate=@sub and p.Contract=@contract and t.Cod=@codT )
						end */
					set @cantfact=convert(decimal(17,5),(case when @val2T=1 then @val1T-@cant_realizataT else 0 end))
					if @cantfact <> 0 and @pretT > 0
					begin					
						--set @nrpozT=isnull((select max(numar_pozitie) from pozcon where subunitate=@sub and tip='BK' and Contract=@factura and tert=@tert and Data=@datadoc),0)+1
						set @nrpozT=@nrpozT+1
						insert into pozcon 
							(Subunitate,Tip,Contract,Tert,Punct_livrare,Data,Cod,Cantitate,
							Pret,Pret_promotional,Discount,Termen,Factura,Cant_disponibila,Cant_aprobata,Cant_realizata,
							Valuta,Cota_TVA,Suma_TVA,Mod_de_plata,UM,Zi_scadenta_din_luna,Explicatii,Numar_pozitie,Utilizator,
							Data_operarii,Ora_operarii) 
							values( @sub, 'BK', @numarAP, @tert, @punctlivrare, @datadoc, @codT, @cantfact, @pretT, 0, 0, @termenT, '', 0, @cantfact, 0,
							@valuta,@proc_tva, round((@cantfact*@pretT*@proc_tva/100),2), @modplataT, '', 0, @explicatiiT, @nrpozT, @Utilizator,
							convert(datetime, convert(char(10), getdate(), 104), 104), RTrim(replace(convert(char(8), getdate(), 108), ':', '')))
						update con 
							set Total_contractat=Total_contractat+round(@cantfact*@pretT,2), 
								Total_TVA=Total_TVA+round((@cantfact*@pretT*@proc_tva/100),2) 
						where tip='BK' and tert=@tert and Contract=@factura and Subunitate=@sub and Data=@datadoc
				
						--Generare AS in Pozdoc si prin triggerul aferent in Doc
						if @zilescad is not null 
							set @datascad=dateadd(d,@zilescad,@datadoc)
						else	
							set @datascad=dateadd(d,@scadenta,@datadoc)
						
						if @cont_corespondentT='' set @cont_corespondentT=(select cont_ca_beneficiar from terti where subunitate=@sub and tert=@tert)
							
						declare @binar varbinary(128)		
						set @binar=cast('modificaredocdefinitiv' as varbinary(128))-->context info pt a fenta triggerul doc definitive
						set CONTEXT_INFO @binar
						
						--in cazul in care este introdus pe macheta se ia contul factura de acolo
						if isnull(@cont_factura,'')<>''
							set @cont_corespondentT=@cont_factura
						declare @input XMl
						set @input=
							(select top 1 rtrim(@sub) as '@subunitate','AP' as '@tip',2 as '@stare',
								rtrim(@numarAP) as '@numar', convert(char(10),@datadoc,101) as '@data',rtrim(@tert) as '@tert',rtrim(@punctlivrare) as '@punctlivrare',
								rtrim(@cont_corespondentT) as '@contfactura',rtrim(@factura) as '@factura', convert(char(10),@datadoc,101) as '@datafacturii',
								 convert(char(10),@datascad,101) as '@datascadentei',rtrim(@loc_de_munca) as '@lm',rtrim(@numarAP) as '@contract',
							
								(select  rtrim(@gestiune) as '@gestiune',rtrim(@codT) as '@cod',2 as '@stare',
									 convert(decimal(17,5),@cantfact) as '@cantitate',RTRIM(@valuta) as '@valuta',						 
									 convert(decimal(17,5),@pretT) as '@pvaluta',convert(decimal(12,3),@curs) as '@curs',
									 convert(decimal(17,2),@proc_tva) as '@cotatva','1' as '@categpret',
									 rtrim(@modplataT) as '@barcod',rtrim(@jurnal) as '@jurnal',
									 (case when @subtip='KX' and ISNULL(@aviz_coresp,'')<>'' then @aviz_coresp else null end) as '@codintrare',
									 (case when @subtip='KX' and ISNULL(@cont_coresp,'')<>'' then @cont_coresp else null end) as '@contstoc'
							 
								for XML path,type)
							for xml Path,type)

					 exec wScriuPozdoc @sesiune,@input
					 set CONTEXT_INFO 0x00--> resetare context info	
			--select CONVERT(varchar(max),@input)
						/*exec scriuAviz @tipDoc, @factura, @datadoc, @tert, @punctlivrare, @cont_corespondentT, @factura, @datadoc, @datascad, 
							@gestiune, @codT, '', @cantfact, @pretT, @valuta, @curs, 0, null, @proc_tva, null, null, 
							'1', @loc_de_munca, '', @factura, '', 5, @modplataT, 0, 0, '', @utilizator, null, null, null, null, 1*/
							
					if @explicatiiT=''
					  update termene set Explicatii=@factura, Data2=@datadoc where contract=@contract and cod=@codT and data=@dataT and termen=@termenT 
					
					end
					fetch next from crstermene into @codT, @modplataT,@cont_corespondentT,@termenT, @dataT, @cantitateT, @pretT,@val1T,@cant_realizataT,@val2T,@explicatiiT
				end
				
				begin try 
					close crstermene 
				end try 
				begin catch end catch
				begin try 
					deallocate crstermene 
				end try 
				begin catch end catch	
				
		-->>>>>>>>>>>script de scriere in anexafac<<<<<<<<<<<<<<--
				delete anexafac where Numar_factura=@factura
				insert into anexafac (Subunitate, Numar_factura, Numele_delegatului, Seria_buletin, Numar_buletin, Eliberat, Mijloc_de_transport, Numarul_mijlocului, Data_expedierii, Ora_expedierii, Observatii)
				select @sub,@factura,@numele_delegatului,@seria_buletin,@numar_buletin,@eliberat,@mijloc_de_transport,@numarul_mijlocului,
				 @data_expedierii,@ora_expedierii,@explicatii_anexaf
				set @generareV=@generareV+1		
		
		fetch next from crscontracte into @contract,@data, @tert, @valuta, @loc_de_munca, @explicatii, @scadenta, @punctlivrare,@termen	,@gestiune
		end				
		begin try 
			close crscontracte 
		end try 
		begin catch end catch
		begin try 
			deallocate crscontracte 
		end try 
		begin catch end catch
		
	end	
	commit tran GenBKdinBF 
		-------------------------------Generare formular daca e pusa bifa-----------------------------------------
	if @generare=1 and @generareV>0 and isnull(@formular,'')<>''
	begin
		declare @p2 xml,@paramXmlString varchar(max)
		set @paramXmlString= (select @tipDoc as tip, @formular as nrform, @ftert as tert, rtrim(@numarAP) as numar, 
		 rtrim(@numarAP) as factura, @datadoc as data, 
		 @inXML as inXML for xml raw )
		exec wTipFormular @sesiune, @paramXmlString
	end
	-------------------------------Generare mesaj de final ----------------------------------------------------
	if @generareV>0 and @subtip in ('KE','KX')
		select 'S-a generat factura cu numarul '+ rtrim(@factura)+'!!' as textMesaj for xml raw, root('Mesaje')
	else
	 if @generareV>0 and @codMeniu='GF' and @genFacturi=1
			select 'Generarea a fost efectuata cu succes. Au fost generate '+ convert(varchar,@generareV)+' facturi!!' as textMesaj for xml raw, root('Mesaje')
		else
			if @genRealizari=1 and @realizari>1
				select 'Termenele au fost realizate!!' as textMesaj for xml raw, root('Mesaje')
			else		
			select 'Verificati realizarile, Nu a fost efectuata nici o operatie!!' as textMesaj for xml raw, root('Mesaje')
	 --
 
end try 
begin catch	
	declare @mesaj varchar(200) 
	set @mesaj=ERROR_MESSAGE()
end catch

declare @cursorStatus int
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='crscontracte' and session_id=@@SPID )
if @cursorStatus=1 
	close crscontracte 
if @cursorStatus is not null 
	deallocate crscontracte 

if LEN(@mesaj)>0
begin
	ROLLBACK TRAN GenBKdinBF
	raiserror(@mesaj, 11, 1)
end	
