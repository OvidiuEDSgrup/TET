--***
create procedure rapBorderouFacturi (@sesiune varchar(50)=null, @datajos datetime, @datasus datetime, 
		@datafjos datetime=null,	@datafsus datetime=null, 
		@ordonare int=1,			-->	1=factura, 2=data doc, 3=data factura, 4=loc de munca
		@avize_facturate int=0,	--> avize 1=facturate, 0=nefacturate
		@tipfacturi int=0,		-->	1=Facturi emise pe avize,
								-->	2=Facturi intocmite aferent avizelor,
								-->	3=Avize nefacturate
		@gestiune varchar(20)=null, @loc_de_munca varchar(20)=null, @cont varchar(40)=null,
		@tipDoc varchar(20)=null, -->	AS, AP sau AC
		@jurnal varchar(20)=null,
		@delegat varchar(50)=null,	--> filtru nume delegat
		@tert varchar(100)=null,	--> filtru pe tert
		@facturiAnulate int=0)
as
set transaction isolation level read uncommitted
declare @eroare varchar(500)
set @eroare=''
begin try
	declare @utilizator varchar(50)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	declare @subunitate varchar(20), @rotunjire int
	select @subunitate='1', @rotunjire='2',
			@loc_de_munca=rtrim(@loc_de_munca)+'%',
			@cont=rtrim(@cont)+'%', @tipDoc=(case when @tipDoc='' or @tipDoc='_' then null else @tipDoc end)

	declare @fltLmUt int
	declare @LmUtiliz table(valoare varchar(200))

	insert into @LmUtiliz (valoare)
	select cod from lmfiltrare where utilizator=@utilizator
	set	@fltLmUt=isnull((select count(1) from @LmUtiliz),0)
			
	select @subunitate=(case when parametru='SUBPRO' then val_alfanumerica else @subunitate end),
			@rotunjire=(case when parametru='ROTUNJ' and val_logica=1 then val_numerica else @rotunjire end)
	from par where par.Tip_parametru='GE' and Parametru in ('SUBPRO', 'ROTUNJ')
			
	select p.subunitate, p.gestiune, data, tert, factura, Data_facturii, 
			(case when @ordonare=4 then p.loc_de_munca else ' ' end) as lm, 
			round(convert(decimal(17,5),p.cantitate*p.pret_vanzare),@rotunjire) as valoare, 
			TVA_deductibil as TVA, round(convert(decimal(18,5), 
			p.cantitate * isnull(n.greutate_specifica, 0)), 3) as greutate, 
			(case when @ordonare=4 then p.Loc_de_munca+convert(char(10),data_facturii,102)+factura 
					when @ordonare=3 then convert(char(10),data_facturii,102)+factura 
					when @ordonare=2 then convert(char(10),data,102)+factura 
				else factura+convert(char(10),data_facturii,102) end) as ordonare
	into #date
	from pozdoc p
		left outer join nomencl n on p.cod=n.cod
		left outer join anexaFac a on a.subunitate=p.subunitate and a.numar_factura=p.factura 
	where p.subunitate=@subunitate and (@gestiune is null or p.gestiune like @gestiune)
			and ((@tipDoc is null or p.tip=@tipDoc) and p.tip in ('AC','AP','AS')) 
			and data between @datajos and @datasus
			and (@loc_de_munca is null or p.Loc_de_munca like @loc_de_munca) 
		--	and (:10=0 or p.gestiune like rtrim (':11')+'%')
			and (@avize_facturate=0 or factura<>'') 
			and (@datafjos is null or Data_facturii>=@datafjos) and (@datafsus is null or Data_facturii<=@datafsus)
			and (@cont is null or cont_factura like @cont) and (@jurnal is null or jurnal=@jurnal) 
			and (@delegat is null or isnull(a.numele_delegatului,'')=@delegat) 
			and (@tipfacturi=0 
				or @tipfacturi=1 and not exists (select 1 from doc where doc.subunitate=p.subunitate and doc.tip=p.tip and doc.numar=p.numar and doc.data=p.data and (doc.tip_miscare='8' or left(doc.cont_factura,3)='418')) 
				or @tipfacturi=2 and exists (select 1 from pozadoc where pozadoc.subunitate=p.subunitate and pozadoc.tip='IF' and pozadoc.tert=p.tert and pozadoc.factura_dreapta=p.factura) 
				or @tipfacturi=3 and exists (select 1 from doc where doc.subunitate=p.subunitate and doc.tip=p.tip and doc.numar=p.numar and doc.data=p.data and (doc.tip_miscare='8' or left(doc.cont_factura,3)='418'))
						and not exists (select 1 from pozadoc where pozadoc.subunitate=p.subunitate and pozadoc.tip='IF' and pozadoc.tert=p.tert and pozadoc.factura_dreapta=p.factura)
			) and @facturiAnulate = 0
			and (@tert is null or p.tert like @tert)
			and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=p.Loc_de_munca))
	union all 
	select subunitate, cod_gestiune, data, cod_tert, factura, Data_facturii,
			(case when @ordonare=4 then loc_munca else '' end), 
			 valoare, TVA_22, 0, 
			(case when @ordonare=4 then Loc_munca+convert(char(10),data_facturii,102)+factura 
				when @ordonare=3 then convert(char(10),data_facturii,102)+factura 
				when @ordonare=2 then convert(char(10),data,102)+factura 
				else factura+convert(char(10),data_facturii,102) end)
	from doc 
	where subunitate=@subunitate
		and (1=0 and numar_pozitii=0 or not exists (select 1 from pozdoc p where p.subunitate=doc.subunitate and p.tip=doc.tip and p.numar=doc.numar and p.data=doc.data))
		and (@gestiune is null or cod_gestiune like @gestiune)
		and ((@tipDoc is null or tip=@tipDoc) and tip in ('AC','AP','AS')) 
		and data between @datajos and @datasus and (@loc_de_munca is null or Loc_munca like @loc_de_munca) 
		and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=Loc_munca))
	--	and (:10=0 or cod_gestiune like rtrim (':11')+'%')
		and (@avize_facturate=0 or factura<>'')
		and (@datafjos is null or Data_facturii>=@datafjos) and (@datafsus is null or Data_facturii<=@datafsus)
		and (@cont is null or cont_factura like @cont) and (@jurnal is null or jurnal=@jurnal)
		and (@tert is null or cod_tert like @tert)
		and (@tipfacturi=0 
			or @tipfacturi=1 and doc.tip_miscare<>'8' and left(doc.cont_factura,3)<>'418' and (@facturiAnulate=0 or doc.stare = 1)
			or @tipfacturi=3 and (doc.tip_miscare='8' or left(doc.cont_factura,3)='418')) 
			
	select rtrim(d.Factura) as Factura, max(d.Data) as data, rtrim(d.Tert) as Tert,
			max(rtrim(isnull(t.Denumire,'<Neidentificat>'))) as den_tert, sum(d.valoare) valoare, sum(d.TVA) TVA, 
			max(rtrim(d.lm)) as loc_de_munca, max(rtrim(lm.Denumire)) as den_lm, --max(gestiune),
			sum(d.greutate) greutate, d.data_facturii
	from #date d 
			left join terti t on d.Tert=t.Tert
			left join lm on d.lm=lm.Cod
		group by d.factura, d.tert, d.data_facturii, d.lm
		order by max(ordonare)
	if object_id('tempdb.dbo.#date') is not null drop table #date
end try
begin catch
	set @eroare='rapBoredrouFacturi:'+char(10)+ERROR_MESSAGE()
end catch

if object_id('tempdb.dbo.#date') is not null drop table #date
if len(@eroare)>0 raiserror(@eroare,16,1)
