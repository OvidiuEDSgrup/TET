--***
/**	functie fPlati trezorerie	*/
create function Plati_trezorerie ()
returns @plati_salarii table
(Numar_document char(13), Suma float, Platitor char(50), Cif_platitor char(13), Adresa char(100), Cont_iban_platitor char(24), 
Cod_banca_Platitor char(15), Banca_Platitor char(50), Beneficiar char(50), Cif_beneficiar char(13), Cont_iban_beneficiar char(24), Cod_banca_Beneficiar char(15), Banca_Beneficiar char(50), Explicatii char(50), Data_emiterii datetime)
As
Begin
DECLARE @platitor char(100), @cod_fiscal char(13), @adresa char(200), @cTerm char(8)
Set @cTerm = (select convert(char(8), abs(convert(int, host_id()))))
Set @platitor=dbo.iauParA('GE','NUME')
Set @cod_fiscal=dbo.iauParA('GE','CODFISC')
Set @adresa=rtrim(dbo.iauParA('PS','LOCALIT'))+' STR. '+rtrim(dbo.iauParA('PS','STRADA'))+
' NR. '+rtrim(dbo.iauParA('PS','NUMAR'))+' JUDET '+rtrim(dbo.iauParA('PS','JUDET'))
insert into @plati_salarii
select rtrim(max(extprogpl.numar_document)), sum(prog_plin.suma), rtrim(@platitor), rtrim(@cod_fiscal), rtrim(@adresa),
(case when left(max(ccontaiban.cont),4)='5311' then '' else rtrim(max(ccontaiban.iban)) end),
(case when left(max(ccontaiban.cont),4)='5311' then '' else rtrim(max(extprogpl.cont_platitor)) end),
max(ccontaiban.banca), rtrim(max(terti.denumire)), 
rtrim((case when max(prog_plin.tert)='ITM' or prog_plin.element='F' then max(terti.cod_fiscal) else dbo.iauParA('GE','CODFISC') end)),
rtrim(max(extprogpl.iban_beneficiar)), rtrim(max(extprogpl.alfa1)), rtrim(max(extprogpl.banca_beneficiar)),
rtrim(max(prog_plin.explicatii)), max(extprogpl.data1)
from prog_plin, extprogpl, ccontaiban, avnefac, terti 
where prog_plin.tip='P' and prog_plin.stare=0 and prog_plin.tip=extprogpl.tip and prog_plin.element=extprogpl.element 
and prog_plin.data=extprogpl.data and prog_plin.tert=extprogpl.tert and prog_plin.factura=extprogpl.factura 
and extprogpl.cont_platitor=ccontaiban.cod and avnefac.terminal=@cTerm and avnefac.subunitate=terti.subunitate 
and prog_plin.tert=avnefac.cod_tert and /*prog_plin.data=avnefac.Data_facturii and*/ terti.tert=prog_plin.tert 
and extprogpl.Numar_document=avnefac.Factura
Group by prog_plin.tip, prog_plin.element, /*prog_plin.data,*/ prog_plin.tert, extprogpl.Numar_document
return
End
