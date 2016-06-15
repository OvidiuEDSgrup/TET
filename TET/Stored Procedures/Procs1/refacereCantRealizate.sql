--***
create procedure refacereCantRealizate @stergereRealizari int, @recalculareRealizari int, @contracteFA int,@comenziAprovFC int, @contracteBF int, @comenziLivrBK int,
	@proformeBP int, @datajos datetime, @datasus datetime, @detaliiComProd int, @detaliiComAprov int, @fltContract varchar(20)
as
begin
	declare @sub varchar(2),@TermPeSurse int,@MULTICDBK int
	declare @cComAprov char(20), @dAprov datetime, @cFurn char(13), @cCod char(20), @nCantReceptie float, 
		@cTip char(2), @cComLivr char(20), @dLivr datetime, @cBenef char(13), @nCantComandata float, @nCantReceptionata float, 
		@nCantDescarc float, @nCantRealizBK float, @nCantRealizata float,
		@cComProd char(20),@nCantPredare float,@nCantLivrata float 	
	declare @stareAprobatBK varchar(1),@stareRealizatBK varchar(1),@stareTransferatBK varchar(1),@stareFacturabilBK varchar(1),
		@stareBlocatBK varchar(1), @stareInchisBK varchar(1),@realBFdinBKapob int
	
	create table #TipuriContr (tip varchar(2))
	if @contracteFA=1
		insert into #TipuriContr select 'FA'
	if @comenziAprovFC=1
		insert into #TipuriContr select 'FC'	
	if @contracteBF=1
		insert into #TipuriContr select 'BF'	
	if @comenziLivrBK=1
		insert into #TipuriContr select 'BK'
	if @proformeBP=1
		insert into #TipuriContr select 'BP'	
		
		
	--luare date din par
	select @sub=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else @sub end),
		@TermPeSurse=isnull((case when Parametru='POZSURSE' then Val_logica else @TermPeSurse end),0),
		@MULTICDBK=isnull((case when Parametru='MULTICDBK' and Tip_parametru='UC' then Val_logica else @MULTICDBK end),0),
		@stareRealizatBK=isnull((case when Parametru='STBKREAL' and Tip_parametru='UC' then Val_logica else @stareRealizatBK end),'6'),
		@stareTransferatBK=isnull((case when Parametru='STBKTRANS' and Tip_parametru='UC' then Val_logica else @stareTransferatBK end),'4'),
		@stareFacturabilBK=isnull((case when Parametru='STBKFACT' and Tip_parametru='UC' then Val_logica else @stareFacturabilBK end),'1'),
		@stareAprobatBK=isnull((case when Parametru='STBKAPROB' and Tip_parametru='UC' then Val_logica else @stareAprobatBK end),'1'),
		@stareBlocatBK=isnull((case when Parametru='STBKBLOC' and Tip_parametru='UC' then Val_logica else @stareBlocatBK end),'2'),
		@stareInchisBK=isnull((case when Parametru='STBKINCH' and Tip_parametru='UC' then Val_logica else @stareInchisBK end),'7'),
		@realBFdinBKapob=isnull((case when Parametru='RBFBKAPR' and Tip_parametru='UC' then Val_logica else @realBFdinBKapob end),0)
	from par
	where (Tip_parametru='GE' and Parametru ='SUBPRO') or (Tip_parametru='UC' and Parametru in ('POZSURSE','MULTICDBK'))
	
	--stergere realizari
	if @stergereRealizari=1
	begin	
		update pozcon 
		set cant_realizata = 0
		where subunitate=@sub 
			and tip in (select tip from #TipuriContr) 
			and data between @datajos and @datasus 
			and (isnull(@fltContract,'')='' or  contract=@fltContract)

		update termene 
		set cant_realizata = 0
		where subunitate=@sub 
			and 'BF' in (select tip from #TipuriContr) 
			and data between @datajos and @datasus 
			and (isnull(@fltContract,'')='' or  contract=@fltContract)

		update pozcon 
		set pret_promotional = 0
		where subunitate=@sub 
			and 'BK' in (select tip from #TipuriContr) 
			and data between @datajos and @datasus and punct_livrare<>''
			and (isnull(@fltContract,'')='' or  contract=@fltContract)
	end
	
	if @recalculareRealizari=1
	begin
		--refacere realizari pentru comenzi(BK,FC,BP)
		if @comenziAprovFC=1
		begin
			--refacere cantitate realizata din pozdoc pentru FC
			update pozcon 
			set cant_realizata = 
				isnull((select sum(cantitate) 
				from pozdoc 
				where pozdoc.subunitate=pozcon.subunitate 
					and pozdoc.tip in ('RM','RS')
					/*and pozdoc.tert=pozcon.tert*/ /*and (pozcon.factura='' or pozdoc.gestiune=pozcon.factura) */
					and pozdoc.cod=pozcon.cod and pozdoc.contract=pozcon.contract
					and (@MULTICDBK=0 or pozcon.tip not in ('BK', 'BP') or abs(pozcon.pret-(case when left(pozdoc.tip,1)='R' or pozdoc.valuta<>'' then pozdoc.pret_valuta else pozdoc.pret_vanzare end))<0.00001)), 0)
			where subunitate=@sub and tip='FC'
				and data between @datajos and @datasus
				and (isnull(@fltContract,'')='' or  contract=@fltContract)
		end	
		
		if 	@comenziLivrBK=1
		begin
			--refacere cantitate realizata din pozdoc pentru BK
			update pozcon 
			set cant_realizata = 
				isnull((select sum(cantitate) 
				from pozdoc 
				where pozdoc.subunitate=pozcon.subunitate 
					and pozdoc.tip in ('AC','AS','AP')
					/*and pozdoc.tert=pozcon.tert*/ /*and (pozcon.factura='' or pozdoc.gestiune=pozcon.factura) */
					and pozdoc.cod=pozcon.cod and pozdoc.contract=pozcon.contract
					and (@MULTICDBK=0 or pozcon.tip not in ('BK', 'BP') or abs(pozcon.pret-(case when left(pozdoc.tip,1)='R' or pozdoc.valuta<>'' then pozdoc.pret_valuta else pozdoc.pret_vanzare end))<0.00001)), 0)
			where subunitate=@sub and tip='BK'
				and data between @datajos and @datasus
				and (isnull(@fltContract,'')='' or  contract=@fltContract)
		
			--transferat din pozdoc
			update pozcon 
			set pret_promotional = isnull((select sum(pozdoc.cantitate) from pozdoc 
						where pozdoc.subunitate=pozcon.subunitate and pozdoc.tip in ('TE', 'AE') 
						and (pozdoc.tip='TE' and pozdoc.factura=pozcon.contract or pozdoc.tip='AE' and pozdoc.grupa=pozcon.contract) 
						and pozdoc.cod=pozcon.cod 
						and (@MULTICDBK=0 or abs(round(convert(decimal(17, 5), pozcon.pret*(1.00+(case when isnull(g.tip_gestiune, '') not in ('A', 'V') then pozcon.cota_TVA else 0 end)/100.00)), 5)-pozdoc.pret_cu_amanuntul)<=0.001)
						/*and (pozcon.factura='' or pozdoc.gestiune=pozcon.factura) */
						/*and (pozdoc.tip='AE' or pozcon.punct_livrare=(case when pozdoc.contract='' then pozdoc.gestiune_primitoare else pozdoc.contract end)) */), 0)
			from pozcon left outer join gestiuni g on g.subunitate=pozcon.subunitate and g.cod_gestiune=pozcon.punct_livrare
			where pozcon.subunitate=@sub 
				and pozcon.tip='BK' 
				and pozcon.data between @datajos and @datasus 
				and pozcon.punct_livrare<>''
				and (isnull(@fltContract,'')='' or  contract=@fltContract)	
		end	--@comenziLivrBK=1
		
		
		if @proformeBP=1
		begin
			--refacere cantitate realizata din pozdoc pentru BP
			update pozcon 
			set cant_realizata = 
				isnull((select sum(cantitate) 
				from pozdoc 
				where pozdoc.subunitate=pozcon.subunitate 
					and pozdoc.tip in ('AC','AS','AP')
					/*and pozdoc.tert=pozcon.tert*/ /*and (pozcon.factura='' or pozdoc.gestiune=pozcon.factura) */
					and pozdoc.cod=pozcon.cod and pozdoc.contract=pozcon.contract
					and (@MULTICDBK=0 or pozcon.tip not in ('BK', 'BP') or abs(pozcon.pret-(case when left(pozdoc.tip,1)='R' or pozdoc.valuta<>'' then pozdoc.pret_valuta else pozdoc.pret_vanzare end))<0.00001)), 0)
			where subunitate=@sub and tip='BP'
				and data between @datajos and @datasus
				and (isnull(@fltContract,'')='' or  contract=@fltContract)
		end
		
	
		--refacere realizari pentru contracte
		if @contracteFA=1
		begin
			update pozcon 
			set cant_realizata = 
				isnull((select sum(case when /*@dinCantAprobata*/0=1 then p.cant_aprobata else p.cantitate end) 
				from pozcon p 
					inner join con c on c.subunitate=p.subunitate and c.tip=p.tip and c.contract=p.contract and c.tert=p.tert and c.data=p.data 
				where p.subunitate=pozcon.subunitate 
					and p.tip='FC' 
					and p.tert=pozcon.tert 
					and p.cod=pozcon.cod 
					and c.contract_coresp=pozcon.contract), 0)
			where subunitate=@sub and tip='FA' 
				and data between @datajos and @datasus
				and (isnull(@fltContract,'')='' or  contract=@fltContract)
		end
		
				--refacere realizari pentru contracte
		if @contracteBF=1
		begin
			--refacere cantitate realizata din pozcon
			update pozcon 
			set cant_realizata = 
				isnull((select sum(case when @realBFdinBKapob=1 then p.cant_aprobata else p.cantitate end) 
				from pozcon p 
					inner join con c on c.subunitate=p.subunitate and c.tip=p.tip and c.contract=p.contract and c.tert=p.tert and c.data=p.data 
				where p.subunitate=pozcon.subunitate 
					and p.tip='BK' 
					and p.tert=pozcon.tert 
					and p.cod=pozcon.cod 
					and c.contract_coresp=pozcon.contract), 0)
			where subunitate=@sub and tip='BF' 
				and data between @datajos and @datasus
				and (isnull(@fltContract,'')='' or  contract=@fltContract)		
		
			--refacere cantitate realizata din termene
			update termene 
			set cant_realizata = 
				isnull((select sum(case when /*@dinCantAprobata*/0=1 then p.cant_aprobata else p.cantitate end) 
				from pozcon p 
					inner join con c on p.subunitate=c.subunitate and p.tip=c.tip and p.contract=c.contract and p.tert=c.tert and p.data=c.data
				where p.tip='BK' 
					and termene.subunitate=p.subunitate 
					and termene.contract=c.contract_coresp 
					and	termene.tert=p.tert 
					and termene.cod=(case when 1=0 then p.cod else ltrim(str((select bf.numar_pozitie from pozcon bf 
						where p.subunitate=bf.subunitate and bf.Contract=c.Contract_coresp and bf.Tert=c.Tert and bf.tip='BF'			
							and termene.tip=bf.tip and termene.contract=bf.contract and termene.tert=bf.tert  
							and termene.data=bf.data and p.cod=bf.cod and bf.Mod_de_plata=p.Mod_de_plata and bf.Numar_pozitie=termene.cod))) end) 
					and termene.termen=p.termen), 0)
			where subunitate=@sub and tip='BF' 
				and data between @datajos and @datasus
				and (isnull(@fltContract,'')='' or  contract=@fltContract)
		end	--@contracteBF=1
	end--@recalculareRealizari=1
	
	if @comenziAprovFC=1 or @comenziLivrBK=1 or @proformeBP=1
	begin
		--stare antet comenzi
		update con 
		set stare = 
			(case 
				when not exists (select 1 from pozcon where con.subunitate=pozcon.subunitate and con.tip=pozcon.tip and 
				con.contract=pozcon.contract and con.tert=pozcon.tert and con.data=pozcon.data) 
					then '0' --nu are pozitii
				/*
				when exists (select 1 from pozcon where con.subunitate=pozcon.subunitate and con.tip=pozcon.tip and 
				con.contract=pozcon.contract and con.tert=pozcon.tert and con.data=pozcon.data and abs(pozcon.cantitate)>=0.001 and abs(pozcon.cant_aprobata)<0.001) 
					then '0' --exista pozitii cu aprobat=0
				*/
				when not exists (select 1 from pozcon where con.subunitate=pozcon.subunitate and con.tip=pozcon.tip and 
				con.contract=pozcon.contract and con.tert=pozcon.tert and con.data=pozcon.data and abs(pozcon.cant_aprobata)>=0.001) 
					then '0' --nu exista nici o pozitie aprobata
				when not exists (select 1 from pozcon where con.subunitate=pozcon.subunitate and con.tip=pozcon.tip and 
				con.contract=pozcon.contract and con.tert=pozcon.tert and con.data=pozcon.data and 
				(abs(pozcon.cant_aprobata)-abs(pozcon.cant_realizata)>=0.001 or abs(pozcon.cant_aprobata)>=0.001 and sign(pozcon.cant_aprobata)*sign(pozcon.cant_realizata)<1)) 
					then (case when tip in ('BK', 'BP') then @stareRealizatBK else '6' end) --realizat
				when tip='BK' and not exists (select 1 from pozcon where con.subunitate=pozcon.subunitate and con.tip=pozcon.tip and 
				con.contract=pozcon.contract and con.tert=pozcon.tert and con.data=pozcon.data and 
				(abs(pozcon.cant_aprobata)-abs(pozcon.pret_promotional)>=0.001 or abs(pozcon.cant_aprobata)>=0.001 and sign(pozcon.cant_aprobata)*sign(pozcon.pret_promotional)<1)) 
					then (case when tip in ('BK', 'BP') then @stareTransferatBK else '4' end) --expediat/transferat
				when tip in ('BK', 'BP') then (case stare when @stareRealizatBK then @stareFacturabilBK when @stareTransferatBK then @stareAprobatBK else stare end)
				else (case stare when '0' then '0' when '3' then '3' else '1' end) -- nerealizat, neexpediat => Operat sau Definitiv
			end)
		where subunitate=@sub 
			and (('FC' in (select tip from #TipuriContr) and tip='FC') 
				or ('BK' in (select tip from #TipuriContr) and tip='BK') 
				or ('BP' in (select tip from #TipuriContr) and tip='BP'))--de revazut			
			and data between @datajos and @datasus 
			and (Stare not in(@stareBlocatBK,@stareInchisBK) and tip in ('BK','BP')
				or Stare not in ('2','7'))
			and (isnull(@fltContract,'')='' or  contract=@fltContract)	
	end
	
	if @detaliiComAprov=1
	begin
		--refacere pozaprov

		if @stergereRealizari=1
		 update pozaprov set cant_receptionata=0, cant_realizata=0

		if @recalculareRealizari=1
		begin
			-- realizata FC => receptionata pozaprov
			declare tmpcmdaprov cursor for
			select p.contract as cntr, p.data as data, p.tert as tert, 
				p.cod as cod, sum(p.cant_realizata) as cant_receptie 
			from pozcon p 
			where p.subunitate=@sub and p.tip='FC' 
			group by p.contract, p.data, p.tert, p.cod
			having sum(p.cant_realizata)>=0.001
			
			open tmpcmdaprov
			fetch next from tmpcmdaprov into @cComAprov, @dAprov, @cFurn, @cCod, @nCantReceptie
			while @@fetch_status = 0
			begin
				declare tmppozaprov cursor for
				select tip, comanda_livrare, data_comenzii, beneficiar, cant_comandata, cant_receptionata
				from pozaprov where contract=@cComAprov and data=@dAprov and furnizor=@cFurn and cod=@cCod
				order by (case tip when 'BK' then 1 when 'C' then 2 else 3 end), data_comenzii 
				open tmppozaprov
				fetch next from tmppozaprov into @cTip, @cComLivr, @dLivr, @cBenef, @nCantComandata, @nCantReceptionata
				
				while @@fetch_status = 0 and abs(@nCantReceptie) >= 0.001
				begin
					set @nCantDescarc = (case when @nCantComandata - @nCantReceptionata < @nCantReceptie then @nCantComandata - @nCantReceptionata else @nCantReceptie end)
					set @nCantReceptie = @nCantReceptie - @nCantDescarc
					
					update pozaprov set cant_receptionata = cant_receptionata + @nCantDescarc
					where contract=@cComAprov and data=@dAprov and furnizor=@cFurn and cod=@cCod 
						and tip=@cTip and comanda_livrare=@cComLivr and data_comenzii=@dLivr and beneficiar=@cBenef 
					
					fetch next from tmppozaprov into @cTip, @cComLivr, @dLivr, @cBenef, @nCantComandata, @nCantReceptionata
				end
				
				close tmppozaprov
				deallocate tmppozaprov
				
				if (@nCantReceptie >= 0.001) 
				begin -- s-a receptionat mai mult decat s-a comandat
					if exists (select 1 from pozaprov where contract=@cComAprov and data=@dAprov and furnizor=@cFurn and cod=@cCod and tip='' and comanda_livrare='') 
						update pozaprov set cant_receptionata = cant_receptionata + @nCantReceptie 
						where contract=@cComAprov and data=@dAprov and furnizor=@cFurn and cod=@cCod and tip='' and comanda_livrare=''
					else
						insert into pozaprov
							(Contract, Data, Furnizor, Cod, Comanda_livrare, Data_comenzii, Beneficiar, Cant_comandata, Cant_receptionata, Cant_realizata, Tip)
						select @cComAprov, @dAprov, @cFurn, @cCod, '', @dAprov, '', 0, @nCantReceptie, 0, '' 
				end
				
				fetch next from tmpcmdaprov into @cComAprov, @dAprov, @cFurn, @cCod, @nCantReceptie
			end
			close tmpcmdaprov
			deallocate tmpcmdaprov

			--realizat BK=>realizat pozaprov
			declare tmpcmdaprov cursor for
			select p.contract as cntr, p.data as data, p.tert as tert, 
			p.cod as cod, sum(p.cant_realizata) as cant_realiz_BK 
			from pozcon p
			where p.subunitate=@sub and p.tip='BK' 
			group by p.contract, p.data, p.tert, p.cod
			having sum(p.cant_realizata)>=0.001
			
			open tmpcmdaprov
			fetch next from tmpcmdaprov into @cComLivr, @dLivr, @cBenef, @cCod, @nCantRealizBK
			while @@fetch_status = 0
			begin
				declare tmppozaprov cursor for
				select contract, data, furnizor, cant_receptionata, cant_realizata
				from pozaprov where tip='BK' and comanda_livrare=@cComLivr and data_comenzii=@dLivr and beneficiar=@cBenef and cod=@cCod
				order by data
				open tmppozaprov
				
				fetch next from tmppozaprov into @cComAprov, @dAprov, @cFurn, @nCantReceptionata, @nCantRealizata
				while @@fetch_status = 0 and abs(@nCantRealizBK) >= 0.001
				begin
					set @nCantDescarc = (case when @nCantReceptionata - @nCantRealizata < @nCantRealizBK then @nCantReceptionata - @nCantRealizata else @nCantRealizBK end)
					set @nCantRealizBK = @nCantRealizBK - @nCantDescarc
					
					update pozaprov set cant_realizata = cant_realizata + @nCantDescarc
					where contract=@cComAprov and data=@dAprov and furnizor=@cFurn and cod=@cCod 
						and tip='BK' and comanda_livrare=@cComLivr and data_comenzii=@dLivr and beneficiar=@cBenef 
					
					fetch next from tmppozaprov into @cComAprov, @dAprov, @cFurn, @nCantReceptionata, @nCantRealizata
				end
				close tmppozaprov
				deallocate tmppozaprov
				
				if (@nCantRealizBK >= 0.001 and RTrim(@cComAprov) <> '') -- s-a realizat mai mult decat s-a receptionat, am pozitie pe BK in pozaprov
					update pozaprov set cant_realizata = cant_realizata + @nCantRealizBK 
					where contract=@cComAprov and data=@dAprov and furnizor=@cFurn and cod=@cCod 
						and tip='BK' and comanda_livrare=@cComLivr and data_comenzii=@dLivr and beneficiar=@cBenef 

				fetch next from tmpcmdaprov into @cComLivr, @dLivr, @cBenef, @cCod, @nCantRealizBK
			end
			close tmpcmdaprov
			deallocate tmpcmdaprov
		end
	end
	
	if @detaliiComAprov=1
	begin
		--refacere pozprod
		if @stergereRealizari=1
			update pozprod set cantitate_realizata=0, cantitate_livrata=0

		if @recalculareRealizari=1
		begin
			-- cantitate PP => realizata pozprod
			declare tmpcmdpred cursor for
			
			select p.comanda as comanda, p.cod as cod, 
				sum(p.cantitate) as cant_predare
			from pozdoc p
			where p.subunitate=@sub and p.tip='PP' and p.comanda<>''
			group by p.comanda, p.cod
			having sum(p.cantitate)>=0.001
			open tmpcmdpred
			
			fetch next from tmpcmdpred into @cComProd, @cCod, @nCantPredare
			while @@fetch_status = 0
			begin
				declare tmppozprod cursor for
				select comanda_livrare, data_comenzii, beneficiar, cantitate_comandata, cantitate_realizata
				from pozprod 
				where comanda=@cComProd and cod=@cCod
				order by data_comenzii, comanda_livrare
				open tmppozprod
				fetch next from tmppozprod into @cComLivr, @dLivr, @cBenef, @nCantComandata, @nCantRealizata
				
				while @@fetch_status = 0 and abs(@nCantPredare) >= 0.001
				begin
					set @nCantDescarc = (case when @nCantComandata - @nCantRealizata < @nCantPredare then @nCantComandata - @nCantRealizata else @nCantPredare end)
					set @nCantPredare = @nCantPredare - @nCantDescarc
					
					update pozprod set cantitate_realizata = cantitate_realizata + @nCantDescarc
					where comanda=@cComProd and cod=@cCod and comanda_livrare=@cComLivr and data_comenzii=@dLivr and beneficiar=@cBenef 
					
					fetch next from tmppozprod into @cComLivr, @dLivr, @cBenef, @nCantComandata, @nCantRealizata
				end
				close tmppozprod
				deallocate tmppozprod
				
				fetch next from tmpcmdpred into @cComProd, @cCod, @nCantPredare
			end
			close tmpcmdpred
			deallocate tmpcmdpred

			--realizat BK=>livrat pozprod
			declare tmpcmdaprov cursor for
			select p.contract as cntr, p.data as data, p.tert as tert, 
				p.cod as cod, sum(p.cant_realizata) as cant_realiz_BK 
			from pozcon p 
			where p.subunitate=@sub and p.tip='BK' 
			group by p.contract, p.data, p.tert, p.cod
			having sum(p.cant_realizata)>=0.001
			
			open tmpcmdaprov
			fetch next from tmpcmdaprov into @cComLivr, @dLivr, @cBenef, @cCod, @nCantRealizBK
			while @@fetch_status = 0
			begin
				declare tmppozprod cursor for
				select p.comanda, cantitate_realizata, cantitate_livrata
				from pozprod p
					left outer join comenzi c on c.subunitate=@sub and c.comanda=p.comanda
				where comanda_livrare=@cComLivr and data_comenzii=@dLivr and p.beneficiar=@cBenef and p.cod=@cCod
				order by isnull(c.data_lansarii, '12/31/2999'), p.comanda 
				open tmppozprod
				
				fetch next from tmppozprod into @cComProd, @nCantRealizata, @nCantLivrata
				while @@fetch_status = 0 and abs(@nCantRealizBK) >= 0.001
				begin
					set @nCantDescarc = (case when @nCantRealizata - @nCantLivrata < @nCantRealizBK then @nCantRealizata - @nCantLivrata else @nCantRealizBK end)
					set @nCantRealizBK = @nCantRealizBK - @nCantDescarc
					
					update pozprod set cantitate_livrata = cantitate_livrata + @nCantDescarc
					where comanda=@cComProd and cod=@cCod and comanda_livrare=@cComLivr and data_comenzii=@dLivr and beneficiar=@cBenef 
					
					fetch next from tmppozprod into @cComProd, @nCantRealizata, @nCantLivrata
				end
				close tmppozprod
				deallocate tmppozprod

				fetch next from tmpcmdaprov into @cComLivr, @dLivr, @cBenef, @cCod, @nCantRealizBK
			end
			close tmpcmdaprov
			deallocate tmpcmdaprov
		end
	end
	
end

