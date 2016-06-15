--***
create function fFurn(@Sb char(9),@IstFactImpl int,@DataJ datetime,@DataS datetime,@Tert char(13),@Fact char(20),@cCt char(13),
		@Ignor4428Avans int,@4428DocFF int,@DVI int,@AccImpDVI int,@CtFactVamaDVI int,@FactBil int,@DataJMF datetime, @locm varchar(20))
returns @docfurn table
(subunitate char(9),tert char(13),factura char(20),tip char(2),numar char(20),data datetime,valoare float,tva float,achitat float,valuta char(3),curs float,total_valuta float,achitat_valuta float,loc_de_munca char(13),comanda char(40),cont_de_tert char(20),fel int,cont_coresp char(20),explicatii char(50),numar_pozitie int,gestiune char(13),data_facturii datetime,data_scadentei datetime,nr_dvi char(13),barcod char(30), contTVA char(13), cod char(20), cantitate float, contract char(20))
begin

set @locm=ISNULL(@locm,'')+'%'
declare @LFact int
set @LFact=isnull((select c.length from sysobjects o, syscolumns c where o.name='facturi' and o.id=c.id and c.name='factura'), 0)

declare @userASiS varchar(10), @lista_gestiuni bit, @fltLmUt int
set @userASiS=dbo.fIaUtilizator(null)
declare @LmUtiliz table(valoare varchar(200))

if @userASiS=''
	set @fltLmUt=0
else
begin
	insert into @LmUtiliz (valoare)
	select l.cod from lmfiltrare l where utilizator=@userASiS

	set	@fltLmUt=isnull((select count(1) from @LmUtiliz),0)
end

insert @docfurn
select i.subunitate,i.tert,i.factura,'SI',i.factura,i.data,i.valoare,i.tva_11+i.tva_22,i.achitat,i.valuta,i.curs,i.valoare_valuta,
		i.achitat_valuta,i.loc_de_munca,i.comanda,i.cont_de_tert,'1','','Sold initial',0,'',i.data,i.data_scadentei,'','','' as contTVA,
		'' as cod,0 as cantitate, '' as contract
from istfact i 
left outer join terti t on i.subunitate=t.subunitate and i.tert=t.tert
where @IstFactImpl=1 and i.subunitate=@Sb and i.tip='F' and i.data_an=@DataJ and i.tert like rtrim(@Tert) and i.factura like rtrim(@Fact) and i.cont_de_tert like rtrim(@cct)+'%'
		and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=i.loc_de_munca))
		and (@locm='%' or i.Loc_de_munca like @locm)
union all
select fi.subunitate,fi.tert,fi.factura,'SI',fi.factura,fi.data,fi.valoare,fi.tva_11+fi.tva_22,fi.achitat,fi.valuta,fi.curs,fi.valoare_valuta,
		fi.achitat_valuta,fi.loc_de_munca,fi.comanda,fi.cont_de_tert,'1','','Sold initial',0,'',fi.data,fi.data_scadentei,'','','' as contTVA,
		'' as cod,0 as cantitate, '' as contract
from factimpl fi 
left outer join terti t on fi.subunitate=t.subunitate and fi.tert=t.tert
where @IstFactImpl=2 and fi.subunitate=@Sb and fi.tip=0x54 and fi.tert like rtrim(@Tert) and fi.factura like rtrim(@Fact) and fi.cont_de_tert like rtrim(@cct)+'%'
	and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=fi.loc_de_munca))
	and (@locm='%' or fi.Loc_de_munca like @locm)
union all
select p.subunitate,p.tert,p.factura,p.tip,p.numar,p.data,
	(case when p.valuta='' then round(convert(decimal(18,5),cantitate*round(pret_valuta*(1+
		(case when abs(p.discount+p.cota_TVA*100.00/(p.cota_TVA+100.00))<0.01 then convert(decimal(12,4),-p.cota_TVA*100.00/(p.cota_TVA+100.00)) 
		else convert(decimal(12,4),p.discount) end)/100),5)),2) when p.tip='RP' then pret_valuta else 
		round(convert(decimal(18,5),cantitate*round(convert(decimal(18,5),pret_valuta*p.curs*(case when numar_dvi='' or p.tip='RS' then 
		(1+convert(decimal(18,5),discount/100)) else 1 end)),5)),2) end),
	(case when not ((numar_DVI<>'' and p.tip='RM') or 
		((numar_DVI='' and p.tip='RM' or p.tip in ('RP','RS')) and procent_vama = 1)) then tva_deductibil else 0 end),
	0,p.valuta,p.curs,(case when p.valuta<>'' and isnull(t.tert_extern,0)=1 then round(
						convert(decimal(18,5),cantitate*
							(case when p.tip='RP' then pret_de_stoc else pret_valuta end)*
							(1+(case when p.tip='RS' or p.numar_DVI='' then discount else 0 end)/100)+
							(case	when /*cota_tva in (9,11,19,22) and*/ not ((numar_DVI<>'' and p.tip='RM') or 
										((numar_DVI='' and p.tip='RM' or p.tip in ('RP','RS')) and procent_vama = 1)) and p.curs > 0 
									then (case	when 1=0 and p.tip='RP' then round(convert(decimal(18,5),p.pret_de_stoc*p.cota_TVA/100),2) 
										when isnumeric(p.grupa)=1 then convert(float,p.grupa) else 0 end) else 0 end)),2) else 0 end),
	0,p.loc_de_munca,p.comanda,p.cont_factura,'2',p.cont_de_stoc,left(isnull(mfix.denumire, isnull(n.denumire,'Intrari')),50),p.numar_pozitie,
	p.gestiune,p.data_facturii,p.data_scadentei,(case when p.tip='RM' and p.valuta<>'' and p.numar_DVI<>'' then left(p.numar_DVI,13) else '' end),'',
	p.Cont_venituri as contTVA, p.Cod as cod, p.Cantitate as cantitate, (case when p.Tip in ('RM','RS') then p.Contract else '' end)
from pozdoc p 
left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
left outer join nomencl n on n.cod=p.cod
left outer join mfix on isnull(n.tip, '')='F' and mfix.subunitate=p.subunitate and mfix.numar_de_inventar=p.cod_intrare
where p.data between @DataJ and @DataS and p.subunitate=@Sb and p.tip in ('RM','RP','RQ','RS') and 
	(@FactBil=1 or p.cont_factura<>'' or left(p.cont_de_stoc,1)<>'8') and p.tert like rtrim(@Tert) and p.factura like rtrim(@Fact) and 
	p.cont_factura like rtrim(@cct)+'%'
	and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=p.loc_de_munca))
	and (@locm='%' or p.Loc_de_munca like @locm)

union all
select p.subunitate,p.tert,p.factura,p.plata_incasare,p.numar,p.data,0,0,
		(case when p.plata_incasare in ('PS','IS') then-1 else 1 end)*(p.suma-p.suma_dif)
						-(case when p.plata_incasare='PF' and @Ignor4428Avans=0 and left(p.Cont_corespondent,3) like '409%' then p.TVA22 else 0 end),
		p.valuta,p.curs,0,
		(case when p.valuta='' or isnull(t.tert_extern,0)=0 then 0 when plata_incasare in ('PS','IS') then-1 else 1 end)*p.achit_fact,
		p.loc_de_munca,p.comanda,p.cont_corespondent,'3',p.cont,p.explicatii,p.numar_pozitie,left(p.comanda,9),p.data,p.data,'','','' as contTVA,
		'' as cod,0 as cantitate, '' contract
from pozplin p 
left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
where p.subunitate=@Sb and p.plata_incasare in ('PF','PR','IS') and p.data between @DataJ and @DataS and p.tert like rtrim(@Tert) and p.factura like rtrim(@Fact) and p.cont_corespondent like rtrim(@cct)+'%'
	and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=p.loc_de_munca))
	and (@locm='%' or p.Loc_de_munca like @locm)
union all 
select p.subunitate,p.tert,p.factura_stinga,(case when p.tip='SF' then 'SX' when p.tip='CF' then 'FX' else p.tip end),p.numar_document,p.data,
		0,0,suma+(case when (1=1 or p.tip<>'C3') then (case when cont_dif like '6%' or cont_dif like '308%' then -suma_dif else suma_dif end) 
					else 0 end)+(case when p.tip='SF' and p.stare<>1 then tva22-dif_tva else 0 end),p.valuta,p.curs,0,
		(case when p.valuta<>'' and isnull(t.tert_extern,0)=1 then achit_fact+
			(case	when p.tip='SF' and p.stare<>1 and isnumeric(p.tert_beneficiar)=1 and p.TVA22<>0 
					then convert(float,p.tert_beneficiar)*(1.00-p.dif_TVA/p.TVA22) else 0 end) else 0 end),
		p.loc_munca,p.comanda,p.cont_deb,'4',p.cont_cred,p.explicatii,p.numar_pozitie,'',p.data_fact,p.data_scad,'','','' as contTVA,
		'' as cod,0 as cantitate, '' contract
from pozadoc p 
left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
where p.subunitate=@Sb and p.tip in ('SF','CO','CF','C3') and p.data between @DataJ and @DataS and p.tert like rtrim(@Tert) and p.factura_stinga like rtrim(@Fact) and p.cont_deb like rtrim(@cct)+'%'
	and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=p.loc_munca))
	and (@locm='%' or p.Loc_munca like @locm)
union all
select p.subunitate,p.tert,p.factura_dreapta,p.tip,p.numar_document,p.data,
		(case when p.tip='CF' then 0 else suma+
			(case when 1=0 and p.tip='SF' and (cont_dif like '6%' or cont_dif like '308%') then suma_dif else 0 end) end),
		(case when p.tip='CF' or p.stare=1 then 0 else tva22 end),
		(case when p.tip='CF' then -suma+(case when @Ignor4428Avans=0 and left(p.Cont_cred,3) like '409%' then p.TVA22 else 0 end) else 0 end),p.valuta,p.curs,
		(case when p.valuta='' or isnull(t.tert_extern,0)=0 then 0 when p.tip='CF' then 0 else suma_valuta+
			(case	when p.tip='FF' and p.stare<>1 then dif_tva 
					when p.tip='SF' and p.stare<>1 and isnumeric(p.tert_beneficiar)=1 then convert(float,p.tert_beneficiar) else 0 end) end),
		(case when p.valuta='' or isnull(t.tert_extern,0)=0 then 0 when p.tip='CF' then -suma_valuta else 0 end),p.loc_munca,p.comanda,
		p.cont_cred,'4',p.cont_deb,p.explicatii,p.numar_pozitie,'',p.data_fact,p.data_scad,'','',p.Tert_beneficiar as contTVA,
		'' as cod,0 as cantitate, '' as contract
from pozadoc p 
left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
where p.subunitate=@Sb and p.tip in ('SF','FF','CF') and p.data between @DataJ and @DataS and p.tert like rtrim(@Tert) and p.factura_dreapta like rtrim(@Fact) and p.cont_cred like rtrim(@cct)+'%'
	and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=p.loc_munca))
	and (@locm='%' or p.Loc_munca like @locm)
union all
select p.subunitate,p.tert,(case when cod_intrare='' then 'AVANS' else left(cod_intrare,@LFact) end),'RX',p.numar,p.data,0,0,
		round(convert(decimal(18,5),cantitate*round(convert(decimal(18,5),pret_valuta*(case when p.valuta<>'' then p.curs else 1 end)),5)),2)+
			round(convert(decimal(18,5),(case when @Ignor4428Avans=0 and left(p.Cont_de_stoc,3) in ('409','451') or @4428DocFF=0 and left(p.Cont_de_stoc,3) in ('408','167') then 0 else 1 end)
				*(case when (numar_DVI<>'' and p.tip='RM') or ((numar_DVI='' and p.tip='RM' or p.tip in ('RP','RS')) and procent_vama=1) then 0 else 1 end)*p.tva_deductibil),2), p.valuta,p.curs,0,
		(case when p.valuta<>'' and p.curs>0 
				then	round(convert(decimal(18,5),cantitate*round(convert(decimal(18,5),pret_valuta),5)),2)*(1+discount/100)+
						round(convert(decimal(18,5),(case when @Ignor4428Avans=0 and left(p.Cont_de_stoc,3) in ('409','451') or @4428DocFF=0 and left(p.Cont_de_stoc,3) in ('408','167') then 0 else 1 end)
							*(case when (numar_DVI<>'' and p.tip='RM') or ((numar_DVI='' and p.tip='RM' or p.tip in ('RP','RS')) and procent_vama=1) then 0 else 1 end)
								*p.tva_deductibil/p.curs),2) else 0 end),
		p.loc_de_munca,p.comanda,cont_de_stoc,'4',cont_factura,left(isnull(n.denumire,''),50),numar_pozitie,'',p.data_facturii,
		p.data_scadentei,'','',p.Cont_venituri as contTVA, p.cod as cod, p.Cantitate as cantitate,
		(case when p.Tip in ('RM','RS') then p.Contract else '' end)
from pozdoc p 
inner join conturi c on c.subunitate=p.subunitate and c.cont=p.cont_de_stoc and c.sold_credit=1
left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
left outer join nomencl n on n.cod=p.cod
where p.subunitate=@Sb and p.tip in ('RM','RS') and p.data between @DataJ and @DataS and p.tert like rtrim(@Tert) and (case when cod_intrare='' then 'AVANS' else left(cod_intrare,20) end) like rtrim(@Fact) and cont_de_stoc like rtrim(@cCt)+'%'
	and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=p.loc_de_munca))
	and (@locm='%' or p.Loc_de_munca like @locm)
union all
select	m.subunitate,m.tert,m.factura,'M'+left(m.tip_miscare,1),m.numar_document,m.data_miscarii,
		(case when tip_miscare='MFF' then diferenta_de_valoare else pret end),m.tva,0,left(m.gestiune_primitoare,3),0,
		(case when tip_miscare='IAF' and gestiune_primitoare<>'' and isnull(t.tert_extern,0)=1 then diferenta_de_valoare else 0 end),0,
		m.loc_de_munca_primitor,'',m.cont_corespondent,'2',isnull(
			(select max(cont_mijloc_fix) from fisamf where subunitate=@Sb and numar_de_inventar=m.numar_de_inventar and felul_operatiei='3'),
			'212'),	'Miscare MF',0,'',m.data_miscarii,m.data_miscarii,'','','' as contTVA, m.Numar_de_inventar as cod,0 as cantitate,
			'' as contract
from mismf m 
left outer join terti t on m.subunitate=t.subunitate and m.tert=t.tert 
where m.procent_inchiriere not in (1,6,9) and m.subunitate=@Sb and m.tip_miscare in ('IAF','MFF') and m.data_miscarii between @DataJMF and @DataS and m.tert like rtrim(@Tert) and m.factura like rtrim(@Fact) and m.cont_corespondent like rtrim(@cct)+'%'
	and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=m.loc_de_munca_primitor))
	and (@locm='%' or m.Loc_de_munca_primitor like @locm)

if @DVI=1
	insert @docfurn
	select f.*, '' as contTVA,'' as cod,0 as cantitate,'' contract from dbo.fFurnDVI(@Sb,@DataJ,@DataS,@Tert,@Fact,@cCt,@AccImpDVI,@CtFactVamaDVI, @locm) f
return
end
