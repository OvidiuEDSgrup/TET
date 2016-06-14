
DROP procedure rapFisaContTert
GO
--***  
create procedure rapFisaContTert(@cFurnBenef varchar(1),@cDataJos datetime,@cDataSus datetime,@cTert varchar(50)=null,@cContTert varchar(20),  
 @grupa varchar(50)=null,  
 @exc_grupa varchar(50)=null, @cFactura varchar(40)=null, @grfact varchar(40)=null, @lm varchar(40) = null, @comanda varchar(40) = null,  
 @cont_cor varchar(40) = null, @tipinc varchar(40) = null,@indicator varchar(40)=null,@detTVA varchar(1)='1')  
as   
declare @eroare varchar(2000)  
set @eroare=''  
begin try  
 IF OBJECT_ID('tempdb..#ftert') IS NOT NULL drop table #ftert  
 IF OBJECT_ID('tempdb..#cuzero') IS NOT NULL drop table #cuzero  
   
 declare @utilizator varchar(50)  
-- exec wIaUtilizator @sesiune='', @utilizator=@utilizator output  
 declare @cuFltLocmStilVechi int, @fltLocmStilNou varchar(20) --> se alege tipul filtrarii pe loc de munca in functie de setare  
 select @cuFltLocmStilVechi=0, @fltLocmStilNou=@lm  
 if exists (select 1 from par where Tip_parametru='GE' and Parametru='FLTTRTLM' and Val_logica=1)  
  select @cuFltLocmStilVechi=1, @fltLocmStilNou=null  
   
--test select @cuFltLocmStilVechi, @fltLocmStilNou  
/*  
select @cFurnBenef=N'F',@cDataJos='2010-01-01 00:00:00',@cDataSus='2010-01-31 00:00:00',@cTert=N'1185',@cContTert=N'4091',@grupa=NULL,  
  @exc_grupa=NULL,@cFactura=NULL,@grfact=NULL,@lm=NULL,@comanda=NULL,@cont_cor=NULL,@tipinc=NULL,  
  @indicator=NULL,@detTVA=N'1'  
*/ set transaction isolation level read uncommitted  
 declare @epsilon decimal(6,5), @dataAnt datetime  
   /** @epsilon = marja de eroare pentru valorile numerice  
    @dataAnt = data anterioara intervalului trimis din raport  
   */  
  set @dataAnt=DateAdd(d,-1,@cDataJos)  
 set @epsilon=0.0001  
/**1. creare cursor pentru a imparti datele mai usor si mai rapid in continuare pe sold si pe rulaj*/  
 select  
 ft.furn_benef, ft.subunitate, ft.tert, ft.factura, ft.tip, ft.numar, ft.data, ft.valoare, ft.tva, ft.achitat, ft.valuta, ft.curs, ft.total_valuta, ft.achitat_valuta, ft.loc_de_munca, ft.comanda, ft.cont_de_tert, ft.fel, ft.cont_coresp, ft.explicatii, ft.
numar_pozitie, ft.gestiune, ft.data_facturii, ft.data_scadentei, ft.nr_dvi, ft.barcod, ft.pozitie, ft.contTVA  
 into #ftert  
 from dbo.fTert(@cFurnBenef,@cDataJos, @cDataSus,@cTert,null,@cContTert,0,0,0,@fltLocmStilNou) ft   
 where   
 (@cFactura is null or ft.factura = rtrim(@cFactura))  
 and (@grfact is null or ft.factura like rtrim(@grfact)+'%')  
 and (@cuFltLocmStilVechi=0 or @lm is null or rtrim(ft.loc_de_munca)= rtrim(@lm))  
 and (@comanda is null or rtrim(substring(ft.comanda,1,20))= rtrim(@comanda))  
 and (@indicator is null or rtrim(substring(ft.comanda,21,20))= rtrim(@indicator))  
 and (@cont_cor is null or rtrim(ft.cont_coresp)= rtrim(@cont_cor))   
 and (@tipinc is null or exists (select nr_doc from incfact e   
 where ft.subunitate=e.subunitate and ft.tert=e.tert and ft.factura=e.numar_factura   
 and e.mod_plata=@tipinc))  
--test select SUM(valoare), SUM(tva) from #ftert  
/**2. se creeaza tabela cu datele organizate pentru a se putea afisa in raport; se foloseste inca o tabela pentru a se mai putea filtra   
  datele inainte de a le trimite */  
 select denumire, grupa, a.cont_de_tert as cont_factura, isnull(c.tip_cont,'B') tip_cont,  
  (case a.debitare when 'D' then cont_corespondent when 'C' then cont_de_tert end) cont_corespondent,   
  debitare, soldfactbenef, soldfactfurn, tert, factura, tip, numar, data,   
  (case when tip not in ('CF','CB','PS','IS') then valoare else -achitat end) valoare, tva, (case when tip not in ('CF','CB','PS','IS') then achitat else -valoare end) achitat,   
  (case a.debitare when 'D' then cont_de_tert when 'C' then cont_corespondent end) cont_de_tert,  
  explicatii, numar_pozitie, data_facturii, data_scadentei, nrpoz, furn_benef into #cuzero  
  from  
 (  
 /** rulaj valoare */  
  select t.denumire,t.grupa,'' as nrpoz, '' as tvap, cont_coresp as cont_corespondent,  
  (case when left(ft.tip,1)='P' or (ft.tip='SI' and furn_benef='B') or   
  (furn_benef='F' and ft.tip in ('SX', 'CO', 'FX', 'C3', 'RX')) or   
  (furn_benef<>'F' and ft.tip not in ('SI', 'IB', 'IR','IX', 'BX', 'CO', 'C3', 'AX'))  
  or (ft.tip in ('SI', 'IB', 'IR') and furn_benef='F')   
  or (ft.tip in ('SI', 'PF', 'PR') and furn_benef='B')  then 'D' else 'C' end) as debitare,  
  0 as soldfactbenef, 0 as soldfactfurn,   
  ft.furn_benef, ft.subunitate, ft.tert, ft.factura, ft.tip, ft.numar, ft.data, ft.valoare, 0 tva, ft.achitat, ft.valuta, ft.curs, ft.total_valuta, ft.achitat_valuta, ft.loc_de_munca, ft.comanda, ft.cont_de_tert, ft.fel, ft.cont_coresp, ft.explicatii, ft.
numar_pozitie, ft.gestiune, ft.data_facturii, ft.data_scadentei, ft.nr_dvi, ft.barcod, ft.pozitie  
  from #ftert ft   
  left outer join terti t on ft.tert=t.tert and ft.subunitate=t.subunitate  
  where   
  (@grupa is null or t.grupa like rtrim(@grupa)+'%')  
  and (@exc_grupa is null or t.grupa <> @exc_grupa) and ft.data>@dataAnt  
  
 union all  
 /** rulaj tva  */  
  select t.denumire,t.grupa,(case when @detTVA=1 then '1' else '' end) numar_pozitie, tva,   
  --(case when furn_benef='F' then '4426' else '4427' end)  
  ft.contTVA,  
  (case when left(ft.tip,1)='P' or (ft.tip='SI' and furn_benef='B') or   
  (furn_benef='F' and ft.tip in ('SX', 'CO', 'FX', 'C3', 'RX')) or   
  (furn_benef<>'F' and ft.tip not in ('SI', 'IB', 'IR','IX', 'BX', 'CO', 'C3', 'AX'))  
  or (ft.tip in ('SI', 'IB', 'IR') and furn_benef='F')   
  or (ft.tip in ('SI', 'PF', 'PR') and furn_benef='B')  then 'D' else 'C' end) as debitare,  
  0 as soldfactbenef, 0 as soldfactfurn,   
  ft.furn_benef, ft.subunitate, ft.tert, ft.factura, ft.tip, ft.numar, ft.data, 0 valoare, ft.tva, 0 achitat, ft.valuta,   
  ft.curs,0 total_valuta, 0 achitat_valuta, ft.loc_de_munca, ft.comanda, ft.cont_de_tert, ft.fel, ft.cont_coresp,   
   '<TVA> '+ft.explicatii, ft.numar_pozitie, ft.gestiune, ft.data_facturii, ft.data_scadentei, ft.nr_dvi, ft.barcod, ft.pozitie  
  from #ftert ft  
  left outer join terti t on ft.tert=t.tert and ft.subunitate=t.subunitate  
  where tva<>0  
  and (@grupa is null or t.grupa like rtrim(@grupa)+'%')  
  and (@exc_grupa is null or t.grupa <> @exc_grupa) and ft.data>@dataAnt  
   
 union all  
 /** sold */  
  select max(t.denumire),max(t.grupa),'' numar_pozitie, 0, '' contTVA,  
  max( case when ft.tip='B'  then 'D' else 'C' end) as debitare,  
  (case when @cFurnBenef='B' then sum(ft.valoare+ft.tva-achitat) else 0 end),(case when @cFurnBenef='F' then sum(ft.valoare+ft.tva-achitat) else 0 end),  
  'S', '', ft.tert, ft.factura, '','',max(ft.data),'','','','','','','','','','','','','','','','','','','',''  
  from #ftert ft  
  left outer join terti t on ft.tert=t.tert and ft.subunitate=t.subunitate  
  where /*tva<>0  
  and*/ (@grupa is null or t.grupa like rtrim(@grupa)+'%')  
  and (@exc_grupa is null or t.grupa <> @exc_grupa) and ft.data<=@dataAnt  
  group by ft.tert, ft.factura --*/  
 )a  
  left join conturi c on a.cont_de_tert=c.Cont  
 where tva<>0 or valoare<>0 or achitat<>0 or furn_benef='S'  
 order by a.tert, data_facturii,factura,a.denumire,a.furn_benef,a.debitare,a.tip,a.numar, nrpoz  
/**3. se trimit datele la raport, dupa ce s-au eliminat eventualele inregistrari cu valori 0*/  
 select rtrim(denumire) denumire, rtrim(grupa) grupa, rtrim(cont_factura) cont_factura, rtrim(tip_cont) tip_cont,   
   rtrim(cont_corespondent) cont_corespondent, debitare, soldfactbenef,   
   soldfactfurn, rtrim(tert) tert, rtrim(factura) factura, rtrim(tip) tip, rtrim(numar) numar,  
   data, valoare, tva, achitat, rtrim(cont_de_tert) cont_de_tert, rtrim(explicatii) explicatii, numar_pozitie,  
   data_facturii, data_scadentei, nrpoz, furn_benef  
  from #cuzero c  
  where abs(tva)>@epsilon or abs(valoare)>@epsilon or abs(achitat)>@epsilon  
    or furn_benef='S' and (abs(c.soldfactbenef)>@epsilon or abs(c.soldfactfurn)>@epsilon)  
end try  
begin catch  
 set @eroare='rapFisaContTerti (linia '+convert(varchar(20),ERROR_LINE())+') '+char(10)+  
    ERROR_MESSAGE()  
end catch  
  
IF OBJECT_ID('tempdb..#ftert') IS NOT NULL drop table #ftert  
IF OBJECT_ID('tempdb..#cuzero') IS NOT NULL drop table #cuzero  
if (@eroare<>'')  
 raiserror(@eroare,16,1)
 
GO
/*
declare @cFurnBenef varchar(1),@cDataJos datetime,@cDataSus datetime,@cTert varchar(50),@cContTert varchar(20),@grupa varchar(50),
	@exc_grupa varchar(50),@cFactura varchar(40),@grfact varchar(40),@lm varchar(40),@comanda varchar(40),@cont_cor varchar(40),
	@tipinc varchar(40),@dataAnt datetime,@indicator varchar(40),@detTVA varchar(1)

select	@cFurnBenef=N'F',@cDataJos='2009-01-01 00:00:00',@cDataSus='2009-12-31 00:00:00',@cTert=N'1185',@cContTert=N'4091',@grupa=NULL,
		@exc_grupa=NULL,@cFactura=NULL,@grfact=NULL,@lm=NULL,@comanda=NULL,@cont_cor=NULL,@tipinc=NULL,
		@indicator=NULL,@detTVA=N'1'
*/
declare @cFurnBenef nvarchar(1),@cDataJos datetime,@cDataSus datetime,@cTert nvarchar(4000),@cContTert nvarchar(5),@grupa nvarchar(4000),@exc_grupa nvarchar(4000),@cFactura nvarchar(4000),@grfact nvarchar(4000),@lm nvarchar(4000),@comanda nvarchar(4000),@cont_cor nvarchar(4000),@tipinc nvarchar(4000),@indicator nvarchar(4000),@detTVA nvarchar(1)
select @cFurnBenef=N'F',@cDataJos='2012-04-01 00:00:00',@cDataSus='2012-04-30 00:00:00',@cTert=NULL,@cContTert=N'401.3',@grupa=NULL,@exc_grupa=NULL,@cFactura=NULL,@grfact=NULL,@lm=NULL,@comanda=NULL,@cont_cor=NULL,@tipinc=NULL,@indicator=NULL,@detTVA=N'1'


exec rapFisaContTert @cFurnBenef=@cFurnBenef, @cDataJos=@cDataJos, @cDataSus=@cDataSus, @cTert=@cTert, @cContTert=@cContTert,
	@grupa=@grupa, @exc_grupa=@exc_grupa, @cFactura=@cFactura, @grfact=@grfact, @lm=@lm, @comanda=@comanda,
	@cont_cor=@cont_cor, @tipinc=@tipinc, @indicator=@indicator, @detTVA=@detTVA

GO