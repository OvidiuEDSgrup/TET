--***
create procedure rapExtrasFacturiPeSold(@sesiune varchar(50)=null, @data datetime, @datajos datetime=null, @datasus datetime=null
		,@facturiLaZi int=0	-->	1=Facturi la zi(din facturi), 0=documente(~ din fFacturi)
		,@FurnBenef varchar(1)		--> 'F'=furnizori, 'B'=beneficiari
		,@validareResponsabilCaMarca int=0
		--> filtre:
		,@tert varchar(20)=null
		,@soldjos decimal(20,3)=null, @soldsus decimal(20,3)=null	-->	sold facturi
		,@valuta varchar(10)=null
		,@cont varchar(40)=null			--> cont de tert
		,@grupa varchar(20)=null			--> grupa tert
		,@locm varchar(20)=null, @responsabil varchar(30)=null
		,@efecteAchitate varchar(20)=0
		,@cont_efecte varchar(40)=null	--> temporar se pastreaza, pt o mica tranzitie; va disparea, parametrul real este @efecteAchitate
		,@tipdoc varchar(1)='F'		--> 'F','E','X' -> facturi, efecte, toate; null='X'
		-->	web:
		,@datascadJos datetime=null
		,@datascadSus datetime=null
		,@GrContFact int=0
		,@filtruSoldAbs int=0
		,@existaDate bit=0 output
		)
as
begin
--/*	declare @efecteAchitate bit
	select @efecteAchitate=(case when @cont_efecte is null then @efecteAchitate else 1 end)
	set transaction isolation level read uncommitted
	select @tipdoc=isnull(@tipdoc,'F')
/*	if (@tipdoc<>'F' and @efecteAchitate=1)
	begin
		raiserror('Nu e permis tip documente diferit de "Facturi" daca e completat contul de efecte!',16,1)
		return
	end*/
	select @tert=rtrim(@tert), @valuta=rtrim(@valuta) , @cont=rtrim(@cont)
		,@grupa=rtrim(@grupa), @locm=rtrim(@locm), @responsabil=rtrim(@responsabil)
		
	declare @subunitate varchar(20), @tipFurnBenef_x binary(1), @lungValidareResponsabil int, @tipEfect varchar(1), @filtruContEfecte bit,
			@locterti bit, @judterti bit, @parXML xml, @parXMLFact xml
	select @locterti=isnull((select p.val_logica from par p where tip_parametru='GE' and parametru='LOCTERTI'),0),
			@judterti=isnull((select p.val_logica from par p where tip_parametru='GE' and parametru='JUDTERTI'),0),
			@parXML=(select @sesiune as sesiune for xml raw)
	select @subunitate=rtrim(Val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'
	select	@tipFurnBenef_x=(case when @FurnBenef='F' then 0x54 else 0x46 end)
			,@soldjos=isnull(@soldjos,-10000000000000), @soldsus=isnull(@soldsus,10000000000000)
			,@cont=rtrim(@cont)
			,@lungValidareResponsabil=(case when @validareResponsabilCaMarca=1 then 6 else 30 end)
			--,@cont_efecte=rtrim(@cont_efecte)+'%'
			,@tipEfect=(case when @FurnBenef='B' then 'I' else 'P' end)
			,@datajos=isnull(@datajos,'1901-1-1')
			,@datasus=isnull(@datasus,'2999-1-1')
			,@datascadJos=isnull(@datascadJos,'1901-1-1')
			,@datascadSus=isnull(@datascadSus,'2999-1-1')
			--,@filtruContEfecte=(case when @cont_efecte is null or rtrim(replace(@cont_efecte,'%',''))='' then 0 else 1 end)
	if object_id('tempdb..#extras') is not null drop table #extras
	if object_id('tempdb..#efecte') is not null drop table #efecte
	if object_id('tempdb..#tot_efecte') is not null drop table #tot_efecte
	if object_id('tempdb..#solduri') is not null drop table #solduri
	
	create table #extras(subunitate varchar(10), tert varchar(20), FurnBenef varchar(1), factura varchar(40), data datetime,
							sold decimal(20,5), tva_din_sold decimal(20,5), valuta varchar(20), cont_de_tert varchar(40), tipdoc varchar(1),
							explicatii varchar(200))
	
	insert into #extras(subunitate, tert,FurnBenef, factura, data, sold, tva_din_sold, valuta, cont_de_tert, tipdoc, explicatii)
	select subunitate, tert, @FurnBenef as FurnBenef, factura, data, 
		sold, 
		(case when abs(valoare+tva_11+tva_22)>=0.01 then sold*(tva_11+tva_22)/(valoare+tva_11+tva_22) else 0 end) as tva_din_sold,
		valuta, cont_de_tert, '' as tipdoc, '' explicatii
	from facturi a
	where @facturiLaZi=1
		and subunitate=@subunitate
		and (@tert is null or a.tert=@tert) and tip=@tipFurnBenef_x
		and data between @datajos and @datasus
		and round(convert(decimal(17,5), sold), 2) between @soldjos and @soldsus
		and (@valuta is null or valuta=@valuta) and cont_de_tert like @cont+'%'
		and (@grupa is null or exists (select 1 from terti t where t.tert=a.tert and t.grupa=@grupa))
		and (@locm is null or a.loc_de_munca like rtrim(@locm)+'%')
		and (@responsabil is null or 
			exists (select 1 from infotert it where it.subunitate=a.subunitate and it.tert=a.tert
						and it.identificator='' and it.descriere=@responsabil))
		and (@responsabil is null or 
			exists (select 1 from infotert it where it.subunitate=a.subunitate and it.tert=a.tert and it.identificator='' 
						and RTrim(left(it.descriere, @lungValidareResponsabil))=RTrim(@responsabil)))
	declare @p xml
	select @p=(select @efecteAchitate as efecteachitate for xml raw)
	if (@tipdoc<>'E')
	begin
		/* se preiau datele in tabela #pfacturi prin procedura pFacturi (in locul functiei fFacturiCen) */
		if object_id('tempdb..#pfacturi') is not null 
			drop table #pfacturi
		create table #pfacturi (subunitate varchar(9))
		exec CreazaDiezFacturi @numeTabela='#pfacturi'
		set @parXMLFact=(select @FurnBenef as furnbenef, null as datajos, @data as datasus, 1 as cen, rtrim(@tert) as tert, rtrim(@cont) as contfactura, 
			1 as grtert, 1 as grfactura, @efecteAchitate as efecteachitate for xml raw)
		exec pFacturi @sesiune=null, @parXML=@parXMLFact

		insert into #extras(subunitate, tert,FurnBenef, factura, data, sold, tva_din_sold, valuta, cont_de_tert, tipdoc, explicatii)
		select subunitate, tert, @FurnBenef, factura, max(data), 
		sum(round(convert(decimal(17,5), sold), 2)) as sold, 
		(case when abs(sum(valoare+tva))>=0.01 then sum(sold)*sum(tva)/sum(valoare+tva) else 0 end) as tva_din_sold,
		max(valuta), max(cont_factura), 'F' tipdoc, max(a.explicatii)
		from #pfacturi a
		--from dbo.fFacturiCen(@FurnBenef, '01/01/1901', @data, @tert, null, 1, 1, @cont, 0, 0, @p) a
		where @facturiLaZi=0
			and (@grupa is null or exists (select 1 from terti t where t.tert=a.tert and t.grupa=@grupa))
			and (@locm is null or a.loc_de_munca like rtrim(@locm)+'%')
			and (@responsabil is null or 
					exists (select 1 from infotert it where it.subunitate=a.subunitate and it.tert=a.tert and it.identificator=''
						and RTrim(left(it.descriere, @lungValidareResponsabil))=RTrim(@responsabil)))
		group by subunitate, tert, factura
		order by 1,2,5,6
	end

	create table #efecte (subunitate varchar(10), tert varchar(20), tip_efect varchar(2), factura varchar(30),
		data datetime, valoare decimal(20,5), achitat decimal(20,5), valuta varchar(10), cont varchar(40), loc_de_munca varchar(20),
		explicatii varchar(200), numar_document varchar(100), efect varchar(100))
	declare @tipef varchar(1)	select @tipef=(case when @FurnBenef='F' then 'P' else 'I' end)

	if (@tipdoc<>'F')
	begin
		insert into #efecte(subunitate, tert, tip_efect, factura, data, valoare, achitat,valuta, cont, loc_de_munca, explicatii, numar_document, efect)
		select a.subunitate, a.tert, a.tip_efect, factura, data, valoare, achitat,valuta, cont, loc_de_munca, a.explicatii, numar_document, efect
			from
			dbo.fEfecte('01/01/1901', @data,@tipef,@tert,null,@cont,'','', @parXML) a
		where @facturiLaZi=0

	--> se calculeaza ponderat soldul fiecarei facturi din cadrul efectelor:
		select sum(achitat) tot_achitat, sum(valoare) tot_valoare, e.tert, e.efect into #tot_efecte
		from #efecte e group by efect, tert
		having sum(valoare)>0
		
		update e set valoare=valoare-valoare*tot_achitat/tot_valoare
		from #efecte e inner join #tot_efecte t on e.efect=t.efect and e.tert=t.tert
		where e.factura<>''
/*
		-->	completare achitari efecte cu numarul facturii:
		update e set factura=e1.factura
		from #efecte e cross apply (select max(factura) factura from #efecte e1
			where e1.subunitate=e.subunitate and e1.tert=e.tert and e1.tip_efect=e.tip_efect and e1.numar_document=e.numar_document and e1.efect=e.efect and factura is not null) e1
		where isnull(e.factura,'')=''
--*/		

		insert into #extras(subunitate, tert,FurnBenef, factura, data, sold, tva_din_sold, valuta, cont_de_tert, tipdoc, explicatii)
		select subunitate, tert, max(case when a.tip_efect='P' then 'F' else 'B' end) FurnBenef, max(factura) factura,
				max(data), sum(a.valoare) sold, 0 tva_din_sold, max(valuta), max(a.cont) cont_de_tert, 'E' tipdoc, max(explicatii)
			from #efecte a
		where @facturiLaZi=0
			and a.factura<>''
			and (@grupa is null or exists (select 1 from terti t where t.tert=a.tert and t.grupa=@grupa))
			and (@locm is null or a.loc_de_munca like rtrim(@locm)+'%')
			and (@responsabil is null or 
					exists (select 1 from infotert it where it.subunitate=a.subunitate and it.tert=a.tert and it.identificator=''
						and RTrim(left(it.descriere, @lungValidareResponsabil))=RTrim(@responsabil)))
			--> se iau doar acele facturi ale caror efecte nu au fost achitate:
			and	abs(a.valoare)>0.0001
		group by subunitate, tert, factura
		order by 1,2,5,6
	end


	if (@facturiLaZi=1)
		select e.subunitate, e.tert, e.FurnBenef, e.factura, e.data, e.Sold as sold, 
					e.tva_din_sold, e.valuta, e.cont_de_tert, explicatii
				from #extras e
	else begin
-------->	determinarea facturilor achitate prin efecte:
/*			create table #fltContEfecte(tert varchar(20), factura varchar(20), sold decimal(20,5))
			if (@filtruContEfecte=1)
			begin
				insert into #fltContEfecte(tert, factura, sold)
				select p.tert, p.factura, sum(p.valoare+p.tva)-
					sum(case when 'B'='B' and 1=1 and p.fel='3' and p.cont_coresp like '413%' and
					(abs(e.sold)>0.0001 or isnull(e.Valoare,0)=0) then 0
					else p.achitat end)
				from 
					dbo.fFacturi (@FurnBenef, '1921-1-1', @data, @tert, '%', @cont, 0, 0, 0, '', @parXML) p
					left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
					left outer join infotert i on p.subunitate=i.subunitate and p.tert=i.tert and i.identificator='' 
					left outer join facturi f on p.subunitate=f.subunitate and p.tert=f.tert and p.factura=f.factura and f.tip=(case when @furnbenef='F' then 0x54 else 0x46 end)
					left outer join efecte e on 
					@furnbenef='B' and 
						p.fel='3' and rtrim(p.cont_coresp) like @cont_efecte and e.subunitate=p.subunitate and e.tert=p.tert and e.tip='I'
						and e.nr_efect=(case when charindex('|', p.numar)>0 then RTRim(substring(p.numar, charindex('|', p.numar) + 1, 20)) else p.numar end)
						and e.data_decontarii<=@data				--> aici trebuie sa fie in functie de limitele pe solduri sau pur si simplu sa fie abs<=0.01 ?:
					where isnull(t.grupa, '') between '' and 'zzz' and isnull(i.descriere,'') between '' and 'zzzzz' and isnull(f.loc_de_munca,'') like rtrim('')+'%' 
				group by p.tert, p.factura

				delete f from #fltContEfecte f where abs(f.sold)<0.01
			end
			*/
			select e.subunitate, e.tert, e.FurnBenef, e.factura, e.data, e.sold/*+isnull(ef.sold,0)*/ as sold
					,e.tva_din_sold, e.valuta, e.cont_de_tert
					-->	pt raport web:
					/*,e.data*/, e.explicatii as explicatii, t.denumire, t.cod_fiscal, 
					(case when @locterti=0 then t.localitate else l.oras end) localitate,
					(case when @judterti=0 then t.Judet else j.denumire end) judet
					,t.adresa, t.telefon_fax, t.banca, t.cont_in_banca
					,(case when @GrContFact=1 then e.cont_de_tert else '' end) as cont_factura
					,abs(round(convert(decimal(17,5), e.sold/*+isnull(ef.sold,0)*/), 2)) as abs_sold, e.tipdoc
				from #extras e
					left outer join terti t on e.tert=t.tert and e.subunitate=t.subunitate
					left outer join facturi f on e.subunitate=f.subunitate and e.tert=f.tert and e.factura=f.factura and f.tip=@tipFurnBenef_x
						and e.tipdoc='F'
					--left join #fltContEfecte ef on @filtruContEfecte=1 and ef.tert=f.tert and ef.factura=f.factura
					left join localitati l on t.localitate=l.cod_oras and t.Judet=l.cod_judet
					left join judete j on t.Judet=j.cod_judet
				where (@filtruSoldAbs=0 and round(convert(decimal(17,5), e.sold), 2) between @soldjos and @soldsus
						or @filtruSoldAbs=1 and abs(round(convert(decimal(17,5), e.sold), 2)) between @soldjos and @soldsus
						--or ef.tert is not null
						)
						and (f.data is null or f.data between @datajos and @datasus)
						and (f.data_scadentei is null or f.data_scadentei between @datascadJos and @datascadSus)
			order by e.subunitate, e.tert, e.data, e.sold
		end

	if @@ROWCOUNT>0
		set @existaDate = 1
	if object_id('tempdb..#extras') is not null drop table #extras
	if object_id('tempdb..#efecte') is not null drop table #efecte
	if object_id('tempdb..#tot_efecte') is not null drop table #tot_efecte
	if object_id('tempdb..#solduri') is not null drop table #solduri
end
