IF OBJECT_ID('tempdb..doctertASIS') IS NOT NULL DROP TABLE tempdb..doctertASIS
select p.subunitate, p.tert, p.factura, p.tip, p.numar, p.data, (case when p.data between '02/01/2014' and '02/28/2014' then '2' else '1' end) as in_perioada, 
p.valoare+p.tva as total, 0 as tva_11, p.tva as tva_22, 
(case when 'F'='B' and 0=1 and p.fel='3' and p.cont_coresp like '%' and
	(abs(e.sold)>0.0001 or isnull(e.Valoare,0)=0) then 0
	else p.achitat end) as achitat, 
p.loc_de_munca, p.comanda, p.cont_de_tert, p.fel, p.cont_coresp, space(3) as valuta, 
p.explicatii, p.numar_pozitie, 
(case when 'F'='F' then 
 (case when p.tip in ('SI', 'PF', 'PR') then 'FC' when p.tip in ('SX', 'CO', 'FX', 'C3', 'RX') then 'D' else 'C' end) else 
 (case when p.tip in ('SI', 'IB', 'IR') then 'FD' when p.tip in ('IX', 'BX', 'CO', 'C3', 'AX') then 'C' else 'D' end) end) as op,
p.gestiune, p.data_facturii, p.data_scadentei, 0 as curs, p.nr_dvi as DVI, p.barcod, 
0 as totLPV, 0 as achLPV, space(10) as Utilizator, contTVA, contract, data_platii 
into tempdb..doctertASIS
from dbo.fFacturi ('F', '02/01/2014', '02/28/2014', null, '%', '', 0, 0,           1.00000000 , '', null) p
left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
left outer join infotert i on p.subunitate=i.subunitate and p.tert=i.tert and i.identificator='' 
left outer join facturi f on p.subunitate=f.subunitate and p.tert=f.tert and p.factura=f.factura and f.tip=(case when 'F'='F' then 0x54 else 0x46 end)
left outer join efecte e on 'F'='B' and 0=1 and p.fel='3' and p.cont_coresp like '%' and e.subunitate=p.subunitate and e.tert=p.tert and e.tip='I'
	and e.nr_efect=(case when charindex('|', p.numar)>0 then RTRim(substring(p.numar, charindex('|', p.numar) + 1, 20)) else p.numar end)
	and e.data_decontarii<='02/28/2014'
where (1=0 or p.tip<>'SI') and (0=0 or isnull(t.judet,'')='') and (0=0 or isnull(t.localitate,'')='') 
and (0=0 or '        ' in (select jz.zona from judzone jz where jz.judet=isnull(t.judet, '') and (0=0 or jz.divizia=left(isnull(f.loc_de_munca, ''), 1)))) 
and isnull(t.grupa, '') between '' and 'zzz' and isnull(i.descriere,'') between '' and 'zzzzz' and isnull(f.loc_de_munca,'') like rtrim('')+'%' 
and (0=0 or p.tip not in ('SI', 'AP', 'AS') or rtrim(p.factura) <> '')
and (0=0 or rtrim(left(isnull(f.comanda, ''),20))=rtrim('                    ')) and (0=0 or rtrim(right(isnull(p.comanda, ''),20))=rtrim('                    ')) 
GO
IF OBJECT_ID('tempdb..valdocASIS') IS NOT NULL DROP TABLE tempdb..valdocASIS
select subunitate, max(case when tip in ('RP','RQ') then 'RM' when tip='SX' then 'SF' when tip='FX' then 'CF' when tip='IX' then 'IF' when tip='BX' then 'CB' when tip='AX' then 'AP' when tip='RX' then 'RM' else tip end) as tip, max(ltrim((case when left(tip,1)='M' then tip else '' end)+numar)) as numar, data, (case when fel=2 or fel=1 or max(tip) in ('FB','FF')  or ((max(tip)='SF' or max(tip)='IF') and max(achitat)=0)  then sum(total) else sum(achitat) end) as total, cont_de_tert, (case when fel=3 and 0=0 then abs(numar_pozitie) else 1 end) as numar_pozitie, fel, (case when fel=3 and 1=1 then cont_coresp else '' end) as cont_coresp, (case when fel=3 and 0=1 then utilizator+str(abs(numar_pozitie),6) else '1' end) as pozitie 
into tempdb..valdocASIS 
from tempdb..doctertASIS 
where cont_de_tert  in (select cont from conturi where sold_credit=(case when 'T'='T' then 1 else 2 end)) and data between '02/01/2014' and '02/28/2014' 
group by subunitate, (case when tip in ('RP','RQ') then 'RM' when tip='SX' then 'SF' when tip='FX' then 'CF' when tip='IX' then 'IF' when tip='BX' then 'CB' when tip='AX' then 'AP' when tip='RX' then 'RM' else tip end), (case when left(tip,1)='M' then tip else '' end)+(case when fel=3 then '' else numar end), data, cont_de_tert, fel, (case when fel=3 and 0=0 then abs(numar_pozitie) else 1 end), (case when fel=3 and 1=1 then cont_coresp else '' end), (case when fel=3 and 0=1 then utilizator+str(abs(numar_pozitie),6) else '1' end)
GO
IF OBJECT_ID('tempdb..valinconASIS') IS NOT NULL DROP TABLE tempdb..valinconASIS
select subunitate, tip_document, numar_document, data, (case when 'T'='T' then -suma else suma end) as suma, cont_debitor as cont, 'D' as tip, (case when tip_document='PI' then numar_pozitie else 1 end) as numar_pozitie, cont_creditor as contc, Utilizator 
into tempdb..valinconASIS
from pozincon 
where cont_debitor  in (select cont from conturi where sold_credit=(case when 'T'='T' then 1 else 2 end) and cont like rtrim('             ')+'%')  and data between '02/01/2014' and '02/28/2014'  
union all 
select subunitate, tip_document, numar_document, data, (case when 'T'='F' then -suma else suma end) as suma, cont_creditor as cont, 'C' as tip, (case when tip_document='PI' then numar_pozitie else 1 end), cont_debitor, Utilizator 
from pozincon 
where cont_creditor  in (select cont from conturi where sold_credit=(case when 'T'='T' then 1 else 2 end) and cont like rtrim('             ')+'%') and data between '02/01/2014' and '02/28/2014' 
GO
IF OBJECT_ID('tempdb..ginconASIS') IS NOT NULL DROP TABLE tempdb..ginconASIS
select subunitate, tip_document, numar_document, data, sum(suma) as suma, cont, (case when tip_document='PI' then numar_pozitie else 1 end) as numar_pozitie, (case when tip_document='PI' and 1=1 then /*contc*/numar_document else '' end) as contc, (case when tip_document='PI' and 0=1 then utilizator+str(numar_pozitie,6) else '1' end) as pozitie 
into tempdb..ginconASIS
from tempdb..valinconASIS 
group by subunitate, tip_document, numar_document, data, cont, (case when tip_document='PI' then numar_pozitie else 1 end), (case when tip_document='PI' and 1=1 then /*contc*/numar_document else '' end), (case when tip_document='PI' and 0=1 then utilizator+str(numar_pozitie,6) else '1' end)
GO
select isnull(a.tip,b.tip_document), isnull(a.numar,b.numar_document), isnull(a.data,b.data) , isnull(a.total,0), isnull(a.cont_de_tert,b.cont), isnull(b.suma,0) 
from tempdb..valdocASIS a 
full outer join tempdb..ginconASIS b on a.subunitate=b.subunitate 
and (case when a.fel=4 and a.tip in ('AP','AS', 'RM', 'RS') then left(a.tip,1) when a.fel in (1,2,4) then a.tip when 1=0 and a.fel=4  then a.numar else '1' end)
=(case when a.fel=4 and b.tip_document in ('AP', 'AS', 'RM', 'RS') then left(b.tip_document,1) when a.fel in (1,2,4) then b.tip_document when 1=0 and a.fel=4 then b.numar_document else '1' end) and (case when a.fel=3 and 0=0 then a.numar_pozitie else 1 end)=(case when a.fel=3 and 0=0 then b.numar_pozitie else 1 end) and (case when a.fel=3 and 0=1 then a.pozitie else '1' end)=(case when a.fel=3 and 0=1 then b.pozitie else '1' end) and (case when a.fel in (1,2,4) then a.numar else '1' end)=(case when a.fel in (1,2,4) then b.numar_document else '1' end) and a.data=b.data and a.cont_de_tert=b.cont and (case when a.fel=3 and 1=1 then a.cont_coresp else '' end)=(case when /*a.fel=3*/b.tip_document='PI' and 1=1 then /*b.contc*/b.numar_document else '' end)
where abs(convert(decimal(17,3),isnull(a.total,0)))<>abs(convert(decimal(17,3),isnull(b.suma,0))) and abs(abs(convert(decimal(17,3),isnull(a.total,0)))-abs(convert(decimal(17,3),isnull(b.suma,0))))>1 
and (a.fel<>3 or a.numar_pozitie>0 or b.numar_pozitie>0)
