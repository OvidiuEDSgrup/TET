--***
create procedure wOPReincadrareIesiriToateGest @sesiune varchar(50), @parXML xml                
as              
declare @subunitate char(9),@gestiune varchar(20),@cod varchar(20),@pDataJ datetime,@pDataS datetime,@cugolire int

select top 1 @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'
--exec wOPReincadrareIesiriToateGest @sesiune='', @parXML='<row gestiune="CAS.CJ" dataj="2012-03-01" datas="2012-05-31" cugolire="0"/>'
--exec wOPReincadrareIesiriToateGest @sesiune='', @parXML='<row gestiune="COLO" dataj="2011-05-01" datas="2011-05-31" cugolire="0"/>'
select
 @gestiune=ISNULL(@parXML.value('(/*/@gestiune)[1]', 'varchar(20)'), '') ,
 @cod=ISNULL(@parXML.value('(/*/@cod)[1]', 'varchar(20)'), '') ,
 @cuGolire=ISNULL(@parXML.value('(/*/@cugolire)[1]', 'int'), 0) , -- daca =0 se verifica iesirile care au problema, daca =1 se reincadreaza toate documentele.
 @pDataJ=ISNULL(@parXML.value('(/*/@dataj)[1]', 'datetime'), '') ,  
 @pDataS=ISNULL(@parXML.value('(/*/@datas)[1]', 'datetime'), '')

begin try

	select gestiune,gestiune_primitoare,count(*) as nrp from pozdoc where subunitate='1' and tip='TE'
	group by gestiune,Gestiune_primitoare
	order by 3 desc
	begin transaction stoc

	select top 0 Cantitate,TVa_deductibil,Subunitate,Tip,Numar,Cod,Data,Gestiune,Pret_valuta,Pret_de_stoc,Adaos,Pret_vanzare,Pret_cu_amanuntul,Cota_TVA,Utilizator,Data_operarii,Ora_operarii,Cod_intrare,Cont_de_stoc,Cont_corespondent,TVA_neexigibil,Pret_amanunt_predator,Tip_miscare,Locatie,Data_expirarii,Numar_pozitie,Loc_de_munca,Comanda,Barcod,Cont_intermediar,Cont_venituri,Discount,Tert,Factura,Gestiune_primitoare,Numar_DVI,Stare,Grupa,Cont_factura,Valuta,Curs,Data_facturii,Data_scadentei,Procent_vama,Suprataxe_vama,Accize_cumparare,Accize_datorate,Contract,Jurnal,
	CONVERT(FLOAT,0) as cumulat,0 as nrordmin,0 as nrordmax,convert(float,0) as tvaunit,0 as nrp, 0 as nrpozmax 
	into #pozd from pozdoc
	

	--select SUM(cantitate) from pozdoc 
	--left outer join stocuri st on pozdoc.subunitate=st.subunitate and pozdoc.gestiune=st.cod_gestiune and pozdoc.cod=st.cod and pozdoc.cod_intrare=st.cod_intrare
	--where pozdoc.subunitate=@subunitate 
	--and pozdoc.data between @pDataJ and @pDataS
	--and pozdoc.gestiune=@gestiune
	--and pozdoc.tip_miscare='E' and abs(pozdoc.cantitate)>=0.001
	--and (@cugolire=1 or st.cod is null or st.stoc<=-0.001 or pozdoc.Cod_intrare='' or pozdoc.Pret_de_stoc!=st.Pret or pozdoc.Cont_de_stoc!=st.Cont or pozdoc.Pret_amanunt_predator!=st.Pret_cu_amanuntul)


	delete pozdoc
	OUTPUT DELETED.Cantitate,DELETED.TVa_deductibil,DELETED.Subunitate,DELETED.Tip,DELETED.Numar,DELETED.Cod,DELETED.Data,DELETED.Gestiune,
		DELETED.Pret_valuta,DELETED.Pret_de_stoc,DELETED.Adaos,DELETED.Pret_vanzare,DELETED.Pret_cu_amanuntul,DELETED.Cota_TVA,
		DELETED.Utilizator,DELETED.Data_operarii,DELETED.Ora_operarii,DELETED.Cod_intrare,DELETED.Cont_de_stoc,DELETED.Cont_corespondent,
		DELETED.TVA_neexigibil,DELETED.Pret_amanunt_predator,DELETED.Tip_miscare,DELETED.Locatie,DELETED.Data_expirarii,DELETED.Numar_pozitie,
		DELETED.Loc_de_munca,DELETED.Comanda,DELETED.Barcod,DELETED.Cont_intermediar,DELETED.Cont_venituri,DELETED.Discount,DELETED.Tert,DELETED.Factura,
		DELETED.Gestiune_primitoare,DELETED.Numar_DVI,DELETED.Stare,DELETED.Grupa,DELETED.Cont_factura,DELETED.Valuta,DELETED.Curs,
		DELETED.Data_facturii,DELETED.Data_scadentei,DELETED.Procent_vama,DELETED.Suprataxe_vama,DELETED.Accize_cumparare,DELETED.Accize_datorate,DELETED.Contract,DELETED.Jurnal,
		CONVERT(FLOAT,0) as cumulat,0 as nrordmin,0 as nrordmax,deleted.tva_deductibil/deleted.cantitate as tvaunit,0,0
	INTO #pozd
	from pozdoc
	left outer join stocuri st on pozdoc.subunitate=st.subunitate and pozdoc.gestiune=st.cod_gestiune and pozdoc.cod=st.cod and pozdoc.cod_intrare=st.cod_intrare
	where pozdoc.subunitate=@subunitate 
	and pozdoc.data between @pDataJ and @pDataS
	and (@cod='' or pozdoc.cod=@cod)
	and (@gestiune='' or pozdoc.gestiune=@gestiune)
	and pozdoc.tip_miscare='E' and abs(pozdoc.cantitate)>=0.001
	--and not (tip='TE' and pozdoc.gestiune=pozdoc.Gestiune_primitoare) -- tentativa de execeptare modificari de pret
	and (@cugolire=1 or st.cod is null or st.stoc<=-0.001 or pozdoc.Cod_intrare='' or pozdoc.Pret_de_stoc!=st.Pret or pozdoc.Cont_de_stoc!=st.Cont or pozdoc.Pret_amanunt_predator!=st.Pret_cu_amanuntul)
	
	update #pozd set nrp=ranc
	from 
	(select p2.subunitate,p2.tip,p2.numar,p2.data,p2.numar_pozitie,
	ROW_NUMBER() over (partition by p2.cod order by p2.cod,p2.data) as ranc
	from #pozd p2) p1 where p1.subunitate=#pozd.subunitate and p1.tip=#pozd.tip and p1.numar=#pozd.numar and p1.data=#pozd.data and p1.numar_pozitie=#pozd.Numar_pozitie

	update #pozd set nrpozmax=maxpoz 
	from 
	(select p2.subunitate,p2.tip,p2.numar,p2.data,
	MAX(p2.numar_pozitie) as maxpoz
	from pozdoc p2
	inner join #pozd p3 on p2.subunitate=p3.subunitate and p2.tip=p3.tip and p2.numar=p3.numar and p2.data=p3.data 
	group by p2.subunitate,p2.tip,p2.numar,p2.data
	) p1 where p1.subunitate=#pozd.subunitate and p1.tip=#pozd.tip and p1.numar=#pozd.numar and p1.data=#pozd.data 
	--declare @pX xml
	--set @pX='<parametri tabela="Stocuri" gest="'+@gestiune+'"/>'
	--exec wOPRefacereStocuri @sesiune=@sesiune,@parXML=@pX

--	select * from #pozd

	select row_number() over (partition by tip_gestiune,cod_gestiune,cod order by data) as nrord, 
		convert(float,0.00) as stoctotal, *
	into #stoctotal
	from stocuri
	where 
	(@cod='' or cod=@cod)
	and (@gestiune='' or cod_gestiune=@gestiune)
	and cod in (select distinct cod from #pozd)
	and stoc>=0.001

	--Mai punem o linie in stocuri cu cod intrare necompletat din stocuri
	insert into #stoctotal
	select
	s1.nrord+1,0,s1.Subunitate,s1.Tip_gestiune,s1.Cod_gestiune,s1.Cod,dateadd(day,1,s1.Data),'' as cod_intrare,
		s1.Pret,10000000,10000000,0,s1.Data_ultimei_iesiri,10000000,s1.Cont,s1.Data_expirarii,s1.Stoc_ce_se_calculeaza,s1.Are_documente_in_perioada,s1.TVA_neexigibil,s1.Pret_cu_amanuntul,s1.Locatie,s1.Pret_vanzare,s1.Loc_de_munca,s1.Comanda,s1.Contract,s1.Furnizor,s1.Lot,s1.Stoc_initial_UM2,s1.Intrari_UM2,s1.Iesiri_UM2,s1.Stoc_UM2,s1.Stoc2_ce_se_calculeaza,s1.Val1,s1.Alfa1,s1.Data1
	from #stoctotal s1
	inner join 
	(select s1.Tip_gestiune,s1.Cod_gestiune,s1.Cod,MAX(nrord) as nrord
	from #stoctotal s1
	group by s1.Tip_gestiune,s1.Cod_gestiune,s1.Cod) sm on s1.Tip_gestiune=sm.Tip_gestiune and s1.Cod_gestiune=sm.Cod_gestiune 
		and s1.Cod=sm.Cod and s1.nrord=sm.nrord	
	--Mai punem o linie in stocuri cu cod intrare necompletat din pozdoc
	insert into #stoctotal
	select
	1,0,p.Subunitate,ISNULL(g.Tip_gestiune,'C'),p.gestiune,p.Cod,p.Data,'' as cod_intrare,
		p.Pret_de_stoc,10000000,10000000,0,p.Data,10000000,p.Cont_de_stoc,p.Data,0,0,p.TVA_neexigibil,p.Pret_cu_amanuntul,p.Locatie,p.Pret_vanzare,p.Loc_de_munca,p.Comanda,p.Contract,'','',0,0,0,0,0,0,'',p.Data
	from #pozd p
	left outer join gestiuni g on g.Subunitate=p.subunitate and g.Cod_gestiune=p.gestiune
	left outer join #stoctotal s on s.subunitate=p.subunitate and s.cod_gestiune=p.gestiune and s.cod=p.cod
	where s.cod is null -- echivalent "not exists"
	
	update #stoctotal set stoctotal=st
	from 
	(select s1.Tip_gestiune,s1.Cod_gestiune,s1.Cod,s1.nrord,SUM(s2.stoc) as st from #stoctotal s1,#stoctotal s2
	where s1.Tip_gestiune=s2.Tip_gestiune and s1.Cod_gestiune=s2.Cod_gestiune and s1.Cod=s2.Cod and s2.nrord<=s1.nrord
	group by s1.Tip_gestiune,s1.Cod_gestiune,s1.Cod,s1.nrord
	) calcule 
	where calcule.Tip_gestiune=#stoctotal.Tip_gestiune and calcule.Cod_gestiune=#stoctotal.Cod_gestiune and
		calcule.Cod=#stoctotal.Cod and calcule.nrord=#stoctotal.nrord

	update #pozd set cumulat=tot.cum
	from 
	(select c1.subunitate,c1.tip,c1.Numar,c1.cod,c1.comanda,c1.Loc_de_munca,c1.Data,c1.nrp,SUM(c2.cantitate) as cum from #pozd c1
		inner join #pozd c2 on c1.cod=c2.cod and c1.gestiune=c2.gestiune and c2.nrp<=c1.nrp
		group by c1.subunitate,c1.tip,c1.Numar,c1.cod,c1.comanda,c1.Loc_de_munca,c1.Data,c1.nrp) tot
	where #pozd.subunitate=tot.subunitate and #pozd.tip=tot.tip and #pozd.Numar=tot.Numar and #pozd.cod=tot.cod and #pozd.comanda=tot.comanda and #pozd.nrp=tot.nrp

	/*Punem min si max */
	update #pozd set nrordmin=st.nrord,nrordmax=st2.nrord
	from #pozd c
		cross apply
			(select top 1 smin.nrord from #stoctotal smin where smin.cod=c.cod and smin.Cod_gestiune=c.gestiune and c.cumulat-c.cantitate<smin.stoctotal order by smin.stoctotal) st 
		cross apply
			(select top 1 smax.nrord from #stoctotal smax where smax.cod=c.cod and smax.Cod_gestiune=c.gestiune and c.cumulat<=smax.stoctotal order by smax.stoctotal) st2
		
	--Fara DETALII Momentan
		
	--select * from #pozd 
    --select * from #stoctotal 
	--select 
	--	sum(case 
	--		when pd.nrordmin=pd.nrordmax or pd.cantitate<0 
	--			then pd.cantitate
	--		when pd.nrordmin=s1.nrord --prima linie de pe stoc
	--			then pd.cantitate-(pd.cumulat-s1.stoctotal)
	--		when pd.nrordmax=s1.nrord --ultima linie de pe stoc
	--			then (pd.cumulat+s1.stoc-s1.stoctotal)
	--	  else s1.stoc
	--	end) as cantitate 
	--	from #pozd pd
 --    	inner join #stoctotal s1 on s1.cod_gestiune=pd.gestiune and s1.Cod=pd.cod and s1.nrord between pd.nrordmin and pd.nrordmax
	--	left outer join stocuri sprim on pd.tip='TE' and sprim.Subunitate=pd.Subunitate and 
	--		sprim.Cod_gestiune=pd.Gestiune_primitoare and sprim.cod=pd.cod and sprim.Cod_intrare=s1.Cod_intrare and sprim.Cont=pd.Cont_corespondent and sprim.Pret=pd.Pret_de_stoc
	--		and sprim.pret_cu_amanuntul=pd.Pret_cu_amanuntul
  
				
	insert into pozdoc(Cantitate,TVa_deductibil,Subunitate,Tip,Numar,Cod,Data,Gestiune,Pret_valuta,Pret_de_stoc,Adaos,Pret_vanzare,Pret_cu_amanuntul,Cota_TVA,Utilizator,Data_operarii,Ora_operarii,Cod_intrare,Cont_de_stoc,Cont_corespondent,TVA_neexigibil,Pret_amanunt_predator,Tip_miscare,Locatie,Data_expirarii,Numar_pozitie,Loc_de_munca,Comanda,Barcod,Cont_intermediar,Cont_venituri,Discount,Tert,Factura,Gestiune_primitoare,Numar_DVI,Stare,Grupa,Cont_factura,Valuta,Curs,Data_facturii,Data_scadentei,Procent_vama,Suprataxe_vama,Accize_cumparare,Accize_datorate,Contract,Jurnal)
	select 
		--Pentru verificari s1.nrord,s1.stoctotal,pd.cantitate as c1,pd.cumulat,s1.stoc,pd.nrordmin,pd.nrordmax,
		(case 
			when pd.nrordmin=pd.nrordmax or pd.cantitate<0 
				then pd.cantitate
			when pd.nrordmin=s1.nrord --prima linie de pe stoc
				then pd.cantitate-(pd.cumulat-s1.stoctotal)
			when pd.nrordmax=s1.nrord --ultima linie de pe stoc
				then (pd.cumulat+s1.stoc-s1.stoctotal)
		  else s1.stoc
		end) as cantitate,
		(case 
			when pd.nrordmin=pd.nrordmax or pd.cantitate<0 
				then pd.cantitate
			when pd.nrordmin=s1.nrord --prima linie de pe stoc
				then pd.cantitate-(pd.cumulat-s1.stoctotal)
			when pd.nrordmax=s1.nrord --ultima linie de pe stoc
				then (pd.cumulat+s1.stoc-s1.stoctotal)
		  else s1.stoc
		end)*pd.tvaunit,
		pd.Subunitate,pd.Tip,pd.Numar,pd.Cod,pd.Data,pd.Gestiune,pd.Pret_valuta,s1.Pret as pret_de_stoc,pd.Adaos,pd.Pret_vanzare,pd.Pret_cu_amanuntul,pd.Cota_TVA,pd.Utilizator,pd.Data_operarii,pd.Ora_operarii,
		s1.Cod_intrare,s1.Cont,pd.Cont_corespondent,pd.TVA_neexigibil,
		s1.Pret_cu_amanuntul,pd.Tip_miscare,pd.Locatie,pd.Data_expirarii,
		pd.nrpozmax+ROW_NUMBER() over (order by pd.numar_pozitie),
		pd.Loc_de_munca,pd.Comanda,pd.Barcod,pd.Cont_intermediar,pd.Cont_venituri,pd.Discount,pd.Tert,pd.Factura,pd.Gestiune_primitoare,pd.Numar_DVI,pd.Stare,
		(case when tip='TE' then
			(case when sprim.cod is not null then pd.Grupa 
			else LEFT(newid(),13) --rtrim(s1.cod_intrare)+ltrim(str(row_number() over (partition by pd.cod order by pd.numar_pozitie)))
			end)
		else pd.Grupa end),
		pd.Cont_factura,pd.Valuta,pd.Curs,pd.Data_facturii,pd.Data_scadentei,pd.Procent_vama,pd.Suprataxe_vama,pd.Accize_cumparare,pd.Accize_datorate,pd.Contract,pd.Jurnal
		from #pozd pd
     	inner join #stoctotal s1 on s1.cod_gestiune=pd.gestiune and s1.Cod=pd.cod and s1.nrord between pd.nrordmin and pd.nrordmax
		/*Pentru transferuri mai fac un join */
		left outer join stocuri sprim on pd.tip='TE' and sprim.Subunitate=pd.Subunitate and 
			sprim.Cod_gestiune=pd.Gestiune_primitoare and sprim.cod=pd.cod and sprim.Cod_intrare=pd.Grupa and sprim.Cont=pd.Cont_corespondent and sprim.Pret=pd.Pret_de_stoc
			and sprim.pret_cu_amanuntul=pd.Pret_cu_amanuntul
  
		commit transaction stoc
end try        
begin catch 
	rollback transaction stoc
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
