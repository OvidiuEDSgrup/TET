--/*revert
drop procedure yso_rapBorderouFacturi
go
--***  
create procedure yso_rapBorderouFacturi (--*/declare
@datajos datetime, @datasus datetime,   
  @datafjos datetime=null, @datafsus datetime=null,   
  @ordonare int=1,   --> 1=factura, 2=data doc, 3=data factura, 4=loc de munca  
  @avize_facturate int=0, --> avize 1=facturate, 0=nefacturate  
  @tipfacturi int=0,  --> 1=Facturi emise pe avize,  
        --> 2=Facturi intocmite aferent avizelor,  
        --> 3=Avize nefacturate  
  @gestiune varchar(20)=null, @loc_de_munca varchar(20)=null, @cont varchar(20)=null,  
  @tipDoc varchar(20)=null, --> AS, AP sau AC  
  @jurnal varchar(20)=null,  
  @delegat varchar(50)=null, --> filtru nume delegat  
  @facturiAnulate int=0
 /*
REVERT
execute As login='TET\magazin.AG'
select SUSER_NAME()
select @datajos='2014-04-01 00:00:00',@datasus='2014-04-30 00:00:00',@loc_de_munca=null,@cont=NULL,@datafjos=NULL,@datafsus=NULL,@ordonare=N'1'
	,@avize_facturate=0,@tipfacturi=N'0',@gestiune=null,@tipDoc=null 
 --*/)  as  
set transaction isolation level read uncommitted  
declare @eroare varchar(500)  
set @eroare=''  
begin try  
 declare @subunitate varchar(20), @rotunjire int  --/*SP
		,@CTCLAVRT bit,@ContAvizNefacturat varchar(20)

exec luare_date_par 'GE', 'CTCLAVRT ', @CTCLAVRT  output, 0, @ContAvizNefacturat output

select @subunitate='1', @rotunjire='2',  
   @loc_de_munca=rtrim(@loc_de_munca)+'%',  @gestiune=rtrim(@gestiune)+'%',
   @cont=rtrim(@cont)+'%', @tipDoc=(case when @tipDoc='' or @tipDoc='_' then null else @tipDoc end)  
  
 declare @userASiS varchar(10), @fltLmUt int  
 set @userASiS=dbo.fIaUtilizator(null)  
 declare @LmUtiliz table(valoare varchar(200), cod varchar(20))  
  
 insert into @LmUtiliz (valoare,cod)  
 select valoare, cod_proprietate from fPropUtiliz(null) where cod_proprietate='LOCMUNCA' and valoare<>''  
 set @fltLmUt=isnull((select count(1) from @LmUtiliz),0)  
--/*sp 
	declare @fltGstUt int
	declare @GestUtiliz table(valoare varchar(200), cod varchar(20), analitic371 varchar(20), analitic707 varchar(20))
	insert into @GestUtiliz (valoare,cod, analitic371, analitic707)
	select valoare, cod_proprietate,
			'371'+'.'+rtrim(cod_proprietate)+'%' analitic371, '707'+'.'+rtrim(cod_proprietate)+'%' analitic707 from fPropUtiliz(null) where cod_proprietate='GESTIUNE' and valoare<>''
	set	@fltGstUt=isnull((select count(1) from @GestUtiliz),0)
--sp*/ 
 select @subunitate=(case when parametru='SUBPRO' then val_alfanumerica else @subunitate end),  
   @rotunjire=(case when parametru='ROTUNJ' and val_logica=1 then val_numerica else @rotunjire end)  
 from par where par.Tip_parametru='GE' and Parametru in ('SUBPRO', 'ROTUNJ')  
     
 select p.subunitate, p.gestiune, p.data, p.tert, nr_doc=rtrim(p.Numar)
 , (case when p.Tip in ('AP','AS') and p.Cont_factura =@ContAvizNefacturat then 1 else 0 end ) as aviznefacturat
 , isnull((case p.Tip when 'AP' then pa.Factura_stinga when 'AC' then ab.Factura end), p.factura) as factura
 , isnull((case p.Tip when 'AP' then pa.Data_fact when 'AC' then ab.Data_facturii end), p.Data_facturii) as Data_facturii
 , cont_factura=rtrim(p.Cont_factura)
 , isnull(case p.Tip when 'AP' then pa.Tip when 'AC' then case when ab.Factura is not null then 'BC' else null end else p.tip end, p.tip) as tip
 , convert(varchar(200),space(200)) as explicatii
 , case p.Tip when 'AP' then p.Factura when 'AC' then p.Numar else '' end as nrdocprimar,
   p.loc_de_munca as lm,   
   round(convert(decimal(17,5),p.cantitate*p.pret_vanzare),@rotunjire) as valoare,   
   TVA_deductibil as TVA, round(convert(decimal(18,5),   
   p.cantitate * isnull(n.greutate_specifica, 0)), 3) as greutate,   
   (case when @ordonare=4 then p.Loc_de_munca+convert(char(10),isnull(case p.Tip when 'AP' then pa.Data_fact when 'AC' then ab.Data_facturii else p.Data_facturii end, p.Data_facturii),102)
		+isnull(case p.Tip when 'AP' then pa.Factura_stinga when 'AC' then ab.Factura else p.Factura end, p.factura)
     when @ordonare=3 then convert(char(10),isnull(case p.Tip when 'AP' then pa.Data_fact when 'AC' then ab.Data_facturii else p.Data_facturii end, p.Data_facturii),102)
		+isnull(case p.Tip when 'AP' then pa.Factura_stinga when 'AC' then ab.Factura else p.Factura end, p.factura)
     when @ordonare=2 then convert(char(10),p.data,102)+isnull(case p.Tip when 'AP' then pa.Factura_stinga when 'AC' then ab.Factura else p.Factura end, p.factura)   
    else rtrim(isnull(case p.Tip when 'AP' then pa.Factura_stinga when 'AC' then ab.Factura else p.Factura end, p.factura))
		+convert(char(10),isnull(case p.Tip when 'AP' then pa.Data_fact when 'AC' then ab.Data_facturii else p.Data_facturii end, p.Data_facturii),102) end) as ordonare  
 into #date  
 from pozdoc p  
  left outer join nomencl n on p.cod=n.cod  
  left outer join anexaFac a on a.subunitate=p.subunitate and a.numar_factura=p.factura   
  left outer join antetBonuri b on isnull(nullif(b.bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(50)'),'')
	,left(rtrim(convert(varchar(4),b.Casa_de_marcat))+right(replace(str(b.Numar_bon),' ','0'),4),8))=p.numar
	and b.Data_bon=p.Data and b.Chitanta=1 
  left outer join antetBonuri ab on ab.Chitanta=0 and ab.Factura=b.Factura and ab.Data_facturii=b.Data_facturii
  left outer join par on par.Tip_parametru='GE' and par.Parametru='CTCLAVRT' 
  left outer join pozadoc pa on pa.Subunitate=p.Subunitate and pa.Tip='IF' and pa.Factura_dreapta=p.Factura
 where p.subunitate=@subunitate and p.tip in ('AC','AP','AS')
   --and (not(p.Tip in ('AP','AS') and p.Cont_factura =isnull(par.Val_alfanumerica,'418.0')) or pa.Factura_stinga is not null)
   and (p.tip<>'AC' or ab.Factura is not null)
   and (@gestiune is null or p.gestiune like @gestiune)  
   and ((@tipDoc is null or p.tip=@tipDoc))   
   and p.data between @datajos and @datasus  
   and (@loc_de_munca is null or p.Loc_de_munca like @loc_de_munca)     
   and (@avize_facturate=0 or p.factura<>'')   
   and (@datafjos is null or isnull(case p.Tip when 'AP' then pa.Data_fact when 'AC' then ab.Data_facturii else p.Data_facturii end, p.Data_facturii)>=@datafjos)
   and (@datafsus is null or isnull(case p.Tip when 'AP' then pa.Data_fact when 'AC' then ab.Data_facturii else p.Data_facturii end, p.Data_facturii)<=@datafsus)  
   and (@cont is null or cont_factura like @cont) and (@jurnal is null or p.jurnal=@jurnal)   
   and (@delegat is null or isnull(a.numele_delegatului,'')=@delegat)   
   and (@tipfacturi=0   
    or @tipfacturi=1 and not exists (select 1 from doc where doc.subunitate=p.subunitate and doc.tip=p.tip and doc.numar=p.numar and doc.data=p.data and (doc.tip_miscare='8' or left(doc.cont_factura,3)='418'))   
    or @tipfacturi=2 and exists (select 1 from pozadoc where pozadoc.subunitate=p.subunitate and pozadoc.tip='IF' and pozadoc.tert=p.tert and pozadoc.factura_dreapta=p.factura)   
    or @tipfacturi=3 and exists (select 1 from doc where doc.subunitate=p.subunitate and doc.tip=p.tip and doc.numar=p.numar and doc.data=p.data and (doc.tip_miscare='8' or left(doc.cont_factura,3)='418'))  
      and not exists (select 1 from pozadoc where pozadoc.subunitate=p.subunitate and pozadoc.tip='IF' and pozadoc.tert=p.tert and pozadoc.factura_dreapta=p.factura)  
   ) and @facturiAnulate = 0  
   and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=p.Loc_de_munca))
   and (@fltGstUt=0 or exists(select 1from @GestUtiliz pr where pr.valoare=p.Gestiune)) 
 --union all   
 --select subunitate, cod_gestiune, data, cod_tert, factura, Data_facturii, doc.Cont_factura, doc.Tip, 
 --  (case when @ordonare=4 then loc_munca else '' end),   
 --   valoare, TVA_22, 0,   
 --  (case when @ordonare=4 then Loc_munca+convert(char(10),data_facturii,102)+factura   
 --   when @ordonare=3 then convert(char(10),data_facturii,102)+factura   
 --   when @ordonare=2 then convert(char(10),data,102)+factura   
 --   else factura+convert(char(10),data_facturii,102) end)  
 --from doc   
 --where subunitate=@subunitate  
 -- and (1=0 and numar_pozitii=0 or not exists (select 1 from pozdoc p where p.subunitate=doc.subunitate and p.tip=doc.tip and p.numar=doc.numar and p.data=doc.data))  
 -- and (@gestiune is null or cod_gestiune like @gestiune)  
 -- and ((@tipDoc is null or tip=@tipDoc) and tip in ('AC','AP','AS'))   
 -- and data between @datajos and @datasus and (@loc_de_munca is null or Loc_munca like @loc_de_munca)   
 -- and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=Loc_munca))   
 -- and (@avize_facturate=0 or factura<>'')  
 -- and (@datafjos is null or Data_facturii>=@datafjos) and (@datafsus is null or Data_facturii<=@datafsus)  
 -- and (@cont is null or cont_factura like @cont) and (@jurnal is null or jurnal=@jurnal)  
 -- and (@tipfacturi=0   
 --  or @tipfacturi=1 and doc.tip_miscare<>'8' and left(doc.cont_factura,3)<>'418' and (@facturiAnulate=0 or doc.stare = 1)  
 --  or @tipfacturi=3 and (doc.tip_miscare='8' or left(doc.cont_factura,3)='418'))   
   
--select * from #date d --where d.tip in ('BC') --factura like '9010001%'

 select rtrim(d.Factura) as Factura, max(d.Data) as data, nr_doc=MAX(d.nr_doc)
	, rtrim(d.Tert) as Tert,  
   max(rtrim(isnull(t.Denumire,'<Neidentificat>'))) as den_tert, sum(d.valoare) valoare, sum(d.TVA) TVA,   
   max(rtrim(d.lm)) as loc_de_munca, max(rtrim(lm.Denumire)) as den_lm, --max(gestiune),  
   sum(d.greutate) greutate, d.data_facturii, max(d.Cont_factura) as cont_factura, d.Tip as tip_doc
   ,case d.Tip when 'AP' then (case max(aviznefacturat) when 1 then 'Aviz nefacturat' else 'Aviz facturat' end)
		when 'IF' then 'Intocmire factura aviz nefacturat '/*+isnull(nullif(replace((select distinct RTRIM(e.nrdocprimar) [data()] from #date e 
			where e.Subunitate=d.Subunitate and e.tip=d.tip and e.factura=d.factura and e.Tert=d.Tert 
				and e.Data_facturii=d.Data_facturii and e.lm=d.lm for xml path('')),' ',';'),max(d.nrdocprimar)),'')*/
		when 'BC' then 'Factura chitanta bon casa'--+RTRIM(max(d.nrdocprimar))
		when 'AC' then 'Aviz chitanta' 
		when 'AS' then 'Aviz servicii'
	else d.tip end as explicatii
 from #date d   
   left join terti t on t.Subunitate=d.Subunitate and d.Tert=t.Tert  
   left join lm on d.lm=lm.Cod  
  group by d.Subunitate, d.tert, d.factura, d.data_facturii, d.tip, d.nr_doc, d.Data--, d.lm  
  order by max(ordonare)  
 if object_id('tempdb.dbo.#date') is not null drop table #date  
end try  
begin catch  
 set @eroare='rapBoredrouFacturi:'+char(10)+ERROR_MESSAGE()  
end catch  
  
if object_id('tempdb.dbo.#date') is not null drop table #date  
if len(@eroare)>0 raiserror(@eroare,16,1)
GO
/*


declare @datajos datetime,@datasus datetime,@locm nvarchar(6),@cont nvarchar(4000),@datafjos nvarchar(4000),@datafsus nvarchar(4000),@ordonare nvarchar(1),@avize_facturate bit,@tipfacturi nvarchar(1),@gestiune nvarchar(4000),@tipDoc nvarchar(2)
select @datajos='2013-07-01 00:00:00',@datasus='2013-07-31 00:00:00',@locm=null,@cont=NULL,@datafjos=NULL,@datafsus=NULL,@ordonare=N'1',@avize_facturate=0,@tipfacturi=N'0',@gestiune=null,@tipDoc=null

exec yso_rapBorderouFacturi @datajos=@datajos, @datasus=@datasus,
		@datafjos=@datafjos,	@datafsus=@datafsus ,
		@ordonare=@ordonare,
		@avize_facturate=@avize_facturate,
		@tipfacturi=@tipfacturi,
		@gestiune=@gestiune,
		@loc_de_munca=@locm, @cont=@cont,
		@tipDoc=@tipDoc 
		--,@jurnal=@jurnal,
		--@delegat=@delegat,
		--@facturiAnulate=@facturiAnulate
*/