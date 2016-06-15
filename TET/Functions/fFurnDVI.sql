--***
create function  fFurnDVI(@Sb char(9),@DataJ datetime,@DataS datetime,@Tert char(13),@Fact char(20),@cCt char(13),@AccImpDVI int,@CtFactVama int, @locm varchar(20))
returns @docfurndvi table
(subunitate char(9),tert char(13),factura char(20),tip char(2),numar char(20),data datetime,valoare float,tva float,achitat float,valuta char(3),curs float,total_valuta float,achitat_valuta float,loc_de_munca char(13),comanda char(40),cont_de_tert char(20),fel int,cont_coresp char(20),explicatii char(50),numar_pozitie int,gestiune char(13),data_facturii datetime,data_scadentei datetime,nr_dvi char(13),barcod char(30))
begin

declare @userASiS varchar(10), @lista_gestiuni bit, @fltLmUt int
set @userASiS= dbo.fIaUtilizator(null)
declare @LmUtiliz table(valoare varchar(200), cod varchar(20))

set @locm=ISNULL(@locm,'')+'%'
insert into @LmUtiliz (valoare)
select cod from lmfiltrare where utilizator=@userASiS

select	@fltLmUt=isnull((select count(1) from @LmUtiliz),0)

insert @docfurndvi
select a.subunitate,b.tert_cif,b.factura_cif,a.tip,a.numar,a.data,b.valoare_cif_lei,b.tva_cif,0,b.valuta_cif,b.curs,(case when b.valuta_cif='' then 0 else b.valoare_cif end),0,a.loc_munca,a.comanda,b.cont_cif,'2','','CIF',0,a.cod_gestiune,b.data_cif,b.data_comis,a.numar_DVI,''
from doc a 
inner join dvi b on a.subunitate=b.subunitate and a.numar=b.numar_receptie and a.data=b.data_dvi
where a.subunitate=@Sb and a.tip='RM' and a.data between @DataJ and @DataS and b.tert_cif<>'' and b.tert_cif like rtrim(@Tert) and b.factura_cif like rtrim(@Fact) and b.cont_cif like rtrim(@cCt)+'%'
and (b.valoare_cif_lei<>0 or b.tva_cif<>0)
	and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=a.loc_munca))
	and (@locm='%' or a.Loc_munca like @locm)
union all
select a.subunitate,b.tert_vama,b.factura_vama,a.tip,a.numar,b.data_DVI,b.suma_vama+b.suma_suprataxe+b.dif_vama+(case when @AccImpDVI=1 then b.valoare_accize+b.tva_11 else 0 end)+(case when @CtFactVama=1 then b.suma_com_vam+b.dif_com_vam else 0 end),(case when @CtFactVama=1 and b.total_vama<>1 then b.tva_22 else 0 end),0,'',0,0,0,a.loc_munca,a.comanda,(case when @CtFactVama=0 or b.cont_tert_vama='' then b.cont_vama else b.cont_tert_vama end),'2','','taxe vamale',0,a.cod_gestiune,b.data_receptiei,convert(datetime,b.tert_comis,103),a.numar_DVI,''
from doc a 
inner join dvi b on a.subunitate=b.subunitate and a.numar=b.numar_receptie and a.data=b.data_dvi 
where a.subunitate=@Sb and a.tip='RM' and b.data_DVI between @DataJ and @DataS and b.tert_vama like rtrim(@Tert) and b.factura_vama like rtrim(@Fact) and (case when @CtFactVama=0 or b.cont_tert_vama='' then b.cont_vama else b.cont_tert_vama end) like rtrim(@cCt)+'%' and b.factura_comis in ('','D') 
	and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=a.loc_munca))
	and (@locm='%' or a.Loc_munca like @locm)
union all
select a.subunitate,b.tert_vama,left(b.cont_tert_vama,8),a.tip,a.numar,b.data_DVI,b.suma_com_vam+b.dif_com_vam,0,0,'',0,0,0,a.loc_munca,a.comanda,b.cont_com_vam,'2','','comision vamal',0,a.cod_gestiune,b.data_receptiei,convert(datetime,b.tert_comis,103),a.numar_DVI,''
from doc a 
inner join dvi b on a.subunitate=b.subunitate and a.numar=b.numar_receptie and a.data=b.data_dvi
where @CtFactVama=0 and a.subunitate=@Sb and a.tip='RM' and b.data_DVI between @DataJ and @DataS and b.tert_vama like rtrim(@Tert) and left(b.cont_tert_vama,8) like rtrim(@Fact) and b.cont_com_vam like rtrim(@cCt)+'%' and b.factura_comis in ('','D')
	and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=a.loc_munca))
	and (@locm='%' or a.Loc_munca like @locm)
union all
select a.subunitate,b.tert_vama,b.factura_TVA,a.tip,a.numar,b.data_DVI,0,(case when b.total_vama<>1 then b.tva_22 else 0 end),0,'',0,0,0,a.loc_munca,a.comanda,b.cont_factura_TVA,'2','','tva vama',0,a.cod_gestiune,b.data_receptiei,convert(datetime,b.tert_comis,103),a.numar_DVI,''
from doc a 
inner join dvi b on a.subunitate=b.subunitate and a.numar=b.numar_receptie and a.data=b.data_dvi 
where @CtFactVama=0 and a.subunitate=@Sb and a.tip='RM' and b.data_DVI between @DataJ and @DataS and b.tert_vama like rtrim(@Tert) and b.factura_TVA like rtrim(@Fact) and b.cont_factura_TVA like rtrim(@cCt)+'%' and b.factura_comis in ('','D')
	and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=a.loc_munca))
	and (@locm='%' or a.Loc_munca like @locm)
return
end